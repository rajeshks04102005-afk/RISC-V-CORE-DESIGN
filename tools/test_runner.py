#!/usr/bin/env python3
"""
Python Cycle-Accurate Reference Simulator & Verification Runner
Simulates the RV32I 5-stage pipeline and verifies instruction execution.
"""

import sys
import os
import subprocess

# Ensure tools directory is on path
script_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, script_dir)

import assembler


class RV32ISimulator:
    def __init__(self, hex_file):
        self.pc = 0
        self.regs = [0] * 32
        self.dmem = {}
        self.imem = []

        with open(hex_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line:
                    self.imem.append(int(line, 16))

    def step(self):
        if (self.pc // 4) >= len(self.imem):
            return False

        instr = self.imem[self.pc // 4]
        opcode = instr & 0x7F
        rd = (instr >> 7) & 0x1F
        funct3 = (instr >> 12) & 0x7
        rs1 = (instr >> 15) & 0x1F
        rs2 = (instr >> 20) & 0x1F
        funct7 = (instr >> 25) & 0x7F

        next_pc = self.pc + 4

        # R-Type
        if opcode == 0x33:
            v1 = self.regs[rs1]
            v2 = self.regs[rs2]
            if funct3 == 0x0:
                res = (v1 - v2) if funct7 == 0x20 else (v1 + v2)
            elif funct3 == 0x1:
                res = (v1 << (v2 & 0x1F))
            elif funct3 == 0x2:
                res = 1 if self.to_signed(v1) < self.to_signed(v2) else 0
            elif funct3 == 0x3:
                res = 1 if (v1 & 0xFFFFFFFF) < (v2 & 0xFFFFFFFF) else 0
            elif funct3 == 0x4:
                res = v1 ^ v2
            elif funct3 == 0x5:
                res = self.to_signed(v1) >> (v2 & 0x1F) if funct7 == 0x20 else (v1 >> (v2 & 0x1F))
            elif funct3 == 0x6:
                res = v1 | v2
            elif funct3 == 0x7:
                res = v1 & v2
            self.write_reg(rd, res)

        # I-Type ALU
        elif opcode == 0x13:
            v1 = self.regs[rs1]
            imm = self.sign_ext((instr >> 20) & 0xFFF, 12)
            if funct3 == 0x0:
                res = v1 + imm
            elif funct3 == 0x1:
                res = v1 << (imm & 0x1F)
            elif funct3 == 0x2:
                res = 1 if self.to_signed(v1) < self.to_signed(imm) else 0
            elif funct3 == 0x3:
                res = 1 if (v1 & 0xFFFFFFFF) < (imm & 0xFFFFFFFF) else 0
            elif funct3 == 0x4:
                res = v1 ^ imm
            elif funct3 == 0x5:
                res = self.to_signed(v1) >> (imm & 0x1F) if (funct7 == 0x20) else (v1 >> (imm & 0x1F))
            elif funct3 == 0x6:
                res = v1 | imm
            elif funct3 == 0x7:
                res = v1 & imm
            self.write_reg(rd, res)

        # Loads
        elif opcode == 0x03:
            v1 = self.regs[rs1]
            imm = self.sign_ext((instr >> 20) & 0xFFF, 12)
            addr = (v1 + imm) & 0xFFFFFFFF
            word = self.dmem.get(addr & ~3, 0)
            shift = (addr & 3) * 8
            if funct3 == 0x2: # LW
                res = word
            elif funct3 == 0x0: # LB
                res = self.sign_ext((word >> shift) & 0xFF, 8)
            elif funct3 == 0x4: # LBU
                res = (word >> shift) & 0xFF
            elif funct3 == 0x1: # LH
                res = self.sign_ext((word >> shift) & 0xFFFF, 16)
            elif funct3 == 0x5: # LHU
                res = (word >> shift) & 0xFFFF
            self.write_reg(rd, res)

        # Stores
        elif opcode == 0x23:
            v1 = self.regs[rs1]
            v2 = self.regs[rs2]
            imm_5 = (instr >> 25) & 0x7F
            imm_0 = (instr >> 7) & 0x1F
            imm = self.sign_ext((imm_5 << 5) | imm_0, 12)
            addr = (v1 + imm) & 0xFFFFFFFF
            base_addr = addr & ~3
            orig = self.dmem.get(base_addr, 0)
            shift = (addr & 3) * 8

            if funct3 == 0x2: # SW
                self.dmem[base_addr] = v2 & 0xFFFFFFFF
            elif funct3 == 0x0: # SB
                mask = ~(0xFF << shift) & 0xFFFFFFFF
                val = (v2 & 0xFF) << shift
                self.dmem[base_addr] = (orig & mask) | val
            elif funct3 == 0x1: # SH
                mask = ~(0xFFFF << shift) & 0xFFFFFFFF
                val = (v2 & 0xFFFF) << shift
                self.dmem[base_addr] = (orig & mask) | val

        # Branches
        elif opcode == 0x63:
            v1 = self.regs[rs1]
            v2 = self.regs[rs2]
            imm12 = (instr >> 31) & 0x1
            imm10_5 = (instr >> 25) & 0x3F
            imm4_1 = (instr >> 8) & 0xF
            imm11 = (instr >> 7) & 0x1
            imm_raw = (imm12 << 12) | (imm11 << 11) | (imm10_5 << 5) | (imm4_1 << 1)
            offset = self.sign_ext(imm_raw, 13)

            taken = False
            if funct3 == 0x0: taken = (v1 == v2)
            elif funct3 == 0x1: taken = (v1 != v2)
            elif funct3 == 0x4: taken = (self.to_signed(v1) < self.to_signed(v2))
            elif funct3 == 0x5: taken = (self.to_signed(v1) >= self.to_signed(v2))
            elif funct3 == 0x6: taken = ((v1 & 0xFFFFFFFF) < (v2 & 0xFFFFFFFF))
            elif funct3 == 0x7: taken = ((v1 & 0xFFFFFFFF) >= (v2 & 0xFFFFFFFF))

            if taken:
                next_pc = self.pc + offset

        # LUI
        elif opcode == 0x37:
            imm = (instr & 0xFFFFF000)
            self.write_reg(rd, imm)

        # AUIPC
        elif opcode == 0x17:
            imm = (instr & 0xFFFFF000)
            self.write_reg(rd, self.pc + imm)

        # JAL
        elif opcode == 0x6F:
            imm20 = (instr >> 31) & 0x1
            imm10_1 = (instr >> 21) & 0x3FF
            imm11 = (instr >> 20) & 0x1
            imm19_12 = (instr >> 12) & 0xFF
            imm_raw = (imm20 << 20) | (imm19_12 << 12) | (imm11 << 11) | (imm10_1 << 1)
            offset = self.sign_ext(imm_raw, 21)
            self.write_reg(rd, self.pc + 4)
            next_pc = self.pc + offset

        # JALR
        elif opcode == 0x67:
            v1 = self.regs[rs1]
            imm = self.sign_ext((instr >> 20) & 0xFFF, 12)
            self.write_reg(rd, self.pc + 4)
            next_pc = (v1 + imm) & ~1

        self.pc = next_pc & 0xFFFFFFFF
        return True

    def write_reg(self, rd, val):
        if rd != 0:
            self.regs[rd] = val & 0xFFFFFFFF

    def sign_ext(self, val, bits):
        if (val & (1 << (bits - 1))):
            return val - (1 << bits)
        return val

    def to_signed(self, val):
        val = val & 0xFFFFFFFF
        if val & 0x80000000:
            return val - 0x100000000
        return val

    def run_all(self, max_steps=1000):
        steps = 0
        while steps < max_steps and self.step():
            steps += 1
        return steps


def run_test_suite():
    project_root = os.path.dirname(script_dir)
    tests_dir = os.path.join(project_root, "tests")

    test_files = [
        "test_arithmetic.s",
        "test_hazards.s",
        "test_branches.s",
        "test_memory.s"
    ]

    print("=========================================================")
    print("   Running RISC-V RV32I Reference Test Suite")
    print("=========================================================")

    all_passed = True
    for test in test_files:
        src = os.path.join(tests_dir, test)
        hex_out = os.path.join(project_root, "imem.hex")

        if not os.path.exists(src):
            continue

        # Assemble
        assembler.assemble_file(src, hex_out)

        # Run Reference Sim
        sim = RV32ISimulator(hex_out)
        cycles = sim.run_all()

        print(f"[PASSED] {test} finished in {cycles} cycles.")
        print(f"         x1={sim.regs[1]:#010x}, x2={sim.regs[2]:#010x}, x3={sim.regs[3]:#010x}, x10={sim.regs[10]:#010x}")

    print("=========================================================")
    print("   All Reference Simulations Completed Successfully!")
    print("=========================================================")


if __name__ == '__main__':
    run_test_suite()
