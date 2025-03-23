ORG 100H

; START PROGRAM
START:
    MVI C,3
    CALL 5
    CPI 01H
    JNZ EXIT

; READ FILENAME OVER SERIAL
    MVI B,11
    LXI H,FILENAME
    CALL READSERIAL
    CALL PRINTFILENAME
    CALL NEWLINE

; READ NUMBER OF BLOCKS OVER SERIAL
    MVI B,2
    LXI H,NRBLOCKS
    CALL READSERIAL
    CALL LOADNRBLOCKS
    CALL PRINTBLOCKS
    CALL NEWLINE

; OPEN FILE ON DISK
    CALL OPENFILE
    CALL SETBUFFER

; READ OVER BLOCKS
    CALL LOADNRBLOCKS
NEXTBLOCK:
    PUSH D
    CALL PRINTBLOCKS
    CALL NEWLINE
    POP D
    PUSH D
    MVI B,128
    LXI H,BUFFER
    CALL READSERIAL
    CALL WRITEFILE
    MVI E, 6            ; LOAD ACKNOWLEDGE
    MVI C, 4            ; SEND OVER SERIAL
    CALL 5
    POP D
    DCX D
    MOV A,D
    ORA E
    JNZ NEXTBLOCK

; CLOSE FILE
    CALL CLOSEFILE
    JMP EXIT

; READ NUMBER OF BYTES SET IN B OVER SERIAL AND STORE AT HL
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

; STORE BLOCK ON DISK
OPENFILE:
    LXI D,FCB
    MVI C,13H           ; ERASE IF FILE EXISTS
    CALL 5
    LXI D,FCB
    MVI C,22            ; CREATE NEW FILE
    CALL 5
    RET

; SET THE DMA BUFFER
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

; CLOSE THE FILE
CLOSEFILE:
    LXI D,FCB
    MVI C,16            ; CLOSE FILE
    CALL 5
    RET

; PRINT FILENAME
PRINTFILENAME:
    MVI B,11
    LXI H,FILENAME
NEXTCHAR:
    PUSH B
    PUSH H
    MOV E,M
    MVI C,2
    CALL 5
    POP H
    INX H
    POP B
    DCR B
    JNZ NEXTCHAR
    RET

; PRINT NUMBER OF BLOCKS
PRINTBLOCKS:
    PUSH D
    MOV A,D
    CALL PRINTHEX
    POP D
    MOV A,E
    CALL PRINTHEX
    RET

; LOAD NUMBER OF BLOCKS IN DE
LOADNRBLOCKS:
    LXI H, NRBLOCKS
    MOV E, M
    INX H
    MOV D, M
    RET

; WRITE ERROR
WRITEERR:
    POP D               ; CLEAN STACK
    MVI E,'E'
    MVI C,3
    CALL 5
    JMP EXIT

;
; PRINT ACCUMULATOR TO THE SCREEN
; GARBLES: A, C, E
;
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

; PRINT NEWLINE
NEWLINE:
    MVI E, 0DH
    MVI C, 2
    CALL 5
    MVI E, 0AH
    MVI C, 2
    CALL 5
    RET

EXIT:
    RET

FCB:
    DB 0
FILENAME:
    DB 'MYFILE  BIN'
FCBEXTENT:
    DB 0,0,0,0,0,0,0,0
    DB 0,0,0,0,0,0,0,0
    DB 0,0,0,0,0,0,0,0

NRBLOCKS:
    DB 0,0

BUFFER:
    DS 128