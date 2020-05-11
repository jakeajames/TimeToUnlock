include $(THEOS)/makefiles/common.mk

ARCHS = arm64 arm64e

BUNDLE_NAME = TimeToUnlockPrefs
TimeToUnlockPrefs_FILES = TTURootListController.m
TimeToUnlockPrefs_INSTALL_PATH = /Library/PreferenceBundles
TimeToUnlockPrefs_FRAMEWORKS = UIKit
TimeToUnlockPrefs_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/TimeToUnlockPrefs.plist$(ECHO_END)
