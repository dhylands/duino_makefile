# vscode.mk

# vscode-settings will add the arduino-cli include files and defines into the
# c_cpp_properties.json settings file, It will also setup 2 configurations,
# one called Linux and one called Arduino. You can choose the active configuration
# in the bottom right corner of the status bar in VSCode. The `Linux` configuration
# is useful when writing unittests, and the Arduino configuration is good for everything
# else.

ifeq ($(filter-out vscode-settings,$(MAKECMDGOALS)),)
ifeq ($(wildcard *.ino),)
$(error Please run make-vscode-settings in a directory containing an .ino file)
endif
endif

# I also need to add something like the following into ./.vscode/settings/json
#
#	{
#	    "python.analysis.extraPaths": ["${workspaceFolder}/../libraries/duino_bus"]
#	}
#
# to in order to have pyLance resolve `from duinp_bus.dump_mem import dump_mem`

.PHONY: vscode-settings
vscode-settings: VSCODE_SETTINGS = $(TOP_DIR)/.vscode/c_cpp_properties.json
vscode-settings: CLI_CONFIG = Arduino-$(BOARD)
vscode-settings: CLI_COMPILE_CMD = $(shell $(COMPILE) --verbose 2> /dev/null | grep g++ | grep .ino.cpp | grep -v -- -lc | tail -1)
vscode-settings: HOST_CONFIG = Linux
vscode-settings: HOST_COMPILER = $(shell which g++)
vscode-settings: HOST_INC_DIRS = $(addprefix -I,$(shell echo | $(HOST_COMPILER) -x c++ -E -Wp,-v - 2>&1 | grep -e '^ '))
vscode-settings: HOST_LIBRARY_INCS = $(addprefix -I,$(abspath $(addprefix $(TOP_DIR)/, src $(DEP_LIB_INC_DIRS))))
vscode-settings:
	$(Q)if [ "${CLI_COMPILE_CMD}" == "" ]; then \
		echo "CLI_COMPILE_CMD is empty"; \
		echo "Try make V=1 compile to see of there are any errors;" \
		exit 1; \
	else \
		mkdir -p $(dir ${VSCODE_SETTINGS}); \
		make-vscode-settings -c $(CLI_CONFIG) $(VSCODE_SETTINGS) -- $(CLI_COMPILE_CMD); \
		make-vscode-settings -c $(HOST_CONFIG) $(VSCODE_SETTINGS) -- $(HOST_COMPILER) $(HOST_INC_DIRS) $(HOST_LIBRARY_INCS); \
		python3 -m json.tool ${VSCODE_SETTINGS}; \
	fi
