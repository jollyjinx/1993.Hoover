GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)
GNUSTEP_MAKEFILES = $(GNUSTEP_SYSTEM_ROOT)/Makefiles

include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = HTMLStripper
HTMLStripper_OBJC_FILES = HTMLStripper_main.m
ADDITIONAL_TOOL_LIBS += -lHooverFramework

-include GNUmakefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/tool.make

-include GNUmakefile.postamble
