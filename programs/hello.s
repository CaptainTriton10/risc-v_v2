li x1, 0x7000

li x2, 0x48656c6c
sw x2, 0(x1)
addi x1, x1, 4

li x2, 0x6f2c2057
sw x2, 0(x1)
addi x1, x1, 4

li x2, 0x6f726c64
sw x2, 0(x1)
addi x1, x1, 4

li x2, 0x21000000
sw x2, 0(x1)
addi x1, x1, 4

loop: j loop
