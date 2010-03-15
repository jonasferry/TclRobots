SRC = battle.tcl gui.tcl simulator.tcl tclrobots.tcl tournament.tcl

all: doc

doc:
	doc/script/generate-doc


header.syntax: $(SRC) helper.syntax
	nagelfar -header header.syntax helper.syntax $(SRC)

check: header.syntax
	nagelfar header.syntax $(SRC)

.PHONY: all doc check
