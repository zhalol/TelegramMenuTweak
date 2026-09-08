TARGET := iphone:clang::16.5
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = botcczz

botcczz_FILES = Tweak.x SatellaObserver.x
botcczz_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
botcczz_FRAMEWORKS = UIKit Foundation StoreKit

include $(THEOS_MAKE_PATH)/tweak.mk
