# style.mk

# Reformats the source code for a consistent look

CLANGFORMAT_ARGS := -style='{BasedOnStyle: chromium, IndentWidth: 4, AccessModifierOffset: -3, AlignAfterOpenBracket: AlwaysBreak, BinPackParameters: false, ColumnLimit: 100, SortIncludes: false}'
FIND_CMD = find $(TOP_DIR) \( -name '*.h' -o -name '*.cpp' -o -name '*.ino' \)

.PHONY: style
style: STYLE_FILES = $(shell $(FIND_CMD))
style:
	$(ECHO) "Stylizing source files ..."
	$(Q)clang-format --verbose $(CLANGFORMAT_ARGS) -i $(STYLE_FILES)

test-style: FILES = $(shell $(FIND_CMD) -exec bash -c "clang-format $(CLANGFORMAT_ARGS) -output-replacements-xml {} | grep -cq 'replacement '" \; -print)
test-style:
	$(Q)if [ -n "$(FILES)" ]; then \
		echo "" && \
		echo "The following files require formatting (with style)" && \
		for file in $(FILES); do \
			echo "  $${file}"; \
		done \
	else \
		echo "All files are formatted properly"; \
	fi
#    @# Show all replacements clang-format would perform | count them | check if any line isn't zero. Negate everything.
#    ! find -regex '.*\.\(h\|c\|cpp\|hpp\|tcc\)\(\.original\)?' $(STYLE_FIND_EXCLUDE) -exec bash -c 'clang-format -output-replacements-xml '"$(CLANG_FORMAT_STYLE_ARGS)"' {}
# | grep -cq "replacement "' \; -exec echo {} \; | grep -v "^0$$" || (echo The files above require clang-formatting. && exit 1)
