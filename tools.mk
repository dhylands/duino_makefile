# tools.mk

.PHONY: install-update
install-update:
	$(ECHO) "===== Updating apt ====="
	$(Q)sudo apt update

.PHONY: install-gtest
install-gtest: install-update
	$(ECHO) "===== Installing googletest ====="
	$(Q)sudo apt install -y libgtest-dev

.PHONY: install-clang-format
install-clang-format: install-update
	$(ECHO) "===== Installing clang-format ====="
	$(Q)python3 -m pip install clang-format

.PHONY: install-cpplint
install-cpplint: install-update
	$(ECHO) "===== Installing cpplint ====="
	$(Q)python3 -m pip install cpplint

.PHONY: install-doxygen
install-doxygen: install-update
	$(ECHO) "===== Installing doxygen ====="
	$(Q)sudo apt install -y doxygen-doc graphviz

.PHONY: install-gcovr
install-gcovr: install-update
	$(ECHO) "===== Installing gcovr ====="
	$(Q)python3 -m pip install gcovr

.PHONY: install-tools
install-tools: install-gtest install-clang-format install-cpplint install-doxygen install-gcovr install-cli

.PHONY: run-rools
run-tools: test-style lint docs unittest
	# Coverage needs to be done separately since it wipes out the build directory.
	$(MAKE) coverage

.PHONY: compile-examples
compile-examples:
	$(ECHO) "===== Compiling examples ====="
	$(Q)if [ -d $(TOP_DIR)/examples ]; then \
		for dir in $(TOP_DIR)/examples/*; do \
			$(MAKE) V=1 -C $${dir} TOP_DIR=../.. compile; \
		done; \
	else \
		echo "No examples to build"; \
	fi
