#include "io.h"

void print_string(const char* s);
void print_hex(unsigned int val);

#define PWM_BASE 0x00401000
#define PWM_OUT(off, val) IO_OUT(PWM_BASE + (off), (val))
#define PWM_IN(off)       IO_IN(PWM_BASE + (off))

void delay(volatile unsigned int count) {
    while (count--) { }
}

int main() {
    unsigned int val;
    int all_passed = 1;

    print_string("\n--- Starting PWM Task-6 Validation ---\n");

    // Test 1: PERIOD=1000, DUTY=250 (25% duty), POL=0, EN=1
    print_string("\nTest 1: Program PERIOD=1000 DUTY=250 EN=1\n");
    PWM_OUT(IO_PWM_PERIOD - PWM_BASE, 1000);
    PWM_OUT(IO_PWM_DUTY - PWM_BASE,   250);
    PWM_OUT(IO_PWM_CTRL - PWM_BASE,   0x1); // EN=1, POL=0

    val = PWM_IN(IO_PWM_PERIOD - PWM_BASE);
    if (val == 1000) print_string("Test 1a PASS\n"); else print_string("Test 1a FAIL\n");

    val = PWM_IN(IO_PWM_DUTY - PWM_BASE);
    if (val == 250) print_string("Test 1b PASS\n"); else print_string("Test 1b FAIL\n");

    // Test 2: STATUS reflects EN
    val = PWM_IN(IO_PWM_STATUS - PWM_BASE);
    if (val & 0x1) print_string("Test 2 PASS\n"); else print_string("Test 2 FAIL\n");

    // Test 3: Disable, check STATUS.RUNNING drops
    PWM_OUT(IO_PWM_CTRL - PWM_BASE, 0x0);
    val = PWM_IN(IO_PWM_STATUS - PWM_BASE);
    if ((val & 0x1) == 0) print_string("Test 3 PASS\n"); else print_string("Test 3 FAIL\n");

    // Test 4: DUTY sweep (board demo) — VISIBLE breathing
    print_string("\nTest 4: DUTY sweep (board demo)\n");

    // Set EN=1 AND POL=1 (0x3).
    // Inverting polarity makes it so Duty=0 is OFF, and Duty=1000 is ON for Active-Low LEDs.
    PWM_OUT(IO_PWM_CTRL - PWM_BASE, 0x3);

    int d;
    while (1) {
        // Fade in
        for (d = 0; d <= 1000; d += 10) {
            PWM_OUT(IO_PWM_DUTY - PWM_BASE, d);
            delay(40000);  // Tuned for ~12MHz clock
        }
        // Fade out
        for (d = 1000; d >= 0; d -= 10) {
            PWM_OUT(IO_PWM_DUTY - PWM_BASE, d);
            delay(40000);
        }
    }
    return 0;
}

