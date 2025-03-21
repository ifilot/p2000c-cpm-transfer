org 0100h

; check for a start of block
startblock:
    mvi a,55
    mov e,a
    mvi c,2
    call 5
    ret