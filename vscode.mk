# vscode.mk

# vscode-settings will add the arduino-cli include files and defines into the
# c_cpp_properties.json settings file, It will also setup 2 configurations,
# one called Linux and one called Arduino. You can choose the active configuration
# in the bottom right corner of the status bar in VSCode. The `Linux` configuration
# is useful when writing unittests, and the Arduino configuration is good for everything
# else.
.PHONY: vscode-settings
vscode-settings: MK_SETTINGS = $(TOP_DIR)/.vscode/make_settings.py
vscode-settings: VSCODE_SETTINGS = $(TOP_DIR)/.vscode/c_cpp_properties.json
vscode-settings: CLI_COMPILE_CMD = $(shell $(COMPILE) --verbose 2> /dev/null | grep g++ | head -1)
vscode-settings: CLI_INC_DIRS = src $(DEP_LIB_INC_DIRS) $(patsubst -I%,%,$(sort $(filter -I%, $(CLI_COMPILE_CMD))))
vscode-settings: CLI_DEFS = $(patsubst -D%,%,$(sort $(filter -D%, $(CLI_COMPILE_CMD))))
vscode-settings: CLI_IPREFIX = $(patsubst -iprefix%,%,$(filter -iprefix%, $(CLI_COMPILE_CMD)))
vscode-settings: CLI_PLATFORM_INCS = $(patsubst -iwithprefixbefore/%,$(CLI_IPREFIX)%,$(shell cat $(patsubst @%,%,$(filter @%,$(CLI_COMPILE_CMD))) /dev/null))
vscode-settings: HOST_COMPILER = $(shell which g++)
vscode-settings: HOST_INC_DIRS = $(shell echo | $(HOST_COMPILER) -x c++ -E -Wp,-v - 2>&1 | grep -e '^ ')
vscode-settings: HOST_LIBRARY_INCS = $(abspath $(addprefix $(TOP_DIR)/, src $(DEP_LIB_INC_DIRS)))
vscode-settings:
	@echo "Updating ${VSCODE_SETTINGS} ..."
	@# We generate a python dictionary (which allows trailing commas) and then
	@# convert the dictionary to json
	@if [ ! -f "${VSCODE_SETTINGS}" ]; then \
		mkdir -p $(dir ${VSCODE_SETTINGS}); \
		(echo '{}' > ${VSCODE_SETTINGS}); \
	fi
	@echo 'import json' > ${MK_SETTINGS}
	@echo 'd = json.loads(open("${VSCODE_SETTINGS}").read())' >> ${MK_SETTINGS}

	@echo 'linux_cfg = {' >> ${MK_SETTINGS}
	@echo '    "name": "Linux",' >> ${MK_SETTINGS}
	@echo '    "compilerPath": "$(HOST_COMPILER)",' >> ${MK_SETTINGS}
	@echo '    "compilerArgs": ["-m64"],' >> ${MK_SETTINGS}
	@echo '    "intelliSenseMode": "linux-gcc-x64",' >> ${MK_SETTINGS}
	@echo '    "includePath": [' >> ${MK_SETTINGS}
	@for dir in $(HOST_INC_DIRS) $(HOST_LIBRARY_INCS); do \
		echo '        "'$${dir}'",' >> ${MK_SETTINGS}; \
	done
	@echo '    ],  # includePath' >> ${MK_SETTINGS}
	@echo '    "defines": [],' >> ${MK_SETTINGS}
	@echo '    "cStandard": "gnu11",' >> ${MK_SETTINGS}
	@echo '    "cppStandard": "gnu++17",' >> ${MK_SETTINGS}
	@echo '    "mergeConfigurations": True,' >> ${MK_SETTINGS}
	@echo '}  # linux_cfg' >> ${MK_SETTINGS}

	@echo 'arduino_cfg = {' >> ${MK_SETTINGS}
	@echo '    "name": "Arduino",' >> ${MK_SETTINGS}
	@echo '    "compilerPath": "$(firstword $(CLI_COMPILE_CMD))",' >> ${MK_SETTINGS}
	@echo '    "intelliSenseMode": "linux-gcc-arm",' >> ${MK_SETTINGS}
	@echo '    "includePath": [' >> ${MK_SETTINGS}
	@for dir in $(CLI_INC_DIRS) $(CLI_PLATFORM_INCS); do \
		if [ "$${dir#/}" != "$${dir}" ]; then \
		    echo '        "'$${dir}'",' >> ${MK_SETTINGS}; \
		else \
			echo '        "$${workspaceFolder}/'$${dir}'",' >> ${MK_SETTINGS}; \
		fi \
	done
	@echo '    ],  # includePath' >> ${MK_SETTINGS}

	echo '    "defines": [' >> ${MK_SETTINGS}
	# We need to strip quotes out. For the most part this is fine. However
	# it may also drop things like the following:
	#     CXXFLAGS += VAR="abc def"
	# And we'll only include `VAR=abc` into the defines. If this becomes an
	# issuethen we'll need to implement this in a python script rather than
	# try to use make/bash.
	echo "DEFS = $($(subst ",,$(CLI_DEFS)))"
	for cflag in $(subst ",,$(CLI_DEFS)); do \
		echo '        "'$${cflag}'",' >> ${MK_SETTINGS}; \
	done
	echo '    ],  # defines' >> ${MK_SETTINGS}
	@echo '    "cStandard": "gnu11",' >> ${MK_SETTINGS}
	@echo '    "cppStandard": "gnu++17",' >> ${MK_SETTINGS}
	@echo '    "mergeConfigurations": True,' >> ${MK_SETTINGS}
	@echo '}  # arduino_cfg' >> ${MK_SETTINGS}

	@echo 'd = {"configurations": [linux_cfg, arduino_cfg]}' >> ${MK_SETTINGS}
	@echo 'print(json.dumps(d, indent=4))' >> ${MK_SETTINGS}
	@python3 ${MK_SETTINGS} > ${VSCODE_SETTINGS}.new
	@# We do a mv after so we don't wipe out the settings if the python script has an error
	@mv ${VSCODE_SETTINGS}.new ${VSCODE_SETTINGS}
	@echo "===== Updated ${VSCODE_SETTINGS} ====="
	python3 -m json.tool ${VSCODE_SETTINGS}
