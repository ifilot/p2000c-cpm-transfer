SHELL := /bin/bash
EMUPATH := ../../vendor/z80pack
PROG := transfer

all: $(PROG).com

$(PROG).com: $(PROG).asm
	asm80 $(PROG).asm -o $(PROG).com

$(EMUPATH)/cpmsim/cpm22 $(EMUPATH)/cpmsim/srctools/mkdskimg:
	make -j -C ../../vendor/z80pack

disassemble: $(PROG).com
	dis80 $(PROG).com

run: $(PROG).com $(EMUPATH)/cpmsim/cpm22 $(EMUPATH)/cpmsim/srctools/mkdskimg
	pushd  $(EMUPATH)/cpmsim/disks && rm -vf drivec.dsk && ../srctools/mkdskimg c && popd
	cpmcp $(EMUPATH)/cpmsim/disks/drivec.dsk $(PROG).com 0:
	pushd  $(EMUPATH)/cpmsim && ./cpm22 && popd