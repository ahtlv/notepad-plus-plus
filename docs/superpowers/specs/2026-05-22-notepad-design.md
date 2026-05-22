# Notepad — Design Spec
**Date:** 2026-05-22  
**Status:** Approved

## Overview

Простая macOS-апка-блокнот на Swift + AppKit, замена Intel-only Notepad+. Apple Silicon native, без Xcode IDE, компилируется через Swift CLI tools.

## Use Cases

**Первичный — скрэтчпэд:**  
Открыл → написал/вставил → закрыл. Контент сохраняется автоматически. Используется как буфер обмена и для strip-форматирования (вставить rich text, скопировать plain).

**Вторичный — работа с файлом:**  
Открыть .txt с диска, отредактировать, сохранить обратно или сохранить в новое место.

## Architecture

### Стек
- **Язык:** Swift 6 (доступен через CLT, без Xcode)
- **UI framework:** AppKit (NSTextView, NSWindow)
- **Сборка:** `swiftc` напрямую + shell-скрипт для упаковки .app bundle

### Файлы
```
notepad++/
  Sources/
    AppDelegate.swift              — точка входа, NSApp setup, главное меню
    NotepadWindowController.swift  — NSWindow + NSScrollView + NSTextView
    ScratchStore.swift             — чтение/запись scratchpad файла
  Resources/
    Info.plist                     — bundle metadata (идентификатор, имя, версия)
  build.sh                         — компиляция + упаковка в Notepad.app
```

### Данные

Scratchpad хранится в `~/Library/Application Support/Notepad/scratch.txt`.  
Загружается при запуске, сохраняется при:
- `applicationWillTerminate`
- `windowWillClose`
- `NSApplicationDidResignActiveNotification` (при сворачивании/переключении)

### Состояния апки

Два режима в рамках одного окна:

| Режим | Title bar | ⌘S |
|-------|-----------|-----|
| Scratchpad | `Notepad` | сохранить как .txt → переходит в File Mode |
| File Mode | `filename.txt` | сохранить в тот же файл |

Переходы:
- `⌘O` → открыть файл → File Mode
- `⌘N` → вернуться в Scratchpad Mode (файл закрывается, scratchpad загружается)
- `⌘S` в Scratchpad → NSSavePanel → если сохранён → File Mode

### Меню (File)
- **New** `⌘N` — вернуться к скрэтчпэду (если File Mode с несохранёнными изменениями → алерт Save/Don't Save/Cancel)
- **Open…** `⌘O` — NSOpenPanel, фильтр .txt
- **Save** `⌘S` — в Scratchpad Mode: показывает NSSavePanel → переходит в File Mode; в File Mode: сохраняет в текущий файл напрямую
- **Save As…** `⌘⇧S` — NSSavePanel всегда (оба режима)
- **Close** `⌘W` — закрыть окно (scratchpad сохранён автоматически; если File Mode с изменениями → алерт)

## UI

- Одно окно, фиксированный минимальный размер 400×300
- Весь контент — `NSScrollView` + `NSTextView`, заполняет окно
- Padding: 16px со всех сторон внутри NSTextView
- Шрифт: system font (SF Pro) 14pt, line height 1.5
- Светлая/тёмная тема: автоматически через NSAppearance (следует системе)
- Нет тулбара, нет статус-бара, нет sidebar

## Текстовый движок (NSTextView)

Включены нативные фичи:
- `isAutomaticSpellingCorrectionEnabled = true`
- `isAutomaticQuoteSubstitutionEnabled = true`
- `isContinuousSpellCheckingEnabled = true`
- `isRichText = false` — только plain text (strip форматирования)

## Сборка и установка

`build.sh` делает:
1. Компилирует все `.swift` из `Sources/` через `swiftc`
2. Создаёт `Notepad.app/Contents/MacOS/` + `Resources/`
3. Копирует бинарник и `Info.plist`
4. Выводит путь к готовому `.app`

Пользователь перетаскивает `Notepad.app` в `/Applications/`.

## Ограничения

- Нет code signing (работает локально, но macOS может попросить разрешение при первом запуске через Gatekeeper — решается через System Settings → Privacy & Security)
- Нет авто-обновлений
- Один файл одновременно (нет вкладок)
