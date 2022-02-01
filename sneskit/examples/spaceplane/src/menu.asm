;-------------------------------------------------------------------------;
.include "fade.inc"
.include "graphics.inc"
.include "menu.inc"
.include "nmi.inc"
.include "oam.inc"
.include "options.inc"
.include "plasma.inc"
.include "reset.inc"
.include "shadow_ram.inc"
.include "snes.inc"
.include "snes_decompress.inc"
.include "snes_init.inc"
.include "snes_joypad.inc"
.include "snes_zvars.inc"
.include "spaceplane.inc"
;-------------------------------------------------------------------------;
.import DoPlasmaMap, clear_palette
.import waitvb
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
RAM_HDMA = 0500h
RAM_TM = RAM_HDMA+(LIST_BG1HOFS_END-LIST_BG1HOFS)

BG12VOFS = 0c2h
BG1GFX = 08000h
BG1MAP = 00000h
BG2GFX = 04000h
BG2MAP = 00800h
OAMGFX = 0c000h
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
addr_tm = m5	; w
tm = m6		; w
mosaic = m7+1
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
.zeropage
;/////////////////////////////////////////////////////////////////////////;


;-------------------------------------------------------------------------;
max_sprites:
	.res	2
row_index:
	.res	1
selection:
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
DoMenu:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	rep	#10h
	sep     #20h			; Accumulator ->  8 bit mode

	jsr	ResetReg

	DoDecompressDataVram gfx_menu1Tiles, BG1GFX
	DoDecompressDataVram gfx_menu1Map, BG1MAP

	DoDecompressDataVram gfx_menu1Tiles, BG2GFX
	DoDecompressDataVram gfx_menu1Map, BG2MAP

	DoCopyPalette gfx_menu1Pal, 0, 16
	DoCopyPalette gfx_menu2Pal, 16, 16

	lda	#BGMODE_1
	sta	REG_BGMODE

	lda	#BG2MAP>>9
	sta	REG_BG2SC

	lda	#(BG2GFX>>9)+(BG1GFX>>13)
	sta	REG_BG12NBA

	lda	#BG12VOFS
	sta	REG_BG1VOFS
	stz	REG_BG1VOFS
	sta	REG_BG2VOFS
	stz	REG_BG2VOFS

	lda	#CGADSUB_HALF|CGADSUB_BACK|CGADSUB_BG1
	sta	REG_CGADSUB

	lda	#VMAIN_INCH
	sta	REG_VMAIN

	ldx	#BG2MAP/2
	stx	REG_VMADDL

	lda	#PALETTE1
	ldx	#0000h
:	sta	REG_VMDATAH
	inx
	cpx	#0400h
	bne	:-

	rep	#30h

	lda	#LIST_TM_END-LIST_BG1HOFS
	ldx	#LIST_BG1HOFS
	ldy	#RAM_HDMA
	sty	REG_A1T0L
	sty	REG_A1T1L

	mvn	80h,^LIST_BG1HOFS

	sep	#20h

	lda	#DMAP_XFER_MODE_2
	sta	REG_DMAP0
	sta	REG_DMAP1
	dea
	sta	REG_DMAP2

	lda	#<REG_BG1HOFS
	sta	REG_BBAD0
	lda	#<REG_BG2HOFS
	sta	REG_BBAD1
	stz	REG_A1B0
	stz	REG_A1B1

	lda	#<REG_TM
	sta	REG_BBAD2
	ldx	#RAM_HDMA+(LIST_TM-HDMA_LIST)
	stx	REG_A1T2L
	stz	REG_A1B2

	lda	#%00000111
	sta	REG_HDMAEN

	lda	selection
	jsr	ChangeSelection

	lda	#NMI_ON|NMI_JOYPAD
	sta	REG_NMITIMEN

	lda	#OPTION_FRAME_READY|OPTION_MOSAIC
	sta	options

	cli
;-------------------------------------------------------------------------;
:	jsr	waitvb
	jsr	FadeMosaic
	jsr	Mosaic
	jsr	JoyPad
;-------------------------------------------------------------------------;
	lda	reg_inidisp
	bne	:-
;-------------------------------------------------------------------------;
	jsr	ResetReg
	jmp	DoPlasmaMap


;=========================================================================;
JoyPad:
;=========================================================================;
	lda	reg_inidisp
	lsr
	cmp	#16
	bne	exit1
;-------------------------------------------------------------------------;
	lda	selection
	bit	#80h
	bne	exit1
;-------------------------------------------------------------------------;
	lda	joy1_down+1
	ora	joy2_down+1
	bit	#JOYPADH_UP
	bne	DecreaseSelection
	bit	#JOYPADH_DOWN
	bne	IncreaseSelection
	bit	#JOYPADH_START
	bne	SelectionMade

	lda	joy1_down
	ora	joy2_down
	bit	#JOYPAD_A
	bne	SelectionMade
exit1:	rts
;-------------------------------------------------------------------------;
SelectionMade:
;-------------------------------------------------------------------------;
	lda	selection

	rep	#30h

	and	#%11
	tax

	sep	#20h

	lda	SELECTION,x
	sta	plasma_mode

	lda	#OPTION_FADE_OUT
	tsb	options

	rts
;-------------------------------------------------------------------------;
DecreaseSelection:
;-------------------------------------------------------------------------;
	lda	selection
	dea
	bmi	exit1
	bra	ChangeSelection
;-------------------------------------------------------------------------;
IncreaseSelection:
;-------------------------------------------------------------------------;
	lda	selection
	ina
	cmp	#3
	beq	exit1
;-------------------------------------------------------------------------;
ChangeSelection:
;-------------------------------------------------------------------------;
	pha				; 8-bit selection pushed to stack

	rep	#30h

	asl
	tax

	lda	SELECTION_TM,x
	sta	addr_tm

	sep	#20h

	lda	#%01100001
	sta	REG_MOSAIC
	lda	#05h
	sta	mosaic

	pla				; pull 8-bit selection from stack
	eor	#80h			; enable mosaic effect
	sta	selection
	cmp	#80h
	beq	SetOpt1
	cmp	#82h
	beq	SetOpt3
;-------------------------------------------------------------------------;
SetOpt2:
;-------------------------------------------------------------------------;
	lda	#TM_BG1
	sta	RAM_HDMA+(LIST_TM_OPTION2-HDMA_LIST)
	jsr	Opt1Off
	bra	Opt3Off
;-------------------------------------------------------------------------;
SetOpt1:
;-------------------------------------------------------------------------;
	lda	#TM_BG1
	sta	RAM_HDMA+(LIST_TM_OPTION1-HDMA_LIST)
	ina
	sta	RAM_HDMA+(LIST_TM_OPTION1-HDMA_LIST)+1
	jsr	Opt2Off
;-------------------------------------------------------------------------;
Opt3Off:
;-------------------------------------------------------------------------;
	stz	RAM_HDMA+(LIST_TM_OPTION3-HDMA_LIST)
	lda	#TM_BG2
	sta	RAM_HDMA+(LIST_TM_OPTION3-HDMA_LIST)+1
	rts
;-------------------------------------------------------------------------;
SetOpt3:
;-------------------------------------------------------------------------;
	lda	#TM_BG1
	sta	RAM_HDMA+(LIST_TM_OPTION3-HDMA_LIST)
	jsr	Opt2Off
;-------------------------------------------------------------------------;
Opt1Off:
;-------------------------------------------------------------------------;
	stz	RAM_HDMA+(LIST_TM_OPTION1-HDMA_LIST)
	lda	#TM_BG2
	sta	RAM_HDMA+(LIST_TM_OPTION1-HDMA_LIST)+1
	rts
;-------------------------------------------------------------------------;
Opt2Off:
;-------------------------------------------------------------------------;
	stz	RAM_HDMA+(LIST_TM_OPTION2-HDMA_LIST)
	lda	#TM_BG2
	sta	RAM_HDMA+(LIST_TM_OPTION2-HDMA_LIST)+1
exit2:	rts


;=========================================================================;
Mosaic:
;=========================================================================;
	lda	selection
	bit	#80h
	beq	exit2
;-------------------------------------------------------------------------;
	lda	mosaic
	dea
	bmi	exit2
	beq	EndMosaic
;-------------------------------------------------------------------------;
	sta	mosaic
	asl
	asl
	asl
	asl
	ora	#%01
;-------------------------------------------------------------------------;
:	sta	REG_MOSAIC
	rts
;-------------------------------------------------------------------------;
EndMosaic:
;-------------------------------------------------------------------------;
	lda	#80h
	trb	selection

	lda	#TM_BG1
	sta	(addr_tm)
	dea
	sta	(addr_tm+1)
	bra	:-


;/////////////////////////////////////////////////////////////////////////;
.segment "DATA"
;/////////////////////////////////////////////////////////////////////////;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
HDMA_LIST:
LIST_BG1HOFS:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	60,000,0
	.byte	32,$af,0
	.byte	40,$cb,0
	.byte	01,$cf,0
	.byte	0
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_BG1HOFS_END:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_TM:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	60,1,0
	.byte	32
LIST_TM_OPTION1:
	.byte	0,TM_BG2
	.byte	40
LIST_TM_OPTION2:
	.byte	0,TM_BG2
	.byte	1
LIST_TM_OPTION3:
	.byte	0,TM_BG2
	.byte	0
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_TM_END:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SELECTION_TM:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.word	RAM_HDMA+(LIST_TM_OPTION1-HDMA_LIST)
	.word	RAM_HDMA+(LIST_TM_OPTION2-HDMA_LIST)
	.word	RAM_HDMA+(LIST_TM_OPTION3-HDMA_LIST)
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SELECTION:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	PLASMAON,PLASMAMAP,PLASMAOFF
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
