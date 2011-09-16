SRC = src/battle.tcl src/gui.tcl src/help.tcl \
      src/simulator.tcl src/main.tcl \
      src/tournament.tcl tclrobots.tcl

SDX = ../build/linux/tclkit-8.6-linux ../build/sdx.kit

# Make reasonably sure no one has a local temp directory
# with the same name
TEMP = temp123123123

all: doc test build-linux build-windows build-mac

build-linux:
	$(MAKE) build MAKEFLAGS=RUNTIME=linux TARGET=tclrobots

build-windows:
	$(MAKE) build MAKEFLAGS=RUNTIME=windows TARGET=tclrobots.exe

build-mac:
	$(MAKE) build MAKEFLAGS=RUNTIME=mac TARGET=tclrobots

build: 
	echo "Building $(TARGET)"
	rm -rf $(TEMP)
	mkdir $(TEMP)
	(cd $(TEMP); cp -rf ../src .; cp -rf ../lib/ .; cp -rf ../samples/ .; cp ../README .; cp ../LICENSE .; cp -rf ../tclrobots.tcl .)
	(cd $(TEMP); $(SDX) qwrap tclrobots.tcl)
	(cd $(TEMP); $(SDX) unwrap tclrobots.kit)
	cp -rf $(TEMP)/src/ $(TEMP)/samples $(TEMP)/README $(TEMP)/LICENSE $(TEMP)/tclrobots.vfs/lib/app-tclrobots/
	cp -rf $(TEMP)/src/ $(TEMP)/lib/ $(TEMP)/README $(TEMP)/LICENSE $(TEMP)/tclrobots.vfs/lib/app-tclrobots/
	cp build/$(RUNTIME)/tclkit-8.6-$(RUNTIME) $(TEMP)/
	(cd $(TEMP); $(SDX) wrap tclrobots.kit -runtime tclkit-8.6-$(RUNTIME))
	cp $(TEMP)/tclrobots.kit build/$(RUNTIME)/$(TARGET)
	rm -rf $(TEMP)

check: header.syntax
	nagelfar header.syntax $(SRC)

header.syntax: $(SRC) helper.syntax
	nagelfar -header header.syntax helper.syntax $(SRC)

doc:
	doc/script/generate-doc

test:
	test/all.tcl

.PHONY: all build build-linux build-windows build-mac check doc test
