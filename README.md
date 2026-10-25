# projectdima

Учебные проекты C# (колледж): репозиторий преподавателя `CSharpCollege-master` с выполненными
требованиями к проектам **1. AlarmClock**, **3. Calculator** и **4. Calculator WPF**.

- Код лежит в папке [`CSharpCollege-Master`](CSharpCollege-Master).
- Подробно о требованиях, о том, откуда они взяты и как проверены, — в
  [`CSharpCollege-Master/REQUIREMENTS.md`](CSharpCollege-Master/REQUIREMENTS.md).

## История коммитов

1. `CSharpCollege-master` без изменений — исходный код преподавателя. С ним удобно сравнивать:
   `git diff HEAD~1 -- CSharpCollege-Master`.
2. Выполненные требования (20 файлов в двух группах) и `REQUIREMENTS.md`.

## Различия между архивами `projects-main` и `CSharpCollege-master`

`projects-main` — это `CSharpCollege-master` плюс выполненные требования. Остальные 1 610 файлов
(`Samples.*`, `GpxDevelop`, `VTimkin`, проекты 2 и 5–10) совпадают побайтно.

| Проект | Файлы (в каждой группе) | Что отличается |
|---|---|---|
| 1. AlarmClock | `Forms/AwakeForm.cs`, `Forms/AwakeForm.Designer.cs`; у 24/3 ещё `ClockForm.cs`, `Forms/AboutForm.Designer.cs` | кнопка «Отложить (5 мин)»; у 24/3 в окне «О программе» добавлен автор |
| 3. Calculator | `CalculatorModel.cs`, `CalculatorService.cs`, `CalculatorForm.cs`, `CalculatorForm.Designer.cs` | `,` `±` `←` `π` `x²` `n!`, ошибка при делении на ноль, отдельная обработка `=` |
| 4. Calculator WPF | `MainWindow.xaml`, `MainWindow.xaml.cs`, `ViewModels/MainWindowViewModel.cs` | те же кнопки в WPF, `=` → `PressEqual` |
| — | `REQUIREMENTS.md` | есть только в `projects-main` |

## Выполненные требования

**Будильник.** В окне срабатывания есть кнопка «Отложить»: окно закрывается, будильник срабатывает
снова через 5 минут, звук остаётся включённым. «Я проснулся» и крестик выключают будильник.

**Калькулятор (WinForms и WPF):**

| Кнопка | Действие |
|---|---|
| `,` | десятичная запятая; повторная игнорируется, `,` в начале даёт `0,` |
| `±` | смена знака набираемого числа или результата |
| `←` | удаление последнего введённого символа |
| `π` | число π |
| `x²` | квадрат числа |
| `n!` | факториал целого числа от 0 до 170, иначе `Ошибка` |
| `/` на 0 | `Ошибка` вместо `∞` |

## Готовые exe

Exe всех запускаемых проектов (43 программы: WinForms, WPF, консольные и ASP.NET Core) собираются
автоматически.

Чтобы собирались все проекты, в коде преподавателя исправлена одна ошибка компиляции:
в `Projects.24.1.24.2.25.1/9. Game DB/EF/.../FifteenGame.Wpf/ViewModels/MainWindowViewModel.cs`
метод `IsGameOver` возвращает `bool?`, поэтому условие записано как `IsGameOver(...) ?? false`,
так же как в проекте 10.

### Скачать с GitHub

При каждом push GitHub Actions собирает проекты на Windows (workflow
[`build-exe.yml`](.github/workflows/build-exe.yml)):

1. Вкладка **Actions** → **Сборка exe** → последний зелёный запуск.
2. Внизу страницы, в разделе **Artifacts**, скачать архив **CSharpCollege-exe** и распаковать.
3. Запустить `run.cmd` и выбрать номер проекта (или открыть нужный exe в папке проекта).

Сборку можно запустить и вручную: **Actions** → **Сборка exe** → **Run workflow**.

### Собрать на своём компьютере

Нужна Visual Studio 2022 (или Build Tools) с нагрузкой «Разработка классических приложений .NET».

1. Дважды щёлкнуть `build.cmd` в корне репозитория (или выполнить `.\build.ps1` в PowerShell).
2. Программы появятся в папке `out`, по папке на проект, а меню запуска — в `out\run.cmd`.

Параметры `build.ps1`:

- `-Filter Calculator` — собрать только проекты, в пути к которым есть эта строка;
- `-List` — показать найденные проекты, ничего не собирая.

Веб-проекту `TicTacToe.Web` (.NET 10) нужен [.NET SDK 10](https://dotnet.microsoft.com/download).
Если его нет, проект пропускается, остальные собираются. Его exe самодостаточный:
устанавливать .NET 10 для запуска не нужно. Меню открывает игру в браузере
по адресу `http://localhost:5168`.

### Что не запустится само

- **9. Game DB** — нужен PostgreSQL на `localhost:5432` с базой из строки подключения в
  `App.config` (рядом с exe лежит `<имя>.exe.config`, строку можно поменять там).
- **10. Game Client-Server** — exe клиента собирается, но клиенту нужен запущенный сервер
  (проект `FifteenGame.WebApi` / `WebApi`). Сервер — веб-приложение ASP.NET на .NET Framework,
  exe у него нет: он запускается из Visual Studio (IIS Express).
- **8. Game Web**, проект `FifteenGame.Web` — тоже ASP.NET на .NET Framework, запускается из Visual Studio.

## Как открыть в Visual Studio

Открыть нужный `.sln` (проекты под .NET Framework 4.7.2), например
`CSharpCollege-Master/Projects.24.3.24.4/3. Calculator/Calculator/Calculator.sln`.
