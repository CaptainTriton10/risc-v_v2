.global _start

# t0 - count
# t1 - store data
# t3 - limit
# t6 - fb addr

_start:
    jal ra, print_message

    li t6, 0x7000
    addi t6, t6, 80
    addi t0, zero, 0    # count = 0
    addi t3, zero, 9    # limit = 9
    j loop              # start loop

print_message:
    # "Counter example:"
    
    li t6, 0x7000
    li t0, 0x436F756E
    sw t0, 0(t6)

    li t0, 0x74657220
    sw t0, 4(t6)

    li t0, 0x6578616D
    sw t0, 8(t6)

    li t0, 0x706C653A
    sw t0, 12(t6)

    ret                 # return

loop:
    addi t1, t0, 0x31   # store_data = count + 0x31
    addi t0, t0, 1      # count = count + 1
    sb t1, 0(t6)        # store(store_data @ fb_addr)

    bge t0, t3, exit    # if count >= limit then exit
    addi t6, t6, 2      # fb_addr = fb_addr + 2

    j loop              # continue

exit:
    halt: j halt
