#include "io.h"

void print_string(const char* s);
void print_hex(unsigned int val);

int main() {
    uint32_t val;
    int all_passed = 1;

    print_string("\n--- Starting GPIO Task-6 Validation (windowed decode) ---\n");

    // Test 1: all outputs
    print_string("\nTest 1: All Outputs (DIR = 0xFFFFFFFF)\n");
    IO_OUT(IO_GPIO_DIR, 0xFFFFFFFF);
    IO_OUT(IO_GPIO_DATA, 0xDEADBEEF);
    val = IO_IN(IO_GPIO_READ);
    print_string("Expected: DEADBEEF | Read: ");
    print_hex(val);
    print_string("\n");
    if (val == 0xDEADBEEF) {
        print_string("Test 1 PASS\n");
    } else {
        print_string("Test 1 FAIL\n");
        all_passed = 0;
    }

    // Test 2: all inputs
    print_string("\nTest 2: All Inputs (DIR = 0x00000000)\n");
    IO_OUT(IO_GPIO_DIR, 0x00000000);
    IO_OUT(IO_GPIO_DATA, 0xCAFEBABE);
    val = IO_IN(IO_GPIO_READ);
    print_string("Read (depends on gpio_in, tied to 0 unless bound to pins): ");
    print_hex(val);
    print_string("\n");
    if (val == 0x00000000) {
        print_string("Test 2 PASS\n");
    } else {
        print_string("Test 2 FAIL\n");
        all_passed = 0;
    }

    // Test 3: mixed mode
    print_string("\nTest 3: Mixed Mode (DIR = 0xFFFF0000)\n");
    IO_OUT(IO_GPIO_DIR, 0xFFFF0000);
    IO_OUT(IO_GPIO_DATA, 0x12345678);
    val = IO_IN(IO_GPIO_READ);
    print_string("Expected top half 1234, bottom depends on gpio_in | Read: ");
    print_hex(val);
    print_string("\n");
    if ((val & 0xFFFF0000) == 0x12340000) {
        print_string("Test 3 PASS\n");
    } else {
        print_string("Test 3 FAIL\n");
        all_passed = 0;
    }

    // Test 4: DATA readback is direction-independent
    print_string("\nTest 4: DATA register readback (independent of DIR)\n");
    val = IO_IN(IO_GPIO_DATA);
    print_string("Expected: 12345678 | Read: ");
    print_hex(val);
    print_string("\n");
    if (val == 0x12345678) {
        print_string("Test 4 PASS\n");
    } else {
        print_string("Test 4 FAIL\n");
        all_passed = 0;
    }

    if (all_passed) {
        print_string("\nALL TESTS PASSED! Task-6 GPIO IP (windowed) Validated.\n");
    } else {
        print_string("\nSOME TESTS FAILED! Check RTL.\n");
    }

    return 0;
}
