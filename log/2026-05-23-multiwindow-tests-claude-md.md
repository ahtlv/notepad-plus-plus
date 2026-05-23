# 2026-05-23 — Мульти-оконность, тесты, CLAUDE.md

## Сделано
- Мульти-оконность: `windowControllers: [NotepadWindowController]` вместо одного контроллера
- `spawnWindow()` — создаёт окно, удаляет себя при закрытии через `willCloseNotification`
- Первое окно запоминает позицию (`setFrameAutosaveName`), следующие каскадируются на 22pt
- `keyWC` — Save/Save As работают с активным окном
- Cmd+N и File → Open всегда открывают новое окно
- Finder open (`application(_:openFile:)`) всегда открывает новое окно
- 9 новых тестов для `NotepadWindowController` (AppKit headless, `.prohibited` activation policy)
- Тесты прогоняются автоматически в `build.sh`
- `CLAUDE.md` с архитектурой и командами

## Решения
- `setActivationPolicy(.prohibited)` — headless NSApp для тестов без дока и экрана
- Тесты компилируются без `main.swift` и `AppDelegate.swift` — изолируют только NotepadWindowController
- `NSAlert`/`NSSavePanel`/`NSOpenPanel` не тестируем — блокируют headless-среду

## Следующий шаг
- Закоммитить и запушить все изменения на GitHub
