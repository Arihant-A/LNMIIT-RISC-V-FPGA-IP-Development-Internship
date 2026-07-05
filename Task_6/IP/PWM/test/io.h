#ifndef IO_H
#define IO_H

#include <stdint.h>

// ---- Existing legacy peripherals (IO_BASE window, 1-hot bit decode) ----
#define IO_BASE       0x00400000
#define IO_LEDS       (IO_BASE + 4)
#define IO_UART_DAT   (IO_BASE + 8)
#define IO_UART_CNTL  (IO_BASE + 16)

// ---- PWM IP (own 4KB window) ----
#define PWM_BASE      0x00401000
#define IO_PWM_CTRL   (PWM_BASE + 0x00)
#define IO_PWM_PERIOD (PWM_BASE + 0x04)
#define IO_PWM_DUTY   (PWM_BASE + 0x08)
#define IO_PWM_STATUS (PWM_BASE + 0x0C)

// ---- GPIO IP (own 4KB window) ----
#define GPIO_BASE     0x00402000
#define IO_GPIO_DATA  (GPIO_BASE + 0x00)
#define IO_GPIO_DIR   (GPIO_BASE + 0x04)
#define IO_GPIO_READ  (GPIO_BASE + 0x08)

#define IO_OUT(addr, val) (*(volatile uint32_t*)(addr) = (val))
#define IO_IN(addr)        (*(volatile uint32_t*)(addr))

#endif
