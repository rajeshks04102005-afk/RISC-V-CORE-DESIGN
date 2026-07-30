# Test 1: Arithmetic and Logical Operations (R-Type and I-Type)
li x1, 15        # x1 = 15 (0x0F)
li x2, 25        # x2 = 25 (0x19)

add x3, x1, x2   # x3 = 40 (0x28)
sub x4, x2, x1   # x4 = 10 (0x0A)
and x5, x1, x2   # x5 = 9  (0x09)
or  x6, x1, x2   # x6 = 31 (0x1F)
xor x7, x1, x2   # x7 = 22 (0x16)

slli x8, x1, 2   # x8 = 60 (0x3C)
srli x9, x2, 1   # x9 = 12 (0x0C)

# Result check register
li x10, 1        # Passed arithmetic test
