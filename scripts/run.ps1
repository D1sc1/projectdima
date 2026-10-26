# Меню запуска собранных проектов. Лежит в папке out рядом с projects.json, запускается через run.cmd.

$ErrorActionPreference = "Stop"

# Веб-проект слушает этот адрес, после запуска он открывается в браузере
$webUrl = "http://localhost:5168"

$manifest = Join-Path $PSScriptRoot "projects.json"
if (-not (Test-Path -LiteralPath $manifest)) {
    Write-Host "Не найден projects.json. Сначала соберите проекты: build.cmd в корне репозитория." -ForegroundColor Red
    Read-Host "Нажмите Enter"
    exit 1
}

# Сначала присваивание, потом @(): в Windows PowerShell 5.1 ConvertFrom-Json отдаёт массив одним объектом
$projects = Get-Content -LiteralPath $manifest -Raw -Encoding UTF8 | ConvertFrom-Json
$projects = @($projects)

$kindNames = @{
    gui = ""
    console = "  [консоль]"
    web = "  [веб, откроется в браузере]"
}

function Show-Menu {
    $group = $null
    for ($i = 0; $i -lt $projects.Count; $i++) {
        # Имя вида "9. Game DB\EF\FifteenGame\FifteenGame.Wpf": заголовок - папка проекта, пункт - остальное
        $parts = $projects[$i].Name -split '\\', 2
        if ($parts[0] -ne $group) {
            $group = $parts[0]
            Write-Host ""
            Write-Host $group -ForegroundColor Cyan
        }
        $title = if ($parts.Count -gt 1) { $parts[1] } else { $parts[0] }
        Write-Host ("  [{0,2}] {1}{2}" -f ($i + 1), $title, $kindNames[$projects[$i].Kind])
    }
}

function Start-Project($project) {
    $exe = Join-Path $PSScriptRoot $project.Exe
    $dir = Split-Path $exe

    # Рабочая папка = папка exe: программы ищут свои файлы (например, Images) относительно неё
    switch ($project.Kind) {
        "console" {
            # cmd /k оставляет окно открытым после завершения программы
            Start-Process cmd.exe -ArgumentList "/k `"$(Split-Path $exe -Leaf)`"" -WorkingDirectory $dir
        }
        "web" {
            $env:ASPNETCORE_URLS = $webUrl
            Start-Process $exe -WorkingDirectory $dir
            Start-Sleep -Seconds 3
            Start-Process $webUrl
        }
        default {
            Start-Process $exe -WorkingDirectory $dir
        }
    }
}

while ($true) {
    Show-Menu
    Write-Host ""
    $answer = Read-Host "Номер проекта (Enter - выход)"
    if ([string]::IsNullOrWhiteSpace($answer)) { break }

    $number = 0
    if (-not [int]::TryParse($answer, [ref]$number) -or $number -lt 1 -or $number -gt $projects.Count) {
        Write-Host "Нет проекта с номером $answer" -ForegroundColor Yellow
        continue
    }

    $project = $projects[$number - 1]
    Write-Host "Запуск: $($project.Name)" -ForegroundColor Green
    Start-Project $project
}
