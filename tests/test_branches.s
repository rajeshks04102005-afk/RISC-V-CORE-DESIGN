# Test 3: Branch and Jump Control Hazard Test
li x1, 10
li x2, 20
li x3, 0

# Branch Not Taken Test
beq x1, x2, taken_label
addi x3, x3, 1   # x3 = 1 (Executed because branch not taken)

# Branch Taken Test
bne x1, x2, taken_label
addi x3, x3, 100 # Should be flushed!

taken_label:
addi x3, x3, 5   # x3 = 6

# JAL Test
jal x4, jump_label
addi x3, x3, 200 # Should be flushed!

jump_label:
# x4 should hold return PC address
addi x3, x3, 10  # x3 = 16

li x10, 3        # Passed control hazard test
