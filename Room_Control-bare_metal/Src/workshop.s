    .section .text
    .syntax unified
    .thumb

    .global main
    .global init_led
    .global init_boton
    .global init_systick
    .global SysTick_Handler

// --- Definiciones de registros para LD2 (GPIOA) -------------------------------
    .equ RCC_BASE,       0x40021000         @ Base de RCC
    .equ RCC_AHB2ENR,    RCC_BASE + 0x4C    @ Enable GPIOx clock (AHB2ENR)

    .equ GPIOA_BASE,     0x48000000         @ Base de GPIOA
    .equ GPIOA_MODER,    GPIOA_BASE + 0x00  @ Mode register
    .equ GPIOA_ODR,      GPIOA_BASE + 0x14  @ Output data register
    .equ LD2_PIN,        5                  @ Pin del LED LD2 (PA5)

// --- Definiciones de registros para Botón (PC13) ------------------------------
    .equ GPIOC_BASE,     0x48000800         @ Base de GPIOC 
    .equ GPIOC_MODER,    GPIOC_BASE + 0x00  @ Mode register
    .equ GPIOC_IDR,      GPIOC_BASE + 0x10  @ Input data register 
    .equ BOTON,          13                 @ Pin del pulsador (PC13)

    .equ SYST_CSR,       0xE000E010         @ Control and status
    .equ SYST_RVR,       0xE000E014         @ Reload value register
    .equ SYST_CVR,       0xE000E018         @ Current value register
    .equ HSI_FREQ,       12000000           @ Reloj interno (12 MHz)

// --- Variable global (contador de ticks) -------------------------------------
    .bss
delay_counter: .word 0

// --- Programa principal ------------------------------------------------------
    .text
main:
    bl init_led
    bl init_boton
    bl init_systick

loop:
    @ Leer el estado del botón
    movw  r0, #:lower16:GPIOC_IDR
    movt  r0, #:upper16:GPIOC_IDR
    ldr   r1, [r0]
    tst   r1, #(1 << BOTON)      @ ¿Está en 1? (no presionado → pull-up)
    bne   loop                   @ Si no está presionado → sigue en loop

    @ Si está presionado → encender LED
    bl encender_led

    @ Cargar 3s en delay_counter
    ldr   r0, =delay_counter
    movs  r1, #3
    str   r1, [r0]

espera:
    ldr   r0, =delay_counter
    ldr   r1, [r0]
    cmp   r1, #0
    bne   espera                 @ Espera hasta que SysTick lo reduzca a 0

    @ Apagar LED
    bl apagar_led
    b loop

// --- Inicialización de GPIOA PA5 como salida ---------------------------------
init_led:
    movw  r0, #:lower16:RCC_AHB2ENR
    movt  r0, #:upper16:RCC_AHB2ENR
    ldr   r1, [r0]
    orr   r1, r1, #(1 << 0)                @ Habilita reloj GPIOA
    str   r1, [r0]

    movw  r0, #:lower16:GPIOA_MODER
    movt  r0, #:upper16:GPIOA_MODER
    ldr   r1, [r0]
    bic   r1, r1, #(0b11 << (LD2_PIN * 2)) @ Limpia bits MODER5
    orr   r1, r1, #(0b01 << (LD2_PIN * 2)) @ PA5 como salida
    str   r1, [r0]
    bx    lr

// --- Inicialización de GPIOC PC13 como entrada -------------------------------
init_boton:
    movw  r0, #:lower16:RCC_AHB2ENR
    movt  r0, #:upper16:RCC_AHB2ENR
    ldr   r1, [r0]
    orr   r1, r1, #(1 << 2)                @ Habilita reloj GPIOC
    str   r1, [r0]

    movw  r0, #:lower16:GPIOC_MODER
    movt  r0, #:upper16:GPIOC_MODER
    ldr   r1, [r0]
    bic   r1, r1, #(0b11 << (BOTON * 2))   @ PC13 como entrada (00)
    str   r1, [r0]
    bx    lr

// --- Inicialización de SysTick para 1s --------------------------------------
init_systick:
    movw  r0, #:lower16:SYST_RVR
    movt  r0, #:upper16:SYST_RVR
    movw  r1, #:lower16:HSI_FREQ*3
    movt  r1, #:upper16:HSI_FREQ*3
    subs  r1, r1, #1                       @ reload = 12,000,000 - 1 (1s)
    str   r1, [r0]

    movw  r0, #:lower16:SYST_CSR
    movt  r0, #:upper16:SYST_CSR
    movs  r1, #(1 << 0)|(1 << 1)|(1 << 2)  @ ENABLE=1, TICKINT=1, CLKSOURCE=1
    str   r1, [r0]
    bx    lr

// --- Manejador de la interrupción SysTick -----------------------------------
    .thumb_func
SysTick_Handler:
    ldr   r0, =delay_counter
    ldr   r1, [r0]
    cmp   r1, #0
    beq   end_systick
    subs  r1, r1, #1
    str   r1, [r0]
end_systick:
    bx    lr


encender_led:
    movw  r0, #:lower16:GPIOA_ODR
    movt  r0, #:upper16:GPIOA_ODR
    ldr   r1, [r0]
    orr   r1, r1, #(1 << LD2_PIN)          @ PA5 = 1
    str   r1, [r0]
    bx    lr

apagar_led:
    movw  r0, #:lower16:GPIOA_ODR
    movt  r0, #:upper16:GPIOA_ODR
    ldr   r1, [r0]
    bic   r1, r1, #(1 << LD2_PIN)          @ PA5 = 0
    str   r1, [r0]
    bx    lr
