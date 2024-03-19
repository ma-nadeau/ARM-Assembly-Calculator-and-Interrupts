

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


LOAD_register_addr = 0xFFFEC600
COUNTER_register_addr = 0xFFFEC604
CONTROL_register_addr = 0xFFFEC608
INTERUPT_register_addr = 0xFFFEC60C

currentResult: .word 0

     

.equ HEX0to3, 0xFF200020                // Addres of 7-Segment display 0 to 3
.equ HEX4to5, 0xFF200030                // Addres of 7-Segment display 4 to 5

Display:  .word 0x3F, 0x06, 0x5B, 0x4F,0x66, 0x6D, 0x7D, 0x07,0x7F, 0x67, 0x77, 0x7C,0x39, 0x5E, 0x79, 0x71


// Value of push buttons
PB0 = 0x00000001
PB1 = 0x00000002
PB2 = 0x00000004
PB3 = 0x00000008

.equ PB_ADDR, 0xFF200050                // Address of Push Button


PB_int_flag: 
    .word 0x0

tim_int_flag:
    .word   0x0

// Inputs: Push button index (PB0 -> A1 = 0; PB1 -> A1 = 1; ..., PB3 -> A1 = 3)
// It enables the interrupt function for the corresponding pushbuttons by 
// setting the interrupt mask bits to '1'.
// No Return
enable_PB_INT_ASM:

    PUSH {V1-V4, LR}                    // Preserve values in V1-V4 and LR
    LDR V1, =PB_ADDR                    // V1 <- 0xFF200050
    // LDRB A2, [V1, #0x8]              // A2 <- read interrup mask register
    ADD V1, V1, #0x8                    // Update Address to that of Mask Register
   	LDR V2, =0xF                         // TODO: 
    STR V2, [V1]                       	// Clear the edge capture register
    
    POP {V1-V4, LR}
    BX LR

//Active Interupt for Counter
ARM_TIM_config_ASM:
    PUSH {V1-V5, LR}
    
    LDR V2, =0x00000001                     // Values to clear interrupt status registe
    LDR V1, =INTERUPT_register_addr         // Loads address of v1 (Interupt register)  
    STR V2, [V1]

    POP {V1-V5, LR}
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

    BL ARM_TIM_config_ASM                   // Active interupt for ARM A9 private timer

    
    // enable IRQ interrupts in the processor
    MOV R0, #0b01010011                     // IRQ unmasked, MODE = SVC
    MSR CPSR_c, R0


IDLE:
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
    BNE Pushbutton_check            // 

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
    PUSH {V1, LR}
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
    //MOV R2, #0b00111111
    //STR R2, [R0]           // display "0"
    B END_KEY_ISR
CHECK_KEY1:
    MOV R3, #0x2
    ANDS R3, R3, R1        // check for KEY1
    BEQ CHECK_KEY2
    //MOV R2, #0b00000110
    //STR R2, [R0]           // display "1"
    B END_KEY_ISR
CHECK_KEY2:
    MOV R3, #0x4
    ANDS R3, R3, R1        // check for KEY2
    BEQ IS_KEY3
    //MOV R2, #0b01011011
    //STR R2, [R0]           // display "2"
    B END_KEY_ISR
IS_KEY3:
    MOV R2, #0b01001111
    STR R2, [R0]           // display "3"
END_KEY_ISR:
    POP {V1, LR}
    BX LR



ARM_TIM_ISR:
    PUSH {V1-V4}

    LDR V1,  =tim_int_flag          // V1 <- Address of Flag
    MOV V2, #1                      // V2 <- Imm 1
    STR V1, [V2]                    // Write '1'  to tim_int_flag

    BL ARM_TIM_clear_INT_ASM
    POP {V1-V4}
    BX LR

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
