;--------------------------------------------------------------------------
.include "c64_font_to_mode7.inc"
.include "snes.inc"
.include "snes_zvars.inc"
;--------------------------------------------------------------------------


;--------------------------------------------------------------------------
	.zeropage
;--------------------------------------------------------------------------


font_conv:
	.res 2


;--------------------------------------------------------------------------
invert = m0
;--------------------------------------------------------------------------


	.a8
	.i16


;--------------------------------------------------------------------------
	.code
;--------------------------------------------------------------------------


C64ToMode7Convert:

	sta	memptr+2	; store font bank
	inx			; increase address by 1
	stx	memptr		; store font address
	xba			; get font invert value
	sta	invert
	sty	REG_VMADDL

	ldy	#0001h
	sty	font_conv
	dey

rltime:	lda	(memptr),y
	eor	invert
	sta	font_conv
	ldx	#0000h
minisub:
	lda	font_conv
	and	#80h
	bne	blank

	;lda	font_conv+1
	;and	#07h
	lda	#01h
	sta	REG_VMDATAH
	bra	next

blank:	stz	REG_VMDATAH
next:	clc
	cld
	lda	font_conv
	asl a
	sta	font_conv
	inc	font_conv+1
	inx
	cpx	#08h
	bne	minisub

	stz	font_conv+1
	inc	font_conv+1
	iny
	cpy	#640
	bne	rltime

	rts
