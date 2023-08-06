main:
    li a0, 3
    li a1, 5

    call mull
    ebreak

mull:
    li a2, 0
loop_:
    beqz a1, end_
    add a2, a2, a0
    addi a1, a1, -1
    j loop_
end_:
    mv a0, a2
    ret