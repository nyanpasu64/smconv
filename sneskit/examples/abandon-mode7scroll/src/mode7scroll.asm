;-------------------------------------------------------------------------;
.include "snes.inc"
.include "snes_decompress.inc"
.include "snes_zvars.inc"
.include "graphics.inc"
;-------------------------------------------------------------------------;
.import ClearZP
;-------------------------------------------------------------------------;
.exportzp Act_Buffer, Act_Object, Drw_Dummy, Drw_Face, Drw_PoiPoi
.exportzp Dummy_Sin, L_DeltaX, L_DeltaY, L_Dummy, L_Incr1, L_Incr2
.exportzp L_OraVal, L_X1Pos, L_Y1Pos, L_X2Pos, L_Y2Pos, Old_Buffer
.exportzp Rot_Dummy1, Rot_Dummy2, Script_Poi, Script_Next, X_Add, Y_Add
.exportzp Z_Add
;-------------------------------------------------------------------------;
.export DoSinusScroller
;-------------------------------------------------------------------------;
;	Author:	Kay Struve
;	E-Mail:	pothead@uni-paderborn.de
;	Telephone:	++49-(0)5251-65459
;	Date:		Beginning of 1994
;	Machine:	Super Nintendo (65816)
;	Assembled with:	SASM V1.81,V2.00

;This Lousy Piece of Code was Produced by the one and lonly Pothead
;All rights reserved to NINTENDO (NOT!)

;Produced using SASM Copyrighted by INFERNAL BYTES!	
;               ^^^^
;Created with THE EDGE .. The Best Text-Editor Ever!
;SASM :WD65C816 S-NES Macro Assembler v2.00 [MC68030] © 1994 by Infernal Byte, INC.
;THE EDGE :Copyright © 1992-1994 Thomas liljetoft.  All rights reserved

;Note to Editor:
;i used this string to mark the beginning of a FOLD : ";FOLD_OUT"
;and this string was used to mark the end of a FOLD : ";FOLD_END"

;Note to Assembler:
;it is possible, that u need the 2.00 Version of the SASM to assemble
;this piece of code, sorry, but i wasnt able to check wether the pd version
;of the sasm still compiles it, cause i dont have it anymore.


;Personal Messages to:

;Sigma Seven:	Yo Sigma, thanks for the support all the time, i hope
;		everything works out to be fine with your board, ANIME
;		is just great..
;The White Knight:thanks for all the nice chats, i know you didnt like
;		the denmark party too much, but dave and ata really tried
;		to nerve you to death ...
;Paninaro:	Sorry you didnt come to europe last year, perhaps we`ll
;		meet in the future ..
;Geggin:	Good luck for your game, perhaps i can reach you on IRC
;		again.
;Alphatech:	Thanks for calling me, your music routine are really a nice
;		piece of work.
;AMR:		Your SWC-DX send util is the best!! Also we will for sure
;		have fun playing Bomberman and Super Family tennis with Dirk
;		and Piepen...
;Dirk Res.:	heheh... ich hab auch dich nich vergessen... Thanks for the
;		best CDs ever.
;Noogman/??:	Noogie... thanks for all the gfx.. you are really skilled, and
;		your mods really kick ass... and sorry again for me being too
;		busy in school for doing serious programming stuff..
;Death Angel:	Thanks for Drawing things i need. i know you are quite busy
;		working, but we should go to the BART and enjoy a couple of
;		Manga Videos and leech him to death...
;IRC Users:	If you are interested in Snes Coding, or whatever , talk to me,
;		if you see me on IRC (pothead)...
;		Hi to Sir Jinx, Wolverine, and all i cant remember.


;legal stuff:

;Tools used:
;-Piccon 2.50,Coded by Morten Eriksen.
;-Super Magic Disassembler V1.4,Coded by -Pan- of Anthrox
;-ASM-One V1.20 MC680x0/MC6888x Macro Assembler,
; Original coding by Rune Gram-Madsen,Additional coding by T.F.A.
;-Deluxe Paint AGA IV, programmed by: lee ozer,dallas j. hodgson
;-SASM WD65C816 S-NES Macro Assembler v2.00 [MC68030],©1994 Infernal Byte, INC
;-The Edge,Copyright © 1992-1994 Thomas liljetoft.  All rights reserved
;-Wildsend 2.00 , programmed bei AMR.
;-PRO-PACK 2.08 Software Developers File Compression Utility 3 Apr 92
; Copyright (c) 1991,92 Rob Northen Computing, UK. All Rights Reserved
;and: dadadadadaaa:
;-AMIGA 4000/30 AGA 16MB Ram and US-Super Nintendo+SWC-DX

;This Source code is copyrighted (c) 1994,1995 by Kay Struve,All Rights Reserved
;You may use and distribute it, as long as nothing is added or removed.
;If u use parts of it for own productions, please let me know, i am more
;than happy IF there are other productions, so feel free to learn from it.
;						Kay Struve

;illegal stuff:
;sniff... the music was ripped from a comercial game, i am sorry for being
;not able to make my own protracker replay routine work well enuff to use
;it for this demo, so i had to ripp the music.
;it is brilliant, and i hope i did no damage to the creators of NINJA Warriors II.
;please note, that the Music is NOT public domain, and will NOT be spread with
;this source... if you want it, ripp it yourself..


; ******       **                                 *******  *******   ******* **     **    ***   *** 
;   **         **                                ****     ***   *** ****     ***   ***   ***** *****
;   **         **       ****   **  **  ****       ******  ***   ***  ******  **** ****   ***** *****
;   **         **      **  **  **  ** **  **          *** *********      *** ** *** **    ***   *** 
;   **         **      **  **  **  ** ****            *** ***   ***      *** **  *  **
; ******       ******   ****     **   ******     *******  ***   *** *******  **     **    ***   *** 

;	********* Macros ***********
.macro Coord one, two, three	;Datatype for 3d Coordinates
	.byte	one, two, three
.endmacro

.macro LineH one, two, three
	.word	one,two*three,three*three	;\1 Number of Line,\2 Point 1,\3 Point 2
.endmacro

;FOLD_END

;	*************************************************************************
;	********* BANK 00 at $08000 ****** CODE SECTION + Used Tables ***********
;	*************************************************************************

BG1GFX = 08000h
BG1MAP = 0f000h
BG3GFX = 01000h
BG3MAP = 00000h
OAMGFX = 08000h

MODE7_SCREEN	=	0600h
SINE_TABLE	=	0400h

SCROLL_SIZE	=	0200h

Act_Main = m7


;/////////////////////////////////////////////////////////////////////////;
.zeropage
;/////////////////////////////////////////////////////////////////////////;


Act_Buffer:
	.res 2
Act_Object:
	.res 2
Drw_Dummy:
	.res 2
Drw_Face:
	.res 2
Drw_PoiPoi:
	.res 2
Dummy_Sin:
	.res 2
L_DeltaX:
	.res 2
L_DeltaY:
	.res 2
L_Dummy:
	.res 2
L_Incr1:
	.res 2
L_Incr2:
	.res 2
L_OraVal:
	.res 2
L_X1Pos:
	.res 2
L_Y1Pos:
	.res 2
L_X2Pos:
	.res 2
L_Y2Pos:
	.res 2
Old_Buffer:
	.res 2
Rot_Dummy1:
	.res 2
Rot_Dummy2:
	.res 2
Script_Poi:
	.res 2
Script_Next:
	.res 2
X_Add:
	.res 2
Y_Add:
	.res 2
Z_Add:
	.res 2


;/////////////////////////////////////////////////////////////////////////;
.code
;/////////////////////////////////////////////////////////////////////////;

	.a8
	.i16

;FOLD_END
;	Init for Sinus-Scroller-Part
;FOLD_OUT

LogoYPos = 88h
LogoXPos = 00h



;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
DoSinusScroller:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;

	rep	#10h
	sep	#20h

	lda	#NMI_IRQY|NMI_JOYPAD
	sta	REG_NMITIMEN

	lda	#80h			;Initialise Registers and clear V-Ram
	sta	REG_INIDISP

	lda	#30h
	sta	REG_CGSWSEL
	lda	#0e0h
	sta	REG_COLDATA
	stz	REG_CGADSUB
	stz	REG_VMAIN

	sei

	ldy	#0000
	sty	Act_Main

	ldx	#4000h
	;ldy	#0000h			; y is already 0000h
	sty	REG_VMADDL
Init_17:sty	REG_VMDATAL
	dex
	bne	Init_17

	ldx	#0400h
	stx	REG_VMADDL
	tyx				; reset x
Init_14:
	lda	Mode7Scr,x
	sta	REG_VMDATAL
	stz	REG_VMDATAH
	inx
	cpx	#0200h
	bne	Init_14

	tyx				; reset x
Init_16:
	stz	MODE7_SCREEN,x
	inx
	cpx	#1000h
	bne	Init_16

	lda	#VMAIN_INCH
	sta	REG_VMAIN

        DoDecompressDataVram gfx_logoTiles, OAMGFX
        DoCopyPalette Mode7Pal, 0, 64
        DoCopyPalette gfx_logoPal, 240, 16

	ldx	Act_Main
	inx
	inx
	stx	Act_Main

	lda	#BGMODE_7
	sta	REG_BGMODE

	stz	REG_BG1SC
	stz	REG_BG2SC
	stz	REG_BG3SC
	stz	REG_BG4SC
	stz	REG_BG12NBA
	stz	REG_BG34NBA
	stz	REG_BG1HOFS
	stz	REG_BG1HOFS
	stz	REG_BG1VOFS
	stz	REG_BG1VOFS

	lda	#01h
	stz	REG_M7A
	sta	REG_M7A
	stz	REG_M7B
	stz	REG_M7B
	stz	REG_M7C
	stz	REG_M7C
	stz	REG_M7D
	sta	REG_M7D
	sta	REG_TM

	lda	#80h
	sta	REG_M7X
	stz	REG_M7X

	lda	#50h
	sta	REG_M7Y
	stz	REG_M7Y

	stz	Dummy_Sin		;Fade Out Dummy
	stz	L_X2Pos
	stz	L_X2Pos+1
	stz	L_Y2Pos
	stz	L_Y2Pos+1
	stz	L_X1Pos
	stz	L_X1Pos+1
	stz	L_Y1Pos
	stz	L_Y1Pos+1
	stz	L_Incr1			;Effect
	stz	L_Incr1+1
	stz	L_Incr2			;Angle
	stz	L_Incr2+1

	ldx	#SCROLL_SIZE
	stx	L_Dummy			;Size

	stz	L_OraVal
	stz	L_OraVal+1		;Effect_Dummy

	lda	#OBSEL_16_64 | OBSEL_BASE(OAMGFX) | OBSEL_NN_16K			;Initialize OAMs For The Logo!
	sta	REG_OBSEL

	stz	REG_OAMADDL
	stz	REG_OAMADDH

	ldx	#0080h
	lda	#0e0h
initloop1:
	stz	REG_OAMDATA
	sta	REG_OAMDATA
	stz	REG_OAMDATA
	stz	REG_OAMDATA
	dex
	bne	initloop1

initloop2:
	stz	REG_OAMDATA
	inx
	cpx	#0020h
	bne	initloop2

	stz	REG_OAMADDL
	stz	REG_OAMADDH

	lda	#LogoXPos
	sta	REG_OAMDATA
	lda	#LogoYPos
	sta	REG_OAMDATA
	stz	REG_OAMDATA
	lda	#0eh
	sta	REG_OAMDATA

	lda	#LogoXPos+40h
	sta	REG_OAMDATA
	lda	#LogoYPos
	sta	REG_OAMDATA
	lda	#08h
	sta	REG_OAMDATA
	lda	#0eh
	sta	REG_OAMDATA

	lda	#LogoXPos+80h
	sta	REG_OAMDATA
	lda	#LogoYPos
	sta	REG_OAMDATA
	lda	#80h
	sta	REG_OAMDATA
	lda	#0eh
	sta	REG_OAMDATA

	lda	#LogoXPos+0c0h
	sta	REG_OAMDATA
	lda	#LogoYPos
	sta	REG_OAMDATA
	lda	#88h
	sta	REG_OAMDATA
	lda	#0eh
	sta	REG_OAMDATA

	lda	#LogoXPos
	sta	REG_OAMDATA
	lda	#LogoYPos+40h
	sta	REG_OAMDATA
	stz	REG_OAMDATA
	lda	#0fh
	sta	REG_OAMDATA

	lda	#LogoXPos+40h
	sta	REG_OAMDATA
	lda	#LogoYPos+40h
	sta	REG_OAMDATA
	lda	#08h
	sta	REG_OAMDATA
	lda	#0fh
	sta	REG_OAMDATA

	lda	#LogoXPos+80h
	sta	REG_OAMDATA
	lda	#LogoYPos+40h
	sta	REG_OAMDATA
	lda	#80h
	sta	REG_OAMDATA
	lda	#0fh
	sta	REG_OAMDATA

	lda	#LogoXPos+0c0h
	sta	REG_OAMDATA
	lda	#LogoYPos+40h
	sta	REG_OAMDATA
	lda	#88h
	sta	REG_OAMDATA
	lda	#0fh
	sta	REG_OAMDATA

	lda	#10h
	sta	REG_OAMADDL
	lda	#01h
	sta	REG_OAMADDH
	lda	#0aah
	sta	REG_OAMDATA
	sta	REG_OAMDATA

	lda	#02h
	sta	REG_CGSWSEL
	lda	#61h
	sta	REG_CGADSUB

	jsr	makesintab
	jsr	makesintab

	rep	#10h
	sep	#20h

	lda	#81h			;Vertical Timer IRQ at Line $0e8
	sta	REG_VTIMEL
	stz	REG_VTIMEH

	stz	REG_DMAP0
	stz	REG_BBAD0
	ldx	#LIST_INIDISP
	stx	REG_A1T0L
	lda	#^LIST_INIDISP
	sta	REG_A1B0

	stz	REG_DMAP1
	lda	#<REG_TS
	sta	REG_BBAD1
	ldx	#LIST_TS
	stx	REG_A1T1L
	lda	#^LIST_TS
	sta	REG_A1B1

	;rep	#20h
	;lda	#000eh
	;jsr	Play_Musik
	;sep	#20h

:	lda	REG_RDNMI
	bpl	:-

	lda	#%11
	sta	REG_HDMAEN

	lda	#88h
	xba
Scroll_In:
	lda	REG_HVBJOY
	bpl	Scroll_In	
	stz	REG_OAMADDL
	stz	REG_OAMADDH
	lda	#LogoXPos
	sta	REG_OAMDATA
	xba
	sta	REG_OAMDATA
	xba
	stz	REG_OAMDATA
	lda	#0eh
	sta	REG_OAMDATA
	lda	#LogoXPos+40h
	sta	REG_OAMDATA
	xba
	sta	REG_OAMDATA
	xba
	lda	#08h
	sta	REG_OAMDATA
	lda	#0eh
	sta	REG_OAMDATA
	lda	#LogoXPos+80h
	sta	REG_OAMDATA
	xba
	sta	REG_OAMDATA
	xba
	lda	#80h
	sta	REG_OAMDATA
	lda	#0eh
	sta	REG_OAMDATA
	lda	#LogoXPos+0c0h
	sta	REG_OAMDATA
	xba
	sta	REG_OAMDATA
	xba
	lda	#88h
	sta	REG_OAMDATA
	lda	#0eh
	sta	REG_OAMDATA
	lda	#LogoXPos
	sta	REG_OAMDATA
	xba
	clc
	adc	#40h
	sta	REG_OAMDATA
	xba
	stz	REG_OAMDATA
	lda	#0fh
	sta	REG_OAMDATA
	lda	#LogoXPos+40h
	sta	REG_OAMDATA
	xba
	sta	REG_OAMDATA
	xba
	lda	#08h
	sta	REG_OAMDATA
	lda	#0fh
	sta	REG_OAMDATA
	lda	#LogoXPos+80h
	sta	REG_OAMDATA
	xba
	sta	REG_OAMDATA
	xba
	lda	#80h
	sta	REG_OAMDATA
	lda	#0fh
	sta	REG_OAMDATA
	lda	#LogoXPos+0c0h
	sta	REG_OAMDATA
	xba
	sta	REG_OAMDATA
	sec
	sbc	#40h
	xba
	lda	#88h
	sta	REG_OAMDATA
	lda	#0fh
	sta	REG_OAMDATA
	xba
	dec	a
	cmp	#27h
	beq	Quit
	xba
Not_VBlanc:
	lda	REG_HVBJOY
	bmi	Not_VBlanc
	jmp	Scroll_In
Quit:	;cli

Loop:	lda	REG_RDNMI
	bpl	Loop
	jsr	Main__03
	jsr	VBR__03
	bra	Loop


;FOLD_END
;	Main Routine for Sinus-Scroll Part
;	Just Waits for a Button to be pressed and changes to the Next Part
;FOLD_OUT
;=========================================================================;
Main__03:
;=========================================================================;
	rep	#10h
	sep	#20h

	wai
@pad:	lda	REG_HVBJOY
	and	#01h
	bne	@pad
	lda	REG_JOY1H
	bit	#JOYPADH_B
	bne	:+

	rts

:	stz	REG_TM
	stz	REG_HDMAEN
	lda	#80h
	sta	REG_INIDISP
	jmp	DoSinusScroller


;FOLD_END
;	VBR for the 256 Colors 1-Pixel Sinus Scroller Part
;	Writes the GFX-Data to V-RAM and Calculates the Sinus Table
;	for the Next Frame.
;FOLD_OUT
;=========================================================================;
VBR__03:
;=========================================================================;
	inc	L_X1Pos
	ldx	L_X1Pos

	sep	#10h
	rep	#21h

	lda	#REG_INIDISP
	tcd

	ldy	#0000h
@loop:	phy
	lda	SINE_TABLE,y		;Put One Row
	sta	<REG_VMADDL
	stz	<REG_VMDATAH
	adc	#08h
	sta	<REG_VMADDL
	ldy	MODE7_SCREEN+0001h,x
	sty	<REG_VMDATAH
	adc	#08h
	sta	<REG_VMADDL
	ldy	MODE7_SCREEN+0201h,x
	sty	<REG_VMDATAH
	adc	#08h
	sta	REG_VMADDL
	ldy	MODE7_SCREEN+0401h,x
	sty	<REG_VMDATAH
	adc	#08h
	sta	<REG_VMADDL
	ldy	MODE7_SCREEN+0601h,x
	sty	<REG_VMDATAH
	adc	#08h
	sta	<REG_VMADDL
	ldy	MODE7_SCREEN+0801h,x
	sty	<REG_VMDATAH
	adc	#08h
	sta	<REG_VMADDL
	ldy	MODE7_SCREEN+0a01h,x
	sty	<REG_VMDATAH
	adc	#08h
	sta	<REG_VMADDL
	ldy	MODE7_SCREEN+0c01h,x
	sty	<REG_VMDATAH
	adc	#08h
	sta	<REG_VMADDL
	ldy	MODE7_SCREEN+0e01h,x
	sty	<REG_VMDATAH
	adc	#08h
	sta	<REG_VMADDL
	stz	<REG_VMDATAH
	inx
	ply
	iny
	iny
	bne	@loop

@loop1:	phy
	lda	SINE_TABLE+0100h,y		;Put One Row
	sta	<REG_VMADDL
	stz	<REG_VMDATAH
	adc	#08h
	sta	<REG_VMADDL
	ldy	MODE7_SCREEN+0001h,x
	sty	<REG_VMDATAH
	adc	#08h
	sta	<REG_VMADDL
	ldy	MODE7_SCREEN+0201h,x
	sty	<REG_VMDATAH
	adc	#08h
	sta	<REG_VMADDL
	ldy	MODE7_SCREEN+0401h,x
	sty	<REG_VMDATAH
	adc	#08h
	sta	<REG_VMADDL
	ldy	MODE7_SCREEN+0601h,x
	sty	<REG_VMDATAH
	adc	#08h
	sta	<REG_VMADDL
	ldy	MODE7_SCREEN+0801h,x
	sty	<REG_VMDATAH
	adc	#08h
	sta	<REG_VMADDL
	ldy	MODE7_SCREEN+0a01h,x
	sty	<REG_VMDATAH
	adc	#08h
	sta	<REG_VMADDL
	ldy	MODE7_SCREEN+0c01h,x
	sty	<REG_VMDATAH
	adc	#08h
	sta	<REG_VMADDL
	ldy	MODE7_SCREEN+0e01h,x
	sty	<REG_VMDATAH
	adc	#08h
	sta	<REG_VMADDL
	stz	<REG_VMDATAH
	inx
	ply
	iny
	iny
	bpl	@loop1

	lda	#0000h
	tcd

	inc	L_Y2Pos
	inc	L_Y2Pos

	rep	#31h

	lda	L_Incr2		;Angle ($000 Normal -$7fe)
	tax
	lda	L_Dummy		;Size ($200=Normal <$200 Bigger..)

	sep	#20h

	sta	REG_M7A
	xba
	sta	REG_M7A
	lda	SINUS+513,x
	sta	REG_M7B
	ldy	REG_MPYM
	lda	SINUS+1,x
	sta	REG_M7B

	rep	#20h

	lda	REG_MPYM
	pha
	tya

	sep	#20h

	sta	REG_M7A
	xba
	sta	REG_M7A

	rep	#20h

	pla

	sep	#20h

	sta	REG_M7B
	xba
	sta	REG_M7B
	xba

	rep	#20h

	eor	#0ffffh
	inc	a

	sep	#20h

	sta	REG_M7C
	xba
	sta	REG_M7C

	rep	#20h

	tya

	sep	#20h

	sta	REG_M7D
	xba
	sta	REG_M7D

	lda	Dummy_Sin
	sta	REG_WH0
makesintab:
	rep	#30h

	lda	L_Y2Pos
	and	#007eh
	clc
	adc	#200h
	tax
	ldy	#0000h
	lda	#0440h
	sta	L_X2Pos

@loop1:	lda	Mode7Sin,x
	adc	L_X2Pos
	sta	SINE_TABLE,y
	dex
	dex
	iny
	iny
	inc	L_X2Pos
	tya
	and	#000eh
	bne	@loop1

	lda	L_X2Pos
	adc	#0100h
	and	#1f40h
	sta	L_X2Pos
	cmp	#0040h
	clc
	bne	@loop1

	inc	L_Y1Pos
	lda	L_Y1Pos
	clc
	ror	a
	clc
	ror	a
	clc
	ror	a
	tax

	sep	#20h

	lda	Mode7Text,x
	bne	@skip2
	stz	L_Y1Pos
	stz	L_Y1Pos+1
	lda	#20h
@skip2:	cmp	#21h
	bcs	@skip1
	cmp	#20h
	beq	@space
	asl	a
	sta	L_Incr1

@space:	rep	#21h

	lda	#37*8
	bra	@cont1

	sep	#20h

@skip1:	sec
	sbc	#41h

	rep	#20h

	and	#00ffh
	asl	a
	asl	a
	asl	a
@cont1:	sta	L_DeltaX
	lda	L_Y1Pos
	and	#0007h
	clc
	adc	L_DeltaX
	tax
	ldy	L_X1Pos
	lda	Mode7Char,x
	sta	MODE7_SCREEN,y
	sta	MODE7_SCREEN+0100h,y
	lda	Mode7Char+304,x
	sta	MODE7_SCREEN+0200h,y
	sta	MODE7_SCREEN+0300h,y
	lda	Mode7Char+304*2,x
	sta	MODE7_SCREEN+0400h,y
	sta	MODE7_SCREEN+0500h,y
	lda	Mode7Char+304*3,x
	sta	MODE7_SCREEN+0600h,y
	sta	MODE7_SCREEN+0700h,y
	lda	Mode7Char+304*4,x
	sta	MODE7_SCREEN+0800h,y
	sta	MODE7_SCREEN+0900h,y
	lda	Mode7Char+304*5,x
	sta	MODE7_SCREEN+0a00h,y
	sta	MODE7_SCREEN+0b00h,y
	lda	Mode7Char+304*6,x
	sta	MODE7_SCREEN+0c00h,y
	sta	MODE7_SCREEN+0d00h,y
	lda	Mode7Char+304*7,x
	sta	MODE7_SCREEN+0e00h,y
	sta	MODE7_SCREEN+0f00h,y

	rep	#30h

	ldx	L_Incr1
	lda	Effect_Tab,x
	sta	memptr
	jmp	(memptr)


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
Effect_Tab:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.word	Effect_01,Effect_02,Effect_03,Effect_04,Effect_05,Effect_06
	.word	Effect_07
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


	.a16
	.i16


;-------------------------------------------------------------------------;
Effect_01:
;-------------------------------------------------------------------------;
	lda	L_Dummy		;Normal Scroller with Size $200, Angle=$0000
	cmp	#SCROLL_SIZE	;If Values differ from Normal, correct them
	beq	@ok		;by Small Steps each Frame!
	bcc	@to_low
	sec
	sbc	#04h
	sta	L_Dummy
	bra	@ok
@to_low:clc
	adc	#04h
	sta	L_Dummy
@ok:	lda	L_Incr2
	beq	@ok2
	clc
	adc	#08h
	and	#7f8h
	sta	L_Incr2
@ok2:	lda	#0080h
	sta	L_OraVal
	rts
;-------------------------------------------------------------------------;
Effect_02:
;-------------------------------------------------------------------------;
	lda	L_Dummy		;Zoom Scroller Closer to Screen, and return
	sec			;to Normal Size afterwards
	sbc	#04h
	sta	L_Dummy
	cmp	#00f0h
	bcs	@skip
	stz	L_Incr1
@skip:	rts
;-------------------------------------------------------------------------;
Effect_03:
;-------------------------------------------------------------------------;
	lda	L_Incr2		;Rotate the Scroller ONCE!
	clc
	adc	#04h
	sta	L_Incr2
	stz	L_Incr1
	rts
;-------------------------------------------------------------------------;
Effect_04:
;-------------------------------------------------------------------------;
	lda	L_Dummy		;Zoom out Scroller and return to Normal Size
	clc			;Afterwards
	adc	#04h
	sta	L_Dummy
	cmp	#0400h
	bcc	@skip
	stz	L_Incr1
@skip:	rts
;-------------------------------------------------------------------------;
Effect_05:
;-------------------------------------------------------------------------;
	lda	L_OraVal	;Rotate Scroll 45 Degrees Back and Forth..
	clc
	adc	#04h
	and	#01feh
	sta	L_OraVal
	and	#100h
	beq	@down
	lda	L_OraVal
	eor	#0fffeh
	and	#0feh
	bra	@up
@down:	lda	L_OraVal
@up:	sec
	sbc	#080h
	and	#07fch
	sta	L_Incr2
	rts
;-------------------------------------------------------------------------;
Effect_06:
;-------------------------------------------------------------------------;
	stz	L_Incr1		;Return to Normal (Call Effect_01)
	rts
;-------------------------------------------------------------------------;
Effect_07:
;-------------------------------------------------------------------------;
	lda	L_Dummy		;Zoom Scroller Closer to Screen
	beq	@skip
	sec
	sbc	#04h
	sta	L_Dummy
@skip:	rts



;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_INIDISP:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$22,$80,$01,$02,$01,$04,$01,$06
	.byte	$01,$08,$01,$0a,$01,$0c,$01,$0e
	.byte	$50,$0f,$01,$0e,$01,$0c,$01,$0a
	.byte	$01,$08,$01,$06,$01,$04,$01,$02
	.byte	$01,$80,$00,$00
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_TS:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$30,$00,$48,$10,$01,$00,$00,$00
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
Mode7Scr:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$01,$05,$09,$0d,$11,$15,$19,$1d,$21,$25,$29,$2d,$31,$35,$39,$3d
	.byte	$41,$45,$49,$4d,$51,$55,$59,$5d,$61,$65,$69,$6d,$71,$75,$79,$7d
	.byte	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$01+1,$05+1,$09+1,$0d+1,$11+1,$15+1,$19+1,$1d+1,$21+1,$25+1,$29+1,$2d+1,$31+1,$35+1,$39+1,$3d+1
	.byte	$41+1,$45+1,$49+1,$4d+1,$51+1,$55+1,$59+1,$5d+1,$61+1,$65+1,$69+1,$6d+1,$71+1,$75+1,$79+1,$7d+1
	.byte	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$01+2,$05+2,$09+2,$0d+2,$11+2,$15+2,$19+2,$1d+2,$21+2,$25+2,$29+2,$2d+2,$31+2,$35+2,$39+2,$3d+2
	.byte	$41+2,$45+2,$49+2,$4d+2,$51+2,$55+2,$59+2,$5d+2,$61+2,$65+2,$69+2,$6d+2,$71+2,$75+2,$79+2,$7d+2
	.byte	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$01+3,$05+3,$09+3,$0d+3,$11+3,$15+3,$19+3,$1d+3,$21+3,$25+3,$29+3,$2d+3,$31+3,$35+3,$39+3,$3d+3
	.byte	$41+3,$45+3,$49+3,$4d+3,$51+3,$55+3,$59+3,$5d+3,$61+3,$65+3,$69+3,$6d+3,$71+3,$75+3,$79+3,$7d+3
	.byte	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
Mode7Sin:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.word	$000B*8,$000C*8,$000D*8,$000E*8,$000f*8,$0010*8,$0011*8,$0012*8
	.word	$0013*8,$0013*8,$0014*8,$0015*8,$0016*8,$0016*8,$0017*8,$0017*8
	.word	$0017*8,$0017*8,$0016*8,$0016*8,$0016*8,$0015*8,$0014*8,$0013*8
	.word	$0013*8,$0012*8,$0011*8,$0010*8,$000f*8,$000E*8,$000D*8,$000C*8
	.word	$000B*8,$000A*8,$0009*8,$0008*8,$0007*8,$0006*8,$0005*8,$0004*8
	.word	$0003*8,$0003*8,$0002*8,$0001*8,$0000*8,$0000*8,$0000*8,$0000*8
	.word	$0000*8,$0000*8,$0000*8,$0000*8,$0000*8,$0001*8,$0002*8,$0003*8
	.word	$0003*8,$0004*8,$0005*8,$0006*8,$0007*8,$0008*8,$0009*8,$000A*8
	.word	$000B*8,$000C*8,$000D*8,$000E*8,$000f*8,$0010*8,$0011*8,$0012*8
	.word	$0013*8,$0013*8,$0014*8,$0015*8,$0016*8,$0016*8,$0017*8,$0017*8
	.word	$0017*8,$0017*8,$0016*8,$0016*8,$0016*8,$0015*8,$0014*8,$0013*8
	.word	$0013*8,$0012*8,$0011*8,$0010*8,$000f*8,$000E*8,$000D*8,$000C*8
	.word	$000B*8,$000A*8,$0009*8,$0008*8,$0007*8,$0006*8,$0005*8,$0004*8
	.word	$0003*8,$0003*8,$0002*8,$0001*8,$0000*8,$0000*8,$0000*8,$0000*8
	.word	$0000*8,$0000*8,$0000*8,$0000*8,$0000*8,$0001*8,$0002*8,$0003*8
	.word	$0003*8,$0004*8,$0005*8,$0006*8,$0007*8,$0008*8,$0009*8,$000A*8
	.word	$000B*8,$000C*8,$000D*8,$000E*8,$000f*8,$0010*8,$0011*8,$0012*8
	.word	$0013*8,$0013*8,$0014*8,$0015*8,$0016*8,$0016*8,$0017*8,$0017*8
	.word	$0017*8,$0017*8,$0016*8,$0016*8,$0016*8,$0015*8,$0014*8,$0013*8
	.word	$0013*8,$0012*8,$0011*8,$0010*8,$000f*8,$000E*8,$000D*8,$000C*8
	.word	$000B*8,$000A*8,$0009*8,$0008*8,$0007*8,$0006*8,$0005*8,$0004*8
	.word	$0003*8,$0003*8,$0002*8,$0001*8,$0000*8,$0000*8,$0000*8,$0000*8
	.word	$0000*8,$0000*8,$0000*8,$0000*8,$0000*8,$0001*8,$0002*8,$0003*8
	.word	$0003*8,$0004*8,$0005*8,$0006*8,$0007*8,$0008*8,$0009*8,$000A*8
	.word	$000B*8,$000C*8,$000D*8,$000E*8,$000f*8,$0010*8,$0011*8,$0012*8
	.word	$0013*8,$0013*8,$0014*8,$0015*8,$0016*8,$0016*8,$0017*8,$0017*8
	.word	$0017*8,$0017*8,$0016*8,$0016*8,$0016*8,$0015*8,$0014*8,$0013*8
	.word	$0013*8,$0012*8,$0011*8,$0010*8,$000f*8,$000E*8,$000D*8,$000C*8
	.word	$000B*8,$000A*8,$0009*8,$0008*8,$0007*8,$0006*8,$0005*8,$0004*8
	.word	$0003*8,$0003*8,$0002*8,$0001*8,$0000*8,$0000*8,$0000*8,$0000*8
	.word	$0000*8,$0000*8,$0000*8,$0000*8,$0000*8,$0001*8,$0002*8,$0003*8
	.word	$0003*8,$0004*8,$0005*8,$0006*8,$0007*8,$0008*8,$0009*8,$000A*8
	.word	$000B*8,$000C*8,$000D*8,$000E*8,$000f*8,$0010*8,$0011*8,$0012*8
	.word	$0013*8,$0013*8,$0014*8,$0015*8,$0016*8,$0016*8,$0017*8,$0017*8
	.word	$0017*8,$0017*8,$0016*8,$0016*8,$0016*8,$0015*8,$0014*8,$0013*8
	.word	$0013*8,$0012*8,$0011*8,$0010*8,$000f*8,$000E*8,$000D*8,$000C*8
	.word	$000B*8,$000A*8,$0009*8,$0008*8,$0007*8,$0006*8,$0005*8,$0004*8
	.word	$0003*8,$0003*8,$0002*8,$0001*8,$0000*8,$0000*8,$0000*8,$0000*8
	.word	$0000*8,$0000*8,$0000*8,$0000*8,$0000*8,$0001*8,$0002*8,$0003*8
	.word	$0003*8,$0004*8,$0005*8,$0006*8,$0007*8,$0008*8,$0009*8,$000A*8
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
Mode7Text:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	" HELLO   ",3,"      DUE TO THE FACT ",2,"     THAT THIS SCROLLER IS"
	.byte	" TOTALLY UNREADABLE I WOULD JUST LIKE TO TELL YOU WHAT U ARE WATCHING"
	.byte	"   THIS SCROLLER IS ONE PIXEL SINUS IN \_` COLORS",1,"    "
	.byte	"   OK NOW TO SOMETHING EVEN MORE BORING     ",4," I DONT REALLY HAVE"
	.byte	" INSPIRATION LEFT    I JUST HOPE YOU LIKE THIS DEMO    ESSPECIALLY "
	.byte	"I HOPE THIS DEMO IS AS GOOD AS THE XMAS DEMO FROM ANTHROX   CAUSE"
	.byte	" ALL OTHER DEMOS RELEASED YET WERE NOT AS GOOD AS THE ATX DEMO   "
	.byte	" IT IS QUITE A PITTY THAT THERE ARE NOT MANY DEMOS OUT FOR THE SNES "
	.byte	"  TO BUY COPIERS CALL TWK AND ORDER UNDER b\c a^[ dcad  BACK FROM THE ADDS"
	.byte	" TO SOME MORE TEXT    "
	.byte	" I WOULD HAVE EXPTECTED MORE DEMOS   ESSPECIALLY FROM SOME OLD C SIXTYFOUR"
	.byte	" GUYS    BUT THERE WASNT MUCH EXCEPT FOR THE REALLY COOL CENSOR SIXTYFOUR"
	.byte	" SOUND DEMO     BY THE WAY IS YOU SHOULD EVER DEVELOPE USEFULL TOOLS SUCH"
	.byte	" AS A DEBUGGER OR CROSS LEVEL EDITOR   PLEASE CONTACT ME    MY PHONENUMBER"
	.byte	"IS IN THE HIDDEN PART      WELL YOU READ THIS REALLY LAME SCROLLER   PLEASE"
	.byte	" PRESS B TO GO ON NOW     THIS PART IS JUST TOO BORING     SORRY FOR TYPING"
	.byte	" SUCH STUPID SHIT ALL THE TIME     CYA IN THE LAST PART    BYE "
	.byte	"                                   ",0
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
Out_Sin:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.word	$00FE,$00FE,$00FE,$00FD,$00FD,$00FC,$00FB,$00FA
	.word	$00F9,$00F7,$00F6,$00F4,$00F2,$00F1,$00EE,$00EC
	.word	$00EA,$00E7,$00E5,$00E2,$00DF,$00DC,$00D9,$00D5
	.word	$00D2,$00CE,$00CA,$00C7,$00C3,$00BF,$00BA,$00B6
	.word	$00B2,$00AD,$00A8,$00A4,$009F,$009A,$0095,$0090
	.word	$008B,$0085,$0080,$007A,$0075,$006F,$006A,$0064
	.word	$005E,$0058,$0052,$004C,$0046,$0040,$003A,$0034
	.word	$002E,$0028,$0021,$001B,$0015,$000F,$0008,$0002
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
Out_Sin2:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.word	$0000,$0005,$000C,$0012,$0018,$001E,$0025,$002B
	.word	$0031,$0037,$003D,$0043,$0049,$004F,$0055,$005B
	.word	$0061,$0067,$006D,$0072,$0078,$007D,$0083,$0088
	.word	$008D,$0092,$0097,$009C,$00A1,$00A6,$00AB,$00AF
	.word	$00B4,$00B8,$00BD,$00C1,$00C5,$00C9,$00CC,$00D0
	.word	$00D4,$00D7,$00DA,$00DD,$00E0,$00E3,$00E6,$00E9
	.word	$00EB,$00ED,$00EF,$00F2,$00F3,$00F5,$00F7,$00F8
	.word	$00F9,$00FA,$00FB,$00FC,$00FD,$00FD,$00FE,$00FE
	.word	$00FE,$00FE,$00FE,$00FD,$00FD,$00FC,$00FB,$00FA
	.word	$00F9,$00F7,$00F6,$00F4,$00F2,$00F1,$00EE,$00EC
	.word	$00EA,$00E7,$00E5,$00E2,$00DF,$00DC,$00D9,$00D5
	.word	$00D2,$00CE,$00CA,$00C7,$00C3,$00BF,$00BA,$00B6
	.word	$00B2,$00AD,$00A8,$00A4,$009F,$009A,$0095,$0090
	.word	$008B,$0085,$0080,$007A,$0075,$006F,$006A,$0064
	.word	$005E,$0058,$0052,$004C,$0046,$0040,$003A,$0034
	.word	$002E,$0028,$0021,$001B,$0015,$000F,$0008,$0002
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SINUS:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.word	$0000,$00D5,$0188,$025F,$0335,$03E8,$04BE,$0571	;Sinus Table with
	.word	$0647,$071D,$07CF,$08A5,$097B,$0A2D,$0B03,$0BB5	;1024 Entries Words
	.word	$0C8B,$0D60,$0E12,$0EE7,$0FBC,$106D,$1142,$11F3
	.word	$12C7,$139B,$144B,$151F,$15F2,$16A2,$1775,$1825
	.word	$18F7,$19C9,$1A79,$1B4A,$1C1B,$1CCA,$1D9B,$1E48
	.word	$1F19,$1FE8,$2095,$2165,$2233,$22DF,$23AE,$2459
	.word	$2527,$25F3,$269E,$276A,$2836,$28E0,$29AB,$2A53
	.word	$2B1E,$2BE7,$2C8F,$2D58,$2E20,$2EC6,$2F8E,$3034
	.word	$30FA,$31C0,$3264,$3329,$33EE,$3491,$3554,$35F6
	.word	$36B8,$377A,$381B,$38DB,$399B,$3A3B,$3AF9,$3B97
	.word	$3C55,$3D11,$3DAF,$3E6A,$3F25,$3FC0,$407A,$4114
	.word	$41CC,$4284,$431C,$43D3,$4488,$451E,$45D3,$4668
	.word	$471B,$47CD,$4860,$4911,$49C1,$4A52,$4B01,$4B91
	.word	$4C3E,$4CEA,$4D78,$4E22,$4ECC,$4F58,$5000,$508C
	.word	$5131,$51D7,$5260,$5303,$53A7,$542E,$54CE,$5554
	.word	$55F3,$5692,$5715,$57B2,$584D,$58CF,$5968,$59E8
	.word	$5A81,$5B17,$5B94,$5C2A,$5CBE,$5D39,$5DCC,$5E44
	.word	$5ED5,$5F65,$5FDB,$6069,$60F5,$6169,$61F5,$6267
	.word	$62EF,$6378,$63E7,$646C,$64F2,$655E,$65E1,$664D
	.word	$66CD,$674C,$67B6,$6832,$68AF,$6915,$698E,$69F4
	.word	$6A6B,$6AE1,$6B44,$6BB8,$6C2B,$6C8B,$6CFB,$6D58
	.word	$6DC8,$6E35,$6E8F,$6EFB,$6F65,$6FBD,$7025,$707A
	.word	$70E0,$7145,$7197,$71FA,$725A,$72AA,$730A,$7357
	.word	$73B3,$740F,$7459,$74B2,$750A,$7551,$75A6,$75ED
	.word	$763F,$7691,$76D3,$7722,$7771,$77B0,$77FB,$7839
	.word	$7882,$78C9,$7905,$7949,$798D,$79C5,$7A06,$7A3B
	.word	$7A7B,$7AB7,$7AEA,$7B25,$7B5F,$7B8E,$7BC5,$7BF2
	.word	$7C28,$7C5A,$7C84,$7CB6,$7CE5,$7D0B,$7D39,$7D5D
	.word	$7D87,$7DB1,$7DD2,$7DF9,$7E1E,$7E3B,$7E5F,$7E7A
	.word	$7E9A,$7EBA,$7ED2,$7EEE,$7F0A,$7F1E,$7F36,$7F4A
	.word	$7F5F,$7F74,$7F84,$7F95,$7FA6,$7FB3,$7FC0,$7FCB
	.word	$7FD6,$7FDF,$7FE7,$7FEE,$7FF3,$7FF8,$7FFB,$7FFC
	.word	$7FFE,$7FFC,$7FFB,$7FF8,$7FF2,$7FEE,$7FE7,$7FDF
	.word	$7FD6,$7FCB,$7FC0,$7FB3,$7FA3,$7F95,$7F84,$7F74
	.word	$7F5F,$7F4A,$7F36,$7F1E,$7F05,$7EEE,$7ED2,$7EBA
	.word	$7E9A,$7E7A,$7E5F,$7E3B,$7E18,$7DF9,$7DD2,$7DB1
	.word	$7D87,$7D5D,$7D39,$7D0B,$7CDD,$7CB6,$7C84,$7C5A
	.word	$7C28,$7BF2,$7BC5,$7B8E,$7B55,$7B25,$7AEA,$7AB7
	.word	$7A7B,$7A3B,$7A06,$79C5,$7982,$7949,$7905,$78C9
	.word	$7882,$7839,$77FB,$77B0,$7763,$7722,$76D3,$7691
	.word	$763F,$75ED,$75A6,$7551,$74FB,$74B2,$7459,$740F
	.word	$73B3,$7357,$730A,$72AA,$724A,$71FA,$7197,$7145
	.word	$70E0,$707A,$7025,$6FBD,$6F53,$6EFB,$6E8F,$6E35
	.word	$6DC8,$6D58,$6CFB,$6C8B,$6C18,$6BB8,$6B44,$6AE1
	.word	$6A6B,$69F4,$698E,$6915,$689A,$6832,$67B6,$674C
	.word	$66CD,$664D,$65E1,$655E,$64DC,$646C,$63E7,$6378
	.word	$62EF,$6267,$61F5,$6169,$60DE,$6069,$5FDB,$5F65
	.word	$5ED5,$5E44,$5DCC,$5D39,$5CA5,$5C2A,$5B94,$5B17
	.word	$5A81,$59E8,$5968,$58CF,$5833,$57B2,$5715,$5692
	.word	$55F3,$5554,$54CE,$542E,$538B,$5303,$5260,$51D7
	.word	$5131,$508C,$5000,$4F58,$4EB0,$4E22,$4D78,$4CEA
	.word	$4C3E,$4B91,$4B01,$4A52,$49A4,$4911,$4860,$47CD
	.word	$471B,$4668,$45D3,$451E,$446A,$43D3,$431C,$4284
	.word	$41CC,$4114,$407A,$3FC0,$3F06,$3E6A,$3DAF,$3D11
	.word	$3C55,$3B97,$3AF9,$3A3B,$397B,$38DB,$381B,$377A
	.word	$36B8,$35F6,$3554,$3491,$33CD,$3329,$3264,$31C0
	.word	$30FA,$3034,$2F8E,$2EC6,$2DFF,$2D58,$2C8F,$2BE7
	.word	$2B1E,$2A53,$29AB,$28E0,$2814,$276A,$269E,$25F3
	.word	$2527,$2459,$23AE,$22DF,$2211,$2165,$2095,$1FE8
	.word	$1F19,$1E48,$1D9B,$1CCA,$1BF9,$1B4A,$1A79,$19C9
	.word	$18F7,$1825,$1775,$16A2,$15CF,$151F,$144B,$139B
	.word	$12C7,$11F3,$1142,$106D,$0F98,$0EE7,$0E12,$0D60
	.word	$0C8B,$0BB5,$0B03,$0A2D,$0958,$08A5,$07CF,$071D
	.word	$0647,$0571,$04BE,$03E8,$0311,$025F,$0188,$00D5
	.word	$0000,$FF2A,$FE77,$FDA0,$FCCA,$FC17,$FB41,$FA8E
	.word	$F9B8,$F8E2,$F830,$F75A,$F684,$F5D2,$F4FC,$F44A
	.word	$F374,$F29F,$F1ED,$F118,$F043,$EF92,$EEBD,$EE0C
	.word	$ED38,$EC64,$EBB4,$EAE0,$EA0D,$E95D,$E88A,$E7DA
	.word	$E708,$E636,$E586,$E4B5,$E3E4,$E335,$E264,$E1B7
	.word	$E0E6,$E017,$DF6A,$DE9A,$DDCC,$DD20,$DC51,$DBA6
	.word	$DAD8,$DA0C,$D961,$D895,$D7C9,$D71F,$D654,$D5AC
	.word	$D4E1,$D418,$D370,$D2A7,$D1DF,$D139,$D071,$CFCB
	.word	$CF05,$CE3F,$CD9B,$CCD6,$CC11,$CB6E,$CAAB,$CA09
	.word	$C947,$C885,$C7E4,$C724,$C664,$C5C4,$C506,$C468
	.word	$C3AA,$C2EE,$C250,$C195,$C0DA,$C03F,$BF85,$BEEB
	.word	$BE33,$BD7B,$BCE3,$BC2C,$BB77,$BAE1,$BA2C,$B997
	.word	$B8E4,$B832,$B79F,$B6EE,$B63E,$B5AD,$B4FE,$B46E
	.word	$B3C1,$B315,$B287,$B1DD,$B133,$B0A7,$AFFF,$AF73
	.word	$AECE,$AE28,$AD9F,$ACFC,$AC58,$ABD1,$AB31,$AAAB
	.word	$AA0C,$A96D,$A8EA,$A84D,$A7B2,$A730,$A697,$A617
	.word	$A57E,$A4E8,$A46B,$A3D5,$A341,$A2C6,$A233,$A1BB
	.word	$A12A,$A09A,$A024,$9F96,$9F0A,$9E96,$9E0A,$9D98
	.word	$9D10,$9C87,$9C18,$9B93,$9B0D,$9AA1,$9A1E,$99B2
	.word	$9932,$98B3,$9849,$97CD,$9750,$96EA,$9671,$960B
	.word	$9594,$951E,$94BB,$9447,$93D4,$9374,$9304,$92A7
	.word	$9237,$91CA,$9170,$9104,$909A,$9042,$8FDA,$8F85
	.word	$8F1F,$8EBA,$8E68,$8E05,$8DA5,$8D55,$8CF5,$8CA8
	.word	$8C4C,$8BF0,$8BA6,$8B4D,$8AF5,$8AAE,$8A59,$8A12
	.word	$89C0,$896E,$892C,$88DD,$888E,$884F,$8804,$87C6
	.word	$877D,$8736,$86FA,$86B6,$8672,$863A,$85F9,$85C4
	.word	$8584,$8548,$8515,$84DA,$84A0,$8471,$843A,$840D
	.word	$83D7,$83A5,$837B,$8349,$831A,$82F4,$82C6,$82A2
	.word	$8278,$824E,$822D,$8206,$81E1,$81C4,$81A0,$8185
	.word	$8165,$8145,$812D,$8111,$80F5,$80E1,$80C9,$80B5
	.word	$80A0,$808B,$807B,$806A,$8059,$804C,$803F,$8034
	.word	$8029,$8020,$8018,$8011,$800C,$8007,$8004,$8003
	.word	$8001,$8003,$8004,$8007,$800D,$8011,$8018,$8020
	.word	$8029,$8034,$803F,$804C,$805C,$806A,$807B,$808B
	.word	$80A0,$80B5,$80C9,$80E1,$80FA,$8111,$812D,$8145
	.word	$8165,$8185,$81A0,$81C4,$81E7,$8206,$822D,$824E
	.word	$8278,$82A2,$82C6,$82F4,$8322,$8349,$837B,$83A5
	.word	$83D7,$840D,$843A,$8471,$84AA,$84DA,$8515,$8548
	.word	$8584,$85C4,$85F9,$863A,$867D,$86B6,$86FA,$8736
	.word	$877D,$87C6,$8804,$884F,$889C,$88DD,$892C,$896E
	.word	$89C0,$8A12,$8A59,$8AAE,$8B04,$8B4D,$8BA6,$8BF0
	.word	$8C4C,$8CA8,$8CF5,$8D55,$8DB5,$8E05,$8E68,$8EBA
	.word	$8F1F,$8F85,$8FDA,$9042,$90AC,$9104,$9170,$91CA
	.word	$9237,$92A7,$9304,$9374,$93E7,$9447,$94BB,$951E
	.word	$9594,$960B,$9671,$96EA,$9765,$97CD,$9849,$98B3
	.word	$9932,$99B2,$9A1E,$9AA1,$9B23,$9B93,$9C18,$9C87
	.word	$9D10,$9D98,$9E0A,$9E96,$9F21,$9F96,$A024,$A09A
	.word	$A12A,$A1BB,$A233,$A2C6,$A35A,$A3D5,$A46B,$A4E8
	.word	$A57E,$A617,$A697,$A730,$A7CC,$A84D,$A8EA,$A96D
	.word	$AA0C,$AAAB,$AB31,$ABD1,$AC74,$ACFC,$AD9F,$AE28
	.word	$AECE,$AF73,$AFFF,$B0A7,$B14F,$B1DD,$B287,$B315
	.word	$B3C1,$B46E,$B4FE,$B5AD,$B65B,$B6EE,$B79F,$B832
	.word	$B8E4,$B997,$BA2C,$BAE1,$BB95,$BC2C,$BCE3,$BD7B
	.word	$BE33,$BEEB,$BF85,$C03F,$C0F9,$C195,$C250,$C2EE
	.word	$C3AA,$C468,$C506,$C5C4,$C684,$C724,$C7E4,$C885
	.word	$C947,$CA09,$CAAB,$CB6E,$CC32,$CCD6,$CD9B,$CE3F
	.word	$CF05,$CFCB,$D071,$D139,$D200,$D2A7,$D370,$D418
	.word	$D4E1,$D5AC,$D654,$D71F,$D7EB,$D895,$D961,$DA0C
	.word	$DAD8,$DBA6,$DC51,$DD20,$DDEE,$DE9A,$DF6A,$E017
	.word	$E0E6,$E1B7,$E264,$E335,$E406,$E4B5,$E586,$E636
	.word	$E708,$E7DA,$E88A,$E95D,$EA30,$EAE0,$EBB4,$EC64
	.word	$ED38,$EE0C,$EEBD,$EF92,$F067,$F118,$F1ED,$F29F
	.word	$F374,$F44A,$F4FC,$F5D2,$F6A7,$F75A,$F830,$F8E2
	.word	$F9B8,$FA8E,$FB41,$FC17,$FCEE,$FDA0,$FE77,$FF2A
	.word	$0000,$00D5,$0188,$025F,$0335,$03E8,$04BE,$0571
	.word	$0647,$071D,$07CF,$08A5,$097B,$0A2D,$0B03,$0BB5
	.word	$0C8B,$0D60,$0E12,$0EE7,$0FBC,$106D,$1142,$11F3
	.word	$12C7,$139B,$144B,$151F,$15F2,$16A2,$1775,$1825
	.word	$18F7,$19C9,$1A79,$1B4A,$1C1B,$1CCA,$1D9B,$1E48
	.word	$1F19,$1FE8,$2095,$2165,$2233,$22DF,$23AE,$2459
	.word	$2527,$25F3,$269E,$276A,$2836,$28E0,$29AB,$2A53
	.word	$2B1E,$2BE7,$2C8F,$2D58,$2E20,$2EC6,$2F8E,$3034
	.word	$30FA,$31C0,$3264,$3329,$33EE,$3491,$3554,$35F6
	.word	$36B8,$377A,$381B,$38DB,$399B,$3A3B,$3AF9,$3B97
	.word	$3C55,$3D11,$3DAF,$3E6A,$3F25,$3FC0,$407A,$4114
	.word	$41CC,$4284,$431C,$43D3,$4488,$451E,$45D3,$4668
	.word	$471B,$47CD,$4860,$4911,$49C1,$4A52,$4B01,$4B91
	.word	$4C3E,$4CEA,$4D78,$4E22,$4ECC,$4F58,$5000,$508C
	.word	$5131,$51D7,$5260,$5303,$53A7,$542E,$54CE,$5554
	.word	$55F3,$5692,$5715,$57B2,$584D,$58CF,$5968,$59E8
	.word	$5A81,$5B17,$5B94,$5C2A,$5CBE,$5D39,$5DCC,$5E44
	.word	$5ED5,$5F65,$5FDB,$6069,$60F5,$6169,$61F5,$6267
	.word	$62EF,$6378,$63E7,$646C,$64F2,$655E,$65E1,$664D
	.word	$66CD,$674C,$67B6,$6832,$68AF,$6915,$698E,$69F4
	.word	$6A6B,$6AE1,$6B44,$6BB8,$6C2B,$6C8B,$6CFB,$6D58
	.word	$6DC8,$6E35,$6E8F,$6EFB,$6F65,$6FBD,$7025,$707A
	.word	$70E0,$7145,$7197,$71FA,$725A,$72AA,$730A,$7357
	.word	$73B3,$740F,$7459,$74B2,$750A,$7551,$75A6,$75ED
	.word	$763F,$7691,$76D3,$7722,$7771,$77B0,$77FB,$7839
	.word	$7882,$78C9,$7905,$7949,$798D,$79C5,$7A06,$7A3B
	.word	$7A7B,$7AB7,$7AEA,$7B25,$7B5F,$7B8E,$7BC5,$7BF2
	.word	$7C28,$7C5A,$7C84,$7CB6,$7CE5,$7D0B,$7D39,$7D5D
	.word	$7D87,$7DB1,$7DD2,$7DF9,$7E1E,$7E3B,$7E5F,$7E7A
	.word	$7E9A,$7EBA,$7ED2,$7EEE,$7F0A,$7F1E,$7F36,$7F4A
	.word	$7F5F,$7F74,$7F84,$7F95,$7FA6,$7FB3,$7FC0,$7FCB
	.word	$7FD6,$7FDF,$7FE7,$7FEE,$7FF3,$7FF8,$7FFB,$7FFC

;--------------------------------------------------------------------
Mode7Char:
;--------------------------------------------------------------------
	.incbin	"../dist/m7scroll.pc7"
;--------------------------------------------------------------------
Mode7Pal:
;--------------------------------------------------------------------
	.incbin	"../dist/m7scroll.pal"
;--------------------------------------------------------------------

