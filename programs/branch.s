.global _start

_start:
    addi t0, zero, 0xFF
    addi t1, zero, 0x34
    bge t0, t1, label
    # Branch NOT TAKEN == 0x111
    addi t0, zero, 0x111
    halt2: j halt2

label:
    # Branch TAKEN == 0x222
    addi t2, zero, 0x222
    halt: j halt
