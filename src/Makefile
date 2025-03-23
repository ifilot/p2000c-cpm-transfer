SHELL := /bin/bash
PROG := transfer

all: $(PROG).com

$(PROG).com: $(PROG).asm
	asm80 $(PROG).asm -o $(PROG).com

$(EMUPATH)/cpmsim/cpm22 $(EMUPATH)/cpmsim/srctools/mkdskimg:
	make -j -C ../../vendor/z80pack

disassemble: $(PROG).com
	dis80 $(PROG).com