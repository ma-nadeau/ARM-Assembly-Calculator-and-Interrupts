

.section .vectors, "ax"
B _start            // reset vector
B SERVICE_UND       // undefined instruction vector
B SERVICE_SVC       // software interrupt vector
B SERVICE_ABT_INST  // aborted prefetch vector
B SERVICE_ABT_DATA  // aborted data vector
.word 0             // unused vector
B SERVICE_IRQ       // IRQ interrupt vector
B SERVICE_FIQ       // FIQ interrupt vector



.text
.global _start

// ------------------------------ Constants ------------------------------------ \\

currentSpeed: .word 0x1                 // This is the value of the current speed, ranges from 1 to 5
previousSpeed: .word 0x0                // This is the value of the previous speed, used/activated when pause is called

//  50 000 000 -> 0.25s
// 100 000 000 -> 0.5 s
// 150 000 000 -> 0.75s
// 200 000 000 -> 1.00s
// 250 000 000 -> 1.25s
currentFrequency: .word 50000000        // This is the value of the current frequency (i.e. Load Register) -> by defautl set to 0.25s (50 000 000)
previousFrequency: .word 0

countingDown: .word 0x1                // Couting down is used check if we are currently using the timer, set set to one by default

currentCount: .word 1                   // 1 to 10

order: .word 1                          // 1 - normal | 0 - reverse

// ------------------------------------ Addresses --------------------------------- \\ 

.equ LED_ADDR, 0xFF200000               // Address of the LEDs' state

LOAD_register_addr = 0xFFFEC600
COUNTER_register_addr = 0xFFFEC604
CONTROL_register_addr = 0xFFFEC608
INTERUPT_register_addr = 0xFFFEC60C

.equ HEX0to3, 0xFF200020                // Addres of 7-Segment display 0 to 3
.equ HEX4to5, 0xFF200030                // Addres of 7-Segment display 4 to 5

.equ PB_ADDR, 0xFF200050                // Address of Push Button



// -------------------------------------  Flags ----------------------------------- \\
PB_int_flag: .word 0x0

tim_int_flag: .word 0x0

// ------------------------------ List of Numbers ---------------------------------- \\

List1: .word 0x77, 0x39, 0x79, 0x71, 0x3D, 0x76, 0x1E, 0x73, 0x3E, 0x6E                 // List of Letters [A,C,E,F,G,H,J,P,U,Y]
List2:  .word 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07,0x7F, 0x67                 // List of numbers [0,1,2,3,4,5,6,7,8,9]

// One Spave for each of the 10 values 
value1: .space 4    // A or 0
value2: .space 4    // C or 1
value3: .space 4    // E or 2
value4: .space 4    // F or 3
value5: .space 4    // G or 4
value6: .space 4    // H or 5
value7: .space 4    // J or 6
value8: .space 4    // P or 7
value9: .space 4    // U or 8
value10: .space 4   // Y or 9


// Inputs: Push button index (PB0 -> A1 = 0; PB1 -> A1 = 1; ..., PB3 -> A1 = 3)
// It enables the interrupt function for the corresponding pushbuttons by 
// setting the interrupt mask bits to '1'.
// No Return
enable_PB_INT_ASM:

    PUSH {V1-V4, LR}                    // Preserve values in V1-V4 and LR
    LDR V1, =PB_ADDR                    // V1 <- 0xFF200050
    // LDRB A2, [V1, #0x8]              // A2 <- read interrup mask register
    ADD V1, V1, #0x8                    // Update Address to that of Mask Register
   	LDR V2, =0xF                        
    STR V2, [V1]                       	// Clear the edge capture register
    
    POP {V1-V4, LR}
    BX LR



_start:
    
    /* Set up stack pointers for IRQ and SVC processor modes */
    MOV R1, #0b11010010                     // interrupts masked, MODE = IRQ
    MSR CPSR_c, R1                          // change to IRQ mode
    LDR SP, =0xFFFFFFFF - 3                 // set IRQ stack to A9 on-chip memory
    
    /* Change to SVC (supervisor) mode with interrupts disabled */
    MOV R1, #0b11010011                     // interrupts masked, MODE = SVC
    MSR CPSR, R1                            // change to supervisor mode
    LDR SP, =0x3FFFFFFF - 3                 // set SVC stack to top of DDR3 memory
    BL  CONFIG_GIC                          // configure the ARM GIC
    
    // NOTE: write to the pushbutton KEY interrupt mask register
    // Or, you can call enable_PB_INT_ASM subroutine from previous task
    // to enable interrupt for ARM A9 private timer, 
    // use ARM_TIM_config_ASM subroutine

    BL enable_PB_INT_ASM                    // Active interupt for pushbuttons

    BL TIMER_SETUP                   // Active interupt for ARM A9 private timer
    
    // enable IRQ interrupts in the processor
    MOV R0, #0b01010011                     // IRQ unmasked, MODE = SVC
    MSR CPSR_c, R0


IDLE:
    PUSH {V1-V2, LR}
	BL getValues
	BL setupLED
   	BL display_to_HEX
    POP {V1-V2, LR}
    B IDLE // This is where you write your main program task(s)




CONFIG_GIC:
    PUSH {LR}
    /*  To configure the FPGA KEYS interrupt (ID 73):
    *   1. set the target to cpu0 in the ICDIPTRn register
    *   2. enable the interrupt in the ICDISERn register */
    /*  CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
    /*  NOTE: you can configure different interrupts by passing their IDs to R0 and repeating the next 3 lines */
    MOV R0, #73            // KEY port (Interrupt ID = 73)
    MOV R1, #1             // this field is a bit-mask; bit 0 targets cpu0
    BL CONFIG_INTERRUPT


    MOV R0, #29            // KEY port (Interrupt ID = 73)
    MOV R1, #1             // this field is a bit-mask; bit 0 targets cpu0
    BL CONFIG_INTERRUPT


/* configure the GIC CPU Interface */
    LDR R0, =0xFFFEC100    // base address of CPU Interface
/* Set Interrupt Priority Mask Register (ICCPMR) */
    LDR R1, =0xFFFF        // enable interrupts of all priorities levels
    STR R1, [R0, #0x04]
/* Set the enable bit in the CPU Interface Control Register (ICCICR).
* This allows interrupts to be forwarded to the CPU(s) */
    MOV R1, #1
    STR R1, [R0]
/* Set the enable bit in the Distributor Control Register (ICDDCR).
* This enables forwarding of interrupts to the CPU Interface(s) */
    LDR R0, =0xFFFED000
    STR R1, [R0]
    POP {PC}



/*
* Configure registers in the GIC for an individual Interrupt ID
* We configure only the Interrupt Set Enable Registers (ICDISERn) and
* Interrupt Processor Target Registers (ICDIPTRn). The default (reset)
* values are used for other registers in the GIC
* Arguments: R0 = Interrupt ID, N
* R1 = CPU target
*/
CONFIG_INTERRUPT:
    PUSH {R4-R5, LR}
    /* Configure Interrupt Set-Enable Registers (ICDISERn).
    * reg_offset = (integer_div(N / 32) * 4
    * value = 1 << (N mod 32) */
    LSR R4, R0, #3    // calculate reg_offset
    BIC R4, R4, #3    // R4 = reg_offset
    LDR R2, =0xFFFED100
    ADD R4, R2, R4    // R4 = address of ICDISER
    AND R2, R0, #0x1F // N mod 32
    MOV R5, #1        // enable
    LSL R2, R5, R2    // R2 = value
    /* Using the register address in R4 and the value in R2 set the
    * correct bit in the GIC register */
    LDR R3, [R4]      // read current register value
    ORR R3, R3, R2    // set the enable bit
    STR R3, [R4]      // store the new register value
    /* Configure Interrupt Processor Targets Register (ICDIPTRn)
    * reg_offset = integer_div(N / 4) * 4
    * index = N mod 4 */
    BIC R4, R0, #3    // R4 = reg_offset
    LDR R2, =0xFFFED800
    ADD R4, R2, R4    // R4 = word address of ICDIPTR
    AND R2, R0, #0x3  // N mod 4
    ADD R4, R2, R4    // R4 = byte address in ICDIPTR
    /* Using register address in R4 and the value in R2 write to
    * (only) the appropriate byte */
    STRB R1, [R4]
    POP {R4-R5, PC}



/*--- Undefined instructions --------------------------------------*/
SERVICE_UND:
    B SERVICE_UND
/*--- Software interrupts ----------------------------------------*/
SERVICE_SVC:
    B SERVICE_SVC
/*--- Aborted data reads ------------------------------------------*/
SERVICE_ABT_DATA:
    B SERVICE_ABT_DATA
/*--- Aborted instruction fetch -----------------------------------*/
SERVICE_ABT_INST:
    B SERVICE_ABT_INST
/*--- IRQ ---------------------------------------------------------*/
SERVICE_IRQ:
    PUSH {R0-R7, LR}
/* Read the ICCIAR from the CPU Interface */
    LDR R4, =0xFFFEC100
    LDR R5, [R4, #0x0C] // read from ICCIAR

    /* NOTE: Check which interrupt has occurred (check interrupt IDs)
       Then call the corresponding ISR
       If the ID is not recognized, branch to UNEXPECTED
       See the assembly example provided in the DE1-SoC Computer Manual
       on page 46 */
private_timer_check:
    CMP R5, #29                     // Check for private timer niterupt
    BNE Pushbutton_check            

    BL ARM_TIM_ISR                  // private timer interupt
    B EXIT_IRQ

Pushbutton_check:
    CMP R5, #73
UNEXPECTED:
    BNE UNEXPECTED      // if not recognized, stop here
    BL KEY_ISR

EXIT_IRQ:
/* Write to the End of Interrupt Register (ICCEOIR) */
    STR R5, [R4, #0x10] // write to ICCEOIR
    POP {R0-R7, LR}
    SUBS PC, LR, #4
/*--- FIQ ---------------------------------------------------------*/
SERVICE_FIQ:
    B SERVICE_FIQ




KEY_ISR:
    PUSH {V1-V5, LR}
    LDR R0, =0xFF200050    // base address of pushbutton KEY port
    LDR R1, [R0, #0xC]     // read edge capture register
    LDR V1, =PB_int_flag   // address of flag
    STR R1, [V1]           // Store content of push button edge capture to PB_int_flag
    MOV R2, #0xF
    STR R2, [R0, #0xC]     // clear the interrupt


CHECK_KEY0:
    MOV R3, #0x1
    ANDS R3, R3, R1        // check for KEY0
    BEQ CHECK_KEY1
 
    BL decrease_Speed       // when KEY0 is pressed, decrease the speed by 1 (augment load value count)
    

    B END_KEY_ISR
CHECK_KEY1:
    MOV R3, #0x2
    ANDS R3, R3, R1        // check for KEY1
    BEQ CHECK_KEY2
    
    BL increase_Speed      // when KEY1 is pressed, increase the speed by 1  (decrease load valye count)

    B END_KEY_ISR
CHECK_KEY2:
    MOV R3, #0x4
    ANDS R3, R3, R1        // check for KEY2
    BEQ IS_KEY3
    
    LDR V1, order          
    LDR V2, =order
    MOV V3, #0           
    MOV V4, #1
    // toggles between order 1 or order 0
    CMP V1, #1             
    STRNE V4, [V2]         // if order is not set to 1 (default), set it to 1
    STREQ V3, [V2]         // otherwise, set it to 0

    
    B END_KEY_ISR
IS_KEY3:
	MOV R3, #0x8
    ANDS R3, R3, R1        // check for KEY3
    BEQ END_KEY_ISR
	BL Pause                // Pauses when key 3 is pressed
	
END_KEY_ISR:
	
    POP {V1-V5, LR}
    BX LR

// -------------------------------------  Setup Timer ---------------------------------------- \\ 
ARM_TIM_ISR:
    PUSH {V1-V8,LR}

    LDR V1,  =tim_int_flag          // V1 <- Address of Flag
    MOV V2, #1                      // V2 <- Imm 1
    STR V2, [V1]                    // Write '1'  to tim_int_flag

    BL ARM_TIM_clear_INT_ASM        // clear interupt

    BL reverse_order_display        // reverse the order of the display when the order changes

    POP {V1-V8,LR}
    BX LR

// Clears the interupt of the timer
ARM_TIM_clear_INT_ASM:
    PUSH {V1-V2, LR}
    
    LDR V2, =0x00000001                     // Values to clear interrupt status registe
    LDR V1, =INTERUPT_register_addr         // Loads address of v1 (Interupt register)  
    STR V2, [V1]                            // F bit cleared to 0 by writing a 0x00000001 to the interrupt status register

    POP {V1-V2, LR}
    BX LR

// Takes no input, Clear the edgecapture register
PB_clear_edgecp_ASM:
    PUSH {V1-V2, LR}                    // Preserve values in V1-V4 and LR
    LDR V1, =PB_ADDR                    // V1 <- 0xFF200050
    LDRB V2, [V1, #0xC]                 // V2 <- read edge capture register
    STR V2, [V1, #0xC]                  // Clear the edge capture register
    POP {V1-V2, LR}                    	// Restore values in V1-V4 and LR
	BX LR                               // Return

// Setup up the interupt and frequency of timer
TIMER_SETUP:
    PUSH {V1-V7, LR}
    
    LDR V1, =LOAD_register_addr             // v1 <- 0xFFFEC600 (addres of Load Register)
    LDR V2, =CONTROL_register_addr          // v2 <- 0xFFFEC608 (addr of )
    LDR V3, =INTERUPT_register_addr         // Loads address of v1 (Interupt register) 

    LDR V4, =0x01                           // Values to clear interrupt status register
    STR V4, [V3]                            // clear interupt register

    LDR V4, currentFrequency                // V4 <- Current Frequency
    STR V4, [V1]                            // store at address v1 (Load Register) the initial count

    LDR V5, [V2]                            // V5 <- content of the control register 
    LDR V4, =0x07                       	// V4 <- Value to be stored in CONTROL register
    ORR V4, V5, V4                          // set bit E in control register using second argument
    STR V4, [V2]                            // store at address v1 (Load Register) the initial count
    
    POP {V1-V7, LR}
    BX LR

// ------------------------------------- Used to reverse the direction of the display ---------------------------- \\
reverse_order_display:

    PUSH {V1-V8,LR}
    LDR V1, order                           
    LDR V2, =order
    LDR V3, currentCount
    LDR V4, =currentCount
    MOV V5, #1
    MOV V6, #10

    CMP V1, #1                              // if the order == 1 => Order = 0 (now we substract), otherwise we add
    BNE reversing

    CMP V3, #10                             // Max value
    STREQ V5, [V4]                          // if max value is reached, set it back to 1
    ADDNE V3, V3, V5                        // Otherwise, currentCount +1    
    STRNE V3, [V4]                          // Store it back
    B end_reverse_order
    
    reversing: 
    CMP V3, #1                              // Min Value
    STREQ V6, [V4]                          // if min value is reach, set it back to 10
    SUBNE V3, V3, V5                        // otherwise, currentCount - 1
    STRNE V3, [V4]                          // Store it back

    end_reverse_order:
        POP {V1-V8,LR} 
        BX LR



// ---------------------------- Set LEDS according to the current speed ------------------------------------- \\
write_LEDs_ASM:
    PUSH {A1-A2, LR}
    LDR A2, =LED_ADDR                   // load the address of the LEDs' state
    STR A1, [A2]                        // update LED state with the contents of A1
    POP {A1-A2, LR}
    BX LR

setupLED:
    PUSH {V1-V5, LR}

	LDR V1, currentSpeed
	CMP V1, #0
	
    BNE speed1
	MOVEQ A1, V1
    BL write_LEDs_ASM
	CMP V1, #0
	B  endSetupLED
    speed1:
        CMP V1, #1
        BNE speed2
        LDR A1, =0x3FF
        BL write_LEDs_ASM
        B endSetupLED
        
    speed2:
        CMP V1, #2
        BNE speed3

        LDR A1, =0xFF
        BL write_LEDs_ASM
        B endSetupLED
        
    speed3:
        CMP V1, #3
        BNE speed4

        LDR A1, =0x3F
        BL write_LEDs_ASM
        B endSetupLED
        
    speed4:
        CMP V1, #4
        BNE speed5 
        LDR A1, =0xF
        BL write_LEDs_ASM
        B endSetupLED

    speed5:
		CMP V1, #5
		BNE endSetupLED
        LDR A1, =0x3
        BL write_LEDs_ASM


    endSetupLED:
        POP {V1-V5, LR}
        BX LR
        


// ----------------------------    Set Speeds and Pauses   --------------------------- \\ 
decrease_Speed: 
    PUSH {V1-V6, LR} 
    LDR V1, currentSpeed
    LDR V2, =currentSpeed
    LDR V3, currentFrequency
    LDR V4, =currentFrequency
	LDR V5, =50000000
	CMP V1, #5              // compare current speed with max
    ADDLT V1, V1, #1        // Otherwise add 1
    STRLT V1, [V2]          // Store current speed 
    ADDLT V3, V3, V5
    STRLT V3, [V4]              // store current speed
	BL TIMER_SETUP
    POP {V1-V6, LR} 
    BX LR 
increase_Speed:  
    PUSH {V1-V6, LR} 
    LDR V1, currentSpeed
    LDR V2, =currentSpeed 
    LDR V3, currentFrequency
    LDR V4, =currentFrequency
	LDR V5, =50000000
	CMP V1, #1                  // compare speed with 1 
    SUBGT V1, V1, #1            // if current speed greater than 1, sub 1
    STRGT V1, [V2]              // store current speed
    SUBGT V3, V3, V5
    STRGT V3, [V4]              // store current speed
	BL TIMER_SETUP
    POP {V1-V6, LR} 
    BX LR 

// This subroutine set the current speed to 0 (or restore it using the past speed) and halts the timer but call setEbitTimer
Pause: 
	PUSH {V1-V7, LR}
	LDR V1, currentSpeed
    LDR V2, =currentSpeed
    LDR V3, previousSpeed
    LDR V4, =previousSpeed

    MOV V5, #0

    LDR V6, =countingDown
	LDR V7, countingDown
    
    CMP V1, #0                          // Compare speed with 0
    STRNE V1, [V4]                      // if current speed not equal to 0, store it in memory

    CMP V7, #1                          // compare counting down with 1
	STREQ V5, [V2]                      // if counting down set to 0, ->  currentSpeed = 0 in memory
    STREQ V5, [V6]                      // counting to 0 in memory
    LDRNE V3, previousSpeed             // update value of previous Speed in registers
    STRNE V3, [V2]                      // otherwise, previousSpeed restored to currentSpeed in memory
	ADDNE V5,V5, #1                     // V5 <- 1
    STRNE V5, [V6]                      // counting to 1 in memory
	
	BL setEbitTimer

    POP {V1-V7, LR}
    BX LR

// Used in Pause to halt the timer (i.e. set the E bit to 0) or restart the timer (i.e. set the E bit to 1)
setEbitTimer:
	
	PUSH {V1-V7}
	
	LDR V1, =CONTROL_register_addr
	LDR V2, [V1]
	MOV V4, #1
	MOV V6, #4					// Used when Halting
	MOV V7, #7                  // Used when restarting
	AND V3, V2, V4				// Get E bit
	CMP V3, #1 					// Check if E bit is set to 1
	STREQB V6, [V1]             // If set to 1, halt
	STRNEB V7, [V1]             // If set to 0, restart
	
	POP {V1-V7}
	BX LR

// -----------------------------       Get Value to be displayed --------------------------------- \\

// Slider Switches Driver
// returns the state of slider switches in A1
// post- A1: slide switch state
.equ SW_ADDR, 0xFF200040
read_slider_switches_ASM:
    LDR A2, =SW_ADDR                    // load the address of slider switch state
    LDR A1, [A2]                        // read slider switch state 
    BX  LR


// Checks between each switches and when it is on, selects from the second list (Letters List), when it is off (default to integers)
getValues:
    PUSH {V1-V8, LR}				    // Preserve values of V1-V2 and LR 

    LDR V1, =SW_ADDR                    // load the address of slider switch state
    LDR V2, [V1]                        // read slider switch state
    LDR V5, =List1
    LDR V6, =List2
    
	LDR V8, =value1
    
    // 0 or A
    AND V3, V2, #1                  // Extract the lower 1 bits and store them in V3
    CMP V3, #1                      // if equal then it is on
    LDREQ V4, [V5]
    STREQ V4, [V8]                  // If EQ, Store 0 in value1
    LDRNE V4, [V6]
    STRNE V4, [V8]                  // If NE, Store A in value1

    LDR V8, =value2

    // 1 or C
    AND V3, V2, #2                  // Extract the second bit and store them in V3
	CMP V3, #2                      // if equal then it is on
	LDREQ V4, [V5, #4]              // If EQ, Store 1 in value2
    STREQ V4, [V8]
    LDRNE V4, [V6, #4]              // If NE, Store C in value2
    STRNE V4, [V8]

    LDR V8, =value3

    // 2 or E
    AND V3, V2, #4                   // Extract the lower 3 bits and store them in V3
	CMP V3, #4 
	LDREQ V4, [V5, #8]
    STREQ V4, [V8]
    LDRNE V4, [V6, #8]
    STRNE V4, [V8]

    LDR V8, =value4

    // 3 or F
    AND V3, V2, #8                  // Extract the 4 bit and store them in V3
	CMP V3, #8 
	LDREQ V4, [V5, #12]
    STREQ V4, [V8]
    LDRNE V4, [V6, #12]
    STRNE V4, [V8]

    LDR V8, =value5

    // 4 or G
    AND V3, V2, #16                  // Extract the 5 bit and store them in V3
	CMP V3, #16 
	LDREQ V4, [V5, #16]
    STREQ V4, [V8]
    LDRNE V4, [V6, #16]
    STRNE V4, [V8]

    LDR V8, =value6

    // 5 or H
    AND V3, V2, #32                   // Extract the 6 bit and store them in V3
	CMP V3, #32 
	LDREQ V4, [V5, #20]
    STREQ V4, [V8]
    LDRNE V4, [V6, #20]
    STRNE V4, [V8]

    LDR V8, =value7

    // 6 or J 
    AND V3, V2, #64                   // Extract the  7 bit and store them in V3
	CMP V3, #64 
	LDREQ V4, [V5, #24]
    STREQ V4, [V8]
    LDRNE V4, [V6, #24]
    STRNE V4, [V8]

    LDR V8, =value8

    // 7 or P
    AND V3, V2, #128                   // Extract the 8 bit and store them in V3
	CMP V3, #128 
	LDREQ V4, [V5, #28]
    STREQ V4, [V8]
    LDRNE V4, [V6, #28]
    STRNE V4, [V8]                  
    
    LDR V8, =value9

    // 8 or U
    AND V3, V2, #256                   // Extract the 9 bit and store them in V3
	CMP V3, #256 
	LDREQ V4, [V5, #32]
    STREQ V4, [V8]
    LDRNE V4, [V6, #32]
    STRNE V4, [V8]

    LDR V8, =value10

    // 9 or Y
    AND V3, V2, #512                   // Extract the 10 bit and store them in V3
	CMP V3, #512 
	LDREQ V4, [V5, #36]
    STREQ V4, [V8]
    LDRNE V4, [V6, #36]
    STRNE V4, [V8]

    POP {V1-V8, LR}                     // Restaure values of V1-V2 and LR 
    BX LR                               // Return 



//  -------------------------------------     6 individual subroutine to display at each 7-Segment --------------------------------------- \\ 

// These subroutines check the current count. The count will vary between 1 and 10 and will select the appropriate value to be displayed at their respective HEX
display_to_first_hex:
    PUSH {V1-V8, LR}
    LDR V1, currentCount
    LDR V2, =currentCount

    CMP V1, #1 
    LDREQ V3, value10
    BEQ end_display_to_first_hex

    CMP V1, #2
    LDREQ V3, value9
    BEQ end_display_to_first_hex
    
    CMP V1, #3
    LDREQ V3, value8
    BEQ end_display_to_first_hex

    CMP V1, #4
    LDREQ V3, value7
    BEQ end_display_to_first_hex

    CMP V1, #5
    LDREQ V3, value6
    BEQ end_display_to_first_hex

    CMP V1, #6
    LDREQ V3, value5
    BEQ end_display_to_first_hex

    CMP V1, #7
    LDREQ V3, value4
    BEQ end_display_to_first_hex

    CMP V1, #8
    LDREQ V3, value3
    BEQ end_display_to_first_hex

    CMP V1, #9
    LDREQ V3, value2
    BEQ end_display_to_first_hex

    CMP V1, #10
    LDREQ V3, value1
    BEQ end_display_to_first_hex


    end_display_to_first_hex:
        LDR V4, =HEX0to3
        STRB V3, [V4]
        POP {V1-V8, LR}
        BX LR

display_to_second_hex:
    PUSH {V1-V8, LR}
    LDR V1, currentCount
    LDR V2, =currentCount

    CMP V1, #1 
    LDREQ V3, value9
    BEQ end_display_to_second_hex

    CMP V1, #2
    LDREQ V3, value8
    BEQ end_display_to_second_hex
    
    CMP V1, #3
    LDREQ V3, value7
    BEQ end_display_to_second_hex

    CMP V1, #4
    LDREQ V3, value6
    BEQ end_display_to_second_hex

    CMP V1, #5
    LDREQ V3, value5
    BEQ end_display_to_second_hex

    CMP V1, #6
    LDREQ V3, value4
    BEQ end_display_to_second_hex

    CMP V1, #7
    LDREQ V3, value3
    BEQ end_display_to_second_hex

    CMP V1, #8
    LDREQ V3, value2
    BEQ end_display_to_second_hex

    CMP V1, #9
    LDREQ V3, value1
    BEQ end_display_to_second_hex

    CMP V1, #10
    LDREQ V3, value10
    BEQ end_display_to_second_hex


    end_display_to_second_hex:
        LDR V4, =HEX0to3
        STRB V3, [V4, #1]
        POP {V1-V8, LR}
        BX LR

display_to_third_hex:
    PUSH {V1-V4, LR}
    LDR V1, currentCount
    LDR V2, =currentCount

    CMP V1, #1 
    LDREQ V3, value8
    BEQ end_display_to_third_hex

    CMP V1, #2
    LDREQ V3, value7
    BEQ end_display_to_third_hex
    
    CMP V1, #3
    LDREQ V3, value6
    BEQ end_display_to_third_hex

    CMP V1, #4
    LDREQ V3, value5
    BEQ end_display_to_third_hex

    CMP V1, #5
    LDREQ V3, value4
    BEQ end_display_to_third_hex

    CMP V1, #6
    LDREQ V3, value3
    BEQ end_display_to_third_hex

    CMP V1, #7
    LDREQ V3, value2
    BEQ end_display_to_third_hex

    CMP V1, #8
    LDREQ V3, value1
    BEQ end_display_to_third_hex

    CMP V1, #9
    LDREQ V3, value10
    BEQ end_display_to_third_hex

    CMP V1, #10
    LDREQ V3, value9
    BEQ end_display_to_third_hex


    end_display_to_third_hex:
        LDR V4, =HEX0to3
        STRB V3, [V4, #2]
        POP {V1-V4, LR}
        BX LR

display_to_fourth_hex:
    PUSH {V1-V4, LR}
    LDR V1, currentCount
    LDR V2, =currentCount

    CMP V1, #1 
    LDREQ V3, value7
    BEQ end_display_to_fourth_hex

    CMP V1, #2
    LDREQ V3, value6
    BEQ end_display_to_fourth_hex
    
    CMP V1, #3
    LDREQ V3, value5
    BEQ end_display_to_fourth_hex

    CMP V1, #4
    LDREQ V3, value4
    BEQ end_display_to_fourth_hex

    CMP V1, #5
    LDREQ V3, value3
    BEQ end_display_to_fourth_hex

    CMP V1, #6
    LDREQ V3, value2
    BEQ end_display_to_fourth_hex

    CMP V1, #7
    LDREQ V3, value1
    BEQ end_display_to_fourth_hex

    CMP V1, #8
    LDREQ V3, value10
    BEQ end_display_to_fourth_hex

    CMP V1, #9
    LDREQ V3, value9
    BEQ end_display_to_fourth_hex

    CMP V1, #10
    LDREQ V3, value8
    BEQ end_display_to_fourth_hex


    end_display_to_fourth_hex:
        LDR V4, =HEX0to3
        STRB V3, [V4, #3]
        POP {V1-V4, LR}
        BX LR

display_to_fifth_hex:
    PUSH {V1-V4, LR}
    LDR V1, currentCount
    LDR V2, =currentCount

    CMP V1, #1 
    LDREQ V3, value6
    BEQ end_display_to_fifth_hex

    CMP V1, #2
    LDREQ V3, value5
    BEQ end_display_to_fifth_hex
    
    CMP V1, #3
    LDREQ V3, value4
    BEQ end_display_to_fifth_hex

    CMP V1, #4
    LDREQ V3, value3
    BEQ end_display_to_fifth_hex

    CMP V1, #5
    LDREQ V3, value2
    BEQ end_display_to_fifth_hex

    CMP V1, #6
    LDREQ V3, value1
    BEQ end_display_to_fifth_hex

    CMP V1, #7
    LDREQ V3, value10
    BEQ end_display_to_fifth_hex

    CMP V1, #8
    LDREQ V3, value9
    BEQ end_display_to_fifth_hex

    CMP V1, #9
    LDREQ V3, value8
    BEQ end_display_to_fifth_hex

    CMP V1, #10
    LDREQ V3, value7
    BEQ end_display_to_fifth_hex


    end_display_to_fifth_hex:
        LDR V4, =HEX4to5
        STRB V3, [V4]
        POP {V1-V4, LR}
        BX LR

display_to_sixth_hex:
    PUSH {V1-V4, LR}
    LDR V1, currentCount
    LDR V2, =currentCount

    CMP V1, #1 
    LDREQ V3, value5
    BEQ end_display_to_sixth_hex

    CMP V1, #2
    LDREQ V3, value4
    BEQ end_display_to_sixth_hex
    
    CMP V1, #3
    LDREQ V3, value3
    BEQ end_display_to_sixth_hex

    CMP V1, #4
    LDREQ V3, value2
    BEQ end_display_to_sixth_hex

    CMP V1, #5
    LDREQ V3, value1
    BEQ end_display_to_sixth_hex

    CMP V1, #6
    LDREQ V3, value10
    BEQ end_display_to_sixth_hex

    CMP V1, #7
    LDREQ V3, value9
    BEQ end_display_to_sixth_hex

    CMP V1, #8
    LDREQ V3, value8
    BEQ end_display_to_sixth_hex

    CMP V1, #9
    LDREQ V3, value7
    BEQ end_display_to_sixth_hex

    CMP V1, #10
    LDREQ V3, value6
    BEQ end_display_to_sixth_hex


    end_display_to_sixth_hex:
        LDR V4, =HEX4to5
        STRB V3, [V4, #1]
        POP {V1-V4, LR}
        BX LR

// ---------------------------------------   Combines All Subroutnie Calls ----------------------------------- \\ 
display_to_HEX:
    PUSH {V1-V4, LR}

    // Ensures that no changes are made when timer is halted
    LDR V1, currentSpeed
    CMP V1, #0
    BEQ skip_display_to_HEX 

    BL display_to_first_hex
    BL display_to_second_hex
    BL display_to_third_hex
    BL display_to_fourth_hex
    BL display_to_fifth_hex
    BL display_to_sixth_hex
    
    skip_display_to_HEX:
        POP {V1-V4,LR}
        BX LR