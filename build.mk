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
BUILD ?= $(TOP_DIR)/$(BUILD_DIR)/$(BOARD)

ifneq ($(DEBUG),)
COMMON_FLAGS += -ggdb
COMMON_FLAGS += -ggdb
C_OPT = -O0
BUILD := $(BUILD)/debug
else
COPT += -Os
BUILD := $(BUILD)/relase
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

include $(TOP_DIR)/src/files.mk

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

vpath %.cpp $(TOP_DIR)

$(BUILD)/%.o: %.cpp $(BUILD)/%.d | $(OBJ_DIRS)
	$(call compile_cxx)

$(BUILD)/%.pp: %.cpp
	$(ECHO) "PreProcess $<"
	$(Q)$(CPP) $(CXXFLAGS) -Wp,-C,-dD,-dI -o $@ $<

LIB_NAME = lib$(notdir $(abspath $(TOP_DIR))).a
LIB = $(BUILD)/$(LIB_NAME)
.PHONY: lib
lib: $(LIB)

$(LIB): $(OBJS)
	$(ECHO) "Creating library $(LIB) ..."

	$(Q)$(AR) crs $(LIB) $(OBJS)
clean:
	$(ECHO) "Removing BUILD directory $(BUILD) ..."
	$(Q)$(RM) -rf $(BUILD)