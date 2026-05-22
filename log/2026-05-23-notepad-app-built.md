# 2026-05-23 — Notepad.app — нативный macOS-блокнот с нуля

## Контекст

Пользователь получал уведомление от macOS о том, что приложение Notepad+ (аналог Windows Notepad, которым он пользовался) основано на Intel-архитектуре и перестанет работать в будущих версиях macOS. Задача: сделать свою замену до того, как старое приложение сломается.

---

## Что сделали

### 1. Brainstorming (design-first)

Провели структурированный дизайн-сессию через скилл `superpowers:brainstorming`:

- Запустили визуальный companion-сервер (http://localhost:61465) для показа мокапов прямо в браузере
- Определили два сценария использования:
  - **Первичный** — скрэтчпэд: открыл → написал/вставил → закрыл, контент сохраняется сам
  - **Вторичный** — работа с файлом: открыть .txt, редактировать, сохранить
- Выбрали тип приложения: обычное dock-приложение (не menubar, не hotkey-апка)
- Выбрали стек из трёх вариантов (Swift+AppKit / Tauri / Electron): **Swift + AppKit** — нативное, ~1-2MB, autocorrect из коробки, не требует Xcode IDE (только CLI tools, которые уже есть)

### 2. Дизайн-спек

Написали и согласовали спек: `docs/superpowers/specs/2026-05-22-notepad-design.md`

Ключевые решения из спека:
- Всё окно — один `NSScrollView + NSTextView`, никакого лишнего UI
- Два режима в одном окне: **Scratchpad Mode** (title "Notepad") и **File Mode** (title = имя файла)
- Scratchpad хранится в `~/Library/Application Support/Notepad/scratch.txt`
- Сохранение: `applicationWillTerminate`, `windowWillClose`, `NSApplicationDidResignActiveNotification`
- Меню: `⌘N` новый/скрэтчпэд, `⌘O` открыть, `⌘S` сохранить (динамически), `⌘⇧S` сохранить как
- Алерт при несохранённых изменениях: Save / Don't Save / Cancel
- NSTextView: `isRichText = false` (strip форматирования), autocorrect, spellcheck, 16px padding, 14pt

### 3. План реализации

Написали детальный план через скилл `superpowers:writing-plans`:
`docs/superpowers/plans/2026-05-22-notepad-implementation.md`

8 задач, каждая с реальным кодом Swift и командами для проверки.

### 4. Реализация через subagent-driven development

Каждая задача выполнялась свежим субагентом, после чего — два ревью: spec compliance + code quality.

#### Task 1: Project skeleton
- `Resources/Info.plist` — bundle metadata (CFBundleIdentifier, NSHighResolutionCapable, .txt document type)
- `build.sh` — компиляция `swiftc Sources/*.swift -framework AppKit -framework Foundation`, упаковка в `.app` bundle
- `.gitignore` — build/, *.app, .DS_Store
- **Фикс от ревью**: добавили guard на пустой Sources/ в build.sh

#### Task 2: ScratchStore (TDD)
- Написан тест первым, проверили что не компилируется, затем реализация
- `Sources/ScratchStore.swift`: struct с `let url: URL`, `static let shared` (~/Library/Application Support/Notepad/scratch.txt), `load() -> String`, `save(_ text: String)`
- 4 теста: nonexistent file, save+load, overwrite, empty string — все зелёные

#### Task 3: NotepadWindowController
- `Sources/NotepadWindowController.swift`: полная реализация окна
- NSWindow (640×480, min 400×300) + NSScrollView + NSTextView
- NSTextView: `isRichText=false`, autocorrect, spellcheck, 16px padding, 14pt font
- Методы: `loadScratchpad()`, `saveScratchpad()`, `loadFile(url:)`, `saveCurrentFile() -> Bool`, `saveFileAs(url:)`
- `promptForUnsavedChanges()` → enum `.save/.discard/.cancel`
- NSWindowDelegate + NSTextViewDelegate
- **Фиксы от ревью**:
  - `saveFileAs` теперь показывает алерт при ошибке (раньше молча глотала)
  - `loadFile` показывает алерт если файл не открылся (раньше silent return)
  - `textView.minSize` убрали frozen height
  - Добавили `lineFragmentPadding = 0` (убрали лишние 5pt к padding)
  - `windowShouldClose` переписан явно (без двусмысленного делегирования)

#### Task 4: AppDelegate + main menu
- `Sources/AppDelegate.swift`: lifecycle + programmatic меню без XIB
- App menu (Quit), File menu (New/Open/Save/Save As), Edit menu (Undo/Redo/Cut/Copy/Paste/Select All)
- `@objc` action-методы: `newDocument`, `openDocument`, `saveDocument`, `saveDocumentAs`
- `Sources/main.swift`: минимальный entry point (5 строк, без `@main`)
- **Фикс от ревью**: `saveDocument` теперь показывает алерт при ошибке сохранения

#### Tasks 5–7: End-to-end верификация
- Проверили scratchpad persistence через тесты и чтение кода
- Проверили file mode: open/save/save as flow
- Проверили unsaved changes flow: алерты при ⌘N и ⌘W в file mode

#### Task 8: Build + install
- `./build.sh` → `build/Notepad.app` (arm64, ~177KB)
- `xattr -d com.apple.quarantine` — убрали карантин Gatekeeper
- Установлен в `/Applications/Notepad.app`

#### Финальный ревью всей реализации
- **Фикс**: `saveCurrentFile()` теперь показывает алерт при ошибке записи
- **Фикс**: добавили `NSApplicationDidResignActiveNotification` — скрэтчпэд сохраняется при переключении на другое приложение (было в спеке, не было реализовано)

### 5. Фича: toggle autocorrect в меню

По запросу добавили переключатель автозамены:
- В Edit-меню появился пункт **Autocorrect** с галочкой
- Переключает `isAutomaticSpellingCorrectionEnabled` + `isAutomaticQuoteSubstitutionEnabled`
- Состояние сохраняется в `UserDefaults` (ключ `"autocorrect"`, по умолчанию `true`)
- Применяется при запуске из сохранённого значения

---

## Структура проекта на выходе

```
notepad++/
  Sources/
    main.swift                    — entry point (5 строк)
    AppDelegate.swift             — lifecycle, programmatic меню, file actions
    NotepadWindowController.swift — окно, NSTextView, два режима, алерты
    ScratchStore.swift            — чтение/запись scratchpad файла
  Resources/
    Info.plist                    — bundle metadata
  Tests/
    test_scratch_store.swift      — 4 unit теста (TDD)
  docs/superpowers/
    specs/2026-05-22-notepad-design.md
    plans/2026-05-22-notepad-implementation.md
  build.sh                        — компиляция + упаковка .app
  log/
    2026-05-23-notepad-app-built.md  — этот файл
```

---

## Технические решения

| Решение | Почему |
|---------|--------|
| Swift + AppKit вместо Tauri/Electron | Нативный arm64, ~1-2MB, NSTextView даёт autocorrect бесплатно, не нужен Xcode |
| `swiftc` без SPM | Достаточно для 3-4 файлов, не тащим лишний tooling |
| `main.swift` вместо `@main` | Проще и надёжнее при компиляции нескольких файлов через swiftc |
| Два режима в одном окне | Проще, чем NSDocument architecture; скрэтчпэд — primary use case |
| `isRichText = false` | Strip форматирования при вставке — один из главных use cases |
| `atomically: true` в write | Защита от потери данных при краше (temp file + rename) |
| UserDefaults для autocorrect | Достаточно для одной настройки, не нужен отдельный конфиг файл |

---

## Итог

Notepad.app установлен в `/Applications/Notepad.app`. Запускается через Spotlight (`⌘Space → "Notepad"`). Пересборка при изменениях: `cd ~/Work/notepad++ && ./build.sh`.
