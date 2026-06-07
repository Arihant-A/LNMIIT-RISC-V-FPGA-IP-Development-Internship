# Task 2: RISC-V Program Execution and Debugging with Spike

> Simulating and step-debugging RISC-V programs using the Spike ISA simulator, inspecting register states, understanding the `LUI` instruction encoding, tracing stack pointer changes via `addi`, and analyzing compiler optimization effects on a custom unsigned integer division program.

---

## Table of Contents

1. [Task Overview](#task-overview)
2. [Tools & Environment](#tools--environment)
3. [Part A — Sum1ton: Normal Execution & Object File Inspection](#part-a--sum1ton-normal-execution--object-file-inspection)
   - [Normal Execution](#normal-execution)
   - [Inspecting the Object File (sum1ton.o)](#inspecting-the-object-file-sum1tono)
4. [Part B — Spike Debugging: Step-Through & Register Inspection](#part-b--spike-debugging-step-through--register-inspection)
   - [LUI Instruction Deep Dive](#lui-instruction-deep-dive)
   - [Stack Pointer Before and After addi](#stack-pointer-before-and-after-addi)
5. [Part C — Unsigned Division Program](#part-c--unsigned-division-program)
   - [C Source Code](#c-source-code)
   - [Algorithm Complexity](#algorithm-complexity)
   - [Running with GCC (x86)](#running-with-gcc-x86)
   - [Running with Spike and -Ofast](#running-with-spike-and--ofast)
   - [Running with Spike and -O1](#running-with-spike-and--o1)
6. [Instruction Count Analysis](#instruction-count-analysis)
   - [With -Ofast](#with--ofast)
   - [With -O1](#with--o1)
7. [Optimization Comparison](#optimization-comparison)
8. [Why Does Instruction Count Differ Between -O1 and -Ofast?](#why-does-instruction-count-differ-between--o1-and--ofast)
9. [Key Learnings](#key-learnings)
10. [Conclusion](#conclusion)

---

## Task Overview

This task extends the RISC-V toolchain workflow from Task 1 into two new areas:

1. **Spike Debugging** — Using Spike's interactive debugger (`-d` flag) to step through a RISC-V binary instruction-by-instruction, inspecting CPU register values at each step. This reveals exactly how the hardware state evolves during program execution.

2. **Unsigned Integer Division** — Writing, compiling, and analyzing a custom software division algorithm in C, compiled for RISC-V with two different optimization flags (`-Ofast` and `-O1`), then counting and comparing the instructions generated in the `<main>` function via `objdump`.

---

## Tools & Environment

| Tool | Purpose |
|---|---|
| `gcc` | Native x86\_64 C compiler for host-side verification |
| `riscv64-unknown-elf-gcc` | RISC-V cross-compiler |
| `spike` | Official RISC-V ISA simulator — both normal (`spike pk`) and debug (`spike -d pk`) modes |
| `pk` | RISC-V proxy kernel — provides syscall support under Spike |
| `riscv64-unknown-elf-objdump` | Disassembles compiled RISC-V ELF binaries to human-readable assembly |
| `gedit` | GUI text editor used to write/edit C source files |

**Host Environment:** Ubuntu (x86\_64)  
**RISC-V Toolchain:** `riscv64-unknown-elf-gcc` (RISC-V GNU Toolchain)  
**Spike Debug Mode Command:** `spike -d pk <binary>`

---

## Part A — Sum1ton: Normal Execution & Object File Inspection

### Normal Execution

The `sum1ton` binary is compiled with `-Ofast` for RISC-V and run under Spike, confirming the sum from 1 to 100 equals **5050**.

**Commands:**
```bash
riscv64-unknown-elf-gcc -Ofast -mabi=lp64 -march=rv64i -o sumlton.o sumlton.c
spike pk sumlton.o
```

**Output:** `Sum from 1 to 100 is 5050`

#### Screenshot — Normal Execution

![Normal Execution](Task_2/normal_execution.png)

> Both the native GCC build and the RISC-V Spike simulation produce the same result, confirming correctness of the cross-compiled binary.

---

### Inspecting the Object File (sum1ton.o)

The `objdump` tool disassembles the compiled RISC-V ELF binary, showing the `.text` section containing the actual machine instructions.

**Command:**
```bash
riscv64-unknown-elf-objdump -d sumlton.o | less
```

#### Screenshot — sum1ton.o Disassembly

![sum1ton.o File Contents](Task_2/sumlton_objdump.png)

**Key observations from the disassembly:**

```
0000000000100b0 <main>:
  100b0:   00001637    lui     a2, 0x1
  100b4:   00021537    lui     a0, 0x21
  100b8:   ff010113    addi    sp, sp, -16
  100bc:   3ba60613    addi    a2, a2, 954 # 13ba <main-0xecf6>
  100c0:   li          a1, 100
  100c4:   18050513    addi    a0, a0, 384 # 21180 <__clzdi2+0x44>
  100c8:   00113423    sd      ra, 8(sp)
  100cc:   340000ef    jal     ra, 1040c <printf>
  100d0:   00813083    ld      ra, 8(sp)
  100d4:   00000513    li      a0, 0
  100d8:   01010113    addi    sp, sp, 16
  100dc:   00008067    ret
```

The `-Ofast` flag has **eliminated the loop entirely** — the compiler computed the sum (5050) at compile time using constant folding. The `main` function simply calls `printf` directly with the pre-computed values.

---

## Part B — Spike Debugging: Step-Through & Register Inspection

Spike's interactive debugger (`-d`) lets you halt execution at any instruction, step forward, and inspect register values. This is equivalent to using `gdb` but at the ISA simulation level.

**Launch Debug Mode:**
```bash
spike -d pk sumlton.o
```

Once inside the debugger:
- `until pc 0 <address>` — run until the program counter reaches a given address
- `reg 0 <regname>` — print the value of a register in core 0
- `run` / `q` — continue / quit

---

### LUI Instruction Deep Dive

The first instruction in `<main>` is a `LUI` (Load Upper Immediate):

```
100b0:   00001637    lui    a2, 0x1
```

#### Screenshot — LUI Instruction in Spike Debugger

![LUI Instruction](Task_2/lui_debug.png)

**What LUI does:**

`LUI` loads a 20-bit immediate value into the **upper 20 bits** of the destination register, setting the lower 12 bits to zero. The result is then sign-extended to 64 bits in RV64.

```
lui  a0, %hi(.LC1)     →   lui  a0, 0x32143
```

| Field | Bits | Value |
|---|---|---|
| opcode | [6:0] | `0110111` (LUI) |
| rd (dest reg) | [11:7] | register index |
| imm[31:12] | [31:12] | 20-bit immediate |

**Encoding breakdown for `lui a2, 0x1` (`0x00001637`):**

```
Binary: 0 0 1 1 0 0 1 0 0 0 0 0 1 0 1 0 0 0 0 1 1
        [31        12][11  7][6    0]
         Immediate     rd     opcode
          0x00001      a2     0110111

Hex groups: (3)  (2)  (1)  (4)  (3)
```

After execution, register `a2` holds:
```
x10 = 0x0000000032143000   (sign-extended to 64 bits)
```

The upper 20 bits carry the page-level address, and `addi` subsequently fills in the lower 12-bit offset to form a complete address (used for string literals, global data, etc.).

#### Screenshot — Spike Stepping Through LUI

![Spike Step Debug](Task_2/spike_step_debug.png)

---

### Stack Pointer Before and After addi

The third instruction in `<main>` is:

```
100b8:   ff010113    addi    sp, sp, -16
```

This allocates 16 bytes on the stack by subtracting 16 (0x10) from the stack pointer — standard RISC-V function prologue behavior.

#### Screenshot — Stack Pointer Before addi

![SP Before addi](Task_2/sp_before_addi.png)

**Before `addi`:**
```
(spike) reg 0 sp
0x000000007f7e9b50
```

#### Screenshot — Stack Pointer After addi

![SP After addi](Task_2/sp_after_addi.png)

**After `addi sp, sp, -16`:**
```
(spike) reg 0 sp
0x000000007f7e9b40
```

**Verification:**
```
0x7f7e9b50 - 0x10 = 0x7f7e9b40  ✓
```

Hexadecimal `10` = decimal `16`, confirming that exactly **16 bytes** were subtracted from the stack pointer. This space is used to save the return address (`ra`) on the stack before calling `printf`, so it can be restored when `main` returns.

---

## Part C — Unsigned Division Program

### C Source Code

A custom software unsigned integer division algorithm implemented from scratch using only bit-shifting and comparison — no hardware divide instruction (`div`) is used.

```c
#include <stdio.h>

unsigned divide(unsigned dividend, unsigned divisor)
{
    unsigned quotient  = 0;
    unsigned remainder = 0;

    for(int i = 31; i >= 0; i--)
    {
        remainder <<= 1;
        remainder |= (dividend >> i) & 1;

        if(remainder >= divisor)
        {
            remainder -= divisor;
            quotient  |= (1U << i);
        }
    }
    return quotient;
}

int main()
{
    unsigned result = divide(13, 3);
    printf("Quotient = %u\n", result);
    return 0;
}
```

**Expected Output:** `Quotient = 4`  (13 ÷ 3 = 4 remainder 1)

**How it works:** The algorithm mimics long division in binary. It processes the dividend bit-by-bit from the most significant bit downward, building up the remainder one bit at a time and producing one quotient bit per iteration.

---

### Algorithm Complexity

| Property | Value |
|---|---|
| Iterations | N (one per bit of dividend) |
| Per iteration | 1 shift + 1 comparison + 1 optional subtraction |
| Time Complexity | O(N) |
| For 32-bit inputs | 32 clock cycles (sequential hardware equivalent) |

In a hardware implementation, this maps to a sequential divider that maintains a remainder register, shifts in one dividend bit per cycle, compares with the divisor, optionally subtracts, and generates one quotient bit every cycle — taking exactly **32 cycles** for a 32-bit division.

---

### Running with GCC (x86)

First verified on the native x86 host to confirm correctness:

```bash
gcc division.c -o division
./a.out
# Output: Quotient = 4
```

#### Screenshot — GCC x86 Execution

![Division with GCC](Task_2/division_gcc.png)

---

### Running with Spike and -Ofast

Cross-compiled with `-Ofast` and simulated under Spike:

```bash
riscv64-unknown-elf-gcc -Ofast -mabi=lp64 -march=rv64i -o division.o division.c
spike pk division.o
# Output: Quotient = 4
```

#### Screenshot — Spike Execution with -Ofast

![Division Spike Ofast](Task_2/division_spike_ofast.png)

---

### Running with Spike and -O1

Cross-compiled with `-O1` and simulated under Spike:

```bash
riscv64-unknown-elf-gcc -O1 -mabi=lp64 -march=rv64i -o division_O1.o division.c
spike pk division_O1.o
# Output: Quotient = 4
```

#### Screenshot — Spike Execution with -O1

![Division Spike O1](Task_2/division_spike_O1.png)

---

## Instruction Count Analysis

Using `riscv64-unknown-elf-objdump -d` to inspect the `<main>` function in both compiled binaries. Since RISC-V uses fixed-width 4-byte instructions:

```
Number of bytes        = address of next function − start address of <main>
Number of instructions = number of bytes ÷ 4
```

---

### With -Ofast

**Objdump output for `<main>` (`-Ofast`):**

```
00000000000100b0 <main>:
  100b0:   ff010113    addi    sp, sp, -16
  100b4:   00113423    sd      ra, 8(sp)
  100b8:   00000593    li      a1, 0
  100bc:   01e00513    li      a0, 30
  100c0:   00200893    li      a7, 13 (a3 = 0)
  100c4:   00200813    li      a6, 2
  100c8:   00d07b13    andi    a5, a5, 3
  100cc:   0017979b    ...
  100d0:   001797bb    slliw   a5, a5, 0x1
  100d4:   00177713    andi    a4, a4, 1
  100d8:   00e7e7b3    or      a5, a5, a4
  100dc:   fff6069e3    ...
  100e0:   00d5e663    blt     ...
  100e4:   00f6f663    bgeu    a3, a3,10100 <main+0x50>
  100f8:   00f67663    bgeu    ...
  100fc:   0007059b    ...
  10100:   fcc69ae3    bne     a3, a3, 10100d4 <main+0x24>
  10104:   21050513    addi    a0, a0, 528 # 21210 <__clzdi2+0x48>
  10108:   38c00ef     jal     ra, 10498 <printf>
  1010c:   00813083    ld      ra, 8(sp)
  10110:   00000513    li      a0, 0
  10114:   01010113    addi    sp, sp, 16
  10118:   00008067    ret
```

From the objdump screenshot:

```
<main>   starts at  : 0x100b0
Next function starts: 0x10120
```

**Calculation:**
```
Number of bytes        = 0x10120 − 0x100b0
                       = 0x70
                       = 112 (decimal)

Number of instructions = 112 ÷ 4 = 28 instructions
```

#### Screenshot — objdump with -Ofast

![Instruction Count Ofast](Task_2/instruction_count_ofast.png)

---

### With -O1

**Objdump output for `<main>` (`-O1`):**

```
00000000000101d8 <main>:
  101d8:   ff010113    addi    sp, sp, -16
  101dc:   00113423    sd      ra, 8(sp)
  101e0:   00300593    li      a1, 3
  101e4:   00d00513    li      a0, 13
  101e8:   0005059b    ...
  101ec:   f9dff0ef    jal     ra, 10184 <divide>
  101f0:   0005059b    sext.w  a1, a0
  101f4:   1d050513    lui     a0, 0x21
  101f8:   26c000ef    jal     ra, 211d8 # 211d8 <__clzdi2+0x3c>
  101fc:   00000513    li      a0, 0
  10200:   00813083    ld      ra, 8(sp)
  10204:   01010113    addi    sp, sp, 16
  10208:   00008067    ret
```

From the objdump screenshot:

```
<main>   starts at  : 0x101d8
Next function starts: 0x1020c
```

**Calculation:**
```
Number of bytes        = 0x1020c − 0x101d8
                       = 0x34
                       = 52 (decimal)

Number of instructions = 52 ÷ 4 = 13 instructions
```

#### Screenshot — objdump with -O1

![Instruction Count O1](Task_2/instruction_count_O1.png)

---

## Optimization Comparison

| Metric | `-O1` | `-Ofast` |
|---|---|---|
| Instructions in `<main>` | **13** | **28** |
| `divide()` called from `main`? | **Yes** (via `jal`) | **No** (inlined or removed) |
| Loop in `divide()` compiled? | Yes, full 32-iteration loop | Partially unrolled / restructured |
| Binary size | Smaller | Larger |
| Runtime speed | Moderate | Fastest |
| Standards compliance | Full | Relaxed (`-ffast-math` etc.) |

---

## Why Does Instruction Count Differ Between -O1 and -Ofast?

This is the most important conceptual question in this lab. The answer lies in what each flag permits the compiler to do.

### `-O1` — Conservative Optimization (13 instructions in `<main>`)

With `-O1`, the compiler applies **safe, local optimizations** only:

- It **cannot** move code across function boundaries (no inlining by default at `-O1`).
- The `divide()` function is compiled as a **separate, standalone function**.
- `main` simply sets up arguments (`a0 = 13`, `a1 = 3`), calls `divide` via `jal ra, <divide>`, then passes the return value to `printf`.
- `main` itself is therefore very short — it just orchestrates two function calls.

The 32-iteration loop inside `divide()` exists in full in the binary; `main` just calls it. Because `main` itself does so little, its instruction count is low (13).

### `-Ofast` — Aggressive Optimization (28 instructions in `<main>`)

With `-Ofast`, the compiler enables **O3 plus non-standard aggressive transformations**:

- **Function inlining:** The compiler may inline `divide()` directly into `main`, eliminating the function call overhead. The loop body from `divide` now physically lives inside `main`'s code.
- **Loop restructuring:** The 32-iteration loop may be **partially unrolled** — instead of one iteration per loop pass, the compiler generates multiple copies of the loop body to reduce branch overhead and expose more instruction-level parallelism.
- **`-ffast-math` effects:** Allows the compiler to reorder and restructure arithmetic operations in ways that are technically non-standard but produce correct results for typical inputs.
- **Wider instruction scheduling:** More instructions from the inlined divide loop become visible to the scheduler at once, leading to a larger but faster instruction sequence.

The result: `main` now contains both its own logic **and** the inlined, restructured divide loop, leading to significantly more instructions (28 vs 13) — but those instructions execute faster because there are no function call overheads, branch mispredictions from the tight loop are reduced, and the CPU's pipeline is better utilized.

### The Key Insight

> **More instructions in `main` does not mean slower execution.**

With `-O1`, the 13 instructions in `main` merely delegate work to `divide()`, which runs a slow 32-iteration loop with call overhead. With `-Ofast`, the 28 instructions in `main` *are* the loop — inlined, restructured, and scheduled for maximum throughput. The `-Ofast` binary is faster despite having more instructions in `main`, because those extra instructions replace slower function-call and loop-overhead patterns with streamlined, pipelined computation.

---

## Key Learnings

- **Spike's `-d` debug mode** allows instruction-level stepping and register inspection, providing the same insight as a hardware oscilloscope but entirely in software — invaluable for RISC-V embedded debugging.
- **The `LUI` instruction** encodes a 20-bit immediate into the upper bits of a register, and is always paired with `addi` or `jalr` to form a complete 32-bit address. Understanding its binary encoding explains how RISC-V constructs arbitrary 32-bit constants from 20+12 bit pairs.
- **Stack frame mechanics** are directly visible in Spike: `addi sp, sp, -16` allocates the frame, and the exact register value change (verified as hexadecimal `0x10` = 16 bytes) can be confirmed interactively.
- **Software division without a hardware divider** is O(N) in the number of bits — foundational knowledge for RISC-V embedded targets where hardware multiply/divide extensions (RVM) may not be present.
- **Instruction count in `<main>` is not the same as total work done** — `-O1` has fewer instructions in `main` because it delegates to `divide()`; `-Ofast` has more because it inlines the work directly.
- The **RISC-V fixed 4-byte instruction width** makes instruction counting from `objdump` output a simple arithmetic operation, which is a major advantage over variable-length ISAs like x86.

---

## Conclusion

Task 2 built significantly on the foundation of Task 1 by introducing interactive simulation and optimization analysis for a real algorithmic program. The key outcomes were:

1. **Spike debugging** was used to trace the execution of `sum1ton` step-by-step, directly observing the effect of `LUI` on register `a2` and the stack pointer change caused by `addi sp, sp, -16`.

2. A **software unsigned division algorithm** was written in C, verified on x86 (GCC), cross-compiled to RISC-V, and simulated successfully on Spike under both `-O1` and `-Ofast` flags — both producing the correct quotient of **4** for 13 ÷ 3.

3. **Instruction count analysis** via `objdump` revealed that `-O1` produces 13 instructions in `<main>` while `-Ofast` produces 28 — a seemingly counterintuitive result explained by the fact that `-Ofast` inlines and restructures the `divide()` function body directly into `main`, trading a compact `main` for an aggressively optimized, self-contained code block that eliminates function-call overhead entirely.

4. The core lesson: **compiler optimization flags fundamentally change not just the speed of code, but its structure** — and reading `objdump` output is an essential skill for any RISC-V systems developer.

---

*Lab performed as part of a RISC-V architecture and toolchain exploration course.*
