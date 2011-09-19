SRC = src/battle.tcl src/game.tcl src/gui.tcl src/help.tcl \
	src/init.tcl src/main.tcl src/simulator.tcl \
	src/tournament.tcl tclrobots.tcl

SDX = ../build/tclkit86-linux ../build/sdx.kit

# Make reasonably sure no one has a local temp directory
# with the same name
TEMP = temp123123123

all: doc test build-linux build-windows build-mac

build-linux:
	$(MAKE) build MAKEFLAGS=RUNTIME=linux TARGET=tclrobots

build-windows:
	$(MAKE) build MAKEFLAGS=RUNTIME=windows TARGET=tclrobots.exe

build-mac:
	$(MAKE) build MAKEFLAGS=RUNTIME=mac TARGET=tclrobots-mac

build: 
	echo "Building $(TARGET)"
	rm -rf $(TEMP)
	mkdir $(TEMP)
	(cd $(TEMP); cp -rf ../src .; cp -rf ../lib/ .; cp -rf ../samples/ .; cp ../README .; cp ../LICENSE .; cp -rf ../tclrobots.tcl .)
	(cd $(TEMP); $(SDX) qwrap tclrobots.tcl)
	(cd $(TEMP); $(SDX) unwrap tclrobots.kit)
	cp -rf $(TEMP)/src/ $(TEMP)/lib/ $(TEMP)/samples $(TEMP)/README $(TEMP)/LICENSE $(TEMP)/tclrobots.vfs/lib/app-tclrobots/
	#mkdir $(TEMP)/tclrobots.vfs/lib/
	#cp -rf $(TEMP)/lib/* $(TEMP)/tclrobots.vfs/lib/
	cp build/tclkit86-$(RUNTIME) $(TEMP)/
	(cd $(TEMP); $(SDX) wrap tclrobots.kit -runtime tclkit86-$(RUNTIME))
	cp $(TEMP)/tclrobots.kit build/download-files/$(TARGET)
	cp $(TEMP)/tclrobots.kit $(TEMP)/$(TARGET)
	#chmod +x build/download-files/$(TARGET)
	(cd $(TEMP); tar cvf ../build/download-files/tclrobots-$(RUNTIME).tar $(TARGET) samples/)
	#rm -rf $(TEMP)

check: header.syntax
	nagelfar header.syntax $(SRC)

header.syntax: $(SRC) helper.syntax
	nagelfar -header header.syntax helper.syntax $(SRC)

doc:
	doc/script/generate-doc

test:
	test/all.tcl

.PHONY: all build build-linux build-windows build-mac check doc test
