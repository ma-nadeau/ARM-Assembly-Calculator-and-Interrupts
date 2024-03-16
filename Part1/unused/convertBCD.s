.global _start
_start:
    // Load the initial hexadecimal value into a register
    MOV R5, #164  // For example, convert 0xf to BCD
    MOV R10, #0   // Counter
	MOV R11,  #0
loop:
	
	CMP R5, #0
	BEQ	stop
   // Load the constant 0xccd into R3 for multiplication by 0xccd
    LDR R3, =0xccd  
    
    // Multiply the quotient (in R5) by 0xccd, store the result in R5
    MUL R4, R5, R3  
    
    // Shift right the result by 5 bits, effectively dividing by 100
    LSR R4, R4, #15
	MOV R6, #10
	MUL R7, R4, R6
	SUB R8, R5, R7
	MOV R5, R4
    
	LSL R9, R10, #3
	LSL R9, R8, R9
    LSR R9, R10, #3
	ORR R11, R11, R9
	ADD R10, R10, #1
	
	B loop
	

stop: 
	LDR R12, =0xff200020
	STR R11, [R12]
    B _start