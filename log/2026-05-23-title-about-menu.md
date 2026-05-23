# 2026-05-23 — Заголовок Notepad++, About menu

## Сделано
- Заголовок окна и scratchpad-режим → "Notepad++" (было "Notepad")
- "Quit Notepad++" в App-меню
- Пункт "About Notepad++" в App-меню — стандартная macOS-панель с версией 1.1.0 и описанием

## Решения
- `NSApp.orderFrontStandardAboutPanel(options:)` — нативная панель, не кастомное окно
- `loadScratchpad()` сбрасывал title обратно на "Notepad" — нашли через grep, исправили

## Следующий шаг
- Закоммитить и запушить на GitHub
