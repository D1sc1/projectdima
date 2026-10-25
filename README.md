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

## Как собрать

Открыть нужный `.sln` в Visual Studio (проекты под .NET Framework 4.7.2), например
`CSharpCollege-Master/Projects.24.3.24.4/3. Calculator/Calculator/Calculator.sln`.
