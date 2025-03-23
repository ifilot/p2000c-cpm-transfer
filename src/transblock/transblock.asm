ORG 100H

START:
        MVI C,3
        CALL 5
        CPI 01H
        JNZ EXIT

; READ FILENAME OVER SERIAL
        MVI B,11
        LXI H,FILENAME
        CALL READSERIAL

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

EXIT:
        RET

FCB:
        DB 0
FILENAME:
        DB 'MYFILE  BIN'
        DS 20