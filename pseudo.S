    li x1, 0
    li x2, 10
LOOP:
    addi x1, x1, 1
    bne x1, x2, LOOP

    li x1, 0
    j LOOP
