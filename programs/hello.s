# 48 65 6C 6C 6F 2C 20 57 6F 72 6C 64 21
xor x1, x1, x1

li x2, 0x48656c6c
sw x2, 424(x1)
addi x1, x1, 1

li x2, 0x6f2c2057
sw x2, 424(x1)
addi x1, x1, 1

li x2, 0x6f726c64
sb x2, 424(x1)
addi x1, x1, 1

li x2, 0x21000000
sb x2, 424(x1)
addi x1, x1, 1
jal x0, 0