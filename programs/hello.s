.global _start

_start:
    li x1, 0x6000

    # 48 65 6C 6C 6F 2C 20 57 6F 72 6C 64 21

    li x2, 0x48C06580
    sw x2, 0(x1)
    addi x1, x1, 4

    li x2, 0x6C406C00
    sw x2, 0(x1)
    addi x1, x1, 4

    li x2, 0x6F302C20
    sw x2, 0(x1)
    addi x1, x1, 4

    li x2, 0x20105700
    sw x2, 0(x1)
    addi x1, x1, 4

    li x2, 0x6F0C7208
    sw x2, 0(x1)
    addi x1, x1, 4

    li x2, 0x6C046400
    sw x2, 0(x1)
    addi x1, x1, 4

    li x2, 0x21F00000
    sw x2, 0(x1)
    addi x1, x1, 4

    halt: j halt
