# Instruction Set

[Back to README](../README.md)

The core supports **35 RV32I instructions**.

| Type | Count | Instructions |
|---|---|---|
| R-type | 10 | ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND |
| I-type (ALU) | 9 | ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI |
| I-type (Load) | 5 | LB, LH, LW, LBU, LHU |
| I-type (Jump) | 1 | JALR |
| S-type (Store) | 3 | SB, SH, SW |
| B-type (Branch) | 6 | BEQ, BNE, BLT, BGE, BLTU, BGEU |
| J-type (Jump) | 1 | JAL |
| **Total** | **35** | |

Not implemented yet: `LUI`, `AUIPC`, `FENCE`, `ECALL`, `EBREAK` (see the [main README](../README.md)).

## Instruction Groups

### R-type (register and register)

Opcode `0110011`. Result = `rs1 (op) rs2`, written to `rd`.

| Instruction | What it does | funct7 | funct3 | ALUcontrol |
|---|---|---|---|---|
| `ADD` | rd = rs1 + rs2 | `0000000` | `000` | `0000` |
| `SUB` | rd = rs1 - rs2 | `0100000` | `000` | `0001` |
| `SLL` | rd = rs1 << rs2[4:0] | `0000000` | `001` | `0010` |
| `SLT` | rd = 1 if rs1 < rs2 (signed), else 0 | `0000000` | `010` | `0011` |
| `SLTU` | rd = 1 if rs1 < rs2 (unsigned), else 0 | `0000000` | `011` | `0100` |
| `XOR` | rd = rs1 ^ rs2 | `0000000` | `100` | `0101` |
| `SRL` | rd = rs1 >> rs2[4:0] (fills with 0) | `0000000` | `101` | `0110` |
| `SRA` | rd = rs1 >>> rs2[4:0] (keeps sign bit) | `0100000` | `101` | `0111` |
| `OR` | rd = rs1 \| rs2 | `0000000` | `110` | `1000` |
| `AND` | rd = rs1 & rs2 | `0000000` | `111` | `1001` |

### I-type (ALU with immediate)

Opcode `0010011`. The second ALU input is the 12-bit immediate (sign-extended).

| Instruction | What it does | funct7 | funct3 | ALUcontrol |
|---|---|---|---|---|
| `ADDI` | rd = rs1 + imm | n/a | `000` | `0000` |
| `SLTI` | rd = 1 if rs1 < imm (signed), else 0 | n/a | `010` | `0011` |
| `SLTIU` | rd = 1 if rs1 < imm (unsigned), else 0 | n/a | `011` | `0100` |
| `XORI` | rd = rs1 ^ imm | n/a | `100` | `0101` |
| `ORI` | rd = rs1 \| imm | n/a | `110` | `1000` |
| `ANDI` | rd = rs1 & imm | n/a | `111` | `1001` |
| `SLLI` | rd = rs1 << shamt | `0000000` | `001` | `0010` |
| `SRLI` | rd = rs1 >> shamt (fills with 0) | `0000000` | `101` | `0110` |
| `SRAI` | rd = rs1 >>> shamt (keeps sign bit) | `0100000` | `101` | `0111` |

### I-type (loads)

Opcode `0000011`. Address = `rs1 + imm`. The data read from memory goes to `rd`.

| Instruction | What it does | funct3 | LoadType |
|---|---|---|---|
| `LB` | load 1 byte, sign-extend | `000` | `000` |
| `LH` | load 2 bytes (halfword), sign-extend | `001` | `001` |
| `LW` | load 4 bytes (word) | `010` | `010` |
| `LBU` | load 1 byte, zero-extend | `100` | `100` |
| `LHU` | load 2 bytes, zero-extend | `101` | `101` |

### S-type (stores)

Opcode `0100011`. Address = `rs1 + imm`. The value of `rs2` is written to memory.

| Instruction | What it does | funct3 | StoreType |
|---|---|---|---|
| `SB` | store lowest byte of rs2 | `000` | `00` |
| `SH` | store lowest halfword of rs2 | `001` | `01` |
| `SW` | store full word of rs2 | `010` | `10` |

### B-type (branches)

Opcode `1100011`. If the condition is true, PC = `PC + imm`. The **Branch Box** in the EX stage checks the condition using `funct3`.

| Instruction | Branch if | funct3 | Comparison |
|---|---|---|---|
| `BEQ` | rs1 == rs2 | `000` | equal |
| `BNE` | rs1 != rs2 | `001` | not equal |
| `BLT` | rs1 < rs2 | `100` | signed |
| `BGE` | rs1 >= rs2 | `101` | signed |
| `BLTU` | rs1 < rs2 | `110` | unsigned |
| `BGEU` | rs1 >= rs2 | `111` | unsigned |

### Jumps

| Instruction | Opcode | What it does |
|---|---|---|
| `JAL` | `1101111` | rd = PC + 4, then PC = PC + imm (J-type immediate) |
| `JALR` | `1100111` (funct3 `000`) | rd = PC + 4, then PC = (rs1 + imm) with the lowest bit cleared |

### Control signals for every instruction

These are the signals the **Control Unit** produces in the ID stage. `-` means "not used / 0".

| Instruction group | RegWrite | ALUsrc | MemWrite | ResultSrc | ImmSrc | ALUcontrol | LoadType | StoreType | Branch | Jump | JumpItr |
|---|---|---|---|---|---|---|---|---|---|---|---|
| R-type | 1 | 0 (rs2) | 0 | `00` | `000` | by funct3/funct7 | - | - | 0 | 0 | 0 |
| I-type ALU | 1 | 1 (imm) | 0 | `00` | `001` | by funct3/funct7 | - | - | 0 | 0 | 0 |
| Loads | 1 | 1 (imm) | 0 | `01` | `001` | `0000` (ADD) | by funct3 | - | 0 | 0 | 0 |
| `JALR` | 1 | 1 (imm) | 0 | `10` | `001` | `0000` (ADD) | - | - | 0 | 1 | 1 |
| Stores | 0 | 1 (imm) | 1 | `00` | `010` | `0000` (ADD) | - | by funct3 | 0 | 0 | 0 |
| Branches | 0 | 0 | 0 | `00` | `011` | not used | - | - | 1 | 0 | 0 |
| `JAL` | 1 | 0 | 0 | `10` | `100` | not used | - | - | 0 | 1 | 0 |

## Instruction Formats and Immediates

### Bit layout of each format

| Type | 31:25 | 24:20 | 19:15 | 14:12 | 11:7 | 6:0 |
|---|---|---|---|---|---|---|
| **R** | funct7 | rs2 | rs1 | funct3 | rd | opcode |
| **I** | imm[11:0] (31:20) | | rs1 | funct3 | rd | opcode |
| **S** | imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode |
| **B** | imm[12], imm[10:5] | rs2 | rs1 | funct3 | imm[4:1], imm[11] | opcode |
| **J** | imm[20], imm[10:1], imm[11], imm[19:12] (31:12) | | | | rd | opcode |

### Immediate generator (`extend` module)

| `ImmSrc` | Type | Immediate built from the instruction |
|---|---|---|
| `000` | R | `0` (no immediate) |
| `001` | I | sign-extend `instr[31:20]` |
| `010` | S | sign-extend `{instr[31:25], instr[11:7]}` |
| `011` | B | sign-extend `{instr[31], instr[7], instr[30:25], instr[11:8], 0}` |
| `100` | J | sign-extend `{instr[31], instr[19:12], instr[20], instr[30:21], 0}` |

## ALU Operations

| `ALUcontrol` | Operation | Result |
|---|---|---|
| `0000` | ADD | `srcA + srcB` |
| `0001` | SUB | `srcA - srcB` |
| `0010` | SLL | `srcA << srcB[4:0]` |
| `0011` | SLT | 1 if `srcA < srcB` (signed) |
| `0100` | SLTU | 1 if `srcA < srcB` (unsigned) |
| `0101` | XOR | `srcA ^ srcB` |
| `0110` | SRL | `srcA >> srcB[4:0]` |
| `0111` | SRA | `srcA >>> srcB[4:0]` |
| `1000` | OR | `srcA \| srcB` |
| `1001` | AND | `srcA & srcB` |
