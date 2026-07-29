.text
.globl _start
_start:
    li   x1, 5 #00      # счетчик = 5 
    li   x2, 0 #04      # сумма = 0

while_loop:
    beq  x1, x0, end #08  # если x1 == 0, выходим из цикла
    add  x2, x2, x1 #0C   # sum += x1
    addi x1, x1, -1 #10  # x1--
    j    while_loop #14

end:
    sw   x2, 0(x0) #18    # сохраняем сумму в память (по адресу 0)
    mv   x3, x2  #1C      # копируем результат в x3 для проверки

    # бесконечный цикл (завершение)
    nop #20
    nop
    nop
    nop
