# P2000C CP/M Transfer

## Requirements

### P2000C

To transfer files using the programs in this repository, you need to have
working Philips P2000C running CP/M 2.2 with the programs
* `PIP.COM`: To transfer text-based programs over serial
* `ASM.COM`: To compile assembly
* `LOAD.COM`: To create a `.COM` file

### Modern computer

Make sure all subbmodules are loaded

```bash
git submodule init
git submodule update --recursive --remote
```

And install the assembler / disassembler

```bash 
pipx install suite8080
```

## Serial communication settings

Unless otherwise specified, we assume throughout that the serial communication
proceeds using 9600 BAUD, one start bit, one stop bit and **No** parity
checking.

## Bootstrapping

First, we need to send over the assembly source code that contains the
transfer program. To do so, run the following on your P2000C

```
PIP TRANSFER.COM=RDR:
```

and run on your modern computer the script `sendasm.py`.