# PWM IP — Example Usage & Validation

## 1. Board-Level Usage (VSDSquadron FM)

This IP's `pwm_out` signal must be routed to a physical pin to be observable on hardware. Two supported approaches:

### Option A (recommended, no extra wiring): reuse an onboard LED pin

The VSDSquadron FM has an onboard RGB LED already wired into the SoC's existing `LEDS[4:0]` bus (e.g. `LEDS[0] → pin 39, green`). To drive one of these bits directly from `pwm_out` instead of the software-writable LED register:

```verilog
output [4:0] LEDS,          // note: no longer `reg` — bit 0 is now combinational
...
reg [4:1] LEDS_reg;
assign LEDS[4:1] = LEDS_reg;
assign LEDS[0]   = pwm_out_sig;   // PWM drives this LED directly

always @(posedge clk) begin
    if (isIO & mem_wstrb & mem_wordaddr[IO_LEDS_bit] & !gpio_sel & !pwm_sel) begin
        LEDS_reg <= mem_wdata[4:1];   // software no longer controls bit 0
    end
end
```

No `.pcf` changes are needed — the existing `set_io LEDS[0] 39` mapping is reused.

### Option B: dedicate a new pin

Add `pwm_out` as a new top-level SoC output port and constrain it to any pin not already claimed in your `.pcf` (e.g. not one of `LEDS[0..4]`, `RESET`, `CLK`, `TXD`, `RXD`). Wire an external LED + current-limiting resistor from that pin to ground.

---

## 2. Example Firmware

See `software/pwm_example.c` for the full ready-to-run source. Summary of what it does:

1. Programs `PERIOD=1000`, `DUTY=250` (25% duty).
2. Sets `CTRL=0x1` (`EN=1`, `POL=0`) for standard testing and confirms register readbacks.
3. Disables the IP (`CTRL=0x0`) and verifies `STATUS.RUNNING` drops to 0.
4. Prepares for board demo: Sets `CTRL=0x3` (`EN=1`, `POL=1`) to support Active-Low RGB LEDs.
5. Enters an infinite `while(1)` loop sweeping `DUTY` from 0 up to 1000 and back down to 0 — creating a continuous "breathing" visual effect on the hardware LED.

Build using the existing firmware Makefile pattern rules (no per-file target needed):

```bash
make pwm_example.bram.hex
```

---

## 3. Expected Output

UART log (via existing UART peripheral, if firmware prints status):

```
--- Starting PWM Task-6 Validation ---
Test 1: Program PERIOD=1000 DUTY=250 EN=1
PERIOD readback: 000003E8
Test 1a PASS
DUTY readback: 000000FA
Test 1b PASS

Test 2: STATUS.RUNNING reflects EN
STATUS: 00000001
Test 2 PASS

Test 3: Disable PWM (EN=0)
STATUS after disable: 00000000
Test 3 PASS

Test 4: DUTY sweep (board demo)
```

**LED behavior (hardware):** Upon power-up, the LED will briefly illuminate at a dim 10% brightness (hardware defaults). Once the firmware boots and reaches Test 4, the LED will begin a continuous, smooth breathing effect (fading in to full brightness, then fading out to off).

---

## 4. Common Failure Symptoms & Likely Causes

| Symptom | Likely Cause |
|---|---|
| Register readback always returns 0 | `IO_rdata` mux missing the `pwm_sel ? pwm_rdata` term in the active build branch (check both BENCH and synthesis paths). |
| LED is stuck full-white immediately | Board is stuck in reset or CPU crashed before C code executed. Active-low LED defaults to full ON when internal output is 0. |
| LED stays at constant 10% brightness | The IP is powered on, but the CPU failed to load the `.hex` firmware into BRAM and cannot execute the sweep. |
| Writes to one register corrupt another | Address decode aliasing bug — confirm `pwm_ip.v` checks `mem_addr[11:4]==0` before decoding the low 2 bits. |
| Everything works in simulation, fails on hardware | Usually a pin/`.pcf` constraint issue, or the compiler over-optimized the delay loop in C (use `__asm__ volatile("nop");`). |
