DUINOMAKEFILE_DIR := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))

ifeq ($(TOP_DIR),)
$(info PWD = $(PWD))
$(error TOP_DIR must be specified in the library Makefile)
endif

ifeq ("$(origin V)", "command line")
BUILD_VERBOSE=$(V)
endif
ifndef BUILD_VERBOSE
BUILD_VERBOSE = 0
endif
ifeq ($(BUILD_VERBOSE),0)
Q = @
else
Q =
endif

all:

RM = rm
ECHO = @echo
MKDIR = mkdir
MV = mv

ifeq ($(BOARD),)
include $(wildcard $(TOP_DIR)/board.mk)
endif
ifeq ($(BOARD),)
$(error BOARD not defined - pass it on the command line or create a board.mk file)
endif

include $(DUINOMAKEFILE_DIR)/build.mk

include $(DUINOMAKEFILE_DIR)/arduino-cli.mk
include $(DUINOMAKEFILE_DIR)/unittest.mk
include $(DUINOMAKEFILE_DIR)/docs.mk
include $(DUINOMAKEFILE_DIR)/style.mk
include $(DUINOMAKEFILE_DIR)/lint.mk
include $(DUINOMAKEFILE_DIR)/vscode.mk
