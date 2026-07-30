#!/usr/bin/env python3
"""
RISC-V RV32I Assembler
Converts RISC-V Assembly (.s) files into Hexadecimal Machine Code (.hex)
for Verilog memory initialization ($readmemh).
"""

import sys
import os
import re

REG_MAP = {
    'zero': 0, 'ra': 1, 'sp': 2, 'gp': 3, 'tp': 4,
    't0': 5, 't1': 6, 't2': 7, 's0': 8, 'fp': 8, 's1': 9,
    'a0': 10, 'a1': 11, 'a2': 12, 'a3': 13, 'a4': 14, 'a5': 15,
    'a6': 16, 'a7': 17, 's2': 18, 's3': 19, 's4': 20, 's5': 21,
    's6': 22, 's7': 23, 's8': 24, 's9': 25, 's10': 26, 's11': 27,
    't3': 28, 't4': 29, 't5': 30, 't6': 31
}

for i in range(32):
    REG_MAP[f'x{i}'] = i


def parse_reg(reg_str):
    reg_str = reg_str.strip().lower()
    if reg_str in REG_MAP:
        return REG_MAP[reg_str]
    raise ValueError(f"Invalid register name: '{reg_str}'")


def parse_imm(imm_str, bits=32):
    imm_str = imm_str.strip()
    if imm_str.startswith("0x") or imm_str.startswith("0X"):
        val = int(imm_str, 16)
    elif imm_str.startswith("0b") or imm_str.startswith("0B"):
        val = int(imm_str, 2)
    else:
        val = int(imm_str)
    return val


def encode_r(opcode, funct3, funct7, rd, rs1, rs2):
    return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode


def encode_i(opcode, funct3, rd, rs1, imm):
    imm = imm & 0xFFF
    return (imm << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode


def encode_s(opcode, funct3, rs1, rs2, imm):
    imm = imm & 0xFFF
    imm_11_5 = (imm >> 5) & 0x7F
    imm_4_0 = imm & 0x1F
    return (imm_11_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm_4_0 << 7) | opcode


def encode_b(opcode, funct3, rs1, rs2, imm):
    imm = imm & 0x1FFF
    imm_12 = (imm >> 12) & 0x1
    imm_11 = (imm >> 11) & 0x1
    imm_10_5 = (imm >> 5) & 0x3F
    imm_4_1 = (imm >> 1) & 0xF
    return (imm_12 << 31) | (imm_10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm_4_1 << 8) | (imm_11 << 7) | opcode


def encode_u(opcode, rd, imm):
    imm_20 = (imm >> 12) & 0xFFFFF
    return (imm_20 << 12) | (rd << 7) | opcode


def encode_j(opcode, rd, imm):
    imm = imm & 0x1FFFFF
    imm_20 = (imm >> 20) & 0x1
    imm_19_12 = (imm >> 12) & 0xFF
    imm_11 = (imm >> 11) & 0x1
    imm_10_1 = (imm >> 1) & 0x3FF
    return (imm_20 << 31) | (imm_10_1 << 21) | (imm_11 << 20) | (imm_19_12 << 12) | (rd << 7) | opcode


def assemble_line(line, pc, labels):
    line = re.sub(r'#.*', '', line)
    line = re.sub(r'//.*', '', line)
    line = line.strip()
    if not line:
        return None

    # Handle memory access syntax like lw rd, offset(rs1)
    line = re.sub(r'(-?\d+|0x[0-9a-fA-F]+)\s*\(\s*([a-zA-Z0-9]+)\s*\)', r'\2, \1', line)

    parts = [p.strip() for p in re.split(r'[\s,]+', line) if p.strip()]
    if not parts:
        return None

    op = parts[0].lower()

    # R-Type
    r_ops = {
        'add':  (0x33, 0x0, 0x00), 'sub':  (0x33, 0x0, 0x20),
        'sll':  (0x33, 0x1, 0x00), 'slt':  (0x33, 0x2, 0x00),
        'sltu': (0x33, 0x3, 0x00), 'xor':  (0x33, 0x4, 0x00),
        'srl':  (0x33, 0x5, 0x00), 'sra':  (0x33, 0x5, 0x20),
        'or':   (0x33, 0x6, 0x00), 'and':  (0x33, 0x7, 0x00),
    }

    if op in r_ops:
        opcode, funct3, funct7 = r_ops[op]
        rd = parse_reg(parts[1])
        rs1 = parse_reg(parts[2])
        rs2 = parse_reg(parts[3])
        return encode_r(opcode, funct3, funct7, rd, rs1, rs2)

    # I-Type ALU
    i_ops = {
        'addi':  (0x13, 0x0), 'slti':  (0x13, 0x2), 'sltiu': (0x13, 0x3),
        'xori':  (0x13, 0x4), 'ori':   (0x13, 0x6), 'andi':  (0x13, 0x7),
        'slli':  (0x13, 0x1), 'srli':  (0x13, 0x5), 'srai':  (0x13, 0x5),
    }

    if op in i_ops:
        opcode, funct3 = i_ops[op]
        rd = parse_reg(parts[1])
        rs1 = parse_reg(parts[2])
        imm = parse_imm(parts[3])
        if op == 'srai':
            imm |= 0x400 # set bit 10 of imm for SRAI
        return encode_i(opcode, funct3, rd, rs1, imm)

    # Loads (I-type)
    loads = {
        'lb': (0x03, 0x0), 'lh': (0x03, 0x1), 'lw': (0x03, 0x2),
        'lbu': (0x03, 0x4), 'lhu': (0x03, 0x5),
    }

    if op in loads:
        opcode, funct3 = loads[op]
        rd = parse_reg(parts[1])
        rs1 = parse_reg(parts[2])
        imm = parse_imm(parts[3])
        return encode_i(opcode, funct3, rd, rs1, imm)

    # JALR (I-type)
    if op == 'jalr':
        rd = parse_reg(parts[1])
        rs1 = parse_reg(parts[2])
        imm = parse_imm(parts[3]) if len(parts) > 3 else 0
        return encode_i(0x67, 0x0, rd, rs1, imm)

    # Stores (S-type)
    stores = {
        'sb': (0x23, 0x0), 'sh': (0x23, 0x1), 'sw': (0x23, 0x2),
    }

    if op in stores:
        opcode, funct3 = stores[op]
        rs2 = parse_reg(parts[1])
        rs1 = parse_reg(parts[2])
        imm = parse_imm(parts[3])
        return encode_s(opcode, funct3, rs1, rs2, imm)

    # Branches (B-type)
    branches = {
        'beq': (0x63, 0x0), 'bne': (0x63, 0x1), 'blt': (0x63, 0x4),
        'bge': (0x63, 0x5), 'bltu': (0x63, 0x6), 'bgeu': (0x63, 0x7),
    }

    if op in branches:
        opcode, funct3 = branches[op]
        rs1 = parse_reg(parts[1])
        rs2 = parse_reg(parts[2])
        target_str = parts[3]
        if target_str in labels:
            offset = labels[target_str] - pc
        else:
            offset = parse_imm(target_str)
        return encode_b(opcode, funct3, rs1, rs2, offset)

    # U-type
    if op in ['lui', 'auipc']:
        opcode = 0x37 if op == 'lui' else 0x17
        rd = parse_reg(parts[1])
        imm = parse_imm(parts[2])
        return encode_u(opcode, rd, imm)

    # J-type
    if op == 'jal':
        rd = parse_reg(parts[1])
        target_str = parts[2]
        if target_str in labels:
            offset = labels[target_str] - pc
        else:
            offset = parse_imm(target_str)
        return encode_j(0x6F, rd, offset)

    # Pseudo-instructions
    if op == 'nop':
        return encode_i(0x13, 0x0, 0, 0, 0) # addi x0, x0, 0

    if op == 'mv':
        rd = parse_reg(parts[1])
        rs1 = parse_reg(parts[2])
        return encode_i(0x13, 0x0, rd, rs1, 0) # addi rd, rs1, 0

    if op == 'j':
        target_str = parts[1]
        offset = labels[target_str] - pc if target_str in labels else parse_imm(target_str)
        return encode_j(0x6F, 0, offset) # jal x0, offset

    if op == 'li':
        rd = parse_reg(parts[1])
        imm = parse_imm(parts[2])
        return encode_i(0x13, 0x0, rd, 0, imm) # addi rd, x0, imm

    raise ValueError(f"Unknown instruction '{op}' at PC 0x{pc:X}")


def assemble_file(src_path, dest_path):
    with open(src_path, 'r') as f:
        lines = f.readlines()

    # Pass 1: Collect Labels & Count Instructions
    labels = {}
    pc = 0
    clean_lines = []

    for line in lines:
        line_clean = re.sub(r'#.*', '', line)
        line_clean = re.sub(r'//.*', '', line_clean).strip()
        if not line_clean:
            continue

        if ':' in line_clean:
            parts = line_clean.split(':', 1)
            label_name = parts[0].strip()
            labels[label_name] = pc
            remainder = parts[1].strip()
            if remainder:
                clean_lines.append((pc, remainder))
                pc += 4
        else:
            clean_lines.append((pc, line_clean))
            pc += 4

    # Pass 2: Encode Machine Instructions
    hex_words = []
    for inst_pc, inst_line in clean_lines:
        code = assemble_line(inst_line, inst_pc, labels)
        if code is not None:
            hex_words.append(f"{code:08x}")

    with open(dest_path, 'w') as f:
        for word in hex_words:
            f.write(word + '\n')

    print(f"[Assembler] Assembled {len(hex_words)} instructions from '{src_path}' -> '{dest_path}'")


if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: python assembler.py <input.s> <output.hex>")
        sys.exit(1)
    assemble_file(sys.argv[1], sys.argv[2])
