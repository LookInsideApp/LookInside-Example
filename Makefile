# LookInsideExample build automation

SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -c

# =============================================================================
# Configuration
# =============================================================================

ROOT_DIR        := $(shell pwd)
PROJECT         := $(ROOT_DIR)/LookInsideExample.xcodeproj
SCHEME          := LookInsideExample
APP_NAME        := LookInsideExample
UIKIT_SCHEME    := LookInsideExampleUIKit
UIKIT_APP_NAME  := LookInsideExampleUIKit
APPKIT_SCHEME   := LookInsideExampleAppKit
APPKIT_APP_NAME := LookInsideExampleAppKit
TV_SCHEME       := LookInsideExampleTV
TV_APP_NAME     := LookInsideExampleTV
TV_UIKIT_SCHEME   := LookInsideExampleTVUIKit
TV_UIKIT_APP_NAME := LookInsideExampleTVUIKit
WATCH_SCHEME      := LookInsideExampleWatch
WATCH_APP_NAME    := LookInsideExampleWatch
WATCHKIT_SCHEME   := LookInsideExampleWatchKit
WATCHKIT_APP_NAME := LookInsideExampleWatchKit
CONFIGURATION   := Debug
TUIST           ?= tuist
DERIVED_DATA   ?= /private/tmp/lookinside-example-deriveddata
BUILD_HOME      = $(DERIVED_DATA)/home
XDG_CACHE_HOME  = $(DERIVED_DATA)/xdg-cache
MODULE_CACHE    = $(DERIVED_DATA)/ModuleCache.noindex
DEVELOPMENT_TEAM ?=
LOOKINSIDE_SERVER_PATH ?=

SIM_DESTINATION    := generic/platform=iOS Simulator
DEVICE_DESTINATION := generic/platform=iOS
MAC_DESTINATION    := generic/platform=macOS
TV_SIM_DESTINATION := generic/platform=tvOS Simulator
WATCH_SIM_DESTINATION := generic/platform=watchOS Simulator

SIMULATOR_NAME     ?= iPhone 16
SIMULATOR_UDID     = ${shell xcrun simctl list devices available | sed -nE 's/^[[:space:]]*$(SIMULATOR_NAME)( \([^)]*\))? \(([A-F0-9-]+)\).*/\2/p' | head -1}
BUNDLE_ID          := app.lookinside.example
UIKIT_BUNDLE_ID    := app.lookinside.example.uikit

# Apple TV simulator names carry parentheses, which a regular expression
# would read as groups, so the name is compared as plain text. Xcode creates
# several devices with the default name; a booted one wins.
TV_SIMULATOR_NAME  ?= Apple TV 4K (4th generation)
TV_SIMULATOR_UDID  = ${shell xcrun simctl list -j devices available | /usr/bin/python3 -c 'import json, sys; devices = [device for runtime_devices in json.load(sys.stdin)["devices"].values() for device in runtime_devices]; print(next((device["udid"] for device in sorted(devices, key=lambda device: device["state"] != "Booted") if device["name"] == sys.argv[1]), ""))' '$(TV_SIMULATOR_NAME)'}
TV_BUNDLE_ID       := app.lookinside.example.tv
TV_UIKIT_BUNDLE_ID := app.lookinside.example.tv.uikit

# Apple Watch simulator names carry parentheses too; same lookup as above.
WATCH_SIMULATOR_NAME ?= Apple Watch Series 12 (46mm)
WATCH_SIMULATOR_UDID  = ${shell xcrun simctl list -j devices available | /usr/bin/python3 -c 'import json, sys; devices = [device for runtime_devices in json.load(sys.stdin)["devices"].values() for device in runtime_devices]; print(next((device["udid"] for device in sorted(devices, key=lambda device: device["state"] != "Booted") if device["name"] == sys.argv[1]), ""))' '$(WATCH_SIMULATOR_NAME)'}
WATCH_BUNDLE_ID      := app.lookinside.example.watch
WATCHKIT_BUNDLE_ID   := app.lookinside.example.watchkit

SWIFTFORMAT_EXCLUDES := build,.build,DerivedData

XCODEBUILD := xcodebuild \
    -project "$(PROJECT)" \
    -configuration $(CONFIGURATION) \
    -derivedDataPath "$(DERIVED_DATA)" \
    -skipMacroValidation \
    -skipPackagePluginValidation

# Simulator needs an ad-hoc signature ("-") to launch on iOS 14+.
# Real-device builds stay unsigned.
SIM_SIGN_FLAGS    := CODE_SIGNING_ALLOWED=YES CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM=$(DEVELOPMENT_TEAM)
DEVICE_SIGN_FLAGS := CODE_SIGNING_ALLOWED=NO  CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=""
MAC_SIGN_FLAGS    := CODE_SIGNING_ALLOWED=YES CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM=$(DEVELOPMENT_TEAM)

.PHONY: all help \
        generate server-watch-framework \
        build build-sim build-device build-mac build-uikit build-appkit build-tv build-tv-uikit build-watch build-watchkit build-all \
        run boot install launch run-mac \
        run-uikit install-uikit launch-uikit run-appkit \
        boot-tv run-tv install-tv launch-tv run-tv-uikit install-tv-uikit launch-tv-uikit \
        boot-watch run-watch install-watch launch-watch run-watchkit install-watchkit launch-watchkit \
        format format-lint \
        clean

# =============================================================================
# Meta
# =============================================================================

all: build-sim

help:
	@echo "Project generation:"
	@echo "  generate           Regenerate $(PROJECT) with Tuist"
	@echo "  server-watch-framework  Package the local server's watchOS Simulator slice"
	@echo "                     (needs LOOKINSIDE_SERVER_PATH); run generate afterwards"
	@echo ""
	@echo "Build (SwiftUI app):"
	@echo "  build              Alias for build-sim"
	@echo "  build-sim          Build for iOS Simulator (generic)"
	@echo "  build-device       Build for iOS device (generic, unsigned)"
	@echo "  build-mac          Build for Mac"
	@echo ""
	@echo "Build (native apps):"
	@echo "  build-uikit        Build the pure-UIKit iOS app for the Simulator"
	@echo "  build-appkit       Build the pure-AppKit macOS app"
	@echo ""
	@echo "Build (Apple TV apps):"
	@echo "  build-tv           Build the SwiftUI tvOS app for the Simulator"
	@echo "  build-tv-uikit     Build the pure-UIKit tvOS app for the Simulator"
	@echo ""
	@echo "Build (Apple Watch apps):"
	@echo "  build-watch        Build the SwiftUI watchOS app for the Simulator"
	@echo "  build-watchkit     Build the WatchKit storyboard app for the Simulator"
	@echo ""
	@echo "  build-all          Build all seven apps"
	@echo ""
	@echo "Run:"
	@echo "  run                Boot \$$(SIMULATOR_NAME), install, and launch the SwiftUI app"
	@echo "  run-mac            Build and launch the SwiftUI app on this Mac"
	@echo "  run-uikit          Boot \$$(SIMULATOR_NAME), install, and launch the UIKit app"
	@echo "  run-appkit         Build and launch the AppKit app on this Mac"
	@echo "  run-tv             Boot \$$(TV_SIMULATOR_NAME), install, and launch the SwiftUI tvOS app"
	@echo "  run-tv-uikit       Boot \$$(TV_SIMULATOR_NAME), install, and launch the UIKit tvOS app"
	@echo "  run-watch          Boot \$$(WATCH_SIMULATOR_NAME), install, and launch the SwiftUI watchOS app"
	@echo "  run-watchkit       Boot \$$(WATCH_SIMULATOR_NAME), install, and launch the WatchKit app"
	@echo "  boot               Boot \$$(SIMULATOR_NAME) (no-op if already booted)"
	@echo "  boot-tv            Boot \$$(TV_SIMULATOR_NAME) (no-op if already booted)"
	@echo "  boot-watch         Boot \$$(WATCH_SIMULATOR_NAME) (no-op if already booted)"
	@echo "  install            Install the built SwiftUI app onto the booted simulator"
	@echo "  launch             Launch the installed SwiftUI app on the booted simulator"
	@echo ""
	@echo "Formatting:"
	@echo "  format             Run swiftformat (write)"
	@echo "  format-lint        Run swiftformat in check mode"
	@echo ""
	@echo "Housekeeping:"
	@echo "  clean              Remove derived data"
	@echo ""
	@echo "Variables:"
	@echo "  SIMULATOR_NAME     Simulator device name (default: iPhone 16)"
	@echo "  SIMULATOR_UDID     Simulator UDID resolved from SIMULATOR_NAME"
	@echo "  TV_SIMULATOR_NAME  Apple TV simulator name (default: Apple TV 4K (4th generation))"
	@echo "  TV_SIMULATOR_UDID  Simulator UDID resolved from TV_SIMULATOR_NAME"
	@echo "  WATCH_SIMULATOR_NAME Apple Watch simulator name (default: Apple Watch Series 12 (46mm))"
	@echo "  WATCH_SIMULATOR_UDID Simulator UDID resolved from WATCH_SIMULATOR_NAME"
	@echo "  LOOKINSIDE_SERVER_PATH Optional local server package path for Tuist generation"
	@echo "  DERIVED_DATA       Derived data path (default: /private/tmp/lookinside-example-deriveddata)"

generate:
	TUIST_LOOKINSIDE_SERVER_PATH="$(LOOKINSIDE_SERVER_PATH)" $(TUIST) generate --no-open

# The watch apps cannot compile a local server from source (the watchOS SDK
# marks UIKit unavailable), so they link the XCFramework the server's own
# packaging script builds against an unlocked copy of the SDK.
server-watch-framework:
	@if [ -z "$(LOOKINSIDE_SERVER_PATH)" ]; then echo "Set LOOKINSIDE_SERVER_PATH to a LookInside-Server checkout." >&2; exit 1; fi
	PLATFORMS=watchsimulator SKIP_ZIP=1 "$(LOOKINSIDE_SERVER_PATH)/Scripts/package-xcframework.sh"

build: build-sim

build-sim:
	mkdir -p "$(BUILD_HOME)" "$(XDG_CACHE_HOME)" "$(MODULE_CACHE)"
	HOME="$(BUILD_HOME)" XDG_CACHE_HOME="$(XDG_CACHE_HOME)" CLANG_MODULE_CACHE_PATH="$(MODULE_CACHE)" SWIFTPM_MODULECACHE_OVERRIDE="$(MODULE_CACHE)" $(XCODEBUILD) \
	    -scheme $(SCHEME) \
	    -destination "$(SIM_DESTINATION)" \
	    $(SIM_SIGN_FLAGS) \
	    build

build-device:
	mkdir -p "$(BUILD_HOME)" "$(XDG_CACHE_HOME)" "$(MODULE_CACHE)"
	HOME="$(BUILD_HOME)" XDG_CACHE_HOME="$(XDG_CACHE_HOME)" CLANG_MODULE_CACHE_PATH="$(MODULE_CACHE)" SWIFTPM_MODULECACHE_OVERRIDE="$(MODULE_CACHE)" $(XCODEBUILD) \
	    -scheme $(SCHEME) \
	    -destination "$(DEVICE_DESTINATION)" \
	    $(DEVICE_SIGN_FLAGS) \
	    build

build-mac:
	mkdir -p "$(BUILD_HOME)" "$(XDG_CACHE_HOME)" "$(MODULE_CACHE)"
	HOME="$(BUILD_HOME)" XDG_CACHE_HOME="$(XDG_CACHE_HOME)" CLANG_MODULE_CACHE_PATH="$(MODULE_CACHE)" SWIFTPM_MODULECACHE_OVERRIDE="$(MODULE_CACHE)" $(XCODEBUILD) \
	    -scheme $(SCHEME) \
	    -destination "$(MAC_DESTINATION)" \
	    $(MAC_SIGN_FLAGS) \
	    build

build-uikit:
	mkdir -p "$(BUILD_HOME)" "$(XDG_CACHE_HOME)" "$(MODULE_CACHE)"
	HOME="$(BUILD_HOME)" XDG_CACHE_HOME="$(XDG_CACHE_HOME)" CLANG_MODULE_CACHE_PATH="$(MODULE_CACHE)" SWIFTPM_MODULECACHE_OVERRIDE="$(MODULE_CACHE)" $(XCODEBUILD) \
	    -scheme $(UIKIT_SCHEME) \
	    -destination "$(SIM_DESTINATION)" \
	    $(SIM_SIGN_FLAGS) \
	    build

build-appkit:
	mkdir -p "$(BUILD_HOME)" "$(XDG_CACHE_HOME)" "$(MODULE_CACHE)"
	HOME="$(BUILD_HOME)" XDG_CACHE_HOME="$(XDG_CACHE_HOME)" CLANG_MODULE_CACHE_PATH="$(MODULE_CACHE)" SWIFTPM_MODULECACHE_OVERRIDE="$(MODULE_CACHE)" $(XCODEBUILD) \
	    -scheme $(APPKIT_SCHEME) \
	    -destination "$(MAC_DESTINATION)" \
	    $(MAC_SIGN_FLAGS) \
	    build

build-tv:
	mkdir -p "$(BUILD_HOME)" "$(XDG_CACHE_HOME)" "$(MODULE_CACHE)"
	HOME="$(BUILD_HOME)" XDG_CACHE_HOME="$(XDG_CACHE_HOME)" CLANG_MODULE_CACHE_PATH="$(MODULE_CACHE)" SWIFTPM_MODULECACHE_OVERRIDE="$(MODULE_CACHE)" $(XCODEBUILD) \
	    -scheme $(TV_SCHEME) \
	    -destination "$(TV_SIM_DESTINATION)" \
	    $(SIM_SIGN_FLAGS) \
	    build

build-tv-uikit:
	mkdir -p "$(BUILD_HOME)" "$(XDG_CACHE_HOME)" "$(MODULE_CACHE)"
	HOME="$(BUILD_HOME)" XDG_CACHE_HOME="$(XDG_CACHE_HOME)" CLANG_MODULE_CACHE_PATH="$(MODULE_CACHE)" SWIFTPM_MODULECACHE_OVERRIDE="$(MODULE_CACHE)" $(XCODEBUILD) \
	    -scheme $(TV_UIKIT_SCHEME) \
	    -destination "$(TV_SIM_DESTINATION)" \
	    $(SIM_SIGN_FLAGS) \
	    build

build-watch:
	mkdir -p "$(BUILD_HOME)" "$(XDG_CACHE_HOME)" "$(MODULE_CACHE)"
	HOME="$(BUILD_HOME)" XDG_CACHE_HOME="$(XDG_CACHE_HOME)" CLANG_MODULE_CACHE_PATH="$(MODULE_CACHE)" SWIFTPM_MODULECACHE_OVERRIDE="$(MODULE_CACHE)" $(XCODEBUILD) \
	    -scheme $(WATCH_SCHEME) \
	    -destination "$(WATCH_SIM_DESTINATION)" \
	    $(SIM_SIGN_FLAGS) \
	    build

build-watchkit:
	mkdir -p "$(BUILD_HOME)" "$(XDG_CACHE_HOME)" "$(MODULE_CACHE)"
	HOME="$(BUILD_HOME)" XDG_CACHE_HOME="$(XDG_CACHE_HOME)" CLANG_MODULE_CACHE_PATH="$(MODULE_CACHE)" SWIFTPM_MODULECACHE_OVERRIDE="$(MODULE_CACHE)" $(XCODEBUILD) \
	    -scheme $(WATCHKIT_SCHEME) \
	    -destination "$(WATCH_SIM_DESTINATION)" \
	    $(SIM_SIGN_FLAGS) \
	    build

build-all: build-sim build-uikit build-appkit build-tv build-tv-uikit build-watch build-watchkit

# =============================================================================
# Run on simulator
# =============================================================================

boot:
	@if [ -z "$(SIMULATOR_UDID)" ]; then echo "Simulator not found: $(SIMULATOR_NAME)" >&2; exit 1; fi
	@xcrun simctl boot "$(SIMULATOR_UDID)" 2>/dev/null || true
	open -a Simulator

install: build-sim boot
	@APP_PATH=$$(find "$(DERIVED_DATA)/Build/Products" -name "$(APP_NAME).app" -type d -path "*Simulator*" | head -1); \
	if [ -z "$$APP_PATH" ]; then echo "App bundle not found under $(DERIVED_DATA)" >&2; exit 1; fi; \
	echo "Installing $$APP_PATH"; \
	xcrun simctl install "$(SIMULATOR_UDID)" "$$APP_PATH"

launch:
	@if [ -z "$(SIMULATOR_UDID)" ]; then echo "Simulator not found: $(SIMULATOR_NAME)" >&2; exit 1; fi
	xcrun simctl launch "$(SIMULATOR_UDID)" "$(BUNDLE_ID)"

run: install launch

run-mac: build-mac
	@APP_PATH=$$(find "$(DERIVED_DATA)/Build/Products" -name "$(APP_NAME).app" -type d -path "*Debug*" | grep -v -i "iphone\|simulator" | head -1); \
	if [ -z "$$APP_PATH" ]; then echo "macOS app bundle not found under $(DERIVED_DATA)" >&2; exit 1; fi; \
	echo "Launching $$APP_PATH"; \
	open "$$APP_PATH"

install-uikit: build-uikit boot
	@APP_PATH=$$(find "$(DERIVED_DATA)/Build/Products" -name "$(UIKIT_APP_NAME).app" -type d -path "*Simulator*" | head -1); \
	if [ -z "$$APP_PATH" ]; then echo "App bundle not found under $(DERIVED_DATA)" >&2; exit 1; fi; \
	echo "Installing $$APP_PATH"; \
	xcrun simctl install "$(SIMULATOR_UDID)" "$$APP_PATH"

launch-uikit:
	@if [ -z "$(SIMULATOR_UDID)" ]; then echo "Simulator not found: $(SIMULATOR_NAME)" >&2; exit 1; fi
	xcrun simctl launch "$(SIMULATOR_UDID)" "$(UIKIT_BUNDLE_ID)"

run-uikit: install-uikit launch-uikit

run-appkit: build-appkit
	@APP_PATH=$$(find "$(DERIVED_DATA)/Build/Products" -name "$(APPKIT_APP_NAME).app" -type d -path "*Debug*" | grep -v -i "iphone\|simulator" | head -1); \
	if [ -z "$$APP_PATH" ]; then echo "macOS app bundle not found under $(DERIVED_DATA)" >&2; exit 1; fi; \
	echo "Launching $$APP_PATH"; \
	open "$$APP_PATH"

# =============================================================================
# Run on the Apple TV simulator
# =============================================================================

boot-tv:
	@if [ -z "$(TV_SIMULATOR_UDID)" ]; then echo "Simulator not found: $(TV_SIMULATOR_NAME). Create one in Xcode > Window > Devices and Simulators, or set TV_SIMULATOR_NAME." >&2; exit 1; fi
	@xcrun simctl boot "$(TV_SIMULATOR_UDID)" 2>/dev/null || true
	open -a Simulator

install-tv: build-tv boot-tv
	@APP_PATH=$$(find "$(DERIVED_DATA)/Build/Products" -name "$(TV_APP_NAME).app" -type d -path "*appletvsimulator*" | head -1); \
	if [ -z "$$APP_PATH" ]; then echo "App bundle not found under $(DERIVED_DATA)" >&2; exit 1; fi; \
	echo "Installing $$APP_PATH"; \
	xcrun simctl install "$(TV_SIMULATOR_UDID)" "$$APP_PATH"

launch-tv:
	@if [ -z "$(TV_SIMULATOR_UDID)" ]; then echo "Simulator not found: $(TV_SIMULATOR_NAME)" >&2; exit 1; fi
	xcrun simctl launch "$(TV_SIMULATOR_UDID)" "$(TV_BUNDLE_ID)"

run-tv: install-tv launch-tv

install-tv-uikit: build-tv-uikit boot-tv
	@APP_PATH=$$(find "$(DERIVED_DATA)/Build/Products" -name "$(TV_UIKIT_APP_NAME).app" -type d -path "*appletvsimulator*" | head -1); \
	if [ -z "$$APP_PATH" ]; then echo "App bundle not found under $(DERIVED_DATA)" >&2; exit 1; fi; \
	echo "Installing $$APP_PATH"; \
	xcrun simctl install "$(TV_SIMULATOR_UDID)" "$$APP_PATH"

launch-tv-uikit:
	@if [ -z "$(TV_SIMULATOR_UDID)" ]; then echo "Simulator not found: $(TV_SIMULATOR_NAME)" >&2; exit 1; fi
	xcrun simctl launch "$(TV_SIMULATOR_UDID)" "$(TV_UIKIT_BUNDLE_ID)"

run-tv-uikit: install-tv-uikit launch-tv-uikit

# =============================================================================
# Run on the Apple Watch simulator
# =============================================================================

boot-watch:
	@if [ -z "$(WATCH_SIMULATOR_UDID)" ]; then echo "Simulator not found: $(WATCH_SIMULATOR_NAME). Create one in Xcode > Window > Devices and Simulators, or set WATCH_SIMULATOR_NAME." >&2; exit 1; fi
	@xcrun simctl boot "$(WATCH_SIMULATOR_UDID)" 2>/dev/null || true
	open -a Simulator

install-watch: build-watch boot-watch
	@APP_PATH=$$(find "$(DERIVED_DATA)/Build/Products" -name "$(WATCH_APP_NAME).app" -type d -path "*watchsimulator*" | head -1); \
	if [ -z "$$APP_PATH" ]; then echo "App bundle not found under $(DERIVED_DATA)" >&2; exit 1; fi; \
	echo "Installing $$APP_PATH"; \
	xcrun simctl install "$(WATCH_SIMULATOR_UDID)" "$$APP_PATH"

launch-watch:
	@if [ -z "$(WATCH_SIMULATOR_UDID)" ]; then echo "Simulator not found: $(WATCH_SIMULATOR_NAME)" >&2; exit 1; fi
	xcrun simctl launch "$(WATCH_SIMULATOR_UDID)" "$(WATCH_BUNDLE_ID)"

run-watch: install-watch launch-watch

install-watchkit: build-watchkit boot-watch
	@APP_PATH=$$(find "$(DERIVED_DATA)/Build/Products" -name "$(WATCHKIT_APP_NAME).app" -type d -path "*watchsimulator*" | head -1); \
	if [ -z "$$APP_PATH" ]; then echo "App bundle not found under $(DERIVED_DATA)" >&2; exit 1; fi; \
	echo "Installing $$APP_PATH"; \
	xcrun simctl install "$(WATCH_SIMULATOR_UDID)" "$$APP_PATH"

launch-watchkit:
	@if [ -z "$(WATCH_SIMULATOR_UDID)" ]; then echo "Simulator not found: $(WATCH_SIMULATOR_NAME)" >&2; exit 1; fi
	xcrun simctl launch "$(WATCH_SIMULATOR_UDID)" "$(WATCHKIT_BUNDLE_ID)"

run-watchkit: install-watchkit launch-watchkit

# =============================================================================
# Formatting
# =============================================================================

format:
	swiftformat . \
	    --swift-version 5.10 \
	    --exclude $(SWIFTFORMAT_EXCLUDES)

format-lint:
	swiftformat . \
	    --swift-version 5.10 \
	    --exclude $(SWIFTFORMAT_EXCLUDES) \
	    --lint

# =============================================================================
# Housekeeping
# =============================================================================

clean:
	rm -rf $(DERIVED_DATA)
