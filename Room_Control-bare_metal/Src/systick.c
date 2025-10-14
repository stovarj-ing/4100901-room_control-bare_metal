#include "systick.h"
#include "gpio.h"



void init_systick(void)
{
    // HSI = 4 MHz (según tu proyecto); 1 ms tick
    SYSTICK->RVR = 4000000U / 1000U - 1U;
    SYSTICK->CSR = (1U << 0) | (1U << 1) | (1U << 2); // ENABLE | TICKINT | CLKSOURCE
}

