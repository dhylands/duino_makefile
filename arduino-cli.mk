# arduino-cli.mk

#     BOARD        VID    PID    FQBN - Fully Qualified Board Name
#     ---------    ------ ------ -------------------------------------------
BOARD_pico 	     = 0x2e8a 0x000a rp2040:rp2040:rpipico
BOARD_picow	     = 0x2e8a 0xf00a rp2040:rp2040:rpipicow
BOARD_zero		 = 0x2e8a 0x0003 rp2040:rp2040:waveshare_rp2040_zero
BOARD_esp32thing = 0x0403 0x6015 esp32:esp32:esp32thing

ifeq ($BOARD_$(BOARD),)
$(error No BOARD definition found for $(BOARD))
endif

VID 	= $(word 1, $(BOARD_$(BOARD)))
PID 	= $(word 2, $(BOARD_$(BOARD)))
FQBN 	= $(word 3, $(BOARD_$(BOARD)))

#MONITOR ?= python3 -m serial.tools.miniterm --raw $(PORT) 115200
MONITOR ?= $(ARDUINO_CLI) monitor --raw --port $(PORT) --config baudrate=$(BAUD_RATE)

# NOTE: The arduino-cli buffers characters typed until a newline is entered
#		so we use python's miniterm instead which sends each character as it's
#		typed.

ifeq ($(CI),true)
ARDUINO_CLI ?= $(HOME)/bin/arduino-cli
else
ARDUINO_CLI ?= arduino-cli
endif

ifeq ($(BUILD_VERBOSE),1)
CLI_VERBOSE = --verbose
else
CLI_VERBOSE =
endif
COMPILE = $(ARDUINO_CLI) compile $(CLI_VERBOSE) --fqbn $(FQBN)

.PHONY: compile
compile:
	$(ECHO) "Compiling for BOARD $(BOARD)"
	$(COMPILE)

# Try detecting the RPi Pico via the serial port. If no serial port found,
# look for the RPi Pico mounted as a filesystem.
.PHONY: upload
upload: PORT = $(shell find_port.py --vid $(VID) --pid $(PID))
upload: BAUD_RATE = 115200
upload: RPI_DIR = /media/$(USER)/RPI-RP2
upload:
	@if [ -z "$(PORT)" ]; then \
		if [ -d "${RPI_DIR}" ]; then \
			echo Compiling with BOARD = $(BOARD); \
			$(COMPILE) --upload --port $(RPI_DIR) && \
			$(MONITOR); \
		else \
			echo "No RPi Pico found"; \
		fi \
	else \
		echo Compiling with BOARD = $(BOARD); \
		$(COMPILE) --upload --port $(PORT) &&  \
		$(MONITOR); \
	fi

# Fires up a terminal monitor to interact with the rp2040 over USB serial
.PHONY: momitor
monitor: PORT = $(shell find_port.py --vid $(VID) --pid $(PID))
monitor:
	@if [ -z "$(PORT)" ]; then \
		echo "No RPi found with USB ID $(VID):$(PID)"; \
		find_port.py -l; \
		exit 1; \
	fi
	$(MONITOR)

# Installs arduino-cli into ~/bin and does the setup for the rp2040
# Note: that many unix distros add ~/bin to your PATH automatically if it exists when you login.
.PHONY: install-cli
install-cli:
	$(ECHO) "===== Installing arduino-cli ====="
	mkdir -p ~/bin
	cd $(HOME) && PATH=$(HOME)/bin:$(PATH) curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh
	$(ARDUINO_CLI) config dump > old-config.txt
	$(ARDUINO_CLI) config init --overwrite
	$(ARDUINO_CLI) config dump > new-config.txt
	$(ARDUINO_CLI) config add board_manager.additional_urls https://github.com/earlephilhower/arduino-pico/releases/download/global/package_rp2040_index.json
ifeq ($(CI),true)
	$(ARDUINO_CLI) config set directories.user $(dir $(abspath $(PWD)/..))
endif
	$(ARDUINO_CLI) core update-index
	$(ARDUINO_CLI) core install rp2040:rp2040

# Extracts the depends= line from the library.properties file and converts spaces to colons and commas to spaces
# Just before installing we convert the colon back to a space
install-deps: ARDUINO_DEP_LIBS = $(subst $(COMMA),$(SPACE),$(subst $(SPACE),:,$(shell sed -n -e '/depends=/s/depends=//p' < $(TOP_DIR)/library.properties)))
install-deps:
	$(Q)if [ -z "$(ARDUINO_DEP_LIBS)" ]; then \
		echo No library dependencies to install; \
	else \
		for dep_lib in $(ARDUINO_DEP_LIBS); do \
			$(ARDUINO_CLI) lib install "$${dep_lib//:/ }"; \
		done; \
	fi
