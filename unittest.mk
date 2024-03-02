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

# DuinoLog => $(TOP_DIR)/DuinoLog/$(BUILD_REL)/libDuinoLog.a

ifeq ($(TEST_OBJS),)
unittest:
	$(ECHO) No source files to run unittest on

coverage:
	$(ECHO) No source files to run unittest on
else

$(BUILD)/test-runner: $(TEST_OBJS) $(OBJS)
	$(ECHO) "Linking $@ ..."
	$(Q)$(CXX) $(LFLAGS) -o $@ $(TEST_OBJS) $(OBJS) -lgtest_main -lgtest -lpthread

unittest: $(BUILD)/test-runner
	$(ECHO) "===== Running unit tests ====="
	$(Q)$(BUILD)/test-runner

.PHONY: coverage
.NOTPARALLEL: coverage
coverage: COMMON_FLAGS += --coverage -fno-exceptions
coverage: LFLAGS += --coverage
coverage: COVERAGE_EXCLUDE = --exclude '.*Test.cpp'
coverage: COVERAGE_DIR = $(TOP_DIR)/coverage
coverage: COVERAGE_DIR_FINAL = $(BUILD)/$(notdir $(COVERAGE_DIR))
coverage: COVERAGE_HTML = $(COVERAGE_DIR)/coverage.html
coverage: COVERAGE_HTML_FINAL = $(COVERAGE_DIR_FINAL)/coverage.html
coverage: clean-build unittest
	$(ECHO) "===== coverage ====="
	@# We're only concerned with coverage in core source files.
	$(Q)cd $(TOP_DIR) && gcovr $(COVERAGE_EXCLUDE) $(BUILD_REL)
	$(Q)cd $(TOP_DIR) && gcovr $(COVERAGE_EXCLUDE) --txt-metric branch $(BUILD_REL)
	$(Q)$(RM) -rf $(COVERAGE_DIR)
	$(Q)$(MKDIR) $(COVERAGE_DIR)
	$(Q)gcovr $(COVERAGE_EXCLUDE) --html-details $(COVERAGE_HTML) $(TOP_DIR)
	$(Q)$(RM) -rf $(BUILD)
	$(Q)$(RM) -rf $(dir $(COVERAGE_DIR_FINAL))
	$(Q)$(MKDIR) -p $(COVERAGE_DIR_FINAL)
	$(Q)$(MV) $(COVERAGE_DIR) $(dir $(COVERAGE_DIR_FINAL))
	$(ECHO) "HTML coverage file is in $(COVERAGE_HTML_FINAL)"

endif  # TEST_OBJS
