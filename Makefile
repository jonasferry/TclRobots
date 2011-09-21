SRC = src/battle.tcl src/game.tcl src/gui.tcl src/help.tcl \
	src/init.tcl src/main.tcl src/simulator.tcl \
	src/tournament.tcl tclrobots.tcl

TCLKIT = build/tclkit86-linux64
SDX = ../$(TCLKIT) ../build/sdx.kit

# Make reasonably sure no one has a local temp directory
# with the same name
TEMP = temp123123123

all: doc test build-linux32 build-linux64 build-windows build-mac

build-linux32:
	$(MAKE) build MAKEFLAGS=RUNTIME=linux32 TARGET=tclrobots
build-linux64:
	$(MAKE) build MAKEFLAGS=RUNTIME=linux64 TARGET=tclrobots

build-windows:
	$(MAKE) build MAKEFLAGS=RUNTIME=windows32 TARGET=tclrobots.exe

build-mac:
	$(MAKE) build MAKEFLAGS=RUNTIME=mac32 TARGET=tclrobots-mac

build: 
	echo "Building $(TARGET)"
	rm -rf $(TEMP)
	mkdir $(TEMP)
	(cd $(TEMP); cp -rf ../src .; cp -rf ../lib/ .; cp -rf ../samples/ .; cp ../README .; cp ../LICENSE .; cp -rf ../tclrobots.tcl .; mkdir -p doc; cp -rf ../doc/readme_doc.html doc)
	(cd $(TEMP); $(SDX) qwrap tclrobots.tcl)
	(cd $(TEMP); $(SDX) unwrap tclrobots.kit)
	cp -rf $(TEMP)/src/ $(TEMP)/lib/ $(TEMP)/doc/ $(TEMP)/samples $(TEMP)/README $(TEMP)/LICENSE $(TEMP)/tclrobots.vfs/lib/app-tclrobots/
	cp build/tclkit86-$(RUNTIME) $(TEMP)/
	(cd $(TEMP); $(SDX) wrap tclrobots.kit -runtime tclkit86-$(RUNTIME))
	mkdir -p build/download-files
	cp $(TEMP)/tclrobots.kit build/download-files/$(TARGET)
	cp $(TEMP)/tclrobots.kit $(TEMP)/$(TARGET)
	(cd $(TEMP); tar cvf ../build/download-files/tclrobots-$(RUNTIME).tar $(TARGET) samples/)
	(cd $(TEMP); zip -r ../build/download-files/tclrobots-$(RUNTIME).zip $(TARGET) samples/)
	rm -rf $(TEMP)

check: header.syntax
	nagelfar -s syntaxdb86.tcl header.syntax $(SRC)

header.syntax: $(SRC) helper.syntax
	nagelfar -s syntaxdb86.tcl -header header.syntax helper.syntax $(SRC)

doc:
	doc/script/generate-doc

run:
	$(TCLKIT) tclrobots.tcl --max --gui samples/*.tr

runtour:
	$(TCLKIT) tclrobots.tcl --nomsg --tournament samples/*.tr

test:
	$(TCLKIT) test/all.tcl

.PHONY: all build build-linux build-windows build-mac check doc run runtour test
