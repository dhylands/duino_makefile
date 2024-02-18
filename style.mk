# Reformats the source code for a consistent look

CLANGFORMAT_ARGS := -style='{BasedOnStyle: chromium, IndentWidth: 4, AccessModifierOffset: -3, AlignAfterOpenBracket: AlwaysBreak, BinPackParameters: false, ColumnLimit: 100, SortIncludes: false}'
STYLE_FILES := $(shell find $(TOP_DIR) -name '*.h' -o -name '*.cpp' -o -name '*.ino')

.PHONY: style
style:
	@echo "Stylizing source files ..."
	@clang-format --verbose $(CLANGFORMAT_ARGS) -i $(STYLE_FILES)
