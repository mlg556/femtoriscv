.start:
    li t1, 1
    li t2, 1
    li t3, 0

    mv a0, t1 # print(x1)

loop:
    add t3, t1, t2
    mv t2, t1
    mv t1, t3
    mv a0, t1 # print(x1)
    j loop

