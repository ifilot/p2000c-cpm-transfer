SHELL := /bin/bash

all: hex.com

hex.com: hex.asm
	asm80 hex.asm -o hex.com

run: hex.com
	pushd  ../../../z80pack/cpmsim/disks && rm -vf drivec.dsk && ../srctools/mkdskimg c && popd
	cpmcp ../../../z80pack/cpmsim/disks/drivec.dsk hex.com 0:
	pushd  ../../../z80pack/cpmsim && ./cpm22 && popd