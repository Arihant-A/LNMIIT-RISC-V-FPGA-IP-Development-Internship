#include "io.h"

void print_string(const char* s);
void print_hex(unsigned int val);

int main() {
    unsigned int val;
    int all_passed = 1;

    print_string("\n--- Starting Combined GPIO+PWM Task-6 Validation ---\n");

    // --- GPIO: mixed-mode test ---
    print_string("\n[GPIO] Mixed Mode (DIR = 0xFFFF0000)\n");
    IO_OUT(IO_GPIO_DIR, 0xFFFF0000);
    IO_OUT(IO_GPIO_DATA, 0x12345678);
    val = IO_IN(IO_GPIO_READ);
    print_string("Read: ");
    print_hex(val);
    print_string("\n");
    if ((val & 0xFFFF0000) == 0x12340000) {
        print_string("[GPIO] PASS\n");
    } else {
        print_string("[GPIO] FAIL\n");
        all_passed = 0;
    }

    // --- PWM: program PERIOD/DUTY, right after GPIO access ---
    print_string("\n[PWM] Program PERIOD=1000 DUTY=250 EN=1\n");
    IO_OUT(IO_PWM_PERIOD, 1000);
    IO_OUT(IO_PWM_DUTY,   250);
    IO_OUT(IO_PWM_CTRL,   0x1);

    val = IO_IN(IO_PWM_PERIOD);
    print_string("PERIOD readback: ");
    print_hex(val);
    print_string("\n");
    if (val == 1000) {
        print_string("[PWM] PERIOD PASS\n");
    } else {
        print_string("[PWM] PERIOD FAIL\n");
        all_passed = 0;
    }

    // --- Interleave: re-check GPIO after PWM writes, to catch cross-talk ---
    print_string("\n[GPIO] Re-check DATA after PWM writes\n");
    val = IO_IN(IO_GPIO_DATA);
    print_string("Read: ");
    print_hex(val);
    print_string("\n");
    if (val == 0x12345678) {
        print_string("[GPIO] Re-check PASS (no cross-talk from PWM)\n");
    } else {
        print_string("[GPIO] Re-check FAIL (possible IP cross-talk!)\n");
        all_passed = 0;
    }

    // --- Interleave: re-check PWM after GPIO access, to catch cross-talk ---
    print_string("\n[PWM] Re-check DUTY after GPIO access\n");
    val = IO_IN(IO_PWM_DUTY);
    print_string("Read: ");
    print_hex(val);
    print_string("\n");
    if (val == 250) {
        print_string("[PWM] Re-check PASS (no cross-talk from GPIO)\n");
    } else {
        print_string("[PWM] Re-check FAIL (possible IP cross-talk!)\n");
        all_passed = 0;
    }

    if (all_passed) {
        print_string("\nALL COMBINED TESTS PASSED! GPIO + PWM coexist correctly.\n");
    } else {
        print_string("\nSOME COMBINED TESTS FAILED! Check RTL.\n");
    }

    return 0;
}
