.define Mlu2

! This subroutine multiplies two unsigned fourbyte intergers.
! For more details see mli.s


Mlu2:
	stx ARTH
	sta ARTH+1	! multiplier
	jsr Pop
	stx ARTH+2
	sta ARTH+3	! multiplicand
	ldy #0
	sty UNSIGN
	jmp Mul


