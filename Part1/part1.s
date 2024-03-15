.global _start


// Values of HEX 
HEX0 = 0x00000001
HEX1 = 0x00000002
HEX2 = 0x00000004
HEX3 = 0x00000008
HEX4 = 0x00000010
HEX5 = 0x00000020

.equ HEX0to3, 0xFF200020                // Addres of 7-Segment display 0 to 3
.equ HEX4to5, 0xFF200030                // Addres of 7-Segment display 4 to 5

.equ SW_ADDR, 0xFF200040                // Addres of slider switch state
.equ LED_ADDR, 0xFF200000               // Address of the LEDs' state

.equ upperBound, 0x0001869F             // UpperBound =  99'999
.equ lowerBound, 0xFFFE7961             // LowerBound = -99'999

// Value of push buttons
PB0 = 0x00000001
PB1 = 0x00000002
PB2 = 0x00000004
PB3 = 0x00000008

.equ PB_ADDR, 0xFF200050                // Address of Push Button

Display: 
    .word 0x003F, 0x0006, 0x005B, 0x004F,0x0066, 0x006D, 0x007D, 0x0007,0x007F, 0x0067, 0x0077, 0x007C,0x0039, 0x005E, 0x0079, 0x0071



// Slider Switches Driver
// returns the state of slider switches in A1
// post- A1: slide switch state
read_slider_switches_ASM:
    LDR A2, =SW_ADDR                    // load the address of slider switch state
    LDR A1, [A2]                        // read slider switch state 
    BX  LR

// LEDs Driver
// writes the state of LEDs (On/Off) in A1 to the LEDs' control register
// pre-- A1: data to write to LED state
write_LEDs_ASM:
    LDR A2, =LED_ADDR                   // load the address of the LEDs' state
    STR A1, [A2]                        // update LED state with the contents of A1
    BX LR


// Input: A1 <- Containing the current result 
// Sets the 7-segment display of 'OVRFLO'
overflow: 
    PUSH {A1, V1-V4, LR}                // Preserve values in A1 and V1-V4 and LR 
    
    LDR V1, =HEX0to3                    // Load the address of the first four HEX displays
    LDR A1, =0x7771383f                 // A1 <- 0x7771383f (Corresponding to 'RFLO' in the hex display)
    STR A1, [V1]                        // Set 0x7771383f at address V1 (=HEX0to3)
	
    LDR V1, =HEX4to5                    // Load the address of the last two HEX displays        
    LDR A1, =0x00003f3e                 // A1 <- 0x00003f3e (Corresponding to 'OV' in the hex display)  
    STR A1, [V1]                        // Set 0x00003f3e at address V1 (=HEX4to5)
    
    POP {A1,V1-V4, LR}                  // Restores values in A1 and V1-V4 and LR
	POP {V1, LR}						// Restore values of V1 and LR  (from checkResultOverflow)
	BX LR                               // Return


// Inputs: A1 <- Contains the current result
checkResultOverflow:
    PUSH {V1, LR}						// Preserve values of V1 and LR 

    // check upper-bound
    LDR V1, =upperBound                 // Loads the upperbound value into V1             
    CMP A1, V1                          // Compare current result with upperbound
    BGT overflow                        // If overflow, Branch to overflow method
    
    // check lower-bound
    LDR V1, =lowerBound                 // Loads the lowerbound value into V1
    CMP A1, V1                          // Compare current result with lowerbound
    BLT overflow                        // If overflow, Branch to overflow method
    POP {V1, LR}						// Restore values of V1 and LR 
    BX LR                               // Return

// Inputs: A1 <- Contains the current result
// Add negative to 6th display
checkResultForNegative:
    PUSH {V1-V3, LR}				    // Preserve values of V1-V3 and LR 

    // check upper-bound
    LDR V1, =#0x40                       // Loads '-' into V1 
    MOV V2, #0                          // Loads Imm 0 into V2 
    LDR V3, =HEX4to5                    // Loads the Address of 4th 7-segment display         
    CMP A1, V2                          // Compare current result with 0
    STRLEB V1, [V3,#1]                  // Put V1 ('-') into HEX4 + 1 (=> HEX 5)  
    POP {V1-V3, LR}						// Restore values of V1-V3 and LR 
    BX LR                               // Return



// No Inputs
// Returns: A2 <- SW0-SW3  and  A3 <- SW4-SW7
getTwoNumbers:
    PUSH {V1-V2, LR}				    // Preserve values of V1-V2 and LR 

    LDR V2, =SW_ADDR                    // load the address of slider switch state
    LDR A2, [V2]                        // read slider switch state
    MOV V1, A2                          // Make a tmp copy of A1
    
    // SW0 - SW3
    AND A2, A2, #0x0F                   // Extract the lower 4 bits and store them in A2

    // SW4-SW5
    AND A3, V1, #0xF0                   // Extract the higher 4 bits and store them in A3
    LSR A3, A3, #4                      // Delete '0000' of the higher numbers

    POP {V1-V2, LR}                     // Restaure values of V1-V2 and LR 
    BX LR                               // Return  

read_PB_edgecp_ASM: 
    PUSH {V1-V4, LR}                    // Preserve values in V1-V4 and LR
    LDR V1, =PB_ADDR                    // V1 <- 0xFF200050
    LDRB A1, [V1, #0xC]                 // A1 <- read edge capture	register 
    POP {V1-V4, LR}                    	// Restore values in V1-V4 and LR
	BX LR                               // Return

// Takes no input, Clear the edgecapture register
PB_clear_edgecp_ASM:
    PUSH {A1, V1-V4, LR}                    // Preserve values in V1-V4 and LR
    LDR V1, =PB_ADDR                    	// V1 <- 0xFF200050
    LDRB A1, [V1, #0xC]                 	// A1 <- read edge capture register
    STR A1, [V1, #0xC]                  	// Clear the edge capture register
    POP {A1, V1-V4, LR}                    	// Restore values in V1-V4 and LR
	BX LR                               	// Return


// No Inputs 
// Look at Edge Registers and performs the action of the released button
// Returns: A1 <- Results
PB_pressed_released:
    PUSH {V1-V2, LR}                    // Preserves V1-V2 and LR on the stack
	
    PUSH {A1}                           // Preserves A1 on the stack

    BL read_PB_edgecp_ASM               // A1 <- Get the button that was released
	MOV V2, A1                          // Store index of button changed

    POP {A1}                            // Restores A1 from the stack
	
	CMP V2, #0                          // Compare V2 (index of button released) with #0 (no change)
    BEQ noButtonReleased                // If Equal, Branch to end of subroutine
	
    LDR V1, =PB0                        // V1 <- 0x0000001
    CMP V2, V1                          // Compare V2 (index of button released) with PB0 (0x0000001)
    BEQ clear                           // If Equal, clear

    LDR V1, =PB1                        // V1 <- 0x00000002 
    CMP V2, V1                          // Compare V2 (index of button released) with PB0 (0x0000002)
    BEQ multiplication                  // If Equal, Multiple
    
	LDR V1, =PB2                        // V1 <- 0x00000004 
    CMP V2, V1                          // Compare V2 (index of button released) with PB0 (0x0000004)
    BEQ substraction                    // If Equal, Subtract

    LDR V1, =PB3                        // V1 <- 0x00000002 
    CMP V2, V1                          // Compare V2 (index of button released) with PB0 (0x0000008)
    BEQ addition                        // If Equal, Add
    
    noButtonReleased:
        BL PB_clear_edgecp_ASM          // Clear Edge Capture Register               
        POP {V1-V2, LR}                 // When no button was released
        BX LR                           // Return

// No inputs 
// Resets the result or show '00000' in HEX displays
clearInitial: 
    PUSH {V1-V2, LR}                    // Preserve values in V1-V2 and LR 
    
    clear:                              
        LDR V1, =HEX0to3                // Load the address of the first four HEX displays
        LDR V2, =0x3f3f3f3f             // V2 <- 0x3f3f3f3f (Corresponding to '0000' in the hex display)
        STR V2, [V1]                    // Write 0x3f3f3f3f to address V1 (=HEX0to3)
	
        LDR V1, =HEX4to5                // Load the address of the last two HEX displays

        LDR V2, =0x0000003f             // A1 <- 0x00003f3f (Corresponding to '0' in the hex display)  
        STR V2, [V1]                    // Write 0x0000003f to address V1 (=HEX4to5)
    
        MOV A1, #0                      // Resets Result to 0
    
        BL PB_clear_edgecp_ASM          // Clear Edge Capture Register

        POP {V1-V2, LR}                 // Restores values in V1-V2 and LR 
        BX LR                           // Return

// Takes as input A2 (SWO-SW3) and A3 (SW4-SW7)
// Multiply A2 with A3, returns the result in A1
multiplication: 
    MUL A1, A2, A3                       // A1 <- A2 (SWO-SW3) * A3 (SW4-SW7)

    BL PB_clear_edgecp_ASM               // Clear Edge Capture Register

	PUSH {A1}                            // Preserves A1
    BL HEX_write_ASM                     // Write to Memory (7-Segment display) the content of A1
    POP {A1}                             // Restores A1

    POP {V1-V2, LR}                      // Restores values in V1-V2 and LR
    BX LR                                // Returns

// Takes as input A1 (SWO-SW3) and A2 (SW4-SW7)
// Substract A2 by A3 and return it in A1
substraction:

    SUB A1, A2, A3                       //  A1 <- A2 (SWO-SW3) - A3 (SW4-SW7)
    BL PB_clear_edgecp_ASM               // Clear Edge Capture Register
	PUSH {A1}                            // Preserves A1
    BL HEX_write_ASM                     // Write to Memory (7-Segment display) the content of A1
    POP {A1}                             // Restores A1
    POP {V1-V2, LR}                      // Restores values in V1-V2 and LR
    BX LR                                // Returns

// Takes as input A1 (SWO-SW3) and A2 (SW4-SW7)
// Add A2 and A3 and return it in A1
addition:
    ADD A1, A2, A3                       //  A1 <- A2 (SWO-SW3) + A3 (SW4-SW7)
    BL PB_clear_edgecp_ASM               // Clear Edge Capture Register
	PUSH {A1}                            // Preserves A1
    BL HEX_write_ASM                     // Write to Memory (7-Segment display) the content of A1
    POP {A1}                             // Restores A1
    POP {V1-V2, LR}                      // Restores values in V1-V2 and LR
    BX LR                                // Returns


// Write to 7-segment
// Inputs: A1 containing the current result 
// Returns:  A1 converted to hexa
convert_decimal_to_display: 
	PUSH {V3, LR}                         // Preserves V3 and LR
    LDR V3, =Display                      // V3 <- Addres of =Display
	LDR A1, [V3, A1]                      // A1 <- Addres of =Display + Offset (A1)        
    POP {V3, LR}                          // Restores V3 and LR
    BX LR                                 // Return

// Inputs: A1 containing the value of to write 
// Returns: Nothing
HEX_write_ASM:

	PUSH {V5-V7, LR}                      // Preserves V5 and LR               
    LDR V5, =HEX0to3                      // V5 <- Address of HEX0to3
    
    LDR V6, =0x0000F                      // V6 <- 0x0000F
    AND V7, A1, V6                        // V7 <- Only first Byte  

    PUSH {A1}
    MOV A1, V7
    BL convert_decimal_to_display         // A1 <- Results converted to 7-Segment Display    
    STRB A1, [V5]                         // Stores A1 (Results converted to 7-Segment Display) in V5 (Address of HEX0to3)
	POP {A1}
    
    ADD V5, V5, #1                        // V5 <- Address of HEX0to3 + 1
    LSL V6, V6, #1                        // V6 <- 0x0000F0
    AND V7, A1, V6                        // V7 <- Take Second Byte 
    LSR V7, V7, #1                        // Delete 0 on the right
    
    PUSH {A1}                             // Preserve A1
    MOV A1,V7                             // 
    BL convert_decimal_to_display         // A1 <- Results converted to 7-Segment Display    
    STRB A1, [V5]                         // Stores A1 (Results converted to 7-Segment Display) in V5 (Address of HEX0to3)
	POP {A1}

    ADD V5, V5, #1                        // V5 <- Address of HEX0to3 + 2
    LSL V6, V6, #1 
    AND V7, A1, V6                        // V7 <- Only first Byte 
    LSR V7, V7, #2                        // V6 <- 0x000F00

    PUSH {A1}
    MOV A1,V7
    BL convert_decimal_to_display         // A1 <- Results converted to 7-Segment Display    
    STRB A1, [V5]                         // Stores A1 (Results converted to 7-Segment Display) in V5 (Address of HEX0to3)
	POP {A1}

    POP {V5-V7, LR}                        // Restore V5 and LR 
    BX LR                               // Return from the function


_start: 
    //BL clear                            // At Startup, r = 0 and HEX displays show '00000'
loop: 
    //BL read_slider_switches_ASM         // Branch to function to read state of slider switches and return it in A1
	//BL write_LEDs_ASM                   // Write content of A1 to LEDs
    //LDR A1, =upperBound
	//ADD A1, A1, #1
    //BL checkResultOverflow              // Check result for overflow
    //TODO: Conflict to with negative oveflow
    //BL checkResultForNegative           // Check for negative result
    BL getTwoNumbers
    BL PB_pressed_released
	
    B loop                              //Infinite Loop