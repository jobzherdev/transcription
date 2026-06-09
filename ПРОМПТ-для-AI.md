# Утилита «Извлечь аудио» — спецификация для AI

> **Как пользоваться этим файлом:** скопируй всё содержимое целиком и отправь любому
> современному LLM (Claude, ChatGPT, Gemini, Copilot и т.п.) с просьбой:
> *«Реализуй это под Windows. Выбери стек на своё усмотрение. Дай мне готовые файлы
> + короткую инструкцию по установке».*
>
> AI прочитает спецификацию и сам решит — делать через интеграцию в контекстное меню
> Эксплорера, через standalone-приложение или комбинированно. Спецификация описывает
> поведение и контракты, не реализацию.

---

## 1. Что нужно построить

Утилита для Windows, которая **одним действием пользователя** извлекает аудио из
видеофайла в `.mp3`-формат, оптимизированный для **распознавания речи** (STT —
Whisper, GPT-4o transcribe, Yandex SpeechKit и т.п.).

Пользователь не должен:
- запускать ffmpeg вручную из терминала;
- помнить параметры `-vn -ac 1 -ar 16000 -b:a 48k`;
- разбираться с UI настройками;
- ждать длинных модальных окон с кнопкой «OK».

Пользователь должен:
- выбрать видеофайл (одним способом — см. §3 ниже, AI выбирает);
- получить рядом `.mp3` с правильными параметрами через несколько секунд;
- увидеть прогресс конвертации (не догадываться, идёт ли процесс);
- быть уверен что mp3 либо готов целиком, либо явно помечен как «не готов»
  (защита от подачи частичного файла в STT — см. §5).

---

## 2. Жёсткий контракт формата выхода (НЕ менять)

```
Контейнер:   mp3
Каналы:      mono (1)
Sample rate: 16000 Hz
Битрейт:     48 kbps CBR
Видео:       отбрасывается (-vn)
```

ffmpeg-команда (или эквивалент):
```
ffmpeg -i <input> -vn -ac 1 -ar 16000 -b:a 48k -y <output>
```

Размер результата: ~360 KB на минуту. Часовое видео → ~21 MB.

Почему именно эти параметры:
- **mono** — STT-модели не используют стерео-информацию для речи, экономит размер
- **16 kHz** — частотный диапазон речи укладывается в 8 kHz, по Найквисту 16 kHz хватает
- **48 kbps** — порог разборчивости голоса для STT, ниже = артефакты сжатия мешают

---

## 3. Триггер запуска (AI выбирает один или комбинацию)

**Вариант A — Контекстное меню Эксплорера** (рекомендуется как основной):
- Правый клик по видеофайлу в Проводнике → пункт «Извлечь аудио».
- Регистрация в `HKCU\Software\Classes\SystemFileAssociations\<ext>\shell\...`
  для расширений: `.mp4`, `.mkv`, `.mov`, `.webm`, `.avi`, `.m4v`, `.flv`, `.ts`,
  `.wmv`, `.mpg`, `.mpeg`.
- Иконка пункта меню — значок «звук» (`mmcndmgr.dll,30` или подобный системный).

**Вариант B — Standalone-приложение**:
- Иконка на рабочем столе / в Старт-меню.
- При запуске показывает диалог выбора файла (один файл за раз) или принимает
  drag-and-drop.
- Можно дополнительно зарегистрировать в `AppPaths` чтобы запускать по имени из Win+R.

**AI решает:** A, или B, или оба варианта параллельно. Если делать только один — лучше A
(меньше кликов в типичном сценарии).

**MUST:** установка БЕЗ admin-прав и без UAC-промпта (для меню — `HKCU`, не `HKLM`).

**MUST NOT:** требовать ручного дополнения PATH, ручной правки реестра пользователем,
открывания командной строки. Установщик делает всё сам.

---

## 4. UX во время извлечения

**MUST: показывать прогресс-индикатор.** Конкретно:
- Полупрозрачное окно (~85-90% непрозрачности) по центру экрана.
- Тёмный фон, скруглённые углы, **без рамки и заголовка**.
- Содержимое: заголовок «Извлечение аудио», имя обрабатываемого файла,
  прогресс-бар, процент.
- Окно поверх всех (Topmost), не в Taskbar, **не крадёт фокус** (пользователь
  продолжает печатать в текущем окне).
- Прогресс вычисляется из `out_time_us` ffmpeg (опция `-progress <file>` пишет
  ключ=значение в файл, парсить в реальном времени) / общая длительность видео
  (получить через `ffprobe` или `ffmpeg -i` парсинг строки `Duration`).
- Пока длительность не получена — `IsIndeterminate` (бегущая полоска).

**MUST: окно автоматически закрывается** по завершении ffmpeg. Никаких кнопок
«OK» / «Готово» — пользователь видит появление `.mp3` в папке.

**MUST NOT: модальные диалоги** (MessageBox, OpenFileDialog для подтверждения
завершения, и т.п.). Только один non-modal popup на время работы.

**MUST: при закрытии popup пользователем вручную** (Alt+F4) — ffmpeg-процесс
останавливается, но артефакт остаётся помеченным как «не готов» (см. §5).

**MUST NOT: вспышка CMD-окна** при запуске. Если стек требует невидимого запуска
скрипта — использовать silent-обёртку (VBS, .scr-helper, либо native-приложение
без console subsystem).

---

## 5. Безопасность артефакта — `INCOMPLETE_` префикс

**Зачем:** пользователь часто скармливает mp3 в STT сразу после появления файла.
Если процесс прерван (kill, выключили питание) — на диске останется частично
записанный mp3. ffmpeg пишет потоком, частичный файл **валиден по формату** (можно
открыть, проиграть), но обрезан по содержанию. STT молча примет его и вернёт
неполный/мусорный транскрипт. Нужна **видимая** защита.

**Алгоритм:**

1. Определить финальное имя (`<имя>.mp3`, при коллизии — `<имя> (2).mp3`,
   `<имя> (3).mp3`...).
2. ffmpeg пишет в **`INCOMPLETE_<финальное_имя>.mp3`** в той же папке.
3. По успешному exit-коду ffmpeg — переименовать (rename / move) в финальное имя.
   Операция атомарна в пределах одного диска.
4. Если ffmpeg завершился с ошибкой (битый input, IO-сбой) — удалить `INCOMPLETE_`-файл,
   причину записать в лог.
5. Если ffmpeg был убит (пользователь закрыл popup, выключение системы) — оставить
   `INCOMPLETE_`-файл как есть. Пользователь увидит «не готово» по имени.

**Различение ошибки vs kill:**
- Реальная ошибка ffmpeg → stderr не пустой (содержит причину).
- Kill → stderr пустой, exit-code ≠ 0.

```
isKilled = (stderr пустой) AND (exitCode ≠ 0)
```

**MUST:** проверка коллизии имён — на ФИНАЛЬНОМ имени, ДО добавления `INCOMPLETE_`
префикса. Иначе при параллельных запусках получим коллизию между двумя
`INCOMPLETE_<тот же_файл>.mp3`.

---

## 6. Расположение результата

- Та же папка, где исходное видео.
- Имя: `<имя_видео_без_расширения>.mp3`.
- Коллизия: `<имя> (2).mp3`, `<имя> (3).mp3`, ...
- Исходное видео **не трогается** (только чтение).

---

## 7. Зависимости

- **ffmpeg.exe** — bundled (положить рядом со скриптом / в папку приложения).
  НЕ требовать у пользователя добавлять ffmpeg в PATH. Версия — любая ≥ 4.x,
  скачать с https://www.gyan.dev/ffmpeg/builds/ (essentials build, ~96 MB).
- **Windows 10/11.** PowerShell 5.1+ (встроен) либо .NET 4.7+ либо Python 3.11+
  через PyInstaller — на выбор AI.

---

## 8. Логирование

**MUST:** все события (успех, ошибка, ffmpeg stderr при ошибке) записываются в лог-файл:
- Расположение: рядом с приложением, в подпапке `логи/` или эквивалент.
- Формат строки: `[YYYY-MM-DD HH:mm:ss] <input> -> <output> | <duration>s | <status>`.
- Ротация: при размере >10 MB переименовать в `.log.old`, начать новый.
- Кодировка лога: **UTF-8** (явно указать в API записи — на Windows default часто ANSI).

---

## 9. Установка / удаление

**MUST: установка/удаление без admin-прав.**
- `install.cmd` или `install.exe` — регистрирует контекстное меню в `HKCU` (см. §3).
- `uninstall.cmd` или `uninstall.exe` — удаляет ключи. Файлы утилиты остаются на диске
  (пользователь удаляет руками или скрипт делает это явно по запросу).
- Поведение при переносе папки: пути в реестре абсолютные, поэтому перенос **ломает**
  работу. README/инструкция должна предупреждать.

---

## 10. Что НЕ делаем (out of scope)

- ❌ Batch-режим (обработка нескольких файлов за раз). Только один файл = один запуск.
- ❌ Окно настроек / диалог выбора формата. Формат фиксирован (см. §2).
- ❌ Другие форматы выхода — только mp3 с указанными параметрами.
- ❌ Передача файла в STT-сервис автоматически — это отдельная утилита, не наша.
- ❌ Запоминание истории обработанных файлов, undo, повторное извлечение.
- ❌ Любая телеметрия / отправка данных наружу.

---

## 11. Acceptance / Definition of Done

- [ ] После установки правый клик по `.mp4`/`.mkv`/`.mov`/`.webm`/`.avi`/`.m4v`/`.flv`/`.ts`/`.wmv`/`.mpg`/`.mpeg`
      показывает пункт «Извлечь аудио» (если выбран Вариант A — §3).
- [ ] Клик / запуск → появляется полупрозрачное окно с прогрессом и именем файла.
- [ ] Прогресс растёт по мере конвертации (или indeterminate если длительность
      ещё не получена).
- [ ] По завершении окно исчезает само, в той же папке появляется `.mp3`.
- [ ] Параметры результирующего mp3 (проверить через `ffprobe`):
      `channels = 1`, `sample_rate = 16000`, `bit_rate ≈ 48000`.
- [ ] Во время конвертации файл существует как `INCOMPLETE_<имя>.mp3`, по успеху
      переименовывается в `<имя>.mp3`.
- [ ] Если убить процесс (kill из Task Manager или закрыть popup) — `INCOMPLETE_` остаётся.
- [ ] Если подсунуть битый видеофайл — `INCOMPLETE_` удаляется, причина в логе,
      никаких modal-окон с «Failed».
- [ ] Коллизия имён — суффикс `(2)`, `(3)` корректно работает.
- [ ] `install.cmd` / установщик работает без admin / UAC.
- [ ] Нет вспышки CMD-окна при срабатывании из контекстного меню.

---

## 12. Технические капканы (экономия времени AI)

**Этот раздел — гарантированная экономия часов отладки.** Прочитай ВНИМАТЕЛЬНО,
если выбираешь стек из списка ниже.

### Если выбираешь PowerShell 5.1 (встроенный powershell.exe, не pwsh 7+)

Windows PowerShell 5.1 имеет несколько критичных багов на путях с кириллицей и
запуске native exe. Все обходятся, но молча и подло. Чек-лист:

- **MUST: `.ps1` с кириллицей в литералах сохранять как UTF-8 with BOM.**
  Без BOM PS 5.1 читает файл как ANSI/CP1251 (в русской локали) → литералы вида
  `'логи'` становятся мусором `'Р»РѕРіРё'` → пути ломаются → тихий exit 1 без понятной
  ошибки. **Первый байт файла должен быть `0xEF 0xBB 0xBF`.** Многие редакторы (VS Code,
  notepad++) пишут UTF-8 БЕЗ BOM по умолчанию.

- **MUST: `Add-Content` / `Set-Content` / `Out-File` с не-ASCII payload — явно
  `-Encoding UTF8`.** Default = ANSI. Если пишешь лог без `-Encoding UTF8` — содержимое
  пишется в CP1251 и при чтении выглядит как мусор. Это **маскирует корректные данные**
  как поломанные и уводит диагностику не туда.

- **MUST: для async-запуска native exe (нужен exitcode или пути с пробелами) — использовать
  `System.Diagnostics.Process` напрямую, НЕ `Start-Process -PassThru`.**
  Причины:
  - `Start-Process -PassThru.ExitCode` — всегда `$null` даже после `WaitForExit()`.
  - `Start-Process -ArgumentList @('-i', 'path with space')` — массив join'ится через
    `' '` без re-quoting → путь с пробелом разбивается на два аргумента.
  Канонический паттерн:
  ```powershell
  function Q([string]$s) { if ($s -match '[\s"]') { '"' + ($s -replace '"','\"') + '"' } else { $s } }
  $argString = @('-i', (Q $input), '-y', (Q $output)) -join ' '
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $exe; $psi.Arguments = $argString
  $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
  $psi.RedirectStandardError = $true
  $proc = New-Object System.Diagnostics.Process
  $proc.StartInfo = $psi
  [void]$proc.Start()
  $stderrTask = $proc.StandardError.ReadToEndAsync()   # async без event handler!
  $proc.WaitForExit()
  $exitCode = $proc.ExitCode                            # теперь работает
  $stderr   = [string]$stderrTask.Result
  ```

- **MUST NOT: `.add_EventName({...})` на .NET-объектах для async-событий**
  (`Process.ErrorDataReceived`, `Process.Exited` с `EnableRaisingEvents`).
  Они срабатывают на ThreadPool-потоке без Runspace → unhandled
  `PSInvalidOperationException: There is no Runspace available to run scripts in this thread`
  → крашит весь PS-процесс. Используй Task-based async (`ReadToEndAsync`) или
  `Register-ObjectEvent`. WPF `DispatcherTimer.add_Tick({...})` — ОК, это UI-поток.

### Если используешь VBScript

- **MUST: для чтения UTF-8 файлов — `ADODB.Stream` с `Charset = "utf-8"`,
  НЕ `FileSystemObject.OpenTextFile`.** FSO ANSI-only. Без этого на UTF-8-trigger
  или config-файле с кириллицей получишь mojibake.
- **MAY: `WScript.Shell.Run cmd, 0, False`** — это правильный способ запускать
  PowerShell скрытно из VBS. `0` = hidden, `False` = fire-and-forget. Под капотом
  CreateProcessW — Unicode-safe.

### Если используешь Lua (например в OBS-скрипте) на Windows

- **MUST: использовать LuaJIT FFI на `_wsystem` и `_wfopen` вместо `os.execute` /
  `io.open` для путей с не-ASCII.** Lua stdlib проходит через C stdlib с ANSI codepage
  — UTF-8 байты пути реинтерпретируются как CP1251 → mojibake → не находит файл.
  Workaround:
  ```lua
  local ffi = require("ffi")
  ffi.cdef[[
      int _wsystem(const wchar_t *command);
      void *_wfopen(const wchar_t *path, const wchar_t *mode);
      int MultiByteToWideChar(unsigned int CP, unsigned long flags, const char *str, int slen, wchar_t *out, int outlen);
  ]]
  -- Конвертация UTF-8 → UTF-16 через MultiByteToWideChar(65001, ...), потом _wsystem(wcmd)
  ```

### Если используешь .bat / .cmd файлы

- **MUST NOT: Unicode/кириллица в `.bat`/`.cmd` содержимом.** Только ASCII.
  cmd.exe парсит .bat в OEM-codepage (CP866 в RU). UTF-8 кириллица в литералах
  → мусор. Если нужно сослаться на путь с кириллицей — вычислить путь в runtime
  через PowerShell (`%~dp0` + `Get-ChildItem -Recurse -Filter '...'`).

### Контекстное меню Эксплорера

- **HKCU vs HKLM:** `HKCU\Software\Classes\SystemFileAssociations\<ext>\shell\<MyVerb>\command`
  — без admin, без UAC. `HKLM` требует admin. Для one-user утилиты — HKCU достаточно.
- **Структура ключа:**
  ```
  HKCU\Software\Classes\SystemFileAssociations\.mp4\shell\ExtractAudio
    (default)   = "Извлечь аудио"           (REG_SZ — текст пункта)
    Icon        = "%SystemRoot%\System32\mmcndmgr.dll,30"
    \command
      (default) = "wscript.exe \"<path>\\silent-wrapper.vbs\" \"%1\""
  ```
- `%1` — Explorer подставит путь к файлу. Кавычки обязательны (на путях с пробелами).
- Без перезапуска Explorer'а пункт меню обычно подхватывается сразу.

### ffmpeg с прогрессом

- `-progress <file>` пишет в указанный файл строки `ключ=значение`.
- Парсить `out_time_us=N` (микросекунды от начала). Делить на общую длительность.
- Общая длительность — из `ffmpeg -i <input>` (парсить stderr `Duration: HH:MM:SS.MS`)
  или `ffprobe -v quiet -show_entries format=duration -of default=nw=1:nk=1 <input>`.

---

## 13. Опциональные подсказки (можно игнорировать, можно использовать)

Эти решения подтверждённо рабочие на стеке PowerShell 5.1 + VBS + WPF
+ HKCU + bundled ffmpeg. AI может взять как референс или сделать иначе.

### Цепочка вызовов в проверенном стеке

```
Эксплорер (правый клик)
  └─ HKCU реестр → wscript.exe silent-wrapper.vbs <video>
       └─ VBS: WScript.Shell.Run "powershell.exe -WindowStyle Hidden -File main.ps1 <video>", 0, False
            └─ PowerShell main.ps1:
                  - Поиск ffmpeg (bundled рядом со скриптом)
                  - Получение длительности через "ffmpeg -i" парсинг stderr
                  - Определение финального имени + INCOMPLETE_ префикс
                  - Создание WPF-окна (XAML с WindowStyle=None, AllowsTransparency)
                  - Запуск ffmpeg через System.Diagnostics.Process с -progress в temp-файл
                  - DispatcherTimer (200мс) парсит temp-файл, обновляет ProgressBar
                  - По proc.HasExited → закрыть окно
                  - Move-Item INCOMPLETE_ → финальное имя (если успех)
                  - Лог
```

### XAML для popup

```xml
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        WindowStyle="None"
        AllowsTransparency="True"
        Background="Transparent"
        Topmost="True"
        ShowInTaskbar="False"
        ShowActivated="False"
        WindowStartupLocation="CenterScreen"
        SizeToContent="Height"
        Width="460">
    <Border CornerRadius="12" Background="#E6202020" Padding="20"
            BorderBrush="#40FFFFFF" BorderThickness="1">
        <StackPanel>
            <TextBlock Text="Извлечение аудио" Foreground="White"
                       FontSize="14" FontWeight="SemiBold"/>
            <TextBlock x:Name="txtFile" Foreground="#CCCCCC" FontSize="11"
                       TextTrimming="CharacterEllipsis" Margin="0,4,0,12"/>
            <ProgressBar x:Name="pbar" Height="14" Minimum="0" Maximum="100"
                         Value="0" IsIndeterminate="True"
                         Foreground="#4FC3F7" Background="#33000000"
                         BorderThickness="0"/>
            <TextBlock x:Name="txtPct" Foreground="#AAAAAA" FontSize="10"
                       HorizontalAlignment="Right" Margin="0,6,0,0"/>
        </StackPanel>
    </Border>
</Window>
```

### Альтернативные стеки которые тоже могут работать

- **Python 3.11+ packaged via PyInstaller** — единый `.exe`. Прогресс через
  `subprocess.Popen` + `tkinter` или `PySide6` popup. Меньше PS 5.1 капканов, но
  один-exe ~30-40 MB.
- **C# / .NET 8 single-file exe** — нативный WPF, нативная установка контекстного
  меню через `Microsoft.Win32` API. Профи-выбор, но сборка требует .NET SDK.
- **Rust** — крошечный exe (~2 MB), но WPF недоступен; для popup использовать
  `winit` + `wgpu` или `egui`. Сложнее но самый чистый.

Выбирай по тому что лучше знаешь / что попросит пользователь. Все три проходят
DoD из §11.

---

## 14. Финальное напутствие для AI

Когда покажешь готовые файлы пользователю — добавь короткую инструкцию (3-5 шагов)
как установить, проверить и удалить. Если что-то на машине пользователя пойдёт
не так — попроси его прислать содержимое лог-файла (см. §8), не «скриншот ошибки».

Удачи. Спецификация написана прямой пользой — без воды.
