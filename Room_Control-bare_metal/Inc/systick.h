// systick.h
#include <stdint.h>

#define SYSTICK_H


void init_systick(void);
uint32_t systick_get_ms(void);



typedef struct {
    volatile uint32_t CSR;   // Control and Status Register
    volatile uint32_t RVR;   // Reload Value Register
    volatile uint32_t CVR;   // Current Value Register
    volatile uint32_t CALIB; // Calibration Value Register
} SYSTICK_Typedef_t;

#define SYSTICK_BASE 0xE000E010U
#define SYSTICK      ((SYSTICK_Typedef_t *) SYSTICK_BASE)

void init_systick(void);