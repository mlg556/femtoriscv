DATA = 100 # base address of data section
WORD = 4 #each word is 32 bits = 4 bytes
WAIT = 10_000

    li sp, 0
    li a1, 3
    sw a1, DATA(sp)

    li a1, 4
    addi sp, sp, WORD
    sw a1, DATA(sp)

    li a1, 5
    addi sp, sp, WORD
    sw a1, DATA(sp)


display:

    li sp, 0
    lw a0, DATA(sp)
    addi sp, sp, WORD
    call delay

    lw a0, DATA(sp)
    addi sp, sp, WORD
    call delay

    lw a0, DATA(sp)
    addi sp, sp, WORD
    call delay

    j display

delay:
    li t1, WAIT
loop:
    beqz t1, stop
    addi t1, t1, -1
    j loop
stop:
    ret

ebreak