# docs.mk

.PHONY: docs
docs: DOXYGEN_CFG = $(DUINOMAKEFILE_DIR)/doxygen.cfg
docs: export PROJECT_NAME = $(notdir $(abspath $(TOP_DIR)))
docs: export PROJECT_NUMBER = $(shell git describe --tags --dirty --always)
docs: export PROJECT_BRIEF = $(patsubst sentence=%,%,$(shell grep sentence $(TOP_DIR)/library.properties))
docs: export OUTPUT_DIRECTORY = $(BUILD)/docs
docs: export PROJECT_EXAMPLES = $(wildcard $(BUILD)/examples)
docs:
	$(ECHO) "Generating HTNL documentation ..."
	$(Q)cd $(TOP_DIR) && \
	$(MKDIR) -p $${OUTPUT_DIRECTORY}/html && \
	doxygen $(abspath $(DUINOMAKEFILE_DIR))/doxygen.cfg
	$(ECHO) "open $(TOP_DIR)/$(OUTPUT_DIRECTORY)/html/index.html to examine"