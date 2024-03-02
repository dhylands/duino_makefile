# build.mk

SHELL := bash

EMPTY :=
SPACE := $(EMPTY) $(EMPTY)
COMMA = ,

CROSS_COMPILE ?=

AS = $(CROSS_COMPILE)as
CC = $(CROSS_COMPILE)gcc
CXX = $(CROSS_COMPILE)g++
CPP = $(CC) -E
LD = $(CROSS_COMPILE)ld
GDB = $(CROSS_COMPILE)gdb
OBJCOPY = $(CROSS_COMPILE)objcopy
SIZE = $(CROSS_COMPILE)size

CXXFLAGS += -std=gnu++17

BUILD = $(TOP_DIR)/build/$(BOARD)

ifeq (,$(filter-out coverage,$(MAKECMDGOALS)))
$(info setting DEBUG=1 due to coverage)
DEBUG=1
endif

ifneq ($(DEBUG),)
COMMON_FLAGS += -ggdb
C_OPT = -O0
BUILD := $(BUILD)/debug
else
COPT += -Os
BUILD := $(BUILD)/release
endif

COMMON_FLAGS += $(C_OPT)

COMMON_FLAGS += -Wall -Werror -Wextra \
    -Wdouble-promotion -Wduplicated-cond -Wformat=2 \
    -Wformat-signedness -Wpointer-arith -Wvla -Wwrite-strings

# We let the comiler generate the dependency files.
DEP_FLAGS += -MT $@ -MMD -MP -MF ${@:%.o=%.d}

COMMON_FLAGS += -I $(TOP_DIR)/src
COMMON_FLAGS += $(DEP_FLAGS)

CFLAGSS += $(COMMON_FLAGS)
CXXFLAGS += $(COMMON_FLAGS)

include $(wildcard $(TOP_DIR)/src/files.mk)
include $(wildcard $(TOP_DIR)/lib.mk)

OBJS = $(addprefix $(BUILD)/, $(SOURCES_CPP:%.cpp=%.o))
OBJ_DIRS = $(sort $(dir $(OBJS)))

DEPS = $(OBJS:%.o=%.d)
$(DEPS):

include $(wildcard $(DEPS))

# DEP_LIB_INC_DIRS is relative to TOP_DIR
DEP_LIB_INC_DIRS = $(addprefix ../,$(DEP_LIBS)) $(addprefix ../,$(addsuffix /src,$(DEP_LIBS)))
DEP_LIB_INC_OPTS = $(addprefix -I $(TOP_DIR)/, $(DEP_LIB_INC_DIRS))

CXXFLAGS += $(DEP_LIB_INC_OPTS)

.PRECIOUS: %/
%/: ; $(Q)$(MKDIR) -p $@

ifneq ($(DEP_LIBS),)

DEP_LIBS_DIRS = $(foreach lib,$(DEP_LIBS),$(TOP_DIR)/../$(lib))
DEP_LIBS_SRC_DIRS = $(addsuffix /src,$(DEP_LIBS_DIRS))
DEP_LIBS_TESTS_DIRS = $(addsuffix /tests,$(DEP_LIBS_DIRS))
DEP_LIBS_FILES_MK = $(addsuffix /files.mk,$(DEP_LIBS_SRC_DIRS))

ifeq ($(BUILD_VERBOSE),1)
$(info DEP_LIBS = $(DEP_LIBS))
$(info DEP_LIBS_DIRS = $(DEP_LIBS_DIRS))
$(info DEP_LIBS_SRC_DIRS = $(DEP_LIBS_SRC_DIRS))
$(info DEP_LIBS_TESTS_DIRS = $(DEP_LIBS_TESTS_DIRS))
$(info DEP_LIBS_FILES_MK = $(DEP_LIBS_FILES_MK))
endif  # BUILD_BERBOSE

$(info including $(DEP_LIBS_FILES_MK))
include $(DEP_LIBS_FILES_MK)

endif  # DEP_LIBS

ifeq ($(BUILD_VERBOSE),1)
$(info BOARD = $(BOARD))
$(info BUILD = $(BUILD))
$(info SOURCES_CPP = $(SOURCES_CPP))
$(info OBJS = $(OBJS))
$(info DEPS = $(DEPS))
endif

vpath %.cpp $(TOP_DIR)/src $(TOP_DIR)/tests $(DEP_LIBS_SRC_DIRS) $(DEP_LIBS_TESTS_DIRS)

$(BUILD)/%.o: %.cpp | $(OBJ_DIRS)
	$(ECHO) "Compiling $<"
	$(Q)$(CXX) $(CXXFLAGS) -c -o $@ $<

$(BUILD)/%.pp: %.cpp
	$(ECHO) "PreProcess $<"
	$(Q)$(CPP) $(CXXFLAGS) -Wp,-C,-dD,-dI -o $@ $<

clean:
	$(ECHO) "Removing BUILD directory $(BUILD) ..."
	$(Q)$(RM) -rf $(BUILD)

clean-build:
	$(ECHO) "Removing BUILD directory $(TOP_DIR)$(BUILD_DIR) ..."
	$(Q)$(RM) -rf $(TOP_DIR)/$(BUILD)
