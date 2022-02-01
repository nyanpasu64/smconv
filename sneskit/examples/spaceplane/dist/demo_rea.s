

;Make Sure to use the Right Tabulator Sizes: (Make sure always two ";" are under each other!)

;This Colons :
;	;	;	;	;	;	;	;	;	;	;	;	;

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
;		All Coding was done by:
;		The Pothead of Magical (now Anthrox)
;
;	Ok now the Source Starts have fun (???) trying to understand my more
;	hacking then programming :

;	btw:	This was the first thing i ever coded on the SNES, so it is
;		written in bad style, i use Absolute Adressing all the time,
;		and the Adresses (Zero-Page) are not re-allocateable, so sorry
;		for this ...


	heap	O=$91000			;Allocate Memory for the SASM to work on
	lrom				;Demo is Low-ROM
	SMC+				;And add a SMC-Header

IrqPointer	EQU	$68			;Pointer for Vertical Blank Subroutines
InitPointer	EQU	$6a			;Actual Non-Irq Routine Running


	;This Lousy Piece of Code was Produced by the one and lonly Pothead
	;All rights reserved to NINTENDO (NOT!)

; ******       **                                 *******  *******   ******* **     **    ***   *** 
;   **         **                                ****     ***   *** ****     ***   ***   ***** *****
;   **         **       ****   **  **  ****       ******  ***   ***  ******  **** ****   ***** *****
;   **         **      **  **  **  ** **  **          *** *********      *** ** *** **    ***   *** 
;   **         **      **  **  **  ** ****            *** ***   ***      *** **  *  **
; ******       ******   ****     **   ******     *******  ***   *** *******  **     **    ***   *** 



	.say	First SNES-Demo written by Pothead/Magical
	.say	Using the SASM, DPaint IV and the Trash`em One
	.say	Done during 93


;	********* Macros ***********

Musik	macro				;/1=Group of Songs (0-5)
	phb				;/2=Song Number in Group:
	sep	#$30			;With Group 0: 0,1,2,3,4,5,6
	jsl	$c8009			;With Group 1: 0,1,2,3,4,5,6
	lda	#\1			;With Group 2: 0,1,2,3,4,5,6
	jsl	$c8003			;With Group 3: 0,1,2,3,4,5,6
	ldy	#\2			;With Group 4: 0,1,2
	jsl	$c8006			;With Group 5: 0
	lda	#$7f
	ldy	#$70			;Marco for Tunes from TURRICAN
	jsl	$c8012
	rep	#$30
	plb
	endm				;This Macro starts a Tune From TURRICAN

Musiky	macro				;\1=Number of tune (0-9)
	rep	#$30
	phb				;Macro for Tunes from WOLFCHILD
	lda	#\1
	jsl	$098004
	lda	#$c0
	jsl	$098008
	plb
	rep	#$30
	sep	#$20
	endm				;This Macro starts a Tune From WOLFCHILD

CopyColor	macro				;\1=Adress of Colortab in Rom
	ldx	#$0000			;\2=Destination Adress in CG-Ram
	lda	#\2			;\3=Number of Colors to be copied
	sta	$2121
.init	lda	!\1,x
	sta	$2122
	inx
	cpx	#\3*2
	bne	.init
	endm

ClearDMA	macro				;No Arguments required
	lda	#$ff
	sta	$4201
	ldx	#$000b
.Clear1	stz	$4202,x
	dex
	bpl	.Clear1
	ldx	#$007f
.Clear2	stz	$4300,x
	dex
	bpl	.Clear2
	endm

InitHDMA	macro				;\1=Adress of HDMA Lists in Rom (Source)
	rep	#$20			;\2=Length of HDMA Lists (will be copied
	ldx	#$0000			;	to $0200 in Ram
.HDMAinit1	lda	!\1,x			;\3=Adress of HDMA Register Settings in Rom
	sta	$0200,x			;\4=Length of HDMA Register Table
	inx
	inx
	cpx	#\2
	bne	.HDMAinit1
	ldx	#$0000
	ldy	#$0000
.HDMAinit2	lda	!\3,x
	sta	$4300,y
	inx
	inx
	lda	!\3,x
	sta	$4302,y
	inx
	inx
	lda	#$00
	sta	$4304,y
	tya
	clc
	adc	#$10
	tay
	cpx	#\4
	bne	.HDMAinit2
	sep	#$20
	endm

CopyToVRAM	macro				;\1=Source Adress of Gfx in Rom
	ldx	#\2			;\2=Destination Adress for Gfx in V-Ram
	stx	$2116			;\3=Number of Bytes to be transfered
	ldx	#$0000
.copy	lda	!\1,x
	sta	$2118
	inx
	inx
	cpx	#\3
	bne	.copy
	endm

Wait4Blank	macro
.loop1	lda	$4212			;Make sure u r in V-Blank
	and	#$80
	beq	.loop1
.loop2	lda	$4212
	and	#$80
	bne	.loop2
	endm


;	*************************************************************************
;	********* BANK 00 at $08000 ****** CODE SECTION + Used Tables ***********
;	*************************************************************************

Start	sei
	clc
	xce			;Processor in 65816 Mode
	rep	#$30
	sep	#$20		;Accu 8 x&y in 16 Bit Mode
	ldx	#$01ff
	txs			;Stack from $7e01ff Downward
	ldx	#$0000
	phx
	pld			;Zero Page at $7e0000
	lda	#$81
	sta	$4212

	rep	#$20		;Reset pressed
	lda	$7f8000
	cmp	#$affe
	beq	start2


	sep	#$20		;Init for WOLFCHILD Tunes
	phb
	rep	#$30
	jsl	$098000
	plb
	rep	#$30
	lda	#$affe
	sta	$7f8000
	sep	#$20
	ldx	#$0000
	bra	start1

start2	sep	#$30		;Init for TURRICAN Tunes
	jsl	$0c8000
	jsl	$0c8009
	rep	#$30
	lda	#$affb
	sta	$7f8000
	ldx	#$0006
	sep	#$20

start1	stx	IrqPointer
	stx	InitPointer
forever	ldx	InitPointer		;Jump to the actual Init-Routine
	jsr	(inittab,x)
	jmp	forever

initregs	lda	#$8f		;Clear V-Ram and Initialize the PPU&CPU Regs
	sta	$2100
	stz	$420c
	lda	#$80
	sta	$2115
	rep	#$30
	ldx	#$8000
	stz	$2116
.loop	stz	$2118
	dex
	bne	.loop
	sep	#$20
	lda	#$30
	sta	$2130
	lda	#$e0
	sta	$2132
	lda	#$c0
	sta	$211a
	lda	#$00
	sta	$2131
	sta	$2106
	sta	$2133
	sta	$2123
	sta	$2124
	sta	$2125
	sta	$2126
	sta	$2127
	sta	$2128
	sta	$2129
	sta	$212a
	sta	$212b
	sta	$210d
	sta	$210d
	sta	$210e
	sta	$210e
	sta	$210f
	sta	$210f
	sta	$2110
	sta	$2110
	sta	$2111
	sta	$2111
	sta	$2112
	sta	$2112
	sta	$2113
	sta	$2113
	sta	$2114
	sta	$2114
	sta	$211b
	sta	$211b
	sta	$211c
	sta	$211c
	sta	$211d
	sta	$211d
	sta	$211e
	sta	$211e
	sta	$211f
	sta	$211f
	sta	$2120
	sta	$2120
	rts

inittab	dcr.w	InitPart6
	dcr.w	InitPart5
	dcr.w	InitPart4
	dcr.w	InitPart3
	dcr.w	InitPart2
	dcr.w	InitPart1,DoNothing1
	dcr.w	InitPart0,DoNothing


;************************************* Init Section ************************


DoNothing1				;Fade out Routine for SPACEPLANE-Part
.pad	sep	#$20
	lda	$4212
	and	#$01
	bne	.pad
	lda	$4219
	and	#$10
	beq	.pad

fadeout	ldy	#$0008
fad1	Wait4Blank
	dey
	bne	fad1

	ldx	#$0000
.loop	lda	$709,x		;Store Colorfade Values at HDMA-List
	dec	a
	bpl	.plus
	inc	a
.plus	sta	$709,x
	inx
	inx
	cpx	#$1c
	bne	.loop
	sta	$705
	cmp	#$00
	beq	.leave
	bra	fadeout

.leave	ldx	InitPointer
	inx
	inx
	stx	InitPointer
DoNothing	rts


;	************************** Init for Intro Part *****************

InitPart6	sei
	rep	#$30
	sep	#$20
	jsr	initregs
	lda	#^IntroGFX			;Copy Tiles to VRAM
	pha
	plb
	rep	#$30
	CopyToVRAM IntroGFX,$0000,5000
	lda	#$104c
	sta	$2116
	lda	#$0000
	tax
	tay
.loop	sty	$2118			;Init Screen for Man's Face
	inc	a
	pha
	ldy	#$0000
	and	#$0018
	bne	.noinx
	inx
	txy
.noinx	pla
	cmp	#$140
	bne	.loop

	lda	#$11c4
	sta	$2116
	lda	#$0000
	tay

	txy

.loop1	sty	$2118			;Init Screen for first Textline
	inc	a
	pha
	ldy	#$0000
	and	#$001f
	cmp	#24
	bcs	.noinx1
	inx
	txy
.noinx1	pla
	cmp	#$40
	bne	.loop1


	lda	#$122a
	sta	$2116
	lda	#$0000
	tay

	txy

.loop2	sty	$2118			;Init Screen for second Textline
	inc	a
	pha
	ldy	#$0000
	and	#$001f
	cmp	#14
	bcs	.noinx2
	inx
	txy
.noinx2	pla
	cmp	#$40
	bne	.loop2

	lda	#$2000
	sta	$2116
	ldx	#$0040
	lda	#$6000
.loop6	sta	$2118			;Init Screen 3 (Offset Change Table)
	dex
	bne	.loop6

	sep	#$20
	lda	#^ColorIntro			;Copy Colors to CG-Ram
	pha
	plb
	CopyColor ColorIntro,$00,$20

	Musiky	6			;Play Tune 6

	lda	#$02
	sta	$2105
	lda	#$13
	sta	$2107
	stz	$2108
	lda	#$20
	sta	$2109
	stz	$210b
	lda	#$01
	sta	$212c
	stz	$212d
	phk
	plb
	ldx	#$0000			;Scroll Screen in

.loop3	lda	$4212			;Make sure u r in V-Blank
	and	#$80
	bne	.loop3
.loop4	lda	$4212
	and	#$80
	beq	.loop4

	ldy	#$2020
	sty	$2116
	phx
	ldy	#$0000
	rep	#$20

.loop5	cpx	#$202
	bne	.ship
	ldx	#$200
.ship	lda	sinus,x
	and	#$00ff
	ora	#$6300
	sta	$2118
	inx
	inx
	iny
	cpy	#$20
	bne	.loop5

	sep	#$20
	lda	#$0f
	sta	$2100
	plx
	inx
	inx
	cpx	#$200
	bne	.loop3

	ldx	#$0100
.loopa	lda	$4212			;Make sure u r in V-Blank
	and	#$80
	bne	.loopa
.loopb	lda	$4212
	and	#$80
	beq	.loopb
	dex
	bne	.loopa


	ldy	#$0000
.loop9	ldx	#$0008
.loop7	lda	$4212			;Make sure u r in V-Blank
	and	#$80
	bne	.loop7
.loop8	lda	$4212
	and	#$80
	beq	.loop8
	dex
	bne	.loop7
	iny
	tya
	asl	a
	asl	a
	asl	a
	pha
	asl	a
	ora	#$01
	sta	$2106			;Mosaic Increase

	pla
	clc
	adc	#$80
	jsl	$098014			;Tune Volume Decrease
	sep	#$20
	rep	#$10

	tya
	eor	#$ff
	inc	a
	and	#$0f
	sta	$2100			;Color Intensity Decrease
	cpy	#$0f
	bne	.loop9

	ldx	IrqPointer
	inx
	inx
	stx	IrqPointer
	ldx	InitPointer
	inx
	inx
	stx	InitPointer
	rts



;	************************** Init for Zoom Part ******************

InitPart5	sei
	rep	#$30
	sep	#$20
	jsr	initregs

	ldx	#$03ff
	stx	$a0
	ldx	#$0003
	stx	$a2
	ldx	#$0000
	stx	$a4
	ldx	#$0000
	stx	$a6
	ldx	#$0000
	stx	$a8
	ldx	#$0000
	stx	$aa

	lda	#^Mountain		;Copy Tiles for Mountain Picture
	pha				;to VRAM and use them for Sprites
	plb				;Sprites are 64x64 Pixels and 16
	rep	#$30			;are used, 4 per line!
					;Which makes a total of 16K Sprite
	CopyToVRAM Mountain,$4000,$7c00	;Tiles (although HDMA is needed to
					;split the screen at line $80!)
	sep	#$20
	lda	#$42
	sta	$2101
	stz	$2102
	stz	$2103

	ldx	#128
	lda	#$f0
.initloop1	stz	$2104
	sta	$2104
	stz	$2104
	stz	$2104
	dex
	bne	.initloop1

	ldx	#32
.initloop2	stz	$2104
	dex
	bne	.initloop2

	stz	$2102
	stz	$2103

	stz	$2104
	stz	$2104
	stz	$2104
	lda	#$0e
	sta	$2104

	lda	#$40
	sta	$2104
	stz	$2104
	lda	#$08
	sta	$2104
	lda	#$0e
	sta	$2104

	lda	#$80
	sta	$2104
	stz	$2104
	lda	#$80
	sta	$2104
	lda	#$0e
	sta	$2104

	lda	#$c0
	sta	$2104
	stz	$2104
	lda	#$88
	sta	$2104
	lda	#$0e
	sta	$2104

	lda	#$40
	stz	$2104
	sta	$2104
	lda	#$0f
	stz	$2104
	sta	$2104

	lda	#$40
	sta	$2104
	sta	$2104
	lda	#$08
	sta	$2104
	lda	#$0f
	sta	$2104

	lda	#$80
	sta	$2104
	lda	#$40
	sta	$2104
	lda	#$80
	sta	$2104
	lda	#$0f
	sta	$2104

	lda	#$c0
	sta	$2104
	lda	#$40
	sta	$2104
	lda	#$88
	sta	$2104
	lda	#$0f
	sta	$2104


	stz	$2104
	lda	#$80
	sta	$2104
	stz	$2104
	lda	#$0e
	sta	$2104

	lda	#$40
	sta	$2104
	lda	#$80
	sta	$2104
	lda	#$08
	sta	$2104
	lda	#$0e
	sta	$2104

	lda	#$80
	sta	$2104
	sta	$2104
	sta	$2104
	lda	#$0e
	sta	$2104

	lda	#$c0
	sta	$2104
	lda	#$80
	sta	$2104
	lda	#$88
	sta	$2104
	lda	#$0e
	sta	$2104

	stz	$2104
	lda	#$c0
	sta	$2104
	stz	$2104
	lda	#$0f
	sta	$2104

	lda	#$40
	sta	$2104
	lda	#$c0
	sta	$2104
	lda	#$08
	sta	$2104
	lda	#$0f
	sta	$2104

	lda	#$80
	sta	$2104
	lda	#$c0
	sta	$2104
	lda	#$80
	sta	$2104
	lda	#$0f
	sta	$2104

	lda	#$c0
	sta	$2104
	sta	$2104
	lda	#$88
	sta	$2104
	lda	#$0f
	sta	$2104

	lda	#$01
	stz	$2102
	sta	$2103
	lda	#$aa
	sta	$2104
	sta	$2104
	sta	$2104
	sta	$2104

	CopyColor Mountaincol,$f0,$20

	lda	#^HDMAList4
	pha
	plb
	ClearDMA
	InitHDMA HDMAList4,1300,HDMALists4,24
	phk
	plb

	lda	#$80				;Prepare for Mode 7 shit
	sta	$211f
	lda	#$00
	sta	$211f
	lda	#$20
	sta	$2120
	stz	$2120
	lda	#$80
	sta	$211a
	lda	#$00
	sta	$210d
	stz	$210d
	lda	#$a8
	sta	$210e
	lda	#$ff
	sta	$210e

	rep	#$20
	lda	$a0
	sep	#$20
	sta	$211b
	xba
	sta	$211b
	xba
	stz	$211c
	stz	$211c
	stz	$211d
	stz	$211d
	sta	$211e
	xba
	sta	$211e

	lda	#$10
	sta	$212c
	stz	$212d
	lda	#$02
	sta	$2130
	lda	#$10
	sta	$2131

	stz	$2107
	stz	$210b
	lda	#$07
	sta	$2105

	Musiky	5

	lda	#$21				;V-Timer IRQ is used (as always!)
	sta	$420c

	stz	$2100
	lda	#$e8
	sta	$4209
	stz	$420a
	lda	#$21
	sta	$4200
	cli
	lda	#$00
	pha

fade	ldx	#$08				;Simple Color Fade In

fadein	Wait4Blank
	dex
	bne	fadein

	pla
	inc	a
	sta	$05f2
	pha
	cmp	#$0f
	bne	fade
	pla

.pad	sep	#$20
	lda	$4212
	and	#$01
	bne	.pad
	lda	$4219
	and	#$10
	bne	.NextPrt
	jmp	.NotNextPrt

.NextPrt	stz	$212a
	stz	$212b
	lda	#$03
	sta	$2123
	sta	$2125
	lda	#$11
	sta	$212e
	lda	#$11
	sta	$212f				;Not-So-Simple Window Fade Out
	lda	#$00
	sta	$2126
	lda	#$ff
	sta	$2127
	pha

.zoomout	lda	$4212		;Make sure u r in V-Blank
	and	#$80
	beq	.zoomout
.W84VBlank1	lda	$4212
	and	#$80
	bne	.W84VBlank1

	pla
	sta	$2127
	eor	#$ff
	inc	a
	sta	$2126
	eor	#$ff
	pha
	cmp	#$7f
	bne	.zoomout
	sei
	pla
	rep	#$30
	ldx	IrqPointer
	inx
	inx
	stx	IrqPointer
	ldx	InitPointer
	inx
	inx
	stx	InitPointer
	sep	#$20
	rts

.NotNextPrt	rep	#$30		;Change to Logo number ($a4)
	lda	$a2
	cmp	#$0002
	beq	.copyChar
	cmp	#$0001
	bne	.pad
	sep	#$20
	ldx	$a4
	lda	!LogoTable,x
	sta	$10
	lda	!LogoTable+1,x
	sta	$11
	lda	!LogoTable+2,x
	sta	$12
	stz	$212d
	lda	#$10
	sta	$212c
	jsr	ConvLog2M7
	stz	$a2
	stz	$a3
	lda	#$27
	sta	$420c
	jmp	.pad

.copyChar	sep	#$20		;Change to Charset or Boris Becker
	stz	$212d
	lda	#$10
	sta	$212c
	stz	$2130
	rep	#$20
	lda	$d0
	cmp	#StarWars1
	beq	.NoScroller

	sep	#$20
	jsr	CopyChar2M7
.Return	lda	#$01
	sta	$212d
	lda	#$10
	sta	$212c
	lda	#$02
	sta	$2130
	stz	$a2
	lda	#$03
	sta	$a3
	jmp	.pad

.NoScroller	rep	#$20		;Change to Starwars Scroller
	sta	$10
	sep	#$20
	stz	$12

	ldx	#$0000
	txy
	sty	$2116
	lda	#^Mode7Colors
	pha
	plb
.loopx	lda	$4212		;Make sure u r in V-Blank
	and	#$80
	bne	.inVBlank
.W84VBlank	lda	$4212
	and	#$80
	bne	.loopx
	bra	.W84VBlank
.inVBlank	lda	#$41
	sta	$d0
	lda	#$41-40
	sta	$d1
	txa
	cmp	#$7f
	bne	.SkipIT

	rep	#$20
	tya
	sec
	sbc	#$0020
	tay
	sep	#$20
	txa

.SkipIT	and	#$80
	beq	.skipIt
	lda	#$41-39
	sta	$d0
	lda	#$41-51
	sta	$d1
.skipIt	lda	#$8f
	sta	$2100
	lda	[$10],y

	cmp	#"g"
	bcc	.NotBoris
	sec
	sbc	$d1
	bra	.Boris
.NotBoris	sec
	sbc	$d0
.Boris	sta	$2118

	lda	!Mode7Char,x
	sta	$2119
	lda	#$0f
	sta	$2100
	inx
	txa
	and	#$7f
	sec
	sbc	#$20
	bpl	.NoINY
	iny
.NoINY	cpx	#$4000
	bne	.loopx
	lda	#$20
	sta	$2120
	stz	$2120
	lda	#$80
	sta	$211a
	lda	#$a8
	sta	$210e
	lda	#$ff
	sta	$210e
	ldx	#$ff40
	stx	$a6
	lda	#$27
	sta	$420c
	phk
	plb
	jmp	.Return

CopyChar2M7	ldx	#$0000		;Copy Chars and Boris to VRAM ($0000) in Mode7
	stx	$2116		;Format .. the screen is filled with Blanks ($4f)
	sep	#$20
	ldy	#$004f
	lda	#^Mode7Colors
	pha
	plb
.loopx	lda	$4212		;Make sure u r in V-Blank
	and	#$80
	bne	.inVBlank
.W84VBlank	lda	$4212
	and	#$80
	bne	.loopx
	bra	.W84VBlank
.inVBlank	lda	#$8f
	sta	$2100
	tya
	sta	$2118
	lda	!Mode7Char,x
	sta	$2119
	lda	#$0f
	sta	$2100
	inx
	cpx	#$4000
	bne	.loopx
	lda	#$80
	sta	$211f
	lda	#$01
	sta	$211f
	lda	#$20
	sta	$2120
	stz	$2120
	lda	#$80
	sta	$211a
	lda	#$00
	sta	$210d
	stz	$210d
	lda	#$dc
	sta	$210e
	lda	#$ff
	sta	$210e
	lda	#$39
	sta	$420c
	phk
	plb
	rts

ConvLog2M7	sep	#$20
	rep	#$10
	lda	#$7e		;Routine to Convert a 256x64x4 Logo from normal
	pha			;Charset to Mode7 Format, while the IRQ is doing
	plb			;something.
	lda	#$00		;Put Adress into $00,$01,$02 and the Routine will
	ldx	#$0000		;convert the logo to $7e0800 and copy it to VRAM
.clear	sta	$800,x		;Location $0000.
	inx			;Done by The Pothead/Magical in 1993.
	cpx	#$4000		;Requires AKKU[8] and INDEX[16]
	bne	.clear

	ldy	#$0020
	ldx	#$0040
	lda	$12		;Bank of the Source Logo
	sta	$15
	sta	$18
	sta	$1b
	lda	$11		;High of the Source Logo
	sta	$14
	sta	$17
	sta	$1a
	lda	$10		;Low of the Source Logo
	inc	a
	sta	$13
	clc
	adc	#$0f
	sta	$16
	inc	a
	sta	$19

.loopinit	lda	[$19],y		;Convert from 4 Bpl to MODE 7 format Loop
	ror	a
	rol	$800,x
	ror	a
	rol	$800+1,x
	ror	a
	rol	$800+2,x
	ror	a
	rol	$800+3,x
	ror	a
	rol	$800+4,x
	ror	a
	rol	$800+5,x
	ror	a
	rol	$800+6,x
	ror	a
	rol	$800+7,x
	lda	[$16],y
	ror	a
	rol	$800,x
	ror	a
	rol	$800+1,x
	ror	a
	rol	$800+2,x
	ror	a
	rol	$800+3,x
	ror	a
	rol	$800+4,x
	ror	a
	rol	$800+5,x
	ror	a
	rol	$800+6,x
	ror	a
	rol	$800+7,x

	lda	[$13],y
	ror	a
	rol	$800,x
	ror	a
	rol	$800+1,x
	ror	a
	rol	$800+2,x
	ror	a
	rol	$800+3,x
	ror	a
	rol	$800+4,x
	ror	a
	rol	$800+5,x
	ror	a
	rol	$800+6,x
	ror	a
	rol	$800+7,x

	lda	[$10],y
	ror	a
	rol	$800,x
	ror	a
	rol	$800+1,x
	ror	a
	rol	$800+2,x
	ror	a
	rol	$800+3,x
	ror	a
	rol	$800+4,x
	ror	a
	rol	$800+5,x
	ror	a
	rol	$800+6,x
	ror	a
	rol	$800+7,x
	.repeat 8 {
	inx
	}
	iny
	iny
	tya
	and	#$0f
	bne	.init2
	rep	#$20
	tya
	clc
	adc	#$0010
	tay
	sep	#$20
	cpx	#64*256
	beq	.init0
.init2	jmp	.loopinit


.init0	ldx	#$0000		;And copy the shit to VRAM $0000
	phk
	plb
	lda	#$0f
	sta	$2100
	ldx	#$0000
	stx	$2116
	stx	$a0
.init1	lda	$4212		;And make sure u r in V-Blank
	and	#$80
	beq	.pause
	lda	#$8f
	sta	$2100
	cpx	#$400
	bcc	.skip1
	lda	#$00
	bra	.skip2
.skip1	txa
	and	#$7f
	cmp	#$20
	bcc	.skip3
	lda	#$00
	bra	.skip2
.skip3	txa
	eor	#$ff
	and	#$1f
	adc	$a0
.skip2	sta	$2118
	lda	$7e0800,x
	sta	$2119
	lda	#$0f
	sta	$2100
	inx
	txa
	and	#$7f
	bne	.shipit
	lda	$a0
	clc
	adc	#$20
	sta	$a0
.shipit	cpx	#$4000
	bne	.init1
	bra	.init3
.pause	lda	$4212
	and	#$80
	beq	.pause
	bra	.init1

.init3	rts		;End of Converting AKKU[8] INDEX[16]

LogoTable	dcr.t	Abandonlog
	dcr.w	0
	dcr.t	Anthroxlog
	dcr.w	32
	dcr.t	Baselinelog
	dcr.w	64
	dcr.t	Premierelog
	dcr.w	96

;	************** Init for Wizard Pic *****************

InitPart4	sei
	rep	#$30
	sep	#$20

	jsr	initregs

	lda	#^Wizardb8			;Copy Picture of the Wizard to VRAM
	pha				;Picture uses 6 Planes and is converted
	plb				;to 8-Plane tiles in this part:

	ldx	#$2000
	stx	$2116
	rep	#$30
	ldx	#$0000
.init1	ldy	#$0000
.init2	lda	!Wizardb8,x
	sta	$2118
	inx
	inx
	iny
	cpy	#$18
	bne	.init2
	ldy	#$0000
.init3	stz	$2118
	iny
	cpy	#$08
	bne	.init3
	cpx	#$7fe0
	bne	.init1

.init4	lda	!Wizardb8,x
	sta	$2118
	inx
	inx
	cpx	#$8000
	bne	.init4

	sep	#$20
	lda	#^Wizardb6
	pha
	plb
	rep	#$20
	ldx	#$0000

.init5	lda	!Wizardb6,x
	sta	$2118
	inx
	inx
	cpx	#$10
	bne	.init5
	.repeat 8 {
	stz	$2118
	}

.init6	ldy	#$0000
.init7	lda	!Wizardb6,x
	sta	$2118
	inx
	inx
	iny
	cpy	#$18
	bne	.init7
	ldy	#$0000
.init8	stz	$2118
	iny
	cpy	#$08
	bne	.init8
	cpx	#$22c0
	bne	.init6


	ldx	#$1c00			;Initialize Screen for Wizard
	stx	$2116
	lda	#$0000
	tax
.init9	sta	$2118
	inc	a
	inx
	cpx	#$1f
	bne	.init9
	pha
	lda	#502
	sta	$2118
	pla
	ldx	#$0000
	cmp	#868
	bne	.init9
	lda	#502
.init10	sta	$2118
	inx
	cpx	#$80
	bne	.init10
	sep	#$20

	lda	#^Char03			;Copy Chars for OAM Scroller to VRAM
	pha
	plb

	rep	#$30
	CopyToVRAM Char03,$1000,$d80+704
	sep	#$20

	lda	#^WizardColor
	pha
	plb

	CopyColor WizardColor,$00,$40	;and copy Colors to CG-RAM
	lda	#^Char03Cols
	pha
	plb
	CopyColor Char03Cols+$00,$80,$8
	CopyColor Char03Cols+$00,$88,$8
	CopyColor Char03Cols+$10,$90,$8
	CopyColor Char03Cols+$20,$a0,$8
	CopyColor Char03Cols+$30,$b0,$8
	CopyColor Char03Cols+$40,$c0,$8
	CopyColor Char03Cols+$50,$d0,$8
	CopyColor Char03Cols+$60,$e0,$8
	CopyColor Char03Cols+$70,$f0,$8

	sep	#$20			;Initialize OAM Data
	phk
	plb

	lda	#$00
	sta	$2101
	ldx	#$0000
	stx	$2102
	ldx	#$0080
	lda	#$01
	xba
	lda	#53
.init11	stz	$2104
	stz	$2104
	sta	$2104
	xba
	sta	$2104
	xba
	dex
	bne	.init11

	ldx	#32
	lda	#$00
.init12	sta	$2104
	dex
	bne	.init12

	ldx	#$0080
	stx	$2102

	sep	#$30
	lda	#$00
	xba
	lda	#$40
	ldx	#$0b
	ldy	#$6c
.init14	sta	$2104
	xba
	lda	#$d2
	sta	$2104
	sty	$2104
	lda	#$31
	sta	$2104
	iny
	xba
	clc
	adc	#$08
	dex
	bne	.init14

	rep	#$10

	lda	#$1c			;Initialize the rest of the Registers
	sta	$2107
	lda	#$02
	sta	$210b
	lda	#$04
	sta	$2105
	lda	#$01
	sta	$212c
	lda	#$10
	sta	$212d

	lda	#$18
	sta	$2109
	ldx	#$1800
	stx	$2116
	ldx	#$a000
	stx	$2118
	ldy	#$a000
.init15	sty	$2118
	inx
	cpx	#$a021
	bne	.init15

	lda	#$fc
	sta	$210d
	lda	#$03
	sta	$210d

	lda	#$02
	sta	$2130
	lda	#$01
	sta	$2131
	Musiky	1
	lda	#$ff
	sta	$9e
	stz	$9f
	stz	$9c
	stz	$9d
	lda	#$01
	sta	$a4
	stz	$a5
	stz	$a6
	stz	$a7
	ldx	#text10
	stx	$a8
	ldx	#$0000
	stx	$ae
	stx	$b0
	lda	#$e8
	sta	$4209
	stz	$420a
	lda	#$21
	sta	$4200
	cli

	lda	#$80		;Window1 Fade the Screen in
	sta	$2126
	sta	$2127
	pha
	lda	#$03
	sta	$2123
	sta	$2125
	stz	$212a
	stz	$212b
	lda	#$11
	sta	$212e
	sta	$212f

	lda	#$0f
	sta	$2100

.zoomout	lda	$4212		;Make sure u r in V-Blank
	and	#$80
	beq	.zoomout
.W84VBlank1	lda	$4212
	and	#$80
	bne	.W84VBlank1

	pla
	sta	$2126
	eor	#$ff
	inc	a
	sta	$2127
	eor	#$ff
	pha
	cmp	#$01
	bne	.zoomout
	stz	$212e
	stz	$212f
	pla

.pad	lda	$4212		;Check the Pad for Musik Changes
	and	#$01
	bne	.pad
	rep	#$30
	lda	$4218
	tax

	and	#$4000		;One Tune up
	beq	.skip1
	lda	#$0000
	sep	#$20
	lda	$a4
	inc	a
	cmp	#10
	bne	.skip
	lda	#$00
.skip	sta	$a4
	rep	#$30
	phb
	jsl	$098004
	lda	#$c0
	jsl	$098008
	plb


.skip1	txa			;One Tune down
	and	#$8000
	beq	.skip2
	lda	#$0000
	sep	#$20
	lda	$a4
	dec	a
	cmp	#$ff
	bne	.skip3
	lda	#$09
.skip3	sta	$a4
	rep	#$30
	phb
	jsl	$098004
	lda	#$c0
	jsl	$098008
	plb

.skip2	txa			;Normal Speed
	and	#$0030
	cmp	#$0030
	beq	.normal
	and	#$0030
	bne	.skip6
.normal	lda	$a5
	beq	.skip5
	stz	$a5
	lda	#$80
	jsl	$098018
	bra	.skip5

.skip6	txa			;Major Slowdown
	and	#$0010
	beq	.skip4
	lda	$a5
	cmp	#$01
	beq	.skip4
	lda	#$40
	jsl	$098018
	lda	#$01
	sta	$a5

.skip4	txa			;Fast Forward
	and	#$0020
	beq	.skip5
	lda	$a5
	cmp	#$02
	beq	.skip5
	lda	#$ff
	jsl	$098018
	lda	#$02
	sta	$a5

.skip5	rep	#$30
	sep	#$20
	jmp	.pad

;	************* Init for Greetings Part **********

InitPart3	sei
	jsr	initregs

	lda	#^BigLogo		;Copy Magical-Logo Tiles to VRAM
	pha
	plb
	rep	#$30

	CopyToVRAM BigLogo,0,$1f00

	lda	#$182c
	ldy	#$0000		;Init Screen for Magical Logo
.init1	sta	$2116
	pha
	ldx	#$0000
.init2	lda	!BigLogoScr,y
	sta	$2118
	inx
	iny
	iny
	cpx	#20
	bne	.init2
	tya
	clc
	adc	#40
	tay
	pla
	clc
	adc	#$20
	cmp	#$192c
	bne	.init1

	lda	#$1c20
	ldy	#40
.init3	sta	$2116
	pha
	ldx	#$0000
.init4	lda	!BigLogoScr,y
	sta	$2118
	inx
	iny
	iny
	cpx	#20
	bne	.init4
	tya
	clc
	adc	#40
	tay
	pla
	clc
	adc	#$20
	cmp	#$1d20
	bne	.init3

	ldx	#$2c20
	stx	$2116
	ldy	#$0001

.init5	tya
	clc
	adc	#$1000
	ldx	#$0000

.init6	sta	$2118
	clc
	adc	#$08
	inx
	cpx	#$20
	bne	.init6
	iny
	cpy	#$0009
	bne	.init5

	lda	#$3020
	ldx	#$1101
.init7	sta	$2116
	stx	$2118
	clc
	adc	#$20
	inx
	cpx	#$1109
	bne	.init7

	phk
	plb

	CopyToVRAM char,$2900,$1b0

	sep	#$20
	lda	#^Char02
	pha
	plb
	rep	#$30

	CopyToVRAM Char02,$1000,$a70

	sep	#$20
	lda	#^Abandonlog
	pha
	plb
	rep	#$20

	CopyToVRAM Abandonlog,$4000,$7ffe

	lda	#$fefe
	sta	$2118
	ldx	#$3e60
	stx	$2116
	lda	#$1000
	ldx	#$0000
.init8	sta	$2118
	clc
	adc	#$1
	inx
	cpx	#$100
	bne	.init8

	sep	#$20

	lda	#^colorBigLog
	pha
	plb

	CopyColor colorBigLog,0,$14
	CopyColor ColorPart1a,$20,$10
	CopyColor ColorPart1a,$80,$10
	CopyColor ABNColors,$40,$40

	lda	#^HDMAList3
	pha
	plb
	ClearDMA
	InitHDMA HDMAList3,560,HDMALists3,20

	phk
	plb

	ldy	#$0000
	ldx	#$2d88
.init9	stx	$2116
.init10	lda	text05,y
	rep	#$20
	and	#$1f
	clc
	adc	#$1120
	sta	$2118
	sep	#$20
	iny
	tya
	and	#$0f
	bne	.init10
	rep	#$20
	txa
	clc
	adc	#$20
	tax
	cpy	#$50
	bne	.init9


	ldx	#$1926
	stx	$2116
	ldy	#$0000
	rep	#$20
.init11	lda	text04,y
	and	#$7f
	clc
	asl	a
	tax
	lda	asciitab2,x
	clc
	adc	#$500
	sta	$2118
	iny
	cpy	#20
	bne	.init11
	ldx	#$1946
	stx	$2116
	ldy	#$0000
.init12	lda	text04,y
	and	#$7f
	clc
	asl	a
	tax
	lda	asciitab2,x
	clc
	adc	#$52a
	sta	$2118
	iny
	cpy	#20
	bne	.init12

	ldx	#$0000
.init13	lda	text06,x
	sta	$1000,x
	inx
	inx
	cpx	#$400
	bne	.init13

	Musik	0,0

	sep	#$20
	lda	#$3c
	sta	$2107

	lda	#$19
	sta	$2108

	lda	#$2d
	sta	$2109
	lda	#$01
	sta	$2105
	lda	#$13
	sta	$212c
	lda	#$04
	sta	$212d
	lda	#$02
	sta	$210c
	lda	#$04
	sta	$210b
	lda	#$02
	sta	$2130
	lda	#$02
	sta	$2131

	lda	#$17
	sta	$420c
	lda	#$d8
	sta	$4209
	stz	$420a
	lda	#$21
	sta	$4200
	ldx	#$0000
	stx	$4e
	stx	$52
	stx	$54
	stx	$56
	stx	$58
	stx	$5a
	stx	$5c
	stx	$5e
	stx	$60
	lda	#$fe
	sta	$c0
	ldx	#$fff0
	stx	$c1
	stx	$c3
	ldx	#$1000
	stx	$50
	jsr	CalcChars
	sep	#$20
	rep	#$10

	lda	#$33
	sta	$2123
	sta	$2124
	lda	#$03
	sta	$2125
	stz	$212a
	stz	$212b
	lda	#$13
	sta	$212e
	lda	#$04
	sta	$212f
	stz	$2127
	stz	$2126
	stz	$d0

	sep	#$20

	stz	$2101
	ldx	#$0000
	stx	$2102
	ldx	#$0084
.init14	stz	$2104
	stz	$2104
	stz	$2104
	stz	$2104
	dex
	bne	.init14

	lda	#$0f
	sta	$2100

	ldx	#$0000
	stx	$d2

.zoomin1	sep	#$20


	lda	$4212		;Make sure u r in V-Blank
	and	#$80
	beq	.zoomin1
.W84VBlank1	lda	$4212
	and	#$80
	bne	.W84VBlank1

	ldx	$d2
	stx	$d0
	ldx	#$0000
.loopo	rep	#$30
	dec	$d0
	lda	$d0
	cmp	#$ffff
	bne	.inc
	inc	$d0
	lda	#$0000
.inc	cmp	#$00ff
	bcc	.dec
	lda	#$00ff
.dec	sep	#$20
	sta	$21f,x
	inx
	inx
	cpx	#440
	bne	.loopo
	rep	#$30
	inc	$d2
	lda	$d2
	cmp	#$1ff
	bne	.zoomin1
	sep	#$20
	lda	#$13
	sta	$420c
	cli
.pad	lda	$4212
	and	#$01
	bne	.pad
	lda	$4219
	and	#$30
	beq	.pad
	cmp	#$30
	beq	.hidden
	cmp	#$20
	beq	.pad
	sei
	lda	#$0b
	sta	$420c

.zoomin2	sep	#$20
	lda	$4212
	and	#$80
	beq	.zoomin2
.W84VBlank3	lda	$4212
	and	#$80
	bne	.W84VBlank3
	inc	$3d8
	lda	$3d8

	sta	$2126
	eor	#$ff
	inc	a
	sta	$2127

	lda	$3da
	dec	a
	sta	$3da
	sta	$3dc
	cmp	#$01
	bne	.zoomin2



	ldx	InitPointer
	inx
	inx
	inx
	inx
	stx	InitPointer
	ldx	IrqPointer
	inx
	inx
	stx	IrqPointer
	rts

.hidden	sei
	stz	$d0

.zoomin	lda	$4212		;Make sure u r in V-Blank
	and	#$80
	beq	.zoomin
.W84VBlank4	lda	$4212
	and	#$80
	bne	.W84VBlank4

	inc	$d0
	lda	$d0
	beq	.padi
	sta	$2126
	bra	.zoomin
.padi	stz	$212e
	stz	$212f

	ldx	InitPointer
	inx
	inx
	stx	InitPointer
	rts

;	************* Init for Train Pic Part **********

InitPart2	sei
	jsr	initregs

	lda	#^ZugPart1
	pha
	plb
	ldx	#$2000
	stx	$2116
	rep	#$30
	ldx	#$0000
.init1	ldy	#$0000
.init4	lda	!ZugPart1,x
	sta	$2118
	inx
	inx
	iny
	cpy	#$10
	bne	.init4
	ldy	#$0000
.init2	lda	!ZugPart1,x
	inx
	and	#$ff
	sta	$2118
	iny
	cpy	#$08
	bne	.init2
	ldy	#$0000
.init3	stz	$2118
	iny
	cpy	#$08
	bne	.init3
	cpx	#$7ff8
	bne	.init1
.init5	lda	!ZugPart1,x
	sta	$2118
	inx
	inx
	cpx	#$8000
	bne	.init5
	sep	#$20
	lda	#^ZugPart2
	pha
	plb
	rep	#$20
	ldx	#$0000
.init6	lda	!ZugPart2,x
	sta	$2118
	inx
	inx
	cpx	#$18
	bne	.init6
.init7	lda	!ZugPart2,x
	inx
	and	#$ff
	sta	$2118
	cpx	#$20
	bne	.init7
	ldy	#$0000
.init8	stz	$2118
	iny
	cpy	#$08
	bne	.init8

.init9	ldy	#$0000
.init12	lda	!ZugPart2,x
	sta	$2118
	inx
	inx
	iny
	cpy	#$10
	bne	.init12
	ldy	#$0000
.init10	lda	!ZugPart2,x
	inx
	and	#$ff
	sta	$2118
	iny
	cpy	#$08
	bne	.init10
	ldy	#$0000
.init11	stz	$2118
	iny
	cpy	#$08
	bne	.init11
	cpx	#$c00
	bne	.init9
	ldy	#$0000
.init13	stz	$2118
	iny
	cpy	#$400
	bne	.init13

	ldx	#$1c00
	stx	$2116
	lda	#$0000
	tax
.init14	sta	$2118
	inc	a
	inx
	cpx	#896
	bne	.init14

	sep	#$20
	lda	#^ColorZug
	pha
	plb

	CopyColor ColorZug,0,$20

	sep	#$20

	lda	#^Char03
	pha
	plb

	rep	#$30
	CopyToVRAM Char03,$1000,$d80+704
	sep	#$20

	lda	#^Char03Cols
	pha
	plb
	CopyColor Char03Cols+$00,$80,$8
	CopyColor Char03Cols+$00,$88,$8
	CopyColor Char03Cols+$10,$90,$8
	CopyColor Char03Cols+$20,$a0,$8
	CopyColor Char03Cols+$30,$b0,$8
	CopyColor Char03Cols+$40,$c0,$8
	CopyColor Char03Cols+$50,$d0,$8
	CopyColor Char03Cols+$60,$e0,$8
	CopyColor Char03Cols+$70,$f0,$8


	lda	#$00
	sta	$2101
	ldx	#$0000
	stx	$2102
	ldx	#$0080
	lda	#$01
	xba
	lda	#53
.init11	stz	$2104
	stz	$2104
	sta	$2104
	xba
	sta	$2104
	xba
	dex
	bne	.init11

	ldx	#32	;24
	lda	#$00
.init12	sta	$2104
	dex
	bne	.init12

	ldx	#$0080
	stx	$2102

	sep	#$30
	lda	#$00
	xba
	lda	#$40
	ldx	#$0b
	ldy	#$6c
.init14	sta	$2104
	xba
	lda	#$d2
	sta	$2104
	sty	$2104
	lda	#$31
	sta	$2104
	iny
	xba
	clc
	adc	#$08
	dex
	bne	.init14

	stz	$420c
	phk
	plb

	lda	#$a0
	sta	$2104
	lda	#$d2
	sta	$2104
	lda	#$77
	sta	$2104
	lda	#$31
	sta	$2104

	rep	#$10

	lda	#^HDMALists5
	pha
	plb

	ClearDMA
	InitHDMA HDMAList5,10,HDMALists5,4

	phk
	plb

	lda	#$1c
	sta	$2107
	lda	#$02
	sta	$210b
	lda	#$03
	sta	$2105

	lda	#$01
	sta	$212c
	lda	#$10
	sta	$212d

	lda	#$02
	sta	$2130
	lda	#$01
	sta	$2131

	lda	#$ff
	sta	$9e
	stz	$9f
	stz	$9c
	stz	$9d
	stz	$a4
	stz	$a5
	stz	$a6
	stz	$a7
	ldx	#text11
	stx	$a8
	ldx	#$0000
	stx	$aa
	lda	#$e8
	sta	$4209
	stz	$420a
	lda	#$21
	sta	$4200

	lda	#$33
	sta	$2123
	sta	$2124
	lda	#$03
	sta	$2125
	stz	$212a
	stz	$212b
	lda	#$03
	sta	$212e
	lda	#$10
	sta	$212f
	lda	#$ff
	sta	$2127
	sta	$2126
	sta	$d0

	lda	#$0f
	sta	$2100

	ldx	IrqPointer
	inx
	inx
	stx	IrqPointer
	cli

.zoomin	lda	$4212		;Make sure u r in V-Blank
	and	#$80
	beq	.zoomin
.W84VBlank1	lda	$4212
	and	#$80
	bne	.W84VBlank1

	dec	$d0
	lda	$d0
	beq	.padi
	sta	$2126
	bra	.zoomin
.padi	stz	$212e
	stz	$212f


pad1	lda	$4212
	and	#$01
	bne	pad1
	rep	#$30
	lda	$4218
	tax
	and	#$d000
	bne	.skip0
	sep	#$20
	bra	pad1
	rep	#$20
.skip0	txa
	and	#$4000
	beq	.skip1

	lda	$aa
	clc
	adc	#$04
	cmp	#30*4
	bne	.skipit
	lda	#$0000
.skipit	sta	$aa
	bra	.ChTune

.skip1	txa
	and	#$8000
	beq	.skip3

	lda	$aa
	sec
	sbc	#$04
	cmp	#$fffc
	bne	.skipit1
	lda	#29*4
.skipit1	sta	$aa

.ChTune	sep	#$20
	ldx	$aa
	lda	!TurriTunes+2,x
	sta	$a7
	lda	!TurriTunes+3,x
	sta	$a4
	lda	!TurriTunes+1,x
	pha
	lda	!TurriTunes,x
	pha
	sep	#$30
	jsl	$c8009
	pla
	jsl	$c8003
	ply
	jsl	$c8006
	lda	#$7f
	ldy	#$70
	jsl	$c8012
	rep	#$30
	sep	#$20
	jmp	pad1
	rep	#$20

.skip3	txa
	and	#$1000
	beq	.skip2
	sep	#$20
	lda	#$01
	sta	$420c
	lda	#$33
	sta	$2123
	sta	$2124
	lda	#$03
	sta	$2125
	stz	$212a
	stz	$212b
	lda	#$03
	sta	$212e
	lda	#$10
	sta	$212f
	lda	#$ff
	sta	$2127
	stz	$2126

.zoomin2	sep	#$20
	lda	$4212
	and	#$80
	beq	.zoomin2
.W84VBlank3	lda	$4212
	and	#$80
	bne	.W84VBlank3
	inc	$200
	lda	$200

	sta	$2126
	eor	#$ff
	inc	a
	sta	$2127

	lda	$202
	dec	a
	sta	$202
	sta	$204
	cmp	#$01
	bne	.zoomin2

	ldx	InitPointer
	inx
	inx
	stx	InitPointer
	rts

.skip2	sep	#$20
	jmp	pad1

TurriTunes	dc.b	0,0,0,0
	dc.b	0,1,0,1
	dc.b	0,2,0,2
	dc.b	0,3,0,3
	dc.b	0,4,0,4
	dc.b	0,5,0,5
	dc.b	0,6,0,6
	dc.b	1,0,0,7
	dc.b	1,1,0,8
	dc.b	1,2,0,9
	dc.b	1,3,1,0
	dc.b	1,4,1,1
	dc.b	1,5,1,2
	dc.b	1,6,1,3
	dc.b	2,0,1,4
	dc.b	2,1,1,5
	dc.b	2,2,1,6
	dc.b	2,3,1,7
	dc.b	2,4,1,8
	dc.b	2,5,1,9
	dc.b	2,6,2,0
	dc.b	3,0,2,1
	dc.b	3,1,2,2
	dc.b	3,2,2,3
	dc.b	3,3,2,4
	dc.b	3,4,2,5
	dc.b	3,5,2,6
	dc.b	4,0,2,7
	dc.b	4,1,2,8
	dc.b	5,0,2,9


;	************* Init for Credits Part **********

InitPart0	sei
	sep	#$20
	jsr	initregs
	lda	#^LinksBorder
	pha
	plb

	rep	#$20

	CopyToVRAM LinksBorder,0,6656

	sep	#$20
	lda	#^MainBorder
	pha
	plb
	rep	#$20

	CopyToVRAM MainBorder,6656/2,$a00
	CopyToVRAM Char02,$2000,$a70

	lda	#$1800
	sta	$2116
	ldx	#$0000
	ldy	#41
.init1	sty	$2118
	inx
	cpx	#$400
	bne	.init1

	lda	#$1400
	sta	$2116
	ldy	#$0000
	ldx	#$0000

.init2	sty	$2118
	iny
	inx
	cpx	#$08
	bne	.init2
	ldx	#$0000
	clc
	adc	#$20
	sta	$2116
	cpy	#208
	bne	.init2


	ldy	#$4007
	lda	#$1417
	sta	$2116
	ldx	#$0000

.init3	sty	$2118
	dey
	inx
	cpx	#$08
	bne	.init3
	pha
	tya
	adc	#$0f
	tay
	pla
	ldx	#$0000
	clc
	adc	#$20
	sta	$2116
	cmp	#$1757
	bne	.init3

	lda	#$1408
	sta	$2116
	ldy	#$0000
	ldx	#208
.init4	stx	$2118
	iny
	inx
	cpy	#$0f
	bne	.init4
	inx
	ldy	#$0000
	clc
	adc	#$20
	sta	$2116
	cmp	#$14a8
	bne	.init4
	sep	#$20

	lda	#^colorpart1
	pha
	plb

	CopyColor colorpart1,0,$20
	rep	#$20
	CopyToVRAM coloraddtil,$3000,$40

	lda	#$1ca8
	ldy	#$8803
	ldx	#$0010
.init5	sta	$2116
.init6	sty	$2118
	dex
	bne	.init6
	ldx	#$0010
	clc
	adc	#$20
	dey
	cpy	#$8800
	bne	.init5

	lda	#$1f48
	ldy	#$0801
	ldx	#$0010
.init7	sta	$2116
.init8	sty	$2118
	dex
	bne	.init8
	ldx	#$0010
	clc
	adc	#$20
	iny
	cpy	#$0804
	bne	.init7

	sep	#$20
	phk
	plb

	lda	#$14
	sta	$2107
	lda	#$18
	sta	$2108
	lda	#$1c
	sta	$2109
	lda	#$00
	sta	$210a

	lda	#$20
	sta	$210b
	lda	#$03
	sta	$210c

	lda	#$01
	sta	$2105
	lda	#$03
	sta	$212c
	lda	#$04
	sta	$212d

	ClearDMA

	stz	$420c
	lda	#^HDMAList2
	pha
	plb

	InitHDMA HDMAList2,20,HDMALists2,8

	phk
	plb

	Musik	4,2

	sep	#$20
	lda	#$03
	sta	$420c
	ldx	#$0000
	stx	$5c
	stx	$5e
	stx	$60
	stx	$62
	stx	$64

	ldx	IrqPointer
	inx
	inx
	stx	IrqPointer
	ldx	InitPointer
	inx
	inx
	stx	InitPointer

	lda	#$e8
	sta	$4209
	stz	$420a
	lda	#$21
	sta	$4200
	lda	#$04
	sta	$2112
	stz	$2112
	lda	#$02
	sta	$2130
	lda	#$82
	sta	$2131

	stz	$212a
	stz	$212b
	lda	#$33
	sta	$2123
	sta	$2124
	stz	$2125
	lda	#$0f
	sta	$212e
	lda	#$0f
	sta	$212f
	stz	$2126

	ldx	#$0000

	cli

putin	Wait4Blank

	lda	sinus,x
	sta	$2127
	eor	#$ff
	inc	a
	sta	$210f
	stz	$210f
	sta	$2111
	stz	$2111
	sec
	sbc	#$04
	sta	$210d
	stz	$210d
	lda	#$0f
	sta	$2100
	inx
	inx
	cpx	#$200
	bne	putin
	rts

;	************* Init for Spaceplane Part **********

InitPart1	sei
	jsr	initregs
	lda	#$5c
	sta	$2107
	stz	$2108
	lda	#$75
	sta	$2109
	stz	$210a
	lda	#$04
	sta	$210b
	lda	#$06
	sta	$210c
	lda	#$07
	sta	$2105
	lda	#$05
	sta	$212c

	lda	#^LogoTile
	pha
	plb
	rep	#$30

	CopyToVRAM LogoTile,$4000,5872
	sep	#$20
	lda	#^LogoScreen
	pha
	plb
	rep	#$20
	CopyToVRAM LogoScreen,$5c00,576

	sep	#$20
	lda	#^char01
	pha
	plb
	rep	#$30

	CopyToVRAM char01,$6000,$2800


	ldx	#$7400
	stx	$2116
	ldx	#$0000

	ldy	#380
.init1	sty	$2118
	inx
	cpx	#$800
	bne	.init1

	sep	#$20

	ldx	#$0000
	stx	$2116
	ldy	#$0000

	lda	#^SpaceMap
	pha
	plb

.init2	lda	!SpaceMap,y
	clc
	asl	a
	asl	a
	pha
	bne	.init3
	inc	a
.init3	sta	$2118
	lda	!Spacetiles,x
	clc
	adc	#20
	sta	$2119
	inx
	pla
	inc	a
	inc	a
	sta	$2118
	lda	!Spacetiles,x
	clc
	adc	#20
	sta	$2119
	inx
	iny
	tya
	and	#$3f
	bne	.init2

	rep	#$20
	tya
	sec
	sbc	#$40
	tay
	sep	#$20

.init4	lda	!SpaceMap,y
	clc
	asl	a
	asl	a
	inc	a
	pha
	sta	$2118
	lda	!Spacetiles,x
	clc
	adc	#20
	sta	$2119
	inx
	pla
	inc	a
	inc	a
	sta	$2118
	lda	!Spacetiles,x
	clc
	adc	#20
	sta	$2119
	inx
	iny
	tya
	and	#$3f
	bne	.init4

	cpy	#$1000
	bne	.init2

	Musik	2,6
	sep	#$20

	lda	#^colorlogo
	pha
	plb

	CopyColor colorlogo,0,20

	lda	#^SpaceColor
	pha
	plb

	CopyColor SpaceColor,20,$10

	lda	#^HDMAList
	pha
	plb

	ClearDMA
	InitHDMA HDMAList,1324+20,HDMALists,32

	lda	#$e8
	sta	$4209
	stz	$420a
	ldx	#$0000
	stx	$5e
	stx	$60
	stx	$62
	stx	$0100
	stx	$0102
	inx
	stx	$5a
	lda	#$00
	sta	$212d
	lda	#$04
	sta	$2112
	lda	#$00
	sta	$2112

	lda	#$28
	sta	$4372

	lda	#$ff
	sta	$420c
	lda	#$21
	sta	$4200
	lda	#$0f
	sta	$2100
	ldx	IrqPointer
	inx
	inx
	stx	IrqPointer
	ldx	InitPointer
	inx
	inx
	stx	InitPointer
	cli


	lda	#$33
	sta	$2123
	sta	$2124
	lda	#$03
	sta	$2125
	stz	$212a
	stz	$212b
	lda	#$07
	sta	$212e
	stz	$212f
	lda	#$ff
	sta	$2127
	stz	$2126

.zoomin2	sep	#$20
	lda	$4212
	and	#$80
	beq	.zoomin2
.W84VBlank3	lda	$4212
	and	#$80
	bne	.W84VBlank3
	dec	$728
	lda	$728

	sta	$2126
	eor	#$ff
	inc	a
	sta	$2127

	lda	$72a
	inc	a
	sta	$72a
	sta	$72c
	cmp	#$6e
	bne	.zoomin2


	lda	#$04
	sta	$4372
	rts

;*********************************************** Bank 00 Data ***************

	.Include Sources:Magical_1st_Demo/Incbins/Text.s
StarWars1
	dc.b	"fffffffffffffBORISffffffffffffff"
	dc.b	"ffffffffffffffffffffffffffffffff" 
	dc.b	"fffffffffffffffWEfffffffffffffff"
	dc.b	"ffffffffffffffffffffffffffffffff"
	dc.b	"ffffffffffffffLOVEffffffffffffff"
	dc.b	"ffffffffffffffffffffffffffffffff"
	dc.b	"ffffffffffffffYOUfffffffffffffff"
	dc.b	"ffffffffffffffffffffffffffffffff"
	dc.b	"ffffffffffffffffffffffffffffffff"
	dc.b	"fffffffffghijklmnopqffffffffffff"
	dc.b	"fffffffff",$7d,$7e,$7f,$80,$81,$82,$83,$84,$85,$86,$87,"ffffffffffff"
	dc.b	"fffffffff",$93,$94,$95,$96,$97,$98,$99,$9a,$9b,$9c,$9d,"ffffffffffff"
	dc.b	"fffffffff",$a9,$aa,$ab,$ac,$ad,$ae,$af,$b0,$b1,$b2,$b3,"ffffffffffff"
	dc.b	"fffffffff",$bf,$c0,$c1,$c2,$c3,$c4,$c5,$c6,$c7,$c8,$c9,"ffffffffffff"
	dc.b	"fffffffff",$d5,$d6,$d7,$d8,$d9,$da,$db,$dc,$dd,$de,$df,"ffffffffffff"
	dc.b	"fffffffff",$eb,$ec,$ed,$ee,$ef,$f0,$f1,$f2,$f3,$f4,$f5,"ffffffffffff"
	dc.b	"ffffffffffffffffffffffffffffffff"
	dc.b	"ffffffffffffffffffffffffffffffff"
	dc.b	"fffffffffffffANDfHEfffffffffffff"
	dc.b	"ffffffffffffffffffffffffffffffff"
	dc.b	"ffffffffffffLOVESfUSffffffffffff"
	dc.b	"ffffffffffffffffffffffffffffffff"
	dc.b	"ffffffffffffffffffffffffffffffff"
	dc.b	"fffffffffghijklmnopqffffffffffff"
	dc.b	"fffffffff",$7d,$7e,$7f,$80,$81,$82,$83,$84,$85,$86,$87,"ffffffffffff"
	dc.b	"fffffffff",$93,$94,$95,$96,$97,$98,$99,$9a,$9b,$9c,$9d,"ffffffffffff"
	dc.b	"fffffffff",$a9,$aa,$ab,$ac,$ad,$ae,$af,$b0,$b1,$b2,$b3,"ffffffffffff"
	dc.b	"fffffffff",$bf,$c0,$c1,$c2,$c3,$c4,$c5,$c6,$c7,$c8,$c9,"ffffffffffff"
	dc.b	"fffffffff",$d5,$d6,$d7,$d8,$d9,$da,$db,$dc,$dd,$de,$df,"ffffffffffff"
	dc.b	"fffffffff",$eb,$ec,$ed,$ee,$ef,$f0,$f1,$f2,$f3,$f4,$f5,"ffffffffffff"
	dc.b	"ffffffffffffffffffffffffffffffff"
	dc.b	"ffffffffffffffffffffffffffffffff"
	dc.b	"ffffffffffffffffffffffffffffffff"
	dc.b	"ffffffffffffffffffffffffffffffff"
	dc.b	"ffffffOKfENUFFfOFfTHISfSHITfffff"
	dc.b	"ffffffffffffffffffffffffffffffff"
	dc.b	"ffffffffffffffffffffffffffffffff"
	dc.b	"ffTOfGETfINTOfTHEfHIDDENfPARTfff"
	dc.b	"HOLDfSELECTfANDfPRESSfTHEfSTARTf"
	dc.b	"ffBUTTONfINfTHEfGREETINGSfPARTff"
	dc.b	"ffffffffffffffffffffffffffffffff"
	dc.b	"ffffffffffffffffffffffffffffffff"
	dc.b	"ffffffffffffffffffffffffffffffff"
	dc.b	"ffIfHOPEfTHISfWASfHARDfTOfREADff"
	dc.b	"ffffffffffffffffffffffffffffffff"
	dc.b	"ffffffffffffffffffffffffffffffff"
	dc.b	"fMfffMffAAfffGGGffIffCCfffAAffLf"
	dc.b	"fMMfMMfAffAfGfffGfIfCffCfAffAfLf"
	dc.b	"fMfMfMfAffAfGfffffIfCffffAffAfLf"
	dc.b	"fMfffMfAAAAfGfGGGfIfCffffAAAAfLf"
	dc.b	"fMfffMfAffAfGfffGfIfCffCfAffAfLf"
	dc.b	"fMfffMfAffAffGGGGfIffCCffAffAfLL"
	dc.b	"ffffffffffffffffffffffffffffffff"
	dc.b	"ffffffffffffOKfLETfTHISfffffffff"
	dc.b	"ffffffffffffffffffffffffffffffff"
	dc.b	"fffffffffffffffSHITfffffffffffff"
	dc.b	"ffffffffffffffffffffffffffffffff"
	dc.b	"fffffffffffffENDfNOWffffffffffff"
	dc.b	"ffffffffffffffffffffffffffffffff"
	dc.b	"fffffSOMEfSPECIALfHELLOSfGOfffff"
	dc.b	"ffffffffffffffffffffffffffffffff"
	dc.b	"ffffffffffffffTOfTHEffffffffffff"
	dc.b	"ffffffffffffffffffffffffffffffff"
	dc.b	"fffffffffWHITEfKNIGHTfOFffffffff"
	dc.b	"ffffffffffffffffffffffffffffffff"

	.Include Sources:Magical_1st_Demo/Incbins/Tables.s

;************************************* Irq Section *****************************

IRQ	rep	#$30
	pha
	phx
	phy
	phd
	phb
	sep	#$20
	ldx	#$0000
	phx
	pld
	phk
	plb
	lda	$4211
	ldx	IrqPointer
	jsr	(irqtab,x)
	rep	#$30
	plb
	pld
	ply
	plx
	pla
NMI	rti

irqtab	dcr.w	NMI
	dcr.w	irq5
	dcr.w	irq4
	dcr.w	irq3
	dcr.w	irq4
	dcr.w	irq1
	dcr.w	irq2

;********************************* Irq for Zoom Part **************************

irq5	ldx	$aa
	jsr	(!Irq5Tab,x)
	rts

Irq5Tab	dcr.w	InitScroll,Text13
	dcr.w	Mode7Scrol2,0

	dcr.w	ZoomLogInit,0
	dcr.w	ZoomLogo,0
	dcr.w	ZoomLogo,$20
	dcr.w	ZoomLogo,$10

	dcr.w	InitScroll,Text14
	dcr.w	Mode7Scrol,0

	dcr.w	InitScroll,StarWars1
	dcr.w	StarWarscr,0

	dcr.w	ZoomLogInit,10
	dcr.w	ZoomLogo,0
	dcr.w	ZoomLogo,$20
	dcr.w	ZoomLogo,$40

	dcr.w	InitScroll,Text12
	dcr.w	Mode7Scrol2,0

	dcr.w	ZoomLogInit,15
	dcr.w	ZoomLogo1,0
	dcr.w	ZoomLogo1,$20
	dcr.w	ZoomLogo1,$50

	dcr.w	InitScroll,Text15
	dcr.w	Mode7Scrol,0

	dcr.w	ZoomLogInit,5
	dcr.w	ZoomLogo,0
	dcr.w	ZoomLogo,$20
	dcr.w	ZoomLogo,$30

	dcr.w	InitScroll,Text16
	dcr.w	Mode7Scrol,0

	dcr.w	WaRpIt,0

WaRpIt	ldx	#$0000
	stx	$aa
	rts

ZoomLogInit	ldx	#$0001		;Init Logo(s)
	stx	$a2
	ldx	$aa
	lda	!Irq5Tab+2,x
	sta	$a4
	ldx	$a4
	rep	#$20
	lda	!LogoTable+3,x
	tax
	sep	#$20
	lda	#^ABNColors
	pha
	plb
	ldy	#$0000
	stz	$2121
.loop1	lda	!ABNColors,x
	sta	$2122
	inx
	iny
	cpy	#$20
	bne	.loop1
	phk
	plb

	lda	#$80
	sta	$211f
	stz	$211f
	lda	#$20
	sta	$2120
	stz	$2120
	lda	#$81
	sta	$211a
	lda	#$00
	sta	$210d
	stz	$210d
	lda	#$a8
	sta	$210e
	lda	#$ff
	sta	$210e
	stz	$212d
	ldx	#$ffff
	stx	$bc

	rep	#$20
	ldx	$aa
	inx
	inx
	inx
	inx
	stx	$aa
	rts

InitScroll	rep	#$30
	lda	!Irq5Tab+2,x
	sta	$d0
	ldx	#$0002		;Init Scroll
	stx	$a2
	sep	#$20
	lda	#^Mode7Colors
	pha
	plb
	CopyColor Mode7Colors,0,$80
	phk
	plb
	ldx	$aa
	inx
	inx
	inx
	inx
	stx	$aa
shit1	rts

ZoomLogo1	sep	#$20
	lda	#$21
	sta	$420c
ZoomLogo	rep	#$30
	lda	$a2
	cmp	#$0001
	beq	shit1

	sep	#$20
	lda	#$11
	sta	$212c
	stz	$2130
	rep	#$30

	ldx	$aa
	lda	!Irq5Tab+2,x
	tax
	lda	$bc
	cmp	#$ffff
	bne	.notfirst
	lda	!Zoomtab+$00,x
	sta	$b0
	sta	$b6
	lda	!Zoomtab+$02,x
	sta	$b2
	sta	$b8
	lda	!Zoomtab+$04,x
	sta	$b4
	sta	$ba
	lda	!Zoomtab+$0c,x
	sta	$bc
	lda	#$0000
	sta	$be
.notfirst	lda	!Zoomtab+$06,x
	clc
	adc	$b6
	sta	$b6
	lda	!Zoomtab+$08,x
	clc
	adc	$b8
	sta	$b8
	lda	!Zoomtab+$0a,x
	clc
	adc	$ba
	sta	$ba
	lda	!Zoomtab+$0e,x
	clc
	adc	$be
	sta	$be
	lda	$bc
	dec	a
	bne	.further
	lda	$aa
	inc	a
	inc	a
	inc	a
	inc	a
	sta	$aa
	lda	#$ffff
.further	sta	$bc
	lda	$b6		;Do X-Changes
	sep	#$20
	sta	$210d
	xba
	sta	$210d
	xba
	rep	#$20
	clc
	adc	#$80
	sep	#$20
	sta	$211f
	xba
	sta	$211f
	rep	#$20
	lda	$b8		;Do Y-Changes
	sec
	sbc	#$48
	sep	#$20
	sta	$210e
	xba
	sta	$210e
	xba
	rep	#$20
	clc
	adc	#$68
	sep	#$20
	sta	$2120
	xba
	sta	$2120

	rep	#$20

	lda	$be		;Do Z-Changes+Rotation
	and	#$7fe
	tay
	lda	cosine,y
	sta	$66
	lda	sinus,y
	sta	$64

	lda	$ba
	cmp	#$00ff
	bcc	.skipme
	lda	#$00ff
.skipme	sep	#$20
	sta	$4202

	rep	#$20
	lda	$66
	bpl	.Job0

	eor	#$ffff
	inc	a
	sep	#$20
	sta	$4203
	nop
	nop
	rep	#$20
	lda	$4216

	and	#$fff0
	.repeat 4 {
	pha
	rol	a
	pla
	rol	a
	}

	xba
	eor	#$ffff
	inc	a
	sep	#$20
	sta	$211b
	xba
	sta	$211b
	xba
	sta	$211e
	xba
	sta	$211e
	rep	#$20
	bra	.Job1

.Job0	sep	#$20
	sta	$4203
	nop
	nop
	rep	#$20
	lda	$4216

	and	#$fff0

	.repeat 4 {
	pha
	rol	a
	pla
	rol	a
	}

	xba
	sep	#$20
	sta	$211b
	xba
	sta	$211b
	xba
	sta	$211e
	xba
	sta	$211e
	rep	#$20
.Job1	lda	$64
	bpl	.Job2
	eor	#$ffff
	inc	a
	sep	#$20
	sta	$4203
	nop
	nop
	rep	#$20
	lda	$4216
	and	#$fff0

	.repeat 4 {
	pha
	rol	a
	pla
	rol	a
	}

	xba
	sep	#$20
	sta	$211d
	xba
	sta	$211d
	xba
	rep	#$20
	eor	#$ffff
	inc	a
	sep	#$20
	sta	$211c
	xba
	sta	$211c
	rep	#$20
	bra	.skip1

.Job2	sep	#$20
	sta	$4203
	nop
	nop
	rep	#$20
	lda	$4216

	and	#$fff0
	.repeat 4 {
	pha
	rol	a
	pla
	rol	a
	}

	xba
	eor	#$ffff
	inc	a

	sep	#$20
	sta	$211d
	xba
	sta	$211d
	xba
	rep	#$20
	eor	#$ffff
	inc	a
	sep	#$20
	sta	$211c
	xba
	sta	$211c

.skip1	rep	#$30
	rts


	;   Start x ,  y  ,  z  ,Add x,  y  ,  z  ,#Stepps,AddToAngle

Zoomtab	dcr.w	$0000,$0200,$0110,$0000,$fffe,$ffff,$0100,$fff0	;$00
	dcr.w	$0000,$0000,$0010,$0000,$0002,$0001,$0100,$fff0	;$10
	dcr.w	$0000,$0000,$0010,$0000,$0000,$0000,$0100,$fff0	;$20
	dcr.w	$0000,$0000,$0010,$0001,$0000,$0000,$0100,$fff0	;$30
	dcr.w	$0000,$0000,$0010,$0000,$0001,$0000,$0100,$fff0	;$40
	dcr.w	$0000,$0000,$0010,$0001,$0001,$0000,$0100,$fff8	;$50
	;$b0=Start x,$b2=Start y,$b4=Start z
	;$b6=Now   x,$B8=Now   y,$ba=Now   z
	;$bc=Number of Steps left

StarWarscr	rep	#$20		;StarWars scroller MODE 7 (Simple as SHIT!)
	lda	$a2
	cmp	#$0002
	beq	.skip1
	lda	#$140
	sep	#$20
	sta	$211b
	xba
	sta	$211b
	xba
	stz	$211c
	stz	$211c
	stz	$211d
	stz	$211d
	sta	$211e
	xba
	sta	$211e
	rep	#$30
	inc	$a6
	lda	$a6
	cmp	#$0500
	bne	.skip2

	ldx	#$0000
	stx	$a8
	ldx	$aa
	inx
	inx
	inx
	inx
	stx	$aa

.skip2	sep	#$20
	sta	$210e
	xba
	sta	$210e
	xba
	rep	#$30
	clc
	adc	#120
	sep	#$20
	sta	$2120
	xba
	sta	$2120

	lda	#$80
	sta	$211f
	lda	#$00
	sta	$211f
	lda	#$00
	sta	$210d
	lda	#$00
	sta	$210d
.skip1	rts

Mode7Scrol2	sep	#$20
	lda	#$21
	sta	$420c
	lda	#$a8
	sta	$210e
	lda	#$ff
	sta	$210e
	lda	#$20
	sta	$2120
	lda	#$00
	sta	$2120

Mode7Scrol	rep	#$20		;Scroll and Zoom in Mode 7
	lda	$a2		;Using Char and Boris
	cmp	#$0002
	beq	.skip3
	lda	$a0
	inc	a
	inc	a
	and	#$07fe
	sta	$a0
	tax
	lda	!sinus,x
	clc
	adc	#$120
	sep	#$20
	sta	$211b
	xba
	sta	$211b
	xba
	stz	$211c
	stz	$211c
	stz	$211d
	stz	$211d
	sta	$211e
	xba
	sta	$211e
	rep	#$20
	inc	$a6
	lda	$a6
	sep	#$20
	sta	$210d
	xba
	inc	a
	sta	$210d
	xba
	ora	#$80
	sta	$211f
	xba
	sta	$211f
	xba
	cmp	#$81
	beq	.chg
	cmp	#$88
	bne	.skip3
	ldx	#$0000
	stx	$a6
.skip3	rts

.chg	lda	#^Mode7Char
	pha
	plb
	ldx	#$0190
	ldy	$a8
	iny
	sty	$a8
	stx	$2116
.loop3	lda	($d0),y
	sec
	sbc	#$41
	sta	$2118
	lda	!Mode7Char,x
	sta	$2119
	iny
	inx
	cpx	#$01d0
	bne	.loop3

	rep	#$20
	lda	$d0
	sec
	sbc	#$40
	sta	$d0
	sep	#$20

	ldx	#$210
	stx	$2116
.loop2	lda	($d0),y
	sec
	sbc	#$41-39
	sta	$2118
	lda	!Mode7Char,x
	sta	$2119
	iny
	inx
	cpx	#$0250
	bne	.loop2

	lda	($d0),y
	bne	.skip4
	ldx	#$0000
	stx	$a8
	ldx	$aa
	inx
	inx
	inx
	inx
	stx	$aa
.skip4	phk
	plb
	rep	#$20
	lda	$d0
	clc
	adc	#$40
	sta	$d0
	sep	#$20
	rts



	
;********************************* Irq for Sound/Pic Part I&II ****************

irq4	jsr	H_Change
	rep	#$30
	sep	#$20
	lda	#$8f
	sta	$2100

	lda	#$00
	sta	$2102
	sta	$2103
	lda	#$10
	sta	$a0
	lda	$9f
	pha
	ldy	$9c
	dec	$9e
	lda	$9e
	cmp	#$ee
	bne	.skip2
	lda	#$ff
	sta	$9e

.skip2	sta	$2104
	xba
	lda	#$c0
	sta	$2104
	lda	($a8),y
	sec
	sbc	#$41
	asl	a
	pha
	sta	$2104
	cmp	#26*2
	bne	.skip1
	lda	$9f
	inc	a
	inc	a
	and	#$0e
	sta	$9f
.skip1	lda	$9f
	clc
	adc	#$31
	sta	$2104
	xba
	sta	$2104
	xba

	lda	#$c8
	sta	$2104
	pla
	pha
	clc
	adc	#54
	sta	$2104
	lda	$9f
	clc
	adc	#$31
	sta	$2104
	xba
	clc
	adc	#$08
	bcc	.skip5
	xba
	lda	$a0
	dec	a
	bne	.skip7
	pla

	lda	#$01
	xba
	lda	#53
	stz	$2104
	stz	$2104
	sta	$2104
	xba
	sta	$2104
	xba
	stz	$2104
	stz	$2104
	sta	$2104
	xba
	sta	$2104
	jmp	.skip6

.skip7	xba
.skip5	sta	$2104
	xba

	lda	#$c0
	sta	$2104
	pla
	pha
	inc	a
	sta	$2104
	lda	$9f
	clc
	adc	#$31
	sta	$2104
	xba
	sta	$2104
	xba

	lda	#$c8
	sta	$2104
	pla
	adc	#55
	sta	$2104
	lda	$9f
	clc
	adc	#$31
	sta	$2104	
	xba
	clc
	adc	#$09
	iny
	dec	$a0
	beq	.skip6
	jmp	.skip2

.skip6	lda	#$01
	stz	$2102
	sta	$2103
	lda	#$05
	xba
	lda	$9e
	clc
	adc	#$08
	bpl	.skip3
	lda	#$55
	xba
.skip3	xba
	sta	$2104


	ldx	#$0096
	stx	$2102


	lda	#$a0
	sta	$2104
	lda	#$d2
	sta	$2104
	lda	$a7
	clc
	adc	#$77
	sta	$2104
	lda	#$31
	sta	$2104


	lda	#$a8
	sta	$2104
	lda	#$d2
	sta	$2104
	lda	$a4
	clc
	adc	#$77
	sta	$2104
	lda	#$31
	sta	$2104

	lda	#$0f
	sta	$2100

	lda	$9e
	cmp	#$ef
	bne	.skip4
	ldy	$9c
	iny
	sty	$9c
	dey
	lda	($a8),y
	cmp	#"["
	bne	.skip4
	pla
	inc	a
	inc	a
	and	#$e
	pha
	rep	#$20
	tya
	clc
	adc	#$11
	tay
	sep	#$20
	lda	($a8),y
	bne	.skip4
	ldx	#$0000
	stx	$9c
.skip4	pla
	sta	$9f
	rts

H_Change	rep	#$20
	lda	#$1800
	sta	$2116
	ldx	$ae
	ldy	$b0
	lda	#$20
	sta	$b4
.loop	lda	scrsin,x
	pha
	lda	scrsin,y
	sta	$b2
	pla
	clc
	adc	$b2
	sec
	sbc	#$34
	lsr	a
	and	#$1ff
	ora	#$a000
	sta	$2118
	inx
	inx
	iny
	iny
	dec	$b4
	bne	.loop
	lda	$ae
	inc	a
	inc	a
	and	#$7e
	sta	$ae
	lda	$b0
	inc	a
	inc	a
	inc	a
	inc	a
	and	#$7e
	sta	$b0
	rts

;***************************** IRQ for Greetinx Part ********************

irq3	rep	#$30
	lda	$56
	clc
	adc	#$8
	and	#$7fe
	sta	$56
	tax
	lda	sinus,x
	clc
	adc	#$100
	lsr	a

	sep	#$20
	sta	$0201
	xba
	sta	$0202
	lda	#$8f
	sta	$2100
	jsr	putchars
	jsr	SpriteScrl
	jsr	Change_Text

	sep	#$20
	lda	$52
	beq	.skip2
	rep	#$20
	ldy	$4e
	and	#$00ff
	dec	a
	tax
	lda	Logo_Turn,x
	and	#$00ff
	pha
	clc
	adc	#$3e60
	sta	$2116
	pla
	clc
	adc	LogoOffset,y
	sta	$2118
	sep	#$20
	lda	$52
	inc	a
	bne	.skip1
	rep	#$20
	lda	#$3ee3
	sta	$2116
	lda	#$0083
	clc
	adc	LogoOffset,y
	sta	$2118
	lda	$4e
	inc	a
	inc	a
	and	#$07
	sta	$4e
	sep	#$20
	lda	#$00
.skip1	sta	$52
.skip2	sep	#$20

	ldx	#$0100
	stx	$2102
	lda	#$00
	sta	$2104
	sta	$2104
	sta	$2104
	sta	$2104
	sta	$2104
	sta	$2104
	sta	$2104
	sta	$2104
	sta	$2104
	sta	$2104
	sta	$2104
	sta	$2104
	sta	$2104
	sta	$2104
	sta	$2104
	sta	$2104

	lda	#$0f
	sta	$2100

	jsr	CalcChars
	jsr	CalcSpr
	jsr	Do_Scroll
	rep	#$30
	lda	$5e
	and	#$0007
	sep	#$20
	sta	$020a
	lda	$5e
	inc	a
	and	#$7
	bne	.skip5
	pha
	rep	#$20
	inc	$60
	lda	$60
	clc
	adc	#$21
	tax
	inc	$58
	inc	$58
	sep	#$20
	lda	text03,x
	bpl	.skip4
	rep	#$20
	stz	$60
.skip4	sep	#$20
	pla
.skip5	sta	$5e
retu	rep	#$10
	sep	#$20
	rts


Change_Text	rep	#$30
	lda	$c3
	bne	retu
	sep	#$20
	lda	$c0
	inc	a
	inc	a
	cmp	#$0a
	bcc	.skip1
	lda	#$00
.skip1	sta	$c0
	rep	#$30
	lda	$c1
	clc
	adc	#$0010
	cmp	#$0140
	bcc	.skip2
	lda	#$0000
.skip2	sta	$c1
	tay
	sep	#$20
	lda	$c0
	rep	#$20
	and	#$000f
	asl	a
	asl	a
	asl	a
	asl	a
	clc
	adc	#$2d88
	sta	$2116

	ldx	#$10
.loop1	sep	#$20
	lda	text05+$50,y
	rep	#$20
	and	#$1f
	clc
	adc	#$1120
	sta	$2118
	iny
	dex
	bne	.loop1
	rep	#$20
	lda	$c0
	and	#$0f
	tax
	sep	#$20

	lda	#$09
	sta	$3e5
	sta	$3e7
	sta	$3e9
	sta	$3eb
	sta	$3ed
	lda	#$0f
	sta	$3e5,x
	rts


Do_Scroll	rep	#$20
	lda	$c3
	inc	a
	inc	a
	inc	a
	inc	a
	and	#$3fc
	sta	$c3

	tax
	sep	#$20
	lda	sinus,x
	eor	#$ff
	sta	$20d

	rep	#$20
	txa
	clc
	adc	#20
	and	#$3fe
	tax
	sep	#$20
	lda	sinus,x
	eor	#$ff
	sta	$210


	rep	#$20
	txa
	clc
	adc	#20
	and	#$3fe
	tax
	sep	#$20
	lda	sinus,x
	eor	#$ff
	sta	$213

	rep	#$20
	txa
	clc
	adc	#20
	and	#$3fe
	tax
	sep	#$20
	lda	sinus,x
	eor	#$ff
	sta	$216

	rep	#$20
	txa
	clc
	adc	#20
	and	#$3fe
	tax
	sep	#$20
	lda	sinus,x
	eor	#$ff
	sta	$219
	rts


SpriteScrl	sep	#$20
	stz	$2101
	stz	$2102
	stz	$2103

times	set	0

	.repeat $100 {
	lda	$400+times
	sta	$2104
times	set	times+1
	}
	rts

putchars	rep	#$30
	ldx	#$0000
.loop1	lda	$500,x
	sta	$2116
	stz	$2118
	stz	$2118
	stz	$2118
	stz	$2118
	stz	$2118
	stz	$2118
	stz	$2118
	inx
	inx
	cpx	#33*2
	bne	.loop1
.loop2	lda	$500,x
	sta	$2116
	inx
	inx
	ldy	$500,x
	inx
	inx
	lda	char+$0,y
	sta	$2118
	lda	char+$2,y
	sta	$2118
	lda	char+$4,y
	sta	$2118
	lda	char+$6,y
	sta	$2118
	lda	char+$8,y
	sta	$2118
	lda	char+$a,y
	sta	$2118
	lda	char+$c,y
	sta	$2118
	cpx	#33*6
	bne	.loop2
	rts

CalcSpr	sep	#$30
	lda	$55
	inc	a
	tax
	sta	$55
	bne	.skip3
	lda	$54
	clc
	adc	#$20
	bne	.skip2
	inc	$52
	lda	$51
	inc	a
	cmp	#$14
	bne	.skip1
	lda	#$10
.skip1	sta	$51
	lda	#$00
.skip2	sta	$54
.skip3	ldy	$54
	sty	$a0
	lda	#$20
	sta	$53
	lda	#$00
	xba
	lda	#$00
	ldy	#$00
.loop1	xba
	sta	$400,y
	iny
	clc
	adc	#$8
	xba
	inx
	lda	Sprite_Sin,x
	sta	$400,y
	iny
	phy
	ldy	$a0
	lda	($50),y
	sec
	sbc	#$41
	iny
	sty	$a0
	ply
	sta	$400,y
	iny
	lda	#$31
	sta	$400,y
	iny
	dec	$53
	lda	$53
	bne	.loop1
	phy
	lda	#$00
	xba
	lda	#$00
	ldx	$55
	lda	#$20
	sta	$53
	ldy	$54
	sty	$a0
	ply
.loop2	xba
	sta	$400,y
	iny
	clc
	adc	#$8
	xba
	inx
	lda	Sprite_Sin,x
	clc
	adc	#$8
	sta	$400,y
	iny
	phy
	ldy	$a0
	lda	($50),y
	sec
	sbc	#$17
	iny
	sty	$a0
	ply
	sta	$400,y
	iny
	lda	#$31
	sta	$400,y
	iny
	dec	$53
	lda	$53
	bne	.loop2
	rep	#$10
	rts

CalcChars	rep	#$30
	ldx	#$0000
	lda	$58
	pha
	sta	$5a
	lda	$5e
	bne	.skip1
	dec	$5a
	dec	$5a
.skip1	lda	#$2008	
.loop1	sta	$5c
	ldy	$5a
	iny
	iny
	sty	$5a
	lda	scrsin,y
	clc
	adc	$5c
	sta	$500,x
	inx
	inx
	lda	$5c
	clc
	adc	#$40
	cmp	#$2848
	bne	.loop1
	txy

	pla
	inc	a
	inc	a
	and	#$7f
	sta	$58
	sta	$5a
	ldx	$60
	lda	#$2008
.loop2	sta	$5c
	phy
	ldy	$5a
	iny
	iny
	sty	$5a
	lda	scrsin,y
	ply
	clc
	adc	$5c
	sta	$500,y
	iny
	iny
	lda	text03,x
	and	#$3f
	asl	a
	asl	a
	asl	a
	asl	a
	sta	$500,y
	iny
	iny
	inx
	lda	$5c
	clc
	adc	#$40
	cmp	#$2848
	bne	.loop2
	rts

;***************************** IRQ for Credits Part *********************

irq2	rep	#$20
	lda	$5c
	bmi	.skip4
	and	#$01
	sta	$5c
	beq	.skip3
	lda	$62
	asl	a
	asl	a
	asl	a
	asl	a
	sta	$60
	clc
	adc	#$310
	clc
	adc	$5e
	sep	#$20
	sta	$0204
	xba
	sta	$0205
	rep	#$20
	lda	$5e
	and	#$000f
	sta	$5e
	bne	.skip2
	stz	$5e
	ldx	$64
	jsr	putline
	ldx	$62
	inx
	cpx	#$10
	bne	.skip
	ldx	#$0000
.skip	stx	$62
	rep	#$20
	lda	$64
	clc
	adc	#$10
	cmp	#$790
	bne	.skip1
	lda	#$fffe
	sta	$5c
.skip1	sta	$64
.skip2	rep	#$20
	inc	$5e
.skip3	inc	$5c
.skip4	sep	#$20
	rts

putline	rep	#$20
	lda	$62
	asl	a
	asl	a
	asl	a
	asl	a
	asl	a
	asl	a
	clc
	adc	#$1808
	sta	$2116
	clc
	adc	#$20
	pha
	ldy	#$0000	
.loop1	sep	#$20
	lda	text02,x
	rep	#$20
	and	#$007f
	asl	a
	phx
	tax
	lda	asciitab2,x
	plx
	sta	$2118
	inx
	iny
	cpy	#$10
	bne	.loop1
	txa
	sec
	sbc	#$10
	tax
	pla
	sta	$2116
	ldy	#$0000
.loop2	sep	#$20
	lda	text02,x
	rep	#$20
	and	#$007f
	phx
	asl	a
	tax
	lda	asciitab2,x
	plx
	clc
	adc	#42
	sta	$2118
	inx
	iny
	cpy	#$10
	bne	.loop2
	sep	#$20
	rts

;***************************** IRQ for SPACEPLANE Part *********************

irq1	jsr	scroll
	rep	#$20
	lda	$5e
	sec
	sbc	#$80
	sta	$6f6

	lda	$5e
	sep	#$20
	sta	$211f
	xba
	sta	$211f

	rep	#$20
	lda	$60
	sec
	sbc	#$c0
	sta	$06ff

	lda	$60
	sta	$2120
	xba
	sta	$2120

	rep	#$30

	ldy	$62
	lda	cosine,y
	sta	$66
	lda	sinus,y
	sta	$64

	ldy	#$0003
	ldx	#$10bd
	lda	#$0011
	sta	$70

.3DLoop	sep	#$20
	stx	$4204
	lda	$70
	sta	$4206
	nop
	nop
	nop
	nop
	nop
	dex
	inc	$70
	lda	$4214
	sta	$4202

	rep	#$20

	lda	$66
	bpl	.Job0

	eor	#$ffff
	inc	a
	sep	#$20
	sta	$4203
	nop
	iny
	rep	#$20
	lda	$4216

	and	#$ff80
	asl	a
	bcc	.skip1
	inc	a
.skip1	xba

	eor	#$ffff
	inc	a
	sta	$0206,y
	sta	$05b7,y
	bra	.Job1

.Job0	sep	#$20
	sta	$4203
	nop
	iny
	rep	#$20
	lda	$4216

	and	#$ff80
	asl	a
	bcc	.skip2
	inc	a
.skip2	xba

	sta	$0206,y
	sta	$05b7,y

.Job1	lda	$64
	bpl	.Job2
	eor	#$ffff
	inc	a
	sep	#$20
	sta	$4203
	iny
	iny
	rep	#$20
	lda	$4216

	and	#$ff80
	asl	a
	bcc	.skip3
	inc	a
.skip3	xba

	sta	$047a,y
	eor	#$ffff
	inc	a
	sta	$033f,y
	bra	.Job3

.Job2	sep	#$20
	sta	$4203
	iny
	iny
	rep	#$20
	lda	$4216

	and	#$ff80
	asl	a
	bcc	.skip4
	inc	a
.skip4	xba
	sta	$033f,y
	eor	#$ffff
	inc	a
	sta	$047a,y

.Job3	cpy	#315
	beq	Finished
	jmp	.3DLoop

Finished	sep	#$20
.Pad	lda	$4212
	and	#$01
	bne	.Pad

	rep	#$20

	lda	$5a
	eor	#$3
	sta	$5a

	ldx	$4218

	txa
	and	#$0010
	beq	.NotRight
	lda	$62
	clc
	adc	#$04
	and	#$07ff
	sta	$62
.NotRight	txa
	and	#$0020
	beq	.NotLeft
	lda	$62
	sec
	sbc	#$04
	and	#$07ff
	sta	$62
.NotLeft	txa
	and	#$0f00
	xba
	asl	a
	tax
	lda	DirTab,x
	beq	.NoPadMove
	sta	$58
	lda	$62
	clc
	adc	#$55

	sta	$4204
	sep	#$20
	lda	#$aa
	sta	$4206
	.repeat 8 {
	nop
	}
	lda	$4214
	rep	#$20
	and	#$f
	clc
	asl	a
	adc	$58
	tax
	jsr	(direction,x)
.NoPadMove	sep	#$20
	rts

DirTab	dcr.w	0,8,20,0,2,6,22,0,14,10,18,0,0,0,0,0

direction	dcr.w	Ntg,LEFT,UPLEF1,UPLEF,UP,UPRIG,UPRIG1,RIGHT,DWNRIG1,DWNRIG,DOWN
	dcr.w	DWNLEF,DWNLEF1,LEFT,UPLEF1,UPLEF,UP,UPRIG,UPRIG1,RIGHT,DWNRIG1,DWNRIG
	dcr.w	DOWN,DWNLEF,DWNLEF1,LEFT,UPLEF1,UPLEF,UP,UPRIG,UPRIG1,RIGHT,DWNRIG1

	rep	#$30

UP	ldx	$5e
	inx
	inx
	cpx	#$400
	bcc	.skip
	dex
	dex
.skip	stx	$5e
Ntg	rts

DOWN	ldx	$5e
	dex
	dex
	bpl	.skip
	inx
	inx
.skip	stx	$5e
	rts

LEFT	ldx	$60
	inx
	inx
	cpx	#$400
	bcc	.skip
	dex
	dex
.skip	stx	$60
	rts

RIGHT	ldx	$60
	dex
	dex
	bpl	.skip
	inx
	inx
.skip	stx	$60
	rts

DWNRIG	lda	$60
	dec	a
	bpl	.skip1
	inc	a
.skip1	sta	$60
	lda	$5e
	dec	a
	dec	a
	bpl	.skip2
	inc	a
	inc	a
.skip2	sta	$5e
	rts

DWNRIG1	lda	$60
	dec	a
	dec	a
	bpl	.skip1
	inc	a
	inc	a
.skip1	sta	$60
	lda	$5e
	dec	a
	bpl	.skip2
	inc	a
.skip2	sta	$5e
	rts

DWNLEF	lda	$60
	cmp	#$400
	bcs	.skip1
	inc	a
.skip1	sta	$60
	lda	$5e
	dec	a
	dec	a
	bpl	.skip2
	inc	a
	inc	a
.skip2	sta	$5e
	rts

DWNLEF1	lda	$60
	cmp	#$400
	bcs	.skip1
	inc	a
	inc	a
.skip1	sta	$60
	lda	$5e
	dec	a
	bpl	.skip2
	inc	a
.skip2	sta	$5e
	rts

UPRIG	lda	$60
	dec	a
	bpl	.skip1
	inc	a
.skip1	sta	$60
	lda	$5e
	cmp	#$400
	bcs	.skip2
	inc	a
	inc	a
.skip2	sta	$5e
	rts

UPRIG1	lda	$60
	dec	a
	dec	a
	bpl	.skip1
	inc	a
	inc	a
.skip1	sta	$60
	lda	$5e
	cmp	#$400
	bcs	.skip2
	inc	a
.skip2	sta	$5e
	rts

UPLEF	lda	$60
	cmp	#$400
	bcs	.skip1
	inc	a
.skip1	sta	$60
	lda	$5e
	cmp	#$400
	bcs	.skip2
	inc	a
	inc	a
.skip2	sta	$5e
	rts

UPLEF1	lda	$60
	cmp	#$400
	bcs	.skip1
	inc	a
	inc	a
.skip1	sta	$60
	lda	$5e
	cmp	#$400
	bcs	.skip2
	inc	a
.skip2	sta	$5e
	rts

	sep	#$20

scroll	lda	$0100
	sta	$2111
	stz	$2111
	lda	$0100
	inc	a
	and	#$0f
	cmp	#$01
	bne	.skip1
	ldx	$0101
	inx
	stx	$0101
.skip1	sta	$0100

	ldy	#$7540
	rep	#$20

.loop	ldx	$0101
	inc	$0101
	lda	text01,x
	asl	a

	and	#$00fe
	tax
	lda	asciitab,x

	.repeat 3 {
	tax
	tya
	sta	$2116
	clc
	adc	#$20
	tay
	txa
	sta	$2118
	inc	a
	sta	$2118
	clc
	adc	#79
	}

	tax
	tya
	sta	$2116
	sec
	sbc	#$5e
	tay
	txa
	sta	$2118
	inc	a
	sta	$2118
	cpy	#$7560
	bne	.loop

	lda	$0101
	tax
	sec
	sbc	#$10
	sta	$0101	
	lda	text01,x
	cmp	#$ffff
	bne	.skip2
	stz	$0101
	lda	#$0020		
.skip2	asl	a
	rep	#$20
	and	#$00fe
	tax
	lda	asciitab,x
	tax
	lda	#$7940
	sta	$2116
	clc
	adc	#$20
	tay
	txa
	sta	$2118
	inc	a
	sta	$2118

	.repeat 3 {
	clc
	adc	#79
	tax
	tya
	sta	$2116
	clc
	adc	#$20
	tay
	txa
	sta	$2118
	inc	a
	sta	$2118
	}

	sep	#$20
Ende	rts

	org	$f000
	dc.b	"To Contact me call ++49-5251-65459 and ask for Kay"

	org	$ffc0
	dc.b	"MAGICAL DEMO BY TPH",0

	org	$ffe4
	dcr.w	NMI,NMI,NMI,NMI,Start,IRQ
	org	$fff4
	dcr.w	NMI,NMI,NMI,NMI,Start
EndOfBank0	.say	Bytes free in Bank 0:
	exp=	$8000-(Ende-Start)

	.pad

;	*************************************************************************
;	*********** Bank 01 ************ Graphics and HDMA Tables ***************
;	*************************************************************************
	
char01	.bin	Sources:Magical_1st_Demo/Incbins/char01.snes		;Length of Char =10240 = $2800

ABNColors	.bin	Sources:Magical_1st_Demo/Incbins/Abandon.pal
ATXColors	.bin	Sources:Magical_1st_Demo/Incbins/Anthrox.pal
BSLColors	.bin	Sources:Magical_1st_Demo/Incbins/Baseline.pal
PREColors	.bin	Sources:Magical_1st_Demo/Incbins/Premiere.pal
LinksBorder	.bin	Sources:Magical_1st_Demo/Incbins/CredBorder.snes
coloraddtil	.bin	Sources:Magical_1st_Demo/Incbins/Coloradd.snes
colorpart1	.bin	Sources:Magical_1st_Demo/Incbins/CredCol.snes
	dc.b	0,0,$08,$21,$10,$42,$18,$63,0,0,0,0,0,0,0,0
ColorPart1a	.bin	Sources:Magical_1st_Demo/Incbins/Char02.col
colorlogo	dc.b	$00,$00,$DE,$7B,$56,$7B,$14,$73,$D2,$6A,$90,$62,$4E,$5A,$0C,$52
	dc.b	$CA,$49,$88,$41,$46,$39,$06,$31,$C4,$28,$84,$20,$00,$00,$00,$00
colorchar	dc.b	$00,$00,$de,$3b,$18,$23,$54,$12
ColorZug	.bin	Sources:Magical_1st_Demo/Incbins/ZugCol.snes
colorBigLog	.bin	Sources:Magical_1st_Demo/Incbins/logo02.col
	dc.b	$00,$00,$40,$72,$80,$61,$c0,$48
ColorIntro	.bin	Sources:Magical_1st_Demo/Incbins/Intro.col

BigLogo	.bin	Sources:Magical_1st_Demo/Incbins/logo02.raw
BigLogoScr	.bin	Sources:Magical_1st_Demo/Incbins/logo02.scr

HDMAList	dc.b	120,$01,1,$07,0,0			;List1   6 bytes at $0200
	dc.b	120,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,0,0,0	;List2 315 bytes at $0206
	dc.b	120,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,0,0,0	;List3 315 bytes at $0341
	dc.b	120,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,0,0,0	;List4 315 bytes at $047c
	dc.b	120,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0
	dc.b	1,0,0,1,0,0,1,0,0,1,0,0,0,0,0	;List5 315 bytes at $05b7
	dc.b	121,0,0,1,0,0,0,0,0			;List6   9 bytes at $06f2
	dc.b	121,0,0,1,0,0,0,0,0			;List7   9 bytes at $06fb
	dc.b	120,$0f,1,$00,1,$02,2,$03,2,$04,3,$05,3,$06,4,$07,4,$08,5,$09
	dc.b	5,$0a,6,$0b,6,$0c,7,$0d,7,$0e,8,$0f	;List8  36 bytes at $0704
	dc.b	0,0,0,0				Length of List = 1320 = $0528		
	dc.b	$6e,$00,$1,$0f,$1,$0f,$1,0,0,0	;List8b	10 bytes at $0728

HDMALists	dc.b	$00,$05,$00,$02
	dc.b	$02,$1b,$06,$02
	dc.b	$02,$1c,$41,$03
	dc.b	$02,$1d,$7c,$04
	dc.b	$02,$1e,$b7,$05
	dc.b	$02,$0d,$f2,$06
	dc.b	$02,$0e,$fb,$06
	dc.b	$00,$00,$04,$07

IntroGFX	.bin	Sources:Magical_1st_Demo/Incbins/IntroMan.Snes
	.bin	Sources:Magical_1st_Demo/Incbins/IntroTx1.Snes
	.bin	Sources:Magical_1st_Demo/Incbins/IntroTx2.Snes

EndOfBank1	.say	Bytes free in Bank 1:
	exp=	$8000-(EndOfBank1-char01)
	.pad

;	*************************************************************************
;	*********** Bank 02 ********************** Graphics and Tables **********
;	*************************************************************************

Spacetiles	.bin	Sources:Magical_1st_Demo/Incbins/Spacetiles.snes
SpaceMap	.bin	Sources:Magical_1st_Demo/Incbins/SpaceMap.snes
SpaceColor	.bin	Sources:Magical_1st_Demo/Incbins/SpaceCol.snes
Char02	.bin	Sources:Magical_1st_Demo/Incbins/Char02.snes
ZugPart2	.bin	Sources:Magical_1st_Demo/Incbins/Zugb02.snes
Char03	.bin	Sources:Magical_1st_Demo/Incbins/Char03.snes
TuneSel	.bin	Sources:Magical_1st_Demo/Incbins/TuneSel.Snes
Char03Cols	.bin	Sources:Magical_1st_Demo/Incbins/Char03.col
MainBorder	.bin	Sources:Magical_1st_Demo/Incbins/CredMain.snes
LogoScreen	.bin	Sources:Magical_1st_Demo/Incbins/logo01.scr		;Length of Scrn =  576 = $0240

HDMAList2	dc.b	$10,$f0,$03,$01,$20,$03,0,0,0,0,0,0
	dc.b	$10,$01,$01,$03,0,0
HDMALists2	dc.b	$02,$10,$00,$02
	dc.b	$00,$2c,$0c,$02
HDMAList3	dc.b	$47,$88,0,$1,0,0,0,0,0
	dc.b	$48,0,0,$1f,8,0,$8,16,0,$8,24,0,$8,32,0,$8,40,0,0,0,0
	.repeat 220 {
	dc.b	1,0
	}
	dc.b	0,0
	dc.b	1,$00,$6e,$0f,$6e,$0f,1,$00,0,0
	dc.b	$5f,$0f,8,$9,8,$9,8,$9,8,$9,8,$9,1,$f,0,0

HDMALists3	dc.b	$02,$0f,$00,$02
	dc.b	$02,$11,$09,$02
	dc.b	$00,$27,$1e,$02
	dc.b	$00,$00,$d8,$03
	dc.b	$00,$00,$e2,$03

HDMALists4	dc.b	$00,$01,$e7,$05
	dc.b	$02,$1b,$00,$02
	dc.b	$02,$1e,$00,$02
	dc.b	$02,$1b,$b5,$04
	dc.b	$02,$1e,$b5,$04
	dc.b	$00,$00,$ef,$05

HDMAList4
xyz	SET	10
	.repeat 230 {
	dc.b	1
	dcr.w	$7fff/xyz
xyz	SET	xyz+1
	}
	dc.b	0,0,0

xyz	SET	400
	.repeat 100 {
	dc.b	1
	dcr.w	xyz
xyz	SET	xyz-4
	}
	dc.b	1,0,$1
	dc.b	0,0,0

	dc.b	$1,$42,$7f,$42,$60,$43,0,0
	dc.b	$1,$00,$1,$00,0,0

HDMALists5	dc.b	$00,$00,$00,$02
HDMAList5	dc.b	$01,$00,$6e,$0f,$6e,$0f,$01,$00,$00,$00

EndOfBank2	.say	Bytes free in Bank 2:
	exp=	$8000-(EndOfBank2-Spacetiles)
	.pad

;	*************************************************************************
;	*********** Bank 03 ********************** Empty (Not for Long) *********
;	*************************************************************************

Mode7Colors	.bin	Sources:Magical_1st_Demo/Incbins/Boris.Pal
Mode7Char	.bin	Sources:Magical_1st_Demo/Incbins/Char8x16.Mode7
Mode7Boris	.bin	Sources:Magical_1st_Demo/Incbins/Boris.Mode7
Wizardb6	.bin	Sources:Magical_1st_Demo/Incbins/Wizard02.Snes
WizardColor	.bin	Sources:Magical_1st_Demo/Incbins/WizrdCol.Snes
LogoTile	.bin	Sources:Magical_1st_Demo/Incbins/logo01.raw		;Length of Logo = 5856 = $16e0

Text12	dc.b	"ffffffffffffffffffffffffffffffff"
	dc.b	"ffffffffffffffffffffffffffffffff"
	dc.b	"TOfBUYfCOPIERSfANDfOTHERfEQUIPMENTfREADfTHEfSCROLLERfINfTHEfPLANEfPART"
	dc.b	"fANDfSOMEfVERYfSPECIALfGREETINGSfTOfTHEfGUYfWHOfHELPEDfMEfSPREADING"
	dc.b	"fTHISfSMALLfPILEfOFfBYTESfANDfISfAfNICEfFRIENDfOFfMINEfANYWAYSf"
	dc.b	"ffSPECIALfTHANKSfGOfTOffSIGMAfbfOFf"
	dc.b	"ffffffffffffffffffffffffffffffff"
	dc.b	"ffffffffffffffffffffffffffffffff",0

Text13	dc.b	"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
	dc.b	"WELCOMEfTOfTHEfFIRSTfPARTfOFfTHISfDEMOfffLETfMEfSHOWfYOUfSOMEf"
	dc.b	"NICEfLOGOSfe"
	dc.b	"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",0

Text14	dc.b	"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
	dc.b	"IfKNOWfTHATfTHISfONEfISfUNREADABLEffffBUTfLETfMEfSHOWfYOUfTHEfRE"
	dc.b	"ASONfFORfGERMANSfTOfBEfPROUDfOFfTHEIRfCOUNTRYfffHEHE"
	dc.b	"ffffffffffffffffffffffffffffffffffffffffffffffffffff",0

Text15	dc.b	"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
	dc.b	"ANDfNOOGMANfDIDfANOTHERfNICEfLOGOfFORf"
	dc.b	"ffffffffffffffffffffffffffffffffffffffffffffffffffff",0

Text16	dc.b	"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
	dc.b	"HEYfSTUPIDfPRESSfSTARTfTOfGOfONfORfWATCHfTHEfWHOLEfSHITfAGAIN"
	dc.b	"ffffffffffffffffffffffffffffffffffffffffffffffffffff",0


EndOfBank3	.say	Bytes free in Bank 3:
	exp=	$8000-(EndOfBank3-Mode7Colors)
	.pad

;	*************************************************************************
;	*********** Bank 04 ********************** Logo and Gfx *****************
;	*************************************************************************

Mountain	.bin	Sources:Magical_1st_Demo/Incbins/Mountain1.snes
	.bin	Sources:Magical_1st_Demo/Incbins/Mountain2.snes
	.bin	Sources:Magical_1st_Demo/Incbins/Mountain3.snes
	.bin	Sources:Magical_1st_Demo/Incbins/Mountain4.snes
Mountaincol	.bin	Sources:Magical_1st_Demo/Incbins/Mountain.Pal

	.pad

;	*************************************************************************
;	*********** Bank 05 ********************** Logos for Greetings **********
;	*************************************************************************

Abandonlog	.bin	Sources:Magical_1st_Demo/Incbins/Abandon.Snes
Anthroxlog	.bin	Sources:Magical_1st_Demo/Incbins/Anthrox.Snes
Baselinelog	.bin	Sources:Magical_1st_Demo/Incbins/Baseline.Snes
Premierelog	.bin	Sources:Magical_1st_Demo/Incbins/Premiere.Snes
	.pad

;	*************************************************************************
;	*********** Bank 06-09 ******************* Wolfchild Tunes **************
;	*************************************************************************

	.bin	Sources:Magical_1st_Demo/Incbins/WolfChild.Bin
	.pad

;	*************************************************************************
;	*********** Bank 0a ********************** Zug Tiles ********************
;	*************************************************************************

ZugPart1	.bin	Sources:Magical_1st_Demo/Incbins/Zugb01.snes

;	*************************************************************************
;	*********** Bank 0b ********************** Wizard Tiles  ****************
;	*************************************************************************

Wizardb8	.bin	Sources:Magical_1st_Demo/Incbins/Wizard01.Snes

;	*************************************************************************
;	*********** Bank 0c-0f ******************* Turrican Tunes ***************
;	*************************************************************************

	.bin	Sources:Magical_1st_Demo/Incbins/turrican.bin
