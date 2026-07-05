#include "io.h"

void print_string(const char* s);
void print_hex(unsigned int val);

#define PWM_BASE 0x00401000
#define PWM_OUT(off, val) IO_OUT(PWM_BASE + (off), (val))
#define PWM_IN(off)       IO_IN(PWM_BASE + (off))

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
    print_string("PERIOD readback: ");
    print_hex(val);
    print_string("\n");
    if (val == 1000) {
        print_string("Test 1a PASS\n");
    } else {
        print_string("Test 1a FAIL\n");
        all_passed = 0;
    }

    val = PWM_IN(IO_PWM_DUTY - PWM_BASE);
    print_string("DUTY readback: ");
    print_hex(val);
    print_string("\n");
    if (val == 250) {
        print_string("Test 1b PASS\n");
    } else {
        print_string("Test 1b FAIL\n");
        all_passed = 0;
    }

    // Test 2: STATUS reflects EN
    print_string("\nTest 2: STATUS.RUNNING reflects EN\n");
    val = PWM_IN(IO_PWM_STATUS - PWM_BASE);
    print_string("STATUS: ");
    print_hex(val);
    print_string("\n");
    if (val & 0x1) {
        print_string("Test 2 PASS\n");
    } else {
        print_string("Test 2 FAIL\n");
        all_passed = 0;
    }

    // Test 3: Disable, check STATUS.RUNNING drops
    print_string("\nTest 3: Disable PWM (EN=0)\n");
    PWM_OUT(IO_PWM_CTRL - PWM_BASE, 0x0);
    val = PWM_IN(IO_PWM_STATUS - PWM_BASE);
    print_string("STATUS after disable: ");
    print_hex(val);
    print_string("\n");
    if ((val & 0x1) == 0) {
        print_string("Test 3 PASS\n");
    } else {
        print_string("Test 3 FAIL\n");
        all_passed = 0;
    }

    // Test 4: Board demo hook — sweep DUTY for visible brightness change.
    print_string("\nTest 4: DUTY sweep (board demo)\n");
    PWM_OUT(IO_PWM_CTRL - PWM_BASE, 0x1); // re-enable
    {
        int d;
        for (d = 0; d <= 1000; d += 100) {
            PWM_OUT(IO_PWM_DUTY - PWM_BASE, d);
        }
    }
    print_string("DUTY sweep complete (visually check LED on hardware)\n");

    if (all_passed) {
        print_string("\nALL TESTS PASSED! Task-6 PWM IP Validated.\n");
    } else {
        print_string("\nSOME TESTS FAILED! Check RTL.\n");
    }

    return 0;
}
