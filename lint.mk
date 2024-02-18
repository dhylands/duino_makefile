# Find common issues with the code

CPPLINT_ARGS :=

.PHONY: lint
lint:
	$(ECHO) "Linting source files ..."
	$(Q)cpplint --linelength=100 --filter=-build/include_subdir,-readability/casting,-whitespace/parens --recursive $(CPPLINT_ARGS) --headers=h  --extensions=c,h,cpp,ino $(TOP_DIR)
