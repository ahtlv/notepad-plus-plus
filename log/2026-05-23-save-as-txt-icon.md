# 2026-05-23 — Save As .txt + иконка

## Сделано
- Починил Save As: `allowedContentTypes = [UTType(filenameExtension: "txt")]` — теперь `.txt` добавляется автоматически
- Добавил `CFBundleIconFile` в `Resources/Info.plist` (раньше ключа не было)
- Добавил `AppIcon.icns` в `Resources/` исходников
- Починил `build.sh`: добавил копирование `AppIcon.icns` в бандл (раньше не копировалось — иконка слетала при каждой пересборке)
- Зарегистрировал апп через `lsregister`

## Решения
- `UTType(filenameExtension: "txt")` вместо `.plainText` — потому что `public.plain-text` покрывает много расширений и NSSavePanel не знает какое именно добавить
- Иконку держать в `Resources/` рядом с `Info.plist`, чтобы `build.sh` копировал всё из одного места

## Следующий шаг
- Проверить поведение Save As когда файл уже открыт с именем (должен предлагать его же с `.txt`)
