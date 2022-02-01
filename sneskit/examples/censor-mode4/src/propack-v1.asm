;-------------------------------------------------------------------------;
.include "propack.inc"
.include "snes.inc"
.include "snes_zvars.inc"
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
BUFFER2 = 000300h	; 24-bit address of $1A0 byte buffer
RAWTAB	= 020h		; indexed from BUFFER2
POSTAB	= 0a0h		; indexed from BUFFER2
SLNTAB	= 120h		; indexed from BUFFER2
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
.zeropage
;/////////////////////////////////////////////////////////////////////////;


propack_in:
	.res 3
wrkbuf:
	.res 3
counts:
	.res 2
blocks:
	.res 2
bitbufl:
	.res 2
bitbufh:
	.res 2
bufbits:
	.res 2
bitlen:
	.res 2
hufcde:
	.res 2
hufbse:
	.res 2
temp1:
	.res 2
temp2:
	.res 2
temp3:
	.res 2
temp4:
	.res 2
propack_out:
	.res 2


;/////////////////////////////////////////////////////////////////////////;
.code
;/////////////////////////////////////////////////////////////////////////;


;=========================================================================;
;                         Start Of Unpack Routine
;=========================================================================;


;-------------------------------------------------------------------------;
; PRO-PACK Unpack Source Code - Super NES, Method 1
;
; Copyright (c) 1992 Rob Northen Computing
;
; File: RNC_1.S
;
; Date: 9.03.92
;-------------------------------------------------------------------------;
;-------------------------------------------------------------------------;
; Unpack Routine - Super NES, Method 1
;
; To unpack a packed file (in any data bank) to an output
; buffer (in any data bank) Note: the packed and unpacked
; files are limited to 65536 bytes in length.
;
; To call (assumes 8-bit accumulator)
;
;	use macro:
;	DoDecompressPP source, destination
;
; On exit,
;
; A, X, Y undefined, M=0, X=0
;-------------------------------------------------------------------------;


	.a8
	.i16


;=========================================================================;
Unpack:
;=========================================================================;
	rep	#10h
	sep	#20h

	sty	propack_out
	stx	propack_in
	sta	propack_in+2

	phb			; Push current data bank register

	xba			; Get the destination RAM bank
	pha			; Push dest RAM bank to stack
	plb			; Set data bank to dest RAM bank

	rep	#39h		; 16-bit AXY, clear D and C

	lda	#BUFFER2
	sta	wrkbuf
	lda	#^BUFFER2
	sta	wrkbuf+2

	lda	#17
	adc	propack_in
	sta	propack_in
	lda	[propack_in]
	and	#00ffh
	sta	blocks
	inc	propack_in
	lda	[propack_in]
	sta	bitbufl
	stz	bufbits
	lda	#2
	jsr	gtbits
;-------------------------------------------------------------------------;
unpack2:
;-------------------------------------------------------------------------;
	ldy	#RAWTAB
	jsr	makehuff
	ldy	#POSTAB
	jsr	makehuff
	ldy	#SLNTAB
	jsr	makehuff
	lda	#16
	jsr	gtbits
	sta	counts
	bra	unpack8
;-------------------------------------------------------------------------;
unpack3:
;-------------------------------------------------------------------------;
	ldy	#POSTAB
	jsr	gtval
	sta	temp2
	lda	propack_out
	clc
	sbc	temp2
	sta	temp3
	ldy	#SLNTAB
	jsr	gtval
	inc	a
	inc	a
	lsr	a
	tax
	ldy	#0
	lda	temp2
	bne	unpack5
	sep	#20h		; 8-bit accumulator
	lda	(temp3),y
	xba
	lda	(temp3),y
	rep	#20h		; 16-bit accumulator
;-------------------------------------------------------------------------;
unpack4:
;-------------------------------------------------------------------------;
	sta	(propack_out),y
	iny
	iny
	dex
	bne	unpack4
	bra	unpack6
;-------------------------------------------------------------------------;
unpack5:
;-------------------------------------------------------------------------;
	lda	(temp3),y
	sta	(propack_out),y
	iny
	iny
	dex
	bne	unpack5
;-------------------------------------------------------------------------;
unpack6:
;-------------------------------------------------------------------------;
	bcc	unpack7
	sep	#20h		; 8-bit accumulator
	lda	(temp3),y
	sta	(propack_out),y
	iny
	rep	#21h		; 16-bit accumulator, clear carry
;-------------------------------------------------------------------------;
unpack7:
;-------------------------------------------------------------------------;
	tya
	adc	propack_out
	sta	propack_out
;-------------------------------------------------------------------------;
unpack8:
;-------------------------------------------------------------------------;
	ldy	#RAWTAB
	jsr	gtval
	tax
	beq	unpack14
	ldy	#0
	lsr	a
	beq	unpack10
	tax
;-------------------------------------------------------------------------;
unpack9:
;-------------------------------------------------------------------------;
	lda	[propack_in],y
	sta	(propack_out),y
	iny
	iny
	dex
	bne	unpack9
;-------------------------------------------------------------------------;
unpack10:
;-------------------------------------------------------------------------;
	bcc	unpack11
	sep	#20h		; 8-bit accumulator
	lda	[propack_in],y
	sta	(propack_out),y
	rep	#21h		; 16-bit accumulator, clear carry
	iny
;-------------------------------------------------------------------------;
unpack11:
;-------------------------------------------------------------------------;
	tya
	adc	propack_in
	sta	propack_in
	tya
	adc	propack_out
	sta	propack_out
	stz	bitbufh
	lda	bufbits
	tay
	asl	a
	tax
	lda	[propack_in]
	cpy	#0
	beq	unpack13
;-------------------------------------------------------------------------;
unpack12:
;-------------------------------------------------------------------------;
	asl	a
	rol	bitbufh
	dey
	bne	unpack12
;-------------------------------------------------------------------------;
unpack13:
;-------------------------------------------------------------------------;
	sta	temp1
	lda	f:MASK_TABLE,x
	and	bitbufl
	ora	temp1
	sta	bitbufl
;-------------------------------------------------------------------------;
unpack14:
;-------------------------------------------------------------------------;
	dec	counts
	beq	mark1
	jmp	unpack3
;-------------------------------------------------------------------------;
mark1:	dec	blocks
	beq	mark2
;-------------------------------------------------------------------------;
	jmp	unpack2
;-------------------------------------------------------------------------;
mark2:	jmp	Return
;=========================================================================;
gtval:	
;=========================================================================;
	ldx	bitbufl
	bra	gtval3
;-------------------------------------------------------------------------;
gtval2:	iny
	iny
;-------------------------------------------------------------------------;
gtval3:	txa
	and	[wrkbuf],y
	iny
	iny
	cmp	[wrkbuf],y
	bne	gtval2
	tya
	adc	#(15*4+1)
	tay
	lda	[wrkbuf],y
	pha
	xba
	and	#0ffh
	jsr	gtbits
	pla
	and	#0ffh
	cmp	#2
	bcc	gtval4
	dec	a
	asl	a
	pha
	lsr	a
	jsr	gtbits
	plx
	ora	f:BIT_TABLE,x
;-------------------------------------------------------------------------;
gtval4:	rts
;=========================================================================;
gtbits:
;=========================================================================;
	tay
	asl	a
	tax
	lda	f:MASK_TABLE,x
	and	bitbufl
	pha
	lda	bitbufh
	ldx	bufbits
	beq	gtbits3
;-------------------------------------------------------------------------;
gtbits2:
;-------------------------------------------------------------------------;
	lsr	a
	ror	bitbufl
	dey
	beq	gtbits4
	dex
	beq	gtbits3
	lsr	a
	ror	bitbufl
	dey
	beq	gtbits4
	dex
	bne	gtbits2
;-------------------------------------------------------------------------;
gtbits3:
;-------------------------------------------------------------------------;
	inc	propack_in
	inc	propack_in
	lda	[propack_in]
	ldx	#16
	bra	gtbits2
;-------------------------------------------------------------------------;
gtbits4:
;-------------------------------------------------------------------------;
	dex
	stx	bufbits
	sta	bitbufh
	pla
;-------------------------------------------------------------------------;
gtbits5:
;-------------------------------------------------------------------------;
	rts
;=========================================================================;
makehuff:
;=========================================================================;
	sty	temp4
	lda	#5
	jsr	gtbits
	beq	gtbits5
	sta	temp1
	sta	temp2
	ldy	#0
;-------------------------------------------------------------------------;
makehuff2:
;-------------------------------------------------------------------------;
	phy
	lda	#4
	jsr	gtbits
	ply
	sta	[wrkbuf],y
	iny
	iny
	dec	temp2
	bne	makehuff2
	stz	hufcde
	lda	#8000h
	sta	hufbse
	lda	#1
	sta	bitlen
;-------------------------------------------------------------------------;
makehuff3:
;-------------------------------------------------------------------------;
	lda	bitlen
	ldx	temp1
	ldy	#0
;-------------------------------------------------------------------------;
makehuff4:
;-------------------------------------------------------------------------;
	cmp	[wrkbuf],y
	bne	makehuff8
	phx
	sty	temp3
	asl	a
	tax
	lda	f:MASK_TABLE,x
	ldy	temp4
	sta	[wrkbuf],y
	iny
	iny
	lda	#16
	sec
	sbc	bitlen
	pha
	lda	hufcde
	sta	temp2
	ldx	bitlen
;-------------------------------------------------------------------------;
makehuff5:
;-------------------------------------------------------------------------;
	asl	temp2
	ror	a
	dex
	bne	makehuff5
	plx
	beq	makehuff7
;-------------------------------------------------------------------------;
makehuff6:
;-------------------------------------------------------------------------;
	lsr	a
	dex
	bne	makehuff6
;-------------------------------------------------------------------------;
makehuff7:
;-------------------------------------------------------------------------;
	sta	[wrkbuf],y
	iny
	iny
	sty	temp4
	tya
	clc
	adc	#(15*4)
	tay
	lda	bitlen
	xba
	sep	#20h		; 8-bit accumulator
	lda	temp3
	lsr	a
	rep	#21h		; 16-bit accumulator, clear carry
	sta	[wrkbuf],y
	lda	hufbse
	adc	hufcde
	sta	hufcde
	lda	bitlen
	ldy	temp3
	plx
;-------------------------------------------------------------------------;
makehuff8:
;-------------------------------------------------------------------------;
	iny
	iny
	dex
	bne	makehuff4
	lsr	hufbse
	inc	bitlen
	cmp	#16
	bne	makehuff3
	rts


;=========================================================================;
Return:
;=========================================================================;
	rep	#10h
	sep	#20h

	plb			; restore data bank

	rtl


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
BIT_TABLE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.word	$0001,$0002,$0004,$0008,$0010,$0020,$0040,$0080
	.word	$0100,$0200,$0400,$0800,$1000,$2000,$4000,$8000
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
MASK_TABLE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.word	$0000,$0001,$0003,$0007,$000f,$001f,$003f,$007f
	.word	$00ff,$01ff,$03ff,$07ff,$0fff,$1fff,$3fff,$7fff
	.word	$ffff
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
