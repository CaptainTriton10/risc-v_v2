.global _start

_start:
    addi a1, zero, 0x5D # addi x4, x0, 0x5D
    jal ra, add_ten # jal x1, add_ten
    addi a1, a1, 10
    halt: j halt

add_ten:
    addi a1, a1, 10
    ret # jalr zero, 0(ra)
