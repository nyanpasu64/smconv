;-------------------------------------------------------------------------;
.include "graphics.inc"
.include "snes.inc"
.include "snes_decompress.inc"
.include "snes_zvars.inc"
;-------------------------------------------------------------------------;
.importzp frame_ready, joy1_down, joy2_down
;-------------------------------------------------------------------------;
.import ASCIIMAP, clear_vram, oam_hitable, oam_table
;-------------------------------------------------------------------------;
.export DoDemoInt5
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
BG1_PAL1 = 1800h
BG3_PAL1 = 0ch|BG3_PRIO
BG3_PAL2 = 1ch|BG3_PRIO

MAX_LEVEL = 8
MAX_OPTIONS = 2		; max-1

BUBBLE_SPRITES = 12
TEXT_SPRITES = 12

SPRITE_BUBBLE_PROP = OAM_PRI2|OAM_PAL1
SPRITE_TEXT_PROP = OAM_PRI3|OAM_PAL3
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
BG1GFX = 04000h
BG1MAP = 00800h
BG2MAP = 01000h
BG3MAP = 01800h
BG3GFX = 02000h
OAMGFX = 0c000h
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
RAM_OPTIONS	=	0040h
RAM_200		=	0f00h
RAM_BG1_MASK	=	0800h
RAM_WH0		=	0c00h
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
current_option	= m6
vmadd		= m7
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
.bss
;/////////////////////////////////////////////////////////////////////////;


;-------------------------------------------------------------------------;
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
.code
;/////////////////////////////////////////////////////////////////////////;


;-------------------------------------------------------------------------;
	.a8
	.i16
;-------------------------------------------------------------------------;


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
DoDemoInt5:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	rep	#10h
	sep	#20h

	lda	#8fh
	sta	REG_INIDISP

	lda	#BGMODE_1|BGMODE_PRIO
	sta	REG_BGMODE

	lda	#BG1MAP>>9
	sta	REG_BG1SC
	lda	#BG2MAP>>9
	sta	REG_BG2SC
	stz	REG_BG3SC
	lda	#BG3MAP>>9
	sta	REG_BG4SC

	lda	#BG1GFX>>9+BG1GFX>>13
	sta	REG_BG12NBA
	lda	#BG3GFX>>9+BG3GFX>>13
	sta	REG_BG34NBA

	lda	#02h
	sta	REG_CGSWSEL
	lda	#3bh
	sta	REG_CGADSUB
	lda	#0e0h
	sta	REG_COLDATA

	lda	#TM_BG3|TM_BG2|TM_BG1
	sta	REG_TM
	lda	#TM_OBJ
	sta	REG_TS

	lda	#23h
	sta	REG_W12SEL
	lda	#TM_OBJ|TM_BG2|TM_BG1
	sta	REG_TMW

	lda	#03h
	sta	REG_BG1HOFS
	stz	REG_BG1HOFS
	sta	REG_BG1VOFS
	stz	REG_BG1VOFS

	ldx	#0060h
	stx	REG_VMADDL
	ldx	#0000h
;-------------------------------------------------------------------------;
:	lda	BG3_TEXT,x
	and	#3fh
	sta	REG_VMDATAL
	lda	#BG3_PAL1
	sta	REG_VMDATAH
	inx	
	cpx	#00e0h
	bne	:-
;-------------------------------------------------------------------------;
:	lda	BG3_TEXT,x
	and	#3fh
	sta	REG_VMDATAL
	lda	#BG3_PAL2
	sta	REG_VMDATAH
	inx	
	cpx	#0180h
	bne	:-
;-------------------------------------------------------------------------;
	DoCopyPalette gfx_logoPal, 48, 16
	DoCopyPalette gfx_8x8_fontPal, 12, 4
	DoCopyPalette gfx_8x8_darkPal, 28, 4
	DoCopyPalette gfx_bubblesPal, 144, 16
	DoCopyPalette gfx_16x16_fontPal, 176, 16
	DoDecompressDataVram gfx_8x8_fontTiles, BG3GFX
	DoDecompressDataVram gfx_16x16_fontTiles, OAMGFX
	DoDecompressDataVram gfx_logoTiles, BG1GFX
	DoDecompressDataVram gfx_logoMap, BG1MAP
	DoDecompressDataVram gfx_logoMap, BG2MAP

	lda	#OBSEL_16_32|OBSEL_BASE(OAMGFX)|OBSEL_NN_8K
	sta	REG_OBSEL

	lda	#10h
	ldx	#0000h
;-------------------------------------------------------------------------;
:	clc
	adc	#10h
	sta	oam_table,x
	xba
	inx
	lda	#0efh
	sta	oam_table,x
	inx
	stz	oam_table,x
	inx
	lda	#SPRITE_TEXT_PROP
	sta	oam_table,x
	xba
	inx
	cpx	#TEXT_SPRITES*4
	bne	:-

:	lda	#0ffh
	sta	oam_table,x
	inx	
	sta	oam_table,x
	inx	
	stz	oam_table,x
	inx	
	lda	#SPRITE_BUBBLE_PROP
	sta	oam_table,x
	inx	
	cpx	#(BUBBLE_SPRITES*4)+(TEXT_SPRITES*4)
	bne	:-

	lda	#0e0h
:	sta	oam_table,x
	inx
	sta	oam_table,x
	inx
	stz	oam_table,x
	inx
	stz	oam_table,x
	inx
	cpx	#0200h
	bne	:-

	ldx	#0000h
	lda	#%10101010
:	stz	oam_hitable,x
	inx
	cpx	#0003h
	bne	:-
:	sta	oam_hitable,x
	inx
	cpx	#0006h
	bne	:-
:	stz	oam_hitable,x
	inx
	cpx	#00020h
	bne	:-
;-------------------------------------------------------------------------;
	ldx	#0000h
	lda	#81h
;-------------------------------------------------------------------------;
:	sta	RAM_WH0,x
	stz	RAM_WH0+1,x
	stz	RAM_WH0+2,x
	inx	
	inx	
	inx	
	cpx	#0300h
	bne	:-
;-------------------------------------------------------------------------;
	stz	REG_HDMAEN

	lda	#DMAP_XFER_MODE_1
	sta	REG_DMAP0
	lda	#<REG_WH0
	sta	REG_BBAD0
	ldx	#RAM_WH0
	stx	REG_A1T0L
	stz	REG_A1B0

	stz	REG_DMAP1
	lda	#<REG_CGADD
	sta	REG_BBAD1
	ldx	#LIST_CGADD
	stx	REG_A1T1L
	lda	#^LIST_CGADD
	sta	REG_A1B1

	lda	#DMAP_XFER_MODE_2
	sta	REG_DMAP2
	lda	#<REG_CGDATA
	sta	REG_BBAD2
	ldx	#LIST_CGDATA
	stx	REG_A1T2L
	lda	#^LIST_CGDATA
	sta	REG_A1B2

	lda	#%111
	sta	REG_HDMAEN

	stz	RAM_200+02h
	ldx	#0000h
	stx	RAM_200
	stx	RAM_200+04h
	stx	RAM_200+06h
	stx	RAM_200+1ch
	stx	RAM_200+24h
	stx	RAM_200+16h
	stz	RAM_200+1eh

	lda	#VMAIN_INCH
	sta	REG_VMAIN

	ldx	#0123h
	stx	vmadd
	stz	current_option

	lda	#NMI_ON|NMI_JOYPAD
	sta	REG_NMITIMEN

	lda	#1
	sta	RAM_OPTIONS+04h
	sta	frame_ready

	jsr	GetText

	lda	#0fh
	sta	REG_INIDISP
;-------------------------------------------------------------------------;
MainLoop:
;-------------------------------------------------------------------------;
	lda	RAM_200+02h
	bne	:+
;-------------------------------------------------------------------------;
	jsr	Bubbles
;-------------------------------------------------------------------------;
:	dec	RAM_200+0ah
	bne	:+
;-------------------------------------------------------------------------;
	jsr	CopyBubbleSpritesToOAM
;-------------------------------------------------------------------------;
:	dec	RAM_200+02h
	ldy	#0000h
;-------------------------------------------------------------------------;
:	lda	RAM_WH0+03h,y
	sta	RAM_WH0,y
	iny	
	cpy	#02fdh
	bne	:-
;-------------------------------------------------------------------------;
	ldx	RAM_200
	lda	RAM_BG1_MASK,x
	inx	
	stx	RAM_200
	sta	RAM_WH0,y
	iny
	ldx	RAM_200
	lda	RAM_BG1_MASK,x
	inx	
	stx	RAM_200
	sta	RAM_WH0,y
	iny
	ldx	RAM_200
	lda	RAM_BG1_MASK,x
	inx	
	stx	RAM_200
	sta	RAM_WH0,y

	ldx	#0000h
;-------------------------------------------------------------------------;
:	lda	oam_table+(TEXT_SPRITES*4)+1,x
	cmp	#0e9h
	beq	:+
;-------------------------------------------------------------------------;
	dec	oam_table+(TEXT_SPRITES*4)+1,x
:	inx	
	inx	
	inx	
	inx	
	cpx	#TEXT_SPRITES*4
	bne	:--
;-------------------------------------------------------------------------;
:	lda	REG_RDNMI
	and	#80h
	beq	:-
;-------------------------------------------------------------------------;
	lda	REG_RDNMI

	lda	#8fh
	sta	REG_INIDISP

	jsr	MoveBG12HV
	jsr	MoveSpriteText

	lda	joy1_down+1
	ora	joy2_down+1
	lsr
	bcs	JoyDR
	lsr
	bcs	JoyDL
	lsr
	bcs	JoyDD
	lsr
	bcs	JoyDU
	lsr
	bcs	JoyStart
;-------------------------------------------------------------------------;
:	lda	#0fh
	sta	REG_INIDISP
	jmp	MainLoop
;-------------------------------------------------------------------------;
JoyDR:	jsr	IncreaseOption
	bra	:-
JoyDL:	jsr	DecreaseOption
	bra	:-
JoyDD:	jsr	OptionDown
	bra	:-
JoyDU:	jsr	OptionUp
	bra	:-
;-------------------------------------------------------------------------;
JoyStart:
;-------------------------------------------------------------------------;
	rep	#10h
	sep	#20h

	stz	frame_ready
	stz	REG_NMITIMEN
	stz	REG_HDMAEN

	lda	#80h
	sta	REG_INIDISP

	sei

	ldx	#0006h
:	lda	RAM_OPTIONS,x
	sta	700000h,x
	dex	
	bpl	:-

	;sep	#30h
	;lda	#00h
	;pla	
	;plb	
	;jmp	008000h

	jmp	DoDemoInt5

;=========================================================================;
OptionDown:
;=========================================================================;
	lda	current_option
	cmp	#MAX_OPTIONS*2
	beq	exit1

	inc	current_option
	inc	current_option

	ldx	vmadd
	stx	REG_VMADDL

	lda	#' '&3fh
	sta	REG_VMDATAL

	lda	#BG3_PAL2
	jsr	ChangeRowPalette

	lda	#BG3_PAL1
	sta	REG_VMDATAH

	rep	#30h

	lda	vmadd
	clc	
	adc	#0020h
	sta	vmadd
	tax	

	sep	#20h

	stx	REG_VMADDL
	lda	#'>'&3fh
	sta	REG_VMDATAL
	lda	#BG3_PAL1
;=========================================================================;
ChangeRowPalette:
;=========================================================================;
	ldx	#001ch
:	sta	REG_VMDATAH
	dex	
	bne	:-
exit1:	rts	
		
;=========================================================================;
OptionUp:
;=========================================================================;
	lda	current_option
	beq	exit1

	dec	current_option
	dec	current_option

	ldx	vmadd
	stx	REG_VMADDL
	lda	#' '&3fh
	sta	REG_VMDATAL

	lda	#BG3_PAL2
	jsr	ChangeRowPalette
	sta	REG_VMDATAH

	rep	#30h

	lda	vmadd
	sec	
	sbc	#0020h
	sta	vmadd
	tax	

	sep	#20h

	stx	REG_VMADDL
	lda	#'>'
	sta	REG_VMDATAL
	lda	#BG3_PAL1
	bra	ChangeRowPalette
		
;=========================================================================;
IncreaseOption:
;=========================================================================;
	sep	#30h

	ldx	current_option
	lda	OPTION_TYPE,x
	cmp	#01h
	bmi	SetYes
;-------------------------------------------------------------------------;
	lda	RAM_OPTIONS,x
	cmp	#MAX_LEVEL
	beq	exit2
;-------------------------------------------------------------------------;
	ina
	sta	RAM_OPTIONS,x

	rep	#30h

	lda	vmadd
	clc	
	adc	#0017h
	tax	

	sep	#20h

	stx	REG_VMADDL

	sep	#30h

	ldx	current_option
	lda	RAM_OPTIONS,x

	jsr	Hex2Dec

	txa	
	clc	
	adc	#30h
	sta	REG_VMDATAL
	lda	#BG3_PAL1
	sta	REG_VMDATAH
	tya	
	clc	
	adc	#30h
	sta	REG_VMDATAL
	lda	#BG3_PAL1
	sta	REG_VMDATAH

exit2:	rep	#10h
	sep	#20h
	rts	
		
;-------------------------------------------------------------------------;
SetYes:
;-------------------------------------------------------------------------;
	lda	#01h
	sta	RAM_OPTIONS,x

	rep	#30h

	lda	vmadd
	clc	
	adc	#0017h
	tax	

	sep	#20h

	stx	REG_VMADDL
	lda	#'Y'&3fh
	sta	REG_VMDATAL
	lda	#BG3_PAL1
	sta	REG_VMDATAH
	lda	#'E'&3fh
	sta	REG_VMDATAL
	lda	#BG3_PAL1
	sta	REG_VMDATAH
	lda	#'S'&3fh
	sta	REG_VMDATAL
	lda	#BG3_PAL1
	sta	REG_VMDATAH
	rts	
		

;=========================================================================;
DecreaseOption:
;=========================================================================;
	sep	#30h
	ldx	current_option
	lda	OPTION_TYPE,x
	cmp	#01h
	bmi	SetNo
;-------------------------------------------------------------------------;
	lda	RAM_OPTIONS,x
	cmp	#01h
	beq	exit2
;-------------------------------------------------------------------------;
	dea
	sta	RAM_OPTIONS,x

	rep	#30h

	lda	vmadd
	clc	
	adc	#0017h
	tax	

	sep	#20h

	stx	REG_VMADDL

	sep	#30h

	ldx	current_option
	lda	RAM_OPTIONS,x

	jsr	Hex2Dec

	txa	
	clc	
	adc	#30h
	sta	REG_VMDATAL
	lda	#BG3_PAL1
	sta	REG_VMDATAH
	tya	
	clc	
	adc	#30h
	sta	REG_VMDATAL
	lda	#BG3_PAL1
	sta	REG_VMDATAH

	rep	#10h
	sep	#20h
	rts	
;-------------------------------------------------------------------------;
SetNo:
;-------------------------------------------------------------------------;
	stz	RAM_OPTIONS,x

	rep	#30h

	lda	vmadd
	clc	
	adc	#0017h
	tax	

	sep	#20h

	stx	REG_VMADDL
	lda	#'N'&3fh
	sta	REG_VMDATAL
	lda	#BG3_PAL1
	sta	REG_VMDATAH
	lda	#'O'&3fh
	sta	REG_VMDATAL
	lda	#BG3_PAL1
	sta	REG_VMDATAH
	lda	#' '&3fh
	sta	REG_VMDATAL
	lda	#BG3_PAL1
	sta	REG_VMDATAH
	rts	
		
;=========================================================================;
Hex2Dec:
;=========================================================================;
	clc	
	ldx	#3800h
;-------------------------------------------------------------------------;
:	sbc	#0ah
	bcc	:+
;-------------------------------------------------------------------------;
	inx	
	bra	:-
;-------------------------------------------------------------------------;
:	clc	
	adc	#0ah
	tay	
	clc	
	rts	
		
;=========================================================================;
Bubbles:
;=========================================================================;
	lda	#18h
	sta	RAM_200+02h
	ldx	RAM_200+04h
	inx	
	cpx	#0014h
	bne	:+
;-------------------------------------------------------------------------;
	ldx	#0000h
;-------------------------------------------------------------------------;
:	stx	RAM_200+04h
	lda	BUBBLE_TILE,x
	sta	RAM_200+22h
	pha
	lda	BUBBLE_XPOS,x
	sta	RAM_200+20h
	ldx	#0000h
	stx	RAM_200
	txy
	pla
	cmp	#04h
	bne	cmp08
;-------------------------------------------------------------------------;
	ldx	#(004bh/3)*2		; /3 then *2 when using a 2 byte
	bra	:+			; list instead of a 3 byte list
;-------------------------------------------------------------------------;
cmp08:	cmp	#08h
	bne	cmp0c
;-------------------------------------------------------------------------;
	ldx	#(0096h/3)*2
	bra	:+
;-------------------------------------------------------------------------;
cmp0c:	cmp	#0ch
	bne	:+
;-------------------------------------------------------------------------;
	ldx	#(00e1h/3)*2
;-------------------------------------------------------------------------;
:	;lda	LIST_BG1_MASK,x		; if using orig 3 byte list use this
	lda	#81h			; remove this
	sta	RAM_BG1_MASK,y		;
	;inx				; and use this
	iny	
	lda	RAM_200+20h
	clc	
	adc	LIST_BG1_MASK,x
	sta	RAM_BG1_MASK,y
	inx	
	iny	
	lda	RAM_200+20h
	clc	
	adc	LIST_BG1_MASK,x
	sta	RAM_BG1_MASK,y
	inx	
	iny	
	cpy	#0048h
	bne	:-
;-------------------------------------------------------------------------;
	lda	#18h
	sta	RAM_200+0ah
	rts	

;=========================================================================;
CopyBubbleSpritesToOAM:
;=========================================================================;
	pha	
	ldx	RAM_200+06h
	cpx	#BUBBLE_SPRITES*4
	bne	:+
;-------------------------------------------------------------------------;
	ldx	#0000h
	stx	RAM_200+06h
;-------------------------------------------------------------------------;
:	lda	RAM_200+20h
	sta	oam_table+(TEXT_SPRITES*4),x
	inx
	lda	#232
	sta	oam_table+(TEXT_SPRITES*4),x
	inx
	lda	RAM_200+22h
	sta	oam_table+(TEXT_SPRITES*4),x
	inx	
	inx	
	stx	RAM_200+06h
	pla	
	rts	

		
;=========================================================================;
MoveBG12HV:
;=========================================================================;
	ldx	RAM_200+1ch
	lda	LIST_BG12VOFS,x
	sta	REG_BG1VOFS
	stz	REG_BG1VOFS
	sbc	#04h
	sta	REG_BG2VOFS
	stz	REG_BG2VOFS
	lda	RAM_200+1eh
	beq	:+
;-------------------------------------------------------------------------;
	lda	#0ffh
	sec	
	sbc	RAM_200+1ch
	dex	
	bne	bg12h
;-------------------------------------------------------------------------;
	stz	RAM_200+1eh
	bra	bg12h
;-------------------------------------------------------------------------;
:	lda	#00h
	sec	
	sbc	RAM_200+1ch
	inx	
	cpx	#(LIST_BG12VOFS_END-LIST_BG12VOFS)-1
	bne	bg12h
;-------------------------------------------------------------------------;
	pha	
	lda	#01h
	sta	RAM_200+1eh
	pla	
;-------------------------------------------------------------------------;
bg12h:	sta	REG_BG1HOFS
	stz	REG_BG1HOFS
	sbc	#04h
	sta	REG_BG2HOFS
	stz	REG_BG2HOFS
	stx	RAM_200+1ch
	rts	
		

;=========================================================================;
MoveSpriteText:
;=========================================================================;
	ldx	RAM_200+24h
	ldy	#0000h
;-------------------------------------------------------------------------;
:	lda	SPRITE_TEXT_YPOS,x
	sta	oam_table+1,y
	inx	
	iny	
	iny	
	iny	
	iny	
	cpy	#TEXT_SPRITES*4
	bne	:-
;-------------------------------------------------------------------------;
	cpx	#SPRITE_TEXT_YPOS_END-SPRITE_TEXT_YPOS
	bne	:+
;-------------------------------------------------------------------------;
	jsr	GetText

	ldx	#0000h
;-------------------------------------------------------------------------;
:	stx	RAM_200+24h
	rts	

;=========================================================================;
GetText:
;=========================================================================;
	ldx	#0000h
	ldy	RAM_200+16h
	lda	#TEXT_SPRITES
	sta	RAM_200+10h
;-------------------------------------------------------------------------;
:	lda	SPRITE_TEXT,y
	bne	:+
;-------------------------------------------------------------------------;
	ldy	#0000h
	sty	RAM_200+16h
	bra	:-
;-------------------------------------------------------------------------;
:	sec				; Skip ASCII printer codes/bubble
	sbc	#20h			; sprites

	phx

	rep	#30h

	and	#00ffh
	tax

	sep	#20h

	lda	ASCIIMAP,x
	plx
	sta	oam_table+2,x
	inx	
	inx	
	inx	
	inx	
	iny	
	dec	RAM_200+10h
	bne	:--
;-------------------------------------------------------------------------;
	sty	RAM_200+16h
	rts	
		

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
BG3_TEXT:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	"                                "
	.byte	"            TRAINED             "
	.byte	"                                "
	.byte	"           MAGIC BOY            "
	.byte	"                                "
	.byte	"                                "
	.byte	"   >SLOWROM FIX           NO    "
	.byte	"    UNLIMITED LIVES       NO    "
	.byte	"    START AT LEVEL        01    "
	.byte	"                                "
	.byte	"     USE PASSWORD MODE TO       "
	.byte	"    ACTIVATE THE LEVELSTART     "
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
BUBBLE_TILE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$00,$04,$08,$00,$08,$00,$04,$00
	.byte	$04,$00,$00,$08,$04,$00,$04,$00
	.byte	$00,$04,$00,$04
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
BUBBLE_XPOS:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$80,$1e,$50,$b4,$82,$d2,$0f,$5f
	.byte	$85,$22,$53,$c8,$32,$a0,$64,$14
	.byte	$dc,$2d,$5a,$ae
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_BG1_MASK:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$07,$0e,$05,$11
	.byte	$04,$12,$03,$13
	.byte	$02,$14,$01,$14
	.byte	$01,$14,$00,$15
	.byte	$00,$15,$00,$15
	.byte	$00,$15,$00,$15
	.byte	$00,$15,$00,$15
	.byte	$00,$15,$00,$15
	.byte	$00,$15,$01,$14
	.byte	$01,$14,$02,$13
	.byte	$03,$12,$04,$11
	.byte	$06,$0f,$08,$0d
	.byte	$81,$00,$03,$09
	.byte	$02,$0a,$01,$0b
	.byte	$00,$0c,$00,$0c
	.byte	$00,$0c,$00,$0c
	.byte	$00,$0c,$00,$0c
	.byte	$00,$0b,$01,$0b
	.byte	$02,$0a,$03,$08
	.byte	$02,$00,$02,$00
	.byte	$14,$14,$12,$16
	.byte	$11,$17,$11,$17
	.byte	$10,$17,$11,$17
	.byte	$11,$17,$12,$16
	.byte	$02,$00,$02,$00
	.byte	$03,$09,$02,$0a
	.byte	$01,$0b,$00,$0c
	.byte	$00,$0c,$00,$0c
	.byte	$00,$0c,$00,$0c
	.byte	$00,$0c,$00,$0b
	.byte	$01,$0b,$02,$0a
	.byte	$03,$08,$02,$00
	.byte	$02,$00,$02,$00
	.byte	$02,$00,$02,$00
	.byte	$02,$00,$02,$00
	.byte	$02,$00,$02,$00
	.byte	$02,$00,$02,$00
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_BG12VOFS:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$f6,$f7,$f8,$f9,$fa,$fb,$fc,$fc
	.byte	$fd,$fd,$fe,$fe,$fe,$fe,$fe,$fe
	.byte	$fe,$fe,$fe,$fe,$fd,$fd,$fc,$fc
	.byte	$fb,$fa,$f9,$f8,$f7,$f6,$f2,$f3
	.byte	$f4,$f6,$f7,$f8,$f9,$fa,$fb,$fb
	.byte	$fc,$fd,$fd,$fe,$fe,$fe,$fe,$fe
	.byte	$fe,$fe,$fe,$fe,$fe,$fd,$fd,$fc
	.byte	$fc,$fb,$fa,$fa,$f9,$f8,$f6,$f5
	.byte	$f4,$f3,$f2,$f4,$f5,$f6,$f7,$f8
	.byte	$f9,$fa,$fb,$fc,$fc,$fd,$fd,$fe
	.byte	$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe
	.byte	$fe,$fd,$fd,$fc,$fc,$fb,$fa,$f9
	.byte	$f8,$f7,$f6,$f5
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_BG12VOFS_END:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_CGADD:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$5e,$00,$01,$00,$01,$00,$01,$00
	.byte	$01,$00,$01,$00,$01,$00,$01,$00
	.byte	$01,$00,$01,$00,$01,$00,$01,$00
	.byte	$01,$00,$01,$00,$01,$00,$01,$00
	.byte	$01,$00,$01,$00,$01,$00,$01,$00
	.byte	$01,$00,$01,$00,$01,$00,$04,$00
	.byte	$04,$00,$04,$00,$04,$00,$04,$00
	.byte	$04,$00,$04,$00,$04,$00,$04,$00
	.byte	$04,$00,$04,$00,$04,$00,$04,$00
	.byte	$04,$00,$04,$00,$04,$00,$04,$00
	.byte	$04,$00,$04,$00,$04,$00,$04,$00
	.byte	$04,$00,$04,$00,$04,$00,$01,$00
	.byte	$00
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_CGDATA:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$5e
	.word	$0c00
	.byte	$01
	.word	$1000
	.byte	$01
	.word	$1400
	.byte	$01
	.word	$1800
	.byte	$01
	.word	$1c00
	.byte	$01
	.word	$2000
	.byte	$01
	.word	$2400
	.byte	$01
	.word	$2800
	.byte	$01
	.word	$2c00
	.byte	$01
	.word	$3000
	.byte	$01
	.word	$3400
	.byte	$01
	.word	$3800
	.byte	$01
	.word	$3c00
	.byte	$01
	.word	$4000
	.byte	$01
	.word	$4400
	.byte	$01
	.word	$4800
	.byte	$01
	.word	$4c00
	.byte	$01
	.word	$5000
	.byte	$01
	.word	$5400
	.byte	$01
	.word	$5800
	.byte	$01
	.word	$5c00
	.byte	$04
	.word	$6000
	.byte	$04
	.word	$5c00
	.byte	$04
	.word	$5800
	.byte	$04
	.word	$5400
	.byte	$04
	.word	$5000
	.byte	$04
	.word	$4c00
	.byte	$04
	.word	$4800
	.byte	$04
	.word	$4400
	.byte	$04
	.word	$4000
	.byte	$04
	.word	$3c00
	.byte	$04
	.word	$3800
	.byte	$04
	.word	$3400
	.byte	$04
	.word	$3000
	.byte	$04
	.word	$2c00
	.byte	$04
	.word	$2800
	.byte	$04
	.word	$2400
	.byte	$04
	.word	$2000
	.byte	$04
	.word	$1c00
	.byte	$04
	.word	$1800
	.byte	$04
	.word	$1400
	.byte	$04
	.word	$1000
	.byte	$04
	.word	$0c00
	.byte	$04
	.word	$0800
	.byte	$04
	.word	$0400
	.byte	$01
	.word	$0000
	.byte	$00
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
OPTION_TYPE:	; 0 = bool; anything else is the max number to be set
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$00,$00,$00,$00,$08,$08
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SPRITE_TEXT:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	"A RELEASE BY"
	.byte	"THE  ROMKIDS"
	.byte	" TRAINED BY "
	.byte	"     MCA    "
	.byte	"  INTRO BY  "
	.byte	"    DIZZY   "
	.byte	" THE DOCTOR "
	.byte	"DATA  BY    "
	.byte	"  LOWLIFE.  "
	.byte	"GREETINGS TO"
	.byte	"   ANTHROX  "
	.byte	"CORSAIR, DAX"
	.byte	"   VISION   "
	.byte	"  FAIRLIGHT "
	.byte	"   CENSOR   "
	.byte	"   LEGEND   "
	.byte	"  PREMIERE  "
	.byte	"   ROMKIDS  "
	.byte	"     RTS    "
	.byte	"    VISA    "
	.byte	" AND YOU... "
	.byte	"            ",0
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SPRITE_TEXT_YPOS:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef
	.byte	$ef,$ef,$ef,$ed,$ef,$ef,$ef,$ef
	.byte	$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef
	.byte	$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef
	.byte	$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef
	.byte	$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef
	.byte	$ed,$ef,$ef,$ef,$ef,$ef,$ef,$ef
	.byte	$ef,$ef,$ef,$ef,$ea,$ef,$ef,$ef
	.byte	$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef
	.byte	$e8,$ef,$ef,$ef,$ef,$ef,$ef,$ef
	.byte	$ef,$ef,$ef,$ef,$e5,$ef,$ef,$ef
	.byte	$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef
	.byte	$e3,$ed,$ef,$ef,$ef,$ef,$ef,$ef
	.byte	$ef,$ef,$ef,$ef,$e1,$ea,$ef,$ef
	.byte	$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef
	.byte	$de,$e8,$ef,$ef,$ef,$ef,$ef,$ef
	.byte	$ef,$ef,$ef,$ef,$db,$e5,$ef,$ef
	.byte	$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef
	.byte	$d9,$e3,$ed,$ef,$ef,$ef,$ef,$ef
	.byte	$ef,$ef,$ef,$ef,$d6,$e1,$ea,$ef
	.byte	$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef
	.byte	$d4,$de,$e8,$ef,$ef,$ef,$ef,$ef
	.byte	$ef,$ef,$ef,$ef,$d1,$db,$e5,$ef
	.byte	$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef
	.byte	$cf,$d9,$e3,$ed,$ef,$ef,$ef,$ef
	.byte	$ef,$ef,$ef,$ef,$cc,$d6,$e1,$ea
	.byte	$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef
	.byte	$c9,$d4,$de,$e8,$ef,$ef,$ef,$ef
	.byte	$ef,$ef,$ef,$ef,$c7,$d1,$db,$e5
	.byte	$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef
	.byte	$c4,$cf,$d9,$e3,$ed,$ef,$ef,$ef
	.byte	$ef,$ef,$ef,$ef,$c2,$cc,$d6,$e1
	.byte	$ea,$ef,$ef,$ef,$ef,$ef,$ef,$ef
	.byte	$bf,$c9,$d4,$de,$e8,$ef,$ef,$ef
	.byte	$ef,$ef,$ef,$ef,$bc,$c7,$d1,$db
	.byte	$e5,$ef,$ef,$ef,$ef,$ef,$ef,$ef
	.byte	$ba,$c4,$cf,$d9,$e3,$ed,$ef,$ef
	.byte	$ef,$ef,$ef,$ef,$b8,$c2,$cc,$d6
	.byte	$e1,$ea,$ef,$ef,$ef,$ef,$ef,$ef
	.byte	$b5,$bf,$c9,$d4,$de,$e8,$ef,$ef
	.byte	$ef,$ef,$ef,$ef,$b3,$bc,$c7,$d1
	.byte	$db,$e5,$ef,$ef,$ef,$ef,$ef,$ef
	.byte	$b1,$ba,$c4,$cf,$d9,$e3,$ed,$ef
	.byte	$ef,$ef,$ef,$ef,$ae,$b8,$c2,$cc
	.byte	$d6,$e1,$ea,$ef,$ef,$ef,$ef,$ef
	.byte	$ac,$b5,$bf,$c9,$d4,$de,$e8,$ef
	.byte	$ef,$ef,$ef,$ef,$aa,$b3,$bc,$c7
	.byte	$d1,$db,$e5,$ef,$ef,$ef,$ef,$ef
	.byte	$a8,$b1,$ba,$c4,$cf,$d9,$e3,$ed
	.byte	$ef,$ef,$ef,$ef,$a6,$ae,$b8,$c2
	.byte	$cc,$d6,$e1,$ea,$ef,$ef,$ef,$ef
	.byte	$a4,$ac,$b5,$bf,$c9,$d4,$de,$e8
	.byte	$ef,$ef,$ef,$ef,$a2,$aa,$b3,$bc
	.byte	$c7,$d1,$db,$e5,$ef,$ef,$ef,$ef
	.byte	$a1,$a8,$b1,$ba,$c4,$cf,$d9,$e3
	.byte	$ed,$ef,$ef,$ef,$9f,$a6,$ae,$b8
	.byte	$c2,$cc,$d6,$e1,$ea,$ef,$ef,$ef
	.byte	$9d,$a4,$ac,$b5,$bf,$c9,$d4,$de
	.byte	$e8,$ef,$ef,$ef,$9c,$a2,$aa,$b3
	.byte	$bc,$c7,$d1,$db,$e5,$ef,$ef,$ef
	.byte	$9b,$a1,$a8,$b1,$ba,$c4,$cf,$d9
	.byte	$e3,$ed,$ef,$ef,$99,$9f,$a6,$ae
	.byte	$b8,$c2,$cc,$d6,$e1,$ea,$ef,$ef
	.byte	$98,$9d,$a4,$ac,$b5,$bf,$c9,$d4
	.byte	$de,$e8,$ef,$ef,$97,$9c,$a2,$aa
	.byte	$b3,$bc,$c7,$d1,$db,$e5,$ef,$ef
	.byte	$96,$9b,$a1,$a8,$b1,$ba,$c4,$cf
	.byte	$d9,$e3,$ed,$ef,$95,$99,$9f,$a6
	.byte	$ae,$b8,$c2,$cc,$d6,$e1,$ea,$ef
	.byte	$95,$98,$9d,$a4,$ac,$b5,$bf,$c9
	.byte	$d4,$de,$e8,$ef,$94,$97,$9c,$a2
	.byte	$aa,$b3,$bc,$c7,$d1,$db,$e5,$ef
	.byte	$93,$96,$9b,$a1,$a8,$b1,$ba,$c4
	.byte	$cf,$d9,$e3,$ed,$93,$95,$99,$9f
	.byte	$a6,$ae,$b8,$c2,$cc,$d6,$e1,$ea
	.byte	$93,$95,$98,$9d,$a4,$ac,$b5,$bf
	.byte	$c9,$d4,$de,$e8,$93,$94,$97,$9c
	.byte	$a2,$aa,$b3,$bc,$c7,$d1,$db,$e5
	.byte	$93,$93,$96,$9b,$a1,$a8,$b1,$ba
	.byte	$c4,$cf,$d9,$e3,$93,$93,$95,$99
	.byte	$9f,$a6,$ae,$b8,$c2,$cc,$d6,$e1
	.byte	$93,$93,$95,$98,$9d,$a4,$ac,$b5
	.byte	$bf,$c9,$d4,$de,$93,$93,$94,$97
	.byte	$9c,$a2,$aa,$b3,$bc,$c7,$d1,$db
	.byte	$93,$93,$93,$96,$9b,$a1,$a8,$b1
	.byte	$ba,$c4,$cf,$d9,$94,$93,$93,$95
	.byte	$99,$9f,$a6,$ae,$b8,$c2,$cc,$d6
	.byte	$95,$93,$93,$95,$98,$9d,$a4,$ac
	.byte	$b5,$bf,$c9,$d4,$95,$93,$93,$94
	.byte	$97,$9c,$a2,$aa,$b3,$bc,$c7,$d1
	.byte	$96,$93,$93,$93,$96,$9b,$a1,$a8
	.byte	$b1,$ba,$c4,$cf,$97,$94,$93,$93
	.byte	$95,$99,$9f,$a6,$ae,$b8,$c2,$cc
	.byte	$98,$95,$93,$93,$95,$98,$9d,$a4
	.byte	$ac,$b5,$bf,$c9,$99,$95,$93,$93
	.byte	$94,$97,$9c,$a2,$aa,$b3,$bc,$c7
	.byte	$9b,$96,$93,$93,$93,$96,$9b,$a1
	.byte	$a8,$b1,$ba,$c4,$9c,$97,$94,$93
	.byte	$93,$95,$99,$9f,$a6,$ae,$b8,$c2
	.byte	$9d,$98,$95,$93,$93,$95,$98,$9d
	.byte	$a4,$ac,$b5,$bf,$9f,$99,$95,$93
	.byte	$93,$94,$97,$9c,$a2,$aa,$b3,$bc
	.byte	$a1,$9b,$96,$93,$93,$93,$96,$9b
	.byte	$a1,$a8,$b1,$ba,$a2,$9c,$97,$94
	.byte	$93,$93,$95,$99,$9f,$a6,$ae,$b8
	.byte	$a4,$9d,$98,$95,$93,$93,$95,$98
	.byte	$9d,$a4,$ac,$b5,$a6,$9f,$99,$95
	.byte	$93,$93,$94,$97,$9c,$a2,$aa,$b3
	.byte	$a8,$a1,$9b,$96,$93,$93,$93,$96
	.byte	$9b,$a1,$a8,$b1,$aa,$a2,$9c,$97
	.byte	$94,$93,$93,$95,$99,$9f,$a6,$ae
	.byte	$ac,$a4,$9d,$98,$95,$93,$93,$95
	.byte	$98,$9d,$a4,$ac,$ae,$a6,$9f,$99
	.byte	$95,$93,$93,$94,$97,$9c,$a2,$aa
	.byte	$b1,$a8,$a1,$9b,$96,$93,$93,$93
	.byte	$96,$9b,$a1,$a8,$b3,$aa,$a2,$9c
	.byte	$97,$94,$93,$93,$95,$99,$9f,$a6
	.byte	$b5,$ac,$a4,$9d,$98,$95,$93,$93
	.byte	$95,$98,$9d,$a4,$b8,$ae,$a6,$9f
	.byte	$99,$95,$93,$93,$94,$97,$9c,$a2
	.byte	$ba,$b1,$a8,$a1,$9b,$96,$93,$93
	.byte	$93,$96,$9b,$a1,$bc,$b3,$aa,$a2
	.byte	$9c,$97,$94,$93,$93,$95,$99,$9f
	.byte	$bf,$b5,$ac,$a4,$9d,$98,$95,$93
	.byte	$93,$95,$98,$9d,$c2,$b8,$ae,$a6
	.byte	$9f,$99,$95,$93,$93,$94,$97,$9c
	.byte	$c4,$ba,$b1,$a8,$a1,$9b,$96,$93
	.byte	$93,$93,$96,$9b,$c7,$bc,$b3,$aa
	.byte	$a2,$9c,$97,$94,$93,$93,$95,$99
	.byte	$c9,$bf,$b5,$ac,$a4,$9d,$98,$95
	.byte	$93,$93,$95,$98,$cc,$c2,$b8,$ae
	.byte	$a6,$9f,$99,$95,$93,$93,$94,$97
	.byte	$cf,$c4,$ba,$b1,$a8,$a1,$9b,$96
	.byte	$93,$93,$93,$96,$d1,$c7,$bc,$b3
	.byte	$aa,$a2,$9c,$97,$94,$93,$93,$95
	.byte	$d4,$c9,$bf,$b5,$ac,$a4,$9d,$98
	.byte	$95,$93,$93,$95,$d6,$cc,$c2,$b8
	.byte	$ae,$a6,$9f,$99,$95,$93,$93,$94
	.byte	$d9,$cf,$c4,$ba,$b1,$a8,$a1,$9b
	.byte	$96,$93,$93,$93,$db,$d1,$c7,$bc
	.byte	$b3,$aa,$a2,$9c,$97,$94,$93,$93
	.byte	$de,$d4,$c9,$bf,$b5,$ac,$a4,$9d
	.byte	$98,$95,$93,$93,$e1,$d6,$cc,$c2
	.byte	$b8,$ae,$a6,$9f,$99,$95,$93,$93
	.byte	$e3,$d9,$cf,$c4,$ba,$b1,$a8,$a1
	.byte	$9b,$96,$93,$93,$e5,$db,$d1,$c7
	.byte	$bc,$b3,$aa,$a2,$9c,$97,$94,$93
	.byte	$e8,$de,$d4,$c9,$bf,$b5,$ac,$a4
	.byte	$9d,$98,$95,$93,$ea,$e1,$d6,$cc
	.byte	$c2,$b8,$ae,$a6,$9f,$99,$95,$93
	.byte	$ed,$e3,$d9,$cf,$c4,$ba,$b1,$a8
	.byte	$a1,$9b,$96,$93,$ef,$e5,$db,$d1
	.byte	$c7,$bc,$b3,$aa,$a2,$9c,$97,$94
	.byte	$ef,$e8,$de,$d4,$c9,$bf,$b5,$ac
	.byte	$a4,$9d,$98,$95,$ef,$ea,$e1,$d6
	.byte	$cc,$c2,$b8,$ae,$a6,$9f,$99,$95
	.byte	$ef,$ed,$e3,$d9,$cf,$c4,$ba,$b1
	.byte	$a8,$a1,$9b,$96,$ef,$ef,$e5,$db
	.byte	$d1,$c7,$bc,$b3,$aa,$a2,$9c,$97
	.byte	$ef,$ef,$e8,$de,$d4,$c9,$bf,$b5
	.byte	$ac,$a4,$9d,$98,$ef,$ef,$ea,$e1
	.byte	$d6,$cc,$c2,$b8,$ae,$a6,$9f,$99
	.byte	$ef,$ef,$ed,$e3,$d9,$cf,$c4,$ba
	.byte	$b1,$a8,$a1,$9b,$ef,$ef,$ef,$e5
	.byte	$db,$d1,$c7,$bc,$b3,$aa,$a2,$9c
	.byte	$ef,$ef,$ef,$e8,$de,$d4,$c9,$bf
	.byte	$b5,$ac,$a4,$9d,$ef,$ef,$ef,$ea
	.byte	$e1,$d6,$cc,$c2,$b8,$ae,$a6,$9f
	.byte	$ef,$ef,$ef,$ed,$e3,$d9,$cf,$c4
	.byte	$ba,$b1,$a8,$a1,$ef,$ef,$ef,$ef
	.byte	$e5,$db,$d1,$c7,$bc,$b3,$aa,$a2
	.byte	$ef,$ef,$ef,$ef,$e8,$de,$d4,$c9
	.byte	$bf,$b5,$ac,$a4,$ef,$ef,$ef,$ef
	.byte	$ea,$e1,$d6,$cc,$c2,$b8,$ae,$a6
	.byte	$ef,$ef,$ef,$ef,$ed,$e3,$d9,$cf
	.byte	$c4,$ba,$b1,$a8,$ef,$ef,$ef,$ef
	.byte	$ef,$e5,$db,$d1,$c7,$bc,$b3,$aa
	.byte	$ef,$ef,$ef,$ef,$ef,$e8,$de,$d4
	.byte	$c9,$bf,$b5,$ac,$ef,$ef,$ef,$ef
	.byte	$ef,$ea,$e1,$d6,$cc,$c2,$b8,$ae
	.byte	$ef,$ef,$ef,$ef,$ef,$ed,$e3,$d9
	.byte	$cf,$c4,$ba,$b1,$ef,$ef,$ef,$ef
	.byte	$ef,$ef,$e5,$db,$d1,$c7,$bc,$b3
	.byte	$ef,$ef,$ef,$ef,$ef,$ef,$e8,$de
	.byte	$d4,$c9,$bf,$b5,$ef,$ef,$ef,$ef
	.byte	$ef,$ef,$ea,$e1,$d6,$cc,$c2,$b8
	.byte	$ef,$ef,$ef,$ef,$ef,$ef,$ed,$e3
	.byte	$d9,$cf,$c4,$ba,$ef,$ef,$ef,$ef
	.byte	$ef,$ef,$ef,$e5,$db,$d1,$c7,$bc
	.byte	$ef,$ef,$ef,$ef,$ef,$ef,$ef,$e8
	.byte	$de,$d4,$c9,$bf,$ef,$ef,$ef,$ef
	.byte	$ef,$ef,$ef,$ea,$e1,$d6,$cc,$c2
	.byte	$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ed
	.byte	$e3,$d9,$cf,$c4,$ef,$ef,$ef,$ef
	.byte	$ef,$ef,$ef,$ef,$e5,$db,$d1,$c7
	.byte	$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef
	.byte	$e8,$de,$d4,$c9,$ef,$ef,$ef,$ef
	.byte	$ef,$ef,$ef,$ef,$ea,$e1,$d6,$cc
	.byte	$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef
	.byte	$ed,$e3,$d9,$cf,$ef,$ef,$ef,$ef
	.byte	$ef,$ef,$ef,$ef,$ef,$e5,$db,$d1
	.byte	$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef
	.byte	$ef,$e8,$de,$d4,$ef,$ef,$ef,$ef
	.byte	$ef,$ef,$ef,$ef,$ef,$ea,$e1,$d6
	.byte	$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef
	.byte	$ef,$ed,$e3,$d9,$ef,$ef,$ef,$ef
	.byte	$ef,$ef,$ef,$ef,$ef,$ef,$e5,$db
	.byte	$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef
	.byte	$ef,$ef,$e8,$de,$ef,$ef,$ef,$ef
	.byte	$ef,$ef,$ef,$ef,$ef,$ef,$ea,$e1
	.byte	$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef
	.byte	$ef,$ef,$ed,$e3,$ef,$ef,$ef,$ef
	.byte	$ef,$ef,$ef,$ef,$ef,$ef,$ef,$e5
	.byte	$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef
	.byte	$ef,$ef,$ef,$e8,$ef,$ef,$ef,$ef
	.byte	$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ea
	.byte	$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef
	.byte	$ef,$ef,$ef,$ed,$ef,$ef,$ef,$ef
	.byte	$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef
	.byte	$ef,$ef,$ef,$ef,$ef,$ef,$ef,$ef
	.byte	$ef,$ef,$ef,$ef
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SPRITE_TEXT_YPOS_END:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;

