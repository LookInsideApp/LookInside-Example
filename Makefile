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

SIMULATOR_NAME     ?= iPhone 16
SIMULATOR_UDID     = ${shell xcrun simctl list devices available | sed -nE 's/^[[:space:]]*$(SIMULATOR_NAME)( \([^)]*\))? \(([A-F0-9-]+)\).*/\2/p' | head -1}
BUNDLE_ID          := app.lookinside.example
UIKIT_BUNDLE_ID    := app.lookinside.example.uikit

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
        generate \
        build build-sim build-device build-mac build-uikit build-appkit build-all \
        run boot install launch run-mac \
        run-uikit install-uikit launch-uikit run-appkit \
        format format-lint \
        clean

# =============================================================================
# Meta
# =============================================================================

all: build-sim

help:
	@echo "Project generation:"
	@echo "  generate           Regenerate $(PROJECT) with Tuist"
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
	@echo "  build-all          Build all three apps"
	@echo ""
	@echo "Run:"
	@echo "  run                Boot \$$(SIMULATOR_NAME), install, and launch the SwiftUI app"
	@echo "  run-mac            Build and launch the SwiftUI app on this Mac"
	@echo "  run-uikit          Boot \$$(SIMULATOR_NAME), install, and launch the UIKit app"
	@echo "  run-appkit         Build and launch the AppKit app on this Mac"
	@echo "  boot               Boot \$$(SIMULATOR_NAME) (no-op if already booted)"
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
	@echo "  LOOKINSIDE_SERVER_PATH Optional local server package path for Tuist generation"
	@echo "  DERIVED_DATA       Derived data path (default: /private/tmp/lookinside-example-deriveddata)"

generate:
	TUIST_LOOKINSIDE_SERVER_PATH="$(LOOKINSIDE_SERVER_PATH)" $(TUIST) generate --no-open

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

build-all: build-sim build-uikit build-appkit

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
