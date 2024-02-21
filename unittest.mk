
include $(TOP_DIR)/tests/files.mk

TEST_OBJS = $(addprefix $(BUILD)/, $(TEST_SOURCES_CPP:%.cpp=%.o))

TEST_OBJ_DIRS = $(sort $(dir $(TEST_OBJS)))

TEST_DEPS := $(TEST_OBJS:%.o=%.d)
$(TEST_DEPS):
include $(wildcard $(TEST_DEPS))

$(TEST_OBJS): | $(TEST_OBJ_DIRS)
$(TEST_OBJS): CXXFLAGS += -I $(TOP_DIR)/src

$(BUILD)/test-runner: $(TEST_OBJS) $(LIB)
	$(ECHO) "Linking $@ ..."
	$(Q)$(CXX) $(LFLAGS) -o $@ $^ -lgtest_main -lgtest

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
	$(Q)gcovr $(BUILD)/src
	$(Q)gcovr -b $(BUILD)/src
	$(Q)$(RM) -rf $(COVERAGE_DIR)
	$(Q)$(MKDIR) $(COVERAGE_DIR)
	$(Q)gcovr --html-details $(COVERAGE_HTML) $(TOP_DIR)
	$(Q)$(RM) -rf $(BUILD)
	$(Q)$(RM) -rf $(dir $(COVERAGE_DIR_FINAL))
	$(Q)$(MKDIR) -p $(COVERAGE_DIR_FINAL)
	$(Q)$(MV) $(COVERAGE_DIR) $(dir $(COVERAGE_DIR_FINAL))
	$(ECHO) "HTML coverage file is in $(COVERAGE_HTML_FINAL)"
