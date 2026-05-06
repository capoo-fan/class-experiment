	.file	"gemv_int8.c"
	.option nopic
	.attribute arch, "rv32i2p1_m2p0_a2p1_f2p2_d2p2_c2p0_zicsr2p0_zifencei2p0_zmmul1p0_zaamo1p0_zalrsc1p0_zca1p0_zcd1p0_zcf1p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.globl	Result_C
	.bss
	.align	2
	.type	Result_C, @object
	.size	Result_C, 16
Result_C:
	.zero	16
	.globl	Matrix_A
	.data
	.align	2
	.type	Matrix_A, @object
	.size	Matrix_A, 32
Matrix_A:
	.base64	"AQIDBAUGBwgCAwQFBgcICQMEBQYHCAkKBAUGBwgJCgs="
	.globl	Vector_B
	.section	.sdata,"aw"
	.align	2
	.type	Vector_B, @object
	.size	Vector_B, 8
Vector_B:
	.base64	"AQEBAQEBAQE="
	.text
	.align	1
	.globl	matmul_int8
	.type	matmul_int8, @function
matmul_int8:
	addi	sp,sp,-64
	sw	ra,60(sp)
	sw	s0,56(sp)
	addi	s0,sp,64
	sw	a0,-36(s0)
	sw	a1,-40(s0)
	sw	a2,-44(s0)
	sw	a3,-48(s0)
	sw	a4,-52(s0)
	sw	zero,-20(s0)
	j	.L2
.L5:
	sw	zero,-24(s0)
	sw	zero,-28(s0)
	j	.L3
.L4:
	lw	a4,-20(s0)
	lw	a5,-52(s0)
	mul	a4,a4,a5
	lw	a5,-28(s0)
	add	a5,a4,a5
	mv	a4,a5
	lw	a5,-40(s0)
	add	a5,a5,a4
	lb	a5,0(a5)
	mv	a3,a5
	lw	a5,-28(s0)
	lw	a4,-44(s0)
	add	a5,a4,a5
	lb	a5,0(a5)
	mul	a5,a3,a5
	lw	a4,-24(s0)
	add	a5,a4,a5
	sw	a5,-24(s0)
	lw	a5,-28(s0)
	addi	a5,a5,1
	sw	a5,-28(s0)
.L3:
	lw	a4,-28(s0)
	lw	a5,-52(s0)
	blt	a4,a5,.L4
	lw	a5,-20(s0)
	slli	a5,a5,2
	lw	a4,-36(s0)
	add	a5,a4,a5
	lw	a4,-24(s0)
	sw	a4,0(a5)
	lw	a5,-20(s0)
	addi	a5,a5,1
	sw	a5,-20(s0)
.L2:
	lw	a4,-20(s0)
	lw	a5,-48(s0)
	blt	a4,a5,.L5
	nop
	nop
	lw	ra,60(sp)
	lw	s0,56(sp)
	addi	sp,sp,64
	jr	ra
	.size	matmul_int8, .-matmul_int8
	.section	.rodata
	.align	2
.LC0:
	.string	"%d "
	.text
	.align	1
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	addi	s0,sp,32
	li	a4,8
	li	a3,4
	lui	a5,%hi(Vector_B)
	addi	a2,a5,%lo(Vector_B)
	lui	a5,%hi(Matrix_A)
	addi	a1,a5,%lo(Matrix_A)
	lui	a5,%hi(Result_C)
	addi	a0,a5,%lo(Result_C)
	call	matmul_int8
	sw	zero,-20(s0)
	j	.L7
.L8:
	lui	a5,%hi(Result_C)
	addi	a4,a5,%lo(Result_C)
	lw	a5,-20(s0)
	slli	a5,a5,2
	add	a5,a4,a5
	lw	a5,0(a5)
	mv	a1,a5
	lui	a5,%hi(.LC0)
	addi	a0,a5,%lo(.LC0)
	call	printf
	lw	a5,-20(s0)
	addi	a5,a5,1
	sw	a5,-20(s0)
.L7:
	lw	a4,-20(s0)
	li	a5,3
	ble	a4,a5,.L8
	li	a0,10
	call	putchar
	li	a5,0
	mv	a0,a5
	lw	ra,28(sp)
	lw	s0,24(sp)
	addi	sp,sp,32
	jr	ra
	.size	main, .-main
	.ident	"GCC: (g5115c7e44) 15.2.0"
	.section	.note.GNU-stack,"",@progbits
