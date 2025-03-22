org 0100h

; check for a start of block
start:
    lxi d,text
    mvi c,9
    call 5
    ret

text:
    db 'Hello World!$'