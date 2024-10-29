.global _start


LOAD_register_addr = 0xFFFEC600
COUNTER_register_addr = 0xFFFEC604
CONTROL_register_addr = 0xFFFEC608
INTERUPT_register_addr = 0xFFFEC60C

currentResult: .word 0

     

.equ HEX0to3, 0xFF200020                // Addres of 7-Segment display 0 to 3
.equ HEX4to5, 0xFF200030                // Addres of 7-Segment display 4 to 5

Display:  .word 0x3F, 0x06, 0x5B, 0x4F,0x66, 0x6D, 0x7D, 0x07,0x7F, 0x67, 0x77, 0x7C,0x39, 0x5E, 0x79, 0x71


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


// A1 <- Initial Count Value
// A2 <- Configuration Bit 
ARM_TIM_config_ASM:
    PUSH {V1-V3, LR}
    
    LDR V1, =LOAD_register_addr             // v1 <- 0xFFFEC600 (addres of Load Register)
    LDR V2, =CONTROL_register_addr          // v2 <- 0xFFFEC608 (addr of )

    STR A1, [V1]                            // store at address v1 (Load Register) the initial count
    
	LDR V3, [V2]                            // V3 <- content of the control register
    ORR V3, V3, A2                          // set bit E in control register using second argument
    STR V3, [V2]                            // write to CONTROL register the change in the bit E
    
    POP {V1-V3, LR}
    BX LR

// No inputs
// Returns the value of the CONTORL register
ARM_TIM_read_INT_ASM:
    PUSH {V1, LR}

    LDR V1, =INTERUPT_register_addr         // Loads address of v1 (Interupt register)  
    LDR A1, [V1]                            // Loads the F value into the A1 register

    POP {V1, LR}
    BX LR

ARM_TIM_clear_INT_ASM:
    PUSH {V1-V2, LR}
    
    LDR V2, =0x00000001                     // Values to clear interrupt status registe
    LDR V1, =INTERUPT_register_addr         // Loads address of v1 (Interupt register)  
    STR V2, [V1]                            // F bit cleared to 0 by writing a 0x00000001 to the interrupt status register

    POP {V1-V2, LR}
    BX LR
HEX_write_ASM:
	PUSH {V5, LR} 
	LDR V5, =HEX0to3
	BL convert_decimal_to_display			// Convert A1 to 7-segment display value
	STRB A1, [V5]                         	// Stores A1 (Results converted to 7-Segment Display) in V5 (Address of HEX0to3)
	POP {V5, LR}
	BX LR

_start:
    LDR A1, =0x50000000                     // A1 <- value to be stored in load counter
    LDR A2, =0x07                       	// A2 <- Value to be stored in CONTROL register
	BL ARM_TIM_config_ASM					// Config CONTROL register
	
	PUSH {A1}								// Preserve A1
    MOV A1, #0								// Move Counter to A1
    BL HEX_write_ASM						// Write first value to HEX0
	POP {A1}								// Restore A1
    	
    MOV V1, #0                              // Counter
loop:
	PUSH {A1}								// Preserve A1
	BL ARM_TIM_read_INT_ASM					// Branch read interupt
    CMP A1, #1								// Compare F with 1
	ADDEQ V1, V1, #1						// If F == 1, add 1 to counter
	BNE skip 								// If F != 1, skip clear F
		BL ARM_TIM_clear_INT_ASM			// Clear F
	
	skip: 
	
	POP {A1}								// Restore A1
	
    PUSH {A1}								// Preserve A1
    MOV A1, V1								// Move Counter to A1
	BL HEX_write_ASM						// Branch to write to HEX1
    POP {A1}								// Restore A1
	
	CMP V1, #15								// Compare counter with 15
	BEQ _start								// if we reach 15, infinite loop
	B loop									// loop
	



