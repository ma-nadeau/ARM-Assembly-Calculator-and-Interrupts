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

    BX LR              // Return from the function

_start: 
    MOV A1 , #0                         // Initialize A1 with 0

infinite_loop: 
    BL read_slider_switches_ASM         // Branch to function to read state of slider switches and return it in A1
    MOV A3, A1                          // MOV A1 to A3 (copy)
    CMP A3, A1                          // Compare A3 (previous state) with A1 (current State)
    BL write_LEDs_ASM                   // Else write content of A1 to LEDs
    B no_change_LED
no_change_LED:
  
    B infinite_loop                     // Infinite Loop
