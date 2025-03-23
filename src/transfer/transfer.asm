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

; READ NUMBER OF BLOCKS OVER SERIAL
    MVI B,2
    LXI H,NRBLOCKS
    CALL READSERIAL

; PRINT FILENAME
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

; PRINT NUMBER OF BLOCKS
    LXI H, NRBLOCKS
    MOV E, M       ; Load low byte into E
    INX H          ; Increment HL to point to next byte
    MOV D, M       ; Load high byte into D
    PUSH D
    MOV A,D
    CALL PRINTHEX
    POP D
    MOV A,E
    CALL PRINTHEX
    JMP EXIT

; READ BLOCK OVER SERIAL
    MVI B,128
    LXI H,200H
    CALL READSERIAL

; STORE FILE ON DISK
    CALL STOREBLOCK
    JMP EXIT

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
STOREBLOCK:
    LXI D,FCB
    MVI C,13H
    CALL 5

    LXI D,FCB
    MVI C,16H
    CALL 5

    LXI D,200H
    MVI C,1AH
    CALL 5

    LXI D,FCB
    MVI C,22H
    CALL 5

    LXI D,FCB
    MVI C,10H
    CALL 5

    RET

;
; print accumulator to the screen
; garbles: a,c,e
;
printhex:
    push psw            ; save original value
    ani 0F0h            ; mask lower byte
    rrc                 ; rotate right 4 times
    rrc
    rrc
    rrc
    call printnibble    ; print nibble
    pop psw             ; retrieve original value
    ani 0Fh             ; mask upper byte
    call printnibble    ; print nibble
    ret

printnibble:
    cpi 0Ah             ; is smaller than A?
    jc isdigit          ; if so, print digit
    adi 37h             ; else add 37h to get 'A' and higher
    jmp printchar       ; then print digit

isdigit:
    adi 30h             ; add 30 to convert to 0-based

printchar:
    mov e,a             ; put a in e
    mvi c,2             ; set function 2
    call 5              ; call BDOS
    ret

EXIT:
    RET

FCB:
    DB 0
FILENAME:
    DB 'MYFILE  BIN'
    DS 24

NRBLOCKS:
    DB 0,0