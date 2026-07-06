# PWM IP — Integration Guide

This guide assumes you already have a working VSDSquadron FM RISC-V SoC build (i.e. `riscv.v`, `Memory`, `Processor`, and the existing LEDS/UART peripherals already synthesize and simulate correctly). It does **not** assume familiarity with this IP's internal RTL.

## 1. Required RTL Files

Copy into your project's RTL directory:

```
rtl/pwm_ip.v
```

That's the only file this IP requires. It has no dependencies on any other custom module.

## 2. Where to Include It

In your top-level SoC file (`riscv.v`), add the include near your other peripheral includes:

```verilog
`include "pwm_ip.v"
```

## 3. Where to Instantiate It

Inside the `SOC` module, alongside your other peripherals:

```verilog
wire [31:0] pwm_rdata;
wire        pwm_out_sig;
wire        pwm_sel;

pwm_ip PWM (
    .clk       (clk),
    .resetn    (resetn),
    .isIO      (isIO),
    .mem_wstrb (mem_wstrb),
    .mem_addr  (mem_addr),
    .mem_wdata (mem_wdata),
    .pwm_rdata (pwm_rdata),
    .pwm_out   (pwm_out_sig),
    .pwm_sel   (pwm_sel)
);
```

## 4. Address Decoding Expectations

- The IP expects to be given the **full, unmodified** `mem_addr` bus. It performs its own window decode internally (`mem_addr[31:12] == 0x00401`) — you do not need to pre-decode or gate `mem_addr` before passing it in.
- `isIO` should be the same top-level signal your SoC already uses to distinguish IO-space accesses from RAM accesses (typically `mem_addr[22]` in this SoC family).
- The IP claims the fixed 4 KB window at `0x0040_1000`–`0x0040_1FFF`. Ensure no other peripheral in your SoC is mapped to this range.

## 5. Signals Exposed to Top-Level

| Signal      | Direction | Purpose                                                   |
|-------------|-----------|------------------------------------------------------------|
| `pwm_rdata` | Output    | Data to return to the CPU when `pwm_sel` is high. Must be muxed into your top-level `IO_rdata` (see below). |
| `pwm_sel`   | Output    | High when the current bus access falls inside the PWM's 4KB window. Use this to gate/mux other peripherals' read data. |
| `pwm_out`   | Output    | The actual PWM waveform. Route this to a physical pin or reuse an existing LED bit (see Board-Level Usage). |

## 6. Wiring into the Read-Data Mux

Your SoC's `IO_rdata` mux must be extended to include the PWM term, e.g.:

```verilog
wire [31:0] IO_rdata = (mem_wordaddr[IO_UART_CNTL_bit] & !gpio_sel & !pwm_sel) ? {22'b0, !uart_ready, 9'b0}
                     : gpio_sel ? gpio_rdata
                     : pwm_sel  ? pwm_rdata
                     : 32'b0;
```

**Important — simulation vs synthesis branches:** if your SoC uses an `` `ifdef BENCH``/`` `else`` split for simulation vs hardware builds (common in this SoC template), make sure **both** branches include the `pwm_sel ? pwm_rdata` term. A common integration mistake is updating only one branch, which causes PWM writes to appear to work while all PWM reads silently return zero in simulation (or vice versa on hardware). Test both build paths after integration.

## 7. Pin Connections

See **[Board-Level Usage](./IP_User_Guide.md)** and the top-level README for how to route `pwm_out` to a physical pin or an existing onboard LED on the VSDSquadron FM.

## 8. Post-Integration Checklist

- [ ] `pwm_ip.v` included and instantiated
- [ ] `IO_rdata` mux updated in **all** build-mode branches (BENCH and synthesis)
- [ ] No other peripheral occupies `0x0040_1000`–`0x0040_1FFF`
- [ ] `pwm_out` routed to a pin/LED (see Board-Level Usage)
- [ ] Re-run `pwm_tb.v` standalone simulation — expect `ALL PWM TESTS PASSED`
- [ ] Re-run full-SoC simulation with example firmware loaded
- [ ] Re-synthesize and confirm timing still meets your target clock (this IP adds one 32-bit counter and comparator to the critical path)
