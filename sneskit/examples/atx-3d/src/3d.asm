;-------------------------------------------------------------------------;
.include "bg_scrolltext.inc"
.include "graphics.inc"
.include "hdma_lines.inc"
.include "snes.inc"
.include "snes_decompress.inc"
.include "snes_joypad.inc"
.include "snes_zvars.inc"
;-------------------------------------------------------------------------;
.importzp frame_ready
;-------------------------------------------------------------------------;
.import clear_vram, oam_table, oam_hitable
;-------------------------------------------------------------------------;
.exportzp shadow_hdmaen
;-------------------------------------------------------------------------;
.export DoIntro
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
OAMGFX = 08000h
BG1GFX = 0a000h
BG1MAP = 0f000h
BG2GFX = 00000h
BG2MAP = 02000h
BG3GFX = 0c000h
BG3MAP = 0d000h

CREDITGFX = 04000h
CREDITMAP = 06000h
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
SCROLL_YPOS = 13		; (0-15)
TOP_SPR	= Y1_TABLE-X1_TABLE	; # of sprites in top logo
BOT_SPR = Y1_TABLE2-X1_TABLE2	; # of sprites in bottom logo
STARS	= 21
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
cosangle	=	0400h
sinangle	=	cosangle+2
storage1	=	sinangle+2
storage2	=	storage1+2
storage3	=	storage2+2
cosangle2	=	storage3+2
sinangle2	=	cosangle2+2
starcosangle	=	sinangle2+2
starsinangle	=	starcosangle+2
stardirection	=	starsinangle+2
startoggle	=	stardirection+2
startoggle2	=	startoggle+2
atxsine		=	startoggle2+2
atxlogodelay	=	atxsine+2
linecounter	=	atxlogodelay+2
linedelay	=	linecounter+2
storage4	=	linedelay+2
signx		=	storage4+2
signy		=	signx+2
sign		=	signy+2
storage5	=	sign+2
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
RAM_SINE	=	0520h
X2_TABLE	=	RAM_SINE+(SINE_END-SINE)
Z2_TABLE	=	X2_TABLE+100h
STAR_XTABLE	=	Z2_TABLE+100h
STAR_XTABLE2	=	STAR_XTABLE+40h
STAR_YTABLE	=	STAR_XTABLE2+40h
STAR_YTABLE2	=	STAR_YTABLE+40h
STAR_ZTABLE	=	STAR_YTABLE2+40h
STAR_X2TABLE	=	STAR_ZTABLE+40h
STAR_Y2TABLE	=	STAR_X2TABLE+40h
RAM_BG1HOFS	=	STAR_Y2TABLE+40h
RAM_BG1SC	=	RAM_BG1HOFS+10
RAM_BG1VOFS	=	RAM_BG1SC+10
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
.zeropage
;/////////////////////////////////////////////////////////////////////////;


;-------------------------------------------------------------------------;
x1_ptr:	.res 3
x2_ptr:	.res 3
y1_ptr:	.res 3
z1_ptr:	.res 3
z2_ptr:	.res 3
shadow_hdmaen:
	.res 1
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
.code
;/////////////////////////////////////////////////////////////////////////;


;=========================================================================;
;       Code (c) 1995 -Pan-/ANTHROX   All code can be used at will!
;=========================================================================;
; Conversion to use direct page indirect indexed Y and other modifications
;                           by Augustus Blackheart
;-------------------------------------------------------------------------;


	.a8
	.i16


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
DoIntro:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	rep	#10h
	sep	#20h

	jsr	clear_vram

	DoDecompressDataVram gfx_scroll_goldTiles, BG2GFX
	DoDecompressDataVram gfx_ballsTiles, OAMGFX
	DoDecompressDataVram LOGO_GFX, BG1GFX
	DoDecompressDataVram gfx_bg3Tiles, BG3GFX
	DoDecompressDataVram gfx_creditsTiles, CREDITGFX

	lda	#SCROLL_YPOS
	xba
	lda	#^SCROLLTEXT
	ldx	#SCROLLTEXT
	ldy	#BG2MAP/2
	jsr	SetupBGScrollText

	rep	#30h

	lda	#(SINE_END-SINE)-1	; length
	pha
	ldx	#SINE			; source address
	phx
	ldy	#RAM_SINE		; destination address
	mvn	80h,^SINE		; bank dest, source
	;	^^--> sets DBR to this value

	plx
	pla
	ldy	#RAM_SINE+(SINE_END-SINE)
	mvn	80h,^SINE		; copy a 2nd time

	ldx	#BG3MAP/2+1c8h
	stx	REG_VMADDL

	ldx	#0000h
	txy				; y=0
	lda	#0
CopyWWWTiles:
	sta	REG_VMDATAL
	ina
	pha
	lda	#BG3_PRIO|10h		; priority and palette
	sta	REG_VMDATAH
	pla
	inx
	cpx	#13
	bne	CopyWWWTiles

	ldx	#CREDITMAP/2
	stx	REG_VMADDL
	tyx				; x=0
:	lda	CREDIT_TEXT,x
	and	#00ffh
	sec
	sbc	#0020h
	sta	REG_VMDATAL
	inx
	cpx	#32*14
	bne	:-
	phx

	tyx				; x=0
	lda	#60h
:	sta	REG_VMDATAL
	ina
	inx
	cpx	#0040h
	bne	:-

	ora	#0400h

:	sta	REG_VMDATAL
	ina
	inx
	cpx	#0080h
	bne	:-

	plx

:	lda	CREDIT_TEXT,x		; copy the rest of the credit tiles
	and	#00ffh
	sec
	sbc	#0020h
	sta	REG_VMDATAL
	inx
	cpx	#0400h-64
	bne	:-

	sep	#20h

	ldy	#BG1MAP/2-700h
	sty	REG_VMADDL
	lda	#PALETTE2		; palette
	ldx	#0000h			; starting tile
	ldy	#0100h/2		; max tile /2 w/ no high byte in map
	jsr	CopyLogoGfx

	ldy	#BG1MAP/2-600h
	sty	REG_VMADDL
	lda	#PALETTE3
					; no need to change starting tile
	ldy	#0200h/2		; max tile /2 w/ no high byte in map
	jsr	CopyLogoGfx

	ldy	#BG1MAP/2+100h
	sty	REG_VMADDL
	lda	#PALETTE2
	ldx	#0100h/2		; ''
	ldy	#0200h/2		; ''
	jsr	CopyLogoGfx

	ldy	#BG1MAP/2+200h
	sty	REG_VMADDL
	lda	#PALETTE3
	ldx	#0000h
	ldy	#0100h/2		; ''
	jsr	CopyLogoGfx

	; Palette
	DoCopyPalette LOGO_PAL, 32, 16
	DoCopyPalette gfx_logo_atxPal, 48, 16
	DoCopyPalette gfx_bg3Pal, 16, 4
	DoCopyPalette SPRITE_PAL, 128, 128
	DoCopyPalette gfx_scroll_goldPal, 0, 16

	; Sprites
	lda	#OBSEL_8_16|OBSEL_BASE(OAMGFX)|OBSEL_NN_8K
	sta	REG_OBSEL

	lda	#0f0h
	xba
	lda	#OAM_PRI3|OAM_PAL5

	ldx	#0000h
	txy
:	xba
	sta	oam_table,x
	inx
	sta	oam_table,x
	inx
	stz	oam_table,x
	inx
	xba
	sta	oam_table,x
	inx
	iny
	cpy	#TOP_SPR		; only top sprites are palette 5
	bne	:+

	and	#OAM_PRI3		; keep priority, clear palette bits
	bra	:-

:	cpx	#0200h
	bne	:--

	ldx	#0000h
:	stz	oam_hitable,x
	inx
	cpx	#0020h
	bne	:-

	jsr	SetupStars
	jsr	HDMA

	lda	#BGMODE_1
	sta	REG_BGMODE
	
	lda	#TM_OBJ|TM_BG3|TM_BG2|TM_BG1
	sta	REG_TM
	
	lda	#BG1GFX>>13
	sta	REG_BG12NBA

	lda	#BG3GFX>>13
	sta	REG_BG34NBA

	lda	#BG2MAP>>9|SC_64x32
	sta	REG_BG2SC

	lda	#BG3MAP>>9
	sta	REG_BG3SC

	lda	#03h
	sta	REG_BG2VOFS
	stz	REG_BG2VOFS

	lda	#0f9h
	sta	REG_BG3HOFS
	stz	REG_BG3HOFS

	ina
	sta	REG_BG3VOFS
	stz	REG_BG3VOFS

	ldx	#0001h
	stx	atxlogodelay
	dex	;0000h
	stx	stardirection
	stx	startoggle

	stx	sinangle
	stx	sinangle2
	stx	starsinangle

	dex	;00ffh
	stx	startoggle2

	ldx	#0040h
	stx	cosangle
	stx	cosangle2
	stx	starcosangle

	ldx	#00bfh
	stx	atxsine
	
	jsr	LogoMotion
	jsr	WaitVb

	lda	#NMI_ON|NMI_JOYPAD
	sta	REG_NMITIMEN

	cli

	lda	#1
	sta	frame_ready

	lda	#0fh
	sta	REG_INIDISP
;--------------------------------------------------------------------------;
WaitLoop:
;--------------------------------------------------------------------------;
	jsr	WaitVb
	jsr	BGScrollText
	jsr	LogoMotion
	jsr	BGScrollSquish
	jsr	Rotation1
	jsr	Rotation2
	jsr	TablePri
	jsr	TablePri2
	jsr	StarZ
	jsr	StarRotate
	jsr	StarRotToggle

	inc	cosangle
	inc	cosangle

	inc	sinangle
	inc	sinangle

	dec	cosangle2
	dec	cosangle2
	
	dec	sinangle2
	dec	sinangle2

	lda	joy1_down+1
	ora	joy2_down+1
	and	#JOYPADH_START
	beq	WaitLoop
;--------------------------------------------------------------------------;
EndTheIntro:
;--------------------------------------------------------------------------;
	stz	shadow_hdmaen
	stz	REG_HDMAEN
	jsr	WaitVb

	stz	REG_BG1HOFS
	stz	REG_BG1HOFS

	lda	#NMI_JOYPAD
	sta	REG_NMITIMEN

	DoCopyPalette gfx_creditsPal, 0, 16
	DoCopyPalette gfx_credits_redPal, 16, 16

	ldx	#RAM_BG1VOFS	; location to store hdma lines table
	jsr	SetupHDMALines

	lda	#BGMODE_1
	sta	REG_BGMODE
	lda	#CREDITGFX>>13
	sta	REG_BG12NBA
	lda	#CREDITMAP>>9
	sta	REG_BG1SC
	lda	#TM_BG1
	sta	REG_TM

	lda	#0fh
	sta	REG_INIDISP

WaitAgain:
	jsr	WaitVb
	jsr	HDMALines
	bne	WaitAgain

WaitAgain2:
	jsr	WaitVb	
	bra	WaitAgain2


;--------------------------------------------------------------------------;
;                               Logos Swinger
;==========================================================================;
LogoMotion:
;--------------------------------------------------------------------------;
	rep	#30h

	dec	atxlogodelay
	lda	atxlogodelay
	bne	skiplogomotion
;-------------------------------------------------------------------------;
logomotionok:
;-------------------------------------------------------------------------;
	lda	#01h
	sta	atxlogodelay

	ldx	atxsine
	lda	LOGO_SINE,x
	and	#00ffh
	sta	RAM_BG1HOFS+1
	txa
	lda	atxsine
	and	#00ffh
	cmp	#40h
	bne	logonoflip1
;-------------------------------------------------------------------------;
	lda	RAM_BG1SC+1
	eor	#08h
	sta	RAM_BG1SC+1
;-------------------------------------------------------------------------;
logonoflip1:
;-------------------------------------------------------------------------;
	lda	atxsine
	and	#00ffh
	eor	#00ffh
	tax
	lda	LOGO_SINE,x
	and	#00ffh
	clc
	adc	#0100h
	sta	RAM_BG1HOFS+4
	txa
	cmp	#0c0h
	bne	logonoflip2
;-------------------------------------------------------------------------;
	lda	RAM_BG1SC+3
	eor	#08h
	sta	RAM_BG1SC+3
;-------------------------------------------------------------------------;
logonoflip2:
;-------------------------------------------------------------------------;
	sep	#20h

	inc	atxsine
	lda	atxsine
	cmp	#0c0h
	bne	skiplogomotion
;-------------------------------------------------------------------------;
atxlogodelayon:
;-------------------------------------------------------------------------;
	rep	#30h

	lda	#01ffh
	sta	atxlogodelay
;-------------------------------------------------------------------------;
skiplogomotion:
;-------------------------------------------------------------------------;
	sep	#20h
	rts


;-------------------------------------------------------------------------;
;                      Calculate the Y rotation of ATX/SWAT logo
;=========================================================================;
Rotation1:
;=========================================================================;
	rep	#30h

	pea	Z2_TABLE
	pea	Z1_TABLE
	pea	X2_TABLE
	pea	X1_TABLE

	lda	#TOP_SPR
	ldx	cosangle
	ldy	sinangle
	bra	set_rot_ptr
;=========================================================================;
Rotation2:
;=========================================================================;
	rep	#30h

	pea	Z2_TABLE+TOP_SPR
	pea	Z1_TABLE2
	pea	X2_TABLE+TOP_SPR
	pea	X1_TABLE2

	lda	#BOT_SPR+1
	ldx	cosangle2
	ldy	sinangle2
;-------------------------------------------------------------------------;
set_rot_ptr:
;-------------------------------------------------------------------------;
	sty	m5
	stx	m6
	sta	m7	

	plx
	stx	x1_ptr
	plx
	stx	x2_ptr
	plx
	stx	z1_ptr
	plx
	stx	z2_ptr

	sep	#20h
;-------------------------------------------------------------------------;
rotation:
;-------------------------------------------------------------------------;
	ldy	#0000h
;-------------------------------------------------------------------------;
rotate:	lda	(x1_ptr),y
	stz	REG_M7A
	sta	REG_M7A

	ldx	m6		; cosangle
	lda	RAM_SINE,x
	sta	REG_M7B
	lda	REG_MPYH
	sta	storage1

	lda	(z1_ptr),y
	stz	REG_M7A
	sta	REG_M7A
	ldx	m5		; sinangle
	lda	RAM_SINE,x
	sta	REG_M7B
	lda	REG_MPYH
	sta	storage2

	lda	storage1
	sec
	sbc	storage2
	sta	(x2_ptr),y

	lda	(x1_ptr),y
	stz	REG_M7A
	sta	REG_M7A
	
	ldx	m5
	lda	RAM_SINE,x
	sta	REG_M7B
	lda	REG_MPYH
	sta	storage1

	lda	(z1_ptr),y
	stz	REG_M7A
	sta	REG_M7A
	ldx	m6
	lda	RAM_SINE,x
	sta	REG_M7B
	lda	REG_MPYH
	sta	storage2

	lda	storage1
	sec
	sbc	storage2
	sta	(z2_ptr),y

	iny
	cpy	m7
	bne	rotate
;-------------------------------------------------------------------------;
	rts


;-------------------------------------------------------------------------;
;                          Star Rotation Toggle
;=========================================================================;
StarRotToggle:
;=========================================================================;
	lda	startoggle
	bne	starroton
;-------------------------------------------------------------------------;
	dec	startoggle2
	lda	startoggle2
	bne	startrotoff
	lda	#0ffh
	sta	startoggle
	lda	stardirection
	eor	#0ffh
	sta	stardirection
;-------------------------------------------------------------------------;
startrotoff:
;-------------------------------------------------------------------------;
	rts
;-------------------------------------------------------------------------;
starroton:
;-------------------------------------------------------------------------;
	lda	#0ffh
	sta	startoggle2

	lda	stardirection
	beq	starcounter
;-------------------------------------------------------------------------;
	dec	starcosangle
	dec	starcosangle
	dec	starsinangle
	dec	starsinangle
	dec	startoggle
	rts
;-------------------------------------------------------------------------;
starcounter:
;-------------------------------------------------------------------------;
	inc	starcosangle
	inc	starcosangle
	inc	starsinangle
	inc	starsinangle

	dec	startoggle
;-------------------------------------------------------------------------;
	rts


;-------------------------------------------------------------------------;
;               Calculate Star Rotation and transfer 2 OAM
;=========================================================================;
StarRotate:
;=========================================================================;
	ldy	#0000h
	sty	storage3
	sty	storage4
;-------------------------------------------------------------------------;
rotate3:
;-------------------------------------------------------------------------;
	lda	STAR_X2TABLE,y
	stz	REG_M7A
	sta	REG_M7A

	ldx	starcosangle
	lda	RAM_SINE,x
	sta	REG_M7B

	rep	#30h

	lda	REG_MPYM
	sta	storage1

	sep	#20h

	lda	STAR_Y2TABLE,y
	stz	REG_M7A
	sta	REG_M7A
	ldx	starsinangle
	lda	RAM_SINE,x
	sta	REG_M7B

	rep	#30h

	lda	REG_MPYM
	sta	storage2

	lda	storage1
	sec
	sbc	storage2
	sta	storage2

	sep	#20h
;-------------------------------------------------------------------------;
signispos1:
;-------------------------------------------------------------------------;
	stz	signy
	lda	storage2+1
	phy
	ldy	storage3

	sec
	sbc	#80h
	sec
	sbc	#40h
	cmp	#78h
	bcc	signxok2
;-------------------------------------------------------------------------;
	lda	#01h
	sta	signy
;-------------------------------------------------------------------------;
signxok2:
;-------------------------------------------------------------------------;
	cmp	#08h
	bcs	signok3
;-------------------------------------------------------------------------;
	lda	#01h
	sta	signy
;-------------------------------------------------------------------------;
signok3:
;-------------------------------------------------------------------------;
	asl a
	bcc	signxok
;-------------------------------------------------------------------------;
	lda	#00h
;-------------------------------------------------------------------------;
signxok:
;-------------------------------------------------------------------------;
	sta	oam_table+100h,y
	inc	storage3
	ply

	lda	STAR_X2TABLE,y

	stz	REG_M7A
	sta	REG_M7A
	
	ldx	starsinangle
	lda	RAM_SINE,x
	sta	REG_M7B

	rep	#30h

	lda	REG_MPYM
	sta	storage1

	sep	#20h

	lda	STAR_Y2TABLE,y
	stz	REG_M7A
	sta	REG_M7A
	ldx	starcosangle
	lda	RAM_SINE,x
	sta	REG_M7B

	rep	#30h

	lda	REG_MPYM
	sta	storage2

	lda	storage1
	clc
	adc	storage2
	sta	storage2

	sep	#20h

	phy
	ldy	storage3

	lda	signy
	beq	signyok1
	lda	#0f5h
	bra	signyok
;-------------------------------------------------------------------------;
signyok1:
;-------------------------------------------------------------------------;
	lda	storage2+1

	clc
	adc	#80h
	eor	#0ffh
	sec
	sbc	#40h
	cmp	#70h
	bcc	signok2
;-------------------------------------------------------------------------;
	lda	#78h
;-------------------------------------------------------------------------;
signok2:
;-------------------------------------------------------------------------;
	cmp	#08h
	bcs	signyok3
;-------------------------------------------------------------------------;
	lda	#78h
;-------------------------------------------------------------------------;
signyok3:
;-------------------------------------------------------------------------;
	asl a
;-------------------------------------------------------------------------;
signyok:
;-------------------------------------------------------------------------;
	sta	oam_table+100h,y
	inc	storage3
	phx
	ldx	storage4
	lda	STAR_ZTABLE,x
	plx
	eor	#0ffh
	lsr a
	lsr a
	lsr a
	lsr a
	lsr a

	clc
	adc	#08h
	ldy	storage3
	sta	oam_table+100h,y
	inc	storage3
	inc	storage3

	ply

	lda	STAR_ZTABLE,y
	inc a
	inc a
	inc a
	bcs	resetstar
;-------------------------------------------------------------------------;
	sta	STAR_ZTABLE,y
;-------------------------------------------------------------------------;
noresetstar:
;-------------------------------------------------------------------------;
	inc	storage4
	iny
	cpy	#STARS
	beq	quitit3
	brl	rotate3
;-------------------------------------------------------------------------;
quitit3:
;-------------------------------------------------------------------------;
	rts
;-------------------------------------------------------------------------;
resetstar:
;-------------------------------------------------------------------------;
	lda	STAR_XTABLE,y
	sec
	sbc	#03h
	sta	STAR_XTABLE,y

	lda	STAR_YTABLE,y
	clc
	adc	#53h
	sta	STAR_XTABLE,y
	bra	noresetstar


;-------------------------------------------------------------------------;
;                      Star Z axis Routine
;=========================================================================;
StarZ:
;=========================================================================;
	ldx	#0000h
	txy
;-------------------------------------------------------------------------;	
star2oamrout:
;-------------------------------------------------------------------------;
	lda	STAR_XTABLE,x
	stz	REG_WRDIVL

	sta	storage1
	bpl	skipx122star
;-------------------------------------------------------------------------;
	eor	#0ffh
;-------------------------------------------------------------------------;
skipx122star:
;-------------------------------------------------------------------------;
	and	#7fh
	sta	REG_WRDIVH

	lda	STAR_ZTABLE,x
	eor	#0ffh
	sta	REG_WRDIVB

	lda	storage1
	and	#80h
	sta	storage1
	stz	storage3

	lda	storage1
	beq	skipx22star
;-------------------------------------------------------------------------;
	dec	storage3
;-------------------------------------------------------------------------;
skipx22star:
;-------------------------------------------------------------------------;
	lda	REG_RDDIVH
	beq	starxok			; is star off screen after division?
;-------------------------------------------------------------------------;
starxnotok:
;-------------------------------------------------------------------------;
	brl	staroutrange
;-------------------------------------------------------------------------;
starxok:
;-------------------------------------------------------------------------;
	lda	REG_RDDIVL
	bmi	starxnotok
;-------------------------------------------------------------------------;
	eor	storage3
	sta	STAR_X2TABLE,y
	lda	STAR_YTABLE,x
	stz	REG_WRDIVL
	sta	storage1
	bpl	skipy122star
;-------------------------------------------------------------------------;
	eor	#0ffh
;-------------------------------------------------------------------------;
skipy122star:
;-------------------------------------------------------------------------;
	and	#7fh
	sta	REG_WRDIVH

	lda	STAR_ZTABLE,x
	eor	#0ffh

	sta	REG_WRDIVB
	
	lda	storage1
	and	#80h
	sta	storage1

	stz	storage3

	lda	storage1
	beq	skipy22star
;-------------------------------------------------------------------------;
	dec	storage3
;-------------------------------------------------------------------------;
skipy22star:
;-------------------------------------------------------------------------;
	lda	REG_RDDIVH
	beq	staryok
;-------------------------------------------------------------------------;
starynotok:
;-------------------------------------------------------------------------;
	bra	staroutrange
;-------------------------------------------------------------------------;
staryok:
;-------------------------------------------------------------------------;
	lda	REG_RDDIVL
	bmi	starynotok
	eor	storage3
	sta	STAR_Y2TABLE,y
;-------------------------------------------------------------------------;
starcont:
;-------------------------------------------------------------------------;
	iny
	inx
	cpx	#STARS
	beq	star2oamend
	brl	star2oamrout
;-------------------------------------------------------------------------;
star2oamend:
;-------------------------------------------------------------------------;
	rts
;-------------------------------------------------------------------------;
staroutrange:
;-------------------------------------------------------------------------;
	lda	STAR_XTABLE,x
	clc
	adc	#03h
	sta	STAR_XTABLE,x

	lda	STAR_YTABLE,x
	clc
	adc	#53h
	sta	STAR_YTABLE,x

	stz	STAR_ZTABLE,x

	lda	#7fh
	sta	STAR_X2TABLE,y
	sta	STAR_Y2TABLE,y
	bra	starcont


;-------------------------------------------------------------------------;
;                 Convert X2 and Z2 table to OAM data
;=========================================================================;
TablePri2:
;=========================================================================;
	rep	#30h

	pea	TOP_SPR*4
	pea	BOT_SPR

	lda	#X2_TABLE+TOP_SPR
	ldx	#Y1_TABLE2
	ldy	#Z2_TABLE+TOP_SPR
	bra	_stptr
;=========================================================================;
TablePri:
;=========================================================================;
	rep	#30h

	pea	0000h
	pea	TOP_SPR

	lda	#X2_TABLE
	ldx	#Y1_TABLE
	ldy	#Z2_TABLE
;-------------------------------------------------------------------------;
_stptr:	sty	z2_ptr
	stx	y1_ptr
	sta	x2_ptr

	ply
	sty	m7
	plx

	sep	#20h

	lda	sinangle
	bpl	table2oam1
	brl	table2oam2
;-------------------------------------------------------------------------;
table2oam1:
;-------------------------------------------------------------------------;
	dey
;-------------------------------------------------------------------------;
transoam1:
;-------------------------------------------------------------------------;
	lda	(x2_ptr),y
	sta	storage1
	bpl	skipx11
	eor	#0ffh
;-------------------------------------------------------------------------;
skipx11:
;-------------------------------------------------------------------------;
	stz	REG_WRDIVL
	and	#7fh
	sta	REG_WRDIVH

	lda	(z2_ptr),y
	eor	#0ffh
	clc
	adc	#80h
	sta	REG_WRDIVB

	lda	storage1
	and	#80h
	sta	storage1
	stz	storage3
	lda	storage1
	beq	skipx1
;-------------------------------------------------------------------------;
	dec	storage3
;-------------------------------------------------------------------------;
skipx1:
;-------------------------------------------------------------------------;
	lda	REG_RDDIVL
	lsr a
	eor	storage3
	sec
	sbc	#80h
	sta	oam_table,x
	inx

	lda	(y1_ptr),y
	sta	storage1
	bpl	skipy11
;-------------------------------------------------------------------------;
	eor	#0ffh
;-------------------------------------------------------------------------;
skipy11:
;-------------------------------------------------------------------------;
	stz	REG_WRDIVL
	and	#7fh
	sta	REG_WRDIVH
	lda	(z2_ptr),y
	eor	#0ffh
	clc
	adc	#80h
	sta	REG_WRDIVB

	lda	storage1
	and	#80h
	sta	storage1
	stz	storage3

	lda	storage1
	beq	skipy1
;-------------------------------------------------------------------------;
	dec	storage3
;-------------------------------------------------------------------------;
skipy1:
;-------------------------------------------------------------------------;
	lda	REG_RDDIVL
	lsr a
	eor	storage3
	clc
	adc	#80h
	eor	#0ffh

	jsr	gety

	dey
	cpy	#0ffffh
	beq	endtransoam1
	brl	transoam1
;-------------------------------------------------------------------------;
endtransoam1:
;-------------------------------------------------------------------------;
	rts
;-------------------------------------------------------------------------;
table2oam2:
;-------------------------------------------------------------------------;
	ldy	#0000h
	ldx	m7
	cpx	#TOP_SPR
	bne	:+
;-------------------------------------------------------------------------;
	tyx
	bra	transoam2
;-------------------------------------------------------------------------;
:	ldx	#TOP_SPR*4
;-------------------------------------------------------------------------;
transoam2:
;-------------------------------------------------------------------------;
	lda	(x2_ptr),y
	sta	storage1
	bpl	skipx12
	eor	#0ffh
;-------------------------------------------------------------------------;
skipx12:
;-------------------------------------------------------------------------;
	stz	REG_WRDIVL
	and	#7fh
	sta	REG_WRDIVH

	lda	(z2_ptr),y
	eor	#0ffh
	clc
	adc	#80h
	sta	REG_WRDIVB

	lda	storage1
	and	#80h
	sta	storage1
	stz	storage3
	lda	storage1
	beq	skipx2
;-------------------------------------------------------------------------;
	dec	storage3
;-------------------------------------------------------------------------;
skipx2:
;-------------------------------------------------------------------------;
	lda	REG_RDDIVL
	lsr a
	eor	storage3
	sec
	sbc	#80h
	sta	oam_table,x
	inx
	lda	(y1_ptr),y
	sta	storage1
	bpl	skipy12
;-------------------------------------------------------------------------;
	eor	#0ffh
;-------------------------------------------------------------------------;
skipy12:
;-------------------------------------------------------------------------;
	stz	REG_WRDIVL
	and	#7fh
	sta	REG_WRDIVH

	lda	(z2_ptr),y
	eor	#0ffh
	clc
	adc	#80h
	sta	REG_WRDIVB

	lda	storage1
	and	#80h
	sta	storage1
	stz	storage3
	lda	storage1
	beq	skipy2
;-------------------------------------------------------------------------;
	dec	storage3
;-------------------------------------------------------------------------;
skipy2:
;-------------------------------------------------------------------------;
	jsr	gety

	iny
	cpy	m7
	beq	endtransoam2
	brl	transoam2
;-------------------------------------------------------------------------;
endtransoam2:
	rts
;-------------------------------------------------------------------------;
gety:
;-------------------------------------------------------------------------;
	lda	REG_RDDIVL
	lsr a
	eor	storage3
	clc
	adc	#80h
	eor	#0ffh

	phy

	ldy	m7
	cpy	#TOP_SPR
	bne	:+
;-------------------------------------------------------------------------;
	sec
	sbc	#5ch
	bra	_ply
;-------------------------------------------------------------------------;
:	clc
	adc	#2ch
;-------------------------------------------------------------------------;
_ply:	ply

	sta	oam_table,x
	inx
	lda	#01h
	sta	oam_table,x
	inx
	inx

	rts


;-------------------------------------------------------------------------;
;                         Wait For Vertical Blank
;=========================================================================;
WaitVb:
;=========================================================================;
	lda	REG_RDNMI
	bpl	WaitVb
:	lda	REG_RDNMI
	bmi	:-
	rts

;-------------------------------------------------------------------------;
;                           Start of HDMA routine
;=========================================================================;
HDMA:
;=========================================================================;
	rep	#10h
	sep	#20h

	ldx	#0000h
	txy
:	lda	LIST_BG1HOFS,x
	sta	RAM_BG1HOFS,x
	inx
	cpx	#0009h
	bne	:-

	tyx
:	lda	LIST_BG1SC,x
	sta	RAM_BG1SC,x
	inx
	cpx	#0006h
	bne	:-

	lda     #DMAP_XFER_MODE_2
	sta     REG_DMAP0       
	sta	REG_DMAP3
	sta	REG_DMAP4

	lda     #<REG_BG1HOFS
	sta     REG_BBAD0         
	ldx     #RAM_BG1HOFS
	stx     REG_A1T0L
	stz     REG_A1B0

	stz     REG_DMAP1         
	lda     #<REG_BG1SC
	sta     REG_BBAD1         
	ldx     #RAM_BG1SC
	stx     REG_A1T1L         
	stz     REG_A1B1

	stz	REG_DMAP2
	lda	#<REG_CGADD
	sta	REG_BBAD2
	ldx	#LIST_CGADD
	stx	REG_A1T2L
	stz	REG_A1B2

	lda	#<REG_CGDATA
	sta	REG_BBAD3
	ldx	#LIST_CGDATA
	stx	REG_A1T3L
	stz	REG_A1B3

	jsr	WaitVb
	lda	#%00001111
	ora	shadow_hdmaen
	sta	REG_HDMAEN
	rts


;=========================================================================;
;       	     SETUP ROUTINES FOR PROGRAM
;=========================================================================;


;=========================================================================;
CopyLogoGfx:
;=========================================================================;
	sta	m6
	sty	m7

:	lda	LOGO_MAP,x
	sta	REG_VMDATAL
	lda	m6
	sta	REG_VMDATAH
	inx
	;inx				; uncomment this if the map file
	cpx	m7			; includes high byte
	bne	:-

	rts


;-------------------------------------------------------------------------;
;                           Setup Star Tables
;=========================================================================;
SetupStars:
;=========================================================================;
	ldx	#0000h
	txy
setstars:
	lda	RANDOM_NUMBERS,x
	sta	STAR_XTABLE,x
	lda	RANDOM_NUMBERS+64,x
	sta	STAR_YTABLE,x
	lda	RANDOM_NUMBERS+128,x
	sta	STAR_ZTABLE,x
	inx
	cpx	#32
	bne	setstars

	tyx
starcolor:
	iny
	iny
	iny
	lda	RANDOM_NUMBERS,x
	lsr a
	lsr a
	and	#03h
	asl a
	sta	oam_table+100h,y
	iny
	inx
	cpy	#32
	bne	starcolor

	rts



;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
CREDIT_TEXT:
;=-=-=-=-=-=-=-=[12345678901234567890123456789012]-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	"    Call These ANTHROX Boards   "
	.byte	"                                "
	.byte	"  USS ENTERPRISE 1-412-233-0805 "
	.byte	"        SYSOP: PICARD           "
	.byte	"  TRADE LINE    +1-514-PRI-VATE "
	.byte	"        SYSOP: WILDFIRE         "
	.byte	"    DIAL HARD  ++41-7350-0155   "
	.byte	"        SYSOP: FURY             "
	.byte	" SMALL VEG PTCH  +44-1619452712 "
	.byte	"        SYSOP: MAD TURNIP       "
	.byte	"     SYNERGY   +49-PRI-VATE     "
	.byte	"        SYSOP: SIGMA-SEVEN      "
	.byte	"     VENGENCE  +61-PRI-VATE     "
	.byte	"        SYSOP: THE CAUSE        "
;
	.byte	"     Call These SWAT Boards     "
	.byte	"                                "
	.byte	" MECH RESISTENCE +1-310-PRI-VATE"
	.byte	"        SYSOP: MR GOODWRENCH    "
	.byte	" RESURRECTION  +44-PRI-VATE     "
	.byte	"        SYSOP: R2D2             "
	.byte	"  KODE ABODE II +1-TOO-PRI-VATE "
	.byte	"        SYSOP: DRUNKFUX         "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_BG1HOFS:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$6f,$00,$00,$4f,$00,$00
	.byte	0,0,0
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_BG1SC:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$6f,$71,$4f,$71,0,0
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_CGADD:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0
	.byte	1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0
	.byte	1,0,1,0,1,0,1,0,$70,0,$36,0

	.byte	1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0
	.byte	1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0
	.byte	1,0,1,0,1,0,1,0,1,0,0,0
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_CGDATA:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	1
	.word	$4DEC
	.byte	1
	.word	$49CB
	.byte	1
	.word	$49AA
	.byte	1
	.word	$4589
	.byte	1
	.word	$4168
	.byte	1
	.word	$4147
	.byte	1
	.word	$3D26
	.byte	1
	.word	$3906
	.byte	1
	.word	$38E5
	.byte	1
	.word	$34E4
	.byte	1
	.word	$34C4
	.byte	1
	.word	$30A3
	.byte	1
	.word	$2C83
	.byte	1
	.word	$2C82
	.byte	1
	.word	$2862
	.byte	1
	.word	$2862
	.byte	1
	.word	$2441
	.byte	1
	.word	$2021
	.byte	1
	.word	$2020	
	.byte	1
	.word	$1C00
	.byte	1
	.word	$1800
	.byte	1
	.word	$1400
	.byte	1
	.word	$1000
	.byte	1
	.word	$0C00
	.byte	1
	.word	$0800
	.byte	1
	.word	$0400
	.byte	1
	.word	$0000
	.byte	1
	.word	$0000 

	.byte	1
	.word	$0000 
	.byte	$70
	.word	$0000
	.byte	$36
	.word	$0000

	.byte	1
	.word	$0000
	.byte	1
	.word	$0000
	.byte	1
	.word	$0400
	.byte	1
	.word	$0800
	.byte	1
	.word	$0C00
	.byte	1
	.word	$1000
	.byte	1
	.word	$1400
	.byte	1
	.word	$1800
	.byte	1
	.word	$1C00
	.byte	1
	.word	$2020
	.byte	1
	.word	$2021
	.byte	1
	.word	$2441
	.byte	1
	.word	$2862
	.byte	1
	.word	$2C82
	.byte	1
	.word	$2C83
	.byte	1
	.word	$30A3
	.byte	1
	.word	$34C4
	.byte	1
	.word	$34E4
	.byte	1
	.word	$38E5
	.byte	1
	.word	$3906
	.byte	1
	.word	$3D26
	.byte	1
	.word	$4147
	.byte	1
	.word	$4168
	.byte	1
	.word	$4168
	.byte	1
	.word	$4589
	.byte	1
	.word	$49AA
	.byte	1
	.word	$49CB
	.byte	1
	.word	$4DEC 
 
	.byte	1
 
	.word	$0000
	.byte	0
	.word	0

	.byte	0
	.word	0


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LOGO_GFX:	.incbin	"../logo/gfx_logo_swat.img.bin"
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
		; since the high byte isn't being used it's been stripped
LOGO_MAP:	; from ../logo/gfx_logo_swat.map.bin
;=-=-=-=-=-=-=-=;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$01,$02,$03,$04,$05,$06,$07,$08
	.byte	$00,$09,$0a,$0b,$0c,$0d,$0e,$0f
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$10,$11,$12,$13,$14,$15,$16,$17
	.byte	$18,$19,$1a,$17,$1b,$1c,$1d,$1e
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$1f,$20,$21,$22,$23,$24,$25,$26
	.byte	$27,$28,$29,$2a,$00,$2b,$2c,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$2d,$2e,$2f,$30,$31,$32,$33,$34
	.byte	$35,$36,$37,$38,$00,$39,$3a,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$3b,$3c,$3d,$3e,$3f
	.byte	$40,$41,$42,$43,$44,$45,$46,$47
	.byte	$48,$49,$4a,$43,$4b,$4c,$4d,$4e
	.byte	$4f,$50,$51,$52,$53,$54,$00,$00
	.byte	$00,$00,$55,$56,$57,$58,$59,$5a
	.byte	$5b,$5c,$5d,$5e,$5f,$60,$61,$62
	.byte	$63,$58,$64,$65,$66,$67,$68,$69
	.byte	$6a,$6b,$6c,$6d,$6e,$6f,$00,$00
	.byte	$00,$00,$70,$71,$72,$73,$74,$75
	.byte	$76,$77,$00,$78,$79,$00,$7a,$7b
	.byte	$7c,$73,$7d,$7b,$7e,$7f,$80,$81
	.byte	$82,$77,$83,$84,$85,$86,$00,$00
	.byte	$00,$00,$87,$88,$89,$8a,$8b,$8c
	.byte	$8d,$8e,$00,$8f,$90,$00,$91,$8c
	.byte	$89,$8a,$91,$8c,$89,$8a,$92,$93
	.byte	$94,$34,$95,$96,$97,$98,$00,$00
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LOGO_PAL:	.incbin "../logo/gfx_logo_swat.pal.bin"
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LOGO_SINE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
 .byte  128,131,134,137,140,143,146,149,152,155,158,162,165,167,170
 .byte  173,176,179,182,185,188,190,193,196,198,201,203,206,208,211
 .byte  213,215,218,220,222,224,226,228,230,232,234,235,237,238,240
 .byte  241,243,244,245,246,248,249,250,250,251,252,253,253,254,254
 .byte  254,255,255,255,255,255,255,255,254,254,254,253,253,252,251
 .byte  250,250,249,248,246,245,244,243,241,240,238,237,235,234,232
 .byte  230,228,226,224,222,220,218,215,213,211,208,206,203,201,198
 .byte  196,193,190,188,185,182,179,176,173,170,167,165,162,158,155
 .byte  152,149,146,143,140,137,134,131,128,124,121,118,115,112,109
 .byte  106,103,100,97,93,90,88,85,82,79,76,73,70,67,65,62,59,57,54
 .byte  52,49,47,44,42,40,37,35,33,31,29,27,25,23,21,20,18,17,15,14
 .byte  12,11,10,9,7,6,5,5,4,3,2,2,1,1,1,0,0,0,0,0,0,0,1,1,1,2,2,3
 .byte  4,5,5,6,7,9,10,11,12,14,15,17,18,20,21,23,25,27,29,31,33,35
 .byte  37,40,42,44,47,49,52,54,57,59,62,65,67,70,73,76,79,82,85,88
 .byte  90,93,97,100,103,106,109,112,115,118,121,124
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
RANDOM_NUMBERS:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.word	$3AA7,$3ECB,$3A50,$9684,$6807,$6DBA,$0FA0,$C455
	.word	$722F,$3280,$630A,$A402,$244E,$3FF7,$FBB5,$83F4
	.word	$7210,$2165,$6688,$1248,$516B,$43BB,$E409,$656A
	.word	$7144,$7525,$C2AE,$E455,$B7A9,$9087,$5E33,$8C23
	.word	$072A,$33B1,$A61E,$1989,$E1AA,$FC54,$8A0B,$1722
	.word	$1FEE,$9226,$079B,$68D5,$1090,$FEC8,$3B4C,$10DA
	.word	$EF06,$A471,$46B7,$4D47,$1984,$3F3F,$FC58,$D0E2
	.word	$B601,$ECF3,$5647,$4113,$738B,$305F,$914A,$8665
	.word	$420B,$D45B,$8825,$F3B6,$F2C1,$ABEF,$96CA,$4BD7
	.word	$A1D4,$8D0C,$A6B1,$EF4C,$033E,$8FAF,$CE49,$4975
	.word	$72FD,$9552,$1366,$3FBE,$67F9,$61BF,$307C,$2B57
	.word	$0FBF,$05C1,$FAA3,$0E8E,$DA0D,$6BDA,$E101,$DF3D
	.word	$CBF2,$8C3A,$0D97,$BED5,$FAD5,$30D9,$361D,$9C81
	.word	$3C27,$5BBD,$45EE,$2C62,$8B21,$5424,$1976,$3D5B
	.word	$3778,$7599,$3EB8,$6A92,$3C30,$BF88,$2F27,$ABE4
	.word	$C50F,$256F,$15AF,$FB7C,$BF5C,$3407,$DCCE,$361A
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SCROLLTEXT:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte " -pan- is back! and another intro appears to the awaiting "
	.byte "masses of fans. this time it contains more 3d effects than"
	.byte " the previous intros            ",0
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SINE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$00,$03,$06,$09,$0c,$10,$13,$16
	.byte	$19,$1c,$1f,$22,$25,$28,$2b,$2e
	.byte	$30,$33,$36,$39,$3c,$3e,$41,$44
	.byte	$46,$49,$4b,$4e,$50,$53,$55,$57
	.byte	$5a,$5c,$5e,$60,$62,$64,$66,$68
	.byte	$69,$6b,$6d,$6e,$70,$71,$73,$74
	.byte	$75,$76,$77,$78,$79,$7a,$7b,$7c
	.byte	$7c,$7d,$7e,$7e,$7e,$7f,$7f,$7f
	.byte	$7f,$7f,$7f,$7f,$7e,$7e,$7e,$7d
	.byte	$7d,$7c,$7b,$7b,$7a,$79,$78,$77
	.byte	$76,$74,$73,$72,$70,$6f,$6d,$6c
	.byte	$6a,$68,$66,$65,$63,$61,$5f,$5d
	.byte	$5a,$58,$56,$54,$51,$4f,$4c,$4a
	.byte	$47,$45,$42,$3f,$3d,$3a,$37,$34
	.byte	$31,$2f,$2c,$29,$26,$23,$20,$1d
	.byte	$1a,$17,$14,$11,$0e,$0a,$07,$04
	.byte	$01,$fe,$fb,$f8,$f5,$f2,$ef,$eb
	.byte	$e8,$e5,$e2,$df,$dc,$d9,$d6,$d3
	.byte	$d1,$ce,$cb,$c8,$c5,$c3,$c0,$bd
	.byte	$bb,$b8,$b5,$b3,$b0,$ae,$ac,$a9
	.byte	$a7,$a5,$a3,$a1,$9f,$9d,$9b,$99
	.byte	$97,$95,$94,$92,$91,$8f,$8e,$8d
	.byte	$8b,$8a,$89,$88,$87,$86,$85,$84
	.byte	$84,$83,$83,$82,$82,$81,$81,$81
	.byte	$81,$81,$81,$81,$81,$82,$82,$83
	.byte	$83,$84,$84,$85,$86,$87,$88,$89
	.byte	$8a,$8b,$8c,$8e,$8f,$91,$92,$94
	.byte	$95,$97,$99,$9b,$9d,$9f,$a1,$a3
	.byte	$a5,$a7,$a9,$ac,$ae,$b0,$b3,$b5
	.byte	$b8,$ba,$bd,$c0,$c2,$c5,$c8,$cb
	.byte	$cd,$d0,$d3,$d6,$d9,$dc,$df,$e2
	.byte	$e5,$e8,$eb,$ee,$f1,$f4,$f8,$fb
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SINE_END:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;



;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SPRITE_PAL:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.word   $0000,$0816,$000E,$0006,$2918,$0014,$1058,$399A ; atx red
	.word   $000A,$1898,$0012,$315A,$20D8,$0006,$7FFF,$7FFF ; atx
	.word	$0000,$0204,$0142,$00C0,$030A,$0182,$0246,$038C ; green
	.word	$0100,$0288,$0182,$034A,$02C8,$00C0,$7FFC,$7FFC
	.word	$0000,$4080,$2840,$1800,$6140,$3880,$48C0,$7180 ; blue
	.word	$2000,$50C0,$3040,$6940,$5900,$1800,$7FFF,$7FFF ;
	.word	$0000,$4210,$294A,$18C6,$6318,$39CE,$4A52,$739C ; grey
	.word	$2108,$2108,$318C,$6B5A,$5AD6,$18C6,$7FFF,$7FFF ;
	.word	$0000,$4200,$2900,$1880,$6300,$3980,$4A40,$7380 ; cyan
	.word	$6300,$5280,$3140,$6B40,$5AC0,$1880,$7FFF,$7FFF ;
	.word   $0000,$4080,$2840,$1800,$6140,$3880,$48C0,$7180 ; swat blue
	.word   $2000,$50C0,$3040,$6940,$5900,$1800,$7FFF,$7FFF ; swat
	.word	$0000,$5ADC,$5A9A,$5218,$49D6,$4194,$3950,$30CE	; purple
	.word	$288C,$284A,$2048,$1808,$1806,$1006,$1004,$0804 ;
	.word	$0000,$5ADC,$529A,$4A9A,$3A98,$3256,$2A54,$1A12	; yellow
	.word	$1212,$09D0,$01CD,$018C,$018C,$014A,$0108,$00C6 ;
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
X1_TABLE:	;ATX
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte $c0,$f0,$00,$10,$28,$58
	.byte $b4,$cc,$00,$34,$4c
	.byte $b0,$c0,$d0,$00,$00,$40
	.byte $b0,$d0,$00,$34,$4c
	.byte $b0,$d0,$00,$28,$58
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
Y1_TABLE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte $10,$10,$10,$10,$10,$10
	.byte $08,$08,$08,$08,$08
	.byte $00,$00,$00,$00,$00,$00
	.byte $f8,$f8,$f8,$f8,$f8
	.byte $f0,$f0,$f0,$f0,$f0
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
Z1_TABLE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte $10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
X1_TABLE2:	;SWAT
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte $a0,$b0,$d0,$00,$30,$50,$60,$70
	.byte $90,$d0,$00,$24,$3c,$60
	.byte $a0,$d0,$e8,$00,$20,$30,$40,$60
	.byte $b0,$d0,$e0,$f0,$00,$20,$40,$60
	.byte $90,$a0,$d0,$00,$20,$40,$60
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
Y1_TABLE2:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $08,$08,$08,$08,$08,$08
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $f8,$f8,$f8,$f8,$f8,$f8,$f8,$f8
	.byte $f0,$f0,$f0,$f0,$f0,$f0,$f0
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
Z1_TABLE2:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10,$10
	.byte $10,$10,$10,$10,$10,$10,$10
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
