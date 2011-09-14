SRC = src/battle.tcl src/gui.tcl src/help.tcl \
      src/simulator.tcl src/tclrobots.tcl \
      src/tournament.tcl

SDX = ../build/tclkit-8.6 ../build/sdx.kit

# Make reasonably sure no one has a local temp directory
# with the same name
TEMP = temp123123123

all: doc test

build: build-linux build-windows

build-linux:
	rm -rf $(TEMP)
	mkdir $(TEMP)
	(cd $(TEMP); cp -rf ../src .; cp -rf ../lib/ .; cp -rf ../samples/ .; cp ../README .; cp ../LICENSE .; cp -rf ../tclrobots.tcl .)
	(cd $(TEMP); $(SDX) qwrap tclrobots.tcl)
	(cd $(TEMP); $(SDX) unwrap tclrobots.kit)
	cp -rf $(TEMP)/src/ $(TEMP)/samples $(TEMP)/README $(TEMP)/LICENSE $(TEMP)/tclrobots.vfs/lib/app-tclrobots/
	cp -rf $(TEMP)/src/ $(TEMP)/README $(TEMP)/LICENSE $(TEMP)/tclrobots.vfs/lib/app-tclrobots/
	mkdir $(TEMP)/tclrobots.vfs/lib/lib
	cp -rf $(TEMP)/lib/ $(TEMP)/tclrobots.vfs/lib/lib/
        # Wrap Linux version
	cp build/tclkit-8.6 $(TEMP)/
	(cd $(TEMP); $(SDX) wrap tclrobots.kit -runtime tclkit-8.6)
	cp $(TEMP)/tclrobots.kit build/tclrobots
	rm -rf $(TEMP)

build-windows:
	rm -rf $(TEMP)
	mkdir $(TEMP)
	(cd $(TEMP); cp -rf ../src .; cp -rf ../lib/ .; cp -rf ../samples/ .; cp ../README .; cp ../LICENSE .; cp -rf ../tclrobots.tcl .)
	(cd $(TEMP); $(SDX) qwrap tclrobots.tcl)
	(cd $(TEMP); $(SDX) unwrap tclrobots.kit)
	cp -rf $(TEMP)/src/ $(TEMP)/samples $(TEMP)/README $(TEMP)/LICENSE $(TEMP)/tclrobots.vfs/lib/app-tclrobots/
	cp -rf $(TEMP)/src/ $(TEMP)/README $(TEMP)/LICENSE $(TEMP)/tclrobots.vfs/lib/app-tclrobots/
	mkdir $(TEMP)/tclrobots.vfs/lib/lib
	cp -rf $(TEMP)/lib/ $(TEMP)/tclrobots.vfs/lib/lib/
        # Wrap Windows version
	cp build/tclkit-8.6.exe $(TEMP)/
	(cd $(TEMP); $(SDX) wrap tclrobots.kit -runtime tclkit-8.6.exe)
	cp $(TEMP)/tclrobots.kit build/tclrobots.exe
	rm -rf $(TEMP)

check: header.syntax
	nagelfar header.syntax $(SRC)

header.syntax: $(SRC) helper.syntax
	nagelfar -header header.syntax helper.syntax $(SRC)

doc:
	doc/script/generate-doc

test:
	test/all.tcl

.PHONY: all build build-linux build-windows check doc test
