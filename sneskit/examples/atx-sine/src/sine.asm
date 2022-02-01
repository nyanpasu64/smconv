;-------------------------------------------------------------------------;
.include "color_glow.inc"
.include "dots.inc"
.include "hdma_colorbar.inc"
.include "snes.inc"
.include "snes_decompress.inc"
.include "snes_joypad.inc"
.include "snes_zvars.inc"
.include "graphics.inc"
;-------------------------------------------------------------------------;
.import SPRITE_COLOR_GLOW, init_reg
;-------------------------------------------------------------------------;
.export DoSine
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
BG1_MAP_LENGTH = 180h
DOT_PAL_DELAY = 4
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
BG1GFX = 04000h
BG1MAP = 0e000h
BG2MAP = 0d000h
BG3GFX = 0c000h
BG3MAP = 0c800h
CRDGFX = 02000h
CRDMAP = 0f000h
SPRGFX = 00000h
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
RAM_OAM = 000500h
TMP_RAM = 7e2000h
;-------------------------------------------------------------------------;
FADE_IN = %10000000
FADE_OUT = %01000000
;-------------------------------------------------------------------------;
gentimer	=	0402h
rcount		=	gentimer+2
storage3	=	rcount+2
logo1hoff	=	storage3+2
logo1voff	=	logo1hoff+2
logo2hoff	=	logo1voff+2
logo2voff	=	logo2hoff+2
scrollhpos	=	logo2voff+2
scrollpos	=	scrollhpos+2
spritehoff	=	scrollpos+2
scrollramoff	=	spritehoff+2
msbsprite	=	scrollramoff+2
offsetsprsine1	=	msbsprite+2
offsetsprsine2	=	offsetsprsine1+2
timerfade	=	offsetsprsine2+2
inidisp		=	timerfade+1
stopflag	=	inidisp+1
bg1hofs		=	stopflag+1
bg1vofs		=	bg1hofs+2
bg2hofs		=	bg1vofs+2
bg2vofs		=	bg2hofs+2
dot_pal_index	=	bg2vofs+2
dot_pal_delay	=	dot_pal_index+2

bgscrollflag	=	storage3
infotimer	=	storage3+1
;-------------------------------------------------------------------------;
; zvar usage:
; Colorbar:	memptr
; Dots:		m5
; CopyColor:	m6,m7
; MoveBg:	m6,m7
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
DoSine:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	rep     #10h		; X,Y fixed -> 16 bit mode
	sep     #20h		; Accumulator ->  8 bit mode

	lda	#BGMODE_1	; mode 0, 8/8 dot
	sta	REG_BGMODE	

	lda	#BG1MAP>>9|SC_64x32
	sta	REG_BG1SC
	lda	#BG2MAP>>9|SC_64x32
	sta	REG_BG2SC

	lda	#BG3MAP>>9
	sta	REG_BG3SC

	lda	#BG1GFX>>9+BG1GFX>>13
	sta	REG_BG12NBA	; BG1 and BG2 graphics data
	lda	#BG3GFX>>13
	sta	REG_BG34NBA	; BG3 graphics data

	lda	#TM_OBJ|TM_BG3|TM_BG2|TM_BG1
	sta	REG_TM
	and	#TM_OBJ|TM_BG2	; REG_TS is OBJ and BG2 only
	sta	REG_TS
	and	#TM_BG1
	sta	REG_TMW		; REG_TMW is OBJ, BG1, and BG2

	lda	#33h
	sta	REG_W12SEL
	stz	REG_WH0
	lda	#0ffh
	sta	REG_WH1
	lda	#03h
	sta	REG_MPYL
	dec a	; a = 02h
	sta	REG_CGSWSEL
	lda	#%01010011
	sta	REG_CGADSUB
	stz	REG_COLDATA

	jsr	SetupBG3Dots
				; a = 04h, x = 0000h, y = 0004h
	;ldx	#0000h		; x = 0 thanks to SetupBG3Dots
	tyx			; 
;-------------------------------------------------------------------------;
ClearSprRam:
;-------------------------------------------------------------------------;
	stz	RAM_OAM,x	; clear some ram for sprite data
	inx
	cpx	#0040h
	bne	ClearSprRam
;-------------------------------------------------------------------------;
	tyx
;-------------------------------------------------------------------------;
ClearSprText:
;-------------------------------------------------------------------------;
	lda	#20h
	sta	RAM_OAM+50h,x
	inx
	cpx	#0011h
	bne	ClearSprText
;-------------------------------------------------------------------------;
	; y is still 0000h

	jsr	SpriteSetup

	DoDecompressDataVram gfx_logoMap, BG1MAP

	ldx	#BG1MAP/2	; DoDecompressDataVram leaves REG_VMAIN set
	stx	REG_VMADDL	; to 0 which is useful since we want to skip
				; palette data when copying BG1 map to RAM
	ldx	#0000h
	txy

	lda	REG_VMDATALREAD	; Dummy read required!
:	lda	REG_VMDATALREAD	; copy BG1 map to RAM
	sta	TMP_RAM,x
	inx
	cpx	#BG1_MAP_LENGTH
	bne	:-

	lda	#VMAIN_INCH	; inc VMADD *after* write to VMDATAH
	sta	REG_VMAIN

	ldx	#BG2MAP/2
	stx	REG_VMADDL

	tyx

:	lda	TMP_RAM,x	; copy BG1 map from RAM
	sta	REG_VMDATAL
	lda	#PALETTE5	; set palette data
	sta	REG_VMDATAH
	inx
	cpx	#BG1_MAP_LENGTH
	bne	:-

	DoDecompressDataVram gfx_logoTiles, BG1GFX
	DoDecompressDataVram gfx_creditsMap, CRDMAP
	DoDecompressDataVram gfx_creditsTiles, CRDGFX
	DoDecompressDataVram gfx_16x16_simpleTiles, SPRGFX
	DoCopyPalette gfx_creditsPal, 16, 16	; -ma 1024 in grit file
	DoCopyPalette gfx_logoPal, 64, 16	; -ma 4096 in grit file
	DoCopyPalette gfx_logo_redPal, 80, 16

	lda	#DOT_PAL_DELAY
	sta	dot_pal_delay

	ldx	#0000h
	stx	offsetsprsine1	; offset for sprite sine
	stx	offsetsprsine2	; offset for sprite sine

	stx	bg1hofs
	stx	bg1vofs
	stx	bg2hofs
	stx	bg2vofs

	stx	msbsprite	; MSB for first sprite
	stx	scrollhpos	; scroll H pos
	stx	scrollpos	; scroll text position
	stx	scrollramoff	; scroll text ram offset
	stx	spritehoff	; sprite H pos offset counter

	inx	; x = 0001h
	stx	logo2hoff	; offset for logo2 H
	stx	logo2voff	; offset for logo2 V
	stx	logo1hoff	; offset for logo1 H
	stx	scrollhpos	; scroll H pos

	ldx	#0046h
	stx	logo1voff	; offset for logo1 V

	ldx	#0200h		; timer for sine values
	stx	gentimer	

	ldx	#000ah		; # of sine patterns
	stx	rcount		; generic timer for routine counters

	ldx	#0020h
	stx	storage3

	stz	inidisp
	stz	stopflag	; flag to stop intro

	jsr	ResetSineData
	jsr	SetupHDMAColorBar

	lda	#80h		; for timer fade, BG2VOFS, and cgaddress

	sta	timerfade
	sta	REG_BG2VOFS
	stz	REG_BG2VOFS

	xba
	lda	#^SPRITE_COLOR_GLOW
	ldx	#SPRITE_COLOR_GLOW
	ldy	#0020h		; bytes to transfer
	jsr	SetupColorGlow

	lda	#NMI_ON|NMI_JOYPAD
	sta	REG_NMITIMEN
;-------------------------------------------------------------------------;
Wait4:
;-------------------------------------------------------------------------;
	jsr	WaitVb

	lda	inidisp
	sta	REG_INIDISP
	and	#0fh
	eor	#0fh
	asl a
	asl a
	asl a
	asl a
	ora	#07h
	sta	REG_MOSAIC

	jsr	Joypad
	jsr	PaletteCycle
	jsr	ColorGlow	; Make sprite glow from blue<->gold
	jsr	Registers	; write to H/V scroll positions (move logo)
	jsr	SpriteScroll	; Copy Sprite Scroll
	jsr	BG3DotRoutine	; go do the dot routines
	jsr	MoveLogo1
	jsr	MoveLogo2
	jsr	MoveScroll
	jsr	HDMAColorBar
	jsr	Fade

	lda	stopflag
	beq	noendintro	; test flag to see if we should end intro
;-------------------------------------------------------------------------;
	jmp	EndTitle	; jump to end of intro!
;-------------------------------------------------------------------------;
noendintro:
;-------------------------------------------------------------------------;
	ldx	gentimer
	dex
	stx	gentimer
	bne	Wait4

	ldx	#0200h
	stx	gentimer

	jsr	SetSineData

	ldx	rcount
	dex			; decrease routine timer
	stx	rcount
	bne	Wait4

	ldx	#000ah
	stx	rcount

	jsr	ResetBG3DotSine
	jsr	ResetSineData

	bra	Wait4


;=========================================================================;
;                              Start Of Routines
;=========================================================================;

;=========================================================================;
Registers:
;=========================================================================;
	ldx	#bg1hofs
	ldy	#REG_BG1HOFS
	jsr	MoveBG

	ldx	#bg1vofs
	ldy	#REG_BG1VOFS
	jsr	MoveBG

	ldx	#bg2hofs
	ldy	#REG_BG2HOFS
	jsr	MoveBG

	ldx	#bg2vofs
	ldy	#REG_BG2VOFS
	jsr	MoveBG

	rts
;-------------------------------------------------------------------------;
MoveBG:
;-------------------------------------------------------------------------;
	stx	m6
	sty	m7

	rep	#30h

	lda	(m6)
	sec
	sbc	#80h

	sep	#20h

	sta	(m7)
	xba
	sta	(m7)

	rts


;=========================================================================;
MoveLogo1:
;=========================================================================;
	ldx	logo1hoff
	lda	HORIZ_SINE,x
	sta	bg1hofs

	ldx	logo1voff
	lda	VERT_SINE,x
	clc
	adc	#04h
	sta	bg1vofs

	inc	logo1hoff
	inc	logo1voff
	inc	logo1voff
	rts
;=========================================================================;
MoveLogo2:
;=========================================================================;
	ldx	logo2hoff
	lda	HORIZ_SINE,x
	sta	bg2hofs

	ldx	logo2voff
	lda	VERT_SINE,x
	clc
	adc	#04h
	sta	bg2vofs

	dec	logo2hoff
	dec	logo2voff
	dec	logo2voff
	rts


;=========================================================================;
;                               Joypad routine!
;=========================================================================;
Joypad:
;=========================================================================;
	lda	timerfade
	and	#FADE_OUT
	beq	JoyStuff
	rts
;-------------------------------------------------------------------------;
JoyStuff:
;-------------------------------------------------------------------------;
	lda	joy1_down+1
	ora	joy2_down+1
	cmp	#JOYPADH_START
	beq	EndIntro2
	rts
;-------------------------------------------------------------------------;
EndIntro2:
;-------------------------------------------------------------------------;
	lda	#FADE_OUT
	sta	timerfade
	rts
	

;=========================================================================;
;                           Fade routine
;=========================================================================;
Fade:
;=========================================================================;
	lda	timerfade
	and	#FADE_IN
	beq	TestFadeOut
;-------------------------------------------------------------------------;
FadeInWork:
;-------------------------------------------------------------------------;
	lda	timerfade
	inc a
	and	#07h
	ora	#FADE_IN
	sta	timerfade
	and	#07h
	bne	Exit
;-------------------------------------------------------------------------;
IncreaseFade:
;-------------------------------------------------------------------------;
	inc	inidisp
	lda	inidisp
	cmp	#10h
	bne	Exit
;-------------------------------------------------------------------------;
FadeMuch:
;-------------------------------------------------------------------------;
	dec	inidisp
	stz	timerfade
	rts
;-------------------------------------------------------------------------;
TestFadeOut:
;-------------------------------------------------------------------------;
	lda	timerfade
	and	#FADE_OUT
	beq	Exit
;-------------------------------------------------------------------------;
FadeOut:
;-------------------------------------------------------------------------;
	lda	timerfade
	and	#07h
	inc a
	and	#07h
	ora	#FADE_OUT
	sta	timerfade
	and	#07h
	bne	Exit
;-------------------------------------------------------------------------;
DecreaseFade:
;-------------------------------------------------------------------------;
	dec	inidisp
	lda	inidisp
	cmp	#0ffh
	bne	Exit
;-------------------------------------------------------------------------;
FadeLess:
;-------------------------------------------------------------------------;
	inc	inidisp
	stz	timerfade
	inc	stopflag
;-------------------------------------------------------------------------;
Exit:	rts

	
;=========================================================================;
;                       Credits part!
;=========================================================================;
EndTitle:
;=========================================================================;
	stz	REG_BG1HOFS
	stz	REG_BG1HOFS
	stz	REG_MOSAIC

	lda	#CRDMAP>>9|SC_32x64
	sta     REG_BG1SC 
	lda	#CRDGFX>>13
	sta     REG_BG12NBA

	lda	#TM_BG3|TM_BG1
	sta	REG_TM
	stz	REG_TS

	ldx	#0000h
	stx	bgscrollflag
	stx	infotimer

	stz	bg1vofs
	stz	REG_BG1VOFS
	lda	#01h
	sta	bg1vofs+1
	sta	REG_BG1VOFS

	lda	#FADE_IN
	sta	timerfade
	stz	inidisp
	stz 	stopflag

	lda	#%11
	sta	REG_HDMAEN
;-------------------------------------------------------------------------;
Wait6:
;-------------------------------------------------------------------------;
	jsr	WaitVb
	lda	inidisp
	sta	REG_INIDISP

	lda	bg1vofs
	sta	REG_BG1VOFS
	lda	bg1vofs+1
	sta	REG_BG1VOFS

	jsr	BG3DotRoutine
	jsr	HDMAColorBar
	jsr	ScrollUp
	jsr	Fade

	lda	bgscrollflag
	beq	Wait7
;-------------------------------------------------------------------------;
	lda	stopflag
	beq	Wait7
;-------------------------------------------------------------------------;
	lda	#80h			; we have reached the end
	sta	REG_INIDISP
	stz	REG_HDMAEN
	jmp	DoSine
;-------------------------------------------------------------------------;
Wait7:
;-------------------------------------------------------------------------;
	ldx	gentimer
	dex
	stx	gentimer
	bne	Wait6

	ldx	#0200h
	stx	gentimer

	jsr	SetSineData

	ldx	rcount
	dex				; decrease routine timer
	stx	rcount
	bne	Wait6

	ldx	#000ah
	stx	rcount

	jsr	ResetBG3DotSine
	jsr	ResetSineData
	bra	Wait6

;=========================================================================;
ScrollUp:
;=========================================================================;
	lda	bgscrollflag
	bne	StopAll

	rep	#30h

	lda	bg1vofs
	cmp	#01feh
	beq	NoScrollUp
;-------------------------------------------------------------------------;
	inc a
	inc a
	sta	bg1vofs
;-------------------------------------------------------------------------;
StopAll:
;-------------------------------------------------------------------------;
	sep	#20h
	rts
;-------------------------------------------------------------------------;
NoScrollUp:
;-------------------------------------------------------------------------;
	rep	#30h

	lda	bg1vofs
	cmp	#01feh
	beq	TimeThis
;-------------------------------------------------------------------------;
	sep	#20h

	rts
;-------------------------------------------------------------------------;
TimeThis:
;-------------------------------------------------------------------------;
	rep	#30h

	inc	infotimer
	lda	infotimer
	cmp	#0150h
	beq	TimerOver
;-------------------------------------------------------------------------;
	sep	#20h

	rts
;-------------------------------------------------------------------------;
TimerOver:
;-------------------------------------------------------------------------;
	sep	#20h

	inc	bgscrollflag
	lda     #FADE_OUT
	sta     timerfade

	rts


;=========================================================================;
;                      Sprite Scroll Routine
;=========================================================================;
SpriteScroll:
;=========================================================================;
	rep	#10h			; x,y = 16 bit
	sep	#20h			; a = 8 bit
			; start of General DMA graphics copy routine!
	stz	REG_DMAP3		; 0= 1 byte per register (not a word!)
	lda	#<REG_OAMDATA
	sta	REG_BBAD3		; 21xx   this is 2118 (VRAM)
	ldx	#RAM_OAM
	stx	REG_A1T3L
	;lda	#^RAM_OAM
	stz	REG_A1B3		; bank address of data in ram
	ldx	#0044h
	stx	REG_DAS3L		; # of bytes to be transferred

	ldx	#0000h
	stx	REG_OAMADDL

	lda	#%1000			; turn on bit 4 of G-DMA channel
	sta	REG_MDMAEN

	ldx	#0100h
	stx	REG_OAMADDL
	lda	msbsprite
	sta	REG_OAMDATA
	rts


;=========================================================================;
MoveScroll:
;=========================================================================;
	stz	msbsprite
	lda	scrollhpos
	sta	offsetsprsine2
	sec
	sbc	#11h
	sta	spritehoff

	and	#80h
	asl a
	rol	msbsprite
	
	ldx	#0000h
	stx	scrollramoff
	txy
;-------------------------------------------------------------------------;
ScrollWriter:
;-------------------------------------------------------------------------;
	lda	spritehoff
	sta	RAM_OAM,x
	inx
	phx

	rep	#30h

	lda	offsetsprsine2
	clc
	adc	offsetsprsine1
	and	#00ffh
	tax

	sep	#20h

	lda	VERT_SINE2,x			; vert pos
	clc
	adc	#48h
	plx
	sta	RAM_OAM,x
	inx

	rep	#30h

	phy
	ldy	scrollramoff
	lda	RAM_OAM+50h,y
	ply

	and	#0ffh
	sec
	sbc	#20h
	phx
	tax

	sep	#20h

	lda	ASCII_MAP,x	
	plx
	sta	RAM_OAM,x
	inx
	lda	#OAM_PAL0|OAM_PRI3|OAM_NT0
	sta	RAM_OAM,x
	inx

	phx
	ldx	scrollramoff
	inx
	stx	scrollramoff
	plx

	lda	offsetsprsine2
	clc
	adc	#10h
	sta	offsetsprsine2

	lda	spritehoff
	clc
	adc	#10h
	sta	spritehoff
	iny
	cpy	#0011h
	bne	ScrollWriter
;-------------------------------------------------------------------------;
	inc	offsetsprsine1
	inc	offsetsprsine1
	inc	offsetsprsine1

	dec	scrollhpos
	lda	scrollhpos
	beq	MoveScrolltext
;-------------------------------------------------------------------------;
	rts
;-------------------------------------------------------------------------;
MoveScrolltext:
;-------------------------------------------------------------------------;
	lda	#10h
	sta	scrollhpos

	inc	logo1voff
	inc	logo2voff

	ldx	#0000h

	sep	#20h
;-------------------------------------------------------------------------;
CopyScrolltext:
;-------------------------------------------------------------------------;
	lda	RAM_OAM+51h,x
	sta	RAM_OAM+50h,x
	inx
	cpx	#0010h
	bne	CopyScrolltext
;-------------------------------------------------------------------------;
ReadText:
;-------------------------------------------------------------------------;
	ldx	scrollpos
	lda	SCROLLTEXT,x
	beq	EndScroll
	cmp	#60h
	bcc	NoAnd5f
	and	#5fh
;-------------------------------------------------------------------------;
NoAnd5f:
;-------------------------------------------------------------------------;
	sta	RAM_OAM+60h
	ldx	scrollpos
	inx
	stx	scrollpos
	rts
;-------------------------------------------------------------------------;
EndScroll:
;-------------------------------------------------------------------------;
	ldx	#0000h
	stx	scrollpos
	bra	ReadText


;=========================================================================;
;                        Vertical Blank Wait Routine
;=========================================================================;
WaitVb:	
;=========================================================================;
	lda	REG_RDNMI
	bpl     WaitVb	; is the number higher than #$7f? (#$80-$ff)
			; bpl tests bit #7 ($80) if this bit is set it means
			; the byte is negative (BMI, Branch on Minus)
			; BPL (Branch on Plus) if bit #7 is set in REG_RDNMI
			; it means that it is at the start of V-Blank
			; if not it will keep testing REG_RDNMI until bit #7
			; is on (which would make it a negative (BMI)
	rts

;==========================================================================
;       	     SETUP ROUTINES FOR PROGRAM
;==========================================================================


;=========================================================================;
PaletteCycle:
;=========================================================================;
	dec	dot_pal_delay
	lda	dot_pal_delay
	bne	:++
;-------------------------------------------------------------------------;
	lda	#DOT_PAL_DELAY
	sta	dot_pal_delay

	ldx	dot_pal_index
	cpx	#PLASMA_PAL_END-PLASMA_PAL
	bne	:+
;-------------------------------------------------------------------------;
	ldx	#0000h
;-------------------------------------------------------------------------;
:	lda	#1
	sta	REG_CGADD
	lda	PLASMA_PAL,x
	sta	REG_CGDATA
	inx
	lda	PLASMA_PAL,x
	sta	REG_CGDATA
	inx
	stx	dot_pal_index
;-------------------------------------------------------------------------;
:	rts


;=========================================================================;
;                           Sprite Setup routine
;=========================================================================;
SpriteSetup:
;=========================================================================;
	lda	#60h
	sta	REG_OBSEL
	;ldx	#0000h
	sty	REG_OAMADDL		; y is still 0 from ClearRam
	tyx
sprtclear:
	stz	REG_OAMDATA		; Horizontal position
	lda	#0f0h
	sta	REG_OAMDATA		; Vertical position
	stz	REG_OAMDATA		; sprite object = 0
	lda	#OAM_PAL0|OAM_PRI3|OAM_NT0
	sta	REG_OAMDATA
	inx
	cpx	#0080h			; (128 sprites)
	bne	sprtclear
;-------------------------------------------------------------------------;
sprtdataclear:
;-------------------------------------------------------------------------;
	stz	REG_OAMDATA		; clear H-position MSB
	stz	REG_OAMDATA		; and make size small
	iny
	cpy	#0020h			; 32 extra bytes for sprite data info
	bne	sprtdataclear
;-------------------------------------------------------------------------;
	rts


;/////////////////////////////////////////////////////////////////////////;
.code
;/////////////////////////////////////////////////////////////////////////;


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
HORIZ_SINE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
 .byte	128,131,134,137,140,143,146,149,152,155,158,162,165,167,170,173
 .byte	176,179,182,185,188,190,193,196,198,201,203,206,208,211,213,215
 .byte	218,220,222,224,226,228,230,232,234,235,237,238,240,241,243,244
 .byte	245,246,248,249,250,250,251,252,253,253,254,254,254,255,255,255
 .byte	255,255,255,255,254,254,254,253,253,252,251,250,250,249,248,246
 .byte	245,244,243,241,240,238,237,235,234,232,230,228,226,224,222,220
 .byte	218,215,213,211,208,206,203,201,198,196,193,190,188,185,182,179
 .byte	176,173,170,167,165,162,158,155,152,149,146,143,140,137,134,131
 .byte	128,124,121,118,115,112,109,106,103,100,097,093,090,088,085,082
 .byte	079,076,073,070,067,065,062,059,057,054,052,049,047,044,042,040
 .byte	037,035,033,031,029,027,025,023,021,020,018,017,015,014,012,011
 .byte	010,009,007,006,005,005,004,003,002,002,001,001,001,000,000,000
 .byte	000,000,000,000,001,001,001,002,002,003,004,005,005,006,007,009
 .byte	010,011,012,014,015,017,018,020,021,023,025,027,029,031,033,035
 .byte	037,040,042,044,047,049,052,054,057,059,062,065,067,070,073,076
 .byte	079,082,085,088,090,093,097,100,103,106,109,112,115,118,121,124
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
VERT_SINE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
 .byte	064,066,067,069,070,072,073,075,076,078,080,081,083,084,086,087
 .byte	088,090,091,093,094,096,097,098,100,101,102,103,105,106,107,108
 .byte	109,110,111,112,113,114,115,116,117,118,119,120,120,121,122,123
 .byte	123,124,124,125,125,126,126,126,127,127,127,128,128,128,128,128
 .byte	128,128,128,128,128,128,127,127,127,126,126,126,125,125,124,124
 .byte	123,123,122,121,120,120,119,118,117,116,115,114,113,112,111,110
 .byte	109,108,107,106,105,103,102,101,100,098,097,096,094,093,091,090
 .byte	088,087,086,084,083,081,080,078,076,075,073,072,070,069,067,066
 .byte	064,062,061,059,058,056,055,053,052,050,048,047,045,044,042,041
 .byte	040,038,037,035,034,032,031,030,028,027,026,025,023,022,021,020
 .byte	019,018,017,016,015,014,013,012,011,010,009,008,008,007,006,005
 .byte	005,004,004,003,003,002,002,002,001,001,001,000,000,000,000,000
 .byte	000,000,000,000,000,000,001,001,001,002,002,002,003,003,004,004
 .byte	005,005,006,007,008,008,009,010,011,012,013,014,015,016,017,018
 .byte	019,020,021,022,023,025,026,027,028,030,031,032,034,035,037,038
 .byte	040,041,042,044,045,047,048,050,052,053,055,056,058,059,061,062
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
VERT_SINE2:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
 .byte	064,064,064,064,064,064,064,064,064,064,064,064,064,064,064,063
 .byte	063,063,063,063,062,062,062,062,061,061,061,060,060,059,059,059
 .byte	058,058,057,057,056,056,055,055,054,053,053,052,052,051,050,050
 .byte	049,048,048,047,046,046,045,044,044,043,042,041,041,040,039,038
 .byte	037,037,036,035,034,034,033,032,031,030,030,029,028,027,027,026
 .byte	025,024,023,023,022,021,020,020,019,018,018,017,016,016,015,014
 .byte	014,013,012,012,011,011,010,009,009,008,008,007,007,006,006,005
 .byte	005,005,004,004,003,003,003,002,002,002,002,001,001,001,001,001
 .byte	000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,001
 .byte	001,001,001,001,002,002,002,002,003,003,003,004,004,005,005,005
 .byte	006,006,007,007,008,008,009,009,010,011,011,012,012,013,014,014
 .byte	015,016,016,017,018,018,019,020,020,021,022,023,023,024,025,026
 .byte	027,027,028,029,030,030,031,032,033,034,034,035,036,037,037,038
 .byte	039,040,041,041,042,043,044,044,045,046,046,047,048,048,049,050
 .byte	050,051,052,052,053,053,054,055,055,056,056,057,057,058,058,059
 .byte	059,059,060,060,061,061,061,062,062,062,062,063,063,063,063,063
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
ASCII_MAP:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	;	      !   "   #   $   %   &   '
	.byte	$20,$02,$04,$20,$20,$20,$0c,$0e
	;	  (   ) HE*   +   ,   -   .   /
	.byte	$06,$08,$24,$26,$28,$2a,$2c,$2e
	;	  0   1   2   3   4   5   6   7
	.byte	$40,$42,$44,$46,$48,$4a,$4c,$4e
	;	  8   9   :   ;   <   =   >   ?
	.byte	$60,$62,$64,$66,$68,$2a,$6c,$6e
	;	  @   A   B   C   D   E   F   G
	.byte	$80,$82,$84,$86,$88,$8a,$8c,$8e
	;	  H   I   J   K   L   M   N   O
	.byte	$a0,$a2,$a4,$a6,$a8,$aa,$ac,$ae
	;	  P   Q   R   S   T   U   V   W
	.byte	$c0,$c2,$c4,$c6,$c8,$ca,$cc,$ce
	;	  X   Y   Z   [   \   ]   ^   _
	.byte	$e0,$e2,$e4
	;	  `   a   b   c   d   e   f   g

	;	  h   i   j   k   l   m   n   o

	;	  p   q   r   s   t   u   v   w

	;	  x   y   z   {   |   }   ~   ©

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	"Scroll starts here ->"
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SCROLLTEXT:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	"<><>  -Pan- presents another awesome intro! the 128 sine-dot "
	.byte	"background effect makes this whole intro totally COOL!     "
	.byte	"           ",0
	.byte	"                                                          "
	.byte	"                                                          "
	.byte	"                                                          "
	.byte	"                                                          "
	.byte	"                                                          "
	.byte	"                                                          "
	.byte	"                                                          "
	.byte	"                                                          "
	.byte	"                                                          "
	.byte	"                                                          "
	.byte	"                                                          "
	.byte	"                                                          "
	.byte	"                                                          "
	.byte	"                                                          "
	.byte	"                     ",0,"<- End of Scroll text"
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
PLASMA_PAL:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.word	$7400,$7c00,$7c40,$7c80,$7cc0,$7d20,$7d60,$7da0
	.word	$7de0,$7e40,$7e80,$7ec0,$7f00,$7f60,$7fa0,$7fe0
	.word	$7fe0,$7fa0,$7f60,$7f00,$7ec0,$7e80,$7e40,$7de0
	.word	$7da0,$7d60,$7d20,$7cc0,$7c80,$7c40,$7c00,$7400

	.word	$01e0,$0200,$0a21,$1243,$1a65,$2686,$2ea8,$36ea
	.word	$430b,$4b2d,$534f,$5b70,$6792,$6fb4,$77d5,$7ff7
	.word	$7ff7,$77d5,$6fb4,$6792,$5b70,$534f,$4b2d,$430b
	.word	$36ea,$2ea8,$2686,$1a65,$1243,$0a21,$0200,$01e0

	.word	$001e,$001f,$085f,$109f,$18de,$253e,$2d7e,$35bd
	.word	$421d,$4A5d,$529c,$5adc,$673c,$6f7b,$77bb,$7ffa
	.word	$7ffa,$77bb,$6f7b,$673c,$5adc,$529c,$4a5d,$421d
	.word	$35bd,$2d7e,$253e,$18de,$109f,$085f,$001f,$001e

	.word	$4c14,$5055,$5096,$54d6,$5917,$5d58,$6199,$65D9
	.word	$663a,$6a7b,$6ebc,$72fc,$773d,$7b7e,$7fbf,$7fff
	.word	$7fff,$7fbf,$7b7e,$773d,$72fc,$6ebc,$6a7b,$663a
	.word	$65d9,$6199,$5d58,$5917,$54d6,$5096,$5055,$4c14

	.word	$0000,$0042,$0084,$00c6,$0108,$014a,$018c,$01ce
	.word	$0231,$0273,$02b5,$02f7,$0339,$037b,$03bd,$03ff
	.word	$03ff,$03bd,$037b,$0339,$02f7,$02b5,$0273,$0231
	.word	$01ce,$018c,$014a,$0108,$00c6,$0084,$0042,$0000

	.word	$0000,$0002,$0004,$0006,$0008,$000a,$000c,$000e
	.word	$0011,$0013,$0015,$0017,$0019,$001b,$001d,$001f
	.word	$001f,$001d,$001b,$0019,$0017,$0015,$0013,$0011
	.word	$000e,$000c,$000a,$0008,$0006,$0004,$0002,$0000

	.word	$0000,$0040,$0080,$00c0,$0100,$0140,$0180,$01c0
	.word	$0220,$0260,$02a0,$02e0,$0320,$0360,$03a0,$03e0
	.word	$03e0,$03a0,$0360,$0320,$02e0,$02a0,$0260,$0220
	.word	$01c0,$0180,$0140,$0100,$00c0,$0080,$0040,$0000

	.word	$0000,$0800,$1000,$1800,$2000,$2800,$3000,$3800
	.word	$4400,$4c00,$5400,$5c00,$6400,$6c00,$7400,$7c00
	.word	$7c00,$7400,$6c00,$6400,$5c00,$5400,$4c00,$4400
	.word	$3800,$3000,$2800,$2000,$1800,$1000,$0800,$0000

	.word	$0000,$0840,$1080,$18c0,$2100,$2940,$3180,$39c0
	.word	$4620,$46e0,$56a0,$5ee0,$6720,$6f60,$77a0,$7fe0
	.word	$7fe0,$77a0,$6f60,$6720,$5ee0,$56a0,$4e60,$4620
	.word	$39c0,$3180,$2940,$2100,$18c0,$1080,$0840,$0000

	.word	$0000,$0802,$1004,$1806,$2008,$280a,$300c,$380e
	.word	$4411,$4c13,$5415,$5c17,$6419,$6c1b,$741d,$7c1f
	.word	$7c1f,$741d,$6c1b,$6419,$5c17,$5415,$4c13,$4411
	.word	$380e,$300c,$280a,$2008,$1806,$1004,$0802,$0000

	.word	$03ff,$0bff,$13ff,$1bff,$23ff,$2bff,$33ff,$3bff
	.word	$47ff,$4fff,$57ff,$5fff,$67ff,$6fff,$77ff,$7fff
	.word	$7fff,$77ff,$6fff,$67ff,$5fff,$57ff,$4fff,$47ff
	.word	$3bff,$33ff,$2bff,$23ff,$1bff,$13ff,$0bff,$03ff

	.word	$0000,$0842,$1084,$18c6,$2108,$294a,$318c,$39ce
	.word	$4631,$4e73,$56b5,$5ef7,$6739,$6f7b,$77bd,$7fff
	.word	$7fff,$77bd,$6f7b,$6739,$5ef7,$56b5,$4e73,$4631
	.word	$39ce,$318c,$294a,$2108,$18C6,$1084,$0842,$0000

	.word	$39df,$3a3f,$3abf,$3aff,$3b3f,$3b7f,$3bff,$3bfd
	.word	$3bfb,$3bf7,$3bf5,$3bf3,$3bf1,$47ee,$4fee,$57ee
	.word	$57ee,$4fee,$47ee,$3bf1,$3fb3,$3bf5,$3bf7,$3bfb
	.word	$3bfd,$3bff,$3b7f,$3b3f,$3aff,$3abf,$3a3f,$39df

	.word	$67ee,$6fee,$77ee,$7fae,$7f6e,$7f2e,$7eee,$7e6e
	.word	$7e2e,$7dce,$7dd3,$7dd5,$7dd7,$7dd9,$7ddd,$7ddf
	.word	$7ddf,$7ddd,$7dd9,$7dd7,$7dd5,$7dd3,$7dce,$7e2e
	.word	$7e6e,$7eee,$7f2e,$7f6e,$7fae,$77ee,$6fee,$67ee

	.word	$001f,$009f,$015f,$01df,$02bf,$033F,$03bf,$03fb
	.word	$03f7,$03f1,$03ec,$03e6,$03e2,$0be0,$23e0,$33e0
	.word	$33e0,$23e0,$0be0,$03e2,$03e6,$03ec,$03f1,$03f7
	.word	$03fb,$03bf,$033f,$02bf,$01df,$015f,$009f,$001f

	.word	$4fe0,$5fe0,$6fe0,$7fa0,$7ee0,$7e60,$7dc0,$7d00
	.word	$7c80,$7c00,$7c06,$7c0a,$7c11,$7c15,$7c19,$7c1f 
	.word	$7c1f,$7c19,$7c15,$7c11,$7c0a,$7c06,$7c00,$7c80
	.word	$7d00,$7dc0,$7e60,$7ee0,$7fa0,$6fe0,$5fe0,$4fe0

	.word	$7400,$7c00,$7c40,$7c80,$7cc0,$7d20,$7d60,$7da0
	.word	$7de0,$7e40,$7e80,$7ec0,$7f00,$7f60,$7fa0,$7fe0
	.word	$7fe0,$7fa0,$7f60,$7f00,$7ec0,$7e80,$7e40,$7de0
	.word	$7da0,$7d60,$7d20,$7cc0,$7c80,$7c40,$7c00,$7400
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
PLASMA_PAL_END:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
