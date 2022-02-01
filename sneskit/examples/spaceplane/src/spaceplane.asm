;-------------------------------------------------------------------------;
.include "fade.inc"
.include "graphics.inc"
.include "macros.inc"
.include "options.inc"
.include "plasma.inc"
.include "text.inc"
.include "shadow_ram.inc"
.include "snes.inc"
.include "snes_decompress.inc"
.include "snes_joypad.inc"
.include "snes_zvars.inc"
.include "spaceplane.inc"
;-------------------------------------------------------------------------;
.export SINUS
;-------------------------------------------------------------------------;

;Make Sure to use the Right Tabulator Sizes: (Make sure always two ";" are under each other!)

;This Colons :
;	;	;	;	;	;	;	;	;	;	;;	;

;Should Be in same Position as this:
;                  ;      ;         ;       ;       ;       ;       ;       ;       ;       ;   ;   ;
;
;
;	*********************************************************
;	****     The Source of MAGiCAL's "First Try" Demo    ****
;	*********************************************************
;
;	Author:	Pothead of Magical/Abandon [now Anthrox]
;			E-Mail: struve@uni-paderborn.de [inter-net]
;	Date:		Beginning of 1994
;	Machine:	Super Nintende (65816)
;	Assembled with:	SASM V1.81
;
;	Produced using SASM Copyrighted by INFERNAL BYTES!	
;	               ^^^^
;	Created with THE EDGE .. The Best Text-Editor Ever!
;
;	Other Tools used:
;
;	Wildsend by AMR
;	PicCon by Morten Eriksen
;	ASM-One by The Flame Arrows
;	Super Magic Disassembler V1.1 (c) 1994 -PAN- of Anthrox
;	Deluxe Paint 4 [AGA]
;	Scenery Animator
;
;
;	Note :	This Source was written by me in half a year.
;		it is mainly without Comments (Sorry!) and was
;		assembled using the SASM V1.81. I am not sure wether
;		the Non-Registered Version of SASM still manages to
;		assemble this file.
;		Feel free to learn or use Parts of it, but PLEASE dont
;		change only a logo and release the shit.
;		I released this Source, cause my new Demo will be ready
;		in the next one or two weeks and the Effects in this demo
;		were quite ... and the code wasn't to well structured.
;		I hope this Source helps other coders to produce 
;		Demos on the Super Nintendo, cause there weren't many
;		releases in the past year.
;		If u use parts or Routines for your own productions, it would
;		be nice if you mention me.
;
;	If you want to produce Programms for the Super-Nintendo , use
;	the SASM , the ultimate SNES Assembler, written by Florian
;	Sauer.
;
;	The SASM is Shareware,u have to register to get a Registered
;	Version of it, which includes:
;
;	1.) a fast 68030 Snes-Assembler for high speed assembling.
;	2.) a low-memory-consuming 68000 Version of the SASM.
;	3.) a nice TeX Manual for the SASM.
;	4.) Include-Files for things like : Reset-Handler,Sinus-Table-Creation...
;	5.) Sinple Example Source to see how to use SASM.
;	6.) Tools for sending the Programm to a Super Magicom,Procom,Wildcard or 
;	    Pro-Fighter Q or compatible.And other usefull tools.
;	7.) and more...
;
;	To register for the SASM send 100 German Mark or 70 US Dollars to:
;
;				Florian Sauer
;				Hachumerstr. 48
;				31167 Bockenem
;				Germany
;
;
;	Credits for this Production:
;
;		The Graphix were done by:
;		Noogman of Complex and Death Angle of Magical.
;		The Tunes were done (and COPYRIGHTED!) by:
;		Factor 5 and The Creators of WOLFCHILD.
;;		All Coding was done by:
;		The Pothead of Magical (now Anthrox)
;
;	Ok now the Source Starts have fun (???) trying to understand my more
;	hacking then programming :

;	btw:	This was the first thing i ever coded on the SNES, so it is
;		written in bad style, i use Absolute Adressing all the time,
;		and the Adresses (Zero-Page) are not re-allocateable, so sorry
;		for this ...


;-------------------------------------------------------------------------;
BG1GFX = 08000h
BG1MAP = 0b800h
BG3GFX = 0c000h
BG3MAP = 0e800h

HDMA_RAM = 0500h
M7PAL_START = 20
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
.zeropage
;/////////////////////////////////////////////////////////////////////////;


;-------------------------------------------------------------------------;
map_xpos:
	.res 2
map_ypos:
	.res 2
sc3_pos:
	.res 2
scrolltxt:
	.res 2
storage1:
	.res 2
storage2:
	.res 2
storage5:
	.res 2
storage6:
	.res 2
storage7:
	.res 2
storage8:
	.res 2
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
.code
;/////////////////////////////////////////////////////////////////////////;


;-------------------------------------------------------------------------;
	.a8
	.i16
;-------------------------------------------------------------------------;


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
DoSpacePlane:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	rep	#10h
	sep	#20h

	lda	#30h
	sta	REG_CGSWSEL
	lda	#0e0h
	sta	REG_COLDATA
	lda	#M7SEL_REPEAT
	sta	REG_M7SEL

	lda	#BG1MAP>>9
	sta	REG_BG1SC
	stz	REG_BG2SC
	lda	#BG3MAP>>9|SC_64x32
	sta	REG_BG3SC
	stz	REG_BG4SC

	lda	#BG1GFX>>13
	sta	REG_BG12NBA
	lda	#BG3GFX>>13
	sta	REG_BG34NBA

	lda	#04h
	sta	REG_BG3VOFS
	stz	REG_BG3VOFS

	lda	#BGMODE_7
	sta	REG_BGMODE

	lda	#TM_BG3|TM_BG1
	sta	REG_TM
	stz	REG_TS

	DoDecompressDataVram gfx_logoTiles, BG1GFX
	DoDecompressDataVram gfx_logoMap,   BG1MAP
	DoDecompressDataVram gfx_charTiles, BG3GFX

	lda	#VMAIN_INCH
	sta	REG_VMAIN

	rep	#20h

	ldx	#BG3MAP/2
	stx	REG_VMADDL

	lda	#380
	ldx	#0000h
	txy
init1:	sta	REG_VMDATAL
	inx
	cpx	#0800h
	bne	init1

	sep	#20h

	tyx
	stx	REG_VMADDL

init2:	lda	SPACE_MAP,x
	sta	REG_VMDATAL
	lda	f:SPACE_TILES,x
	clc
	adc	#M7PAL_START
	sta	REG_VMDATAH
	inx
	cpx	#4000h
	bne	init2

	DoCopyPalette gfx_logoPal,0,16
	DoCopyPalette gfx_charPal,16,4
	DoCopyPalette SPACE_PALETTE,M7PAL_START,16

	jsr	SpacePlaneDMA

	ldx	#0100h
	stx	map_xpos
	stx	map_ypos
	ldx	#0000h
	stx	scrolltxt
	stx	storage5
	stx	sc3_pos
	inx
	stx	storage2

	lda	#%00110011
	sta	REG_W12SEL
	sta	REG_W34SEL

	lda	#03h
	sta	REG_WOBJSEL
	stz	REG_WBGLOG
	stz	REG_WOBJLOG

	lda	#TMW_BG3|TMW_BG2|TMW_BG1
	sta	REG_TMW
	stz	REG_TSW

	lda	#0ffh
	sta	REG_WH1
	stz	REG_WH0

	lda	#%11111111
	sta	REG_HDMAEN
	sta	reg_inidisp		; exit when reg_inidisp == 0

	lda	#NMI_JOYPAD
	sta	REG_NMITIMEN
;-------------------------------------------------------------------------;
ZoomIn2:
;-------------------------------------------------------------------------;
	lda	REG_HVBJOY
	and	#80h
	beq	ZoomIn2
;-------------------------------------------------------------------------;
W84VBlank3:	
;-------------------------------------------------------------------------;
	lda	REG_HVBJOY
	and	#80h
	bne	W84VBlank3
;-------------------------------------------------------------------------;
	dec	HDMA_RAM+(LIST_WH0-HDMA_LIST)
	lda	HDMA_RAM+(LIST_WH0-HDMA_LIST)
	sta	REG_WH0
	eor	#0ffh
	inc	a
	sta	REG_WH1

	inc	HDMA_RAM+(LIST_WH0-HDMA_LIST)+02h
	inc	HDMA_RAM+(LIST_WH0-HDMA_LIST)+04h
	lda	HDMA_RAM+(LIST_WH0-HDMA_LIST)+04h
	cmp	#6eh
	bne	ZoomIn2
;-------------------------------------------------------------------------;
	lda	#04h
	sta	REG_A1T7L
;-------------------------------------------------------------------------;
Forever:
;-------------------------------------------------------------------------;
waitvb:	lda	REG_RDNMI
	bpl	waitvb

	jsr	Scroll
	jsr	SpacePlane

	sep	#20h

	lda	reg_inidisp
	bne	Forever
	rts
;-------------------------------------------------------------------------;


;************************ IRQ for SPACEPLANE Part ************************;
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
SpacePlane:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	rep	#30h

	lda	map_xpos
	sec
	sbc	#80h
	sta	HDMA_RAM+(LIST_BG1HOFS-HDMA_LIST)+04h

	lda	map_xpos

	sep	#20h

	sta	REG_M7X
	xba
	sta	REG_M7X

	rep	#20h

	lda	map_ypos
	sec
	sbc	#0c0h
	sta	HDMA_RAM+(LIST_BG1VOFS-HDMA_LIST)+04h

	lda	map_ypos
	sta	REG_M7Y
	xba
	sta	REG_M7Y

	ldy	storage5
	lda	COSINE,y
	sta	storage7
	lda	SINUS,y
	sta	storage6

	ldy	#0003h
	ldx	#10bdh
	lda	#0011h
	sta	storage8
;-------------------------------------------------------------------------;
Loop3D:	
;-------------------------------------------------------------------------;
	sep	#20h

	stx	REG_WRDIVL
	lda	storage8
	sta	REG_WRDIVB

.repeat 5
	nop
.endrepeat

	dex
	inc	storage8
	lda	REG_RDDIVL
	sta	REG_WRMPYA

	rep	#20h

	lda	storage7
	bpl	JobSpace0
;-------------------------------------------------------------------------;
	eor	#0ffffh
	inc	a

	sep	#20h

	sta	REG_WRMPYB
	nop
	iny

	rep	#20h

	lda	REG_RDMPYL
	and	#0ff80h
	asl	a
	bcc	:+
;-------------------------------------------------------------------------;
	inc	a
;-------------------------------------------------------------------------;
:	xba
	eor	#0ffffh
	inc	a
	sta	HDMA_RAM+(LIST_M7A-HDMA_LIST),y
	sta	HDMA_RAM+(LIST_M7D-HDMA_LIST),y
	bra	JobSpace1
;-------------------------------------------------------------------------;
JobSpace0:
;-------------------------------------------------------------------------;
	sep	#20h

	sta	REG_WRMPYB
	nop
	iny

	rep	#20h

	lda	REG_RDMPYL
	and	#0ff80h
	asl	a
	bcc	:+
;-------------------------------------------------------------------------;
	inc	a
;-------------------------------------------------------------------------;
:	xba

	sta	HDMA_RAM+(LIST_M7A-HDMA_LIST),y
	sta	HDMA_RAM+(LIST_M7D-HDMA_LIST),y
;-------------------------------------------------------------------------;
JobSpace1:
;-------------------------------------------------------------------------;
	lda	storage6
	bpl	JobSpace2
;-------------------------------------------------------------------------;
	eor	#0ffffh
	inc	a

	sep	#20h

	sta	REG_WRMPYB
	iny
	iny

	rep	#20h

	lda	REG_RDMPYL

	and	#0ff80h
	asl	a
	bcc	:+
;-------------------------------------------------------------------------;
	inc	a
;-------------------------------------------------------------------------;
:	xba

	sta	HDMA_RAM+(LIST_M7C-HDMA_LIST)-2,y
	eor	#0ffffh
	inc	a
	sta	HDMA_RAM+(LIST_M7B-HDMA_LIST)-2,y
	bra	JobSpace3
;-------------------------------------------------------------------------;
JobSpace2:
;-------------------------------------------------------------------------;
	sep	#20h

	sta	REG_WRMPYB
	iny
	iny

	rep	#20h

	lda	REG_RDMPYL

	and	#0ff80h
	asl	a
	bcc	:+
;-------------------------------------------------------------------------;
	inc	a
;-------------------------------------------------------------------------;
:	xba
	sta	HDMA_RAM+(LIST_M7B-HDMA_LIST)-2,y
	eor	#0ffffh
	inc	a
	sta	HDMA_RAM+(LIST_M7C-HDMA_LIST)-2,y
;-------------------------------------------------------------------------;
JobSpace3:
;-------------------------------------------------------------------------;
	cpy	#LIST_M7B-LIST_M7A
	beq	FinishedSpace
;-------------------------------------------------------------------------;
	jmp	Loop3D
;-------------------------------------------------------------------------;
FinishedSpace:
;-------------------------------------------------------------------------;
	sep	#20h
;-------------------------------------------------------------------------;
SpacePad:
;-------------------------------------------------------------------------;
	lda	REG_HVBJOY
	and	#01h
	bne	SpacePad
;-------------------------------------------------------------------------;
	rep	#20h

	lda	storage2
	eor	#03h
	sta	storage2

	jsr	TestQuit
					; a,x = value of REG_JOY1L
	and	#JOYPAD_R
	beq	NotRight
;-------------------------------------------------------------------------;
	lda	storage5
	clc
	adc	#04h
	and	#07ffh
	sta	storage5
;-------------------------------------------------------------------------;
NotRight:
;-------------------------------------------------------------------------;
	txa
	and	#JOYPAD_L
	beq	NotLeft
;-------------------------------------------------------------------------;
	lda	storage5
	sec
	sbc	#04h
	and	#07ffh
	sta	storage5
;-------------------------------------------------------------------------;
NotLeft:
;-------------------------------------------------------------------------;
	txa
	and	#0f00h
	xba
	asl	a
	tax
	lda	DIR_TAB,x
	beq	NoPadMove
;-------------------------------------------------------------------------;
	sta	storage1
	lda	storage5
	clc
	adc	#55h
	sta	REG_WRDIVL

	sep	#20h

	lda	#0aah
	sta	REG_WRDIVB

.repeat 8
	nop
.endrepeat

	lda	REG_RDDIVL

	rep	#20h

	and	#000fh
	clc
	asl	a
	adc	storage1
	tax

.ifdef BANK_ZERO
	jsr	(DIRECTION,x)
.else
	lda	DIRECTION,x
	sta	m0
	jmp	(m0)
.endif
;-------------------------------------------------------------------------;
NoPadMove:				; a,x,y = 16b
;-------------------------------------------------------------------------;
	rts
;-------------------------------------------------------------------------;
UP:	ldx	map_xpos
	inx
	inx
	cpx	#0400h
	bcc	:+
	dex
	dex
:	stx	map_xpos
Ntg:	rts
;-------------------------------------------------------------------------;
DOWN:	ldx	map_xpos
	dex
	dex
	bpl	:+
	inx
	inx
:	stx	map_xpos
	rts
;-------------------------------------------------------------------------;
LEFT:	ldx	map_ypos
	inx
	inx
	cpx	#0400h
	bcc	:+
	dex
	dex
:	stx	map_ypos
	rts
;-------------------------------------------------------------------------;
RIGHT:	ldx	map_ypos
	dex
	dex
	bpl	:+
	inx
	inx
:	stx	map_ypos
	rts
;-------------------------------------------------------------------------;
DWNRIG:	lda	map_ypos
	dec	a
	bpl	:+
	inc	a
:	sta	map_ypos
	lda	map_xpos
	dec	a
	dec	a
	bpl	:+
	inc	a
	inc	a
:	sta	map_xpos
	rts
;-------------------------------------------------------------------------;
DWNRIG1:
	lda	map_ypos
	dec	a
	dec	a
	bpl	:+
	inc	a
	inc	a
:	sta	map_ypos
	lda	map_xpos
	dec	a
	bpl	:+
	inc	a
:	sta	map_xpos
	rts
;-------------------------------------------------------------------------;
DWNLEF:	lda	map_ypos
	cmp	#0400h
	bcs	:+
	inc	a
:	sta	map_ypos
	lda	map_xpos
	dec	a
	dec	a
	bpl	:+
	inc	a
	inc	a
:	sta	map_xpos
	rts
;-------------------------------------------------------------------------;
DWNLEF1:
	lda	map_ypos
	cmp	#0400h
	bcs	:+
	inc	a
	inc	a
:	sta	map_ypos
	lda	map_xpos
	dec	a
	bpl	:+
	inc	a
:	sta	map_xpos
	rts
;-------------------------------------------------------------------------;
UPRIG:	lda	map_ypos
	dec	a
	bpl	:+
	inc	a
:	sta	map_ypos
	lda	map_xpos
	cmp	#0400h
	bcs	:+
	inc	a
	inc	a
:	sta	map_xpos
	rts
;-------------------------------------------------------------------------;
UPRIG1:	lda	map_ypos
	dec	a
	dec	a
	bpl	:+
	inc	a
	inc	a
:	sta	map_ypos
	lda	map_xpos
	cmp	#0400h
	bcs	:+
	inc	a
:	sta	map_xpos
	rts
;-------------------------------------------------------------------------;
UPLEF:	lda	map_ypos
	cmp	#0400h
	bcs	:+
	inc	a
:	sta	map_ypos
	lda	map_xpos
	cmp	#0400h
	bcs	:+
	inc	a
	inc	a
:	sta	map_xpos
	rts
;-------------------------------------------------------------------------;
UPLEF1:	lda	map_ypos
	cmp	#0400h
	bcs	:+
	inc	a
	inc	a
:	sta	map_ypos
	lda	map_xpos
	cmp	#0400h
	bcs	:+
	inc	a
:	sta	map_xpos
	rts


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
TestQuit:				; a,x,y = 16b
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	ldx	REG_JOY1L
	txa
	bit	#JOYPAD_START
	bne	EndRoutine
	bit	#JOYPAD_A
	beq	exit1
;-------------------------------------------------------------------------;
EndRoutine:
;-------------------------------------------------------------------------;
	lda	plasma_mode
	bit	#PLASMAON
	bne	:+
;-------------------------------------------------------------------------;
	lda	#80h
	sta	REG_INIDISP
	stz	REG_HDMAEN
	stz	reg_inidisp
	bra	exit1
;-------------------------------------------------------------------------;
:	lda	#OPTION_FADE_OUT
	tsb	options
;-------------------------------------------------------------------------;
exit1:	rts


;-------------------------------------------------------------------------;
adc79:					; a,x,y = 16b
;-------------------------------------------------------------------------;
	clc
	adc	#79
;-------------------------------------------------------------------------;
:	tax
	tya
	sta	REG_VMADDL
	clc
	adc	#20h
	tay
	txa
	sta	REG_VMDATAL
	inc	a
	sta	REG_VMDATAL
	rts
;=========================================================================;
Scroll:					; a = 8b
;=========================================================================;
	sep	#20h

	lda	sc3_pos
	sta	REG_BG3HOFS
	stz	REG_BG3HOFS
	lda	sc3_pos
	inc	a
	and	#0fh
	cmp	#01h
	bne	:+
;-------------------------------------------------------------------------;
	ldx	scrolltxt
	inx
	stx	scrolltxt
;-------------------------------------------------------------------------;
:	sta	sc3_pos
	ldy	#BG3MAP/2+140h

	rep	#20h
;-------------------------------------------------------------------------;
ScrollLoop:
;-------------------------------------------------------------------------;
	ldx	scrolltxt
	inc	scrolltxt
	lda	SPACEPLANE_TEXT,x
	asl	a
	and	#00feh
	tax
	lda	f:ASCII_TABLE,x

	jsr	:--
	jsr	adc79
	jsr	adc79
	clc
	adc	#79

	tax
	tya
	sta	REG_VMADDL
	sec
	sbc	#5eh
	tay
	txa
	sta	REG_VMDATAL
	inc	a
	sta	REG_VMDATAL
	cpy	#BG3MAP/2+160h
	bne	ScrollLoop
;-------------------------------------------------------------------------;
	lda	scrolltxt
	tax
	sec
	sbc	#10h
	sta	scrolltxt
	lda	SPACEPLANE_TEXT,x
	cmp	#0ffffh
	bne	:+
;-------------------------------------------------------------------------;
	stz	scrolltxt

	lda	#0020h
;-------------------------------------------------------------------------;
:	asl	a
	and	#00feh
	tax
	lda	f:ASCII_TABLE,x
	tax
	lda	#BG3MAP/2+540h
	sta	REG_VMADDL
	clc
	adc	#20h
	tay
	txa
	sta	REG_VMDATAL
	inc	a
	sta	REG_VMDATAL

	jsr	adc79
	jsr	adc79
	jsr	adc79

	sep	#20h

	rts


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
PlasmaMapSpacePlaneDMA:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	jsr	SpacePlaneDMA
	lda	#80
	sta	HDMA_RAM
	sta	HDMA_RAM+(LIST_M7A-HDMA_LIST)
	sta	HDMA_RAM+(LIST_M7B-HDMA_LIST)
	sta	HDMA_RAM+(LIST_M7C-HDMA_LIST)
	sta	HDMA_RAM+(LIST_M7D-HDMA_LIST)
	sta	HDMA_RAM+(LIST_INIDISP-HDMA_LIST)
	sta	HDMA_RAM+(LIST_BG1HOFS-HDMA_LIST)
	sta	HDMA_RAM+(LIST_BG1VOFS-HDMA_LIST)
	rts


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
SpacePlaneDMA:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	InitHDMA HDMA_LIST,^HDMA_LIST,HDMA_TABLE-HDMA_LIST,HDMA_TABLE,HDMA_TABLE_END-HDMA_TABLE,0,HDMA_RAM

	lda	#28h
	sta	REG_A1T7L

	lda	#0e8h
	sta	REG_VTIMEL
	stz	REG_VTIMEH

	rts


;/////////////////////////////////////////////////////////////////////////;
.segment "DATA"
;/////////////////////////////////////////////////////////////////////////;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
DIR_TAB:.word	0,8,20,0,2,6,22,0,14,10,18,0,0,0,0,0
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
DIRECTION:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.word	Ntg,LEFT,UPLEF1,UPLEF,UP,UPRIG,UPRIG1,RIGHT
	.word	DWNRIG1,DWNRIG,DOWN,DWNLEF,DWNLEF1,LEFT,UPLEF1,UPLEF
	.word	UP,UPRIG,UPRIG1,RIGHT,DWNRIG1,DWNRIG,DOWN,DWNLEF
	.word	DWNLEF1,LEFT,UPLEF1,UPLEF,UP,UPRIG,UPRIG1,RIGHT,DWNRIG1
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SINUS:	.word	$0000,$0001,$0002,$0004,$0005,$0007,$0008,$000A
	.word	$000C,$000D,$000F,$0010,$0012,$0013,$0015,$0016
	.word	$0018,$001A,$001B,$001D,$001E,$0020,$0021,$0023
	.word	$0024,$0026,$0027,$0029,$002B,$002C,$002E,$002F
	.word	$0031,$0032,$0034,$0035,$0037,$0038,$003A,$003B
	.word	$003D,$003F,$0040,$0042,$0043,$0044,$0046,$0047
	.word	$0049,$004B,$004C,$004E,$004F,$0050,$0052,$0053
	.word	$0055,$0056,$0058,$0059,$005B,$005C,$005E,$005F
	.word	$0061,$0062,$0063,$0065,$0066,$0068,$0069,$006B
	.word	$006C,$006E,$006F,$0070,$0072,$0073,$0074,$0076
	.word	$0077,$0079,$007A,$007B,$007D,$007E,$007F,$0081
	.word	$0082,$0084,$0085,$0086,$0088,$0089,$008A,$008B
	.word	$008D,$008E,$008F,$0091,$0092,$0093,$0094,$0096
	.word	$0097,$0098,$0099,$009B,$009C,$009D,$009E,$009F
	.word	$00A1,$00A2,$00A3,$00A4,$00A6,$00A7,$00A8,$00A9
	.word	$00AA,$00AB,$00AC,$00AE,$00AF,$00B0,$00B1,$00B2
	.word	$00B3,$00B4,$00B5,$00B7,$00B8,$00B9,$00BA,$00BB
	.word	$00BC,$00BD,$00BE,$00BF,$00C0,$00C1,$00C2,$00C3
	.word	$00C4,$00C5,$00C6,$00C7,$00C8,$00C9,$00CA,$00CB
	.word	$00CC,$00CD,$00CE,$00CF,$00D0,$00D0,$00D1,$00D2
	.word	$00D3,$00D4,$00D5,$00D6,$00D7,$00D7,$00D8,$00D9
	.word	$00DA,$00DB,$00DB,$00DC,$00DD,$00DE,$00DE,$00DF
	.word	$00E0,$00E1,$00E1,$00E2,$00E3,$00E3,$00E4,$00E5
	.word	$00E6,$00E6,$00E7,$00E7,$00E8,$00E9,$00E9,$00EA
	.word	$00EB,$00EB,$00EC,$00EC,$00ED,$00ED,$00EE,$00EF
	.word	$00EF,$00F0,$00F0,$00F1,$00F1,$00F2,$00F2,$00F3
	.word	$00F3,$00F3,$00F4,$00F4,$00F5,$00F5,$00F6,$00F6
	.word	$00F6,$00F7,$00F7,$00F7,$00F8,$00F8,$00F8,$00F9
	.word	$00F9,$00F9,$00FA,$00FA,$00FA,$00FA,$00FB,$00FB
	.word	$00FB,$00FB,$00FC,$00FC,$00FC,$00FC,$00FC,$00FD
	.word	$00FD,$00FD,$00FD,$00FD,$00FD,$00FD,$00FE,$00FE
	.word	$00FE,$00FE,$00FE,$00FE,$00FE,$00FE,$00FE,$00FE
COSINE:	.word	$00FE,$00FE,$00FE,$00FE,$00FE,$00FE,$00FE,$00FE
	.word	$00FE,$00FE,$00FE,$00FD,$00FD,$00FD,$00FD,$00FD
	.word	$00FD,$00FD,$00FC,$00FC,$00FC,$00FC,$00FC,$00FB
	.word	$00FB,$00FB,$00FB,$00FA,$00FA,$00FA,$00FA,$00F9
	.word	$00F9,$00F9,$00F8,$00F8,$00F8,$00F7,$00F7,$00F7
	.word	$00F6,$00F6,$00F6,$00F5,$00F5,$00F4,$00F4,$00F3
	.word	$00F3,$00F3,$00F2,$00F2,$00F1,$00F1,$00F0,$00F0
	.word	$00EF,$00EF,$00EE,$00ED,$00ED,$00EC,$00EC,$00EB
	.word	$00EB,$00EA,$00E9,$00E9,$00E8,$00E7,$00E7,$00E6
	.word	$00E6,$00E5,$00E4,$00E3,$00E3,$00E2,$00E1,$00E1
	.word	$00E0,$00DF,$00DE,$00DE,$00DD,$00DC,$00DB,$00DB
	.word	$00DA,$00D9,$00D8,$00D7,$00D6,$00D6,$00D5,$00D4
	.word	$00D3,$00D2,$00D1,$00D0,$00CF,$00CF,$00CE,$00CD
	.word	$00CC,$00CB,$00CA,$00C9,$00C8,$00C7,$00C6,$00C5
	.word	$00C4,$00C3,$00C2,$00C1,$00C0,$00BF,$00BE,$00BD
	.word	$00BC,$00BB,$00BA,$00B9,$00B8,$00B7,$00B5,$00B4
	.word	$00B3,$00B2,$00B1,$00B0,$00AF,$00AE,$00AC,$00AB
	.word	$00AA,$00A9,$00A8,$00A7,$00A5,$00A4,$00A3,$00A2
	.word	$00A1,$009F,$009E,$009D,$009C,$009B,$0099,$0098
	.word	$0097,$0096,$0094,$0093,$0092,$0091,$008F,$008E
	.word	$008D,$008B,$008A,$0089,$0087,$0086,$0085,$0084
	.word	$0082,$0081,$007F,$007E,$007D,$007B,$007A,$0079
	.word	$0077,$0076,$0074,$0073,$0072,$0070,$006F,$006E
	.word	$006C,$006B,$0069,$0068,$0066,$0065,$0063,$0062
	.word	$0061,$005F,$005E,$005C,$005B,$0059,$0058,$0056
	.word	$0055,$0053,$0052,$0050,$004F,$004E,$004C,$004B
	.word	$0049,$0047,$0046,$0044,$0043,$0042,$0040,$003F
	.word	$003D,$003B,$003A,$0038,$0037,$0035,$0034,$0032
	.word	$0031,$002F,$002E,$002C,$002A,$0029,$0027,$0026
	.word	$0024,$0023,$0021,$0020,$001E,$001D,$001B,$001A
	.word	$0018,$0016,$0015,$0013,$0012,$0010,$000F,$000D
	.word	$000C,$000A,$0008,$0007,$0005,$0004,$0002,$0001
MSINUS:	.word	$0000,$FFFE,$FFFD,$FFFB,$FFFA,$FFF8,$FFF7,$FFF5
	.word	$FFF3,$FFF2,$FFF0,$FFEF,$FFED,$FFEC,$FFEA,$FFE9
	.word	$FFE7,$FFE5,$FFE4,$FFE2,$FFE1,$FFDF,$FFDE,$FFDC
	.word	$FFDB,$FFD9,$FFD8,$FFD6,$FFD4,$FFD3,$FFD1,$FFD0
	.word	$FFCE,$FFCD,$FFCB,$FFCA,$FFC8,$FFC7,$FFC5,$FFC4
	.word	$FFC2,$FFC0,$FFBF,$FFBD,$FFBC,$FFBB,$FFB9,$FFB8
	.word	$FFB6,$FFB4,$FFB3,$FFB1,$FFB0,$FFAF,$FFAD,$FFAC
	.word	$FFAA,$FFA9,$FFA7,$FFA6,$FFA4,$FFA3,$FFA1,$FFA0
	.word	$FF9E,$FF9D,$FF9C,$FF9A,$FF99,$FF97,$FF96,$FF94
	.word	$FF93,$FF91,$FF90,$FF8F,$FF8D,$FF8C,$FF8B,$FF89
	.word	$FF88,$FF86,$FF85,$FF84,$FF82,$FF81,$FF80,$FF7E
	.word	$FF7D,$FF7B,$FF7A,$FF79,$FF77,$FF76,$FF75,$FF74
	.word	$FF72,$FF71,$FF70,$FF6E,$FF6D,$FF6C,$FF6B,$FF69
	.word	$FF68,$FF67,$FF66,$FF64,$FF63,$FF62,$FF61,$FF60
	.word	$FF5E,$FF5D,$FF5C,$FF5B,$FF59,$FF58,$FF57,$FF56
	.word	$FF55,$FF54,$FF53,$FF51,$FF50,$FF4F,$FF4E,$FF4D
	.word	$FF4C,$FF4B,$FF4A,$FF48,$FF47,$FF46,$FF45,$FF44
	.word	$FF43,$FF42,$FF41,$FF40,$FF3F,$FF3E,$FF3D,$FF3C
	.word	$FF3B,$FF3A,$FF39,$FF38,$FF37,$FF36,$FF35,$FF34
	.word	$FF33,$FF32,$FF31,$FF30,$FF2F,$FF2F,$FF2E,$FF2D
	.word	$FF2C,$FF2B,$FF2A,$FF29,$FF28,$FF28,$FF27,$FF26
	.word	$FF25,$FF24,$FF24,$FF23,$FF22,$FF21,$FF21,$FF20
	.word	$FF1F,$FF1E,$FF1E,$FF1D,$FF1C,$FF1C,$FF1B,$FF1A
	.word	$FF19,$FF19,$FF18,$FF18,$FF17,$FF16,$FF16,$FF15
	.word	$FF14,$FF14,$FF13,$FF13,$FF12,$FF12,$FF11,$FF10
	.word	$FF10,$FF0F,$FF0F,$FF0E,$FF0E,$FF0D,$FF0D,$FF0C
	.word	$FF0C,$FF0C,$FF0B,$FF0B,$FF0A,$FF0A,$FF09,$FF09
	.word	$FF09,$FF08,$FF08,$FF08,$FF07,$FF07,$FF07,$FF06
	.word	$FF06,$FF06,$FF05,$FF05,$FF05,$FF05,$FF04,$FF04
	.word	$FF04,$FF04,$FF03,$FF03,$FF03,$FF03,$FF03,$FF02
	.word	$FF02,$FF02,$FF02,$FF02,$FF02,$FF02,$FF01,$FF01
	.word	$FF01,$FF01,$FF01,$FF01,$FF01,$FF01,$FF01,$FF01
	.word	$FF01,$FF01,$FF01,$FF01,$FF01,$FF01,$FF01,$FF01
	.word	$FF01,$FF01,$FF01,$FF02,$FF02,$FF02,$FF02,$FF02
	.word	$FF02,$FF02,$FF03,$FF03,$FF03,$FF03,$FF03,$FF04
	.word	$FF04,$FF04,$FF04,$FF05,$FF05,$FF05,$FF05,$FF06
	.word	$FF06,$FF06,$FF07,$FF07,$FF07,$FF08,$FF08,$FF08
	.word	$FF09,$FF09,$FF09,$FF0A,$FF0A,$FF0B,$FF0B,$FF0C
	.word	$FF0C,$FF0C,$FF0D,$FF0D,$FF0E,$FF0E,$FF0F,$FF0F
	.word	$FF10,$FF10,$FF11,$FF12,$FF12,$FF13,$FF13,$FF14
	.word	$FF14,$FF15,$FF16,$FF16,$FF17,$FF18,$FF18,$FF19
	.word	$FF19,$FF1A,$FF1B,$FF1C,$FF1C,$FF1D,$FF1E,$FF1E
	.word	$FF1F,$FF20,$FF21,$FF21,$FF22,$FF23,$FF24,$FF24
	.word	$FF25,$FF26,$FF27,$FF28,$FF29,$FF29,$FF2A,$FF2B
	.word	$FF2C,$FF2D,$FF2E,$FF2F,$FF30,$FF30,$FF31,$FF32
	.word	$FF33,$FF34,$FF35,$FF36,$FF37,$FF38,$FF39,$FF3A
	.word	$FF3B,$FF3C,$FF3D,$FF3E,$FF3F,$FF40,$FF41,$FF42
	.word	$FF43,$FF44,$FF45,$FF46,$FF47,$FF48,$FF4A,$FF4B
	.word	$FF4C,$FF4D,$FF4E,$FF4F,$FF50,$FF51,$FF53,$FF54
	.word	$FF55,$FF56,$FF57,$FF58,$FF5A,$FF5B,$FF5C,$FF5D
	.word	$FF5E,$FF60,$FF61,$FF62,$FF63,$FF64,$FF66,$FF67
	.word	$FF68,$FF69,$FF6B,$FF6C,$FF6D,$FF6E,$FF70,$FF71
	.word	$FF72,$FF74,$FF75,$FF76,$FF78,$FF79,$FF7A,$FF7B
	.word	$FF7D,$FF7E,$FF80,$FF81,$FF82,$FF84,$FF85,$FF86
	.word	$FF88,$FF89,$FF8B,$FF8C,$FF8D,$FF8F,$FF90,$FF91
	.word	$FF93,$FF94,$FF96,$FF97,$FF99,$FF9A,$FF9C,$FF9D
	.word	$FF9E,$FFA0,$FFA1,$FFA3,$FFA4,$FFA6,$FFA7,$FFA9
	.word	$FFAA,$FFAC,$FFAD,$FFAF,$FFB0,$FFB1,$FFB3,$FFB4
	.word	$FFB6,$FFB8,$FFB9,$FFBB,$FFBC,$FFBD,$FFBF,$FFC0
	.word	$FFC2,$FFC4,$FFC5,$FFC7,$FFC8,$FFCA,$FFCB,$FFCD
	.word	$FFCE,$FFD0,$FFD1,$FFD3,$FFD5,$FFD6,$FFD8,$FFD9
	.word	$FFDB,$FFDC,$FFDE,$FFDF,$FFE1,$FFE2,$FFE4,$FFE5
	.word	$FFE7,$FFE9,$FFEA,$FFEC,$FFED,$FFEF,$FFF0,$FFF2
	.word	$FFF3,$FFF5,$FFF7,$FFF8,$FFFA,$FFFB,$FFFD,$FFFE
	.word	$0000,$0001,$0002,$0004,$0005,$0007,$0008,$000A
	.word	$000C,$000D,$000F,$0010,$0012,$0013,$0015,$0016
	.word	$0018,$001A,$001B,$001D,$001E,$0020,$0021,$0023
	.word	$0024,$0026,$0027,$0029,$002B,$002C,$002E,$002F
	.word	$0031,$0032,$0034,$0035,$0037,$0038,$003A,$003B
	.word	$003D,$003F,$0040,$0042,$0043,$0044,$0046,$0047
	.word	$0049,$004B,$004C,$004E,$004F,$0050,$0052,$0053
	.word	$0055,$0056,$0058,$0059,$005B,$005C,$005E,$005F
	.word	$0061,$0062,$0063,$0065,$0066,$0068,$0069,$006B
	.word	$006C,$006E,$006F,$0070,$0072,$0073,$0074,$0076
	.word	$0077,$0079,$007A,$007B,$007D,$007E,$007F,$0081
	.word	$0082,$0084,$0085,$0086,$0088,$0089,$008A,$008B
	.word	$008D,$008E,$008F,$0091,$0092,$0093,$0094,$0096
	.word	$0097,$0098,$0099,$009B,$009C,$009D,$009E,$009F
	.word	$00A1,$00A2,$00A3,$00A4,$00A6,$00A7,$00A8,$00A9
	.word	$00AA,$00AB,$00AC,$00AE,$00AF,$00B0,$00B1,$00B2
	.word	$00B3,$00B4,$00B5,$00B7,$00B8,$00B9,$00BA,$00BB
	.word	$00BC,$00BD,$00BE,$00BF,$00C0,$00C1,$00C2,$00C3
	.word	$00C4,$00C5,$00C6,$00C7,$00C8,$00C9,$00CA,$00CB
	.word	$00CC,$00CD,$00CE,$00CF,$00D0,$00D0,$00D1,$00D2
	.word	$00D3,$00D4,$00D5,$00D6,$00D7,$00D7,$00D8,$00D9
	.word	$00DA,$00DB,$00DB,$00DC,$00DD,$00DE,$00DE,$00DF
	.word	$00E0,$00E1,$00E1,$00E2,$00E3,$00E3,$00E4,$00E5
	.word	$00E6,$00E6,$00E7,$00E7,$00E8,$00E9,$00E9,$00EA
	.word	$00EB,$00EB,$00EC,$00EC,$00ED,$00ED,$00EE,$00EF
	.word	$00EF,$00F0,$00F0,$00F1,$00F1,$00F2,$00F2,$00F3
	.word	$00F3,$00F3,$00F4,$00F4,$00F5,$00F5,$00F6,$00F6
	.word	$00F6,$00F7,$00F7,$00F7,$00F8,$00F8,$00F8,$00F9
	.word	$00F9,$00F9,$00FA,$00FA,$00FA,$00FA,$00FB,$00FB
	.word	$00FB,$00FB,$00FC,$00FC,$00FC,$00FC,$00FC,$00FD
	.word	$00FD,$00FD,$00FD,$00FD,$00FD,$00FD,$00FE,$00FE
	.word	$00FE,$00FE,$00FE,$00FE,$00FE,$00FE,$00FE,$00FE
	.word	$00FE,$00FE,$00FE,$00FE,$00FE,$00FE,$00FE,$00FE
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
HDMA_LIST:
LIST_BGMODE:	; 6 bytes
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	120,BGMODE_1,1,BGMODE_7,0,0
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_M7A:	; 315 bytes
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	120,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,0,0,0
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_M7B:	; 315 bytes
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	120,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,0,0,0
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_M7C:	; 315 bytes
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	120,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,0,0,0
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_M7D:	; 315 bytes
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	120,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	.byte	1,0,0,1,0,0,1,0,0,1,0,0,0,0,0
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_BG1HOFS:	; 9 bytes
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	121,0,0,1,0,0,0,0,0
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_BG1VOFS:	; 9 bytes
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	121,0,0,1,0,0,0,0,0
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_INIDISP:	; 34 bytes
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	120,$0f,001,$00,001,$02,002,$03
	.byte	002,$04,003,$05,003,$06,004,$07
	.byte	004,$08,005,$09,005,$0a,006,$0b
	.byte	006,$0c,007,$0d,007,$0e,008,$0f
	.byte	000,0
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_WH0:	; 10 bytes
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	110,$00,$1,$0f,$1,$0f,$1,0,0,0
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
HDMA_TABLE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	DMAP_XFER_MODE_0,<REG_BGMODE
	.byte	<HDMA_RAM
	.byte	>HDMA_RAM

	.byte	DMAP_XFER_MODE_2,<REG_M7A
	.byte	<(HDMA_RAM+(LIST_M7A-HDMA_LIST))
	.byte	>(HDMA_RAM+(LIST_M7A-HDMA_LIST))

	.byte	DMAP_XFER_MODE_2,<REG_M7B
	.byte	<(HDMA_RAM+(LIST_M7B-HDMA_LIST))
	.byte	>(HDMA_RAM+(LIST_M7B-HDMA_LIST))

	.byte	DMAP_XFER_MODE_2,<REG_M7C
	.byte	<(HDMA_RAM+(LIST_M7C-HDMA_LIST))
	.byte	>(HDMA_RAM+(LIST_M7C-HDMA_LIST))

	.byte	DMAP_XFER_MODE_2,<REG_M7D
	.byte	<(HDMA_RAM+(LIST_M7D-HDMA_LIST))
	.byte	>(HDMA_RAM+(LIST_M7D-HDMA_LIST))

	.byte	DMAP_XFER_MODE_2,<REG_BG1HOFS
	.byte	<(HDMA_RAM+(LIST_BG1HOFS-HDMA_LIST))
	.byte	>(HDMA_RAM+(LIST_BG1HOFS-HDMA_LIST))

	.byte	DMAP_XFER_MODE_2,<REG_BG1VOFS
	.byte	<(HDMA_RAM+(LIST_BG1VOFS-HDMA_LIST))
	.byte	>(HDMA_RAM+(LIST_BG1VOFS-HDMA_LIST))

	.byte	DMAP_XFER_MODE_0,<REG_INIDISP
	.byte	<(HDMA_RAM+(LIST_INIDISP-HDMA_LIST))
	.byte	>(HDMA_RAM+(LIST_INIDISP-HDMA_LIST))
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
HDMA_TABLE_END:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SPACE_MAP:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.incbin "../m7gfx/spaceplane.mp7"
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;/////////////////////////////////////////////////////////////////////////;
.segment "GRAPHICS"
;/////////////////////////////////////////////////////////////////////////;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
ASCII_TABLE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.word	$117c,$117c,$117c,$117c,$117c,$117c,$117c,$117c
	.word	$117c,$117c,$117c,$117c,$117c,$117c,$117c,$117c
	.word	$117c,$117c,$117c,$117c,$117c,$117c,$117c,$117c
	.word	$117c,$117c,$117c,$117c,$117c,$117c,$117c,$117c
	.word	$117c,$1158,$117c,$117c,$117c,$117c,$117c,$117c
	.word	$1162,$1164,$117c,$117c,$1160,$1166,$115e,$117c
	.word	$117a,$1168,$116a,$116c,$116e,$1170,$1172,$1174
	.word	$1176,$1178,$115c,$1160,$117c,$117c,$117c,$115a
	.word	$117c,$1000,$1002,$1004,$1006,$1008,$100a,$100c
	.word	$100e,$1010,$1012,$1014,$1016,$1018,$101a,$101c
	.word	$101e,$1020,$1022,$1024,$1026,$1028,$102a,$102c
	.word	$102e,$1030,$1032,$117c,$117c,$117c,$117c,$117c
	.word	$117c,$1034,$1036,$1038,$103a,$103c,$103e,$1040
	.word	$1042,$1044,$1046,$1048,$104a,$104c,$104e,$1140
	.word	$1142,$1144,$1146,$1148,$114a,$114c,$114e,$1150
	.word	$1152,$1154,$1156,$117c,$117c,$117c,$117c,$117c
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SPACE_PALETTE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.incbin "../m7gfx/spaceplane.pal"
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SPACE_TILES:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.incbin	"../m7gfx/spaceplane.pc7"
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
