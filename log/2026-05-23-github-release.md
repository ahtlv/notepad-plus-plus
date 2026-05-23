# 2026-05-23 — GitHub релиз + open from Finder

## Сделано
- Починил краш при открытии файла из Finder: `pendingFileURL` паттерн — сохраняем URL до инициализации windowController
- Создан публичный репозиторий https://github.com/ahtlv/notepad-plus-plus
- README: описание, скриншот, требования, инструкция сборки, шорткаты
- CHANGELOG по стандарту Keep a Changelog
- LICENSE (MIT)
- Теги v1.0.0 и v1.1.0
- icns/README.md — инструкция сборки .icns из .png через sips + iconutil

## Решения
- `pendingFileURL: URL?` в AppDelegate — macOS вызывает `openFile` до `applicationDidFinishLaunching`, нужно отложить загрузку
- Репо назван `notepad-plus-plus` (GitHub не принимает `++` в названии)

## Следующий шаг
- Проверить edge cases: открыть файл когда апп уже запущен с другим файлом
- Возможно: recent files menu
