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
    .word 0x3F, 0x06, 0x5B, 0x4F,0x66, 0x6D, 0x7D, 0x07,0x7F, 0x67, 0x77, 0x7C,0x39, 0x5E, 0x79, 0x71



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
    PUSH {A1, V1-V5, LR}                // Preserve values in A1 and V1-V4 and LR 
    MOV V5, #1
	STR V5, overflowDetected
    LDR V1, =HEX0to3                    // Load the address of the first four HEX displays
    LDR A1, =0x5071383f                 // A1 <- 0x7771383f (Corresponding to 'RFLO' in the hex display)
    STR A1, [V1]                        // Set 0x7771383f at address V1 (=HEX0to3)
	
    LDR V1, =HEX4to5                    // Load the address of the last two HEX displays        
    LDR A1, =0x00003f1c                 // A1 <- 0x00003f3e (Corresponding to 'OV' in the hex display)  
    STR A1, [V1]                        // Set 0x00003f3e at address V1 (=HEX4to5)
    
    POP {A1,V1-V5, LR}                  // Restores values in A1 and V1-V4 and LR
	POP {V1-V2, LR}						// Restore values of V1 and LR  (from checkResultOverflow)
	BX LR                               // Return


// Inputs: A1 <- Contains the current result
checkResultOverflow:
    PUSH {V1-V2, LR}						// Preserve values of V1 and LR 
    // check upper-bound
    LDR V1, =upperBound                 // Loads the upperbound value into V1             
    CMP A1, V1                          // Compare current result with upperbound
    MOV V2, #0
	STRLE V2, overflowDetected
	BGT overflow                        // If overflow, Branch to overflow method
    
    // check lower-bound
    LDR V1, =lowerBound                 // Loads the lowerbound value into V1
    CMP A1, V1                          // Compare current result with lowerbound
    BLT overflow                        // If overflow, Branch to overflow method
    STRGE V2, overflowDetected
	POP {V1-V2, LR}						// Restore values of V1 and LR  
	BX LR                               // Return

// Inputs: A1 <- Contains the current result
// Add negative to 6th display
checkResultForNegative:
    PUSH {V1-V4, LR}				    // Preserve values of V1-V3 and LR 
	MOV V4, #-1							// TODO: STore original value
    // check upper-bound
    LDR V1, =#0x40                      // Loads '-' into V1 
    MOV V2, #0                          // Loads Imm 0 into V2 
    LDR V3, =HEX4to5                    // Loads the Address of 4th 7-segment display         
    CMP A1, V2                          // Compare current result with 0
    STRLTB V1, [V3,#1]                  // Put V1 ('-') into HEX4 + 1 (=> HEX 5)
	MULLT A1, A1, V4
	STRGEB V2, [V3,#1] 
    POP {V1-V4, LR}						// Restore values of V1-V3 and LR 
    BX LR                               // Return

currentResult: .word 0
hasStarted: .word 0
overflowDetected: .word 0


// No Inputs
// Returns: A2 <- SW0-SW3  and  A3 <- SW4-SW7
getTwoNumbers:
    PUSH {V1-V4, LR}				    // Preserve values of V1-V2 and LR 

    LDR V2, =SW_ADDR                    // load the address of slider switch state
    LDR A2, [V2]                        // read slider switch state
    MOV V1, A2                          // Make a tmp copy of A1
    
    // SW0 - SW3
    AND A2, A2, #0x0F                   // Extract the lower 4 bits and store them in A2
    LDR A1, currentResult
    
	LDR V3, hasStarted
	CMP V3, #0
	MOVNE V4, A2
    MOVNE A2, A1
	MOVNE A3, V4
	
    // SW4-SW5
    ANDEQ A3, V1, #0xF0                   // Extract the higher 4 bits and store them in A3
    LSREQ A3, A3, #4                      // Delete '0000' of the higher numbers

    POP {V1-V4, LR}                     // Restaure values of V1-V2 and LR 
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
    	STR A1, currentResult
		STR A1, hasStarted
		STR A1, overflowDetected
        BL PB_clear_edgecp_ASM          // Clear Edge Capture Register

        POP {V1-V2, LR}                 // Restores values in V1-V2 and LR 
        BX LR                           // Return

// Takes as input A2 (SWO-SW3) and A3 (SW4-SW7)
// Multiply A2 with A3, returns the result in A1
multiplication: 
    MUL A1, A2, A3                       // A1 <- A2 (SWO-SW3) * A3 (SW4-SW7)

    BL PB_clear_edgecp_ASM               // Clear Edge Capture Register
	PUSH {V4}
	MOV V4, #1
	STR V4, hasStarted
	POP {V4}
	
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
	
	PUSH {V4}
	MOV V4, #1
	STR V4, hasStarted
	POP {V4}
	
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
    
	PUSH {V4}
	MOV V4, #1
	STR V4, hasStarted
	POP {V4}
	
	BL HEX_write_ASM                     // Write to Memory (7-Segment display) the content of A1
    POP {A1}                             // Restores A1
    POP {V1-V2, LR}                      // Restores values in V1-V2 and LR
    BX LR                                // Returns


// Write to 7-segment
// Inputs: A1 containing the current result 
// Returns:  A1 converted to hexa
convert_decimal_to_display: 
	PUSH {V3-V4, LR}                         // Preserves V3 and LR
    LDR V3, =Display                      // V3 <- Addres of =Display
	
	MOV V4, A1
	LSL V4, V4, #2
	LDR A1, [V3, V4]                      // A1 <- Addres of =Display + Offset (A1)        
    LSR V4, V4, #2
	POP {V3-V4, LR}                          // Restores V3 and LR
    BX LR                                 // Return

divideByTen: 
	PUSH {V1-V2, LR}
	MOV V1, #0 							// Counter V1 <- 0
	
	loopDivideByTen: 
		CMP A1, #10 
		BLT end_loopDivideByTen
		
		SUB A1, A1, #10
		ADD V1, V1, #1
		B loopDivideByTen
		
	end_loopDivideByTen:
		MOV A1, V1						// Move the Quotient to A1
		POP {V1-V2, LR}
		BX LR
		
convertToBCD: 
    PUSH {V1-V8, LR}                      // Preserves V3 and LR
    MOV V7, #0                         // V7 <- Counter = 0
	MOV V8, #0                         // Holds Result
	MOV V2, A1
    loopBCD:
	    CMP V2, #0                     // Compare Quotient with 0
	    BEQ	stop_loop                  // Stop Loop when Quotient == 0
        
        //LDR A4, =0xCCCD                 // A4 <- 0xccd
        //MUL V1, V2, A4                 // V1 <- V2 (Quotient) * A4 (0xccd) 
        //LSR V1, V1, #19                // V1 <- V1 << 15 
		
		BL divideByTen		
		MOV V1, A1
		
		
		
	    MOV V3, #10                    // V3 <- 10
	    MUL V4, V1, V3                 // V4 <- V1 * V3 (10)
	    SUB V5, V2, V4
	    MOV V2, V1
    
	    LSL V6, V7, #2
	    LSL V6, V5, V6
		//LSR V6, V7, #3
	    ORR V8, V8, V6
	    
		ADD V7, V7, #1
	B loopBCD
    stop_loop: 
	    
	    MOV A1, V8
        POP {V1-V8, LR}
        BX LR

    
// Inputs: A1 containing the value of to write 
// Returns: Nothing
HEX_write_ASM:

	PUSH {V5-V8, LR}                      // Preserves V5 and LR               
    LDR V5, =HEX0to3                      // V5 <- Address of HEX0to3
    
	STR A1, currentResult
	
	PUSH {A1}
    BL checkResultOverflow              // Check result for overflow
   	POP {A1}
	LDR V8, overflowDetected
	CMP V8, #0
	BGT skipWrite
	
	
    BL checkResultForNegative           // Check for negative result
    
	BL convertToBCD
    
    LDR V6, =0x0000F                      // V6 <- 0x0000F
    AND V7, A1, V6                        // V7 <- Only first Byte  

    PUSH {A1}
    MOV A1, V7
    BL convert_decimal_to_display         // A1 <- Results converted to 7-Segment Display    
    STRB A1, [V5]                         // Stores A1 (Results converted to 7-Segment Display) in V5 (Address of HEX0to3)
	POP {A1}
    
    ADD V5, V5, #1                        // V5 <- Address of HEX0to3 + 1
    
	LSL V6, V6, #4                        // V6 <- 0x0000F0
    AND V7, A1, V6                        // V7 <- Take Second Byte 
    LSR V7, V7, #4
    
    PUSH {A1}                             // Preserve A1
    MOV A1,V7                             // 
    BL convert_decimal_to_display         // A1 <- Results converted to 7-Segment Display    
    STRB A1, [V5]                         // Stores A1 (Results converted to 7-Segment Display) in V5 (Address of HEX0to3)
	POP {A1}

    ADD V5, V5, #1                        // V5 <- Address of HEX0to3 + 2
    
	LSL V6, V6, #4 
    AND V7, A1, V6                        // V7 <- Only first Byte 
    LSR V7, V7, #8

    PUSH {A1}
    MOV A1,V7
    BL convert_decimal_to_display         // A1 <- Results converted to 7-Segment Display    
    STRB A1, [V5]                         // Stores A1 (Results converted to 7-Segment Display) in V5 (Address of HEX0to3)
	POP {A1}
	
	ADD V5, V5, #1                        // V5 <- Address of HEX0to3 + 2
    
	LSL V6, V6, #4 
    AND V7, A1, V6                        // V7 <- Only first Byte 
    LSR V7, V7, #12

    PUSH {A1}
    MOV A1,V7
    BL convert_decimal_to_display         // A1 <- Results converted to 7-Segment Display    
    STRB A1, [V5]                         // Stores A1 (Results converted to 7-Segment Display) in V5 (Address of HEX0to3)
	POP {A1}

	LDR V5, =HEX4to5                      // V5 <- Address of HEX0to3
    LSL V6, V6, #4
	AND V7, A1, V6                        // V7 <- Only first Byte  
	LSR V7, V7, #16
    PUSH {A1}
    MOV A1, V7
    BL convert_decimal_to_display         // A1 <- Results converted to 7-Segment Display    
    STRB A1, [V5]                         // Stores A1 (Results converted to 7-Segment Display) in V5 (Address of HEX0to3)
	POP {A1}
	
	skipWrite:
    LDR A1, currentResult
	POP {V5-V8, LR}                       // Restore V5 and LR 
    BX LR                                 // Return from the function


_start: 
    BL clearInitial                       // At Startup, r = 0 and HEX displays show '00000'
loop: 
    BL read_slider_switches_ASM         // Branch to function to read state of slider switches and return it in A1
	BL write_LEDs_ASM                   // Write content of A1 to LEDs
    
    BL getTwoNumbers
    BL PB_pressed_released
	
    B loop                              //Infinite Loop