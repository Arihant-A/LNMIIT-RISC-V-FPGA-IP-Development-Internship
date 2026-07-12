# LNMIIT-RISC-V-FPGA-IP-Development-Internship

Repository for the LNMIIT RISC-V FPGA IP Development Internship, encompassing multiple RTL design, verification, and FPGA implementation tasks.

**Submitted by** Arihant Agarwal

**College**: The LNM Institute of Information Technology

**Email**: 23UEC521@LNMIIT.AC.IN

---

## Overview

This repository documents a hands-on RISC-V FPGA internship progressing from toolchain basics to custom memory-mapped IP design, SoC integration, and hardware bring-up on the **VSDSquadron FPGA Mini (Lattice iCE40 UP5K)**.

| Task | Title | Summary |
|------|-------|---------|
| [Task 1](./Task_1) | GCC vs RISC-V GCC Toolchain | Compiled a sum-1-to-N C program with native GCC and `riscv64-unknown-elf-gcc`, compared `-O1`/`-Ofast`/`-Og`/`-Os` optimization flags, and manually counted instructions via `objdump`. |
| [Task 2](./Task_2) | Spike Debugging & Division Algorithm | Used Spike's interactive debugger to step through instructions and inspect registers (`LUI`, stack pointer via `addi`); wrote and analyzed a software unsigned-division routine under different optimization levels. |
| [Task 3](./Task_3) | Environment Setup & Reference Bring-Up | Set up the GitHub Codespace RISC-V environment, verified the toolchain, cloned and ran the `vsdfpga_labs` reference SoC, and customized the firmware banner. |
| [Task 4](./Task_4) | First Memory-Mapped IP — GPIO | Designed a simple memory-mapped GPIO IP from scratch, integrated it into the SoC bus, debugged address-decode/simulation-clock issues, and verified it in RTL simulation and on FPGA hardware. |
| [Task 5](./Task_5) | GPIO Register Map Rework | Extended the GPIO IP into a proper 3-register (DATA/DIR/READ) bidirectional peripheral with a real input-pin path, resolving address-decode collisions with existing peripherals. |
| [Task 6](./Task_6) | PWM IP + Windowed Address Decode | Added a 4-register PWM IP alongside a reworked GPIO IP, both using clean 4KB-aligned windowed address decoding; validated via simulation and full hardware synthesis/flash with a PWM LED breathing demo. |
| [Task 7](./Task_7) | Packaged PWM IP (Deliverable) | Packaged the single-channel PWM peripheral as a standalone, drop-in IP with full documentation (user guide, register map, integration guide, example usage) for reuse in other RISC-V SoC projects. |

---

## Video Link
https://drive.google.com/file/d/1T24XkmOKFsO85MZ68yUoNx_O-tQOqUEX/view?usp=drive_link

## Tools & Environment

- **RISC-V Toolchain:** `riscv64-unknown-elf-gcc`, `objdump`
- **Simulation:** Spike ISA simulator, Icarus Verilog (`iverilog`/`vvp`), GTKWave
- **FPGA Flow:** Yosys, NextPNR, IceStorm (`icepack`, `icetime`) targeting the Lattice iCE40 UP5K
- **Hardware:** VSDSquadron FPGA Mini
- **Dev Environment:** GitHub Codespaces

## Repository Structure

Each `Task_N/` folder contains its own detailed `README.md`, along with the associated RTL, firmware, testbenches, and supporting screenshots for that task.
