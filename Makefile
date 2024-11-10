DUINOMAKEFILE_DIR := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))

# LIB_DIR is the directory that the Arduino libraries are stored it.
# It is expected to be the directory that duino_makefile is contained in.
LIB_DIR ?= $(dir $(DUINOMAKEFILE_DIR))

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

ifeq ($(BUILD_VERBOSE),1)
$(info TOP_DIR = $(TOP_DIR))
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
include $(DUINOMAKEFILE_DIR)/tools.mk
include $(DUINOMAKEFILE_DIR)/lint.mk
include $(DUINOMAKEFILE_DIR)/vscode.mk
