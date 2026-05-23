# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test

```bash
bash build.sh          # сборка + все тесты + копирование ресурсов
open build/Notepad.app # запуск
```

Запуск отдельных тестов:
```bash
./build/test_scratch           # ScratchStore (4 теста, только Foundation)
./build/test_window_controller # NotepadWindowController (9 тестов, AppKit headless)
```

Установка в Applications:
```bash
cp -r build/Notepad.app /Applications/
```

## Архитектура

Приложение **без Xcode-проекта** — собирается через `swiftc` напрямую. Нет `@NSApplicationMain` / `@main` в продакшн-коде — точка входа `main.swift` создаёт `NSApplication` и `AppDelegate` вручную.

**Два режима окна** (`NotepadWindowController`):
- **Scratchpad** — `currentFileURL == nil`, текст автосохраняется в `ScratchStore` при деактивации и завершении
- **File mode** — `currentFileURL != nil`, стандартные save/load, `hasUnsavedChanges` флаг

**Мульти-оконность** (`AppDelegate`):
- `windowControllers: [NotepadWindowController]` — массив всех окон
- `spawnWindow()` — создаёт окно, вешает `NSWindow.willCloseNotification` для удаления из массива
- Первое окно получает `setFrameAutosaveName`, каждое следующее каскадируется на 22pt
- `keyWC` — окно с фокусом, используется для Save / Save As
- `pendingFileURL` — URL файла переданного через Finder до `applicationDidFinishLaunching`

**Ресурсы**: `Resources/Info.plist` и `Resources/AppIcon.icns` — исходники. `build.sh` копирует их в `build/Notepad.app/Contents/`.

## Тесты

Тесты компилируются **без** `main.swift` и `AppDelegate.swift`. `test_window_controller.swift` инициализирует `NSApplication.shared` с `.prohibited` activation policy (headless — окна создаются, но не показываются).

`NotepadWindowController` намеренно не тестирует диалоги (`NSAlert`, `NSSavePanel`, `NSOpenPanel`) — они блокируют headless-среду.
