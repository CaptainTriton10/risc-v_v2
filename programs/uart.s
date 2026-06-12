.global _start

.macro set_constants
    li      t4, 0x7000
    li      t5, 0x6000
.endm

_start:
    set_constants
    j       L_loop

L_loop:
    # Get status
    lw      t0, 4(t5)
    andi    t0, t0, 1
    beqz    t0, L_loop   # Continue if no char

    lw      t0, 0(t5)

    addi    t1, zero, 8
    beq     t0, t1, L_delete

    sb      t0, 0(t4)
    addi    t4, t4, 1
    j       L_loop

L_delete:
    # addi    t4, t4, -1
    addi    ra, ra, 8
    ret