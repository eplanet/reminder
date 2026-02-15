.PHONY: build run clean install uninstall

APP_NAME = Reminder
BUILD_DIR = .build/arm64-apple-macosx/debug
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
INSTALL_DIR = $(HOME)/Applications
INSTALL_APP = $(INSTALL_DIR)/$(APP_NAME).app
PLIST_NAME = com.personal.Reminder.plist
PLIST_PATH = $(HOME)/Library/LaunchAgents/$(PLIST_NAME)

build:
	swift build
	mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	cp "$(BUILD_DIR)/$(APP_NAME)" "$(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)"
	cp Sources/Reminder/Info.plist "$(APP_BUNDLE)/Contents/Info.plist"

run: build
	open "$(APP_BUNDLE)"

install: build
	mkdir -p "$(INSTALL_DIR)"
	rm -rf "$(INSTALL_APP)"
	cp -R "$(APP_BUNDLE)" "$(INSTALL_APP)"
	@echo "Installed to $(INSTALL_APP)"
	@mkdir -p "$(HOME)/Library/LaunchAgents"
	@echo '<?xml version="1.0" encoding="UTF-8"?>' > "$(PLIST_PATH)"
	@echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> "$(PLIST_PATH)"
	@echo '<plist version="1.0">' >> "$(PLIST_PATH)"
	@echo '<dict>' >> "$(PLIST_PATH)"
	@echo '    <key>Label</key>' >> "$(PLIST_PATH)"
	@echo '    <string>com.personal.Reminder</string>' >> "$(PLIST_PATH)"
	@echo '    <key>ProgramArguments</key>' >> "$(PLIST_PATH)"
	@echo '    <array>' >> "$(PLIST_PATH)"
	@echo '        <string>/usr/bin/open</string>' >> "$(PLIST_PATH)"
	@echo '        <string>-a</string>' >> "$(PLIST_PATH)"
	@echo '        <string>$(INSTALL_APP)</string>' >> "$(PLIST_PATH)"
	@echo '    </array>' >> "$(PLIST_PATH)"
	@echo '    <key>RunAtLoad</key>' >> "$(PLIST_PATH)"
	@echo '    <true/>' >> "$(PLIST_PATH)"
	@echo '</dict>' >> "$(PLIST_PATH)"
	@echo '</plist>' >> "$(PLIST_PATH)"
	@echo "LaunchAgent installed to $(PLIST_PATH)"
	@echo "Reminder will start automatically at login."

uninstall:
	launchctl bootout gui/$$(id -u) "$(PLIST_PATH)" 2>/dev/null || true
	rm -f "$(PLIST_PATH)"
	rm -rf "$(INSTALL_APP)"
	@echo "Uninstalled."

clean:
	swift package clean
	rm -rf "$(APP_BUNDLE)"
