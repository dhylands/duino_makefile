# build.mk

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

BUILD_DIR = build
BUILD_REL = $(BUILD_DIR)/$(BOARD)
BUILD ?= $(TOP_DIR)/$(BUILD_REL)

ifeq (,$(filter-out coverage,$(MAKECMDGOALS)))
$(info setting DEBUG=1 due to coverage)
DEBUG=1
endif

ifneq ($(DEBUG),)
COMMON_FLAGS += -ggdb
C_OPT = -O0
BUILD := $(BUILD)/debug
BUILD_REL := $(BUILD_REL)/debug
else
COPT += -Os
BUILD := $(BUILD)/relase
BUILD_REL := $(BUILD_REL)/relase
endif
COMMON_FLAGS += $(C_OPT)

COMMON_FLAGS += -Wall -Werror -Wextra \
    -Wdouble-promotion -Wduplicated-cond -Wformat=2 \
    -Wformat-signedness -Wpointer-arith -Wvla -Wwrite-strings

# We let the comiler generate the dependency files.
DEP_FLAGS += -MT $@ -MMD -MP -MF ${@:%.o=%.d}

COMMON_FLAGS += $(DEP_FLAGS)

CFLAGSS += $(COMMON_FLAGS)
CXXFLAGS += $(COMMON_FLAGS)

include $(wildcard $(TOP_DIR)/src/files.mk)
include $(wildcard $(TOP_DIR)/lib.mk)

OBJS = $(addprefix $(BUILD)/, $(SOURCES_CPP:%.cpp=%.o))

OBJ_DIRS = $(sort $(dir $(OBJS)))

define compile_cxx
$(ECHO) "Compiling $<"
$(Q)$(CXX) $(CXXFLAGS) -c -o $@ $<
endef

DEPS := $(OBJS:%.o=%.d)
$(DEPS):

include $(wildcard $(DEPS))

.PRECIOUS: %/
%/: ; $(Q)$(MKDIR) -p $@

vpath %.cpp $(TOP_DIR) $(TOP_DIR)/src $(TOP_DIR)/tests

$(BUILD)/%.o: %.cpp $(BUILD)/%.d | $(OBJ_DIRS)
	$(call compile_cxx)

$(BUILD)/%.pp: %.cpp
	$(ECHO) "PreProcess $<"
	$(Q)$(CPP) $(CXXFLAGS) -Wp,-C,-dD,-dI -o $@ $<

LIB_NAME = lib$(THIS_LIB).a
LIB = $(BUILD)/$(LIB_NAME)
.PHONY: lib
lib: $(LIB)

$(LIB): $(OBJS)
	$(ECHO) "Creating library $(LIB) ..."
	$(Q)$(AR) crs $(LIB) $(OBJS)

clean:
	$(ECHO) "Removing BUILD directory $(BUILD) ..."
	$(Q)$(RM) -rf $(BUILD)

clean-build:
	$(ECHO) "Removing BUILD directory $(TOP_DIR)$(BUILD_DIR) ..."
	$(Q)$(RM) -rf $(TOP_DIR)/$(BUILD)
