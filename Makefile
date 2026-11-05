ARCHS = armv7
TARGET = iphone:clang:10.3:10.3
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GestureX
GestureX_FILES = GestureX/Tweak.xm
GestureX_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
GestureX_FRAMEWORKS = UIKit
include $(THEOS_MAKE_PATH)/tweak.mk
