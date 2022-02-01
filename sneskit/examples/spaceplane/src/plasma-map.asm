;-------------------------------------------------------------------------;
.include "fade.inc"
.include "graphics.inc"
.include "macros.inc"
.include "nmi.inc"
.include "oam.inc"
.include "options.inc"
.include "plasma.inc"
.include "shadow_ram.inc"
.include "snes.inc"
.include "snes_decompress.inc"
.include "snes_init.inc"
.include "snes_joypad.inc"
.include "snes_zvars.inc"
.include "spaceplane.inc"
;-------------------------------------------------------------------------;
.import oam_hitable, oam_table, waitvb
;-------------------------------------------------------------------------;
.export DoPlasmaMap
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
BG1GFX = 08000h
BG1MAP = 0b800h
OAMGFX = 0c000h
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
color_ptr = m2
plasma_sine_addr1 = m4
plasma_sine_addr2 = m5
plasma_sine_addr3 = m6
plasma_sine_addr4 = m7
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
	.zeropage
;/////////////////////////////////////////////////////////////////////////;


;-------------------------------------------------------------------------;
max_sprites:
	.res	2
row_index:
	.res	1
sprite_xpos:
	.res	1
sprite_ypos:
	.res	1
tile_index:
	.res	2
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
	.code
;/////////////////////////////////////////////////////////////////////////;


	.a8
	.i16


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
DoPlasmaMap:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	rep	#10h
	sep     #20h			; Accumulator ->  8 bit mode

	lda	plasma_mode
	bne	:+
;-------------------------------------------------------------------------;
	jmp	DoSpacePlane
;-------------------------------------------------------------------------;
:	lda	#BGMODE_7		; mode 0, 8/8 dot
	sta	REG_BGMODE	

	lda	#TM_OBJ|TM_BG1
	sta	REG_TM

	stz	REG_M7SEL

	lda	#%00110011		; planes 0-3 uses Window 1
	sta	REG_W12SEL
	stz	REG_MPYL

	lda	#0c3h			; Color window uses window 2
	sta	REG_WOBJSEL		; Obj window uses window 1
	
	stz	REG_WH0			; window 1 start
	lda	#0ffh			; window 1 end
	sta	REG_WH1

	stz	REG_WH2			; window 2 start
	lda	#0a0h			; Window 2 end
	sta	REG_WH3

	lda	#0ch			; Color Window Logic 0 = or
	sta	REG_WOBJLOG		; 4 =and , 8 = xor, c = xnor

	lda	#TMW_BG1		; Main screen mask belongs to obj, and planes
	sta	REG_TMW
	stz	REG_TSW
	stz	REG_CGSWSEL
	stz	color_ptr+2

	jsr	InitPlasma
;-------------------------------------------------------------------------;
	lda	plasma_mode
	bit	#PLASMAMAP
	bne	PlasmaMapSetup
;-------------------------------------------------------------------------;
	lda	#OPTION_MOSAIC
	tsb	options

	ldx	#REG_A1T1L
	stx	color_ptr

	ldx	#PLASMA_SINE
	stx	plasma_sine_addr3

	lda	#CGADSUB_SUBTRACT|CGADSUB_BACKDROP|CGADSUB_BG1
 	sta	REG_CGADSUB		; add,not 1/2 bright, back, no obj, bg0-3

		;%bgrccccc		; blue off, green on, red off
	lda	#%10100111
	sta	REG_COLDATA		; lowest 5 bits = brightness

	jsr	CopyPlasmaGfx
	jsr	PlasmaOnlyHDMA

	lda	#%00000111
	sta	REG_HDMAEN

	jmp	ContinueSetup
;-------------------------------------------------------------------------;
PlasmaMapSetup:
;-------------------------------------------------------------------------;
	lda	#20h
	sta	reg_inidisp

	lda	#CGADSUB_HALF|CGADSUB_BACKDROP
 	sta	REG_CGADSUB		; add,not 1/2 bright, back, no obj, bg0-3

		;%bgrccccc		; blue off, green on, red off
	lda	#%01000111
	sta	REG_COLDATA		; lowest 5 bits = brightness

	lda	#(BG1MAP>>9)
	sta	REG_BG1SC

	lda	#(BG1GFX>>13)
	sta	REG_BG12NBA

	lda	#1
	sta	REG_WH0
	eor	#255
	sta	REG_WH1

	jsr	PlasmaMapSpacePlaneDMA
	jsr	CopyPlasmaGfx

	DoDecompressDataVram gfx_plasma_mapTiles, OAMGFX
	DoCopyPalette gfx_plasma_map_pal6Pal, 224, 16
	DoCopyPalette gfx_plasma_mapPal, 240, 16

	lda	#OBSEL_16_32|OBSEL_BASE(OAMGFX)|OBSEL_NN_16K
	sta	REG_OBSEL

	stz	sprite_xpos
	stz	sprite_ypos

	ldx	#(SPRITE_TILES_END-SPRITE_TILES)-1
	stx	max_sprites
	lda	#OAM_PRI3|OAM_PAL6	; oam properties
	ldx	#0			; tile index
	stx	color_ptr
	txy				; oam table index
	jsr	SetupSprites

	stz	sprite_xpos
	lda	#176
	sta	sprite_ypos
	ldx	#(SPRITE_TILES_FG_END-SPRITE_TILES)-1
	stx	max_sprites
	lda	#OAM_HFLIP|OAM_PRI3|OAM_PAL7
	ldx	tile_index
	jsr	SetupSprites

	jsr	PlasmaOnlyHDMA
	jsr	PlasmaMapHDMA

		;    +----> reserved for oam in nmi
	lda	#%11101111
	sta	REG_HDMAEN

	lda	#04h
	sta	REG_A1T7L
;-------------------------------------------------------------------------;
ContinueSetup:
;-------------------------------------------------------------------------;
	lda	#NMI_ON|NMI_JOYPAD
	sta	REG_NMITIMEN

	lda	#OPTION_FRAME_READY
	tsb	options
;-------------------------------------------------------------------------;
Loop:	
;-------------------------------------------------------------------------;
	lda	REG_RDNMI
	bpl	Loop

	lda	plasma_mode
	bit	#PLASMAON
	bne	SkipSpacePlane
;-------------------------------------------------------------------------;
	jsr	SpacePlane
	bra	SkipPlasmaOnly
;-------------------------------------------------------------------------;
SkipSpacePlane:
;-------------------------------------------------------------------------;
	jsr	FadeMosaic

joy:	lda	REG_HVBJOY
	and	#01h
	bne	joy

	rep	#30h

	lda	REG_JOY1L
	jsr	TestQuit

	sep	#20h
;-------------------------------------------------------------------------;
SkipPlasmaOnly:
;-------------------------------------------------------------------------;
	jsr	PlasmaMode7
	jsr	PlasmaHDMAMover
	jsr	ColorBlend

	lda	reg_inidisp
	bne	Loop
;-------------------------------------------------------------------------;
	rts


;=========================================================================;
SetupSprites:	; a = oam prop  x = tile inex  y = oam table index
;=========================================================================;
	xba
;-------------------------------------------------------------------------;
:	lda	#0
;-------------------------------------------------------------------------;
:	sta	row_index
	lda	sprite_xpos
	sta	oam_table,y
	iny
	lda	sprite_ypos
	sta	oam_table,y
	iny
	lda	SPRITE_TILES,x
	sta	oam_table,y
	inx
	iny
	xba
	sta	oam_table,y
	xba
	iny
	lda	sprite_xpos
	sec
	adc	#0fh			; inc xpos
	sta	sprite_xpos
	lda	row_index
	ina
	cmp	#16
	bne	:-
;-------------------------------------------------------------------------;
	lda	sprite_ypos
	sec
	adc	#0fh
	sta	sprite_ypos
	cpx	max_sprites
	bcc	:--
;-------------------------------------------------------------------------;
	stx	tile_index

	rts


;/////////////////////////////////////////////////////////////////////////;
.segment "DATA"
;/////////////////////////////////////////////////////////////////////////;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SPRITE_TILES:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
 .byte	$00,$02,$04,$06,$08,$00,$02,$04,$06,$08,$00,$02,$04,$06,$08,$00
 .byte	$0a,$0c,$0e,$20,$22,$0a,$0c,$0e,$20,$22,$0a,$0c,$0e,$20,$22,$0a
 .byte	$24,$26,$28,$2a,$2c,$24,$26,$28,$2a,$2c,$24,$26,$28,$2a,$2c,$24
 .byte	$2e,$40,$42,$44,$46,$2e,$40,$42,$44,$46,$2e,$40,$42,$44,$46,$2e
 .byte	$48,$4a,$4c,$4e,$60,$48,$4a,$4c,$4e,$60,$48,$4a,$4c,$4e,$60,$48
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SPRITE_TILES_END:
SPRITE_TILES_FG:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
 .byte	$ce,$e0,$e2,$ce,$e0,$e2,$ce,$e0,$e2,$ce,$e0,$e2,$ce,$e0,$e2,$ce
 .byte	$e4,$e6,$e8,$e4,$e6,$e8,$e4,$e6,$e8,$e4,$e6,$e8,$e4,$e6,$e8,$e4
 .byte	$ea,$ec,$ee,$ea,$ec,$ee,$ea,$ec,$ee,$ea,$ec,$ee,$ea,$ec,$ee,$ea
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SPRITE_TILES_FG_END:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;

