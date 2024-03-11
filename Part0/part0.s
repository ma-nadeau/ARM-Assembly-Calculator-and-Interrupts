.global _start

// Slider Switches Driver
// returns the state of slider switches in A1
// post- A1: slide switch state
.equ SW_ADDR, 0xFF200040
read_slider_switches_ASM:
    LDR A2, =SW_ADDR                    // load the address of slider switch state
    LDR A1, [A2]                        // read slider switch state 
    BX  LR

// LEDs Driver
// writes the state of LEDs (On/Off) in A1 to the LEDs' control register
// pre-- A1: data to write to LED state
.equ LED_ADDR, 0xFF200000
write_LEDs_ASM:
    LDR A2, =LED_ADDR                   // load the address of the LEDs' state
    STR A1, [A2]                        // update LED state with the contents of A1
    BX LR

//Values of HEX 
HEX0 = 0x00000001
HEX1 = 0x00000002
HEX2 = 0x00000004
HEX3 = 0x00000008
HEX4 = 0x00000010
HEX5 = 0x00000020

.equ HEX0to3, 0xFF200020
.equ HEX4to5, 0xFF200030
HEX_clear_ASM:
    MOV V3, #0
    LDR V4, =HEX0to3
    LDR V1, =HEX0
    AND V2, A1, V1
    CMP V2, V1
    STREQB V3, [V4] 

    LDR V1, =HEX1
    AND V2, A1, V1
    CMP V2, V1
    STREQB V3, [V4] 

    LDR V1, =HEX2
    AND V2, A1, V1
    CMP V2, V1
    STREQB V3, [V4] 

    LDR V1, =HEX3
    AND V2, A1, V1
    CMP V2, V1
    STREQB V3, [V4] 

    LDR V4, =HEX4to5
    LDR V1, =HEX4
    AND V2, A1, V1
    CMP V2, V1
    STREQB V3, [V4] 

    LDR V1, =HEX5
    AND V2, A1, V1
    CMP V2, V1
    STREQB V3, [V4] 

    BX LR              // Return from the function


_start: 
    MOV A1 , #0                         // Initialize A1 with 0

infinite_loop: 
    BL read_slider_switches_ASM         // Branch to function to read state of slider switches and return it in A1
    MOV A3, A1                          // MOV A1 to A3 (copy)
    CMP A3, A1                          // Compare A3 (previous state) with A1 (current State)
    BEQ no_change_LED                   // If no change (A3 = A1), skip LEDs write
    BL write_LEDs_ASM                   // Else write content of A1 to LEDs
 
no_change_LED:
    MOV A1, #0b01
    BL HEX_clear_ASM
    B infinite_loop                     // Infinite Loop
