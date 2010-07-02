SRC = battle.tcl gui.tcl help.tcl simulator.tcl tclrobots.tcl tournament.tcl

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
