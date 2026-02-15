.PHONY: build run clean

APP_NAME = Reminder
BUILD_DIR = .build/arm64-apple-macosx/debug
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app

build:
	swift build
	mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	cp "$(BUILD_DIR)/$(APP_NAME)" "$(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)"
	cp Sources/Reminder/Info.plist "$(APP_BUNDLE)/Contents/Info.plist"

run: build
	open "$(APP_BUNDLE)"

clean:
	swift package clean
	rm -rf "$(APP_BUNDLE)"
