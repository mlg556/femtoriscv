# fibonacci
# a=1
# b=1
# t=0

# while True:
#    t=a + b
#    b=a
#    a=t
#    print(a)
START:
    li t1, 1
    li t2, 1
    li t3, 0
    li t4, 1000

    mv x1, t1 # print(x1)

LOOP:
    bgt t1, t4, START # if x1 > 100 jump back to the beginning
    add t3, t1, t2
    mv t2, t1
    mv t1, t3
    mv x1, t1 # print(x1)
    j LOOP

