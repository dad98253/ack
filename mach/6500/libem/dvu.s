.define Dvu2

! This subroutine performs a twobyte unsigned division
! For more details see dvi.s.


Dvu2:
	stx ARTH
	sta ARTH+1
	jsr Pop
	stx ARTH+2
	sta ARTH+3
	ldy #0
	sty UNSIGN
	jmp Dvu


