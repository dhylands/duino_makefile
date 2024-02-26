# arduino-cli.mk

ifeq ($(BOARD),)
include $(wildcard $(TOP_DIR)/board.mk)
endif
ifeq ($(BOARD),)
$(error BOARD not defined - pass it on the command line or create a board.mk file)
endif

#     BOARD       VID    PID    FQBN - Fully Qualified Board Name
#     ---------   ------ ------ -------------------------------------------
BOARD_pico 	    = 0x2e8a 0x000a rp2040:rp2040:rpipico
BOARD_picow	    = 0x2e8a 0xf00a rp2040:rp2040:rpipicow
BOARD_zero		= 0x2e8a 0x0003 rp2040:rp2040:waveshare_rp2040_zero

ifeq ($BOARD_$(BOARD),)
$(error No BOARD definition found for $(BOARD))
endif

VID 	= $(word 1, $(BOARD_$(BOARD)))
PID 	= $(word 2, $(BOARD_$(BOARD)))
FQBN 	= $(word 3, $(BOARD_$(BOARD)))

MONITOR ?= python3 -m serial.tools.miniterm --raw $(PORT) 115200

# NOTE: The arduino-cli buffers characters typed until a newline is entered
#		so we use python's miniterm instead which sends each character as it's
#		typed.

ifeq ($(CI),true)
ARDUINO_CLI ?= $(HOME)/bin/arduino-cli
else
ARDUINO_CLI ?= arduino-cli
endif
COMPILE = $(ARDUINO_CLI) compile --fqbn $(FQBN)

.PHONY: compile
compile:
	$(ECHO) "Compiling for BOARD $(BOARD)"
	$(COMPILE) --verbose

# Try detecting the RPi Pico via the serial port. If no serial port found,
# look for the RPi Pico mounted as a filesystem.
.PHONY: upload
upload: PORT = $(shell find_port.py --vid $(VID) --pid $(PID))
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
.PHONY: install-cli
install-cli:
	mkdir -p ~/bin
	cd $(HOME) && curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh
	$(ARDUINO_CLI) config init
	$(ARDUINO_CLI) config add board_manager.additional_urls https://github.com/earlephilhower/arduino-pico/releases/download/global/package_rp2040_index.json
	$(ARDUINO_CLI) core update-index
	$(ARDUINO_CLI) core install rp2040:rp2040

