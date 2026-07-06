# PWM IP — Example Usage & Validation

## 1. Board-Level Usage (VSDSquadron FM)

This IP's `pwm_out` signal must be routed to a physical pin to be observable on hardware. Two supported approaches:

**Option A (recommended, no extra wiring): reuse an onboard LED pin.**
The VSDSquadron FM has an onboard RGB LED already wired into the SoC's existing `LEDS[4:0]` bus (e.g. `LEDS[0]` → pin 39, green). To drive one of these bits directly from `pwm_out` instead of the software-writable LED register:

```verilog
output [4:0] LEDS,          // note: no longer `reg` — bit 0 is now combinational
...
reg [4:1] LEDS_reg;
assign LEDS[4:1] = LEDS_reg;
assign LEDS[0]   = pwm_out_sig;   // PWM drives this LED directly

always @(posedge clk) begin
    if (isIO & mem_wstrb & mem_wordaddr[IO_LEDS_bit] & !gpio_sel) begin
        LEDS_reg <= mem_wdata[4:1];   // software no longer controls bit 0
    end
end
```

No `.pcf` changes are needed — the existing `set_io LEDS[0] 39` mapping is reused.

**Option B: dedicate a new pin.** Add `pwm_out` as a new top-level SoC output port and constrain it to any pin not already claimed in your `.pcf` (e.g. not one of `LEDS[0..4]`, `RESET`, `CLK`, `TXD`, `RXD`). Wire an external LED + current-limiting resistor from that pin to ground.

## 2. Example Firmware

See **[software/pwm_example.c](../software/pwm_example.c)** for the full ready-to-run source. Summary of what it does:

1. Programs `PERIOD=1000`, `DUTY=250` (25% duty), enables the IP.
2. Confirms register readback matches what was written.
3. Confirms `STATUS.RUNNING` reflects the enable state (both enabled and disabled).
4. Sweeps `DUTY` from 0 to `PERIOD` in steps of 100 — this is the board demo step: on hardware, this produces a visible brightness ramp on whichever LED/pin `pwm_out` is wired to.

Build using the existing firmware `Makefile` pattern rules (no per-file target needed):
```
make pwm_example.bram.hex
```

## 3. Expected Output

**UART log (via existing UART peripheral, if firmware prints status):**
```
--- PWM IP Example / Validation ---

Step 1: PERIOD=1000, DUTY=250 (25%), POL=0, EN=1
PERIOD readback: 000003E8
DUTY readback: 000000FA

Step 2: Check STATUS.RUNNING
STATUS: 00000001

Step 3: Disable (EN=0), check RUNNING clears

Step 4: Duty sweep (visual LED brightness demo)
Duty sweep complete — observe LED brightness change on hardware.

ALL CHECKS PASSED.
```

**LED behavior (hardware):** the LED wired to `pwm_out` should visibly dim/brighten as the duty sweep runs — starting dark (or dim, depending on polarity) and increasing to fully bright as `DUTY` approaches `PERIOD`.

## 4. Common Failure Symptoms & Likely Causes

| Symptom                                   | Likely Cause                                                        |
|--------------------------------------------|------------------------------------------------------------------------|
| Register readback always returns 0         | `IO_rdata` mux missing the `pwm_sel ? pwm_rdata` term in the active build branch (check both `BENCH` and synthesis paths). |
| LED never lights, even at max DUTY         | `pwm_out` not actually wired to the pin/LED bit — check `.pcf`/port connection. |
| LED stays at constant brightness regardless of DUTY | Firmware writing to the wrong address (check `PWM_BASE` matches RTL), or IP not enabled (`CTRL.EN=0`). |
| Writes to one register corrupt another    | Address decode aliasing bug — confirm `pwm_ip.v` checks `mem_addr[11:4]==0` before decoding the low 2 bits, not just `mem_addr[5:2]` or similar. |
| Everything works in simulation, fails on hardware | Usually a pin/`.pcf` constraint issue, or a clock-domain assumption mismatch — confirm `clk` fed to the IP matches the SoC's actual operating frequency. |
