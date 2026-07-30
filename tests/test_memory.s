# Test 4: Memory Load and Store Alignment Test (SW, SH, SB, LW, LH, LHU, LB, LBU)
li x1, 0x12345678

# Store Word and Load Word
sw x1, 0(x0)
lw x2, 0(x0)     # x2 = 0x12345678

# Half-word load
lhu x3, 0(x0)    # x3 = 0x5678 (unsigned)
lh  x4, 0(x0)    # x4 = 0x00005678 (positive sign extension)

# Byte load
lbu x5, 0(x0)    # x5 = 0x78
lb  x6, 1(x0)    # x6 = 0x56

# Store Byte
li x7, 0xFF
sb x7, 0(x0)
lw x8, 0(x0)     # x8 = 0x123456FF

li x10, 4        # Passed memory alignment test
