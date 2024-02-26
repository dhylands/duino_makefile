# unittest.mk

include $(wildcard $(TOP_DIR)/tests/files.mk)

TEST_OBJS = $(addprefix $(BUILD)/, $(TEST_SOURCES_CPP:%.cpp=%.o))
TEST_DEPS := $(TEST_OBJS:%.o=%.d)
TEST_OBJ_DIRS = $(sort $(dir $(TEST_OBJS)))

ifeq ($(BUILD_VERBOSE),1)
$(info TEST_OBJS = $(TEST_OBJS))
endif

$(TEST_DEPS):
include $(wildcard $(TEST_DEPS))

$(TEST_OBJS): | $(TEST_OBJ_DIRS)
$(TEST_OBJS): CXXFLAGS += -I $(TOP_DIR)/src $(DEP_LIB_INC_OPTS)

ifneq ($(DEP_LIBS),)
DEP_LIBS_OPTS = $(addprefix, -l, $(DEP_LIBS))
DEP_LIB_DIRS = $(addprefix -L $(TOP_DIR)/../, $(DEP_LIBS))
endif

ifeq ($(TEST_OBJS),)
unittest:
	$(ECHO) No source files to run unittest on

coverage:
	$(ECHO) No source files to run unittest on
else
$(BUILD)/test-runner: $(TEST_OBJS) $(LIB)
	$(ECHO) "Linking $@ ..."
	@echo THIS_LIB = $(THIS_LIB)
	$(Q)$(CXX) $(LFLAGS) -o $@ $(TEST_OBJS) -L$(BUILD) $(DEP_LIB_DIRS) -l$(THIS_LIB) $(DEP_LIB_OPTS) -lgtest_main -lgtest -lpthread

unittest: $(BUILD)/test-runner
	$(ECHO) "Running unit tests ..."
	$(Q)$(BUILD)/test-runner

.PHONY: coverage
.NOTPARALLEL: coverage
coverage: COMMON_FLAGS += --coverage
coverage: LFLAGS += --coverage
coverage: COVERAGE_DIR = $(TOP_DIR)/coverage
coverage: COVERAGE_DIR_FINAL = $(TOP_DIR)/$(BUILD_DIR)/$(notdir $(COVERAGE_DIR))
coverage: COVERAGE_HTML = $(COVERAGE_DIR)/coverage.html
coverage: COVERAGE_HTML_FINAL = $(COVERAGE_DIR_FINAL)/coverage.html
coverage: clean-build unittest
	@# We're only concerned with coverage in core source files.
	$(Q)cd $(TOP_DIR) && gcovr $(BUILD_REL)/src
	$(Q)cd $(TOP_DIR) && gcovr -b $(BUILD_REL)/src
	$(Q)$(RM) -rf $(COVERAGE_DIR)
	$(Q)$(MKDIR) $(COVERAGE_DIR)
	$(Q)gcovr --html-details $(COVERAGE_HTML) $(TOP_DIR)
	$(Q)$(RM) -rf $(BUILD)
	$(Q)$(RM) -rf $(dir $(COVERAGE_DIR_FINAL))
	$(Q)$(MKDIR) -p $(COVERAGE_DIR_FINAL)
	$(Q)$(MV) $(COVERAGE_DIR) $(dir $(COVERAGE_DIR_FINAL))
	$(ECHO) "HTML coverage file is in $(COVERAGE_HTML_FINAL)"
endif
