.data
	array: .word   0xA, 0x123, 0xFF
    str:   .string "Hello World!\n"

.macro push %a
	addi	sp, sp, -4
	sw 		%a, 0(sp) 
.end_macro

.macro pop %a
	lw 		%a, 0(sp) 
	addi	sp, sp, 4
.end_macro

.text
MAIN:
	lui		s0, 0x10010
	
	lw 		a0, 0(s0)
	jal		ra, FUNC
	jal     FUNC
	
	ori     a7, zero, 10
	ecall

FUNC:
	push	s0
	push    s1
	# ......
	pop     s1
	pop 	s0
	jalr 	zero, ra, 0		# jalr zero, 0(ra) OR ret OR jr ra
