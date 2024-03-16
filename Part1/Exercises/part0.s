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



// Values of HEX 
HEX0 = 0x00000001
HEX1 = 0x00000002
HEX2 = 0x00000004
HEX3 = 0x00000008
HEX4 = 0x00000010
HEX5 = 0x00000020

.equ HEX0to3, 0xFF200020                // Addres of 7-Segment display 0 to 3
.equ HEX4to5, 0xFF200030                // Addres of 7-Segment display 4 to 5
HEX_clear_ASM:
	PUSH {V1-V4, LR}                    // Preserve values in V1-V4 and LR           
    
    MOV V3, #0                          // V3 <- 0 ; Used to reset 7-segment 
    LDR V4, =HEX0to3                    // V4 <- address of HEX0to3 
    
    LDR V1, =HEX0                       // V1 <- 0x00000001 
    AND V2, A1, V1                      // V2 <- A1 (Index of displays to reset) AND V1 (HEX0) 
    CMP V2, V1                          // Compare V2 ( A1 and HEX0 ) with HEX0 (check if remains active after and)
    STREQB V3, [V4]                     // Store (reset display) V3 (#0) at addre V4 (0xFF200020) 
	
	ADD V4, V4, #1                      // V4 (Address display 2) <- V4 (Address display 1)  + 1 

    LDR V1, =HEX1
    AND V2, A1, V1
    CMP V2, V1
    STREQB V3, [V4] 
	
	ADD V4, V4, #1

    LDR V1, =HEX2
    AND V2, A1, V1
    CMP V2, V1
    STREQB V3, [V4] 
	
	ADD V4, V4, #1

    LDR V1, =HEX3
    AND V2, A1, V1
    CMP V2, V1
    STREQB V3, [V4] 
	
	LDR V4, =HEX4to5

	LDR V1, =HEX4
    AND V2, A1, V1
    CMP V2, V1
    STREQB V3, [V4] 
	
	ADD V4, V4, #1

    LDR V1, =HEX5
    AND V2, A1, V1
    CMP V2, V1
    STREQB V3, [V4]
	
	POP {V1-V4, LR}                     // Restore values in V1-V4 and LR 
    BX LR                               // Return from the function

HEX_flood_ASM:

	PUSH {V1-V4, LR}  

    MOV V3, #0xff
    LDR V4, =HEX0to3

    LDR V1, =HEX0
    AND V2, A1, V1
    CMP V2, V1
    STREQB V3, [V4] 
	
	ADD V4, V4, #1

    LDR V1, =HEX1
    AND V2, A1, V1
    CMP V2, V1
    STREQB V3, [V4] 
	
	ADD V4, V4, #1

    LDR V1, =HEX2
    AND V2, A1, V1
    CMP V2, V1
    STREQB V3, [V4] 
	
	ADD V4, V4, #1

    LDR V1, =HEX3
    AND V2, A1, V1
    CMP V2, V1
    STREQB V3, [V4] 
	
	LDR V4, =HEX4to5

	LDR V1, =HEX4
    AND V2, A1, V1
    CMP V2, V1
    STREQB V3, [V4] 
	
	ADD V4, V4, #1

    LDR V1, =HEX5
    AND V2, A1, V1
    CMP V2, V1
    STREQB V3, [V4]
	
	POP {V1-V4, LR}
    BX LR                           // Return from the function

HEX_write_ASM:

	PUSH {V1-V4, LR}  
    LDR V4, =HEX0to3

    LDR V1, =HEX0
    AND V2, A1, V1
    CMP V2, V1
    STREQB A2, [V4] 
	
	ADD V4, V4, #1

    LDR V1, =HEX1
    AND V2, A1, V1
    CMP V2, V1
    STREQB A2, [V4] 
	
	ADD V4, V4, #1

    LDR V1, =HEX2
    AND V2, A1, V1
    CMP V2, V1
    STREQB A2, [V4] 
	
	ADD V4, V4, #1

    LDR V1, =HEX3
    AND V2, A1, V1
    CMP V2, V1
    STREQB A2, [V4] 
	
	LDR V4, =HEX4to5

	LDR V1, =HEX4
    AND V2, A1, V1
    CMP V2, V1
    STREQB A2, [V4] 
	
	ADD V4, V4, #1

    LDR V1, =HEX5
    AND V2, A1, V1
    CMP V2, V1
    STREQB A2, [V4]
	
	POP {V1-V4, LR}
    BX LR                               // Return from the function

// Value of push buttons
PB0 = 0x00000001
PB1 = 0x00000002
PB2 = 0x00000004
PB3 = 0x00000008

.equ PB_ADDR, 0xFF200050                // Address of Push Button
read_PB_data_ASM:
    LDR A2, =PB_ADDR                    // Load the address of slider switch state
    LDR A1, [A2]                        // Read slider switch state 
    BX  LR                              // Return 

// TODO: Check if we need multiple buttons can be pressed
PB_data_is_pressed:

    PUSH {V1-V4, LR}                    // Preserve values in V1-V4 and LR
	PUSH {A2}                           // Preserve Button to check
    BL read_PB_data_ASM                 // Checks which button is pussed in PB
	V2 = A1;                            // V2 <- A1 (Values o)
	POP {A2}                            // Restore Button to check

    CMP A2, #0                          // Compare A2 ( Push Button Index ) with 0 
    BEQ pb0_Pressed                     // Branch if equal to pb0_Pressed

    CMP A2, #1                          // Compare A2 ( Push Button Index ) with 1 
    BEQ pb1_Pressed                     // Branch if equal to pb1_Pressed

    CMP A2, #2                          // Compare A2 ( Push Button Index) with 2 
    BEQ pb2_Pressed                     // Branch if equal to pb2_Pressed

    CMP A2, #3                          // Compare A2 ( Push Button Index) with 3 
    BEQ pb3_Pressed                     // Branch if equal to pb3_Pressed

    pb0_Pressed: 
        LDR V1, =PB0                    // V1 <- 0x00000001
		CMP A1, V1                      // Compare A1 (button pushed) and 0x00000004
        BEQ PB_data_is_pressed_done     // Branch Return if button pushed #0x00000001
        B PB_data_is_pressed_done2      // Branch Return #0x00000000, otherwise

    pb1_Pressed: 
        LDR V1, =PB1                    // V1 <- 0x00000002
		CMP A1, V1                      // Compare A1 (button pushed) and 0x00000004
        BEQ PB_data_is_pressed_done     // Branch Return if button pushed #0x00000001
        B PB_data_is_pressed_done2      // Branch Return #0x00000000, otherwise

    pb2_Pressed: 
        LDR V1, =PB2                    // V1 <- 0x00000004
		CMP A1, V1                      // Compare A1 (button pushed) and 0x00000004
        BEQ PB_data_is_pressed_done     // Branch Return if button pushed #0x00000001
        B PB_data_is_pressed_done2      // Branch Return #0x00000000, otherwise

    pb3_Pressed:
        LDR V1, =PB3                    // V1 <- 0x00000008
		CMP A1, V1                      // Compare A1 (button pushed) and 0x00000004
        BEQ PB_data_is_pressed_done     // Branch Return if button pushed #0x00000001
        B PB_data_is_pressed_done2      // Branch Return #0x00000000, otherwise
    
    PB_data_is_pressed_done:
        MOV A1, #0x00000001             // Return into A1 #0x00000001
        POP {V1-V4, LR}                 // Restore V1-V4 and LR
        BX LR                           // Return

    PB_data_is_pressed_done2:
        MOV A1, #0x00000000             // Return into A1 #0x00000000 
        POP {V1-V4, LR}                 // Restore V1-V4 and LR
        BX LR                           // Return

// Returns index of push buttons that have been pressed
// No Inputs
read_PB_edgecp_ASM: 
    PUSH {V1-V4, LR}                    // Preserve values in V1-V4 and LR
    LDR V1, =PB_ADDR                    // V1 <- 0xFF200050
    LDRB A1, [V1, #0xC]                 // A1 <- read edge capture	register 
    POP {V1-V4, LR}                    	// Restore values in V1-V4 and LR
	BX LR                               // Return

// Returns #0x00000001 if PB has be pressed and released
// Inputs: A1 <- Push button index
PB_edgecp_is_pressed_ASM:

    PUSH {V1-V4, LR}                    // Preserve values in V1-V4 and LR
    LDR V1, =PB_ADDR                    // V1 <- 0xFF200050
    
    PUSH {A1}                           // Preseve index to verify on stack
    BL read_PB_edgecp_ASM               // A1 <- Index of Push buttons that have pressed a released
    MOV A2, A1                          // A2 <- A1 (Store in A2 the index of Push buttons that have pressed a released)
    POP {A1}                            // Restore index to verify on stack

    LDR V1, =PB0                        // V1 <- 0x00000001 
    AND V2, A1, A2                      // V2 <- A1 (Index of push buttons to chekc) AND V1 (HEX0) 
    CMP V2, V1                          // Compare V2 ( A1 and PB0 ) with PB0 (check if remains active after and)
    BEQ PB_pressed_released_done        // If Equal, return #0x00000001

    LDR V1, =PB1                        // V1 <- 0x00000002 
    AND V2, A1, A2                      // V2 <- A1 (Index of push buttons to chekc) AND V1 (HEX0) 
    CMP V2, V1                          // Compare V2 ( A1 and PB0 ) with PB0 (check if remains active after and)
    BEQ PB_pressed_released_done        // If Equal, return #0x00000001
    
    LDR V1, =PB2                        // V1 <- 0x00000004
    AND V2, A1, A2                      // V2 <- A1 (Index of push buttons to chekc) AND V1 (HEX0) 
    CMP V2, V1                          // Compare V2 ( A1 and PB0 ) with PB0 (check if remains active after and)
    BEQ PB_pressed_released_done        // If Equal, return #0x00000001

    LDR V1, =PB3                        // V1 <- 0x00000008 
    AND V2, A1, A2                      // V2 <- A1 (Index of push buttons to chekc) AND V1 (HEX0) 
    CMP V2, V1                          // Compare V2 ( A1 and PB0 ) with PB0 (check if remains active after and)
    BEQ PB_pressed_released_done        // If Equal, return #0x00000001

    // If none are equal, return A1 <- #0x00000000
    MOV A1, #0x00000000             // A1 <- #0x00000001
    POP {V1-V4, LR}                 // Restore values in V1-V4 and LR
    BX LR                           // Return

    // Returns #0x00000001 into A1 when PB is pressed
    PB_pressed_released_done: 
        MOV A1, #0x00000001             // A1 <- #0x00000001
        POP {V1-V4, LR}                 // Restore values in V1-V4 and LR
        BX LR                           // Return

// Takes no input, Clear the edgecapture register
PB_clear_edgecp_ASM:
    PUSH {V1-V4, LR}                    // Preserve values in V1-V4 and LR
    LDR V1, =PB_ADDR                    // V1 <- 0xFF200050
    LDRB A1, [V1, #0xC]                 // A1 <- read edge capture register
    STR A1, [V1, #0xC]                  // Clear the edge capture register
    POP {V1-V4, LR}                    	// Restore values in V1-V4 and LR
	BX LR                               // Return

// Inputs: Push button index (PB0 -> A1 = 0; PB1 -> A1 = 1; ..., PB3 -> A1 = 3)
// It enables the interrupt function for the corresponding pushbuttons by 
// setting the interrupt mask bits to '1'.
// No Return
enable_PB_INT_ASM:

    PUSH {V1-V4, LR}                    // Preserve values in V1-V4 and LR
    LDR V1, =PB_ADDR                    // V1 <- 0xFF200050
    // LDRB A2, [V1, #0x8]              // A2 <- read interrup mask register
    ADD V1, V1, #0x8                    // Update Address to that of Mask Register
    MOV A2, #1
    STRB A2, [V1, A1]                    // Clear the edge capture register
    
    POP {V1-V4, LR}
    BX LR

// Inputs: Push button index (PB0 -> A1 = 0; PB1 -> A1 = 1; ..., PB3 -> A1 = 3)
// It disable the interrupt function for the corresponding pushbuttons by 
// setting the interrupt mask bits to '0'.
// No Return
disable_PB_INT_ASM:

    PUSH {V1-V4, LR}                    // Preserve values in V1-V4 and LR
    LDR V1, =PB_ADDR                    // V1 <- 0xFF200050
    // LDRB A2, [V1, #0x8]              // A2 <- read interrup mask register
    ADD V1, V1, #0x8                    // Update Address to that of Mask Register
    MOV A2, #0
    STRB A2, [V1, A1]                    // Clear the edge capture register
    
    POP {V1-V4, LR}
    BX LR



_start: 
    MOV A1 , #0                         // Initialize A1 with 0
	
infinite_loop:
    //BL read_slider_switches_ASM         // Branch to function to read state of slider switches and return it in A1

	
	//BL write_LEDs_ASM                   // Else write content of A1 to LEDs
	
	//BL HEX_clear_ASM
    //BL HEX_flood_ASM
	//MOV A2 , #4
	//BL HEX_write_ASM
	//BL read_PB_data_ASM
    MOV A1, #2
    // BL PB_data_is_pressed
    //BL read_PB_edgecp_ASM
	// BL PB_edgecp_is_pressed_ASM
    //BL PB_clear_edgecp_ASM
    BL enable_PB_INT_ASM:
	
	
	
    B infinite_loop                     // Infinite Loop