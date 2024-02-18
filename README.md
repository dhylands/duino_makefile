# Arduino-Makefile
Common makefile snippets shared between my Arduino projects

[TOC]

# Providing a BOARD

A board must be provided for all invocations of `make`. Thid can either
be specified in a board.mk located in the top of the repository, or can
be specified on the command line.

A typical board.mk file might look like:
```
BOARD = pico
```
You can always override this by specifying the board on the command line
when invoking make:
```
make BOARD=picow upload
```

# Top level Makefile in a library

Outside of the DuinoMakefile repository, the top level `Makefile` needs to include the DuinoMakefile's top-level Makefile, so assuming that the DuinoMakefile repository is beside the library in question, it's top level Makefile might look like:
```
THIS_DIR := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))
TOP_DIR ?= $(THIS_DIR)

DUINO_MAKEFILE ?= $(THIS_DIR)/../DuinoMakefile

ifeq ("$(wildcard $(DUINO_MAKEFILE)/Makefile)","")
$(error Unable to open $(DUINO_MAKEFILE)/Makefile)
else
include $(DUINO_MAKEFILE)/Makefile
endif
```

# From within a directory containing a .ino file

To use the make command from within a directory you must provide a `Makefile`. This Makefile typically contains 2 lines. The first line
defines a variable called `TOP_DIR` which is a relative path to get from
the current directory to the top of the library. You can use the following git command to achieve this:
```
TOP_DIR := $(patsubst %/,%,$(shell git rev-parse --path-format=relatve --show-toplevel))
```
The `$(patsubst %/,%,test)` remove the trailing slash that git rev-parse puts on the directoty.

Finally, you should incude the `Makefile` from the top of the repository. So the final `Makefile` will look like this:
```
TOP_DIR := $(patsubst %/,%,$(shell git rev-parse --path-format=relatve --show-toplevel))
include $(TOP_DIR)/Makefile
```

# Predefined targets

The DuinoMakefile provides the following targets:
- compile
- upload
- monitor
- install-cli
- lib
- clean
- unittest
- style
- lint
- docs
- vscode-settings

## compile

The `compile` target will compile the sketch. This is useful to check that all of your syntax is correct.

## install-cli

The `install-cli` target will install the board core files needed by arduino-cli.

## upload

The `upload` target will compule the sketch and upload it to your board. It will also invoke a serial monitor so that you can see the output that
your program writes using the `Serial` object. This is the most commonly used target:

Example:
```
$ make BOARD=picow upload
Use make V=1 or set BUILD_VERBOSE in your environment to increase build verbosity.
Compiling with BOARD = picow
Sketch uses 78772 bytes (3%) of program storage space. Maximum is 2093056 bytes.
Global variables use 70784 bytes (27%) of dynamic memory, leaving 191360 bytes for local variables. Maximum is 262144 bytes.
Resetting /dev/ttyACM0
Converting to uf2, output size: 194048, start address: 0x2000
Scanning for RP2040 devices
Flashing /media/dhylands/RPI-RP2 (RPI-RP2)
Wrote 194048 bytes to /media/dhylands/RPI-RP2/NEW.UF2

Used platform Version Path
rp2040:rp2040 3.7.0   /home/dhylands/.arduino15/packages/rp2040/hardware/rp2040/3.7.0
--- Miniterm on /dev/ttyACM0  115200,8,N,1 ---
--- Quit: Ctrl+] | Menu: Ctrl+T | Help: Ctrl+T followed by Ctrl+H ---
Counter = 6
Counter = 7
Counter = 8
Counter = 9
Counter = 10

--- exit ---
```

## monitor

The `monitor` target will just invoke the serial monitor. This is useful
if your program is already running and doesn't need to be uploaded.

## lib

The `lib` target will build the library using the HOST compiler, rather than arduino-cli. This builds the library used by the `unittest`. This is useful when trying to fix compile errors.

## clean

The `clean` target removes all of the generated files (which are found in the `build` directory).

## unittest

The `unittest` target runs all of the unit tests found in the `tests` directory.

## style

The `style`  command reformats the source code.

## lint

The `lint` command runs a linter on the source, which identifies common issues, many stylistic.

## docs

The `docs` command extracts documentation from the source code using doxygen. The generated source can be found in `$(TOP_DIR)/build/docs/html/index.html`

## vscode-settings

The `vscode-settings` target will generate a `$(TOP_DIR)/.vscode/c_cpp_properties.json` file which sets up 2 compiler configurations. The first is called `Linux` and is useful for examining the source files
as seen by the compiler for unit testsing. The second is called `Arduino` and sets up all of the include paths and defines that `arduino-cli` uses. You can switch between compile configurations by selecting `Linux` or `Arduino` in the bottom right of the status bar in
VS Code.
