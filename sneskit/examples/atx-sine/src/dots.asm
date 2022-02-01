;-------------------------------------------------------------------------;
.include "dots.inc"
.include "snes.inc"
.include "snes_zvars.inc"
;-------------------------------------------------------------------------;
; Sine Dot Intro Source
;
; The following source code was written on an Amiga 4000/040 computer using
; CygnusEd (text editor), SASM (snes assembler), IFF2SNES (gfx converter).
; This is a horrible piece of code and shows very sloppy work.

;-------------------------------------------------------------------------;
ROWS = 3
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
BG3GFX = 0c000h
BG3MAP = 0c800h
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
RAM_DOTS = 0200h
;-------------------------------------------------------------------------;
; zvar usage:
; m5
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
.bss
;/////////////////////////////////////////////////////////////////////////;


;-------------------------------------------------------------------------;
dots_to_draw:
	.res 2
dots_to_make:
	.res 2
gfx_ram_offset:
	.res 2
sine_offset:
	.res 2
xbit_offset:
	.res 2
xsine_offset:
	.res 2
xsine_storage:
	.res 2
ysine_offset:
	.res 2
ysine_storage:
	.res 2


sineoff:
	.res 2
sineinc:
	.res 1
xinc:
	.res 1
yinc:
	.res 1
xdis:
	.res 1
ydis:
	.res 1
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
SetupBG3Dots:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	rep     #10h		; X,Y fixed -> 16 bit mode
	sep     #20h		; Accumulator ->  8 bit mode

	ldx	#BG3MAP/2
	stx	REG_VMADDL

	ldx	#0000h		; as long as 0 is already loaded...
	txy
	stx	xsine_storage	; ...let's use it! x sine offset storage
	stx	ysine_storage	; y sine offset storage
	stx	dots_to_make	; number of dots to make storage
	stx	gfx_ram_offset	; graf-x ram location offset
	stx	xbit_offset	; X bit offset

:	stz	RAM_DOTS,x
	inx
	cpx	#0200h
	bne	:-

	lda	#40h
;-------------------------------------------------------------------------;
clearscreen:
;-------------------------------------------------------------------------;
	sta	REG_VMDATAL	; clear the text screen (with unused tile)
	stz	REG_VMDATAH	; palette 0
	iny
	cpy	#0400h
	bne	clearscreen
;-------------------------------------------------------------------------;
	ldx	#BG3MAP/2+40h
	stx	REG_VMADDL
;-------------------------------------------------------------------------;
	sep	#10h		; updated code saves 735 bytes by not
				; storing the entire screen data as bytes
	lda	#08h*ROWS	; (see dist/screen.asm)
	xba
	ldx	#08h
	ldy	#04h
;-------------------------------------------------------------------------;
:	lda	#00h		; starting value
	sta	m0
;-------------------------------------------------------------------------;
:	sta	REG_VMDATAL
	stz	REG_VMDATAH	; palette 0
	clc
	adc	#08h		; increase a by 8
	dex
	bne	:-
;-------------------------------------------------------------------------;
	lda	m0		; back to starting value
	ldx	#08h		; reset x counter
	dey
	bne	:-
;-------------------------------------------------------------------------;
	ldy	#04h		; reset y counter
	xba
	dea
	beq	:+		; we've reached the end
;-------------------------------------------------------------------------;
	xba
	inc	m0		; increase starting value
	lda	m0
	cmp	#08h
	bcc	:-
	bra	:--
;-------------------------------------------------------------------------;
:	rep	#10h
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
ResetBG3DotSine:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	ldx	#0080h
	stx	dots_to_draw	; # of dots to draw

	lda	#01h
	sta	sineinc		; sine increase value
	sta	xinc		; x increase
	sta	yinc		; y increase

	lda	#03h		; x distance
	sta	xdis
	ina
	sta	ydis		; y distance

	ldx	#0000h
	stx	sine_offset	; sine data location offset
	stx	xsine_offset	; X sine offset
	stx	ysine_offset	; Y sine offset

	rts


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
;                               Start of Dot Setup
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
BG3DotRoutine:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	rep	#10h		; x,y = 16 bit
	sep	#20h		; a = 8 bit
				; start of General DMA graphics copy routine!
	stz	REG_DMAP3	; 0= 1 byte per register (not a word!)
	lda	#<REG_VMDATA
	sta	REG_BBAD3
	ldx	#RAM_DOTS
	stx	REG_A1T3L
	stz	REG_A1B3	; bank address of data in ram
	ldx	#0200h
	stx	REG_DAS3L	; # of bytes to be transferred
	stz	REG_VMAIN	; increase V-Ram address after writing
				; to REG_VMDATAL
	ldx	#BG3GFX/2
	stx	REG_VMADDL	; address of VRAM to copy garphics in
	lda	#%1000		; turn on bit 4 of G-DMA channel
	sta	REG_MDMAEN
	lda	#80h		; increase V-Ram address after writing
	sta	REG_VMAIN	; to REG_VMDATAH

	rep	#30h	

	ldy	#0200h
	lda	#0000h
:	sta	RAM_DOTS,y
	dey
	dey
	bpl	:-

	lda	#SINE		; get address of SINE data location
	clc
	adc	sine_offset	; add an offset to it
	sta	m5

	sep	#20h

	lda	sine_offset
	clc
	adc	sineinc		; increase sine offset for SINE data location
	sta	sine_offset

	lda	xsine_offset
	clc
	adc	xinc		; increase Y position
	sta	xsine_offset

	lda	ysine_offset
	clc
	adc	yinc		; increase X position
	sta	ysine_offset

	ldy	xsine_offset
	sty	xsine_storage
	ldy	ysine_offset
	sty	ysine_storage

	ldx	dots_to_draw
	stx	dots_to_make	; number of dots to make
;-------------------------------;-----------------------------------------;
DotDraw:
;-------------------------------;-----------------------------------------;
	ldy	xsine_storage	; read REAL sine offset
	ldx	ysine_storage	; 
				; 
				; 
	lda	SINE,x		; get SINE for column offset (x position)
	lsr a			; 
	lsr a			;
	lsr a			; divide by 8 (to get column offset) [0-1f)
	sta	gfx_ram_offset
	stz	gfx_ram_offset+1

	rep	#30h

	lda	gfx_ram_offset
	asl a 			;
	asl a 			;
	asl a			; multiply by 64 to get offset to write data 
	asl a			; to graphics buffer
	asl a			; the grid is 32 columns*8 rows (8*8=64)
	asl a			;
	sta	gfx_ram_offset

	sep	#20h

	lda	(m5),y
	adc	gfx_ram_offset
	sta	gfx_ram_offset
	lda	SINE,x		; get column bit offset
	and	#07h
	sta	xbit_offset
	ldx	xbit_offset
	ldy	gfx_ram_offset
	lda	RAM_DOTS,y
	ora	OFFSET,x
	sta	RAM_DOTS,y

	lda	xsine_storage	; increase REAL sine offset to get movement
	adc	xdis
	sta	xsine_storage
				; 2 incs move the sine faster
	lda	ysine_storage
	adc	ydis
	sta	ysine_storage

	dec	dots_to_make
	bne	DotDraw

	rts


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
ResetSineData:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	lda	#0ffh
	sta	sineoff
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
SetSineData:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	inc	sineoff
	ldx	sineoff		; offset for sine positions

	lda	SINE_POS1,x
	sta	sineinc
	lda	SINE_POS2,x
	sta	xinc
	lda	SINE_POS3,x
	sta	yinc
	lda	SINE_POS4,x
	sta	xdis
	lda	SINE_POS5,x
	sta	ydis

	rts


;/////////////////////////////////////////////////////////////////////////;
.code
;/////////////////////////////////////////////////////////////////////////;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
OFFSET:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$80,$40,$20,$10,$08,$04,$02,$01
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SINE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
 .byte	032,032,033,034,035,035,036,037,038,038,039,040,041,041,042,043
 .byte	044,044,045,046,046,047,048,048,049,050,050,051,051,052,053,053
 .byte	054,054,055,055,056,056,057,057,058,058,059,059,059,060,060,060
 .byte	061,061,061,061,062,062,062,062,062,063,063,063,063,063,063,063
 .byte	063,063,063,063,063,063,063,063,062,062,062,062,062,061,061,061
 .byte	061,060,060,060,059,059,059,058,058,057,057,056,056,055,055,054
 .byte	054,053,053,052,051,051,050,050,049,048,048,047,046,046,045,044
 .byte	044,043,042,041,041,040,039,038,038,037,036,035,035,034,033,032
 .byte	032,031,030,029,028,028,027,026,025,025,024,023,022,022,021,020
 .byte	019,019,018,017,017,016,015,015,014,013,013,012,012,011,010,010
 .byte	009,009,008,008,007,007,006,006,005,005,004,004,004,003,003,003
 .byte	002,002,002,002,001,001,001,001,001,000,000,000,000,000,000,000
 .byte	000,000,000,000,000,000,000,000,001,001,001,001,001,002,002,002
 .byte	002,003,003,003,004,004,004,005,005,006,006,007,007,008,008,009
 .byte	009,010,010,011,012,012,013,013,014,015,015,016,017,017,018,019
 .byte	019,020,021,022,022,023,024,025,025,026,027,028,028,029,030,031
 .byte	032,032,033,034,035,035,036,037,038,038,039,040,041,041,042,043
 .byte	044,044,045,046,046,047,048,048,049,050,050,051,051,052,053,053
 .byte	054,054,055,055,056,056,057,057,058,058,059,059,059,060,060,060
 .byte	061,061,061,061,062,062,062,062,062,063,063,063,063,063,063,063
 .byte	063,063,063,063,063,063,063,063,062,062,062,062,062,061,061,061
 .byte	061,060,060,060,059,059,059,058,058,057,057,056,056,055,055,054
 .byte	054,053,053,052,051,051,050,050,049,048,048,047,046,046,045,044
 .byte	044,043,042,041,041,040,039,038,038,037,036,035,035,034,033,032
 .byte	032,031,030,029,028,028,027,026,025,025,024,023,022,022,021,020
 .byte	019,019,018,017,017,016,015,015,014,013,013,012,012,011,010,010
 .byte	009,009,008,008,007,007,006,006,005,005,004,004,004,003,003,003
 .byte	002,002,002,002,001,001,001,001,001,000,000,000,000,000,000,000
 .byte	000,000,000,000,000,000,000,000,001,001,001,001,001,002,002,002
 .byte	002,003,003,003,004,004,004,005,005,006,006,007,007,008,008,009
 .byte	009,010,010,011,012,012,013,013,014,015,015,016,017,017,018,019
 .byte	019,020,021,022,022,023,024,025,025,026,027,028,028,029,030,031
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SINE_POS1:	.byte	$03,$02,$01,$00,$fe,$ff,$01,$01,$01,$02
SINE_POS2:	.byte	$fe,$02,$04,$01,$01,$03,$01,$02,$01,$01
SINE_POS3:	.byte	$01,$02,$ff,$02,$03,$fe,$00,$fe,$fe,$01
SINE_POS4:	.byte	$fe,$02,$01,$fe,$02,$ff,$01,$01,$01,$05
SINE_POS5:	.byte	$05,$02,$01,$04,$01,$02,$02,$ff,$3f,$03
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;

