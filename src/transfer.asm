; ==============================================================================
;  CP/M Serial File Transfer Utility for Philips P2000C
; ------------------------------------------------------------------------------
;  Author      : Ivo Filot <ivo@ivofilot.nl>
;  Version     : 1.0.0
;  Target      : CP/M 2.2 (Philips P2000C)
;  Assembler   : ASM.COM
;  Origin      : 0100H (CP/M standard)
; ------------------------------------------------------------------------------
;  Description :
;    This program receives a file over the serial port and writes it to disk.
;    It waits for a trigger byte (0x01), receives an 8.3 filename, the number 
;    of 128-byte blocks, and the data blocks themselves. After receiving all 
;    blocks, it writes them sequentially to a new file on disk.
;
;    All communication is via BDOS calls. Serial input uses BDOS function 3 
;    and output uses function 2. Strings use function 9.
;
;  Serial Protocol :
;    - Baud rate  : 9600
;    - Format     : 8N1 (8 data bits, no parity, 1 stop bit)
;    - Trigger    : Byte 0x01 starts transfer
;    - Filename   : 11 bytes (8.3 format)
;    - Size       : 2 bytes (number of 128-byte blocks, little-endian)
;    - Data       : N blocks of 128 bytes
;    - Response   : 0x06 (ACK) sent after each block received
;
;  Program Flow :
;    1. Wait for trigger byte
;    2. Read filename
;    3. Read block count
;    4. Create file and set DMA buffer
;    5. Receive and write blocks
;    6. Close file and exit
;
;  Memory Layout :
;    FCB       : File Control Block
;    FILENAME  : 11-byte 8.3 filename
;    NRBLOCKS  : 2-byte block count
;    BUFFER    : 128-byte DMA buffer
;
;  Exit Code :
;    - Program returns to CP/M with RET instruction
; ==============================================================================

ORG 100H

; START PROGRAM
START:
    CALL PRINTSTARTMSG

; WAIT FOR BIT 1 TO START TRANSFER
WAIT:
    MVI C,3
    CALL 5
    CPI 01H
    JNZ EXIT        ; EXIT WHEN NO BIT 1 IS RECEIVED

; READ FILENAME OVER SERIAL
    MVI B,11
    LXI H,FILENAME
    CALL READSERIAL
    CALL PRINTFILENAME

; READ NUMBER OF BLOCKS OVER SERIAL
    MVI B,2
    LXI H,NRBLOCKS
    CALL READSERIAL
    CALL PRINTBLOCKS
    CALL DASHEDLINE

; OPEN FILE ON DISK
    CALL OPENFILE
    CALL SETBUFFER

; READ OVER BLOCKS
    CALL LOADNRBLOCKS   ; LOAD NUMBER OF BLOCKS IN DE
    LXI B,0             ; SET BLOCK COUNTER
NEXTBLOCK:
    INX B
    PUSH B              ; PUT BLOCK INCREMENTER ON STACK
    PUSH D              ; PUT BLOCK DECREMENTER ON STACK
    CALL PRINTCOUNTER
    MVI B,128           ; SET NUMBER OF BYTES
    LXI H,BUFFER        ; SET BUFFER
    CALL READSERIAL     ; READ SERIAL INPUT TO BUFFER
    CALL WRITEFILE      ; WRITE TO FILE
    CALL PRINTCHECKSUM
    MVI E, 6            ; LOAD ACKNOWLEDGE
    MVI C, 4            ; SEND OVER SERIAL
    CALL 5
    POP D               ; RETRIEVE BLOCK DECREMENTER
    POP B               ; RETRIEVE BLOCK INCREMENTER
    DCX D               ; DECREMENT BLOCK COUNTER
    MOV A,D
    ORA E               ; CHECK IF ZERO
    JNZ NEXTBLOCK       ; IF NOT, NEXT ITERATION

; CLOSE FILE
    CALL CLOSEFILE
    JMP EXIT

;-------------------------------------------------------------------------------
; READ NUMBER OF BYTES SET IN B OVER SERIAL AND STORE AT HL
;-------------------------------------------------------------------------------
READSERIAL:
    PUSH B
    PUSH H
    MVI C,3
    CALL 5
    POP H
    MOV M,A
    INX H
    POP B
    DCR B
    JNZ READSERIAL
    RET

;-------------------------------------------------------------------------------
; STORE BLOCK ON DISK
;-------------------------------------------------------------------------------
OPENFILE:
    LXI D,FCB
    MVI C,13H           ; ERASE IF FILE EXISTS
    CALL 5
    LXI D,FCB
    MVI C,22            ; CREATE NEW FILE
    CALL 5
    RET

;-------------------------------------------------------------------------------
; SET THE DMA BUFFER
;-------------------------------------------------------------------------------
SETBUFFER:
    LXI D,BUFFER
    MVI C,26            ; SET DMA
    CALL 5
    RET

; WRITE SEQUENTIALLY TO FILE
WRITEFILE:
    LXI D,FCB
    MVI C,21            ; WRITE BLOCK TO FILE
    CALL 5
    CPI 0FFH
    JZ WRITEERR
    RET

;-------------------------------------------------------------------------------
; CLOSE THE FILE
;-------------------------------------------------------------------------------
CLOSEFILE:
    LXI D,FCB
    MVI C,16            ; CLOSE FILE
    CALL 5
    RET

;-------------------------------------------------------------------------------
; PRINT FILENAME
;-------------------------------------------------------------------------------
PRINTFILENAME:
    LXI D,MSGFN
    MVI C,9
    CALL 5

    MVI B,8
    LXI H,BASENAME
NEXTCHARBASE:           ; PRINT BASENAME
    PUSH B
    PUSH H
    MOV A,M
    CPI 20H             ; COMPARE WITH SPACE
    JZ SKIPBASE
    MOV E,M
    MVI C,2
    CALL 5
    POP H
    INX H
    POP B
    DCR B
    JNZ NEXTCHARBASE
    JMP PRINTDOT
SKIPBASE:               ; STOP PRINTING BASENAME AND CLEAN STACK
    POP H
    POP B
PRINTDOT:
    MVI E,2EH           ; LOAD DOT
    MVI C,2
    CALL 5
PRINTEXT:               ; PRINT EXTENSION
    MVI B,3
    LXI H,EXTENSION
NEXTCHAREXT:
    PUSH B
    PUSH H
    MOV A,M
    CPI 20H             ; COMPARE WITH SPACE
    JZ PRINTEXT
    MOV E,M
    MVI C,2
    CALL 5
    POP H
    INX H
    POP B
    DCR B
    JNZ NEXTCHAREXT
    CALL NEWLINE
    RET

MSGFN:
    DB 'Transferring: $'

;-------------------------------------------------------------------------------
; PRINT NUMBER OF BLOCKS TO RECEIVE
;-------------------------------------------------------------------------------
PRINTBLOCKS:
    LXI D, MSGBLK1
    MVI C,9
    CALL 5
    
    CALL LOADNRBLOCKS
    CALL PRINTHEX16

    LXI D, MSGBLK2
    MVI C,9
    CALL 5
    CALL NEWLINE

    RET

MSGBLK1:
    DB 'Receiving: $'
MSGBLK2:
    DB 'H blocks.$'

;-------------------------------------------------------------------------------
; PRINT BLOCK COUNTER
;-------------------------------------------------------------------------------
PRINTCOUNTER:
    PUSH B              ; PUT BLOCK COUNTER ON STACK
    LXI D, MSGC
    MVI C,9
    CALL 5
    POP D               ; RETRIEVE BLOCK COUNTER IN DE
    CALL PRINTHEX16
    LXI D,MSGC2         ; WRITE SEPARATOR
    MVI C,9
    CALL 5
    CALL LOADNRBLOCKS
    CALL PRINTHEX16     ; WRITE TOTAL NUMBER OF BLOCKS
    MVI E,48H           ; WRITE 'H'
    MVI C,2
    CALL 5
    RET

MSGC:
    DB 'Block: $'
MSGC2:
    DB 'H / $'

;-------------------------------------------------------------------------------
; PRINT CHECKSUM ON SCREEN AND SEND IT OVER SERIAL
;-------------------------------------------------------------------------------
PRINTCHECKSUM:
    LXI D,MSGCHK
    MVI C,9
    CALL 5

    CALL CHECKSUM       ; CALCULATE CHECKSUM (STORE IN A)
    PUSH PSW            ; STORE CHECKSUM ON STACK
    MOV E, A
    MVI C, 4            ; SEND CHECKSUM OVER SERIAL
    CALL 5
    POP PSW             ; RETRIEVE CHECKSUM
    CALL PRINTHEX       ; PRINT CHECKSUM ON SCREEN

    CALL NEWLINE
    RET

MSGCHK:
    DB '   Checksum: $'

;-------------------------------------------------------------------------------
; LOAD NUMBER OF BLOCKS IN DE
;-------------------------------------------------------------------------------
LOADNRBLOCKS:
    LXI H, NRBLOCKS
    MOV E, M
    INX H
    MOV D, M
    RET

;-------------------------------------------------------------------------------
; WRITE ERROR
;-------------------------------------------------------------------------------
WRITEERR:
    POP D               ; CLEAN STACK
    MVI E,'E'
    MVI C,3
    CALL 5
    JMP EXIT

;-------------------------------------------------------------------------------
; PRINT DE TO THE SCREEN IN HEX
; GARBLES: A, C, E
;-------------------------------------------------------------------------------
PRINTHEX16:
    PUSH D
    MOV A,D
    CALL PRINTHEX
    POP D
    MOV A,E
    CALL PRINTHEX
    RET

;-------------------------------------------------------------------------------
; PRINT ACCUMULATOR TO THE SCREEN IN HEX
; GARBLES: A, C, E
;-------------------------------------------------------------------------------
PRINTHEX:
    PUSH PSW            ; SAVE ORIGINAL VALUE
    ANI 0F0H            ; MASK LOWER BYTE
    RRC                 ; ROTATE RIGHT 4 TIMES
    RRC
    RRC
    RRC
    CALL PRINTNIBBLE    ; PRINT NIBBLE
    POP PSW             ; RETRIEVE ORIGINAL VALUE
    ANI 0FH             ; MASK UPPER BYTE
    CALL PRINTNIBBLE    ; PRINT NIBBLE
    RET

PRINTNIBBLE:
    CPI 0AH             ; IS SMALLER THAN A?
    JC ISDIGIT          ; IF SO, PRINT DIGIT
    ADI 37H             ; ELSE ADD 37H TO GET 'A' AND HIGHER
    JMP PRINTCHAR       ; THEN PRINT DIGIT

ISDIGIT:
    ADI 30H             ; ADD 30 TO CONVERT TO 0-BASED

PRINTCHAR:
    MOV E, A            ; PUT A IN E
    MVI C, 2            ; SET FUNCTION 2
    CALL 5              ; CALL BDOS
    RET

;-------------------------------------------------------------------------------
; PRINT NEWLINE
;-------------------------------------------------------------------------------
NEWLINE:
    MVI E, 0DH
    MVI C, 2
    CALL 5
    MVI E, 0AH
    MVI C, 2
    CALL 5
    RET

;-------------------------------------------------------------------------------
; CALCULATE CHECKSUM OF BUFFER DATA
;-------------------------------------------------------------------------------
CHECKSUM:
    LXI H,BUFFER
    MVI B,128
    MVI A,0
CHKNEXTBYTE:
    MOV C,M
    ADD C
    INX H
    DCR B
    JNZ CHKNEXTBYTE
    RET

;-------------------------------------------------------------------------------
; PRINT DASHED LINE
;-------------------------------------------------------------------------------
DASHEDLINE:
    LXI D, SMSG2            ; PRINT DASHED LINE
    MVI C,9
    CALL 5
    CALL NEWLINE
    RET

;-------------------------------------------------------------------------------
; PRINT START MESSAGE
;-------------------------------------------------------------------------------
PRINTSTARTMSG:
    LXI H, MSGTABLE         ; POINT MESSAGE TO TABLE

PRINTMSGLOOP:
    MOV E, M                ; GET LOW BYTE
    INX H
    MOV D, M                ; GET HIGH BYTE
    INX H

    MOV A, D
    ORA E
    JZ EXITPRINT

    PUSH H
    MVI C, 9
    CALL 5
    CALL NEWLINE
    POP H
    JMP PRINTMSGLOOP
EXITPRINT:
    RET

;-------------------------------------------------------------------------------
; TABLE OF MESSAGES TO PRINT (null-terminated)
;-------------------------------------------------------------------------------
MSGTABLE:
    DW SMSG2
    DW SMSG1
    DW SMSGAUTH
    DW SMSG2
    DW SMSG3
    DW SMSG4
    DW 0

SMSG1:
    DB '   Philips P2000C File Transfer program - Version 1.0.0$'
SMSGAUTH:
    DB '   Copyright (C) 2025 - Ivo Filot / ivo@ivofilot.nl$'
SMSG2:
    DB '----------------------------------------------------------$'
SMSG3:
    DB 'Settings: 9600 BAUD / 1 START bit / 1 STOP bit / NO parity.$'
SMSG4:
    DB 'READY to receive file over SERIAL port.$'

;-------------------------------------------------------------------------------
; EXIT THE PROGRAM
;-------------------------------------------------------------------------------
EXIT:
    CALL DASHEDLINE
    LXI D,MSGEXIT
    MVI C,9
    CALL 5
    RET

MSGEXIT:
    DB 'End of program$'

;-------------------------------------------------------------------------------
; VARIABLES AND STORAGE
;-------------------------------------------------------------------------------
FCB:
    DB 0
FILENAME:
BASENAME:
    DB 'MYFILE  '
EXTENSION:
    DB 'BIN'
FCBEXTENT:
    DB 0,0,0,0,0,0,0,0
    DB 0,0,0,0,0,0,0,0
    DB 0,0,0,0,0,0,0,0

NRBLOCKS:
    DB 0,0

BUFFER:
    DS 128