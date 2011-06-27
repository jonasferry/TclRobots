SRC = src/battle.tcl src/gui.tcl src/help.tcl \
      src/simulator.tcl src/tclrobots.tcl \
      src/tournament.tcl

all: doc test

doc:
	doc/script/generate-doc

test:
	test/all.tcl

header.syntax: $(SRC) helper.syntax
	nagelfar -header header.syntax helper.syntax $(SRC)

check: header.syntax
	nagelfar header.syntax $(SRC)

.PHONY: all doc test check
