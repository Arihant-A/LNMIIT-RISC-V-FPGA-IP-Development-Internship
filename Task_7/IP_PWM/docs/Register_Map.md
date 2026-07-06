# PWM IP — Register Map

**Base Address:** `PWM_BASE = 0x0040_1000`
**Window Size:** 4 KB (aligned)
**Register Width:** 32-bit, word-aligned
**Access outside register offsets 0x00–0x0C:** reads return `0x0`, writes are ignored.

| Offset | Name     | R/W | Reset Value | Description                                  |
|--------|----------|-----|--------------|-----------------------------------------------|
| 0x00   | CTRL     | R/W | 0x0000_0000  | Enable and polarity control                   |
| 0x04   | PERIOD   | R/W | 0x0000_0001  | PWM period, in clock ticks                    |
| 0x08   | DUTY     | R/W | 0x0000_0000  | High time, in clock ticks                     |
| 0x0C   | STATUS   | R   | 0x0000_0000  | Running flag + live counter (debug)           |

---

## CTRL (0x00) — Read/Write

| Bit(s) | Name | Description                                       |
|--------|------|----------------------------------------------------|
| 0      | EN   | 1 = enable PWM output. 0 = output forced to inactive level. |
| 1      | POL  | 0 = active-high. 1 = active-low (inverts output).  |
| 31:2   | —    | Reserved. Write 0, ignore on read.                 |

## PERIOD (0x04) — Read/Write

- 32-bit unsigned tick count defining the full PWM cycle length.
- Counter runs `0 → PERIOD−1`, then wraps.
- **Hardware-enforced minimum of 1**: writing `0` is silently clamped to `1` at write time. This guarantees the counter comparison logic never divides by / compares against zero.

## DUTY (0x08) — Read/Write

- 32-bit unsigned tick count. Output is driven to the *active* level while the internal counter `cnt < DUTY`, and to the *inactive* level otherwise (before polarity inversion).
- `DUTY = 0` → output stays at the inactive level for the full period.
- `DUTY >= PERIOD` → output stays at the active level for the full period.
- No special-case logic is needed for either edge case — both fall out naturally from the `cnt < DUTY` comparison once PERIOD is clamped to ≥1.

## STATUS (0x0C) — Read-only

| Bit(s) | Name    | Description                              |
|--------|---------|--------------------------------------------|
| 0      | RUNNING | Mirrors CTRL.EN.                           |
| 15:1   | —       | Reserved, reads 0.                         |
| 31:16  | CNT     | Live value of the internal counter (debug/observability only — not required for normal operation). |

Writes to STATUS are ignored (read-only register).

---

## PWM Output Equation

```
pwm_raw    = (cnt < DUTY)
pwm_active = POL ? ~pwm_raw : pwm_raw
pwm_out    = EN  ? pwm_active : (POL ? 1 : 0)   // forced inactive level when disabled
```

## Address Decode Behavior

- The IP claims a full 4 KB window: any address where `addr[31:12] == PWM_BASE[31:12]` asserts the internal `pwm_sel` signal.
- Within that window, only byte offsets `0x00`–`0x0C` are valid registers (`addr[11:4] == 0`). Any other offset inside the window (e.g. `0x10`, `0x40`, `0x100`, ... up to `0xFFC`) is treated as undefined: reads return `0`, writes have no effect. This is enforced explicitly in RTL and covered by regression tests (see `rtl/pwm_tb.v`, Test 8).
