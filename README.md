[README.md](https://github.com/user-attachments/files/33634798/README.md)
# Spartan-6 DSP48A1 Slice: Verilog Design & FPGA Implementation

Verilog HDL implementation of the Spartan-6 DSP48A1 arithmetic slice. The design is built from small reusable modules (pipeline registers, 4-to-1 multiplexers, a pre-adder/subtracter, and a post-adder/subtracter) and supports a configurable pipeline, a multiplier, an accumulator path, and cascade ports.

The design was verified with a self-checking testbench in QuestaSim, then taken through the Vivado flow (elaboration, synthesis, and implementation) on an Artix-7 device with a 100 MHz clock constraint.

**[Open the full project report (PDF)](Project1_DSP48A1.pdf)**

## Project Overview

The DSP48A1 is the math building block of Spartan-6 FPGAs. It chains an 18-bit pre-adder/subtracter, an 18x18 multiplier, and a 48-bit post-adder/subtracter, with optional pipeline registers at every stage. The OPMODE input selects, at run time, which operands reach the multiplier and the post-adder, and whether each adder adds or subtracts.

The project focuses on building this datapath in synthesizable Verilog, parameterizing the register stages, and proving the behavior with directed, self-checking tests.

## Key Features

- 18-bit pre-adder/subtracter (`D +/- B`) with a bypass path, controlled by `OPMODE[6]` and `OPMODE[4]`.
- 18x18 signed multiplier producing a 36-bit `M` output.
- 48-bit post-adder/subtracter computing `Z +/- (X + CIN)`, with `CARRYOUT` and `CARRYOUTF`.
- X and Z multiplexers driven by `OPMODE[1:0]` and `OPMODE[3:2]`, including P feedback (accumulate), `PCIN`, the `C` port, and the concatenated `D:A:B` input.
- Configurable pipeline registers: `A0REG`, `A1REG`, `B0REG`, `B1REG`, `CREG`, `DREG`, `MREG`, `PREG`, `CARRYINREG`, `CARRYOUTREG`, `OPMODEREG`.
- Selectable carry source (`CARRYINSEL`), selectable B source (`B_INPUT`: `DIRECT` or `CASCADE`), and synchronous or asynchronous reset (`RSTTYPE`).
- Per-register clock enables and active-high resets.
- Cascade ports: `BCIN`, `BCOUT`, `PCIN`, `PCOUT`.

## Repository Contents

| Folder / File | Description |
|---|---|
| `pipe_reg.v` | Generic pipeline register with optional bypass, clock enable, and sync/async reset. |
| `mux4.v` | Parameterizable 4-to-1 multiplexer, used for both the X and Z muxes. |
| `preadder_sub.v` | Pre-adder/subtracter (`D +/- B`). |
| `postadder_sub.v` | Post-adder/subtracter (`Z +/- (X + CIN)`) with carry out. |
| `dsp48a1_top.v` | Top-level `DSP48A1` module that connects all submodules. |
| `dsp48a1_tb_.v` | Self-checking testbench with directed test patterns. |
| `run_.do` | QuestaSim script: compile, simulate, and add waves. |
| `constraints_1.xdc` | Timing constraint: 100 MHz clock on pin W5. |
| `Project1_DSP48A1.pdf` | Full project report. |

## Design Flow

1. **RTL Design:** Build the datapath from `pipe_reg`, `mux4`, `preadder_sub`, and `postadder_sub`, then connect them in `DSP48A1`.
2. **Simulation:** Run the self-checking testbench in QuestaSim using `run_.do`.
3. **Elaboration:** Open the elaborated design in Vivado and review the schematic and messages.
4. **Synthesis:** Synthesize for `xc7a200tffg1156-3` and review the utilization and timing reports.
5. **Implementation:** Place and route, then review utilization, timing, and the device view.
6. **Linting:** Run Questa Lint with the default methodology and goals.

## Verification Through Simulation

The testbench drives the design with the default parameters and checks the outputs automatically. It runs five scenarios:

| Test | What it checks | OPMODE |
|---|---|---|
| 2.1 Reset | All resets asserted, all outputs must be zero. | any |
| 2.2 Path 1 | Pre-subtract, multiply, then post-subtract with the C port. | `8'b11011101` |
| 2.3 Path 2 | Pre-add, multiply, zeros through X and Z. | `8'b00010000` |
| 2.4 Path 3 | No pre-adder, P feedback through X and Z (accumulate). | `8'b00001010` |
| 2.5 Path 4 | `D:A:B` through X, `PCIN` through Z, post-subtract. | `8'b10100111` |

**Result: 28 checks passed, 0 failed.**

Waveform screenshots and the exact expected values for each path are in the project report.

## FPGA Results

Target device: `xc7a200tffg1156-3` (Artix-7), clock constrained to 100 MHz on pin W5.

| Metric | Synthesis | Implementation |
|---|---|---|
| LUTs | 255 | 254 |
| Flip-flops | 160 | 179 |
| DSP blocks | 1 (DSP48E1) | 1 (DSP48E1) |
| Bonded IO | 327 (65.4 %) | 327 (65.4 %) |
| Worst setup slack (WNS) | +5.216 ns | +3.696 ns |
| Worst hold slack (WHS) | +0.182 ns | +0.271 ns |
| Failing endpoints | 0 | 0 |

All user-specified timing constraints are met. The warnings reported by Vivado are "unconnected port" messages for inputs that are not used with the default parameters (for example `BCIN` and `CARRYIN`); there are no critical warnings or errors.

## Linting

Questa Lint reported 5 informational/style items (constant condition, repeated parameter names across modules, and several ports on one line). They were reviewed and waived, leaving no open lint findings.

## Tools & Technologies

- **HDL:** Verilog
- **Simulation:** Siemens QuestaSim
- **FPGA Design & Implementation:** AMD/Xilinx Vivado
- **Design Analysis:** Questa Lint, Synthesis Reports, Timing Analysis, and FPGA Resource Utilization

## Project Report

See the full PDF report for the RTL code, testbench, do file, QuestaSim waveforms, constraint file, elaboration, synthesis, and implementation results, and the linting screenshots.

**Project Type:** Individual Project

## Author

- [Ahmed Mohamed Khalafallah](ضع-لينك-LinkedIn-هنا)
