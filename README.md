[![Tag build](https://github.com/jochumdev/letscheck/actions/workflows/tag.yml/badge.svg)](https://github.com/jochumdev/letscheck/actions/workflows/tag.yml)

> **Note:** This is a fork of the original [LetsCheck](https://github.com/jochumdev/letscheck) project with additional features and improvements.

## 🚀 Enhanced Features

This fork includes the following enhancements:

### 1. **Host Alias Display Throughout App** 🎯
- Host alias now displays before hostname in all views and notifications
- Format: "ALIAS - HOSTNAME" with fallback to just hostname
- Applied to: host cards, service group headers, host screen titles, and notification titles
- Smart fallback: alias → displayName → hostname hierarchy

### 2. **Fixed Linux/GNOME Notifications** 🔔
- Enhanced notification display with proper formatting
- Removes cache information from notification messages
- Adds spacing before state abbreviations (CRIT, WARN, OK, UNKN)
- Improved GNOME desktop integration and background service stability

### 3. **Added Top Bar and Minimize Behavior** 🖥️
- Restored application top bar for better navigation
- X button now minimizes to system tray instead of exiting
- Application continues running in background when minimized
- Better desktop integration for long-running monitoring

---

# LetsCheck

LetsCheck is a Checkmk client for Android, iOS, Linux, Mac OS-X and Windows written with the [Flutter SDK](https://flutter.dev/).

[Checkmk](https://checkmk.com/) is a leading tool for Infrastructure and Application Monitoring. Simple configuration, scalable, flexible. Open Source and Enterprise.

## Features

- View Hosts/Services with comments
- Notifications
- Search Hosts/Services, use the | symbol to seperated multiple searches

## 📦 Building from Source

**Note:** This fork does not provide pre-built packages. You'll need to build the application yourself.

### Prerequisites
- Flutter SDK (3.19+ recommended)
- Dart SDK
- Platform-specific build tools (for Linux: gcc, cmake, ninja, etc.)

### Build Instructions

#### Linux Build
```bash
flutter build linux --release
```

**Important:** After building, you need to fix a misplaced library file:

```bash
# Create symlink for the misplaced library
ln -sf ../../../plugins/flutter_js/bundle/lib/libquickjs_c_bridge_plugin.so \
   build/linux/x64/release/bundle/lib/libquickjs_c_bridge_plugin.so
```

This resolves an issue where the flutter_js plugin library is placed in the wrong directory during the build process.

#### Other Platforms
```bash
# Android
flutter build apk --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release
```

### Running the Built Application

**Linux:**
```bash
./build/linux/x64/release/bundle/letscheck
```

**Windows:**
```bash
.\build\windows\x64\runner\Release\letscheck.exe
```

## Intodruction and new release notes

See the [Checkmk forums](https://forum.checkmk.com/t/letscheck-a-checkmk-client-with-notifications-for-mobile-and-desktop/52088)

## Download

Get it from [Github Releases](https://github.com/jochumdev/letscheck/releases)

## Demo:

![image](docs/videos/letscheck_v0.0.1-rc1.webp)

## FAQ

The “Frequently asked questions” page is available on the [Github WIKI](https://github.com/jochumdev/letscheck/wiki/FAQ).

## Development

**Commit**:

```
git add ./file1 ./file2
./scripts/commit_fix.sh "a bug in component x"
```

**Release**:

- Create changelog, tag and push it
  ```
  ./scripts/release.sh "0.0.99+9763"
  ```
- Create a release on Github
- Wait for Github Actions to publish binaries

## Authors

- [@jochumdev](https://github.com/jochumdev)

## License

Apache 2.0 - Copyright 2025 by [@jochumdev](https://github.com/jochumdev)
