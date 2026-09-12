TARGET = iphone:clang:latest:14.0
ARCHS = arm64
INSTALL_PATH = /
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = SPTMRace

SPTMRace_FILES = Main.mm ASUKAViewController.mm ASUKAExploit.mm
SPTMRace_CFLAGS = -fobjc-arc -Wno-error -fobjc-weak -fuse-ld=lld
SPTMRace_LDFLAGS = -fuse-ld=lld
SPTMRace_FRAMEWORKS = UIKit Foundation
SPTMRace_PRIVATE_FRAMEWORKS = IOKit

include $(THEOS_MAKE_PATH)/application.mk
