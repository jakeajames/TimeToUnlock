include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TimeToUnlock
TimeToUnlock_FILES = Tweak.xm
TimeToUnlock_PRIVATE_FRAMEWORKS = SpringBoardFoundation

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += timetounlockprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
