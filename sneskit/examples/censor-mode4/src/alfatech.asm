;-------------------------------------------------------------------------;
.include "copying.inc"
.include "graphics.inc"
.include "propack.inc"
.include "snes.inc"
.include "snes_decompress.inc"
.include "snes_zvars.inc"
.include "sprite_scroll32.inc"
;-------------------------------------------------------------------------;
.importzp frame_ready, joy1_down, joy2_down
;-------------------------------------------------------------------------;
.import oam_hitable, oam_table
;-------------------------------------------------------------------------;
.export DoMode4
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
MAX_BRIGHTNESS = 12	; 0-15
SCROLLTEXT_YPOS = 136
;-------------------------------------------------------------------------;

;-------------------------------------------------------------------------;
BG1GFX = 02000h
BG1MAP = 00000h
BG2GFX = 06000h
BG2MAP = 07000h
BG3MAP = 04200h
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
RAM_PAL_RED	=	0600h
RAM_PAL_GREEN	=	0700h
RAM_PAL_BLUE	=	0800h
RAM_CGDATA	=	0900h
RAM_BG2VOFS	=	0a00h
RAM_BG13HOFS	=	0b00h
RAM_BG1MAP	=	0d00h
RAM_FONT	=	7e8000h
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
.bss
;/////////////////////////////////////////////////////////////////////////;


;-------------------------------------------------------------------------;
fade_delay:
	.res 1
exit_flag:
	.res 1
inidisp:
	.res 1
;-[ BG2 ]-----------------------------------------------------------------;
bg2_list_index:
	.res 2
bg2vofs:
	.res 2
max_bg2vofs:
	.res 2
;-[ PALETTE ]-------------------------------------------------------------;
pal_index:
	.res 2
pal_index_start:
	.res 2
pal_sine1:
	.res 2
pal_sine2:
	.res 2
;-[ PLASMA ]--------------------------------------------------------------;
bg13hofs_lines:
	.res 2
bg13hofs_start_index:
	.res 2
bg13hofs_index:
	.res 2
bg13hofs_start_adc:
	.res 2
bg13hofs_adc:
	.res 2
bg1_start_index:
	.res 2
bg1_index:
	.res 2
;-------------------------------------------------------------------------;

tmp = inidisp



;/////////////////////////////////////////////////////////////////////////;
.code
;/////////////////////////////////////////////////////////////////////////;


;-------------------------------------------------------------------------;
	.a8
	.i16
;-------------------------------------------------------------------------;


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
DoMode4:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	rep	#10h
	sep	#20h

	lda	#80h
	sta	REG_INIDISP
	stz	REG_NMITIMEN

	sei

	DoDecompressPP FONT, RAM_FONT

	jsr	Setup

	lda	#0ffh
	sta	RAM_BG13HOFS

	DoDecompressDataVram gfx_censor_logoTiles, BG2GFX
	DoDecompressDataVram gfx_censor_logoMap, BG2MAP
	DoDecompressDataVram gfx_8x8_alfatech_fontTiles, BG2GFX+930h
	;DoCopyPalette SPRITE_PALETTE, 160, 80

	lda	#80h
	sta	REG_VMAIN

	ldx	#BG2MAP/2+200h
	stx	REG_VMADDL
	ldx	#0000h
:	lda	BG2_TEXT,x
	beq	:+
	clc
	adc	#73h		; ASCII: 20h = tile 93h, tile address 3498h
	sta	REG_VMDATAL
	lda	#BG_PRIO	; tile priority
	sta	REG_VMDATAH
	inx
	cpx	#0400h
	bne	:-
:

	lda	#SCROLLTEXT_YPOS	; ypos of scrolltext
	xba
	lda	#^SCROLLTEXT		; bank where scrolltext is located
	ldx	#SCROLLTEXT		; address where scrolltext is located
	ldy	#.loword(RAM_FONT)	; address where font is in bank 7eh

	jsr	SpriteScroll32Setup

	lda	#DMAP_XFER_MODE_2
	sta	REG_DMAP0
	sta	REG_DMAP1
	sta	REG_DMAP3
	lda	#<REG_BG1HOFS
	sta	REG_BBAD0
	ldx	#RAM_BG13HOFS
	stx	REG_A1T0L
	stz	REG_A1B0

	lda	#<REG_BG3HOFS
	sta	REG_BBAD1
	ldx	#RAM_BG13HOFS
	stx	REG_A1T1L
	stz	REG_A1B1

	lda	#DMAP_XFER_MODE_3
	sta	REG_DMAP2
	lda	#<REG_CGADD
	sta	REG_BBAD2
	ldx	#LIST_CGADD
	stx	REG_A1T2L
	stz	REG_A1B2

	lda	#<REG_BG2VOFS
	sta	REG_BBAD3
	ldx	#RAM_BG2VOFS
	stx	REG_A1T3L
	stz	REG_A1B3

	lda	#NMI_JOYPAD
	sta	REG_NMITIMEN

		; +----bg2vofs
		; |+---cgadd
		; ||+--bg3hofs
		; |||+-bg1hofs
	lda	#%1111
	sta	REG_HDMAEN
;=========================================================================;
Loopy:
;=========================================================================;
:	lda	REG_RDNMI
	bit	#80h
	bne	:-
:	lda	REG_RDNMI
	bit	#80h
	beq	:-
;-------------------------------------------------------------------------;
	lda	#160			; fix palette...does not appear
	sta	REG_CGADD		; to be needed on initial run*;
	lda	#DMAP_XFER_MODE_2	; however, it does fix palette
	sta	REG_DMAP4		; issues on reset
	lda	#<REG_CGDATA
	sta	REG_BBAD4		; * assuming palette has been
	ldx	#SPRITE_PALETTE		; loaded prior to this loop
	stx	REG_A1T4L
	stz	REG_A1B4
	ldx	#160
	stx	REG_DAS4L
	lda	#10h
	sta	REG_MDMAEN
	stz	REG_CGADD
	stz	REG_CGDATA
	stz	REG_CGDATA

	rep	#30h

	lda	bg1_start_index
	sec
	sbc	#0002h
	bpl	:+
;-------------------------------------------------------------------------;
	clc
	adc	#02d0h
	sta	bg1_start_index
;-------------------------------------------------------------------------;
:	sep	#20h

	jsr	TransferOAMGfxToVram
	jsr	PlasmaDMA
	jsr	SpriteScroll32

	lda	#20h
	sta	REG_CGADD
	lda	#DMAP_XFER_MODE_2
	sta	REG_DMAP4
	lda	#<REG_CGDATA
	sta	REG_BBAD4
	ldx	#RAM_CGDATA
	stx	REG_A1T4L
	stz	REG_A1B4
	ldx	#0100h
	stx	REG_DAS4L
	lda	#10h
	sta	REG_MDMAEN

	jsr	BG2Palette

	dec	fade_delay
	bne	Continue
;-------------------------------------------------------------------------;
	lda	#02h
	sta	fade_delay
	lda	exit_flag
	beq	FadeIn
;-------------------------------------------------------------------------;
	lda	inidisp
	beq	End
;-------------------------------------------------------------------------;
	dea
	bra	StoreBrightness
;-------------------------------------------------------------------------;
End:	
	stz	REG_TM
	stz	REG_HDMAEN

	jmp	DoMode4
;-------------------------------------------------------------------------;
FadeIn:	lda	inidisp
	cmp	#MAX_BRIGHTNESS
	beq	StoreBrightness
;-------------------------------------------------------------------------;
	ina
;-------------------------------------------------------------------------;
StoreBrightness:
;-------------------------------------------------------------------------;
	sta	inidisp
	sta	REG_INIDISP
;-------------------------------------------------------------------------;
Continue:
;-------------------------------------------------------------------------;
	rep	#30h

	lda	bg13hofs_start_index
	sta	bg13hofs_index
	lda	bg13hofs_start_adc
	sta	bg13hofs_adc

	ldx	#0000h
	stx	bg13hofs_lines
;-------------------------------------------------------------------------;
:	ldy	bg13hofs_index
	lda	BG13HOFS_SINE,y
	and	#00ffh
	ldy	bg13hofs_adc
	clc
	adc	LIST_BG13HOFS,y
	sta	RAM_BG13HOFS+01h,x
	inc	bg13hofs_index
	inc	bg13hofs_adc
	inc	bg13hofs_adc
	inx
	inx
	inc	bg13hofs_lines
	lda	bg13hofs_lines
	cmp	#7fh
	bne	:-
;-------------------------------------------------------------------------;
	sep	#20h

	lda	#0e1h
	sta	RAM_BG13HOFS+01h,x
	inx

	rep	#30h
;-------------------------------------------------------------------------;
:	ldy	bg13hofs_index
	lda	BG13HOFS_SINE,y
	and	#00ffh
	ldy	bg13hofs_adc
	clc
	adc	LIST_BG13HOFS,y
	sta	RAM_BG13HOFS+01h,x
	inc	bg13hofs_index
	inc	bg13hofs_adc
	inc	bg13hofs_adc
	inx
	inx
	inc	bg13hofs_lines
	lda	bg13hofs_lines
	cmp	#7fh+61h
	bne	:-
;-------------------------------------------------------------------------;
	stz	RAM_BG13HOFS+01h,x
	lda	bg13hofs_start_index
	clc
	adc	#0002h
	cmp	#00a9h
	bcc	:+
;-------------------------------------------------------------------------;
	lda	bg13hofs_start_index
	sec
	sbc	#00a9h
;-------------------------------------------------------------------------;
:	sta	bg13hofs_start_index
	lda	bg13hofs_start_adc
	sec
	sbc	#0006h
	bpl	:+
;-------------------------------------------------------------------------;
	lda	#01d6h
	clc
	adc	bg13hofs_start_adc
;-------------------------------------------------------------------------;
:	sta	bg13hofs_start_adc

	sep	#20h

	jsr	BG1Palette
	jsr	SpriteScroll32Attributes
	jsr	Plasma
	jsr	MoveBG2

	lda	REG_JOY1L
	and	#0f0h
	bne	:+
;-------------------------------------------------------------------------;
	lda	REG_JOY1H
	beq	:++
;-------------------------------------------------------------------------;
:	lda	#01h
	sta	exit_flag
;-------------------------------------------------------------------------;
:	jmp	Loopy


;=========================================================================;
BG1Palette:
;=========================================================================;
	sep	#30h

	ldx	pal_sine1
	lda	SINE_OF_DOOM,x
	and	#0feh
	tax
	ldy	#00h
;-------------------------------------------------------------------------;
:	lda	RAM_PAL_RED,x
	sta	RAM_CGDATA,y
	inx
	iny
	bne	:-
;-------------------------------------------------------------------------;
	ldx	pal_index_start
	and	#0feh
	tax
	stx	pal_index
	ldx	pal_sine2
	lda	SINE_OF_DOOM,x
	and	#0feh
	tax
	stx	pal_index+1
	ldy	#00h
;-------------------------------------------------------------------------;
:	lda	RAM_CGDATA,y
	ldx	pal_index
	ora	RAM_PAL_GREEN,x
	ldx	pal_index+1
	ora	RAM_PAL_BLUE,x
	sta	RAM_CGDATA,y
	lda	RAM_CGDATA+01h,y
	ora	RAM_PAL_BLUE+01h,x
	ldx	pal_index
	ora	RAM_PAL_GREEN+01h,x
	sta	RAM_CGDATA+01h,y
	inx
	inx
	stx	pal_index
	ldx	pal_index+1
	inx
	inx
	stx	pal_index+1
	iny
	iny
	bne	:-
;-------------------------------------------------------------------------;
	inc	pal_sine1
	inc	pal_index_start
	inc	pal_sine2

	rep	#10h

	rts


;=========================================================================;
BG2Palette:
;=========================================================================;
	lda	#01h
	sta	REG_CGADD
	lda	#21h
	sta	REG_M7A
	lda	#04h
	sta	REG_M7A
	lda	#18h
	sta	REG_M7B
	lda	REG_MPYL
	sta	REG_CGDATA
	lda	REG_MPYM
	sta	REG_CGDATA
	lda	#21h
	sta	REG_M7A
	lda	#04h
	sta	REG_M7A
	lda	#14h
	sta	REG_M7B
	lda	REG_MPYL
	sta	REG_CGDATA
	lda	REG_MPYM
	sta	REG_CGDATA

	rts


;=========================================================================;
MoveBG2:
;=========================================================================;
	ldx	#00ffh
	stx	bg2vofs
	lda	bg2_list_index
	clc
	adc	#40h
	sta	max_bg2vofs
	stz	max_bg2vofs+1
	ldx	bg2_list_index
	ldy	#0000h
	lda	#0ffh
	sta	RAM_BG2VOFS
;-------------------------------------------------------------------------;
:	lda	BG2_LINES,x
	sta	bg2vofs
;-------------------------------------------------------------------------;
:	lda	bg2vofs
	beq	:+
;-------------------------------------------------------------------------;
	dec	bg2vofs

	rep	#30h

	lda	bg2vofs+1
	sta	RAM_BG2VOFS+01h,y

	sep	#20h

	iny
	iny
	dec	bg2vofs+1
	bra	:-
;-------------------------------------------------------------------------;
:	inc	bg2vofs+1
	inx
	cpx	max_bg2vofs
	bne	:---
;-------------------------------------------------------------------------;
	tya
	lsr a
	clc
	adc	#80h
	sta	RAM_BG2VOFS
	lda	#40h
	sta	RAM_BG2VOFS+01h,y
	lda	#00h
	sta	RAM_BG2VOFS+02h,y
	sta	RAM_BG2VOFS+03h,y
	sta	RAM_BG2VOFS+04h,y
	inc	bg2_list_index
	lda	bg2_list_index
	cmp	#30h
	bne	:+
;-------------------------------------------------------------------------;
	stz	bg2_list_index
;-------------------------------------------------------------------------;
:	rts


;=========================================================================;
Plasma:
;=========================================================================;
	rep	#30h

	ldx	#BG3MAP/2-100h
	stx	REG_VMADDL
	lda	bg1_start_index
	sta	bg1_index
	ldx	#0000h
;-------------------------------------------------------------------------;
:	ldy	bg13hofs_index
	lda	BG13HOFS_SINE,y
	and	#00ffh
	ldy	bg1_index
	clc
	adc	LIST_BG1MAP,y
	eor	#0a000h
	sta	RAM_BG1MAP,x
	inc	bg13hofs_index
	lda	bg1_index
	clc
	adc	#0004h
	sta	bg1_index
	inx
	inx
	cpx	#0040h
	bne	:-
;-------------------------------------------------------------------------;
	dec	bg13hofs_index
	lda	bg1_index
	sec
	sbc	#0004h
	sta	bg1_index

	ldy	#BG3MAP/2+2ffh
	sty	REG_VMADDL
;-------------------------------------------------------------------------;
:	ldy	bg13hofs_index
	lda	BG13HOFS_SINE,y
	and	#00ffh
	ldy	bg1_index
	clc
	adc	LIST_BG1MAP,y
	ora	#0a000h
	sta	RAM_BG1MAP,x
	inc	bg13hofs_index
	lda	bg1_index
	clc
	adc	#0004h
	sta	bg1_index
	inx
	inx
	cpx	#006ah
	bne	:-
;-------------------------------------------------------------------------;
	sep	#20h
	rts


;=========================================================================;
PlasmaDMA:
;=========================================================================;
	ldx	#BG3MAP/2-100h
	stx	REG_VMADDL
	lda	#DMAP_XFER_MODE_1
	sta	REG_DMAP4
	lda	#<REG_VMDATA
	sta	REG_BBAD4
	ldx	#RAM_BG1MAP
	stx	REG_A1T4L
	stz	REG_A1B4
	ldx	#0040h
	stx	REG_DAS4L
	lda	#%10000
	sta	REG_MDMAEN

	ldx	#BG3MAP/2+2ffh
	stx	REG_VMADDL
	ldx	#RAM_BG1MAP+40h
	stx	REG_A1T4L
	ldx	#0040h
	stx	REG_DAS4L
	lda	#%10000
	sta	REG_MDMAEN

	rts


;=========================================================================;
Setup:
;=========================================================================;
	ldx	#0000h
	stx	REG_VMADDL
	txy

:	stz	REG_VMDATAL
	stz	REG_VMDATAH
	iny
	cpy	#8000h
	bne	:-
;-------------------------------------------------------------------------;
:	stz	REG_BG1HOFS,x
	stz	REG_BG1HOFS,x
	inx
	cpx	#0008h
	bne	:-

	lda	#BGMODE_4|BGMODE_PRIO
	sta	REG_BGMODE

	;lda	#BG1MAP>>9
	stz	REG_BG1SC
	lda	#BG2MAP>>9
	sta	REG_BG2SC
	lda	#BG3MAP>>9
	sta	REG_BG3SC

	lda	#BG2GFX>>9+BG1GFX>>13
	sta	REG_BG12NBA

	lda	#0feh
	sta	REG_BG2VOFS
	stz	REG_BG2VOFS
	lda	#0f7h
	sta	REG_BG2HOFS
	stz	REG_BG2HOFS

	lda	#TM_OBJ|TM_BG2|TM_BG1
	sta	REG_TM

	lda	#0e0h
	sta	REG_COLDATA
	lda	#02h
	sta	REG_CGSWSEL

	lda	#0c3h
	sta	REG_W12SEL
	stz	REG_W34SEL
	lda	#30h
	sta	REG_WOBJSEL
	lda	#08h
	sta	REG_WH0
	sta	REG_WH2
	lda	#0f9h
	sta	REG_WH1
	sta	REG_WH3
	stz	REG_WBGLOG

	lda	#TM_BG1
	sta	REG_TS
	sta	REG_TMW
	ora	#TM_BG2
	sta	REG_TSW
;-------------------------------------------------------------------------;
	lda	707fffh
	ina
	and	#01h
	sta	707fffh
	bne	:+

	lda	#%10000010
	bra	:++

:	lda	#%01000010
:	sta	REG_CGADSUB
;-------------------------------------------------------------------------;
	ldx	#BG1GFX/2
	stx	REG_VMADDL
	ldy	#0000h
	tyx

:	sty	REG_VMDATAL
	inx
	cpx	#0400h
	bne	:-
;-------------------------------------------------------------------------;
	ldx	#BG1MAP/2	; if you change BG1MAP uncomment this line
	;tyx			; and comment out this and update REG_BG1SC
	stx	REG_VMADDL	; accordingly
	lda	#00h
:	sta	REG_VMDATAL
	stz	REG_VMDATAH
	inx
	cpx	#BG1MAP/2+20h
	bne	:-

	ldx	#BG1MAP/2
	ina
	cmp	#10h
	bne	:-

	lda	#00h
	iny
	cpy	#2
	bne	:-
;-------------------------------------------------------------------------;
	ldx	#BG1GFX/2
	stx	REG_VMADDL
	lda	#20h
	sta	tmp
	ldx	#0000h
;-------------------------------------------------------------------------;
MakeBG1Graphics:
;-------------------------------------------------------------------------;
	ldy	#0000h
NoResY:	lda	tmp
	and	#01h
	beq	:+

	lda	#0ffh
	bra	:++

:	lda	#00h
:	sta	RAM_BG13HOFS,y
	lda	tmp
	and	#02h
	beq	:+

	lda	#0ffh
	bra	:++

:	lda	#00h
:	sta	RAM_BG13HOFS+01h,y
	lda	tmp
	and	#04h
	beq	:+

	lda	#0ffh
	bra	:++

:	lda	#00h
:	sta	RAM_BG13HOFS+10h,y
	lda	tmp
	and	#08h
	beq	:+

	lda	#0ffh
	bra	:++

:	lda	#00h
:	sta	RAM_BG13HOFS+11h,y
	lda	tmp
	and	#10h
	beq	:+

	lda	#0ffh
	bra	:++

:	lda	#00h
:	sta	RAM_BG13HOFS+20h,y
	lda	tmp
	and	#20h
	beq	:+

	lda	#0ffh
	bra	:++

:	lda	#00h
:	sta	RAM_BG13HOFS+21h,y
	lda	tmp
	and	#40h
	beq	:+

	lda	#0ffh
	bra	:++

:	lda	#00h
:	sta	RAM_BG13HOFS+30h,y
	lda	tmp
	and	#80h
	beq	:+

	lda	#0ffh
	bra	:++

:	lda	#00h
:	sta	RAM_BG13HOFS+31h,y
	inc	tmp
	iny
	iny
	cpy	#0010h
	beq	:+

	jmp	NoResY

:	ldy	#0000h
:	lda	RAM_BG13HOFS,y
	sta	REG_VMDATAL
	iny
	lda	RAM_BG13HOFS,y
	sta	REG_VMDATAH
	iny
	cpy	#0040h
	bne	:-

	inx
	cpx	#0010h
	beq	:+

	jmp	MakeBG1Graphics
;-------------------------------------------------------------------------;
:	ldx	#0000h
	txy
:	lda	#01h
	sta	REG_M7A
	stz	REG_M7A
	lda	BG1_COLOR,y
	sta	REG_M7B
	lda	REG_MPYL
	sta	RAM_PAL_RED,x
	lda	REG_MPYM
	sta	RAM_PAL_RED+01h,x

	lda	#20h
	sta	REG_M7A
	stz	REG_M7A
	lda	BG1_COLOR,y
	sta	REG_M7B
	lda	REG_MPYL
	sta	RAM_PAL_GREEN,x
	lda	REG_MPYM
	sta	RAM_PAL_GREEN+01h,x

	stz	REG_M7A
	lda	#04h
	sta	REG_M7A
	lda	BG1_COLOR,y
	sta	REG_M7B
	lda	REG_MPYL
	sta	RAM_PAL_BLUE,x
	lda	REG_MPYM
	sta	RAM_PAL_BLUE+01h,x
	inx
	inx
	iny
	cpy	#0080h
	bne	:-
;-------------------------------------------------------------------------;
	stz	inidisp
	stz	exit_flag
	lda	#04h
	sta	fade_delay

	ldx	#0000h
	stx	bg1_start_index
	stx	bg2_list_index
	stx	pal_index
	stx	pal_sine1

	ldx	#00d6h
	stx	bg13hofs_start_index
	ldx	#01d6h
	stx	bg13hofs_start_adc
	stx	bg13hofs_adc
	ldx	#005ch
	stx	pal_index_start
	ldx	#00b6h
	stx	pal_sine2

	jsr	BG1Palette

	rts


;/////////////////////////////////////////////////////////////////////////;
.code
;/////////////////////////////////////////////////////////////////////////;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
BG1_COLOR:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	00h,00h,01h,01h,02h,02h,03h,03h
	.byte	04h,04h,05h,05h,06h,06h,07h,07h
	.byte	08h,08h,09h,09h,0ah,0ah,0bh,0bh
	.byte	0ch,0ch,0dh,0dh,0eh,0eh,0fh,0fh
	.byte	10h,10h,11h,11h,12h,12h,13h,13h
	.byte	14h,14h,15h,15h,16h,16h,17h,17h
	.byte	18h,18h,19h,19h,1ah,1ah,1bh,1bh
	.byte	1ch,1ch,1dh,1dh,1eh,1eh,1fh,1fh
	.byte	1fh,1fh,1eh,1eh,1dh,1dh,1ch,1ch
	.byte	1bh,1bh,1ah,1ah,19h,19h,18h,18h
	.byte	17h,17h,16h,16h,15h,15h,14h,14h
	.byte	13h,13h,12h,12h,11h,11h,10h,10h
	.byte	0fh,0fh,0eh,0eh,0dh,0dh,0ch,0ch
	.byte	0bh,0bh,0ah,0ah,09h,09h,08h,08h
	.byte	07h,07h,06h,06h,05h,05h,04h,04h
	.byte	03h,03h,02h,02h,01h,01h,00h,00h
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
BG13HOFS_SINE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.word	1616h,1817h,1a19h,1b1ah,1d1ch,1e1dh,201fh,2120h
	.word	2222h,2423h,2524h,2626h,2727h,2828h,2928h,2a29h
	.word	2a2ah,2b2ah,2b2bh,2b2bh,2b2bh,2b2bh,2b2bh,2b2bh
	.word	2b2bh,2a2bh,2a2ah,2929h,2829h,2728h,2627h,2526h
	.word	2425h,2323h,2122h,2021h,1f1fh,1d1eh,1c1ch,1a1bh
	.word	1819h,1718h,1616h,1415h,1314h,1112h,1010h,0e0fh
	.word	0d0dh,0b0ch,0a0bh,0909h,0708h,0607h,0506h,0405h
	.word	0304h,0303h,0202h,0102h,0101h,0101h,0101h,0101h
	.word	0101h,0101h,0101h,0201h,0202h,0302h,0403h,0404h
	.word	0505h,0606h,0807h,0908h,0a0ah,0c0bh,0d0ch,0f0eh
	.word	100fh,1211h,1312h,1514h,1616h,1716h,1918h,1a1ah
	.word	1c1bh,1d1dh,1f1eh,2020h,2221h,2322h,2424h,2625h
	.word	2726h,2827h,2828h,2929h,2a2ah,2a2ah,2b2bh,2b2bh
	.word	2b2bh,2b2bh,2b2bh,2b2bh,2b2bh,2b2bh,2a2ah,292ah
	.word	2929h,2828h,2727h,2626h,2525h,2324h,2223h,2121h
	.word	1f20h,1e1fh,1c1dh,1b1ch,191ah,1818h,1617h,1516h
	.word	1414h,1213h,1011h,0f10h,0d0eh,0c0dh,0b0bh,090ah
	.word	0809h,0707h,0606h,0505h,0404h,0303h,0203h,0202h
	.word	0101h,0101h,0101h,0101h,0101h,0101h,0101h,0101h
	.word	0202h,0202h,0303h,0404h,0504h,0605h,0706h,0808h
	.word	0a09h,0b0ah,0c0ch,0e0dh,0f0fh,1110h,1212h,1413h
	.word	1615h,1616h,1817h,1a19h,1b1ah,1d1ch,1e1dh,201fh
	.word	2120h,2222h,2423h,2524h,2626h,2727h,2828h,2928h
	.word	2a29h,2a2ah,2b2ah,2b2bh,2b2bh,2b2bh,2b2bh,2b2bh
	.word	2b2bh,2b2bh,2a2bh,2a2ah,2929h,2829h,2728h,2627h
	.word	2526h,2425h,2323h,2122h,2021h,1f1fh,1d1eh,1c1ch
	.word	1a1bh,1819h,1718h,1616h,1415h,1314h,1112h,1010h
	.word	0e0fh,0d0dh,0b0ch,0a0bh,0909h,0708h,0607h,0506h
	.word	0405h,0304h,0303h,0202h,0102h,0101h,0101h,0101h
	.word	0101h,0101h,0101h,0101h,0201h,0202h,0302h,0403h
	.word	0404h,0505h,0606h,0807h,0908h,0a0ah,0c0bh,0d0ch
	.word	0f0eh,100fh,1211h,1312h,1514h,1716h
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
BG2_LINES:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	03h,02h,03h,02h,03h,02h,03h,02h
	.byte	03h,02h,02h,02h,02h,02h,01h,02h
	.byte	01h,01h,01h,01h,01h,01h,00h,00h
	.byte	01h,01h,00h,00h,01h,01h,01h,01h
	.byte	01h,01h,02h,01h,02h,02h,02h,02h
	.byte	02h,03h,02h,03h,02h,03h,02h,03h
	.byte	03h,02h,03h,02h,03h,02h,03h,02h
	.byte	03h,02h,02h,02h,02h,02h,01h,02h
	.byte	01h,01h,01h,01h,01h,01h,00h,00h
	.byte	01h,01h,00h,00h,01h,01h,01h,01h
	.byte	01h,01h,02h,01h,02h,02h,02h,02h
	.byte	02h,03h,02h,03h,02h,03h,02h,03h
	.byte	03h,02h,03h,02h,03h,02h,03h,02h
	.byte	03h,02h,02h,02h,02h,02h,01h,02h
	.byte	01h,01h,01h,01h,01h,01h,00h,00h
	.byte	01h,01h,00h,00h,01h,01h,01h,01h
	.byte	01h,01h,02h,01h,02h,02h,02h,02h
	.byte	02h,03h,02h,03h,02h,03h,02h,03h
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
BG2_TEXT:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	"      THE LIVING LEGEND       @@"
	.byte	"                              @@"
	.byte	"          PRESENTS:           @@"
	.byte	"                              @@"
	.byte	"  - ACME ANIMATION FACTORY -  @@"
	.byte	"          BY SUNSOFT          @@"
	.byte	"                              @@"
	.byte	" MUSICDRIVER BY ALFATECH/CEN  @@"
	.byte	"                CONQUEROR/QTX @@"
	.byte	"                              @@"
	.byte	"                      ALFATECH@@",0
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
FONT:	.incbin "../font/32x32.rnc"
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_BG1MAP:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.word	00c8h,00cbh,00ceh,00d2h,00d5h,00d9h,00dch,00e0h
	.word	00e3h,00e7h,00eah,00eeh,00f1h,00f5h,00f8h,00fbh
	.word	00ffh,0102h,0105h,0109h,010ch,010fh,0113h,0116h
	.word	0119h,011ch,011fh,0123h,0126h,0129h,012ch,012fh
	.word	0132h,0135h,0138h,013ah,013dh,0140h,0143h,0146h
	.word	0148h,014bh,014eh,0150h,0153h,0155h,0158h,015ah
	.word	015ch,015fh,0161h,0163h,0165h,0168h,016ah,016ch
	.word	016eh,0170h,0171h,0173h,0175h,0177h,0178h,017ah
	.word	017ch,017dh,017eh,0180h,0181h,0182h,0184h,0185h
	.word	0186h,0187h,0188h,0189h,018ah,018bh,018bh,018ch
	.word	018dh,018dh,018eh,018eh,018eh,018fh,018fh,018fh
	.word	018fh,018fh,018fh,018fh,018fh,018fh,018fh,018fh
	.word	018eh,018eh,018dh,018dh,018ch,018ch,018bh,018ah
	.word	0189h,0188h,0187h,0186h,0185h,0184h,0183h,0182h
	.word	0181h,017fh,017eh,017ch,017bh,0179h,0178h,0176h
	.word	0174h,0172h,0170h,016fh,016dh,016bh,0169h,0166h
	.word	0164h,0162h,0160h,015eh,015bh,0159h,0156h,0154h
	.word	0151h,014fh,014ch,014ah,0147h,0144h,0142h,013fh
	.word	013ch,0139h,0136h,0133h,0130h,012dh,012ah,0127h
	.word	0124h,0121h,011eh,011bh,0117h,0114h,0111h,010eh
	.word	010ah,0107h,0104h,0100h,00fdh,00fah,00f6h,00f3h
	.word	00efh,00ech,00e9h,00e5h,00e2h,00deh,00dbh,00d7h
	.word	00d4h,00d0h,00cdh,00c9h,00c7h,00c3h,00c0h,00bch
	.word	00b9h,00b5h,00b2h,00aeh,00abh,00a7h,00a4h,00a1h
	.word	009dh,009ah,0096h,0093h,0090h,008ch,0089h,0086h
	.word	0082h,007fh,007ch,0079h,0075h,0072h,006fh,006ch
	.word	0069h,0066h,0063h,0060h,005dh,005ah,0057h,0054h
	.word	0051h,004eh,004ch,0049h,0046h,0044h,0041h,003fh
	.word	003ch,003ah,0037h,0035h,0032h,0030h,002eh,002ch
	.word	002ah,0027h,0025h,0023h,0021h,0020h,001eh,001ch
	.word	001ah,0018h,0017h,0015h,0014h,0012h,0011h,000fh
	.word	000eh,000dh,000ch,000bh,000ah,0009h,0008h,0007h
	.word	0006h,0005h,0004h,0004h,0003h,0003h,0002h,0002h
	.word	0001h,0001h,0001h,0001h,0001h,0001h,0001h,0001h
	.word	0001h,0001h,0001h,0001h,0002h,0002h,0002h,0003h
	.word	0003h,0004h,0005h,0005h,0006h,0007h,0008h,0009h
	.word	000ah,000bh,000ch,000eh,000fh,0010h,0012h,0013h
	.word	0014h,0016h,0018h,0019h,001bh,001dh,001fh,0020h
	.word	0022h,0024h,0026h,0028h,002bh,002dh,002fh,0031h
	.word	0034h,0036h,0038h,003bh,003dh,0040h,0042h,0045h
	.word	0048h,004ah,004dh,0050h,0053h,0055h,0058h,005bh
	.word	005eh,0061h,0064h,0067h,006ah,006dh,0071h,0074h
	.word	0077h,007ah,007dh,0081h,0084h,0087h,008bh,008eh
	.word	0091h,0095h,0098h,009bh,009fh,00a2h,00a6h,00a9h
	.word	00adh,00b0h,00b4h,00b7h,00bah,00beh,00c1h,00c5h
	.word	00c8h,00cbh,00ceh,00d2h,00d5h,00d9h,00dch,00e0h
	.word	00e3h,00e7h,00eah,00eeh,00f1h,00f5h,00f8h,00fbh
	.word	00ffh,0102h,0105h,0109h,010ch,010fh,0113h,0116h
	.word	0119h,011ch,011fh,0123h,0126h,0129h,012ch,012fh
	.word	0132h,0135h,0138h,013ah,013dh,0140h,0143h,0146h
	.word	0148h,014bh,014eh,0150h,0153h,0155h,0158h,015ah
	.word	015ch,015fh,0161h,0163h,0165h,0168h,016ah,016ch
	.word	016eh,0170h,0171h,0173h,0175h,0177h,0178h,017ah
	.word	017ch,017dh,017eh,0180h,0181h,0182h,0184h,0185h
	.word	0186h,0187h,0188h,0189h,018ah,018bh,018bh,018ch
	.word	018dh,018dh,018eh,018eh,018eh,018fh,018fh,018fh
	.word	018fh,018fh,018fh,018fh,018fh,018fh,018fh,018fh
	.word	018eh,018eh,018dh,018dh,018ch,018ch,018bh,018ah
	;.word	0189h,0188h,0187h,0186h,0185h,0184h,0183h,0182h
	;.word	0181h,017fh,017eh,017ch,017bh,0179h,0178h,0176h
	;.word	0174h,0172h,0170h,016fh,016dh,016bh,0169h,0166h
	;.word	0164h,0162h,0160h,015eh,015bh,0159h,0156h,0154h
	;.word	0151h,014fh,014ch,014ah,0147h,0144h,0142h,013fh
	;.word	013ch,0139h,0136h,0133h,0130h,012dh,012ah,0127h
	;.word	0124h,0121h,011eh,011bh,0117h,0114h,0111h,010eh
	;.word	010ah,0107h,0104h,0100h,00fdh,00fah,00f6h,00f3h
	;.word	00efh,00ech,00e9h,00e5h,00e2h,00deh,00dbh,00d7h
	;.word	00d4h,00d0h,00cdh,00c9h,00c7h,00c3h,00c0h,00bch
	;.word	00b9h,00b5h,00b2h,00aeh,00abh,00a7h,00a4h,00a1h
	;.word	009dh,009ah,0096h,0093h,0090h,008ch,0089h,0086h
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_BG13HOFS:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.word	0041h,0042h,0044h,0046h,0047h,0049h,004bh,004dh
	.word	004eh,0050h,0052h,0053h,0055h,0057h,0058h,005ah
	.word	005bh,005dh,005fh,0060h,0062h,0063h,0065h,0066h
	.word	0067h,0069h,006ah,006bh,006dh,006eh,006fh,0070h
	.word	0072h,0073h,0074h,0075h,0076h,0077h,0078h,0079h
	.word	007ah,007ah,007bh,007ch,007dh,007dh,007eh,007eh
	.word	007fh,007fh,0080h,0080h,0080h,0081h,0081h,0081h
	.word	0081h,0081h,0081h,0081h,0081h,0081h,0081h,0081h
	.word	0081h,0081h,0080h,0080h,0080h,007fh,007fh,007eh
	.word	007dh,007dh,007ch,007bh,007bh,007ah,0079h,0078h
	.word	0077h,0076h,0075h,0074h,0073h,0072h,0071h,0070h
	.word	006fh,006dh,006ch,006bh,0069h,0068h,0067h,0065h
	.word	0064h,0062h,0061h,005fh,005eh,005ch,005bh,0059h
	.word	0057h,0056h,0054h,0053h,0051h,004fh,004dh,004ch
	.word	004ah,0048h,0047h,0045h,0043h,0041h,0041h,003fh
	.word	003dh,003bh,003ah,0038h,0036h,0035h,0033h,0031h
	.word	002fh,002eh,002ch,002bh,0029h,0027h,0026h,0024h
	.word	0023h,0021h,0020h,001eh,001dh,001bh,001ah,0019h
	.word	0017h,0016h,0015h,0013h,0012h,0011h,0010h,000fh
	.word	000eh,000dh,000ch,000bh,000ah,0009h,0008h,0007h
	.word	0007h,0006h,0005h,0005h,0004h,0003h,0003h,0002h
	.word	0002h,0002h,0001h,0001h,0001h,0001h,0001h,0001h
	.word	0001h,0001h,0001h,0001h,0001h,0001h,0001h,0002h
	.word	0002h,0002h,0003h,0003h,0004h,0004h,0005h,0005h
	.word	0006h,0007h,0008h,0008h,0009h,000ah,000bh,000ch
	.word	000dh,000eh,000fh,0010h,0012h,0013h,0014h,0015h
	.word	0017h,0018h,0019h,001bh,001ch,001dh,001fh,0020h
	.word	0022h,0023h,0025h,0027h,0028h,002ah,002bh,002dh
	.word	002fh,0030h,0032h,0034h,0035h,0037h,0039h,003bh
	.word	003ch,003eh,0040h,0041h,0042h,0044h,0046h,0047h
	.word	0049h,004bh,004dh,004eh,0050h,0052h,0053h,0055h
	.word	0057h,0058h,005ah,005bh,005dh,005fh,0060h,0062h
	.word	0063h,0065h,0066h,0067h,0069h,006ah,006bh,006dh
	.word	006eh,006fh,0070h,0072h,0073h,0074h,0075h,0076h
	.word	0077h,0078h,0079h,007ah,007ah,007bh,007ch,007dh
	.word	007dh,007eh,007eh,007fh,007fh,0080h,0080h,0080h
	.word	0081h,0081h,0081h,0081h,0081h,0081h,0081h,0081h
	.word	0081h,0081h,0081h,0081h,0081h,0080h,0080h,0080h
	.word	007fh,007fh,007eh,007dh,007dh,007ch,007bh,007bh
	.word	007ah,0079h,0078h,0077h,0076h,0075h,0074h,0073h
	.word	0072h,0071h,0070h,006fh,006dh,006ch,006bh,0069h
	.word	0068h,0067h,0065h,0064h,0062h,0061h,005fh,005eh
	.word	005ch,005bh,0059h,0057h,0056h,0054h,0053h,0051h
	.word	004fh,004dh,004ch,004ah,0048h,0047h,0045h,0043h
	.word	0041h,0041h,003fh,003dh,003bh,003ah,0038h,0036h
	.word	0035h,0033h,0031h,002fh,002eh,002ch,002bh,0029h
	.word	0027h,0026h,0024h,0023h,0021h,0020h,001eh,001dh
	.word	001bh,001ah,0019h,0017h,0016h,0015h,0013h,0012h
	.word	0011h,0010h,000fh,000eh,000dh,000ch,000bh,000ah
	.word	0009h,0008h,0007h,0007h,0006h,0005h,0005h,0004h
	.word	0003h,0003h,0002h,0002h,0002h,0001h,0001h,0001h
	.word	0001h,0001h,0001h,0001h,0001h,0001h,0001h,0001h
	.word	0001h,0001h,0002h,0002h,0002h,0003h,0003h,0004h
	.word	0004h,0005h,0005h,0006h,0007h,0008h,0008h,0009h
	.word	000ah,000bh,000ch,000dh,000eh,000fh,0010h,0012h
	.word	0013h,0014h,0015h,0017h,0018h,0019h,001bh,001ch
	.word	001dh,001fh,0020h,0022h,0023h,0025h,0027h,0028h
	.word	002ah,002bh,002dh,002fh,0030h,0032h,0034h,0035h
	.word	0037h,0039h,003bh,003ch,003eh,0040h,0041h,0042h
	.word	0044h,0046h,0047h,0049h,004bh,004dh,004eh,0050h
	.word	0052h,0053h,0055h,0057h,0058h,005ah,005bh,005dh
	.word	005fh,0060h,0062h,0063h,0065h,0066h,0067h,0069h
	.word	006ah,006bh,006dh,006eh,006fh,0070h,0072h,0073h
	.word	0074h,0075h,0076h,0077h,0078h,0079h,007ah,007ah
	.word	007bh,007ch,007dh,007dh,007eh,007eh,007fh,007fh
	.word	0080h,0080h,0080h,0081h,0081h,0081h,0081h,0081h
	.word	0081h,0081h,0081h,0081h,0081h,0081h,0081h,0081h
	.word	0080h,0080h,0080h,007fh,007fh,007eh,007dh,007dh
	.word	007ch,007bh,007bh,007ah,0079h,0078h,0077h,0076h
	.word	0075h,0074h,0073h,0072h,0071h,0070h,006fh,006dh
	.word	006ch,006bh,0069h,0068h,0067h,0065h,0064h,0062h
	.word	0061h,005fh,005eh,005ch,005bh,0059h,0057h,0056h
	.word	0054h,0053h,0051h,004fh,004dh,004ch,004ah,0048h
	.word	0047h,0045h,0043h,0041h,0041h,003fh,003dh,003bh
	.word	003ah,0038h,0036h,0035h,0033h,0031h,002fh,002eh
	.word	002ch,002bh,0029h,0027h,0026h,0024h,0023h,0021h
	.word	0020h,001eh,001dh,001bh,001ah,0019h,0017h,0016h
	.word	0015h,0013h,0012h,0011h,0010h,000fh,000eh,000dh
	.word	000ch,000bh,000ah,0009h,0008h,0007h,0007h,0006h
	.word	0005h,0005h,0004h,0003h,0003h,0002h,0002h,0002h
	.word	0001h,0001h,0001h,0001h,0001h,0001h,0001h,0001h
	.word	0001h,0001h,0001h,0001h,0001h,0002h,0002h,0002h
	.word	0003h,0003h,0004h,0004h,0005h,0005h,0006h,0007h
	.word	0008h,0008h,0009h,000ah,000bh,000ch,000dh,000eh
	.word	000fh,0010h,0012h,0013h,0014h,0015h,0017h,0018h
	.word	0019h,001bh,001ch,001dh,001fh,0020h,0022h,0023h
	.word	0025h,0027h,0028h,002ah,002bh,002dh,002fh,0030h
	.word	0032h,0034h,0035h,0037h,0039h,003bh,003ch,003eh
	.word	0040h
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_CGADD: 
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	7fh,03h,03h,10h,42h,08h,03h,03h
	.byte	08h,21h,00h,00h
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SCROLLTEXT:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	" we are back!  ..  bringing you "
	.byte	"another hot release  ..  we are "
	.byte	"looking for those who can contri"
	.byte	"bute .. contact us on our boards"
	.byte	" : wet dreams .or. streets of fi"
	.byte	"re .or. nuclear assault .. respe"
	.byte	"ct to : acc . atx . elt . fuck ."
	.byte	" ils . pdx . pr . qsr . re . snk"
	.byte	"  ..  censor says: .. until next"
	.byte	" time..!!                       "
	.byte	"           ",0
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SPRITE_PALETTE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.word	0000h,0046h,008ah,00ceh,0152h,01d6h,029ah,035eh
	.word	0000h,0000h,0000h,0000h,0000h,0000h,0000h,0000h
	.word	0000h,0011h,1091h,2113h,3195h,4637h,56b9h,6f7bh
	.word	0000h,0000h,0000h,0000h,0000h,0000h,0000h,0000h
	.word	0000h,2084h,28c6h,3908h,4d4ah,5d8ch,6dceh,7e31h
	.word	0000h,0000h,0000h,0000h,0000h,0000h,0000h,0000h
	.word	0000h,1806h,2008h,300ch,4411h,4c13h,5c17h,6c1bh
	.word	0000h,0000h,0000h,0000h,0000h,0000h,0000h,0000h
	.word	0000h,18c0h,2100h,3180h,39c0h,4e60h,56a0h,6720h
	.word	0000h,0000h,0000h,0000h,0000h,0000h,0000h,0000h
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;

