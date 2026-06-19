FLUTTER := flutter
ADB     := adb

# Pick the first connected Android device dynamically
DEVICE  := $(shell $(ADB) devices -l 2>/dev/null | awk 'NR>1 && /device /{print $$1; exit}')

.PHONY: run run-linux \
        build build-arm64 build-arm32 build-x64 build-x86 build-all build-split \
        build-appbundle install icons splash deps clean help

help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "Run:"
	@echo "  run             Run on connected Android device (auto-detected)"
	@echo "  run-linux       Run on Linux desktop"
	@echo ""
	@echo "Build APK:"
	@echo "  build           APK for arm64-v8a (default, modern devices)"
	@echo "  build-arm64     APK for arm64-v8a"
	@echo "  build-arm32     APK for armeabi-v7a (older Android)"
	@echo "  build-x64       APK for x86_64 (emulators, Chromebooks)"
	@echo "  build-x86       APK for x86 (legacy emulators)"
	@echo "  build-all       Fat APK for arm64 + arm32 + x64"
	@echo "  build-split     Separate APK per ABI"
	@echo "  build-appbundle App Bundle for Play Store"
	@echo ""
	@echo "Other:"
	@echo "  install         Install APK on connected device"
	@echo "  icons           Regenerate launcher icons"
	@echo "  splash          Regenerate splash screen"
	@echo "  deps            flutter pub get"
	@echo "  clean           Clean build cache"

run:
	@if [ -z "$(DEVICE)" ]; then \
		echo "No Android device connected. Connect a device or run: make run-linux"; \
		exit 1; \
	fi
	$(FLUTTER) run -d $(DEVICE)

run-linux:
	$(FLUTTER) run -d linux

build: build-arm64

build-arm64:
	$(FLUTTER) build apk --target-platform android-arm64

build-arm32:
	$(FLUTTER) build apk --target-platform android-arm

build-x64:
	$(FLUTTER) build apk --target-platform android-x64

build-x86:
	$(FLUTTER) build apk --target-platform android-x86

build-all:
	$(FLUTTER) build apk --target-platform android-arm64,android-arm,android-x64

build-split:
	$(FLUTTER) build apk --split-per-abi

build-appbundle:
	$(FLUTTER) build appbundle

install:
	@if [ -z "$(DEVICE)" ]; then \
		echo "No Android device connected."; \
		exit 1; \
	fi
	$(FLUTTER) install -d $(DEVICE)

icons:
	dart run flutter_launcher_icons

splash:
	dart run flutter_native_splash:create

deps:
	$(FLUTTER) pub get

clean:
	$(FLUTTER) clean
	$(FLUTTER) pub get
