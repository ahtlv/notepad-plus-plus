# Сборка AppIcon.icns из PNG

Исходник: `notepad.png` (минимум 1024×1024 px).

```bash
cd /Users/anatoli/Work/notepad++/icns

mkdir AppIcon.iconset

sips -z 16 16     notepad.png --out AppIcon.iconset/icon_16x16.png
sips -z 32 32     notepad.png --out AppIcon.iconset/icon_16x16@2x.png
sips -z 32 32     notepad.png --out AppIcon.iconset/icon_32x32.png
sips -z 64 64     notepad.png --out AppIcon.iconset/icon_32x32@2x.png
sips -z 128 128   notepad.png --out AppIcon.iconset/icon_128x128.png
sips -z 256 256   notepad.png --out AppIcon.iconset/icon_128x128@2x.png
sips -z 256 256   notepad.png --out AppIcon.iconset/icon_256x256.png
sips -z 512 512   notepad.png --out AppIcon.iconset/icon_256x256@2x.png
sips -z 512 512   notepad.png --out AppIcon.iconset/icon_512x512.png
cp notepad.png    AppIcon.iconset/icon_512x512@2x.png

iconutil -c icns AppIcon.iconset
```

Готовый `AppIcon.icns` появится рядом. Скопируй его в `Resources/` и пересобери приложение:

```bash
cp AppIcon.icns ../Resources/AppIcon.icns
cd .. && bash build.sh
```
