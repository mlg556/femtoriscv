DATA = 100 # base address of data section
WORD = 4 #each word is 32 bits = 4 bytes
WAIT = 500_000

    li sp, 0
    li a1, 1
    sw a1, DATA(sp)

    li a1, 2
    addi sp, sp, WORD
    sw a1, DATA(sp)

    li a1, 3
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
    li x4, WAIT
loop:
    beqz x4, stop
    addi x4, x4, -1
    j loop
stop:
    ret

ebreak