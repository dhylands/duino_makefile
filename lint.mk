# lint.mk

# Find common issues with the code

CPPLINT_ARGS :=

.PHONY: lint
lint: EXCLUDE_DIRS = .direnv
lint: EXCLUDE_OPT = $(addprefix --exclude=,$(EXCLUDE_DIRS))
lint:
	$(ECHO) "===== Linting source files ====="
	$(Q)cpplint --version
	$(Q)cpplint --linelength=100 --filter=-build/include_subdir,-readability/casting,-whitespace/parens --recursive $(CPPLINT_ARGS) --headers=h  --extensions=c,h,cpp,ino $(EXCLUDE_OPT) $(TOP_DIR)
