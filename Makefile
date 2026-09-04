TARGET := iphone:clang::16.5
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = botcczz

botcczz_FILES = Tweak.x
botcczz_CFLAGS = -fobjc-arc
botcczz_FRAMEWORKS = UIKit Foundation StoreKit

include $(THEOS_MAKE_PATH)/tweak.mk
