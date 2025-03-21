SHELL := /bin/bash

all: hello.com

hello.com: hello.asm
	asm80 hello.asm -o hello.com

run: hello.com
	pushd  ../../../z80pack/cpmsim/disks && rm -vf drivec.dsk && ../srctools/mkdskimg c && popd
	cpmcp ../../../z80pack/cpmsim/disks/drivec.dsk hello.com 0:
	pushd  ../../../z80pack/cpmsim && ./cpm22 && popd