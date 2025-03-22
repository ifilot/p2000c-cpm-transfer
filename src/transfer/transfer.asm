org 0100h

; check for a start of block
startblock:
    mvi c,3         ; set function 3 (serial in)
    call 5          ; call BDOS, result stored in A
    cpi 01h         ; check if one
    jnz exit
    call printhex

blockword:
    mvi c,3         ; set function 3 (serial in)
    call 5          ; call BDOS, result stored in A
    call printhex
    mvi c,3         ; set function 3 (serial in)
    call 5          ; call BDOS, result stored in A
    call printhex
 
 

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

exit:
    ret