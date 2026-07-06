# PWM IP — User Guide

## 1. IP Overview

This IP is a single-channel, memory-mapped PWM (Pulse Width Modulation) generator. It produces a configurable-frequency, configurable-duty-cycle digital output suitable for LED dimming, servo control, or any application needing a variable-duty square wave from software control.

**Typical use cases:**
- LED brightness control (dimming) via duty cycle sweep
- Hobby servo motor positioning
- Simple buzzer/tone generation
- Any application needing a software-programmable duty-cycle output without a dedicated timer/PWM hardware block elsewhere in the SoC

**Why use this IP:** it requires no external timer dependency, occupies its own isolated 4 KB address window (no risk of address collision with other peripherals), and is fully self-contained — three writable registers and one status register are all that's needed to drive it.

---

## 2. Feature Summary

| Feature                  | Support                                      |
|---------------------------|-----------------------------------------------|
| Modes                     | Continuous PWM output (no one-shot mode)     |
| Duty cycle resolution     | 32-bit tick count (as fine as PERIOD allows) |
| Polarity                  | Active-high or active-low (software-selectable) |
| Bit width                 | 32-bit registers, word-aligned                |
| Clock                     | Single clock domain, synchronous to system `clk` |
| Minimum period             | Hardware-clamped to 1 tick (never 0)          |

**Limitations (stated honestly):**
- **No interrupt support.** Status must be polled if needed; the IP has no way to signal the CPU asynchronously.
- **Single channel only.** One PWM output per instance. Multiple channels require multiple IP instances at different base addresses.
- **No hardware dead-time / complementary output.** This is a simple single-ended PWM, not suitable for driving H-bridges directly without external gate logic.
- **Assumes the SoC's memory-mapped bus convention** (`mem_addr` / `mem_wdata` / `mem_wstrb`, no wait-states) — not a standard AXI/Wishbone/APB peripheral without an adapter.
- **Frequency is a function of system clock and PERIOD** — there's no independent PWM clock or prescaler, so very low PWM frequencies require large PERIOD values (32-bit ceiling).

---

## 3. Block Diagram

```
                CPU Bus (mem_addr, mem_wdata, mem_wstrb, isIO)
                              |
                              v
                 +--------------------------+
                 |   Address Decode          |
                 |  (4KB window match +      |
                 |   offset validity check)  |
                 +--------------------------+
                       |              |
                       v              v
                 +-----------+  +--------------+
                 |  CTRL     |  |  PERIOD/DUTY  |
                 |  Register |  |  Registers    |
                 +-----------+  +--------------+
                       |              |
                       v              v
                 +--------------------------+
                 |   Counter (0..PERIOD-1)   |
                 |   + Comparator (cnt<DUTY) |
                 +--------------------------+
                              |
                              v
                 +--------------------------+
                 | Polarity / Enable Logic   |
                 +--------------------------+
                              |
                              v
                          pwm_out
```

---

## 4. Register Map

See **[Register_Map.md](./Register_Map.md)** for the full bit-level register table.

---

## 5. Software Programming Model

Typical initialization sequence:

1. Write `PERIOD` — sets the PWM cycle length in clock ticks.
2. Write `DUTY` — sets the active-time in clock ticks (must be ≤ PERIOD for a partial duty cycle; can exceed it intentionally for always-on).
3. Write `CTRL` — set `EN=1` and the desired `POL`.
4. (Optional) Poll `STATUS.RUNNING` to confirm the IP is active.
5. To change brightness/duty dynamically, write `DUTY` again at any time — the change takes effect on the next counter cycle, no re-enable needed.

There is no interrupt or blocking wait required by the IP itself — all register writes take effect combinationally/synchronously on the next clock edge, and `DUTY` can be updated freely at runtime.

See **[Example_Usage.md](./Example_Usage.md)** for a complete working example.
