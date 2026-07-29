.text
.globl _start
_start:
    addi x5, x0, 5
    addi x6, x0, 7
    blt  x5, x6, less_add
    sub  x7, x6, x5
    j    exit
less_add:
    add  x7, x5, x6
exit:
    sw   x7, 0(x0)
    lw   x8, 0(x0)
    nop
