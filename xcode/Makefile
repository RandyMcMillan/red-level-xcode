SHELL := /bin/bash

PROJECT := swiftyapp/Red-Level.xcodeproj
SCHEME := Red-Level
TRAYAPP_PROJECT := trayapp/trayapp.xcodeproj
TRAYAPP_SCHEME := trayapp
BUILD_SCRIPT := ./build.sh
RUST_CRATE_DIR := rustylib
DERIVED_DATA ?= .build/xcode
CONFIGURATION ?= Debug
APP_NAME := Red-Level.app
TRAYAPP_APP_NAME := trayapp.app
INSTALL_DIR ?= $(HOME)/Applications
SYMROOT := $(abspath $(DERIVED_DATA))
OBJROOT := $(SYMROOT)/Intermediates.noindex
HOST_ARCH := $(shell uname -m)
SIMULATOR_ARCH := $(if $(filter arm64,$(HOST_ARCH)),arm64,x86_64)
IOS_DESTINATION ?= generic/platform=iOS Simulator
CATALYST_DESTINATION ?= generic/platform=macOS,variant=Mac Catalyst
MACOS_DESTINATION ?= generic/platform=macOS
CATALYST_APP_PATH := $(SYMROOT)/$(CONFIGURATION)-maccatalyst/$(APP_NAME)
TRAYAPP_APP_PATH := $(SYMROOT)/$(CONFIGURATION)/$(TRAYAPP_APP_NAME)

.DEFAULT_GOAL := help

.PHONY: help rust resolve resolve-trayapp all app catalyst trayapp install install-red-level install-trayapp install-all clean

help:
	@printf '%s\n' \
		'make rust      - build the Rust library, bindings, and XCFramework' \
		'make resolve   - resolve local Swift package dependencies' \
		'make all       - build the iOS app, Mac Catalyst app, and tray app' \
		'make app       - build the iOS app for a generic simulator destination' \
		'make catalyst  - build the app for Mac Catalyst' \
		'make trayapp   - build the tray app for macOS' \
		'make install   - install the Mac Catalyst app into ~/Applications' \
		'make install-red-level - install the Red-Level app into ~/Applications' \
		'make install-trayapp - install the tray app into ~/Applications' \
		'make install-all - install both apps into ~/Applications' \
		'make clean     - clean Rust and Xcode build artifacts'

rust:
	$(BUILD_SCRIPT)

resolve:
	xcodebuild -resolvePackageDependencies -project "$(PROJECT)" -scheme "$(SCHEME)"

resolve-trayapp: rust
	xcodebuild -resolvePackageDependencies -project "$(TRAYAPP_PROJECT)" -scheme "$(TRAYAPP_SCHEME)"

app: rust resolve
	xcodebuild \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-configuration "$(CONFIGURATION)" \
		-derivedDataPath "$(DERIVED_DATA)" \
		SYMROOT="$(SYMROOT)" \
		OBJROOT="$(OBJROOT)" \
		-destination "$(IOS_DESTINATION)" \
		ARCHS="$(SIMULATOR_ARCH)" \
		ONLY_ACTIVE_ARCH=YES \
		build

all: app catalyst trayapp

catalyst: rust resolve
	xcodebuild \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-configuration "$(CONFIGURATION)" \
		-derivedDataPath "$(DERIVED_DATA)" \
		SYMROOT="$(SYMROOT)" \
		OBJROOT="$(OBJROOT)" \
		-destination "$(CATALYST_DESTINATION)" \
		ARCHS="$(HOST_ARCH)" \
		ONLY_ACTIVE_ARCH=YES \
		build

trayapp: rust resolve-trayapp
	xcodebuild \
		-project "$(TRAYAPP_PROJECT)" \
		-scheme "$(TRAYAPP_SCHEME)" \
		-configuration "$(CONFIGURATION)" \
		-derivedDataPath "$(DERIVED_DATA)" \
		SYMROOT="$(SYMROOT)" \
		OBJROOT="$(OBJROOT)" \
		-destination "$(MACOS_DESTINATION)" \
		ARCHS="$(HOST_ARCH)" \
		ONLY_ACTIVE_ARCH=YES \
		build

install: install-red-level
install-red-level: catalyst
	mkdir -p "$(INSTALL_DIR)"
	rm -rf "$(INSTALL_DIR)/$(APP_NAME)"
	cp -R "$(CATALYST_APP_PATH)" "$(INSTALL_DIR)/$(APP_NAME)"

install-trayapp: trayapp
	mkdir -p "$(INSTALL_DIR)"
	rm -rf "$(INSTALL_DIR)/$(TRAYAPP_APP_NAME)"
	cp -R "$(TRAYAPP_APP_PATH)" "$(INSTALL_DIR)/$(TRAYAPP_APP_NAME)"

install-all: install-red-level install-trayapp

clean:
	cd "$(RUST_CRATE_DIR)" && cargo clean
	rm -rf "$(DERIVED_DATA)"
