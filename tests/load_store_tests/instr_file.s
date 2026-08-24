.text
.globl _start
_start:
    lui x1, 0x12345         # PC=0x00000000  x1 = 0x12345000
    auipc x2, 0x6789        # PC=0x00000004  x2 = PC + 0x6789000
    addi x3, x0, 0xAA       # PC=0x00000008  x3 = 170
    sw   x3, 32(x0)         # PC=0x0000000C  mem[32] = 0xAA
    addi x4, x0, 0xBB       # PC=0x00000010  x4 = 187
    sw   x4, 36(x0)         # PC=0x00000014  mem[36] = 0xBB
    addi x5, x0, 0xCC       # PC=0x00000018  x5 = 204
    sw   x5, 40(x0)         # PC=0x0000001C  mem[40] = 0xCC
    lw   x6, 32(x0)         # PC=0x00000020  x6 = 0x000000AA
    lh   x7, 36(x0)         # PC=0x00000024  x7 = 0x000000BB
    lb   x8, 40(x0)         # PC=0x00000028  x8 = 0xFFFFFFCC
    lbu  x9, 40(x0)         # PC=0x0000002C  x9 = 0x000000CC
    lhu  x10, 36(x0)        # PC=0x00000030  x10 = 0x000000BB
    addi x11, x0, 5         # PC=0x00000034
    addi x12, x0, 3         # PC=0x00000038
    add  x13, x11, x12      # PC=0x0000003C  8
    sub  x14, x11, x12      # PC=0x00000040  2
    and  x15, x11, x12      # PC=0x00000044  1
    or   x16, x11, x12      # PC=0x00000048  7
    xor  x17, x11, x12      # PC=0x0000004C  6
    sll  x18, x11, x12      # PC=0x00000050  5 << 3 = 40
    srl  x19, x11, x12      # PC=0x00000054  5 >> 3 = 0
    sra  x20, x11, x12      # PC=0x00000058  5 >> 3 = 0
    slt  x21, x11, x12      # PC=0x0000005C  5 < 3 ? 0
    sltu x22, x11, x12      # PC=0x00000060  0 (беззнаковое сравнение)
exit:
    nop                     # PC=0x00000064
