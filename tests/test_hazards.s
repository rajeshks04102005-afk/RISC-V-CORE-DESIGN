# Test 2: Data Hazard Forwarding and Load-Use Stall Test
li x1, 100       # x1 = 100

# EX->EX Forwarding: x2 depends directly on x1 produced in previous instruction
add x2, x1, x1   # x2 = 200 (EX->EX forwarding of x1)

# MEM->EX Forwarding: x3 depends on x1 (2 cycles prior) and x2 (1 cycle prior)
add x3, x2, x1   # x3 = 300 (EX->EX for x2, MEM->EX for x1)

# Store & Load-Use Hazard Test
sw x3, 0(x0)     # Store 300 into RAM address 0

# LW into x4 followed immediately by dependent ADD (Load-Use Stall)
lw x4, 0(x0)     # Load 300 from address 0 into x4
add x5, x4, x1   # x5 = 300 + 100 = 400 (Must insert stall bubble!)

# Verification marker
li x10, 2        # Passed hazards test
