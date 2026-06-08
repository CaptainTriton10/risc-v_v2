.global _start

.macro load_constants
    li t6, 0x7000
.endm

_start:
    load_constants
    li t0, 0x41424344 # t0 = 0x41424344
    sw t0, 0(t6)

    halt: j halt

    li t0, 0x31323334 # t0 = 0x31323334
    sw t0, 80(t6) 
