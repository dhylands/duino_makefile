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
vscode-settings: COMPILE_CMD = $(shell $(COMPILE) --verbose 2> /dev/null | grep g++ | head -1)
vscode-settings: INC_DIRS = src $(DEP_LIB_INC_DIRS) $(patsubst -I%,%,$(sort $(filter -I%, $(COMPILE_CMD))))
vscode-settings: HOST_COMPILER = $(shell which g++)
vscode-settings: HOST_INC_DIRS = $(shell echo | $(HOST_COMPILER) -x c++ -E -Wp,-v - 2>&1 | grep -e '^ ')
vscode-settings: DEFS = $(patsubst -D%,%,$(sort $(filter -D%, $(COMPILE_CMD))))
vscode-settings: IPREFIX = $(patsubst -iprefix%,%,$(filter -iprefix%, $(COMPILE_CMD)))
vscode-settings: PLATFORM_INCS = $(patsubst -iwithprefixbefore/%,$(IPREFIX)%,$(shell cat $(patsubst @%,%,$(filter @%,$(COMPILE_CMD))) /dev/null))
vscode-settings: LIBRARY_INCS = $(abspath $(TOP_DIR)/src)
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
	@for dir in $(HOST_INC_DIRS) $(LIBRARY_INCS); do \
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
	@echo '    "compilerPath": "$(firstword $(COMPILE_CMD))",' >> ${MK_SETTINGS}
	@echo '    "intelliSenseMode": "linux-gcc-arm",' >> ${MK_SETTINGS}
	@echo '    "includePath": [' >> ${MK_SETTINGS}
	@for dir in $(INC_DIRS) $(PLATFORM_INCS); do \
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
	echo "DEFS = $($(subst ",,$(DEFS)))"
	for cflag in $(subst ",,$(DEFS)); do \
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
