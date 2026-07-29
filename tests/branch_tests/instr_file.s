.text
.globl _start
_start:
    # Инициализация
    addi x1, x0, 10       # x1 = 10
    addi x2, x0, 20       # x2 = 20
    addi x3, x0, 10       # x3 = 10 (равно x1)
    addi x4, x0, 5        # x4 = 5  (меньше x2)

    # BEQ: x1 == x3 -> должно перейти
    beq  x1, x3, beq_label
    addi x5, x0, 1        # не должно выполняться
beq_label:
    addi x5, x0, 100      # x5 = 100

    # BNE: x1 != x2 -> должно перейти
    bne  x1, x2, bne_label
    addi x6, x0, 2        # не должно выполняться
bne_label:
    addi x6, x0, 200      # x6 = 200

    # BLT: x4 (5) < x2 (20) -> должно перейти
    blt  x4, x2, blt_label
    addi x7, x0, 3        # не должно выполняться
blt_label:
    addi x7, x0, 300      # x7 = 300

    # BGE: x1 (10) >= x4 (5) -> должно перейти
    bge  x1, x4, bge_label
    addi x8, x0, 4        # не должно выполняться
bge_label:
    addi x8, x0, 400      # x8 = 400

    # BLTU: беззнаковое сравнение: x1 (10) < x4 (5)? нет -> не перейти
    bltu x1, x4, bltu_fail
    addi x9, x0, 500      # должно выполниться (x9 = 500)
    j    bltu_ok
bltu_fail:
    addi x9, x0, 0        # не должно выполняться
bltu_ok:
    nop

    # BGEU: беззнаковое: x2 (20) >= x1 (10)? да -> перейти
    bgeu x2, x1, bgeu_label
    addi x10, x0, 6       # не должно выполняться
bgeu_label:
    addi x10, x0, 600     # x10 = 600

exit:
    sw   x5, 0(x0)
    sw   x6, 4(x0)
    sw   x7, 8(x0)
    sw   x8, 12(x0)
    sw   x9, 16(x0)
    sw   x10, 20(x0)
    nop
