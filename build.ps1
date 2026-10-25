<#
.SYNOPSIS
    Собирает exe всех проектов из папки CSharpCollege-Master в папку out.

.DESCRIPTION
    Находит все решения (.sln, .slnx), берёт из них запускаемые проекты (WinForms, WPF, консольные,
    ASP.NET Core), восстанавливает NuGet-пакеты и собирает каждый проект в Release в свою папку
    внутри out. Туда же кладётся меню запуска run.cmd.

    Нужно: Windows и Visual Studio 2022 (или Build Tools) с нагрузкой «Разработка классических
    приложений .NET». Для веб-проекта на .NET 10 (TicTacToe.Web) нужен .NET SDK 10, без него
    проект пропускается.

.PARAMETER Filter
    Собрать только проекты, в пути к которым есть эта строка, например: -Filter Calculator

.PARAMETER List
    Только показать найденные проекты, ничего не собирая.

.EXAMPLE
    .\build.ps1

.EXAMPLE
    .\build.ps1 -Filter "Projects.24.3.24.4"
#>
[CmdletBinding()]
param(
    [string]$Filter = "",
    [switch]$List
)

$ErrorActionPreference = "Stop"

$repoRoot = $PSScriptRoot
$sourceRoot = Join-Path $repoRoot "CSharpCollege-Master"
$outRoot = Join-Path $repoRoot "out"
$toolsDir = Join-Path $repoRoot ".tools"
$launcherDir = Join-Path $repoRoot "scripts"
$sep = [IO.Path]::DirectorySeparatorChar

# На GitHub Actions пропущенный проект считается ошибкой: там должно собираться всё
$isCI = [bool]$env:CI

function Get-RelativePath([string]$basePath, [string]$path) {
    $base = $basePath.TrimEnd('\', '/') + $sep
    if (-not $path.StartsWith($base, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Путь $path лежит вне $basePath"
    }
    return $path.Substring($base.Length)
}

function Get-FullPath([string]$baseDir, [string]$relativePath) {
    return [IO.Path]::GetFullPath((Join-Path $baseDir ($relativePath -replace '[\\/]', $sep)))
}

function Get-XmlValue([xml]$xml, [string]$name) {
    $node = $xml.SelectSingleNode("//*[local-name()='$name']")
    if ($node) { return $node.InnerText.Trim() }
    return $null
}

function Read-Project([string]$path) {
    [xml]$xml = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    $dir = Split-Path $path
    $sdk = $xml.DocumentElement.GetAttribute("Sdk")
    $outputType = Get-XmlValue $xml "OutputType"
    $assemblyName = Get-XmlValue $xml "AssemblyName"
    if (-not $assemblyName) { $assemblyName = [IO.Path]::GetFileNameWithoutExtension($path) }

    if ($sdk -like "*Sdk.Web*") { $kind = "web" }
    elseif ($outputType -eq "WinExe") { $kind = "gui" }
    elseif ($outputType -eq "Exe") { $kind = "console" }
    else { $kind = "library" }

    $references = @()
    foreach ($node in $xml.SelectNodes("//*[local-name()='ProjectReference']")) {
        $references += Get-FullPath $dir $node.GetAttribute("Include")
    }

    return [pscustomobject]@{
        Path = $path
        Dir = $dir
        IsSdk = [bool]$sdk
        Kind = $kind
        ExeName = "$assemblyName.exe"
        References = $references
    }
}

# Папка сборки повторяет путь к проекту, только без повторов подряд:
# Projects.24.3.24.4\3. Calculator\Calculator\Calculator -> Projects.24.3.24.4\3. Calculator\Calculator
function Get-ShortName([string]$relativeDir) {
    $parts = New-Object System.Collections.Generic.List[string]
    foreach ($part in ($relativeDir -split '[\\/]')) {
        if ($parts.Count -eq 0 -or $parts[$parts.Count - 1] -ne $part) { $parts.Add($part) }
    }
    return $parts -join '\'
}

function Find-MSBuild {
    $command = Get-Command msbuild.exe -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }

    $vswhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path -LiteralPath $vswhere) {
        $ErrorActionPreference = "Continue"
        $path = & $vswhere -latest -prerelease -products * -requires Microsoft.Component.MSBuild `
            -find "MSBuild\**\Bin\MSBuild.exe" | Select-Object -First 1
        if ($path) { return $path }
    }

    throw "Не найден MSBuild. Установите Visual Studio 2022 (или Build Tools) с нагрузкой «Разработка классических приложений .NET»."
}

function Find-NuGet {
    $command = Get-Command nuget.exe -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }

    $path = Join-Path $toolsDir "nuget.exe"
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Host "Скачивается nuget.exe..."
        New-Item -ItemType Directory -Force -Path $toolsDir | Out-Null
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -OutFile $path -UseBasicParsing
    }
    return $path
}

function Test-DotnetSdk10 {
    if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) { return $false }
    $ErrorActionPreference = "Continue"
    $sdks = & dotnet --list-sdks 2>$null
    return [bool]($sdks | Where-Object { $_ -match '^(1\d|[2-9]\d)\.' })
}

# Запускает внешнюю программу, выводит её сообщения в консоль и возвращает код завершения.
# Внутри функции ErrorActionPreference = Continue: иначе Windows PowerShell 5.1 может прервать
# скрипт из-за строки в stderr (например, предупреждения nuget)
function Invoke-Tool([string]$exe, [string[]]$arguments) {
    $ErrorActionPreference = "Continue"
    & $exe @arguments | Out-Host
    return $LASTEXITCODE
}

# --- Поиск проектов ---------------------------------------------------------------------------

$projectPaths = New-Object System.Collections.Generic.HashSet[string] ([StringComparer]::OrdinalIgnoreCase)
$solutions = Get-ChildItem -LiteralPath $sourceRoot -Recurse -File |
    Where-Object { $_.Extension -eq ".sln" -or $_.Extension -eq ".slnx" }

foreach ($solution in $solutions) {
    $text = Get-Content -LiteralPath $solution.FullName -Raw -Encoding UTF8
    $pattern = if ($solution.Extension -eq ".slnx") { 'Path="([^"]+\.csproj)"' } else { '"([^"]+\.csproj)"' }
    foreach ($match in [regex]::Matches($text, $pattern)) {
        $path = Get-FullPath $solution.DirectoryName $match.Groups[1].Value
        if (Test-Path -LiteralPath $path) { [void]$projectPaths.Add($path) }
    }
}

$projectCache = @{}
function Get-Project([string]$path) {
    if (-not $projectCache.ContainsKey($path)) { $projectCache[$path] = Read-Project $path }
    return $projectCache[$path]
}

$allProjects = @()
foreach ($path in $projectPaths) {
    $project = Get-Project $path
    if ($project.Kind -eq "library") { continue }

    $name = Get-ShortName (Get-RelativePath $sourceRoot $project.Dir)
    $project | Add-Member Name $name
    $project | Add-Member OutDir (Join-Path $outRoot ($name -replace '\\', $sep))
    $allProjects += $project
}

# Сортировка с учётом чисел: "2. Drawing" раньше "10. Game Client-Server"
$allProjects = @($allProjects | Sort-Object { [regex]::Replace($_.Name, '\d+', { $args[0].Value.PadLeft(6, '0') }) })

$duplicates = $allProjects | Group-Object Name | Where-Object Count -gt 1
if ($duplicates) { throw "Одинаковые папки сборки: $($duplicates.Name -join ', ')" }

$projects = @($allProjects | Where-Object { $_.Name -like "*$Filter*" })
Write-Host "Найдено запускаемых проектов: $($projects.Count)"

if ($List) {
    $projects | ForEach-Object { Write-Host ("  {0,-8} {1}" -f $_.Kind, $_.Name) }
    exit 0
}

if ($projects.Count -eq 0) { throw "Нет проектов, подходящих под фильтр '$Filter'" }

# --- Инструменты ------------------------------------------------------------------------------

$msbuild = Find-MSBuild
$nuget = Find-NuGet
$hasDotnetSdk = Test-DotnetSdk10
Write-Host "MSBuild: $msbuild"
Write-Host "NuGet:   $nuget"

$msbuildArgs = @("/nologo", "/v:minimal", "/m", "/nr:false", "/p:Configuration=Release")

# Если в системе нет targeting pack .NET Framework 4.7.2, берём референсные сборки из NuGet
$referenceAssemblies = Join-Path ${env:ProgramFiles(x86)} "Reference Assemblies\Microsoft\Framework\.NETFramework\v4.7.2"
if (-not (Test-Path -LiteralPath $referenceAssemblies)) {
    $package = "Microsoft.NETFramework.ReferenceAssemblies.net472"
    $version = "1.0.3"
    Write-Host "Не найден targeting pack .NET Framework 4.7.2, используется пакет $package"
    [void](Invoke-Tool $nuget @("install", $package, "-Version", $version, "-OutputDirectory", $toolsDir, "-NonInteractive"))
    $msbuildArgs += "/p:TargetFrameworkRootPath=$(Join-Path $toolsDir "$package.$version\build")"
}

# --- Восстановление NuGet-пакетов (packages.config) -------------------------------------------

$packageConfigs = New-Object System.Collections.Generic.HashSet[string] ([StringComparer]::OrdinalIgnoreCase)
foreach ($project in ($projects | Where-Object { -not $_.IsSdk })) {
    $stack = New-Object System.Collections.Stack
    $stack.Push($project.Path)
    $visited = @{}
    while ($stack.Count -gt 0) {
        $path = $stack.Pop()
        if ($visited.ContainsKey($path) -or -not (Test-Path -LiteralPath $path)) { continue }
        $visited[$path] = $true

        $config = Join-Path (Split-Path $path) "packages.config"
        if (Test-Path -LiteralPath $config) { [void]$packageConfigs.Add($config) }
        foreach ($reference in (Get-Project $path).References) { $stack.Push($reference) }
    }
}

Write-Host "Восстановление NuGet-пакетов ($($packageConfigs.Count) packages.config)..." -ForegroundColor Cyan
foreach ($config in $packageConfigs) {
    # В проектах пути к пакетам вида ..\packages\..., т.е. папка packages рядом с папкой проекта
    $packagesDir = Join-Path (Split-Path (Split-Path $config)) "packages"
    $code = Invoke-Tool $nuget @("restore", $config, "-PackagesDirectory", $packagesDir, "-NonInteractive", "-Verbosity", "quiet")
    if ($code -ne 0) { Write-Warning "Не удалось восстановить пакеты: $config" }
}

# --- Сборка -----------------------------------------------------------------------------------

$results = @()
$index = 0
foreach ($project in $projects) {
    $index++
    Write-Host ""
    Write-Host "==> [$index/$($projects.Count)] $($project.Name)" -ForegroundColor Cyan

    if (Test-Path -LiteralPath $project.OutDir) { Remove-Item -LiteralPath $project.OutDir -Recurse -Force }
    $timer = [Diagnostics.Stopwatch]::StartNew()

    if ($project.IsSdk -and -not $hasDotnetSdk) {
        Write-Warning "Не найден .NET SDK 10 (https://dotnet.microsoft.com/download) — проект пропущен"
        $status = "ПРОПУЩЕН"
    }
    else {
        if ($project.IsSdk) {
            # Самодостаточный exe: на компьютере не нужен установленный .NET 10
            $code = Invoke-Tool "dotnet" @("publish", $project.Path, "-c", "Release", "-r", "win-x64",
                "--self-contained", "true", "-p:PublishSingleFile=true", "-p:EnableCompressionInSingleFile=true",
                "-p:DebugType=None", "-o", $project.OutDir, "--nologo", "-v", "minimal")
        }
        else {
            $code = Invoke-Tool $msbuild ($msbuildArgs + @($project.Path, "/p:OutDir=$($project.OutDir)"))
        }

        $exeExists = Test-Path -LiteralPath (Join-Path $project.OutDir $project.ExeName)
        $status = if ($code -eq 0 -and $exeExists) { "OK" } else { "ОШИБКА" }
    }

    $timer.Stop()
    $results += [pscustomobject]@{
        Status = $status
        Seconds = [int]$timer.Elapsed.TotalSeconds
        Project = $project.Name
    }
}

# --- Меню запуска -----------------------------------------------------------------------------

# В меню попадают все собранные проекты, в том числе собранные прошлыми запусками с -Filter
$built = @()
foreach ($project in $allProjects) {
    $exe = Join-Path $project.OutDir $project.ExeName
    if (Test-Path -LiteralPath $exe) {
        $built += [pscustomobject]@{
            Name = $project.Name
            Kind = $project.Kind
            Exe = (Get-RelativePath $outRoot $exe) -replace '[\\/]', '\'
        }
    }
}

New-Item -ItemType Directory -Force -Path $outRoot | Out-Null
Copy-Item -LiteralPath (Join-Path $launcherDir "run.cmd") -Destination $outRoot -Force
Copy-Item -LiteralPath (Join-Path $launcherDir "run.ps1") -Destination $outRoot -Force
$json = ConvertTo-Json -InputObject $built
[IO.File]::WriteAllText((Join-Path $outRoot "projects.json"), $json, (New-Object Text.UTF8Encoding $true))

# --- Итог -------------------------------------------------------------------------------------

Write-Host ""
Write-Host ("{0,-9} {1,6}  {2}" -f "Статус", "Время", "Проект")
foreach ($result in $results) {
    $color = if ($result.Status -eq "OK") { "Green" } elseif ($result.Status -eq "ПРОПУЩЕН") { "Yellow" } else { "Red" }
    Write-Host ("{0,-9} {1,5}с  {2}" -f $result.Status, $result.Seconds, $result.Project) -ForegroundColor $color
}
Write-Host ""

$failed = @($results | Where-Object { $_.Status -eq "ОШИБКА" -or ($isCI -and $_.Status -ne "OK") })
$ok = @($results | Where-Object { $_.Status -eq "OK" })

if ($env:GITHUB_STEP_SUMMARY) {
    $summary = @("## Сборка exe: собрано $($ok.Count) из $($results.Count)", "", "| Статус | Время, с | Проект |", "|---|---:|---|")
    $summary += $results | ForEach-Object { "| $($_.Status) | $($_.Seconds) | ``$($_.Project)`` |" }
    $text = ($summary -join "`n") + "`n"
    [IO.File]::AppendAllText($env:GITHUB_STEP_SUMMARY, $text, (New-Object Text.UTF8Encoding $false))
}

Write-Host "Собрано $($ok.Count) из $($results.Count). Программы лежат в $outRoot, меню запуска: $(Join-Path $outRoot 'run.cmd')"
if ($failed.Count -gt 0) {
    Write-Host "Не собрались: $($failed.Project -join ', ')" -ForegroundColor Red
    exit 1
}
exit 0
