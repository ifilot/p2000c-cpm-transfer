org 0100h

; check for a start of block
startblock:
    mvi c,3         ; set function 3 (serial in)
    call 5          ; call BDOS, result stored in A
    cpi 01h         ; check if one
    jnz exit

    mvi b,128       ; set number of bytes
    lxi h,200h      ; set storage pointer
nextbyte:
    push bc         ; push counter onto stack
    push hl         ; push address onto stack
    mvi c,3         ; set function 3 (serial in)
    call 5          ; call BDOS, result stored in A
    pop hl          ; retrieve storage address
    mov m,a         ; store in memory
    inx hl          ; increment storage pointer
    pop bc          ; retrieve counter from stack
    dcr b           ; decrement counter
    jnz nextbyte    ; next byte

    lxi d,fcb
    mvi c,13h       ; delete file if it exists
    call 5

    lxi d,fcb
    mvi c,16h       ; create file
    call 5

    lxi d,200h
    mvi c,1ah
    call 5

    lxi d,fcb
    mvi c,22h       ; write sequential
    call 5

    lxi d,fcb
    mvi c,10h       ; close file
    call 5

    jmp exit

exit:
    rst 7

fcb:
    db 0
    db 'MYFILE  BIN'
    ds 20