.global _start

_start:
    addi t0, zero, 0x111
    jal ra, next
    addi t0, zero, 0x333
    halt: j halt
    addi t0, zero, 0x555

next:
    addi t0, zero, 0x222
    ret
    addi t0, zero, 0x444