PREFIX ?= /usr/local
APP_NAME = JoyMapKit
APP_BUNDLE = $(APP_NAME).app
INSTALL_DIR = /Applications

.PHONY: build test install uninstall clean release app install-app bump-version

build:
	swift build -c release

test:
	swift test

install: build
	install -d $(PREFIX)/bin
	install .build/release/joymapkit $(PREFIX)/bin/joymapkit

uninstall:
	rm -f $(PREFIX)/bin/joymapkit

clean:
	swift package clean
	rm -rf $(APP_BUNDLE)

release:
	swift build -c release --arch arm64 --arch x86_64
	strip .build/apple/Products/Release/joymapkit
	@echo "Universal binary at .build/apple/Products/Release/joymapkit"

# Build a proper .app bundle for the menu bar app
app: build
	@echo "Assembling $(APP_BUNDLE)..."
	rm -rf $(APP_BUNDLE)
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	mkdir -p $(APP_BUNDLE)/Contents/Resources
	cp Distribution/Info.plist $(APP_BUNDLE)/Contents/
	cp .build/release/JoyMapKitApp $(APP_BUNDLE)/Contents/MacOS/JoyMapKit
	@# Copy icon
	cp Distribution/AppIcon.icns $(APP_BUNDLE)/Contents/Resources/AppIcon.icns
	@# Generate minimal PkgInfo
	echo -n "APPL????" > $(APP_BUNDLE)/Contents/PkgInfo
	@# Code sign (ad-hoc for local use, replace with identity for distribution)
	codesign --force --sign - --entitlements Distribution/Entitlements/JoyMapKit.entitlements $(APP_BUNDLE)
	@echo "Built $(APP_BUNDLE) — open it or drag to /Applications"

# Install the .app to /Applications
install-app: app
	rm -rf $(INSTALL_DIR)/$(APP_BUNDLE)
	cp -R $(APP_BUNDLE) $(INSTALL_DIR)/
	@echo "Installed to $(INSTALL_DIR)/$(APP_BUNDLE)"

# Bump version: make bump-version V=0.2.0
bump-version:
ifndef V
	$(error Usage: make bump-version V=x.y.z)
endif
	@echo "Bumping version to $(V)..."
	sed -i '' 's|static let current = ".*"|static let current = "$(V)"|' Sources/JoyMapKitCore/Version.swift
	sed -i '' 's|<string>[0-9]*\.[0-9]*\.[0-9]*</string>|<string>$(V)</string>|' Distribution/Info.plist
	@echo "Updated Version.swift and Info.plist to $(V)"
	@echo "Don't forget to update Formula/joymapkit.rb URL and SHA after release"
