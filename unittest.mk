
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
	$(Q)$(CXX) -o $@ $^ -lgtest_main -lgtest

unittest: $(BUILD)/test-runner
	$(ECHO) "Running unit tests ..."
	$(Q)$(BUILD)/test-runner

