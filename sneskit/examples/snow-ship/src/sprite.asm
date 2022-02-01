;-------------------------------------------------------------------------;
.include "oam.inc"
.include "random.inc"
.include "screen.inc"
.include "snes.inc"
.include "snes_decompress.inc"
.include "snes_joypad.inc"
.include "snes_zvars.inc"
.include "graphics.inc"
;-------------------------------------------------------------------------;
.global DoSprite
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
AERA_RIGHT	= 40h
AERA_LEFT	= 34h	; this will be subtracted from AERA_RIGHT
AERA_FORWARD	= 38h	; ''

SNOW_TILES	= 54
SPR_XPOS	= 204
SPR_YPOS	= 76

snow_xpos	= m4
oam_frame	= m5
;-------------------------------------------------------------------------;

BG1GFX = 02000h
BG1MAP = 01000h
BG2GFX = 0c800h
BG2MAP = 01800h
OAMGFX = 00000h

TITLEMAP = 0f800h
TITLEGFX = 0e800h


;/////////////////////////////////////////////////////////////////////////;
.code
;/////////////////////////////////////////////////////////////////////////;


;-------------------------------------------------------------------------;
.a8
.i16
;-------------------------------------------------------------------------;


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
DoSprite:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	lda	#0ffh
	sta	REG_BG1VOFS
	stz	REG_BG1VOFS
	sta	REG_BG2VOFS
	stz	REG_BG2VOFS
	sta	REG_BG3VOFS
	stz	REG_BG3VOFS

	DoCopyPalette gfx_alundra3Pal, 64, 15	; pal offset 4096 + map offset
						; 64 = -ma 4160 in grit file
	DoCopyPalette gfx_titlePal, 80, 16	; pal offset 5120 + map offset
						; 64 = -ma 5184 in grit file
	DoCopyPalette gfx_aeraPal, 128, 16
	DoCopyPalette gfx_aera_pal2Pal, 144, 9

	DoDecompressDataVram gfx_titleTiles, TITLEGFX
	DoDecompressDataVram gfx_titleMap, TITLEMAP

	DoDecompressDataVram gfx_aeraTiles, OAMGFX
	DoDecompressDataVram gfx_alundra3Map, BG2MAP
	DoDecompressDataVram gfx_alundra3Tiles, BG2GFX

Reset:	DoDecompressDataVram gfx_alundra2Map, BG1MAP
	DoDecompressDataVram gfx_alundra2Tiles, BG1GFX

	DoCopyPalette gfx_alundra2Pal, 0, 63

	lda	#TITLEMAP>>9
	sta	REG_BG1SC

	lda	#TITLEGFX>>13
	sta	REG_BG12NBA

	stz	oam_frame
	jsr	SpriteInit		; put RAM "copy" of sprites offscreen


	ldx	#0000h
	lda	#44h
	sta	m0
	lda	#96			; hpos
:	sta	oam_table,x
	clc
	adc	#32
	xba
	inx

	lda	#100			; vpos
	sta	oam_table,x
	inx

	lda	m0
	sta	oam_table,x
	clc
	adc	#04h
	sta	m0
	inx

	lda	#OAM_PRI2|OAM_PAL1|OAM_NT0
	sta	oam_table,x
	xba
	inx
	cpx	#0008h
	bne	:-

	lda	#%01010000
	sta	oam_hitable

	lda	#OBSEL_32_64|OBSEL_BASE(OAMGFX)|OBSEL_NN_8K
	sta	REG_OBSEL		; set sprite size to 32x32 at "small"

;		  +---------[ subtract           ]
; if set to	  |+--------[ half color math    ]
; 1		  ||+-------[ enable on backdrop ]
;		  |||+------[ enable on objects  ]
;		  ||||+-----[ enable on screen 4 ]
;		  |||||+----[ enable on screen 3 ]
;		  ||||||+---[ enable on screen 2 ]
;		  |||||||+--[ enable on screen 1 ]
;		  ||||||||
	lda	#%01100011
	sta	REG_CGADSUB

	lda	#TM_OBJ|TM_BG1
	sta	REG_TM
	and	#TM_BG1

	sta	frame_ready
	sta	REG_BGMODE
	inc
	sta	REG_CGSWSEL
	lda	#0e0h
	sta	REG_COLDATA
;-------------------------------------------------------------------------;
TitleLoop:
;-------------------------------------------------------------------------;
	lda	REG_RDNMI
	bpl	TitleLoop

	jsr	FadeInMosaic
	jsr	ScreenSaver

	lda	joy1_down
	eor	joy1_down+1
	eor	joy2_down
	eor	joy2_down+1
	beq	TitleLoop
;-------------------------------------------------------------------------;
DoSprites:
;-------------------------------------------------------------------------;
	jsr	FadeOut

	lda	#BGMODE_3
	sta	REG_BGMODE

	lda	#BG1MAP>>9			; 08h
	sta	REG_BG1SC
	lda	#BG2MAP>>9			; 0ch
	sta	REG_BG2SC
	lda	#(BG2GFX>>9)			; 0c8h
	and	#0f0h
	ina					; BG1 = 01h
	sta	REG_BG12NBA			; 61h

	lda	#TM_OBJ|TM_BG1
	sta	REG_TM

	lda	#TM_BG2
	sta	REG_TS

	jsr	SpriteInit
	lda	#0cfh
	jsr	Seed
	jsr	SetupSnowSprites
;-------------------------------------------------------------------------;
SpriteLoop:
;-------------------------------------------------------------------------;
	lda	REG_RDNMI
	bpl	SpriteLoop

	jsr	FadeInMosaic
	jsr	SnowSprite
	jsr	ScreenSaver

	lda	joy1_down+1
	eor	joy2_down+1
	cmp	#JOYPADH_START
	bne	SpriteLoop
;-------------------------------------------------------------------------;
	jsr	FadeOut

	stz 	frame_ready
	stz	REG_TS

	lda	#TM_BG1
	sta	REG_TM

	DoDecompressDataVram gfx_alundra1Map, BG1MAP
	DoDecompressDataVram gfx_alundra1Tiles, BG1GFX
	DoCopyPalette gfx_alundra1Pal, 0, 64
;-------------------------------------------------------------------------;
EndLoop:
;-------------------------------------------------------------------------;
	lda	REG_RDNMI
	bpl	EndLoop
	jsr	FadeInMosaic
	jsr	ScreenSaver

	lda	joy1_down+1
	eor	joy2_down+1
	cmp	#JOYPADH_START
	bne	EndLoop

	jsr	FadeOut
	jmp	Reset





;=========================================================================;
SetupSnowSprites:
;=========================================================================;
	ldx	#0000h
set_sp:	jsr	Random

	sta	oam_table,x			; x coordinate
	inx

	lda	random
	sta	oam_table,x			; y coordinate
	inx

	lda	#04h
	sta	oam_table,x			; tile number
	inx
		;%vhoopppN
	lda	#OAM_PRI3|OAM_PAL0|OAM_NT0	; enable sprite priority
	sta	oam_table,x
	inx

	cpx	#SNOW_TILES*4
	bne	set_sp
;-------------------------------------------------------------------------;
	lda	#SPR_XPOS
	sta	oam_table,x
	inx

	lda	#SPR_YPOS
	sta	oam_table,x
	inx

	stz	oam_table,x
	inx
		;%vhoopppN
	lda	#OAM_PRI2|OAM_PAL0|OAM_NT0
	sta	oam_table,x

	ldx	#0000h
;-------------------------------------------------------------------------;
ohi:	stz	oam_hitable,x
	inx
	cpx	#(SNOW_TILES/4)+1
	bne	ohi
;-------------------------------------------------------------------------;
	rts


;=========================================================================;
SnowSprite:
;=========================================================================;
	sep	#10h

	ldx	#00h
;-------------------------------------------------------------------------;
PositionSprite:
;-------------------------------------------------------------------------;
	lda	oam_table,x
	sta	snow_xpos
	jsr	Random
	cmp	#241			; 241-255: move right
	bcs	IncX			; add x variability
	cmp	#3			; 000-003: move left
	bcs	cont			; 004-240: don't add variablity 
;-------------------------------------------------------------------------;
	dec	snow_xpos		; add x variability
	bra	cont
;-------------------------------------------------------------------------;
IncX:	inc	snow_xpos
;-------------------------------------------------------------------------;
cont:	lda	snow_xpos
	sta	oam_table,x		; x coordinate
	inx
	lda	oam_table,x		; get y coordinate
	inc				; increase
	sta	oam_table,x		; store new y coordinate
	inx
	inx				; skip tile number
	inx				; skip other properties
	cpx	#SNOW_TILES*4
	bne	PositionSprite
;-------------------------------------------------------------------------;
AeraSprite:
;-------------------------------------------------------------------------;
	lda	#AERA_RIGHT
	inx
	inx
	ldy	oam_frame
	cpy	#97
	bcs	StoreTile	; Right = 97-127
	cpy	#95
	bcs	AeraForward	; Forward = 95, 96
	cpy	#64
	bcs	AeraLeft	; Left = 64-94
;-------------------------------------------------------------------------;
AeraForward:
;-------------------------------------------------------------------------;
	sec
	sbc	#AERA_FORWARD
	bra	StoreTile
;-------------------------------------------------------------------------;
AeraLeft:
;-------------------------------------------------------------------------;
	sbc	#AERA_LEFT
;-------------------------------------------------------------------------;
StoreTile:
;-------------------------------------------------------------------------;
	sta	oam_table,x
	iny
	cpy	#128
	bne	:+
;-------------------------------------------------------------------------;
	ldy	#00h
;-------------------------------------------------------------------------;
:	sty	oam_frame

	rep	#10h

	rts
