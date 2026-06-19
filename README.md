# Tabik

A minimalist Android browser that organizes websites into categories with persistent tabbed WebViews.

## Features

- Tabbed browsing — each tab stays alive in memory (no reload on switch)
- Categories — group tabs into named categories, switch from the menu
- Refresh — tap the active tab to reload to its default URL
- Settings — reorder, add, edit, delete categories and tabs
- Theme — light / dark / system

## Build

```
make              # show all targets
make run          # run on connected Android device
make build        # release APK for arm64
make build-split  # separate APK per ABI (arm64, arm32, x64)
make build-appbundle  # App Bundle for Play Store
```

## Package

`net.cheack.tabik`
