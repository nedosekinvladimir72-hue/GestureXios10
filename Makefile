ARCHS = armv7
TARGET = iphone:clang:10.3:10.3
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GestureX
GestureX_FILES = Tweak.xm
GestureX_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -fno-modules
GestureX_FRAMEWORKS = UIKit
include $(THEOS_MAKE_PATH)/tweak.mk

LIBRARIES = substrate
FRAMEWORKS = UIKit Foundation CoreGraphics QuartzCore
ADDITIONAL_LDFLAGS = -lc++ -lobjc
