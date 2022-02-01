;-------------------------------------------------------------------------;
.include "color_glow.inc"
.include "snes.inc"
;-------------------------------------------------------------------------;
; Sine Dot Intro Source
;
; The following source code was written on an Amiga 4000/040 computer using
; CygnusEd (text editor), SASM (snes assembler), IFF2SNES (gfx converter).
; This is a horrible piece of code and shows very sloppy work.
; The only equates used are by the un-packer (which was hand written and
; is a simple sequence unpacker, the packer itself was written in 68000 by
; me using ASM-One). 
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
.bss
;/////////////////////////////////////////////////////////////////////////;


;-------------------------------------------------------------------------;
bytes_to_xfer:
	.res 2
cgadd:
	.res 1
palette_address:
	.res 2
palette_bank:
	.res 1
offsetsprcol:
	.res 2
storageoffcol:
	.res 2
timersprcol:
	.res 2
;-------------------------------------------------------------------------;


;=========================================================================;
;      Code (c) 1993-94 -Pan-/ANTHROX   All code can be used at will!
;=========================================================================;
                     

;/////////////////////////////////////////////////////////////////////////;
.code
;/////////////////////////////////////////////////////////////////////////;


	.a8
	.i16


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
; A = palette bank
; B = CGRAM address
; X = palette address
; Y = bytes to transfer
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
SetupColorGlow:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	rep	#10h			; X,Y fixed -> 16 bit mode
	sep	#20h			; Accumulator ->  8 bit mode

	sta	palette_bank
	stx	palette_address
	sty	bytes_to_xfer
	xba
	sta	cgadd

	ldx	#0000h
	stx	offsetsprcol
	stx	storageoffcol
	stx	timersprcol
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
;                       Start of sprite color glow
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
ColorGlow:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	stz	REG_DMAP3		; 0= 1 byte per register (not a word!)
	lda	#<REG_CGDATA
	sta	REG_BBAD3		; 21xx   this is 2118 (VRAM)

	rep	#30h

	lda	palette_address
	clc
	adc	storageoffcol		; add offset to read color pos.
	tax

	sep	#20h

	stx	REG_A1T3L
	lda	palette_bank
	sta	REG_A1B3		; bank address of data in ram
	ldx	bytes_to_xfer
	stx	REG_DAS3L		; # of bytes to be transferred
	lda	cgadd
	sta	REG_CGADD		; address of VRAM to copy garphics in
	lda	#%1000			; turn on bit 4 of G-DMA channel
	sta	REG_MDMAEN

	lda	timersprcol
	dec a
	and	#0eh
	sta	timersprcol
	bne	EndColor	

	rep	#30h

	lda	offsetsprcol
	inc a
	and	#000fh
	sta	offsetsprcol
	asl a
	asl a
	asl a
	asl a
	asl a
	sta	storageoffcol

	sep	#20h	
;-------------------------------------------------------------------------;
EndColor:
;-------------------------------------------------------------------------;
	rts
