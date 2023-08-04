    
# count to N and repeat
    # x1 = 0
    add x1, x0, x0
    # x2 = N
    addi x2, x0, 63
LOOP:
    addi x1, x1, 1 # x1 += 1
    bne x1, x2, LOOP # if x1 != x2, goto LOOP

    add x1, x0, x0 # x1 = 0
    jal x0, LOOP # start again
