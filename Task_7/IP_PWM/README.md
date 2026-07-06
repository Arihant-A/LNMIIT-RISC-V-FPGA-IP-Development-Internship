# PWM IP — Single-Channel Memory-Mapped PWM Peripheral

A drop-in PWM generator for the VSDSquadron FM RISC-V SoC. Four 32-bit registers, one output pin, no dependencies.

## What This IP Is

A programmable-frequency, programmable-duty-cycle PWM output, controlled entirely through 4 memory-mapped registers. Suitable for LED dimming, servo control, or any application needing a software-adjustable duty cycle.

## How to Integrate It

1. Copy `rtl/pwm_ip.v` into your project.
2. Include and instantiate it in your SoC's top-level file.
3. Extend your `IO_rdata` mux to route reads through `pwm_sel`/`pwm_rdata`.
4. Route `pwm_out` to a physical pin or an existing LED bit.

Full step-by-step instructions: **[docs/Integration_Guide.md](docs/Integration_Guide.md)**

## Where to Find Docs

| Document | Purpose |
|----------|---------|
| [docs/IP_User_Guide.md](docs/IP_User_Guide.md) | Overview, features, limitations, block diagram, programming model |
| [docs/Register_Map.md](docs/Register_Map.md) | Full bit-level register reference |
| [docs/Integration_Guide.md](docs/Integration_Guide.md) | How to wire this IP into your SoC |
| [docs/Example_Usage.md](docs/Example_Usage.md) | Board-level wiring, example firmware, expected output, troubleshooting |

## How to Test It

**Simulation (standalone IP):**
```bash
iverilog -o pwm_tb rtl/pwm_tb.v rtl/pwm_ip.v && vvp pwm_tb
```
Expect: `ALL PWM TESTS PASSED`.

**Simulation (full SoC with example firmware):**
```bash
iverilog -DBENCH -o soc_sim riscv.v soc_tb.v && vvp soc_sim
```

**Hardware (VSDSquadron FM):**
Flash the synthesized bitstream, run `software/pwm_example.c`, and observe the LED brightness ramp described in [docs/Example_Usage.md](docs/Example_Usage.md).

## Key Specs

| | |
|---|---|
| Base address | `0x0040_1000` |
| Window size | 4 KB |
| Registers | CTRL, PERIOD, DUTY, STATUS (all 32-bit) |
| Interrupt support | No |
| Channels | 1 |

## Known Limitations

- No interrupt support — poll `STATUS` if needed.
- Single channel per instance.
- No hardware dead-time/complementary output — not suitable for direct H-bridge drive.
- Assumes this SoC's native memory bus convention (not AXI/Wishbone/APB).
