# 32-bit RISC-V 5-Stage Pipelined Processor (Verilog)

A 32-bit **RISC-V (RV32I)** processor with a **5-stage pipeline**, written in plain Verilog.
Data forwarding, load-use stalls and branch/jump flushing are handled by a separate **Hazard Unit**.

## Datapath

![Datapath](docs/datapath.png)

*Red = data, blue = control, green = hazard unit, orange = pipeline registers and clock.*

## Vivado Schematic

![Vivado Schematic](docs/vivado_schematic.png)

## At a Glance

| Item | Details |
|---|---|
| ISA | RISC-V RV32I, 35 instructions |
| Pipeline | IF, ID, EX, MEM, WB |
| Hazards | forwarding (MEM and WB), load-use stall, branch/jump flush |
| Registers | 32 x 32-bit, `x0` always 0 |
| Memory | 4 KB instruction memory (from `program.hex`), 4 KB data memory |
| Language / tools | Verilog, Vivado |

## Supported Instructions

| Type | Instructions |
|---|---|
| R-type | ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND |
| I-type (ALU) | ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI |
| Loads | LB, LH, LW, LBU, LHU |
| Stores | SB, SH, SW |
| Branches | BEQ, BNE, BLT, BGE, BLTU, BGEU |
| Jumps | JAL, JALR |

Not implemented yet: `LUI`, `AUIPC`, `FENCE`, `ECALL`, `EBREAK`.
Full encodings and control signals are in [docs/instruction_set.md](docs/instruction_set.md).

## Hazard Handling

| Hazard | Fix | Cost |
|---|---|---|
| Data hazard (result not written yet) | forward the result to the ALU input | 0 cycles |
| Load-use hazard | stall 1 cycle, then forward | 1 cycle |
| Taken branch / jump (decided in EX) | flush the 2 wrong instructions | 2 cycles |

Details and cycle-by-cycle examples are in [docs/hazard_unit.md](docs/hazard_unit.md).

## Verification

Testbenches are self-checking (`PASS` / `FAIL`). Plan: test every module alone first, then run an end-to-end test of the full core.

| Status | Modules |
|---|---|
| Verified | `pc`, `alu`, `pc_4adder` |
| In progress | all other modules |
| Planned | end-to-end test of the full core |

Full status table and method: [docs/verification.md](docs/verification.md).

## Repository Structure

```
riscv-32bit-pipelined-core/
├── README.md
├── rtl/
│   └── RTL.v                  all modules of the design
├── tb/                        testbenches
└── docs/
    ├── datapath.png
    ├── vivado_schematic.png
    ├── architecture.md        stages, module index, pipeline registers
    ├── instruction_set.md     instructions, formats, ALU operations
    ├── hazard_unit.md         forwarding, stall, flush
    └── verification.md        testbench plan and status
```

## How to Run

1. Create a Vivado project and add `rtl/RTL.v` as a design source.
2. Add a testbench from `tb/` as a simulation source.
3. Put `program.hex` in the simulation working folder, because `instruction_memory` loads it with `$readmemh`.
4. Run Behavioral Simulation. Self-checking testbenches print `PASS` or `FAIL` in the Tcl console.

## Next Steps

- [ ] Finish module testbenches, then the end-to-end test
- [ ] Add older versions in a `milestones/` folder (R, I, S types, then branches, then single-cycle, then pipeline)
- [ ] Add `LUI` and `AUIPC`
- [ ] Waveform screenshots of forwarding, stall and flush
- [ ] Later: branch prediction, cache, superscalar

## Author

**Abhinav Kushwaha**, IIIT Kottayam
Interested in RTL design and verification.

