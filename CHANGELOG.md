# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-05-23

### Added
- About Notepad++ panel (App menu → About Notepad++)
- Multi-window support — opening a file from Finder or File → Open spawns a new window
- New windows cascade 22pt from the previous one
- Cmd+N opens a new empty window

### Fixed
- Window title now correctly shows "Notepad++" in all states

## [1.1.0] - 2026-05-23

### Added
- Open `.txt` files via double-click in Finder or drag onto app icon
- App icon

### Fixed
- Save As now always appends `.txt` extension and shows it in the dialog field
- App icon registered in `Info.plist` and copied by `build.sh`

## [1.0.0] - 2026-05-22

### Added
- Scratchpad mode — persistent text without a file
- File mode — open, save, save as `.txt` files
- Edit menu with Undo/Redo, Cut/Copy/Paste, Select All
- Autocorrect toggle persisted via UserDefaults
- Unsaved changes prompt on close/new/open
- Auto-save scratchpad on app deactivate and quit
- Native macOS window with scroll, resizable, min size
- Build script — no Xcode project required
