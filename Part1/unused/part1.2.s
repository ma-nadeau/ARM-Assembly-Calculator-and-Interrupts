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
Display: .word 0x3F, 0x06, 0x5B, 0x4F, 0x66,0x6D,0x7D, 0x07, 0x7F,0x67, 0x77,0x7C, 0x39, 0x5E, 0x79, 0x71 

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

//TODO: change for A2 and A3
// Returns: A2 <- SW0-SW3  and  A3 <- SW4-SW7
getTwoNumbers:
    PUSH {V1-V2, LR}

    LDR V2, =SW_ADDR                    // load the address of slider switch state
    LDR A2, [V2]                        // read slider switch state
    MOV V1, A2                          // Make a tmp copy of A1
    
    // SW0 - SW3
    AND A2, A2, #0x0F                   // Extract the lower 4 bits

    // SW4-SW5
    AND A3, V1, #0xF0                   // Extract the lower 4 bits
    LSR A3, A3, #4                      //   

    POP {V1-V2, LR}   
    BX LR      

read_PB_edgecp_ASM: 
    PUSH {V1-V4, LR}                    // Preserve values in V1-V4 and LR
    LDR V1, =PB_ADDR                    // V1 <- 0xFF200050
    LDRB A1, [V1, #0xC]                 // A1 <- read edge capture	register 
    POP {V1-V4, LR}                    	// Restore values in V1-V4 and LR
	BX LR                               // Return

// Takes no input, Clear the edgecapture register
PB_clear_edgecp_ASM:
    PUSH {A1, V1-V4, LR}                    // Preserve values in V1-V4 and LR
    LDR V1, =PB_ADDR                    // V1 <- 0xFF200050
    LDRB A1, [V1, #0xC]                 // A1 <- read edge capture register
    STR A1, [V1, #0xC]                  // Clear the edge capture register
    POP {A1, V1-V4, LR}                    	// Restore values in V1-V4 and LR
	BX LR                               // Return

// No Inputs 
PB_pressed_released:
    PUSH {V1-V2, LR}
	PUSH {A1,LR}
    BL read_PB_edgecp_ASM               // A1 <- Get the button that was released
	MOV V2, A1                          // Store index of button changed
    POP {A1,LR} 
	
	CMP V2, #0                          // Compare V2 ( A1 and PB0 ) with PB0 (check if remains active after and)
    BEQ test
	
    LDR V1, =PB0                        // V1 <- 0x0000001
    CMP V2, V1                          // Compare V2 ( A1 and PB0 ) with PB0 (check if remains active after and)
    BEQ clear                           // If Equal, clear

    LDR V1, =PB1                        // V1 <- 0x00000002 
    CMP V2, V1                          // Compare V2 ( A1 and PB0 ) with PB0 (check if remains active after and)
    BEQ multiplication
    
	LDR V1, =PB2                        // V1 <- 0x00000002 
    CMP V2, V1                          // Compare V2 ( A1 and PB0 ) with PB0 (check if remains active after and)
    SUBEQ A1, A2, A3                    // If Equal, return #0x00000001

    LDR V1, =PB3                        // V1 <- 0x00000002 
    CMP V2, V1                          // Compare V2 ( A1 and PB0 ) with PB0 (check if remains active after and)
    ADDEQ A1, A2, A3                        // If Equal, return #0x00000001
    
    BL PB_clear_edgecp_ASM              // Clear Edge Capture Register
test: 
    POP {V1-V2, LR}
    BX LR

// Takes as input A1 (SWO-SW3) and A2 (SW4-SW7)
// Multiply A2 with A3 and return it in A1
multiplication: 
    MUL A1, A2, A3
	BL HEX_write_ASM
    POP {V1, LR}
    BX LR 

// Takes as input A1 (SWO-SW3) and A2 (SW4-SW7)
// Substract A2 by A3 and return it in A1
substraction:
    SUB A1, A2, A3
    POP {V1, LR}
    BX LR 

// Takes as input A1 (SWO-SW3) and A2 (SW4-SW7)
// Add A2 and A3 and return it in A1
addition:
    ADD A1, A2, A3
    POP {V1, LR}
    BX LR 

// No inputs 
// Resets the result or show '00000' in HEX displays
clear: 
    PUSH {A1, V1-V4, LR}                // Preserve values in A1 and V1-V4 and LR 
    LDR V1, =HEX0to3                    // Load the address of the first four HEX displays
    LDR A1, =0x3f3f3f3f                 // A1 <- 0x3f3f3f3f (Corresponding to '0000' in the hex display)
    STR A1, [V1]                        // Set 0x3f3f3f3f at address V1 (=HEX0to3)
	
    LDR V1, =HEX4to5                    // Load the address of the last two HEX displays        
    //TODO: ask about sign bit
    LDR A1, =0x0000003f                 // A1 <- 0x00003f3f (Corresponding to '0' in the hex display)  
    STR A1, [V1]                        // Set 0x0000003f at address V1 (=HEX4to5)
    POP {A1,V1-V4, LR}                  // Restores values in A1 and V1-V4 and LR
	BX LR                               // Return

// Write to 7-segment
// Inputs: A1 containing the current result 
// Returns:  A1 converted to hexa
convert_decimal_to_display: 
    
	PUSH {V1-V4, LR} 
	
    LDR A2, =Display
	LDR A1, [A2, A1]
    POP {V1-V4, LR}
    
	BX LR

HEX_write_ASM:

	PUSH {V1-V4, LR}  
    LDR V4, =HEX0to3

    MOV A1, #0
    BL convert_decimal_to_display
    MOV A4, A1
    POP {A1-A3,LR}

    LDR V1, =HEX0
    AND V2, A1, V1
    CMP V2, V1
    STREQB A2, [V4] 
	
	POP {V1-V4, LR}
    BX LR                               // Return from the function

_start: 
    BL clear                            // At Startup, r = 0 and HEX displays show '00000'
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