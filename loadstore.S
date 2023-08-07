DATA = 400

li t0, 3
li sp, 8
sw t0, DATA(sp)

li t0, 7
li sp, 12
sw t0, DATA(sp)

# read
li sp, 8
lw a0, DATA(sp)

addi sp, sp, 4
lw a0, DATA(sp)

ebreak