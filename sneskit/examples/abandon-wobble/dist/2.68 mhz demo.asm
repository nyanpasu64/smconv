
;Make Sure to use the Right Tabulator Sizes: (Make sure always two ";" are under each other!)

;This Colons :
;	;	;	;	;	;	;	;	;	;	;	;	;

;Should Be in same Position as this:
;                  ;      ;         ;       ;       ;       ;       ;       ;       ;       ;   ;   ;


;	Author:	Kay Struve
;	E-Mail:	pothead@uni-paderborn.de
;	Telephone:	++49-(0)5251-65459
;	Date:		Beginning of 1994
;	Machine:	Super Nintendo (65816)
;	Assembled with:	SASM V1.81,V2.00


	heap	O=$140000			;Hope you got enuff ram, hehehe
	lrom				;Low Rom, slow Rom Banking ($00-$7f)
	SMC+				;Super MagicCom header

	.say	---------------------------------------------------------------------
	.say	------------------ "Draw a Line" featuring: 65816 -------------------
	.say	------------- Now extended to draw a Hidden Surface Object ----------
	.say	---------------------------------------------------------------------

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

	.include Sources:sasm/include/ppuregs.i
	.include sources:sasm/include/math.i

;	********* Macros ***********
;FOLD_OUT
Bank	macro				;\=Label of the Bank to change to
	lda	#^\1
	pha
	plb
	endm

CopyColor	macro				;\1=Adress of Colortab in Rom
	ldx	#$0000			;\2=Destination Adress in CG-Ram
	lda	#\2			;\3=Number of Colors to be copied
	sta	CGADD
.init	lda	!\1,x
	sta	CGDATA
	inx
	cpx	#\3*2
	bne	.init
	endm

CopyToVRAM	macro				;\1=Source Adress of Gfx in Rom
	ldx	#\2			;\2=Destination Adress for Gfx in V-Ram
	stx	VMADDL			;\3=Number of Bytes to be transfered
	ldx	#$0000
.copy	lda	!\1,x
	sta	VMDATAL
	inx
	inx
	cpx	#\3
	bne	.copy
	endm

Coord	macro				;Datatype for 3d Coordinates
	.byte	\1,\2,\3
	endm

LineH	macro
	.word	\1,\2*3,\3*3		;\1 Number of Line,\2 Point 1,\3 Point 2
	endm

;FOLD_END

;	*************************************************************************
;	********* BANK 00 at $08000 ****** CODE SECTION + Used Tables ***********
;	*************************************************************************

MAXPOINTS	EQU	16


Object_Buf	EQU	$7e0800
OneBPL_Buf	EQU	$7e1000			;One Bitplane of a 4 Col Char (26*26 Chars)
TwoBPL_Buf	EQU	$7e4040			;Making a Total of 10816 Bytes ($3040)
HDMAFive	EQU	$7e0400
UnpackBuffr	EQU	$7f01a0			;Destination Adress for Depacking
OAM_Buffer	EQU	$7e0400			;$200 Bytes of OAM Ram Mirror-Image

	rs=	$0c
Act_Main	rs.w	1

	rs=	$28
Musik_ZP1	rs.w	1
Musik_ZP2	rs.w	1

	rs=	$200
Musik_RAM1	rs.w	1
Musik_RAM2	rs.w	1

	rs=	$2c		;Zero Page Registers for Rotate_Object Routine
Dummy_Sin	rs.w	1
Comm_Bit	rs.b	1
Act_Object	rs.w	1
Act_Buffer	rs.w	1
Old_Buffer	rs.w	1
Rot_Dummy1	rs.w	1
Rot_Dummy2	rs.w	1		;Zero Page Registers for Line-Routine
L_X2Pos	rs.w	1		;Also used for the Sinus-Scroller
L_Y2Pos	rs.w	1		;and the Wobble-me-Part
L_X1Pos	rs.w	1
L_Y1Pos	rs.w	1
L_DeltaX	rs.w	1
L_DeltaY	rs.w	1
L_Incr1	rs.w	1
L_Incr2	rs.w	1
L_Dummy	rs.w	1
L_OraVal	rs.w	1
Drw_PoiPoi	rs.w	1		;Zero Page Registers for Draw_Object Routine
Drw_Face	rs.w	1
Drw_Dummy	rs.w	1
X_Add	rs.w	1
Y_Add	rs.w	1
Z_Add	rs.w	1
Script_Next	rs.w	1
Script_Poi	rs.w	1
Hundekuchen	rs.w	1

	rs=$800			;Object_Buf!
OBuf_Points	rs.w	1			;Number of Points Object is using
OBuf_Faces	rs.w	1			;Number of Surfaces Object is using
OBuf_Lines	rs.w	1			;Number of Lines Surface is using
OBuf_RotX	rs.w	1			;Angle for X-Rotation
OBuf_XSin	rs.w	1			;Sinus of X-Rot Angle
OBuf_XCos	rs.w	1			;Cosin of X-Rot Angle
OBuf_RotY	rs.w	1			;Angle for Y-Rotation
OBuf_YSin	rs.w	1			;Sinus of Y-Rot Angle
OBuf_YCos	rs.w	1			;Cosin of Y-Rot Angle
OBuf_RotZ	rs.w	1			;Angle for Z-Rotation
OBuf_ZSin	rs.w	1			;Sinus of Z-Rot Angle
OBuf_ZCos	rs.w	1			;Cosin of Z-Rot Angle
OBuf_Color	rs.w	1			;Color of Surface Buffer
OBuf_Dist	rs.w	1			;Distance of Object to eye (Z) ($80-$3c0)
OBuf_RotPts	rs.b	3*MAXPOINTS		;Buffer for rotated Points



;	Offsets for Decrunched Datas

;		Offsets for the Wobbeling Decrunching
DreieckScr	EQU	UnpackBuffr
Dreieck2	EQU	UnpackBuffr+1024
Dreieck1	EQU	UnpackBuffr+1024+8736
DreieckCols	EQU	UnpackBuffr+1024+8736+8736

	;	Offsets for Filled-Vektor Decrunching
Logo1	EQU	UnpackBuffr				;Packed2.RNC
Logo1Col	EQU	UnpackBuffr+12480

	;	Offsets for Sinus-Scroller Decrunching
Mode7Char	EQU	UnpackBuffr				;Packed3.RNC
Mode7Cols	EQU	UnpackBuffr+2432
Mode7Logo	EQU	UnpackBuffr+2432+128
Mode7LogoCols	EQU	UnpackBuffr+2432+128+8192+8192

	;	Offsets for Shade-Bob Decrunching
Logo	EQU	UnpackBuffr				;Packed4.RNC
Logo_Colors	EQU	UnpackBuffr+8192


;Rotation:	x`=x*Sinus(z)		z=Rotation Angle
;	y`=x*Cosine(z)


Bank00	.byte	"  !Author:Kay Struve,UGHSPaderborn,Germany."
	.byte	"Date:21.03.93"
	.byte	"Title:Why coding shit on the Super Nintendo when there "
	.byte	"are plenty of more important things to do."
	.byte	"  Version:0.12."
	.byte	"  To Contact The Author of this Shitty Production send E-Mail"
	.byte	" to pothead@uni-paderborn.de (Internet)."
	.byte	"or leave Mail to me in any of this US BBS`s:"
	.byte	"Mirage,USS Enterprise,Menace 2 Society or Danse Macabre."
	.byte	"This piece of Software was Produced using the SASM made by Florian"
	.byte	" W. Sauer."

Start	;.include Sources:sasm/include/resethandler.i		;Power Reset
	sei
	clc
	xce				;Native Mode on (Fuck 6502!)
	sep	#$20
	rep	#$10
	ldx	#$01ff			;Stack starts at $1ff (going down)
	txs
	ldx	#$0000
	stx	Act_Main			;Initialize Main and VBR Pointers
	phx
	pld				;Zero Page at $7e0000

	sep	#$30			;Fade out Screen
	ldx	#$0f
.w80	ldy	#$06
.w81	lda	REG_HVBJOY
	bpl	.w81
.w82	lda	REG_HVBJOY
	bmi	.w82
	dey
	bne	.w81
	dex
	beq	.quit
	stx	REG_INIDISP
	bra	.w80
.quit	rep	#$10
	lda	#$80
	sta	REG_INIDISP
	jsr	Initregs
	jsr	Check_For_Hidden		;Check wether hidden part is activated
	jsr	Init_Musik		;First music init
	lda	#$21			;Enable V-Timer-IRQ and Auto-Pad-Read
	sta	REG_NMITIMEN
.forever	ldx	Act_Main			;Non-Vertical-Blanc-IRQ Routines
	jsr	(!MainRoutine,x)
	jmp	.forever

MainRoutine	.word	Initscreen8,Main__08	;Introduction Main
	.word	Initscreen7,Main__07	;Landscape Main
	.word	Initscreen9,Main__09	;Picture Main
	.word	Init004,Main__02		;Wobble-Part Main
	.word	Initscreen6,Main__06	;Vector-Bob Main
	.word	Init003,Main__02		;Wobble-Part Main
	.word	Initscreen5,Main__05	;Shade-Bob Main
	.word	Init001,Main__02		;Wobble-Part Main
	.word	Initscreen3,Main__03	;Sinus-Scroller Main
	.word	Init002,Main__02		;Wobble-Part Main
	.word	Initscreen,Main__01	;Vektor-Part Main
	.word	Initscreen4,Main__04	;End Part Main

VBR_Routines	.word	VBR__08,VBR__08		;Introduction V-Blank-Routine
	.word	VBR__07,VBR__07		;Landscape V-Blank-Routine
	.word	VBR__09,VBR__09		;Picture V-Blank-Routine
	.word	VBR__02,VBR__02		;Wobble-Part V-Blank-Routine
	.word	VBR__06,VBR__06		;Vector-Bob V-Blank-Routine
	.word	VBR__02,VBR__02		;Wobble-Part V-Blank-Routine
	.word	VBR__05,VBR__05		;Shade-Bob V-Blank-Routine
	.word	VBR__02,VBR__02		;Wobble-Part V-Blank-Routine
	.word	VBR__03,VBR__03		;Sinus-Scroller V-Blank-Routine
	.word	VBR__02,VBR__02		;Wobble-Part V-Blank-Routine
	.word	VBR__01,VBR__01		;Vektor-Part V-Blank-Routine
	.word	VBR__04,VBR__04		;End-Part V-Blank-Routine

;	*************************************************
;	***** MAIN (NON-VBR) Routines for Each Part *****
;	*************************************************

;	Main Routine for the Filled Vector Part.Calls Rot_Points,Draw_Objekt and
;	Fill (Buffer) .
;	Furthermore the Communication with the VBR is arranged with the Comm_Bit.
;FOLD_OUT
Main__01	lda	Comm_Bit
	bmi	.noBut
	jsr	Exec_Script
	jsr	Rot_Points			;Rotate Object Points
	jsr	Draw_Objekt			;Draw Object
	jsr	fill
	lda	Comm_Bit
	ora	#$80
	sta	Comm_Bit
	rep	#$20
	lda	<Dummy_Sin
	beq	.skip2
	clc
	adc	#$10
	sta	<Dummy_Sin
	sta	!OBuf_Dist
	cmp	#$370
	bcc	.exit
	lda	#$370
	sta	<Dummy_Sin
	sta	!OBuf_Dist
	lda	<Hundekuchen
	cmp	#$00ff
	bcc	.exit
	rep	#$10
	ldx	Act_Main				;Next part please
	inx
	inx
	stx	Act_Main
.exit	sep	#$20
	rts

.skip2	sep	#$20
.skip3	lda	REG_HVBJOY
	and	#$01
	bne	.skip3
	lda	REG_JOY1H
	and	#$80
	beq	.noBut
	lda	#$55
	sta	REG_APUIO1
	rep	#$10
	ldx	!OBuf_Dist
	stx	<Dummy_Sin
.noBut	rts
;FOLD_END
;	Main Routine for the Wobbleing-Part
;	Waits for a Button to be Pressed and does a Color-Fade-Out
;FOLD_OUT
Main__02	wai
.pad	lda	REG_HVBJOY
	and	#$01
	bne	.pad
	lda	<Comm_Bit			;Color Fade Out
	sta	REG_INIDISP
	rep	#$20
	lda	OBuf_RotZ
	beq	.cont3
	sep	#$20
	bpl	.noBut
.cont3	sep	#$20
	lda	<Comm_Bit
	cmp	#$0f
	beq	.cont
	pha
	and	#$70
	bne	.to70
	pla
	ora	#$70
	bra	.toStop
.to70	sec
	sbc	#$10
	bne	.cont2
	pla
	sec
	sbc	#$11
	bne	.toStop
	rep	#$10
	ldx	Act_Main			;next part
	inx
	inx
	stx	Act_Main
	bra	.toStop
.cont2	pla
	sec
	sbc	#$10
.toStop	sta	Comm_Bit
	rep	#$20
	dec	OBuf_RotZ
	dec	OBuf_RotZ
	sep	#$20
	bra	.noBut
.cont	lda	REG_JOY1H
	and	#$80
	beq	.noBut
	lda	#$0e
	sta	Comm_Bit
	lda	#$05			;Some Sound Effect!
	sta	REG_APUIO1
.noBut	rts
;FOLD_END
;	Main Routine for Sinus-Scroll Part
;	Just Waits for a Button to be pressed and changes to the Next Part
;FOLD_OUT
noBut	rts
Main__03	wai
.pad	lda	REG_HVBJOY
	and	#$01
	bne	.pad
	lda	REG_JOY1H
	and	#$80
	beq	noBut
	sep	#$20
	lda	#$60
	sta	REG_APUIO1
	lda	#$22
	sta	REG_W12SEL
	stz	REG_W34SEL
	lda	#$02
	sta	REG_WOBJSEL
	stz	REG_WBGLOG
	stz	REG_WOBJLOG
	lda	#$11
	sta	REG_TMW
	sta	REG_TSW
	lda	#$ff
	sta	REG_WH1
	ldx	#$0000
.loop1	lda	!Out_Sin,x
	sta	<Dummy_Sin
	inx
	inx
	cpx	#$080
	beq	.Next1
	wai
	bra	.loop1
.Next1	ldx	#$0000
.loop2	lda	!Out_Sin2,x
	sta	<Dummy_Sin
	inx
	inx
	cpx	#$100
	beq	.Next2
	wai
	bra	.loop2
.Next2	ldx	#$0000
.loop3	lda	!Out_Sin2,x
	clc
	ror	a
	sta	<Dummy_Sin
	inx
	inx
	cpx	#$100
	beq	.Next3
	wai
	bra	.loop3
.Next3	ldx	#$0000
.loop4	lda	!Out_Sin2,x
	clc
	ror	a
	clc
	ror	a
	sta	<Dummy_Sin
	inx
	inx
	cpx	#$100
	beq	.Next4
	wai
	bra	.loop4
.Next4	ldx	#$0000
.loop5	lda	!Out_Sin2,x
	clc
	ror	a
	clc
	ror	a
	clc
	ror	a
	sta	<Dummy_Sin
	inx
	inx
	cpx	#$100
	beq	.Next5
	wai
	bra	.loop5
.Next5	rep	#$10
	ldx	Act_Main
	inx
	inx
	stx	Act_Main
	rts
;FOLD_END
;	Main Routine for End Part
;	Changes Screen and HDMA-Table.
;FOLD_OUT
Main__04	wai
	lda	#$80
	sta	REG_INIDISP
	lda	#^End_Text
	pha
	plb
	rep	#$30
	ldx	L_Y1Pos
	lda	#$0a20+$20*12
	clc
	adc	L_Y2Pos
	sta	L_X2Pos
	sec
	sbc	#$20*12
.Put_Loop2	sta	REG_VMADDL		;Transfere Actual Page to VRAM
	pha
.Put_Loop1	lda	!End_Text,x
	and	#$00ff
	asl	a
	tay
	lda	!ASCIIEnd,y
	sta	REG_VMDATAL
	inx
	txa
	and	#$0f
	bne	.Put_Loop1
	pla
	clc
	adc	#$20
	cmp	L_X2Pos
	bne	.Put_Loop2

	sep	#$20
	rep	#$20
	lda	<Comm_Bit
	sta	REG_INIDISP
	ldy	#$0000
	lda	L_X1Pos
	clc
	adc	#$0008
	and	#$0ffe		;Indirect WAIT Delay ... Change for Longer One!
	sta	L_X1Pos
	cmp	#$7fe
	bcs	.skip4
.Put_Loop3	cmp	#$219		;Generate right HDMA-List for H-Offsets
	bcs	.skip1
	tax
	lda	#$0100
	bra	.skip6
.skip1	cmp	#$600
	bcc	.skip2
	lda	#$0600		
	tax
	lda	#$0000
	bra	.skip6
.skip2	tax
	lda	>sinus+1,x
	adc	#$80
	and 	#$00ff
.skip6	sta	!OBuf_Points+1+3*1,y
	txa
	clc
	adc	#$18
	and	#$7fe
	iny
	iny
	iny
	cpy	#$3*12
	bne	.Put_Loop3
.exit	lda	L_X1Pos		;Change Page?
	cmp	#$07f8
	bne	.skip3		;No -> Quit
	lda	L_Y2Pos
	eor	#$10
	sta	L_Y2Pos		;Change Actual Page
	bra	.skip4
.skip3	cmp	#$0000
	bne	.skip4
	lda	L_Y2Pos
	eor	#$10
	sta	L_Y2Pos		;Change Actual Page

	lda	L_Y1Pos
	clc
	adc	#$10*12
	cmp	#$10*12*6		;Max Number of Pages*$10*12
	bne	.skip5
	lda	#$0000
.skip5	sta	L_Y1Pos
.skip4	sep	#$20
	phk
	plb

.pad	lda	REG_HVBJOY
	and	#$01
	bne	.pad
	lda	REG_JOY1H
	and	#$f0
	beq	.noBut
	cmp	#$f0
	bne	.noBut
	lda	REG_JOY1L
	cmp	#$f0
	bne	.noBut
	lda	#$08
	sta	<Comm_Bit
	lda	#75		;Activate hidden part!
	sta	$7efffd
	lda	#97
	sta	$7efffe
	lda	#121
	sta	$7effff
	lda	#$5f
	sta	REG_APUIO1
.noBut	rts
;FOLD_END
;	Main Routine for Shade-Bob Part
;	Waits for the Button to be pressed.
;FOLD_OUT
Main__05	wai
	sep	#$20
	lda	<Dummy_Sin
	cmp	#$02
	bcc	.pad
	dec	a
	sta	<Dummy_Sin
	sta	REG_WH0
	eor	#$ff
	inc	a
	sta	REG_WH1
	rts
.pad	lda	REG_HVBJOY
	and	#$01
	bne	.pad
	stz	REG_TMW
	stz	REG_TSW
	lda	REG_JOY1H
	and	#$80
	beq	.noBut
	lda	#$12
	sta	REG_APUIO1
	lda	#$11
	sta	REG_TMW
	sta	REG_TSW
	lda	<Dummy_Sin
.loop	inc	a
	cmp	#$7f
	beq	.Next_Part
	sta	REG_WH0
	eor	#$ff
	inc	a
	sta	REG_WH1
	eor	#$ff
	inc	a
	wai
	bra	.loop
.Next_Part	rep	#$10
	ldx	Act_Main
	inx
	inx
	stx	Act_Main
.noBut	rts
;FOLD_END
;	Main Routine for the Vector-Bob Part
;	Rotates Bobs and Copies Coords to OAM-Mirror-Ram..
;FOLD_OUT

Main__06	wai
	rep	#$30
	lda	<Act_Object
	bmi	.Continue
	dec	a
	bpl	.Not_PartChange
	sep	#$20
	lda	#$0e
.fadeout	wai
	wai
	wai
	wai
	sta	REG_INIDISP
	dec	a
	bne	.fadeout
	ldx	<Act_Main
	inx
	inx
	stx	<Act_Main
	rts

.Not_PartChange	sta	<Act_Object
	sep	#$20
	sta	REG_BG2HOFS
	xba
	sta	REG_BG2HOFS
	xba
	rep	#$20
	eor	#$ffff
	inc	a
	sep	#$20
	sta	REG_BG3HOFS
	xba
	sta	REG_BG3HOFS
	rep	#$20
	bra	.Not_In

.Continue	sep	#$20
	lda	<Dummy_Sin
	cmp	#$70
	bne	.noBut
.pad	lda	REG_HVBJOY
	and	#$01
	bne	.pad
	lda	REG_JOY1H
	and	#$80
	beq	.noBut
	lda	#$11
	sta	REG_APUIO1
	rep	#$10
	ldx	#$70
	stx	<Act_Object

.noBut	rep	#$30
	lda	<Dummy_Sin
	cmp	#$0070
	beq	.Not_In
	inc	a
	sta	<Dummy_Sin
	sep	#$20
	sta	REG_BG2HOFS
	xba
	sta	REG_BG2HOFS
	xba
	rep	#$20
	eor	#$ffff
	inc	a
	sep	#$20
	sta	REG_BG3HOFS
	xba
	sta	REG_BG3HOFS
	rep	#$20
.Not_In
	jsr	.Script			;Do Script
	lda	#$00a0
	sta	!OBuf_Dist
	lda	!OBuf_Color
	inc	a
	inc	a
	sta	<Drw_PoiPoi		;Object Point Structure
	ldx	!OBuf_Color
	lda	!$0000,x
	sta	!OBuf_Points		;Number of Points to be rotated
	jsr	Rot_Points		;Rotate Object Points

	rep	#$30
	phk
	plb
	ldx	!OBuf_Color
	lda	!$0000,x
	sec
	sbc	!OBuf_Faces
	beq	.skip1
	tax
	ldy	#$0000
.PutLoop1	lda	!OBuf_RotPts-3,x		;Transfer Position of Used Bobs
	clc				;to OAM_Ram Mirror
	adc	#$e810
	sta	!OAM_Buffer,y
	iny
	iny
	iny
	iny
	dex
	dex
	dex
	bne	.PutLoop1

.skip1	lda	#$e000			;And "Clear" the Rest by Putting them
	ldx	!OBuf_Faces		;to Position $00,$e0
	cpx	#$0000
	beq	.skip2
.PutLoop2	sta	!OAM_Buffer,y
	iny
	iny
	iny
	iny
	dex
	dex
	dex
	bne	.PutLoop2
.skip2	lda	!OBuf_RotX		;Change X-Rotation Angle
	clc
	adc	<X_Add
	and	#$07fe
	sta	!OBuf_RotX
	lda	!OBuf_RotY		;Change Y-Rotation Angle
	clc
	adc	<Y_Add
	and	#$07fe
	sta	!OBuf_RotY
	lda	!OBuf_RotZ		;Change Z-Rotation Angle
	clc
	adc	<Z_Add
	and	#$07fe
	sta	!OBuf_RotZ
	sep	#$20
	rts

	Mode	A16X16

.Script	lda	<Script_Next
	beq	.Init
	bmi	.Increase_Visible
	cmp	#$0001
	beq	.Decrease_Visible
	dec	a
	sta	<Script_Next
	rts

.Decrease_Visible	dec	L_OraVal
	bne	.not3
	inc	L_OraVal
	inc	L_OraVal
	inc	L_OraVal
	lda	!OBuf_Faces	;Decrease Number of Visible Bobs by One
	clc
	adc	#$03
	ldx	!OBuf_Color
	cmp	!$0000,x
	bcc	.not1
	stz	<Script_Next
	sec
	sbc	#$03
.not1	sta	!OBuf_Faces
.not3	rts

.Increase_Visible	dec	L_OraVal
	bne	.not4
	inc	L_OraVal
	inc	L_OraVal
	inc	L_OraVal
	lda	!OBuf_Faces	;Increase Number of Visible Bobs by One
	sec
	sbc	#$03
	bne	.not2
	ldx	<Script_Poi
	lda	!Bob_Script-2,x	;Get Number of Frames this Obj. is shown.
	sta	<Script_Next
	lda	#$0000
.not2	sta	!OBuf_Faces
.not4	rts

.Init	dec	a
	sta	<Script_Next	;Negativ Value to Script_Next => .Increase_Visible
	ldx	<Script_Poi
	lda	!Bob_Script,x
	bne	.Not_Warp
	lda	#$0000
	sta	<Script_Poi
	bra	.Init
.Not_Warp	sta	!OBuf_Color	;New Object Structure
	lda	!Bob_Script+2,x
	sta	<X_Add		;New X_Add
	lda	!Bob_Script+4,x
	sta	<Y_Add		;New Y_Add
	lda	!Bob_Script+6,x
	sta	<Z_Add		;New Z_Add
	txa
	clc
	adc	#$0a		;Increase Script_Poi(nter)
	sta	<Script_Poi
	ldx	!OBuf_Color	;Number of Bobs to be Displayed = 0
	lda	!$0000,x
	sta	!OBuf_Faces
	lda	#$0003
	sta	L_OraVal
	rts

;	.word	!Object,X_Add,Y_Add,Z_Add,#Frames
Bob_Script	.word	Bob_Points1,$c,$8,-$c,$200
	.word	Bob_Points2,$6,$c,-$8,$200
	.word	Bob_Points3,$c,$4,-$c,$200
	.word	Bob_Points4,$e,$2,-$a,$200
	.word	0

;FOLD_END
;	Main Routine for the Landscape Part
;	Calls the Do_Landscape Routine and does the Movements.W8s for Button.
;FOLD_OUT
Main__07	sep	#$20
	rep	#$10
.w84trans	lda	<Comm_Bit
	bmi	.w84trans
	stz	<Comm_Bit

	jsl	>Do_Landscape	;Voxelspace sub routine (BIG!)
	phk
	plb
	sep	#$20
	lda	<Z_Add
	bne	.Go_Out
.pad	lda	REG_HVBJOY
	and	#$01
	bne	.pad
	ldx	<Act_Buffer
	cpx	#$0f00
	bne	.noBut
	lda	REG_JOY1H
	and	#$80
	beq	.noBut
	lda	#$59
	sta	REG_APUIO1
	rep	#$10
	lda	#$1f
	sta	<Z_Add
	bra	.noBut
.Go_Out	dec	a
	sta	<Z_Add
	bne	.skip
	ldx	Act_Main
	inx
	inx
	stx	Act_Main
.skip	rep	#$20
	lda	<Y_Add
	clc
	adc	#$10
	sta	<Y_Add
	sep	#$20
	sta	REG_M7A
	xba
	sta	REG_M7A
	xba
	sta	REG_M7D
	xba
	sta	REG_M7D	
.noBut	rep	#$20
	lda	L_DeltaX
	clc
	adc	#$180
	and	#$ff80
	sta	L_DeltaX
	sep	#$20
	inc	L_X2Pos		;New X_Pos
	inc	L_X2Pos+1
	inc	L_X2Pos		;New Y_Pos
	inc	L_X2Pos+1
	inc	L_X2Pos		;New X_Pos
	inc	L_X2Pos+1
	inc	L_X2Pos		;New Y_Pos
	inc	L_X2Pos+1
	rts

;FOLD_END
;	Main Routine for the Introduction.
;	Waits for VBR to Finish Work and Fades Screen Out ...
;FOLD_OUT
Main__08	wai
	lda	<Dummy_Sin
	beq	.skip
	sep	#$20
	rep	#$10
	ldx	#$0f
	lda	#$1f
.loop	sta	REG_MOSAIC
	wai
	wai
	wai
	wai
	clc
	adc	#$10
	dex
	bne	.loop
	ldx	Act_Main
	inx
	inx
	stx	Act_Main
.skip	rts
;FOLD_END
;	Main Routine for the Picture Part
;	Not yet Implanted ....
;FOLD_OUT
Main__09	wai
	rts
;FOLD_END
;		**************************************
;		************ Init Routines ***********
;		**************************************
;	Initregs	:  First Time Init All PPU Registers
;	Initscreen	:  Init for the Filled Vektor Part
;	Initscreen2	:  Init for the In-Between-Wobbling Part
;	Initscreen3	:  Init for the Sinus-Scroller Part
;	Initscreen4	:  Init for the End of the Demo Part0
;	Initscreen5	:  Init for the Shade Bob Part
;	Initscreen6	:  Init for the Vector-Bob Part
;	Initscreen7	:  Init for the Landscape Part
;	Initscreen8	:  Init for the Introduction
;	Initscreen9	:  Init for the Picture
;	Check_For_Hidden	:  Init for the Hidden Part


;	Useable Tunes: 1.. INTRO
;	Main Parts(Fast): 4(short),7(ok,Nice!),8(shot,fast,BASS!),9(ok)
;			a(fast,nice),b(well,ok),c+(GREAT!),e+(GREEEEAT!)
;			f(nice rock!),10+(good),11(ok,nice),12+(good)
;			13+(fast`n`nice,very good),14+(GREAAAAAT!)
;			15+(ok,rocky),16+(NICE!,short),17(Cool Beginning,rest ok)
;	End Part(Slow): 3+(nice),d+(FAST Game Over like Tune)
;	2,5,6 too short

;	Used Tunes: 
;			$14 Filled Vektor Part
;			$12,$13,$16,$15 for the in between Part
;			$0e for the Sinus Scroller
;			$03 for the End Part
;			$0c for the Shade Bob Part
;			$0d for the Landscape Part
;			$10 for the Vector Bob Part
;			$01 for the Introduction
;	Init Registers
;FOLD_OUT
Initregs	php				;FIRST Init for Everything inside PPU
	sep	#$20
	lda	#$8f			;Initialise Registers and clear V-Ram
	sta	INIDISP
	lda	#$80
	sta	VMAINC
	rep	#$30
	ldx	#$8000
	stz	VMADDL
.loop	stz	VMDATAL			;Clear VRAM
	dex
	bne	.loop
	ldx	#$0040
	lda	#$0000
.loop2	sta	$2b,x			;Clear ZERO-PAGE !!!!
	dex				;---------------------
	dex
	bpl	.loop2
	sep	#$20
	lda	#$30
	sta	CGSWSEL
	lda	#$e0
	sta	COLDATA
	lda	#$00
	sta	CGADSUB
	sta	MOSAIC
	sta	SETINI
	sta	W12SEL
	sta	W34SEL
	sta	WOBJSEL
	sta	WH0
	sta	WH1
	sta	WH2
	sta	WH3
	sta	WBGLOG
	sta	WOBJLOG
	sta	BG1HOFS
	sta	BG1HOFS
	sta	BG1VOFS
	sta	BG1VOFS
	sta	BG2HOFS
	sta	BG2HOFS
	sta	BG2VOFS
	sta	BG2VOFS
	sta	BG3HOFS
	sta	BG3HOFS
	sta	BG3VOFS
	sta	BG3VOFS
	sta	BG4HOFS
	sta	BG4HOFS
	sta	BG4VOFS
	sta	BG4VOFS
	sta	M7SEL
	sta	M7A
	sta	M7A
	sta	M7B
	sta	M7B
	sta	M7C
	sta	M7C
	sta	M7D
	sta	M7D
	sta	M7X
	sta	M7X
	sta	M7Y
	sta	M7Y
	plp
	rts
;FOLD_END
;	Init for Filled Vektor-Part
;FOLD_OUT
Initscreen	sei
	php
	rep	#$30
	sep	#$20
	lda	#$8f
	sta	REG_INIDISP
	stz	REG_MDMAEN
	stz	REG_HDMAEN

	ldx	#Packed_02&&$ffff
	stx	<in
	lda	#^Packed_02
	sta	<in+2
	ldx	#UnpackBuffr&&$ffff
	stx	<out
	lda	#^UnpackBuffr
	pha
	plb
	jsl	>UNPACK				;R=ires A[8] XY[16]
	phk
	plb
	sep	#$20
	lda	#$ff
	sta	REG_BG1HOFS
	stz	REG_BG1HOFS
	lda	#$b0
	sta	REG_BG1VOFS
	lda	#$00
	sta	REG_BG1VOFS
	stz	REG_BG3HOFS
	stz	REG_BG3HOFS
	stz	REG_BG3VOFS
	stz	REG_BG3VOFS
	lda	#$80
	sta	VMAINC
	wai
	rep	#$30
	lda	#$4000
	sta	REG_VMADDL
	ldx	#$0000
.Init_10	lda	>Logo1,x
	sta	REG_VMDATAL
	inx
	inx
	cpx	#12480
	bne	.Init_10

	ldx	#$0020
	stx	REG_VMADDL
	ldx	#$0000
	rep	#$20
.Init_01	lda	!Test_Screen,x		;Init 4-Col Screen
	ora	#$2000
	sta	REG_VMDATAL
	inx
	inx
	cpx	#1664
	bne	.Init_01


	lda	#$400
	sta	REG_VMADDL
	ldx	#00015
	lda	#$1c00
.Init_13	ldy	#00026
.Init_12	sta	REG_VMDATAL
	inc	a
	dey
	bne	.Init_12
	pha
	lda	#$1c04
	sta	REG_VMDATAL
	sta	REG_VMDATAL
	sta	REG_VMDATAL
	sta	REG_VMDATAL
	sta	REG_VMDATAL
	sta	REG_VMDATAL
	pla
	dex
	bne	.Init_13
	ldx	#32*(17+32)
	lda	#$1c04
.Init_14	sta	REG_VMDATAL
	dex
	bpl	.Init_14

	ldx	#$1540
	ldy	#$1000
	sty	REG_VMADDL
.Init_15	stz	REG_VMDATAL
	dex
	bpl	.Init_15

	ldx	#$0000
	lda	#$0000
.Init_02	sta	>OneBPL_Buf,x		;Clear One_Bitplane_Buffer
	inx
	inx
	cpx	#$6080
	bne	.Init_02
	lda	#OneBPL_Buf&&$ffff
	sta	Act_Buffer
	lda	#TwoBPL_Buf&&$ffff
	sta	Old_Buffer
	sep	#$20
	lda	#$09			;Screen-Mode 1 with Priority for Screen 3
	sta	REG_BGMODE
	lda	#$05
	sta	REG_BG1SC
	lda	#$00			;Screen 3 8x8 Tiles, List at $0000
	sta	REG_BG3SC
	lda	#$01			;Tiles For Screen 3 at $1000
	sta	REG_BG34NBA
	lda	#$04
	sta	REG_BG12NBA
	lda	#$01			;Only Screen 1 is on as MAIN Screen
	sta	REG_TM
	lda	#$04			;Screen 3 is Sub Screen
	sta	REG_TS
	lda	#$00
	sta	REG_DMAP1
	lda	#$21
	sta	REG_BBAD1
	ldx	#HDMAOne&&$ffff
	stx	REG_A1T1L
	lda	#^HDMAOne
	sta	REG_A1B1
	lda	#$02
	sta	REG_DMAP2
	lda	#$22
	sta	REG_BBAD2
	ldx	#HDMATwo&&$ffff
	stx	REG_A1T2L
	lda	#^HDMATwo
	sta	REG_A1B2
	lda	#$02
	sta	REG_DMAP3
	lda	#$22
	sta	REG_BBAD3
	ldx	#HDMAThree&&$ffff
	stx	REG_A1T3L
	lda	#^HDMAThree
	sta	REG_A1B3
	lda	#$02
	sta	REG_DMAP4
	lda	#$22
	sta	REG_BBAD4
	ldx	#HDMAFour&&$ffff
	stx	REG_A1T4L
	lda	#^HDMAFour
	sta	REG_A1B4

	lda	#$00
	sta	REG_DMAP5
	lda	#$00
	sta	REG_BBAD5
	ldx	#HDMASix&&$ffff
	stx	REG_A1T5L
	lda	#^HDMASix
	sta	REG_A1B5

	ldx	#$0000
	lda	#$70
	sta	REG_CGADD
.Init_11	lda	>Logo1Col,x
	sta	REG_CGDATA
	lda	>Logo1Col+1,x
	sta	REG_CGDATA
	inx
	inx
	cpx	#$20
	bne	.Init_11
	lda	#$02
	sta	CGSWSEL
	lda	#$e0
	sta	COLDATA
	lda	#$01
	sta	CGADSUB
	ldx	#$0026
	lda	#$00
.Init_09	sta	L_X2Pos,x		;Clear RAM for Vector Part
	sta	!Object_Buf,x
	dex
	bpl	.Init_09
	stz	Dummy_Sin
	stz	Dummy_Sin+1
	lda	#$01
	sta	<Comm_Bit
	lda	#$c8			;Vertical Timer IRQ at Line $0e8
	sta	REG_VTIMEL
	stz	REG_VTIMEH
	ldx	Act_Main
	inx
	inx
	stx	Act_Main
	rep	#$20
	lda	#$0014
	jsr	Play_Musik
	sep	#$20
	rep	#$10
	lda	#$0f
	sta	REG_INIDISP
	lda	#$ff
	xba
.VBlank	lda	REG_HVBJOY
	bpl	.VBlank
	xba
	sta	REG_BG1HOFS
	stz	REG_BG1HOFS
	dec	a
	beq	.Quit
	xba
.NVBlank	lda	REG_HVBJOY
	bmi	.NVBlank
	bra	.VBlank
.Quit	lda	#$3e
	sta	REG_HDMAEN
	plp
	cli
	rts
;FOLD_END
;	Init for Wobble-In-Between-Part
;FOLD_OUT

Init001	sei
	php
	sep	#$20
	rep	#$10
	lda	#$8f
	sta	REG_INIDISP
	stz	REG_HDMAEN
	ldx	#Texttech1&&$ffff
	stx	Drw_PoiPoi
	lda	#^Texttech1
	sta	Drw_PoiPoi+2
	rep	#$20
	lda	#$0016
	jsr	Play_Musik
	jmp	Initscreen2

Init002	sei
	php
	sep	#$20
	rep	#$10
	lda	#$8f
	sta	REG_INIDISP
	stz	REG_HDMAEN
	ldx	#Texttech2&&$ffff
	stx	Drw_PoiPoi
	lda	#^Texttech2
	sta	Drw_PoiPoi+2
	rep	#$20
	lda	#$0013
	jsr	Play_Musik
	jmp	Initscreen2

Init003	sei
	php
	sep	#$20
	rep	#$10
	lda	#$8f
	sta	REG_INIDISP
	stz	REG_HDMAEN
	ldx	#Texttech3&&$ffff
	stx	Drw_PoiPoi
	lda	#^Texttech1
	sta	Drw_PoiPoi+2
	rep	#$20
	lda	#$0012
	jsr	Play_Musik
	jmp	Initscreen2

Init004	sei
	php
	sep	#$20
	rep	#$10
	lda	#$8f
	sta	REG_INIDISP
	stz	REG_HDMAEN
	ldx	#Texttech4&&$ffff
	stx	Drw_PoiPoi
	lda	#^Texttech1
	sta	Drw_PoiPoi+2
	rep	#$20
	lda	#$0015
	jsr	Play_Musik
	jmp	Initscreen2

Initscreen2	sep	#$20
	lda	#$8f
	sta	REG_INIDISP
	lda	#$00
	sta	REG_HDMAEN
	sta	REG_MDMAEN
	sta	W12SEL
	sta	W34SEL
	sta	WOBJSEL
	sta	WH0
	sta	WH1
	sta	WH2
	sta	WH3
	sta	WBGLOG
	sta	WOBJLOG
	sta	REG_TMW
	sta	REG_TSW

	ldx	#DreiekSourc&&$ffff
	stx	<in
	lda	#^DreiekSourc
	sta	<in+2
	ldx	#UnpackBuffr&&$ffff
	stx	<out
	lda	#^UnpackBuffr
	pha
	plb
	jsl	>UNPACK				;R=ires A[8] XY[16]
	phk
	plb


	sep	#$20
	lda	#$80
	sta	VMAINC
	rep	#$30
	ldx	#$0000
	stz	REG_VMADDL
@clearVRam:
	stz	REG_VMDATAL
	dex
	bne	@clearVRam

	ldx	#$0000
	lda	#$3000
	sta	REG_VMADDL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
@Init_03:
	lda	>Dreieck1+32,x
	sta	REG_VMDATAL
	inx
	inx
	cpx	#$2200
	bne	@Init_03
	ldx	#$0000
	lda	#$4000
	sta	REG_VMADDL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
@Init_04:
	lda	>Dreieck2+32,x
	sta	REG_VMDATAL
	inx
	inx
	cpx	#$2200
	bne	@Init_04
	ldx	#$0000
	lda	#$2c00
	sta	REG_VMADDL
@Init_05:
	lda	>DreieckScr,x
	ora	#$0400
	sta	REG_VMDATAL
	inx
	inx
	cpx	#$40*15
	bne	@Init_05
	ldx	#$0000
	lda	#$5000
	sta	REG_VMADDL
@Init_07:
	lda	>DreieckScr,x
	ora	#$0800
	sta	REG_VMDATAL
	inx
	inx
	cpx	#$40*15
	bne	@Init_07

	ldx	#$1000
	stx	REG_VMADDL
	ldx	#$0000
@Init_02:
	lda	>SmChar,x
	sta	REG_VMDATAL
	inx
	inx
	cpx	#1280
	bne	@Init_02

	ldx	#$0000
	ldy	#$0000
	sty	REG_VMADDL
@Init_10:
	ldy	#$0020
@Init_00:
	sep	#$21
	phy
	txy
	lda	[Drw_PoiPoi],y	
	ply
	rep	#$20
	and	#$00ff
	phx
	tax
	sep	#$20
	lda	>ASCIISmall,x
	plx
	rep	#$20
	and	#$00ff
	ora	#$2000
	sta	REG_VMDATAL
	inx
	dey
	bne	@Init_00
	txa
	sec
	sbc	#$20
	tax
	ldy	#$20
@Init_09:
	sep	#$21
	phy
	txy
	lda	[Drw_PoiPoi],y	
	ply
	rep	#$21
	and	#$00ff
	phx
	tax
	sep	#$20
	lda	>ASCIISmall,x
	adc	#40
	plx
	rep	#$20
	and	#$00ff
	ora	#$2000
	sta	REG_VMDATAL
	inx
	dey
	bne	@Init_09
	cpx	#$20*14
	bne	@Init_10

	ldx	#$400*3+$20*4
	lda	#39
@Init_11:
	sta	REG_VMDATAL
	dex
	bne	@Init_11

	sep	#$20
	lda	#$02
	sta	REG_DMAP5
	lda	#$10
	sta	REG_BBAD5
	ldx	#HDMAFive&&$ffff
	stx	REG_A1T5L
	lda	#^HDMAFive
	sta	REG_A1B5
	lda	#$02
	sta	REG_DMAP6
	lda	#$0e
	sta	REG_BBAD6
	ldx	#HDMAFive&&$ffff
	stx	REG_A1T6L
	lda	#^HDMAFive
	sta	REG_A1B6

	lda	#$09			;Screen-Mode 1 with Priority for Screen 3
	sta	REG_BGMODE
	lda	#$34
	sta	REG_BG12NBA
	lda	#$01
	sta	REG_BG34NBA
	lda	#$06			;Only Screen 2&3 are on as MAIN Screens
	sta	REG_TM
	lda	#$01			;BG 1 Sub Screen
	sta	REG_TS
	lda	#$2c
	sta	REG_BG2SC
	lda	#$03
	sta	REG_BG3SC
	lda	#$50
	sta	REG_BG1SC
	lda	#$02			;Fixed ColorAddition with
	sta	REG_CGSWSEL			;BG1,3 as Main Screens
	lda	#$06			;BG2 as Sub Screen (added to BG1)
	sta	REG_CGADSUB
	stz	REG_BG1HOFS
	stz	REG_BG1HOFS
	stz	REG_BG2HOFS
	stz	REG_BG2HOFS
	lda	#$01
	ldx	#$0000
.Init_08	sta	!HDMAFive,x
	stz	!HDMAFive+2,x
	inx
	inx
	inx
	cpx	#224*3
	bne	.Init_08
	stz	!HDMAFive,x
	stz	!HDMAFive+1,x
	stz	!HDMAFive+2,x


	stz	REG_CGADD
	ldx	#$0000
.Init_01	lda	>SmCols,x
	sta	REG_CGDATA
	inx
	cpx	#$08
	bne	.Init_01
	lda	#$10
	sta	REG_CGADD
	ldx	#$0000
.Init_06	rep	#$20
	lda	>DreieckCols,x		;Colors are to Bright ,SHIT!!!!
	and	#$7bde
	clc
	ror	a			;Fix it!
	rep	#$20
	sta	REG_CGDATA
	xba
	sta	REG_CGDATA
	inx
	inx
	cpx	#$40
	bne	.Init_06
	lda	#$60
	sta	REG_HDMAEN
	lda	#$0f
	sta	Comm_Bit			;Init for Color Fade Out
	lda	#$e8			;Vertical Timer IRQ at Line $0e8
	sta	REG_VTIMEL
	stz	REG_VTIMEH
	ldx	#$0000
	stx	Script_Next			;Ready to start Script
	stx	Script_Poi			;Script Pointer to first entry
	ldx	Act_Main
	inx
	inx
	stx	Act_Main
	ldx	#$1c0
	stx	OBuf_RotZ
	plp
	cli
	rts
;FOLD_END
;	Init for Sinus-Scroller-Part
;FOLD_OUT

LogoYPos	Set	$88
LogoXPos	Set	$00

Initscreen3	sei
	php
	rep	#$30
	sep	#$20
	lda	#$8f
	sta	REG_INIDISP
	stz	REG_HDMAEN
	stz	REG_MDMAEN

	ldx	#Packed_03&&$ffff
	stx	<in
	lda	#^Packed_03
	sta	<in+2
	ldx	#UnpackBuffr&&$ffff
	stx	<out
	lda	#^UnpackBuffr
	pha
	plb
	jsl	>UNPACK				;R=ires A[8] XY[16]
	phk
	plb
	sep	#$20
	stz	REG_CGADD
	lda	#$00
	sta	REG_DMAP5
	lda	#$22
	sta	REG_BBAD5
	ldx	#Mode7Cols&&$ffff
	stx	REG_A1T5L
	lda	#^Mode7Cols
	sta	REG_A1B5
	lda	#$80
	sta	REG_DAS5L
	stz	REG_DAS5H
	lda	#$20
	sta	REG_MDMAEN
	stz	REG_VMAIN
	rep	#$20
	ldx	#$4000
	ldy	#$0000
	sty	REG_VMADDL
.Init_17	sty	REG_VMDATAL
	dex
	bne	.Init_17
	ldx	#$0000
	ldy	#$400
	sty	REG_VMADDL
.Init_14	lda	>Mode7Scr,x
	sta	REG_VMDATAL
	stz	REG_VMDATAH
	inx
	cpx	#$200
	bne	.Init_14
	ldx	#$0000
	lda	#$00
.Init_16	sta	$1000,x
	inx
	cpx	#$1000
	bne	.Init_16
	lda	#$80
	sta	REG_VMAIN

	rep	#$20
	ldx	#$4000
	stx	REG_VMADDL
	ldx	#$0000
.Init_18	lda	>Mode7Logo,x
	sta	REG_VMDATAL
	inx
	inx
	cpx	#$4000
	bne	.Init_18
	sep	#$20

	lda	#$f0
	sta	REG_CGADD
	ldx	#$0000
.Init_19	lda	>Mode7LogoCols,x
	sta	REG_CGDATA
	inx
	cpx	#$20
	bne	.Init_19

	ldx	Act_Main
	inx
	inx
	stx	Act_Main
	lda	#$07
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
	lda	#$01
	stz	REG_M7A
	sta	REG_M7A
	stz	REG_M7B
	stz	REG_M7B
	stz	REG_M7C
	stz	REG_M7C
	stz	REG_M7D
	sta	REG_M7D
	lda	#$80
	sta	REG_M7X
	stz	REG_M7X
	lda	#$50
	sta	REG_M7Y
	stz	REG_M7Y
	lda	#$01
	sta	REG_TM
	lda	#$10
	sta	REG_TS
	stz	Dummy_Sin		;Fade Out Dummy
	stz	L_X2Pos
	stz	L_X2Pos+1
	stz	L_Y2Pos
	stz	L_Y2Pos+1
	stz	L_X1Pos
	stz	L_X1Pos+1
	stz	L_Y1Pos
	stz	L_Y1Pos+1
	stz	L_Incr1		;Effect
	stz	L_Incr1+1
	stz	L_Incr2		;Angle
	stz	L_Incr2+1
	stz	L_Dummy		;Size
	lda	#$02
	sta	L_Dummy+1
	stz	L_OraVal
	stz	L_OraVal+1	;Effect_Dummy
	lda	#$42			;Initialize OAMs For The Logo!
	sta	REG_OBSEL
	stz	REG_OAMADDL
	stz	REG_OAMADDH
	ldx	#$80
	lda	#$e0
.initloop1	stz	REG_OAMDATA
	sta	REG_OAMDATA
	stz	REG_OAMDATA
	stz	REG_OAMDATA
	dex
	bne	.initloop1
.initloop2	stz	REG_OAMDATA
	inx
	cpx	#$20
	bne	.initloop2
	stz	REG_OAMADDL
	stz	REG_OAMADDH
	lda	#LogoXPos
	sta	REG_OAMDATA
	lda	#LogoYPos
	sta	REG_OAMDATA
	lda	#$00
	sta	REG_OAMDATA
	lda	#$0e
	sta	REG_OAMDATA
	lda	#LogoXPos+$40
	sta	REG_OAMDATA
	lda	#LogoYPos
	sta	REG_OAMDATA
	lda	#$08
	sta	REG_OAMDATA
	lda	#$0e
	sta	REG_OAMDATA
	lda	#LogoXPos+$80
	sta	REG_OAMDATA
	lda	#LogoYPos
	sta	REG_OAMDATA
	lda	#$80
	sta	REG_OAMDATA
	lda	#$0e
	sta	REG_OAMDATA
	lda	#LogoXPos+$c0
	sta	REG_OAMDATA
	lda	#LogoYPos
	sta	REG_OAMDATA
	lda	#$88
	sta	REG_OAMDATA
	lda	#$0e
	sta	REG_OAMDATA
	lda	#LogoXPos
	sta	REG_OAMDATA
	lda	#LogoYPos+$40
	sta	REG_OAMDATA
	lda	#$00
	sta	REG_OAMDATA
	lda	#$0f
	sta	REG_OAMDATA
	lda	#LogoXPos+$40
	sta	REG_OAMDATA
	lda	#LogoYPos+$40
	sta	REG_OAMDATA
	lda	#$08
	sta	REG_OAMDATA
	lda	#$0f
	sta	REG_OAMDATA
	lda	#LogoXPos+$80
	sta	REG_OAMDATA
	lda	#LogoYPos+$40
	sta	REG_OAMDATA
	lda	#$80
	sta	REG_OAMDATA
	lda	#$0f
	sta	REG_OAMDATA
	lda	#LogoXPos+$c0
	sta	REG_OAMDATA
	lda	#LogoYPos+$40
	sta	REG_OAMDATA
	lda	#$88
	sta	REG_OAMDATA
	lda	#$0f
	sta	REG_OAMDATA
	lda	#$10
	sta	REG_OAMADDL
	lda	#$01
	sta	REG_OAMADDH
	lda	#$aa
	sta	REG_OAMDATA
	sta	REG_OAMDATA
	lda	#$02
	sta	REG_CGSWSEL
	lda	#$61
	sta	REG_CGADSUB
	jsr	makesintab
	jsr	makesintab
	sep	#$20
	rep	#$10
	lda	#$81			;Vertical Timer IRQ at Line $0e8
	sta	REG_VTIMEL
	stz	REG_VTIMEH
	lda	#$00
	sta	REG_DMAP0
	sta	REG_BBAD0
	ldx	#HDMASeven&&$ffff
	stx	REG_A1T0L
	lda	#^HDMASeven
	sta	REG_A1B0

	lda	#$00
	sta	REG_DMAP1
	lda	#$2d
	sta	REG_BBAD1
	ldx	#HDMASeven1&&$ffff
	stx	REG_A1T1L
	lda	#^HDMASeven1
	sta	REG_A1B1

	rep	#$20
	lda	#$000e
	jsr	Play_Musik
	sep	#$20
	lda	#$03
	sta	REG_HDMAEN
	stz	REG_MDMAEN
	plp

	lda	#$88
	xba
.Scroll_In	lda	REG_HVBJOY
	bpl	.Scroll_In	
	stz	REG_OAMADDL
	stz	REG_OAMADDH
	lda	#LogoXPos
	sta	REG_OAMDATA
	xba
	sta	REG_OAMDATA
	xba
	lda	#$00
	sta	REG_OAMDATA
	lda	#$0e
	sta	REG_OAMDATA
	lda	#LogoXPos+$40
	sta	REG_OAMDATA
	xba
	sta	REG_OAMDATA
	xba
	lda	#$08
	sta	REG_OAMDATA
	lda	#$0e
	sta	REG_OAMDATA
	lda	#LogoXPos+$80
	sta	REG_OAMDATA
	xba
	sta	REG_OAMDATA
	xba
	lda	#$80
	sta	REG_OAMDATA
	lda	#$0e
	sta	REG_OAMDATA
	lda	#LogoXPos+$c0
	sta	REG_OAMDATA
	xba
	sta	REG_OAMDATA
	xba
	lda	#$88
	sta	REG_OAMDATA
	lda	#$0e
	sta	REG_OAMDATA
	lda	#LogoXPos
	sta	REG_OAMDATA
	xba
	clc
	adc	#$40
	sta	REG_OAMDATA
	xba
	lda	#$00
	sta	REG_OAMDATA
	lda	#$0f
	sta	REG_OAMDATA
	lda	#LogoXPos+$40
	sta	REG_OAMDATA
	xba
	sta	REG_OAMDATA
	xba
	lda	#$08
	sta	REG_OAMDATA
	lda	#$0f
	sta	REG_OAMDATA
	lda	#LogoXPos+$80
	sta	REG_OAMDATA
	xba
	sta	REG_OAMDATA
	xba
	lda	#$80
	sta	REG_OAMDATA
	lda	#$0f
	sta	REG_OAMDATA
	lda	#LogoXPos+$c0
	sta	REG_OAMDATA
	xba
	sta	REG_OAMDATA
	sec
	sbc	#$40
	xba
	lda	#$88
	sta	REG_OAMDATA
	lda	#$0f
	sta	REG_OAMDATA
	xba
	dec	a
	cmp	#$27
	beq	.Quit
	xba
.Not_VBlanc	lda	REG_HVBJOY
	bmi	.Not_VBlanc
	jmp	.Scroll_In
.Quit	cli
	rts
;FOLD_END
;	Init for End Part
;FOLD_OUT
Initscreen4	sei
	php
	rep	#$30
	sep	#$20
	lda	#$8f
	sta	REG_INIDISP
	stz	REG_HDMAEN
	stz	REG_MDMAEN
	stz	REG_CGADD
	lda	#$00
	sta	REG_DMAP5
	lda	#$22
	sta	REG_BBAD5
	ldx	#EndPic_Cols&&$ffff
	stx	REG_A1T5L
	lda	#^EndPic_Cols
	sta	REG_A1B5
	lda	#$02
	stz	REG_DAS5L
	sta	REG_DAS5H
	lda	#$20			;Transfer Colors for 256 Colors Picture
	sta	REG_MDMAEN
	lda	#$80
	sta	REG_VMAIN
	rep	#$20
	ldx	#$2000
	stx	REG_VMADDL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	ldx	#$0000
.Init_01	lda	>EndPic,x			;Transfer 256 Colors Picture Tiles
	sta	REG_VMDATAL
	inx
	inx
	cpx	#$8000
	bne	.Init_01
	ldx	#$0000
.Init_02	lda	>EndPic+$10000,x
	sta	REG_VMDATAL
	inx
	inx
	cpx	#53760-$8000
	bne	.Init_02
	sep	#$20
	ldx	#$0c00
	stx	REG_VMADDL
	ldx	#$0000
	ldy	#$0000
	rep	#$20
	lda	#$0001	
.Init_03	ldy	#0030			;Init Screen for 256 Colors Picture
	stz	REG_VMDATAL
.Init_04	sta	REG_VMDATAL
	inc	a
	dey
	bne	.Init_04
	stz	REG_VMDATAL
	inx
	cpx	#224/8
	bne	.Init_03
	rep	#$20
	ldx	#$1000
	stx	REG_VMADDL
	ldx	#$0000
.Init_05	lda	>EndPic_Char,x		;Transfer 16 Colors Char
	sta	REG_VMDATAL
	inx
	inx
	cpx	#$2000
	bne	.Init_05


	ldx	#$0a00			;Init Screen for 16 Color Char
	stx	REG_VMADDL
	lda	#$18ee
.Init_06	sta	REG_VMDATAL
	inx
	cpx	#$0c00
	bne	.Init_06

	sep	#$20
	lda	#$0c
	sta	REG_BG1SC
	lda	#$08
	sta	REG_BG2SC
	lda	#$12
	sta	REG_BG12NBA
	lda	#$23
	sta	REG_BGMODE
	lda	#$01
	sta	REG_TM
	lda	#$02
	sta	REG_TS
	lda	#$f8
	sta	REG_BG1HOFS
	lda	#$ff
	sta	REG_BG1HOFS
	stz	REG_BG1VOFS
	stz	REG_BG1VOFS
	stz	REG_BG2HOFS
	stz	REG_BG2HOFS
	lda	#$01
	stz	REG_BG2VOFS
	sta	REG_BG2VOFS
	rep	#$20
	lda	#$0003
	jsr	Play_Musik
	sep	#$20

	lda	#$02
	sta	CGSWSEL
	lda	#$e0
	sta	COLDATA
	lda	#$21
	sta	CGADSUB

	ldx	#$0000			;Init HDMA for h-Offset Changeing every 16
	lda	#$10			;Lines.. HDMA List at OBuf_Points ($7e0800)
.Init_07	sta	!OBuf_Points,x
	stz	!OBuf_Points+1,x
	stz	!OBuf_Points+2,x
	inx
	inx
	inx
	cpx	#$3*14
	bne	.Init_07
	stz	!OBuf_Points,x
	stz	!OBuf_Points+1,x
	stz	!OBuf_Points+2,x
	lda	#$0f
	sta	!OBuf_Points

	lda	#$6f
	sta	>TwoBPL_Buf
	sta	>TwoBPL_Buf+6
	lda	#$00
	sta	>TwoBPL_Buf+1
	sta	>TwoBPL_Buf+7
	sta	>TwoBPL_Buf+8
	sta	>TwoBPL_Buf+9
	lda	#$01
	sta	>TwoBPL_Buf+2
	sta	>TwoBPL_Buf+4
	lda	#$0f
	sta	>TwoBPL_Buf+3
	sta	>TwoBPL_Buf+5

	lda	#$02
	sta	REG_DMAP0
	lda	#$0f			;H-Offset for Screen 2 (Sub Screen)
	sta	REG_BBAD0
	ldx	#OBuf_Points&&$ffff
	stx	REG_A1T0L
	lda	#^OBuf_Points
	sta	REG_A1B0
	lda	#$00
	sta	REG_DMAP1
	sta	REG_BBAD1
	ldx	#TwoBPL_Buf&&$ffff
	stx	REG_A1T1L
	lda	#^TwoBPL_Buf
	sta	REG_A1B1
	lda	#$03
	sta	REG_HDMAEN			;Start HDMA Channel One
	ldx	#$0000
	stx	L_Y2Pos			;#of Page to be done ($0000=1,$0010=2)
	ldx	#$0000
	stx	L_X2Pos			;Init Registers for HDMA Movement
	stx	L_X1Pos
	stx	L_Y1Pos
	ldx	Act_Main
	inx
	inx
	stx	Act_Main
	lda	#$0f
	sta	<Comm_Bit
	lda	#$de			;Vertical Timer IRQ at Line $0e8
	sta	REG_VTIMEL
	stz	REG_VTIMEH
	lda	#$33
	sta	REG_W12SEL
	stz	REG_W34SEL
	stz	REG_WBGLOG
	stz	REG_WOBJLOG
	lda	#$13
	sta	REG_TMW
	sta	REG_TSW
	lda	#$80
	sta	REG_WH1
	sta	REG_WH0
	xba
.w81	lda	REG_HVBJOY
	bpl	.w81
.w82	lda	REG_HVBJOY
	bmi	.w82
	lda	>TwoBPL_Buf
	cmp	#$01
	beq	.Finished
	dec	a
	sta	>TwoBPL_Buf
	sta	>TwoBPL_Buf+6
	lda	>TwoBPL_Buf+2
	inc	a
	sta	>TwoBPL_Buf+2
	sta	>TwoBPL_Buf+4
.Finished	xba
	dec	a
	beq	.Quit
	sta	REG_WH0
	eor	#$ff
	inc	a
	sta	REG_WH1
	eor	#$ff
	inc	a
	xba
	bra	.w81
.Quit	stz	REG_W12SEL
	stz	REG_W34SEL
	stz	REG_WOBJSEL
	stz	REG_WH0
	stz	REG_WH1
	stz	REG_WH2
	stz	REG_WH3
	stz	REG_TMW
	stz	REG_TSW
	lda	#$01
	sta	REG_HDMAEN
	lda	#$0f
	sta	REG_INIDISP
	plp
	cli
	rts
;FOLD_END
;	Init for Shade-Bobs Part
;FOLD_OUT
LogoYPos	Set	$94
LogoXPos	Set	$04

Initscreen5	sei
	php
	sep	#$20
	rep	#$10
	stz	REG_HDMAEN
	lda	#$8f
	sta	REG_INIDISP
	ldx	#Packed_04&&$ffff
	stx	<in
	lda	#^Packed_04
	sta	<in+2
	ldx	#UnpackBuffr&&$ffff
	stx	<out
	lda	#^UnpackBuffr
	pha
	plb
	jsl	>UNPACK				;R=ires A[8] XY[16]
	phk
	plb
	sep	#$20
	rep	#$10
	wai
	lda	#$07
	sta	REG_BGMODE
	ldx	#$0000
	txy
	stx	REG_VMADDL
.Init_00	sty	REG_VMDATAL
	inx
	bpl	.Init_00
	stz	REG_CGADD
	ldx	#$0000
.Init_01	lda	>Colors,x			;Init Colors
	sta	REG_CGDATA
	inx
	cpx	#$100
	bne	.Init_01
	lda	#$e0
	sta	REG_CGADD
	ldx	#$0000
.Init_06	lda	>Logo_Colors,x
	sta	REG_CGDATA
	inx
	cpx	#$40
	bne	.Init_06

	lda	#$80
	sta	REG_VMAIN
	rep	#$30
	ldx	#$0000
	lda	#$4000
	sta	REG_VMADDL
.Init_05	lda	>Logo,x			;Copy Logo to VRAM Location $4000
	sta	REG_VMDATAL
	inx
	inx
	cpx	#8192
	bne	.Init_05
	sep	#$20

	ldx	#$8000
	lda	#$00
.Init_02	sta	>$7f0000,x		;Init Ram Buffer
	dex
	bpl	.Init_02

	lda	#$00
	sta	REG_VMAIN
	ldx	#$0000
	stx	REG_VMADDL			;Init Mode 7 Screen
.Init_03	ldy	#$0080
.Init_04	sta	REG_VMDATAL
	clc
	adc	#$10
	dey
	bne	.Init_04
	inc	a
	and	#$0f
	bne	.Init_03
	inx
	cpx	#$08
	bne	.Init_03



	lda	#$80
	sta	REG_VMAIN
	rep	#$20
	lda	#$5000
	sta	REG_VMADDL
	ldx	#$0000
.Init_07	lda	>EndPic_Char,x		;Copy Char to $5000
	sta	REG_VMDATAL
	inx
	inx
	cpx	#8192
	bne	.Init_07
	lda	#$7800
	sta	REG_VMADDL
	ldx	#$0000
	lda	#$18ee
.Init_08	sta	REG_VMDATAL			;Init Screen for the Char
	inx
	cpx	#$800
	bne	.Init_08

	sep	#$20
	lda	#$11
	sta	REG_TM
	lda	#$11
	sta	REG_TS
	lda	#$00
	sta	REG_CGSWSEL
	lda	#$00
	sta	REG_CGADSUB

	lda	#$05			;Char for Hires Scroller at $5000-$6000
	sta	REG_BG12NBA
	lda	#$79			;Screen For Hires-Scroller at $7800-$8000
	sta	REG_BG1SC
	lda	#$01			;Init Mode 7 Registers
	stz	REG_M7A
	sta	REG_M7A
	stz	REG_M7B
	stz	REG_M7B
	stz	REG_M7C
	stz	REG_M7C
	stz	REG_M7D
	sta	REG_M7D
	stz	REG_BG2HOFS
	stz	REG_BG2HOFS
	stz	REG_BG2VOFS
	stz	REG_BG2VOFS

	lda	#$40
	sta	REG_BG1HOFS
	stz	REG_BG1HOFS
	lda	#$c0
	sta	REG_M7X
	stz	REG_M7X

	lda	#$80
	sta	REG_BG1VOFS
	stz	REG_BG1VOFS
	lda	#$c0
	sta	REG_M7Y
	stz	REG_M7Y

	lda	#$22
	sta	REG_OBSEL
	stz	REG_OAMADDL
	stz	REG_OAMADDH
	ldx	#$80
	lda	#$e0
.initloop1	stz	REG_OAMDATA			;Init OAM Ram
	sta	REG_OAMDATA
	stz	REG_OAMDATA
	stz	REG_OAMDATA
	dex
	bne	.initloop1
.initloop2	stz	REG_OAMDATA
	inx
	cpx	#$20
	bne	.initloop2

	stz	REG_OAMADDL
	stz	REG_OAMADDH

	lda	#LogoXPos			;Create Sprite List for the Logo
	sta	REG_OAMDATA
	lda	#LogoYPos
	sta	REG_OAMDATA
	lda	#$00
	sta	REG_OAMDATA
	lda	#$3c
	sta	REG_OAMDATA

	lda	#LogoXPos+$20
	sta	REG_OAMDATA
	lda	#LogoYPos
	sta	REG_OAMDATA
	lda	#$04
	sta	REG_OAMDATA
	lda	#$3c
	sta	REG_OAMDATA

	lda	#LogoXPos
	sta	REG_OAMDATA
	lda	#LogoYPos+$20
	sta	REG_OAMDATA
	lda	#$40
	sta	REG_OAMDATA
	lda	#$3c
	sta	REG_OAMDATA

	lda	#LogoXPos+$20
	sta	REG_OAMDATA
	lda	#LogoYPos+$20
	sta	REG_OAMDATA
	lda	#$44
	sta	REG_OAMDATA
	lda	#$3c
	sta	REG_OAMDATA

	lda	#LogoXPos+$40
	sta	REG_OAMDATA
	lda	#LogoYPos
	sta	REG_OAMDATA
	lda	#$08
	sta	REG_OAMDATA
	lda	#$3c
	sta	REG_OAMDATA

	lda	#LogoXPos+$40
	sta	REG_OAMDATA
	lda	#LogoYPos+$20
	sta	REG_OAMDATA
	lda	#$48
	sta	REG_OAMDATA
	lda	#$3c
	sta	REG_OAMDATA

	lda	#LogoXPos+$60
	sta	REG_OAMDATA
	lda	#LogoYPos
	sta	REG_OAMDATA
	lda	#$0c
	sta	REG_OAMDATA
	lda	#$3e
	sta	REG_OAMDATA

	lda	#LogoXPos+$60
	sta	REG_OAMDATA
	lda	#LogoYPos+$20
	sta	REG_OAMDATA
	lda	#$4c
	sta	REG_OAMDATA
	lda	#$3e
	sta	REG_OAMDATA

	lda	#LogoXPos+$80
	sta	REG_OAMDATA
	lda	#LogoYPos
	sta	REG_OAMDATA
	lda	#$80
	sta	REG_OAMDATA
	lda	#$3e
	sta	REG_OAMDATA

	lda	#LogoXPos+$a0
	sta	REG_OAMDATA
	lda	#LogoYPos
	sta	REG_OAMDATA
	lda	#$84
	sta	REG_OAMDATA
	lda	#$3e
	sta	REG_OAMDATA

	lda	#LogoXPos+$80
	sta	REG_OAMDATA
	lda	#LogoYPos+$20
	sta	REG_OAMDATA
	lda	#$c0
	sta	REG_OAMDATA
	lda	#$3e
	sta	REG_OAMDATA

	lda	#LogoXPos+$a0
	sta	REG_OAMDATA
	lda	#LogoYPos+$20
	sta	REG_OAMDATA
	lda	#$c4
	sta	REG_OAMDATA
	lda	#$3e
	sta	REG_OAMDATA

	lda	#LogoXPos+$c0
	sta	REG_OAMDATA
	lda	#LogoYPos
	sta	REG_OAMDATA
	lda	#$88
	sta	REG_OAMDATA
	lda	#$3e
	sta	REG_OAMDATA

	lda	#LogoXPos+$e0
	sta	REG_OAMDATA
	lda	#LogoYPos
	sta	REG_OAMDATA
	lda	#$8c
	sta	REG_OAMDATA
	lda	#$3e
	sta	REG_OAMDATA

	lda	#LogoXPos+$c0
	sta	REG_OAMDATA
	lda	#LogoYPos+$20
	sta	REG_OAMDATA
	lda	#$c8
	sta	REG_OAMDATA
	lda	#$3e
	sta	REG_OAMDATA

	lda	#LogoXPos+$e0
	sta	REG_OAMDATA
	lda	#LogoYPos+$20
	sta	REG_OAMDATA
	lda	#$cc
	sta	REG_OAMDATA
	lda	#$3e
	sta	REG_OAMDATA

	lda	#$00
	sta	REG_OAMADDL
	lda	#$01
	sta	REG_OAMADDH
	lda	#$aa
	sta	REG_OAMDATA
	sta	REG_OAMDATA
	sta	REG_OAMDATA
	sta	REG_OAMDATA

	ldx	#$0000
	stx	L_X2Pos
	stx	L_Y2Pos
	stx	L_X1Pos
	stx	L_Y1Pos
	stx	L_DeltaX
	stx	L_DeltaY
	stx	L_Incr1
	stx	L_Incr2
	stx	L_Dummy
	stx	Drw_PoiPoi	;Frames to go Counter
	stx	Drw_Dummy		;Scroll Offset Counter
	stx	Drw_Dummy+2	;Text Offset
	stx	Drw_Dummy+6	;Pointer for Routine Effect Handler
	stx	Drw_Dummy+8	;Dummy for Clear Routine
	stx	L_OraVal		;Scipt Counter
	ldx	#$7ea2
	stx	Drw_Dummy+4	;Offset to put Char at.
	ldx	Act_Main
	inx
	inx
	stx	Act_Main

	stz	REG_DMAP0
	lda	#$05
	sta	REG_BBAD0
	ldx	#HDMAFive1&&$ffff
	stx	REG_A1T0L
	lda	#^HDMAFive1
	sta	REG_A1B0

	lda	#$02
	sta	REG_DMAP1
	lda	#$0d
	sta	REG_BBAD1
	ldx	#HDMAFive2&&$ffff
	stx	REG_A1T1L
	lda	#^HDMAFive2
	sta	REG_A1B1

	stz	REG_DMAP2
	stz	REG_BBAD2
	ldx	#HDMAFive3&&$ffff
	stx	REG_A1T2L
	lda	#^HDMAFive3
	sta	REG_A1B2

	rep	#$20
	lda	#$0c
	jsr	Play_Musik
	sep	#$20
	lda	#$33
	sta	REG_W12SEL
	stz	REG_W34SEL
	lda	#$03
	sta	REG_WOBJSEL
	stz	REG_WBGLOG
	stz	REG_WOBJLOG
	lda	#$11
	sta	REG_TMW
	sta	REG_TSW
	lda	#$7f
	sta	REG_WH0
	sta	<Dummy_Sin
	lda	#$80
	sta	REG_WH1
	lda	#$90			;Vertical Timer IRQ at Line $0e8
	sta	REG_VTIMEL
	stz	REG_VTIMEH
	lda	#$07
	sta	REG_HDMAEN
	lda	#$0f
	sta	REG_INIDISP
	plp
	cli
	rts
;FOLD_END
;	Init for Vektor-Bobs Part
;FOLD_OUT
Initscreen6	sei
	php
	sep	#$20
	rep	#$10
	stz	REG_HDMAEN
	stz	REG_MDMAEN
	lda	#$8f
	sta	REG_INIDISP
	lda	#$80
	sta	REG_CGADD
	ldx	#$0000
.Init_01	lda	>GlassBob_Cols,x		;Transfer Bob Colors
	sta	REG_CGDATA
	inx
	cpx	#$20
	bne	.Init_01
	stz	REG_CGADD
	ldx	#$0000
.Init_07	lda	>Bobs_Logo_Col,x
	sta	REG_CGDATA
	inx
	cpx	#$20
	bne	.Init_07
	lda	#$80
	sta	REG_VMAIN
	rep	#$20
	ldx	#$4000
	stx	REG_VMADDL
	ldx	#$0000
.Init_02	lda	>GlassBob,x		;Transfer Bob Image to VRAM (16x16 Tiles)
	sta	REG_VMDATAL
	inx
	inx
	cpx	#$40
	bne	.Init_02
	lda	#$4100
	sta	REG_VMADDL
.Init_03	lda	>GlassBob,x
	sta	REG_VMDATAL
	inx
	inx
	cpx	#$80
	bne	.Init_03
	ldx	#$0000
	stx	REG_VMADDL
.Init_08	lda	>Bobs_Logo,x
	sta	REG_VMDATAL
	inx
	inx
	cpx	#$2400
	bne	.Init_08

	ldx	#$2000
	stx	REG_VMADDL
	ldx	#$0000
.Init_13	lda	>Bobs_Back,x
	sta	REG_VMDATAL
	inx
	inx
	cpx	#$200
	bne	.Init_13

	ldx	#$3000
	stx	REG_VMADDL
	ldx	#$0000
.Init_17	lda	>Bobs_Back1,x
	sta	REG_VMDATAL
	inx
	inx
	cpx	#$400
	bne	.Init_17

	ldx	#$4400
	stx	REG_VMADDL
	ldx	#$0000
.Init_09	stz	REG_VMDATAL
	inx
	cpx	#$0c00
	bne	.Init_09

	lda	#$0000
	sta	<X_Add
	ldx	#$4400
	stx	REG_VMADDL
	ldy	#$03
.Init_12	ldx	#$0000
.Init_11	lda	!Bob_Logo_Data,x
	clc
	adc	<X_Add
	sta	REG_VMDATAL
	inx
	inx
	cpx	#$40
	bne	.Init_11
	lda	<X_Add
	clc
	adc	#$20
	sta	<X_Add
	dey
	bne	.Init_12

	ldx	#$4800
	stx	REG_VMADDL
	ldy	#0000
.Init_14	lda	#$0020
	ldx	!Back_Tab,y
.Init_15	stz	REG_VMDATAL
	dec	a
	dex
	bne	.Init_15
	ldx	#$0008
.Init_16	stx	REG_VMDATAL
	dec	a
	bne	.Init_16
	iny
	iny
	cpy	#11*2
	bne	.Init_14

	ldx	#$4c00
	stx	REG_VMADDL
	ldy	#0000
.Init_18	lda	#$0010
	ldx	!Back_Tab,y
.Init_19	pha
	lda	#$0008
	sta	REG_VMDATAL
	pla
	dec	a
	dex
	bne	.Init_19
	ldx	#$2002
.Init_20	stx	REG_VMDATAL
	dec	a
	bne	.Init_20
	lda	#$0008
	ldx	#$10
.Init_21	sta	REG_VMDATAL
	dex
	bne	.Init_21
	iny
	iny
	cpy	#11*2
	bne	.Init_18

	sep	#$20			;Fixed Color Addition OFF
	lda	#$00
	sta	CGSWSEL
	lda	#$e0
	sta	COLDATA
	lda	#$00
	sta	CGADSUB
;	lda	#$15			;Screenmode 1
;	sta	REG_BGMODE
;	lda	#$17			;Only Objects on!+Screen 1
;	sta	REG_TM
	lda	#$01
	sta	REG_TS

	lda	#$44
	sta	REG_BG1SC
	lda	#$48
	sta	REG_BG2SC
	lda	#$4c
	sta	REG_BG3SC

	lda	#$30
	sta	REG_BG12NBA
	lda	#$02
	sta	REG_BG34NBA

	lda	#$c0
	sta	REG_BG1HOFS
	lda	#$ff
	sta	REG_BG1HOFS
	lda	#$50
	sta	REG_BG1VOFS
	lda	#$ff
	sta	REG_BG1VOFS

	stz	REG_BG2HOFS
	stz	REG_BG2HOFS
	stz	REG_BG3HOFS
	stz	REG_BG3HOFS
	stz	REG_BG2VOFS
	stz	REG_BG2VOFS
	stz	REG_BG3VOFS
	stz	REG_BG3VOFS

	lda	#$62			;Oam Image at $4000,Size 16x16 or 32x32
	sta	REG_OBSEL
	stz	REG_OAMADDL
	stz	REG_OAMADDH
	ldx	#$80
	lda	#$00
	xba
	lda	#$e0
.Init_04	stz	REG_OAMDATA			;Init OAM Ram
	sta	REG_OAMDATA
	xba
	stz	REG_OAMDATA
	sta	REG_OAMDATA
	xba
	dex
	bne	.Init_04
.Init_05	stz	REG_OAMDATA
	inx
	cpx	#$20
	bne	.Init_05
	ldx	#$0000
.Init_06	stz	!OAM_Buffer,x		;Init OAM Mirror Image
	sta	!OAM_Buffer+1,x
	xba
	stz	!OAM_Buffer+2,x
	sta	!OAM_Buffer+3,x
	xba
	inx
	inx
	inx
	inx
	cpx	#$0200
	bne	.Init_06

	ldx	<Act_Main			;Switch to Main Part
	inx
	inx
	stx	<Act_Main
	ldx	#$0000
	stx	!OBuf_Faces		;Number of Bobs NOT to be displayed
	stx	!OBuf_RotX		;X-Rotation-Angle ($0000-$07fe)
	stx	!OBuf_XSin		;Used in Rotation Sub Routine
	stx	!OBuf_XCos		;Used in Rotation Sub Routine
	stx	!OBuf_RotY		;Y-Rotation-Angle
	stx	!OBuf_YSin		;Used in Rotation Sub Routine
	stx	!OBuf_YCos		;Used in Rotation Sub Routine
	stx	!OBuf_RotZ		;Z-Rotation-Angle
	stx	!OBuf_ZSin		;Used in Rotation Sub Routine
	stx	!OBuf_ZCos		;Used in Rotation Sub Routine
	stx	!OBuf_Dist		;Offset to z Coord (Eye Coord)
	stx	<Script_Poi		;Pointer for Script
	stx	<Script_Next		;Counter for the Script
	stx	<X_Add			;Add to x-rotation-angle (Every Frame)
	stx	<Y_Add			;Add to y-rotation-angle (Every Frame)
	stx	<Z_Add			;Add to z-rotation-angle (Every Frame)
	stx	<Dummy_Sin		;Screen Open Scroll
	dex
	stx	<Act_Object		;Screen Close Scroll
	ldx	#Bob_Points2&&$ffff
	stx	!OBuf_Color		;Actual Object (Pointer)

	rep	#$20
	
	lda	#$10
	jsr	Play_Musik
	sep	#$20
	rep	#$10
	lda	#$00
	sta	REG_DMAP0
	lda	#$05
	sta	REG_BBAD0
	ldx	#ScrMode&&$ffff
	stx	REG_A1T0L
	lda	#^ScrMode
	sta	REG_A1B0

	lda	#$00
	sta	REG_DMAP1
	lda	#$2c
	sta	REG_BBAD1
	ldx	#ScrMode1&&$ffff
	stx	REG_A1T1L
	lda	#^ScrMode1
	sta	REG_A1B1

	lda	#$03
	sta	REG_HDMAEN
	lda	#$e1			;Vertical Timer IRQ at Line $0e8
	sta	REG_VTIMEL
	stz	REG_VTIMEH
	plp
	cli

	sep	#$20
	lda	#$00
.fadeout	wai
	wai
	wai
	wai
	sta	REG_INIDISP
	inc	a
	cmp	#$10
	bne	.fadeout
	rts

Bob_Logo_Data	.word	$00,$02,$04,$06,$08,$0a,$0c,$0e,$60,$62,$64,$66,$68,$6a,$6c,$6e,$c0,$c2,$c4,$c6,$c8,$ca,$cc,$ce,$ce,$ce,$ce,$ce,$ce,$ce,$ce,$ce
ScrMode	.byte	$7f,$f9,$30,$f9,$1,$f5,0,0
ScrMode1	.byte	$7f,$16,$30,$16,$1,$01,0,0
Back_Tab	.word	8,9,8,7,8,6,7,9,8,10,8

;FOLD_END
;	Init for Landscape Part
;FOLD_OUT

LogoYPos	Set	$00
LogoXPos	Set	$bf

Initscreen7	sei
	php
	sep	#$20
	rep	#$10
	stz	REG_HDMAEN
	stz	REG_MDMAEN
	stz	REG_MOSAIC
	lda	#$8f
	sta	REG_INIDISP

	rep	#$30
	rep	#$30
	ldx	#$0000
.Init_06	lda	>Land_Divs_Table,x
	sta	>$7e3000,x
	inx
	inx
	cpx	#$4000
	bne	.Init_06
	sep	#$20
	lda	#$07
	sta	REG_BGMODE

	lda	#$80
	sta	REG_VMAIN
	ldx	#$4000
	stx	REG_VMADDL
	ldx	#$0000
	rep	#$20
.Init_07	lda	>Land_Logo,x
	sta	REG_VMDATAL
	inx
	inx
	cpx	#$8000
	bne	.Init_07
	sep	#$20
	stz	REG_CGADD
	ldx	#$0000
.Init_01	lda	>Land_Colors,x		;Init Colors
	sta	REG_CGDATA
	inx
	cpx	#$200
	bne	.Init_01
	rep	#$20

	ldx	#$0000
.Init_05	lda	>Land_Landscape1,x	;Transfer Chunky Pic to RAM
	sta	>$7e8000,x
	lda	>Land_Landscape2,x
	sta	>$7f0000,x
	inx
	inx
	bpl	.Init_05
	sep	#$20
	ldx	#$0000			;Clear VRam
	ldy	#$00ff
	stx	REG_VMADDL
	ldx	#$3fff
.Init_00	sty	REG_VMDATAL
	dex
	bpl	.Init_00
	lda	#$00
	sta	REG_VMAIN
	ldx	#$0000
	stx	REG_VMADDL
.Init_03	ldy	#$0080			;Init Mode 7 Screen
.Init_04	cpy	#$0070
	bcs	.ship
	stz	REG_VMDATAL
	bra	.hund
.ship	sta	REG_VMDATAL
.hund	clc
	adc	#$08
	dey
	bne	.Init_04
	inc	a
	and	#$07
	bne	.Init_03
	lda	#$11
	sta	REG_TM
	stz	REG_TS
	lda	#$c0
	sta	REG_M7SEL
	lda	#$60			;Init Mode 7 Registers
	sta	REG_M7A
	stz	REG_M7A
	stz	REG_M7B
	stz	REG_M7B
	stz	REG_M7C
	stz	REG_M7C
	sta	REG_M7D
	stz	REG_M7D
	lda	#$97
	sta	REG_BG1HOFS
	lda	#$ff
	sta	REG_BG1HOFS
	lda	#$40
	sta	REG_M7X
	stz	REG_M7X
	lda	#$65
	sta	REG_BG1VOFS
	lda	#$ff
	sta	REG_BG1VOFS
	lda	#$50
	sta	REG_M7Y
	stz	REG_M7Y
	lda	#$40
	sta	<L_X2Pos			;Eye X-Pos (Byte)
	sta	<L_X2Pos+1			;Eye Y-Pos (Byte)
	stz	<L_Y2Pos			;Eye Angle (Word)
	stz	<L_Y2Pos+1
	stz	<L_DeltaX
	stz	<L_DeltaX+1
	stz	<Z_Add			;Next_Part?
	stz	<Y_Add+1
	stz	<Act_Buffer
	stz	<Act_Buffer+1
	lda	#$60
	sta	<Y_Add
	lda	#$42			;Initialize OAMs For The Logo!
	sta	REG_OBSEL
	stz	REG_OAMADDL
	stz	REG_OAMADDH
	ldx	#$80
	lda	#$e0
.initloop1	stz	REG_OAMDATA
	sta	REG_OAMDATA
	stz	REG_OAMDATA
	stz	REG_OAMDATA
	dex
	bne	.initloop1
.initloop2	stz	REG_OAMDATA
	inx
	cpx	#$20
	bne	.initloop2
	stz	REG_OAMADDL
	stz	REG_OAMADDH

	lda	#LogoXPos
	sta	REG_OAMDATA
	lda	#LogoYPos
	sta	REG_OAMDATA
	lda	#$00
	sta	REG_OAMDATA
	lda	#$08
	sta	REG_OAMDATA

	lda	#LogoXPos
	sta	REG_OAMDATA
	lda	#LogoYPos
	sta	REG_OAMDATA
	lda	#$08
	sta	REG_OAMDATA
	lda	#$0a
	sta	REG_OAMDATA

	lda	#LogoXPos
	sta	REG_OAMDATA
	lda	#LogoYPos
	sta	REG_OAMDATA
	lda	#$00
	sta	REG_OAMDATA
	lda	#$0d
	sta	REG_OAMDATA

	lda	#LogoXPos
	sta	REG_OAMDATA
	lda	#LogoYPos
	sta	REG_OAMDATA
	lda	#$08
	sta	REG_OAMDATA
	lda	#$0f
	sta	REG_OAMDATA


	lda	#LogoXPos
	sta	REG_OAMDATA
	lda	#LogoYPos+$40
	sta	REG_OAMDATA
	lda	#$80
	sta	REG_OAMDATA
	lda	#$08
	sta	REG_OAMDATA

	lda	#LogoXPos
	sta	REG_OAMDATA
	lda	#LogoYPos+$40
	sta	REG_OAMDATA
	lda	#$88
	sta	REG_OAMDATA
	lda	#$0a
	sta	REG_OAMDATA

	lda	#LogoXPos
	sta	REG_OAMDATA
	lda	#LogoYPos+$40
	sta	REG_OAMDATA
	lda	#$80
	sta	REG_OAMDATA
	lda	#$0d
	sta	REG_OAMDATA

	lda	#LogoXPos
	sta	REG_OAMDATA
	lda	#LogoYPos+$40
	sta	REG_OAMDATA
	lda	#$88
	sta	REG_OAMDATA
	lda	#$0f
	sta	REG_OAMDATA


	lda	#LogoXPos
	sta	REG_OAMDATA
	lda	#LogoYPos+$80
	sta	REG_OAMDATA
	lda	#$00
	sta	REG_OAMDATA
	lda	#$08
	sta	REG_OAMDATA

	lda	#LogoXPos
	sta	REG_OAMDATA
	lda	#LogoYPos+$80
	sta	REG_OAMDATA
	lda	#$08
	sta	REG_OAMDATA
	lda	#$0a
	sta	REG_OAMDATA

	lda	#LogoXPos
	sta	REG_OAMDATA
	lda	#LogoYPos+$80
	sta	REG_OAMDATA
	lda	#$00
	sta	REG_OAMDATA
	lda	#$0d
	sta	REG_OAMDATA

	lda	#LogoXPos
	sta	REG_OAMDATA
	lda	#LogoYPos+$80
	sta	REG_OAMDATA
	lda	#$08
	sta	REG_OAMDATA
	lda	#$0f
	sta	REG_OAMDATA


	lda	#LogoXPos
	sta	REG_OAMDATA
	lda	#LogoYPos+$c0
	sta	REG_OAMDATA
	lda	#$80
	sta	REG_OAMDATA
	lda	#$08
	sta	REG_OAMDATA

	lda	#LogoXPos
	sta	REG_OAMDATA
	lda	#LogoYPos+$c0
	sta	REG_OAMDATA
	lda	#$88
	sta	REG_OAMDATA
	lda	#$0a
	sta	REG_OAMDATA

	lda	#LogoXPos
	sta	REG_OAMDATA
	lda	#LogoYPos+$c0
	sta	REG_OAMDATA
	lda	#$80
	sta	REG_OAMDATA
	lda	#$0d
	sta	REG_OAMDATA

	lda	#LogoXPos
	sta	REG_OAMDATA
	lda	#LogoYPos+$c0
	sta	REG_OAMDATA
	lda	#$88
	sta	REG_OAMDATA
	lda	#$0f
	sta	REG_OAMDATA

	lda	#$10
	sta	REG_OAMADDL
	lda	#$01
	sta	REG_OAMADDH
	lda	#$aa
	sta	REG_OAMDATA
	sta	REG_OAMDATA
	sta	REG_OAMDATA
	sta	REG_OAMDATA

	stz	REG_DMAP1
	lda	#$01
	sta	REG_BBAD1
	ldx	#OAM_Change&&$ffff
	stx	REG_A1T1L
	lda	#^OAM_Change
	sta	REG_A1B1


	ldx	#$0000
	lda	#$00
.Init_12	sta	>$7e1000,x
	inx
	cpx	#$2000
	bne	.Init_12
	ldx	Act_Main
	inx
	inx
	stx	Act_Main
	rep	#$20
	lda	#$0d
	jsr	Play_Musik
	sep	#$20
	lda	#$e0			;Vertical Timer IRQ at Line $0e8
	sta	REG_VTIMEL
	stz	REG_VTIMEH
	lda	#$02
	sta	REG_HDMAEN
	stz	REG_MDMAEN
	plp
	cli
	rts
;FOLD_END
;	Init for the Introduction
;FOLD_OUT
Initscreen8	sei
	php
	sep	#$20
	rep	#$10
	lda	#$8f
	sta	REG_INIDISP
	stz	REG_HDMAEN
	stz	REG_MDMAEN

	rep	#$20
	lda	#$0001
	jsr	Play_Musik
	sep	#$20
	rep	#$10

	lda	#$80
	sta	REG_VMAIN
	rep	#$30
	ldx	#$0000
	stx	REG_VMADDL
	txa
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
.First_Init1	lda	>Intro_Logo2,x		;Copy BIG Logo to VRam
	sta	REG_VMDATAL
	inx
	inx
	cpx	#$6400			;$3200 in VRAM
	bne	.First_Init1

	ldx	#$3400
	stx	REG_VMADDL
	ldx	#$800
	lda	#$0000
.First_Init2	sta	REG_VMDATAL			;Init 2 Empty Screens at $3400 & $3800
	dex
	bne	.First_Init2
	ldx	#$3c00
	stx	REG_VMADDL
	ldx	#$0000
.First_Init3	lda	>Intro_TextScrScr,x	;Init Screen for "Presents" Stuff
	xba
	sta	REG_VMDATAL
	inx
	inx
	cpx	#$800
	bne	.First_Init3
	ldx	#$4000
	stx	REG_VMADDL
	ldx	#$0000
.First_Init4	lda	>Intro_TextScr,x		;Copy "Presents" Text to VRAM
	sta	REG_VMDATAL
	inx
	inx
	cpx	#5000
	bne	.First_Init4
	sep	#$20
	stz	REG_CGADD
	ldx	#$0000
.First_Init5	lda	>Intro_Logo2Col,x
	sta	REG_CGDATA
	inx
	cpx	#$40
	bne	.First_Init5

	lda	#$01
	sta	REG_BGMODE
	lda	#$01
	sta	REG_TM
	lda	#$02
	sta	REG_TS
	lda	#$40
	sta	REG_BG12NBA
	stz	REG_BG34NBA
	stz	REG_BG1HOFS
	stz	REG_BG1HOFS
	stz	REG_BG1VOFS
	stz	REG_BG1VOFS
	stz	REG_BG2HOFS
	stz	REG_BG2HOFS
	stz	REG_BG2VOFS
	stz	REG_BG2VOFS
	lda	#$34
	sta	REG_BG1SC
	lda	#$3c
	sta	REG_BG2SC
	stz	<L_Incr1
	stz	<L_Incr2
	stz	<L_Incr2+1
	lda	#$02
	sta	CGSWSEL
	lda	#$e0
	sta	COLDATA
	lda	#$21
	sta	CGADSUB


	sep	#$20
	lda	#$22
	sta	REG_W12SEL
	stz	REG_W34SEL
	lda	#$02
	sta	REG_WOBJSEL
	stz	REG_WBGLOG
	stz	REG_WOBJLOG
	lda	#$11
	sta	REG_TMW
	sta	REG_TSW
	lda	#$00
	sta	REG_WH0
	lda	#$08
	sta	REG_WH1


	sep	#$30
	ldx	#$00
.w70	ldy	#$06
.w71	lda	REG_HVBJOY
	bpl	.w71
.w72	lda	REG_HVBJOY
	bmi	.w72
	dey
	bne	.w71
	inx
	cpx	#$10
	beq	.quit1
	stx	REG_INIDISP
	bra	.w70
.quit1	rep	#$10
	lda	#$0f
	sta	REG_INIDISP


.Not_VBlanc	lda	REG_HVBJOY
	bpl	.Not_VBlanc
	inc	<L_Incr1
	lda	<L_Incr1
	and	#$07
	bne	.Just_Scroll

	ldx	<L_Incr2
	lda	>Scroll_Logo,x
	beq	.Nothing_New
	bmi	.Ende
	xba
	lda	#$00
	xba
	rep	#$20
	ora	#$0400
	tax
	lda	<L_Incr1
	and	#$0f8
	ror	a
	ror	a
	ror	a
	adc	#$3480

	ldy	#$0014
.Put_Row1	sta	REG_VMADDL
	stx	REG_VMDATAL
	pha
	txa
	clc
	adc	#0040
	tax
	pla
	clc
	adc	#$20
	dey
	bne	.Put_Row1
	bra	.Fin

.Nothing_New	rep	#$21
	lda	<L_Incr1
	and	#$0f8
	ror	a
	ror	a
	ror	a
	adc	#$3480
	ldy	#20
.Put_Row3	sta	REG_VMADDL
	stz	REG_VMDATAL
	clc
	adc	#$20
	dey
	bne	.Put_Row3

.Fin	ldx	<L_Incr2
	inx
	stx	<L_Incr2

.Just_Scroll	sep	#$20
	lda	<L_Incr1
	sta	REG_BG1HOFS
	stz	REG_BG1HOFS
.VBlanc	lda	REG_HVBJOY
	bmi	.VBlanc
	jmp	.Not_VBlanc

.Ende	sep	#$30
	ldx	#$0f
.w80	ldy	#$06
.w81	lda	REG_HVBJOY
	bpl	.w81
.w82	lda	REG_HVBJOY
	bmi	.w82
	dey
	bne	.w81
	dex
	beq	.quit
	stx	REG_INIDISP
	bra	.w80

.quit	rep	#$10
	lda	#$80
	sta	REG_INIDISP
	stz	REG_TMW
	stz	REG_TSW

	lda	#$80
	sta	REG_VMAIN
	ldx	#$0000
	stx	REG_VMADDL
	txa
.Init_01	lda	>Intro_Logo,x		;Init Tiles for the mode 7 Logo
	sta	REG_VMDATAH
	inx
	cpx	#$4000
	bne	.Init_01
	lda	#$00
	sta	REG_VMAIN
	ldx	#$0000
	stx	REG_VMADDL
.Init_03	sta	REG_VMDATAL			;Init Screen for Mode7 Logo
	inc	a
	bit	#$1f
	bne	.Init_03
	ldx	#$60
.Init_04	stz	REG_VMDATAL
	dex
	bne	.Init_04
	cmp	#$00
	bne	.Init_03
	ldx	#$80*$78
.Init_05	sta	REG_VMDATAL
	dex
	bne	.Init_05

	lda	#$80
	sta	REG_VMAIN
	ldx	#$0000
	rep	#$20
.Init_07	lda	>Intro_Char,x
	sta	REG_VMDATAL
	inx
	inx
	cpx	#12280
	bne	.Init_07
	ldx	#$0000
	rep	#$20
	lda	#$6000
	sta	REG_VMADDL
	lda	#$1d44		;1d44
.Init_09	sta	REG_VMDATAL			;Init two screens for text at $6000 and $6400
	inx
	cpx	#$800
	bne	.Init_09
	sep	#$20
	lda	#$07
	sta	REG_BGMODE
	lda	#$01
	sta	REG_TM
	lda	#$02
	sta	REG_TS
	lda	#$02
	sta	REG_CGSWSEL
	lda	#$23
	sta	REG_CGADSUB
	lda	#$44
	sta	REG_BG12NBA
	stz	REG_BG34NBA
	lda	#$60
	sta	REG_BG1SC
	lda	#$64
	sta	REG_BG2SC

	lda	#$01			;Init Mode 7 Registers
	stz	REG_M7A
	sta	REG_M7A
	stz	REG_M7B
	stz	REG_M7B
	stz	REG_M7C
	stz	REG_M7C
	stz	REG_M7D
	sta	REG_M7D
	stz	REG_BG2HOFS
	stz	REG_BG2HOFS
	lda	#$c0
	sta	REG_BG2VOFS
	lda	#$ff
	sta	REG_BG2VOFS
	stz	Act_Object
	stz	Act_Object+1
	stz	REG_BG1HOFS
	stz	REG_BG1HOFS
	lda	#$80
	sta	REG_M7X
	stz	REG_M7X
	lda	#$c0
	sta	REG_BG1VOFS
	lda	#$ff
	sta	REG_BG1VOFS
	lda	#$20
	sta	REG_M7Y
	stz	REG_M7Y

	lda	#$02			;Init DMA Registers
	sta	REG_DMAP0
	lda	#$1b
	sta	REG_BBAD0
	stz	REG_A1T0L
	lda	#$10
	sta	REG_A1T0H
	stz	REG_A1B0
	lda	#$02
	sta	REG_DMAP1
	lda	#$1c
	sta	REG_BBAD1
	stz	REG_A1T1L
	lda	#$14
	sta	REG_A1T1H
	stz	REG_A1B1
	lda	#$02
	sta	REG_DMAP2
	lda	#$1d
	sta	REG_BBAD2
	stz	REG_A1T2L
	lda	#$18
	sta	REG_A1T2H
	stz	REG_A1B2
	lda	#$02
	sta	REG_DMAP3
	lda	#$1e
	sta	REG_BBAD3
	stz	REG_A1T3L
	lda	#$10
	sta	REG_A1T3H
	stz	REG_A1B3
	lda	#$00
	sta	REG_DMAP4
	sta	REG_BBAD4
	ldx	#HDMAFade&&$ffff
	stx	REG_A1T4L
	lda	#^HDMAFade
	sta	REG_A1B4
	lda	#$00
	sta	REG_DMAP5
	lda	#$05
	sta	REG_BBAD5
	ldx	#HDMAScrMode&&$ffff
	stx	REG_A1T5L
	lda	#^HDMAScrMode
	sta	REG_A1B5

	ldx	#$0000
	lda	#$01
.Init_06	sta	$1000,x			;Init HDMA Tables
	stz	$1001,x
	stz	$1002,x
	sta	$1400,x
	stz	$1401,x
	stz	$1402,x
	sta	$1800,x
	stz	$1801,x
	stz	$1802,x
	inx
	inx
	inx
	cpx	#3*160
	bne	.Init_06
	stz	$1000,x
	stz	$1001,x
	stz	$1002,x
	stz	$1400,x
	stz	$1401,x
	stz	$1402,x
	stz	$1800,x
	stz	$1801,x
	stz	$1802,x

	ldx	Act_Main
	inx
	inx
	stx	Act_Main
	ldx	#$0000
	stx	<L_Incr1			;Rotation Counter
	stx	<L_Incr2			;Zoom Adder Pointer 1
	stx	<L_DeltaX			;Effect of Sinus on Zoom
	stx	<Script_Next		;Init Script_Pointer and Script_Counter
	stx	<Script_Poi
	stx	<X_Add			;Text Counter
	stx	<Y_Add			;Text Delay Counter
	stx	<Z_Add			;Text Color Pointer
	stx	<L_OraVal
	stx	<Dummy_Sin
	lda	#$a1			;Vertical Timer IRQ at Line $0e8
	sta	REG_VTIMEL
	stz	REG_VTIMEH
	plp
	cli
	rts

Test_Text	.byte	"                "
	.byte	" THE POTHEAD OF "
	.byte	" ANTROX STRIKES "
	.byte	"  BACK WITH THE "
	.byte	" FIRST ABANDON  "
	.byte	" SNES DEMO EVER."
	.byte	"THIS DEMO IS MY "
	.byte	" WAY OF SAYING  "
	.byte	" THANKS FOR THE "
	.byte	"NICE TIME WE HAD"
	.byte	"IN THE PAST FIVE"
	.byte	"    YEARS..     "
	.byte	"SO LEAN BACK AND"
	.byte	" TRY TO ENJOY IT"
	.byte	"                "
	.byte	"                "
	.byte	"                "
	.byte	"                "
Scroll_Logo	.byte	0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25
	.byte	26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,0,0,0,0,0,0,0,0,0,0
	.byte	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,$ff

;FOLD_END
;	Init for the Picture
;FOLD_OUT
Initscreen9	sei
	php
	rep	#$30
	sep	#$20
	lda	#$8f
	sta	REG_INIDISP
	stz	REG_HDMAEN
	stz	REG_MDMAEN
	stz	REG_CGADD
	lda	#$00
	sta	REG_DMAP5
	lda	#$22
	sta	REG_BBAD5
	ldx	#Picture_1_Col&&$ffff
	stx	REG_A1T5L
	lda	#^Picture_1_Col
	sta	REG_A1B5
	lda	#$02
	stz	REG_DAS5L
	sta	REG_DAS5H
	lda	#$20			;Transfer Colors for 256 Colors Picture
	sta	REG_MDMAEN
	lda	#$80
	sta	REG_VMAIN
	rep	#$20
	ldx	#$2000
	stx	REG_VMADDL
	ldx	#$0000
.Init_01	lda	>Picture_1_Tiles,x			;Transfer 256 Colors Picture Tiles
	sta	REG_VMDATAL
	inx
	inx
	cpx	#$8000
	bne	.Init_01
	ldx	#$0000
.Init_02	lda	>Picture_1_Tiles+$10000,x
	sta	REG_VMDATAL
	inx
	inx
	cpx	#47552-$8000
	bne	.Init_02
	ldx	#$0c00
	stx	REG_VMADDL
	ldx	#$0000
.Init_03	lda	>Picture_1_Screen,x
	xba
	sta	REG_VMDATAL
	inx
	inx
	cpx	#1792
	bne	.Init_03
	ldx	#$20
.Init_04	stz	REG_VMDATAL
	dex
	bne	.Init_04
	sep	#$20
	lda	#$0c
	sta	REG_BG1SC
	lda	#$02
	sta	REG_BG12NBA
	lda	#$03
	sta	REG_BGMODE
	lda	#$01
	sta	REG_TM
	stz	REG_TS
	stz	REG_BG1HOFS
	stz	REG_BG1HOFS
	stz	REG_BG1VOFS
	stz	REG_BG1VOFS
	rep	#$20
	lda	#$0005
	jsr	Play_Musik
	sep	#$20
	lda	#$02
	sta	CGSWSEL
	lda	#$e0
	sta	COLDATA
	lda	#$21
	sta	CGADSUB
	lda	#$00
	sta	REG_CGSWSEL
	lda	#$21
	sta	REG_CGADSUB
	sep	#$30
	ldy	#$ff
	sty	REG_COLDATA
	lda	#$00
	sta	REG_INIDISP
	cli
.Wait1	xba				;Fade in Screen (White)
	ldx	#$04
	sep	#$30
.4ever1	lda	REG_HVBJOY
	bmi	.4ever1
.Not_Blank1	lda	REG_HVBJOY
	bpl	.Not_Blank1
	dex
	bne	.4ever1
	xba
	inc	a
	cmp	#$10
	beq	.Wait
	sta	REG_INIDISP
	bra	.Wait1
.Wait	ldx	#$04			;Use Fixed Color Addition
.4ever	lda	REG_HVBJOY			;to Fade in Screen
	bmi	.4ever
.Not_Blank	lda	REG_HVBJOY
	bpl	.Not_Blank
	sty	REG_COLDATA
	dex
	bne	.4ever
	dey
	cpy	#$e0
	bne	.Wait			;Picture Displayed

	ldy	#$01
.Shit	ldx	#$00			;Wait $200 Frames
.4ever2	lda	REG_HVBJOY
	bmi	.4ever2
.Not_Blank2	lda	REG_HVBJOY
	bpl	.Not_Blank2
	dex
	bne	.4ever2
	dey
	bne	.Shit

	lda	#$0f
	sta	REG_INIDISP
.Wait3	xba				;Fade in Screen (Black)
	ldx	#$05
	sep	#$30
.4ever3	lda	REG_HVBJOY
	bmi	.4ever3
.Not_Blank3	lda	REG_HVBJOY
	bpl	.Not_Blank3
	dex
	bne	.4ever3
	xba
	dec	a
	bmi	.Wait2
	sta	REG_INIDISP
	bra	.Wait3
.Wait2	rep	#$10
	ldx	Act_Main
	inx
	inx
	inx
	inx
	stx	Act_Main
	sep	#$20
	lda	#$8f
	sta	REG_INIDISP
	plp
	rts

;FOLD_END
;	Init for Hidden
;
;	Check Wether Hidden Part is activated (PRESS A,B,X,Y,TL,TR,Start,Select at
;	the same time in the Last Part and reset Afterwards!)
;FOLD_OUT
Check_For_Hidden	php
	sep	#$20
	rep	#$10
	lda	>$7efffd
	cmp	#$4b
	bne	.Not_Part
	lda	>$7efffe
	cmp	#$61
	bne	.Not_Part
	lda	>$7effff
	cmp	#$79
	bne	.Not_Part
	lda	#$00
	sta	>$7effff
	jsr	init_musax
	jmp	Do_Hidden
.Not_Part	plp
	rts	

init_musax	php
	sep	#$20
	rep	#$10
	lda	#^Music		;R=ires A[8] XY[16]
	sta	$a5
	ldy	#Music&&$ffff
	sty	$a3
	lda	#$e5
	sta	REG_APUIO0
	rep	#$30
	ldy	#$0000
	lda	#$bbaa
.loop1	cmp	REG_APUIO0
	bne	.loop1
	sep	#$20
	lda	#$cc
	bra	.start
.Main_Loop	lda	[$a3],y
	iny
	bpl	.skip0
	ldy	#$0000 
	inc	$a5
.skip0	xba
	lda	#$00
	bra	.skip2
.loop4	xba
	lda	[$a3],y
	iny
	bpl	.skip1
	ldy	#$0000
	inc	$a5
.skip1	xba
.loop5	cmp	REG_APUIO0
	bne	.loop5
	inc	a
.skip2	rep	#$20
	sta	REG_APUIO0
	sep	#$20
	dex
	bne	.loop4
.loop3	cmp	REG_APUIO0
	bne	.loop3
.zero	adc	#$03
	beq	.zero
.start	pha
	rep	#$20
	lda	[$a3],y
	iny
	iny
	tax
	lda	[$a3],y
	iny
	iny
	sta	REG_APUIO2
	sep	#$20
	cpx	#$0001
	lda	#$00
	rol	a
	sta	REG_APUIO1
	adc	#$7f
	pla
	sta	REG_APUIO0
.loop2	cmp	REG_APUIO0
	bne	.loop2
	bvs	.Main_Loop
	rep	#$20
	lda	#$207
	sta	$2400
	plp
	rts				;A [8] XY[16]

Do_Hidden	sei
	rep	#$10
	sep	#$20
	lda	#$80
	sta	REG_INIDISP
	stz	REG_MDMAEN
	stz	REG_HDMAEN
	lda	#$80
	sta	REG_VMAIN
	rep	#$30
	ldx	#$0000
	stx	REG_VMADDL
.Init1	lda	>Hidden_Logo,x		;Copy Tiles for Logo
	sta	REG_VMDATAL
	inx
	inx
	cpx	#$2800
	bne	.Init1
	ldx	#$2000
	stx	REG_VMADDL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	stz	REG_VMDATAL
	ldx	#$0000
.Init2	lda	>Hidden_Char,x		;Copy Tiles for Char
	sta	REG_VMDATAL
	inx
	inx
	cpx	#$3c0
	bne	.Init2
	ldx	#$0000
	sep	#$20
	stz	REG_CGADD
.Init3	lda	>Hidden_Colors,x		;Copy Colors
	sta	REG_CGDATA
	inx
	cpx	#$20
	bne	.Init3
	rep	#$20
	lda	#$0000
	ldy	#$1400
	sty	REG_VMADDL
.Init4	sta	REG_VMDATAL			;Init Logo Screen
	inc	a
	cmp	#$140
	bne	.Init4
	lda	#$001e
	ldx	#$2c0
.Init5	sta	REG_VMDATAL
	dex
	bne	.Init5
	lda	#$0000			;Init Screens for Scroller
	ldx	#$800
.Init6	sta	REG_VMDATAL
	dex
	bne	.Init6
	sep	#$20
	lda	#$01
	sta	REG_BGMODE
	lda	#$14
	sta	REG_BG1SC
	lda	#$19
	sta	REG_BG2SC
	lda	#$20
	sta	REG_BG12NBA
	lda	#$03
	sta	REG_TM
	stz	REG_TS
	stz	REG_BG1HOFS
	stz	REG_BG1HOFS
	stz	REG_BG1VOFS
	stz	REG_BG1VOFS
	stz	REG_BG2HOFS
	stz	REG_BG2HOFS
	stz	REG_BG2VOFS
	stz	REG_BG2VOFS
	ldx	#$0000
	stx	L_X2Pos			;Scroll-Value
	ldx	#$1e00
	stx	L_Y2Pos			;Scroll-Offset
	ldx	#$0000
	stx	L_X1Pos			;Text-Pointer
	lda	#$0f
	sta	REG_INIDISP
.4ever	lda	REG_HVBJOY
	bmi	.4ever
.Not_Blank	lda	REG_HVBJOY
	bpl	.Not_Blank
	rep	#$20
	lda	L_X2Pos
	inc	a
	sta	L_X2Pos
	sep	#$20
	sta	REG_BG2HOFS
	xba
	sta	REG_BG2HOFS
	xba
	and	#$07
	bne	.4ever
	ldx	L_Y2Pos
	inx
	cpx	#$1e20
	bne	.Not_That
	ldx	#$1a00
	bra	.skip
.Not_That	cpx	#$1a20
	bne	.skip
	ldx	#$1e00
.skip	stx	L_Y2Pos
	stx	REG_VMADDL
	ldx	L_X1Pos
	inx
	stx	L_X1Pos
	lda	!TextHidden,x
	eor	#$17
	bne	.Not_Warp
	ldx	#$0000
	stx	L_X1Pos
	bra	.4ever
.Not_Warp	rep	#$20
	and	#$00ff
	tax
	sep	#$20
	lda	ASCIIHidden,x
	rep	#$20
	and	#$00ff
	sta	REG_VMDATAL
	sep	#$20
	jmp	.4ever

ASCIIHidden	.byte	00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
	.byte	00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
	.byte	00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
	.byte	00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
	.byte	00,01,02,03,04,05,06,07,08,09,10,11,12,13,14,15
	.byte	16,17,18,19,20,21,22,23,24,25,26,00,00,00,00,00

TextHidden	.bin	ram:Magical_2nd_Demo/incbins/Hidden.text

;FOLD_END


IRQ	php
	rep	#$30
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
	lda	REG_TIMEUP
	ldx	Act_Main
	jsr	(VBR_Routines,x)
	rep	#$30
	plb
	pld
	ply
	plx
	pla
	plp
NMI	rti


;	*************************************************
;	*** Vertical Blank Sub-Routines for Each Part ***
;	*************************************************
;	VBR for Filled-Vector Object Part
;	Changes Rotation Angles for all 3 Axis
;	Manages Double Buffer Switching, General Purpose DMA Transfering
;	and Clearing Buffers
;FOLD_OUT
VBR__01	sep	#$20
	rep	#$20
	lda	!OBuf_RotX	;Change X-Rotation Angle
	clc
	adc	<X_Add
	and	#$07fe
	sta	!OBuf_RotX
	lda	!OBuf_RotY	;Change Y-Rotation Angle
	clc
	adc	<Y_Add
	and	#$07fe
	sta	!OBuf_RotY
	lda	!OBuf_RotZ	;Change Z-Rotation Angle
	clc
	adc	<Z_Add
	and	#$07fe
	sta	!OBuf_RotZ
	sep	#$20
	lda	Comm_Bit
	bne	.skip
	jmp	.Skip1
.skip	bit	#$01
	bne	.Clear
	ldx	<Act_Buffer		;Switch Buffers before Transfering
	ldy	<Old_Buffer
	stx	<Old_Buffer
	sty	<Act_Buffer
	stz	REG_MDMAEN
	lda	#$80
	sta	REG_VMAIN
	ldx	#$1008
	stx	REG_VMADDL
	lda	#$01		;Write One Byte
	sta	REG_DMAP0
	lda	#$18		;to REG_VMDATAH
	sta	REG_BBAD0
	lda	<Old_Buffer		;And read from $7e04e0
	sta	REG_A1T0L
	lda	<Old_Buffer+1
	sta	REG_A1T0H
	lda	#$7e
	sta	REG_A1B0
	lda	#$40		;Transfer $3040 Bytes
	sta	REG_DAS0L
	lda	#$30
	sta	REG_DAS0H
	lda	#$01		;Start Transfer
	sta	REG_MDMAEN
	lda	#$01		;Allow Main Routine to Start Calculating
	sta	Comm_Bit
	bra	.Skip1
.Clear	stz	REG_MDMAEN
	ldx	#$6000		;Clear Screen Buffer
	stx	REG_VMADDL		;(Transfer ZEROs ($6000 VRAM) to WRAM
	lda	#$80		;Write One Byte
	sta	REG_DMAP0
	lda	#$39		;from REG_VMDATALREAD
	sta	REG_BBAD0
	lda	Old_Buffer		;And write to $7e04e0
	sta	REG_A1T0L
	lda	Old_Buffer+1
	sta	REG_A1T0H
	lda	#$7e
	sta	REG_A1B0
	lda	#$40		;Transfer $3040 Bytes
	sta	REG_DAS0L
	lda	#$30
	sta	REG_DAS0H
	lda	#$01		;Start Transfer
	sta	REG_MDMAEN
	stz	Comm_Bit		;Tell VBR-Routine to w8 4 Calculation to be finished
.Skip1	rep	#$20
	lda	<Dummy_Sin
	beq	.Looser
	lda	<Hundekuchen
	inc	a
	cmp	#$101
	beq	.Looser
	sta	<Hundekuchen
	sep	#$20
	sta	REG_BG1HOFS
	xba
	sta	REG_BG1HOFS
.Looser	sep	#$20	
	rts
;FOLD_END
;	VBR for Wobbeling in between Part
;	Just Calculates the Wobbleing for each Rasterline (HDMA Five Table)
;	And Increases the Pointers to the Sinus Table
;FOLD_OUT
VBR__02	inc	OBuf_RotX
	inc	OBuf_RotX+1
	inc	OBuf_RotX+1
	inc	OBuf_RotY
	inc	OBuf_RotY
	inc	OBuf_RotY

	lda	OBuf_RotX+1
	rep	#$20
	pha
	dec	OBuf_RotZ
	lda	OBuf_RotZ	
	cmp	#$ffff
	bne	.cont
	stz	OBuf_RotZ
.cont	pla
	and	#$00ff
	asl	a
	asl	a
	asl	a
	tax
	sep	#$20

	lda	OBuf_RotZ
	sta	REG_M7A
	lda	OBuf_RotZ+1
	sta	REG_M7A

	lda	!sinus+1,x
	sta	REG_M7B
	lda	REG_MPYM
	sta	REG_BG3HOFS
	lda	REG_MPYH
	sta	REG_BG3HOFS
	rep	#$21
	txa
	adc	#512
	and	#$7ff
	tax
	sep	#$20

;	lda	OBuf_RotZ
;	sta	REG_M7A
;	lda	OBuf_RotZ+1
;	sta	REG_M7A

	lda	!sinus+1,x
	sta	REG_M7B
	lda	REG_MPYM
	sta	REG_BG3VOFS
	lda	REG_MPYH
	sta	REG_BG3VOFS
	
	rep	#$20
	lda	OBuf_RotX+1
	and	#$00ff
	clc
	adc	#sinus2&&$ffff
	sta	L_X1Pos
	lda	OBuf_RotY
	and	#$00ff
	clc
	adc	#sinus2&&$ffff
	sta	L_Y1Pos

	rep	#$20
	lda	OBuf_RotX
	and	#$00ff
	tay
	lda	OBuf_RotZ
	bpl	.Pos1
	eor	#$ffff
	inc	a
.Pos1	clc
	ror	a
	clc
	ror	a
	sep	#$20
	sta	Dummy_Sin
	ldx	#224*3
.LOOP	lda	sinus2,x
	clc
	adc	(L_X1Pos),y
	ror	a
	clc
	adc	(L_Y1Pos),y
	ror	a
	sec
	sbc	Dummy_Sin
	phx
	pha
	rep	#$21
	txa
	sbc	#224*3-1
	eor	#$ffff
	inc	a
	tax
	sep	#$20
	pla
	sta	!HDMAFive+1,x
	plx
	iny
	inc	Dummy_Sin
	dex
	dex
	dex
	bne	.LOOP
	rts
;FOLD_END
;	VBR for the 256 Colors 1-Pixel Sinus Scroller Part
;	Writes the GFX-Data to V-RAM and Calculates the Sinus Table
;	for the Next Frame.
;FOLD_OUT
VBR__03	inc	L_X1Pos
	ldx	L_X1Pos
	sep	#$10
	rep	#$21
	lda	#REG_INIDISP
	tcd
	ldy	#$00
.loop	phy
	lda	$0e00,y		;Put One Row
	sta	$16
	stz	$19
	adc	#$08
	sta	$16
	ldy	$1001,x
	sty	$19
	adc	#$08
	sta	$16
	ldy	$1201,x
	sty	$19
	adc	#$08
	sta	$16
	ldy	$1401,x
	sty	$19
	adc	#$08
	sta	$16
	ldy	$1601,x
	sty	$19
	adc	#$08
	sta	$16
	ldy	$1801,x
	sty	$19
	adc	#$08
	sta	$16
	ldy	$1a01,x
	sty	$19
	adc	#$08
	sta	$16
	ldy	$1c01,x
	sty	$19
	adc	#$08
	sta	$16
	ldy	$1e01,x
	sty	$19
	adc	#$08
	sta	$16
	stz	$19
	inx
	ply
	iny
	iny
	bne	.loop
.loop1	phy
	lda	$0f00,y		;Put One Row
	sta	$16
	stz	$19
	adc	#$08
	sta	$16
	ldy	$1001,x
	sty	$19
	adc	#$08
	sta	$16
	ldy	$1201,x
	sty	$19
	adc	#$08
	sta	$16
	ldy	$1401,x
	sty	$19
	adc	#$08
	sta	$16
	ldy	$1601,x
	sty	$19
	adc	#$08
	sta	$16
	ldy	$1801,x
	sty	$19
	adc	#$08
	sta	$16
	ldy	$1a01,x
	sty	$19
	adc	#$08
	sta	$16
	ldy	$1c01,x
	sty	$19
	adc	#$08
	sta	$16
	ldy	$1e01,x
	sty	$19
	adc	#$08
	sta	$16
	stz	$19
	inx
	ply
	iny
	iny
	bpl	.loop1

	lda	#$0000
	tcd

	inc	L_Y2Pos
	inc	L_Y2Pos


	rep	#$31
	lda	L_Incr2		;Angle ($000 Normal -$7fe)
	tax
	lda	L_Dummy		;Size ($200=Normal <$200 Bigger..)
	sep	#$20
	sta	REG_M7A
	xba
	sta	REG_M7A
	lda	>sinus+513,x
	sta	REG_M7B
	ldy	REG_MPYM
	lda	>sinus+1,x
	sta	REG_M7B
	rep	#$20
	lda	REG_MPYM
	pha
	tya
	sep	#$20
	sta	REG_M7A
	xba
	sta	REG_M7A
	rep	#$20
	pla
	sep	#$20
	sta	REG_M7B
	xba
	sta	REG_M7B
	xba
	rep	#$20
	eor	#$ffff
	inc	a
	sep	#$20
	sta	REG_M7C
	xba
	sta	REG_M7C
	rep	#$20
	tya
	sep	#$20
	sta	REG_M7D
	xba
	sta	REG_M7D

	lda	<Dummy_Sin
	sta	REG_WH0
makesintab	rep	#$30
	lda	L_Y2Pos
	and	#$007e
	clc
	adc	#$200
	tax
	ldy	#$0000
	lda	#$0440
	sta	L_X2Pos

.loop1	lda	!Mode7Sin,x
	adc	L_X2Pos
	sta	$0e00,y
	dex
	dex
	iny
	iny
	inc	L_X2Pos
	tya
	and	#$000e
	bne	.loop1


	lda	L_X2Pos
	adc	#$100
	and	#$1f40
	sta	L_X2Pos
	cmp	#$0040
	clc
	bne	.loop1


	inc	L_Y1Pos
	lda	L_Y1Pos
	clc
	ror	a
	clc
	ror	a
	clc
	ror	a
	tax
	sep	#$20
	lda	!Mode7Text,x
	bne	.skip2
	stz	L_Y1Pos
	stz	L_Y1Pos+1
	lda	#$20
.skip2	cmp	#$21
	bcs	.skip1
	cmp	#$20
	beq	.space
	asl	a
	sta	L_Incr1
.space	rep	#$21
	lda	#37*8
	bra	.cont1
	sep	#$20
.skip1	sec
	sbc	#$41
	rep	#$20
	and	#$00ff
	asl	a
	asl	a
	asl	a
.cont1	sta	L_DeltaX
	lda	L_Y1Pos
	and	#$0007
	clc
	adc	L_DeltaX
	tax
	ldy	L_X1Pos
	lda	>Mode7Char,x
	sta	$1000,y
	sta	$1100,y
	lda	>Mode7Char+304,x
	sta	$1200,y
	sta	$1300,y
	lda	>Mode7Char+304*2,x
	sta	$1400,y
	sta	$1500,y
	lda	>Mode7Char+304*3,x
	sta	$1600,y
	sta	$1700,y
	lda	>Mode7Char+304*4,x
	sta	$1800,y
	sta	$1900,y
	lda	>Mode7Char+304*5,x
	sta	$1a00,y
	sta	$1b00,y
	lda	>Mode7Char+304*6,x
	sta	$1c00,y
	sta	$1d00,y
	lda	>Mode7Char+304*7,x
	sta	$1e00,y
	sta	$1f00,y

	rep	#$30
	ldx	L_Incr1
	jsr	(!Effect_Tab,x)
	sep	#$20
	rts

Effect_Tab	.word	Effect_01,Effect_02,Effect_03,Effect_04,Effect_05,Effect_06

	Mode	A16X16
Effect_01	lda	L_Dummy		;Normal Scroller with Size $200, Angle=$0000
	cmp	#$200		;If Values differ from Normal, correct them
	beq	.ok		;by Small Steps each Frame!
	bcc	.to_low
	sec
	sbc	#$04
	sta	L_Dummy
	bra	.ok
.to_low	clc
	adc	#$04
	sta	L_Dummy
.ok	lda	L_Incr2
	beq	.ok2
	clc
	adc	#$08
	and	#$7f8
	sta	L_Incr2
.ok2	lda	#$0080
	sta	L_OraVal
	rts

Effect_02	lda	L_Dummy		;Zoom Scroller Closer to Screen, and return
	sec			;to Normal Size afterwards
	sbc	#$04
	sta	L_Dummy
	cmp	#$00f0
	bcs	.skip
	stz	L_Incr1
.skip	rts

Effect_03	lda	L_Incr2		;Rotate the Scroller ONCE!
	clc
	adc	#$04
	sta	L_Incr2
	stz	L_Incr1
	rts

Effect_04	lda	L_Dummy		;Zoom out Scroller and return to Normal Size
	clc			;Afterwards
	adc	#$04
	sta	L_Dummy
	cmp	#$0400
	bcc	.skip
	stz	L_Incr1
.skip	rts

Effect_05	lda	L_OraVal		;Rotate Scroll 45 Degrees Back and Forth..
	clc
	adc	#$04
	and	#$01fe
	sta	L_OraVal
	and	#$100
	beq	.down
	lda	L_OraVal
	eor	#$fffe
	and	#$0fe
	bra	.up
.down	lda	L_OraVal
.up	sec
	sbc	#$080
	and	#$07fc
	sta	L_Incr2
	rts

Effect_06	stz	L_Incr1		;Return to Normal (Call Effect_01)
	rts
;FOLD_END
;	VBR for the End of the Demo Part.
;	Does NOTHING, cause nothing is neccesary to be done.
;FOLD_OUT
VBR__04	rts
;FOLD_END
;	VBR for the Shade-Bob Part
;	Calls Shade-Bob-VB Subroutines to Calc and Put Bobs..
;FOLD_OUT
VBR__05					;Start Interrupt at Line $90
	rep	#$30
	lda	Drw_Dummy			;Change Scroll-Offset for Screen 1 first
	inc	a
	sta	Drw_Dummy
	sep	#$20
	sta	REG_BG1HOFS
	xba
	sta	REG_BG1HOFS
	jsr	!Scribt
	ldx	Drw_Dummy+6		;Calculate some Shit
	jsr	(!Not_VRAM_Tab,x)
.Wait4Blank	lda	REG_HVBJOY			;And Wait for the V-Blank
	bpl	.Wait4Blank
	lda	#$80
	sta	REG_INIDISP

	lda	Drw_Dummy			;Do Scroller
	and	#$07
	bne	.NoChange
	ldx	Drw_Dummy+2
	inx
	stx	Drw_Dummy+2
	lda	>Math_Text,x
	bne	.skip
	stz	Drw_Dummy+2		;Warp Text at 0
	stz	Drw_Dummy+3
.skip	rep	#$20
	asl	a
	and	#$fe
	tax
	lda	Drw_Dummy+4
	inc	a
	cmp	#$7ec0
	bne	.Not_01
	lda	#$7aa0
.Not_01	cmp	#$7ac0
	bne	.Not_02
	lda	#$7ea0
.Not_02	sta	Drw_Dummy+4
	sta	REG_VMADDL
	lda	>ASCIIEnd,x
	sta	REG_VMDATAL
	sep	#$20
.NoChange	ldx	Drw_Dummy+6		;Do the VRAM Transfers
	jsr	(!VRAM_Tab,x)
	lda	#$0f
	sta	REG_INIDISP
	rts

Not_VRAM_Tab	.word	Do_Nothing,Clear_Buffer,Calculate_Shit
VRAM_Tab	.word	Do_Bobs,Clear_Screen,Put_Shit

Do_Nothing	rts

Clear_Buffer	php
	sep	#$20
	lda	#$7f
	pha
	plb
	rep	#$30
	lda	Drw_PoiPoi
	dec	a
	clc
	rol	a
	rol	a
	rol	a
	ldy	#$0010
.clear1	tax
	stz	!$0000,x
	stz	!$0002,x
	stz	!$0004,x
	stz	!$0006,x
	txa
	clc
	adc	#$400
	dey
	bne	.clear1
	phk
	plb
	plp
	rts

Calculate_Shit	php
	rep	#$20
	lda	Drw_PoiPoi
	beq	.shit
	dec	a
	clc
	rol	a
	rol	a
	rol	a
	tay			;Line Offset Calculated

	lda	Drw_PoiPoi	;Get Y-Coordinate
	sec
	sbc	#$40
	ldx	L_Dummy
	jsr	(!Shit_Routines,x)
.shit	plp
	rts

Shit_Routines	.word	0,Shit_01,Shit_02,Shit_03,Shit_04,Shit_05
;FOLD_OUT
Shit_01	rep	#$20
	tyx
	ldy	#$ffc0		;X-Coordinate
	sep	#$20
	sta	REG_M7A
	xba
	sta	REG_M7A
	xba
	sta	REG_M7B		;Y^2
	rep	#$20
	lda	REG_MPYL
	sta	Drw_Dummy+8
.Loop1	tya
	sep	#$20
	sta	REG_M7A
	xba
	sta	REG_M7A
	xba
	sta	REG_M7B
	rep	#$21
	lda	REG_MPYL		;X^2
	adc	Drw_Dummy+8	;X^2+Y^2
	ror	a
	ror	a
	sep	#$20
	and	#$7f
	sta	>$7f0000,x
	inx
	iny
	rep	#$20
	txa
	and	#$07
	bne	.not_Shit
	txa
	clc
	adc	#$3f8
	tax
.not_Shit	cpy	#$40
	bne	.Loop1	
	rts

Shit_02	rep	#$20
	tyx
	ldy	#$ffc0		;X-Coordinate
	sep	#$20
	sta	REG_M7A
	xba
	sta	REG_M7A
	xba
	sta	REG_M7B		;Y^2
	rep	#$20
	lda	REG_MPYL
	sta	Drw_Dummy+8
.Loop1	tya
	sep	#$20
	sta	REG_M7A
	xba
	sta	REG_M7A
	xba
	sta	REG_M7B
	rep	#$21
	lda	REG_MPYL		;X^2
	adc	Drw_Dummy+8	;X^2+Y^2
	ror	a
	ror	a
	ror	a
	ror	a
	sep	#$20
	and	#$7f
	sta	>$7f0000,x
	inx
	iny
	rep	#$20
	txa
	and	#$07
	bne	.not_Shit
	txa
	clc
	adc	#$3f8
	tax
.not_Shit	cpy	#$40
	bne	.Loop1	
	rts

Shit_03	rep	#$20
	tyx
	ldy	#$ffc0		;X-Coordinate
	sep	#$20
	sta	REG_M7A
	xba
	sta	REG_M7A
	xba
	sta	REG_M7B		;Y^2
	rep	#$20
	lda	REG_MPYL
	sta	Drw_Dummy+8
.Loop1	tya
	sep	#$20
	sta	REG_M7A
	xba
	sta	REG_M7A
	xba
	sta	REG_M7B
	rep	#$21
	lda	REG_MPYL		;X^2
	adc	Drw_Dummy+8	;X^2+Y^2
	sep	#$20
	and	#$7f
	sta	>$7f0000,x
	inx
	iny
	rep	#$20
	txa
	and	#$07
	bne	.not_Shit
	txa
	clc
	adc	#$3f8
	tax
.not_Shit	cpy	#$40
	bne	.Loop1	
	rts

Shit_04	rep	#$20
	tyx
	sta	Drw_Dummy+10
	ldy	#$ffc0		;X-Coordinate
	sep	#$20
	sta	REG_M7A
	xba
	sta	REG_M7A
	xba
	sta	REG_M7B		;Y^2
	rep	#$20
	lda	REG_MPYL
	sep	#$20
	sta	Drw_Dummy+8
.Loop1	tya
	sep	#$20
	sta	REG_M7A
	xba
	sta	REG_M7A
	xba
	sta	REG_M7B
	rep	#$21
	lda	REG_MPYL		;X^2
	sep	#$20
	sta	REG_M7A
	xba
	sta	REG_M7A
	lda	Drw_Dummy+10
	sta	REG_M7B
	rep	#$21
	lda	REG_MPYL		;X^2*Y
	ror	a
	adc	Drw_Dummy+8	;;X^2*Y+Y^2
	ror	a
	ror	a
	ror	a
	sep	#$20
	and	#$7f
	sta	>$7f0000,x
	inx
	iny
	rep	#$20
	txa
	and	#$07
	bne	.not_Shit
	txa
	clc
	adc	#$3f8
	tax
.not_Shit	cpy	#$40
	bne	.Loop1	
	rts

Shit_05	rep	#$20
	tyx
	sta	Drw_Dummy+10
	ldy	#$ffc0		;X-Coordinate
	sep	#$20
	sta	REG_M7A
	xba
	sta	REG_M7A
	xba
	sta	REG_M7B		;Y^2
	rep	#$20
	lda	REG_MPYL
	sep	#$20
	sta	Drw_Dummy+8
.Loop1	tya
	sep	#$20
	sta	REG_M7A
	xba
	sta	REG_M7A
	xba
	sta	REG_M7B
	rep	#$21
	lda	REG_MPYL		;X^2
	sep	#$20
	sta	REG_M7A
	xba
	sta	REG_M7A
	tya			;Drw_Dummy+10
	sta	REG_M7B
	rep	#$21
	lda	REG_MPYM		;X^3
	adc	Drw_Dummy+8	;;X^3+Y^2
	ror	a
	sep	#$20
	and	#$7f
	sta	>$7f0000,x
	inx
	iny
	rep	#$20
	txa
	and	#$07
	bne	.not_Shit
	txa
	clc
	adc	#$3f8
	tax
.not_Shit	cpy	#$40
	bne	.Loop1	
	rts
;FOLD_END

Do_Bobs	jsr	!Rotate_n_Zoom
	ldx	L_Dummy
	jsr	!Shade_Bobs1
	rts


Clear_Screen	php
	rep	#$30
	lda	Drw_PoiPoi	;Get # of Line to be Cleared
	dec	a
	clc
	rol	a
	rol	a
	rol	a
	ldx	#$0010
.clear1	sta	REG_VMADDL
	sep	#$20
	stz	REG_VMDATAH
	stz	REG_VMDATAH
	stz	REG_VMDATAH
	stz	REG_VMDATAH
	stz	REG_VMDATAH
	stz	REG_VMDATAH
	stz	REG_VMDATAH
	stz	REG_VMDATAH
	rep	#$21
	adc	#$400
	dex
	bne	.clear1
	plp
	rts

Put_Shit	php
	jsr	!Rotate_n_Zoom
	rep	#$30
	lda	Drw_PoiPoi	;Get # of Line to be Cleared
	dec	a
	clc
	rol	a
	rol	a
	rol	a
	tax
	ldy	#$0010
.clear1	stx	REG_VMADDL
	sep	#$20
	lda	>$7f0000,x
	sta	REG_VMDATAH
	lda	>$7f0001,x
	sta	REG_VMDATAH
	lda	>$7f0002,x
	sta	REG_VMDATAH
	lda	>$7f0003,x
	sta	REG_VMDATAH
	lda	>$7f0004,x
	sta	REG_VMDATAH
	lda	>$7f0005,x
	sta	REG_VMDATAH
	lda	>$7f0006,x
	sta	REG_VMDATAH
	lda	>$7f0007,x
	sta	REG_VMDATAH
	rep	#$21
	txa
	adc	#$400
	tax
	dey
	bne	.clear1
	plp
	rts

;FOLD_END
;	VBR for the Vector-Bob Part
;	Transfers OAM-Mirror Image to OAM-Ram.
;FOLD_OUT
VBR__06	sep	#$20
	rep	#$10
	stz	REG_OAMADDL
	stz	REG_OAMADDH
	stz	REG_DMAP7
	lda	#$04
	sta	REG_BBAD7
	ldx	#OAM_Buffer&&$ffff
	stx	REG_A1T7L
	lda	#^OAM_Buffer
	sta	REG_A1B7
	stz	REG_DAS7L
	lda	#$02
	sta	REG_DAS7H
	lda	#$80
	sta	REG_MDMAEN		;Transfer $200 Bytes from OAM_Buffer to OAM RAM ($000)
	rts
;FOLD_END
;	VBR for the Landscape Part
;	Transfers VRam-Mirror Ram to VRam and Clears Buffer afterwards.
;FOLD_OUT
VBR__07	sep	#$20
	rep	#$10
	lda	Comm_Bit
	bpl	.skip
	stz	Comm_Bit
	stz	REG_DMAP0			;Transfer Ram Buffer to VRAM
	lda	#$19
	sta	REG_BBAD0
	ldx	#$1000
	stx	REG_A1T0L
	lda	#$7e
	sta	REG_A1B0
	stz	REG_DAS0L
	lda	#$12
	sta	REG_DAS0H

	lda	#$80
	sta	REG_INIDISP
	ldx	#$0000
	stx	REG_VMADDL
	sta	REG_VMAIN
	lda	#$01
	sta	REG_MDMAEN
	lda	<Z_Add
	beq	.shit
	clc
	ror	a
	bra	.ship	
.shit	rep	#$20
	lda	<Act_Buffer
	clc
	adc	#$80
	cmp	#$0f80
	bne	.shipp
	lda	#$0f00
.shipp	sta	<Act_Buffer
	sep	#$20
	xba
.ship	sta	REG_INIDISP

	stz	REG_WMADDL
	lda	#$10
	sta	REG_WMADDM
	stz	REG_WMADDH
	lda	#$08
	sta	REG_DMAP0
	lda	#$80
	sta	REG_BBAD0
	ldx	#(HDMAFour-2)&&$ffff	;(Zero)
	stx	REG_A1T0L
	lda	#^HDMAFour
	sta	REG_A1B0
	stz	REG_DAS0L
	lda	#$12
	sta	REG_DAS0H
	lda	#$01
	sta	REG_MDMAEN

.skip	rts
;FOLD_END
;	VBR for the Introduction
;	Does Mode 7 Logo Wobble and Text Fade.
;FOLD_OUT
VBR__08	rep	#$30
	lda	Act_Object
	cmp	#$0f10
	beq	.shipit
	clc
	adc	#$0010
	sta	Act_Object
	cmp	#$0010
	bne	.shit
	sep	#$20
	jsr	.shiit
	jsr	.shiit
	rts
.shit	sep	#$20
	lda	#$2f
	sta	REG_HDMAEN
	xba
	sta	REG_INIDISP
	rts

.shipit	sep	#$20
	lda	#$3f
	sta	REG_HDMAEN			;Start H-DMA
.shiit	sep	#$20
	jsr	Intro_Put_Text
	jsr	RotateZoom		;Rotate Logo
	rep	#$30
	ldx	<Script_Poi
	jsr	(Intro_Effect,x)
.CreateZoomTab	stx	<L_X1Pos			;Create Table For 
	lda	#$00
	xba
	sep	#$20
	lda	>Sinus,x
	rol	a
	sta	REG_WRMPYB
	nop
	nop
	nop
	nop
	rol	REG_RDMPYL
	lda	REG_RDMPYH
	rep	#$20
	rol	a
	clc
	adc	<L_X1Pos
	sec
	sbc	<L_Incr2
	and	#$fffe
	tax
	lda	!DivsTab-$40,x		;+$48 fuer Normal Size
	sta	$1c00,y
	ldx	<L_X1Pos
	inx
	inx
	iny
	iny
	iny
	cpy	#180*3
	bne	.CreateZoomTab
	sep	#$20
	rts

	Mode	A8X16
Intro_Put_Text	lda	#$70			;Put Colors for Playfield1
	sta	REG_CGADD
	stz	REG_MDMAEN
	lda	#$02
	sta	REG_DMAP7
	lda	#$22
	sta	REG_BBAD7
	rep	#$21
	lda	#Intro_Char_Colors&&$ffff
	adc	<Z_Add
	sta	REG_A1T7L
	sep	#$20
	lda	#^Intro_Char_Colors
	sta	REG_A1B7
	lda	#$10
	sta	REG_DAS7L
	stz	REG_DAS7H
	lda	#$80
	sta	REG_MDMAEN
	lda	#$60			;Put Colors for PlayField2
	sta	REG_CGADD
	stz	REG_MDMAEN
	lda	#$02
	sta	REG_DMAP7
	lda	#$22
	sta	REG_BBAD7
	rep	#$21
	lda	#Intro_Char_Colors&&$ffff
	adc	#$80
	sec
	sbc	<Z_Add
	sta	REG_A1T7L
	sep	#$20
	lda	#^Intro_Char_Colors
	sta	REG_A1B7
	lda	#$10
	sta	REG_DAS7L
	stz	REG_DAS7H
	lda	#$80
	sta	REG_MDMAEN
	stz	REG_CGADD			;Put Colors for Logo
	lda	#$02
	sta	REG_DMAP7
	lda	#$22
	sta	REG_BBAD7
	ldx	#Intro_Logo_Colors&&$ffff
	stx	REG_A1T7L
	lda	#^Intro_Logo_Colors
	sta	REG_A1B7
	lda	#$c0
	sta	REG_DAS7L
	stz	REG_DAS7H
	lda	#$80
	sta	REG_MDMAEN

	rep	#$30
	lda	<Y_Add			;Text Delay Counter
	and	#$7ff
	inc	a
	sta	<Y_Add
	cmp	#$0003
	bcs	.Not_First

	ldx	#$60e0
	stx	REG_VMADDL
	ldx	<L_OraVal
	ldy	#$0000
	sep	#$20
	lda	#$80
	sta	REG_VMAIN
.Init_10	lda	#$00			;Put Text to First Playfield
	xba
	lda	!Test_Text,x
	inx
	phx
	tax
	lda	>Intro_Char_ASCII,x
	rep	#$21
	rol	a
	ora	#$1800
	sep	#$20
	sta	REG_VMDATAL
	xba
	sta	REG_VMDATAH
	plx
	iny
	cpy	#$10
	bne	.Init_10
	ldx	#$6100
	stx	REG_VMADDL
	ldx	<L_OraVal
	ldy	#$0000
.Init_11	lda	#$00			;Second Line
	xba
	lda	!Test_Text,x
	inx
	phx
	tax
	lda	>Intro_Char_ASCII,x
	rep	#$21
	rol	a
	clc
	adc	#$20
	ora	#$1800
	sep	#$20
	sta	REG_VMDATAL
	xba
	sta	REG_VMDATAH
	plx
	iny
	cpy	#$10
	bne	.Init_11
.Exit1	rts

	Mode	A16X16
.Not_First	cmp	#$40
	bcc	.Exit1
	cmp	#$7f
	bcs	.Not_FadeIn1
	and	#$0007
	bne	.skiop
	lda	<Z_Add
	clc
	adc	#$10
	sta	<Z_Add
.skiop	sep	#$20
	rts

	Mode	A16X16
.Not_FadeIn1	cmp	#$80
	bcs	.Not_Second
	sep	#$20
	lda	#$80
	sta	REG_VMAIN
	ldx	#$64e0
	stx	REG_VMADDL
	ldx	<L_OraVal
	ldy	#$0000
.Init_12	lda	#$00			;Put Text to Second Playfield
	xba
	lda	!Test_Text+$10,x
	inx
	phx
	tax
	lda	>Intro_Char_ASCII,x
	rep	#$21
	rol	a
	ora	#$1c00
	sep	#$20
	sta	REG_VMDATAL
	xba
	sta	REG_VMDATAH
	plx
	iny
	cpy	#$10
	bne	.Init_12
	ldx	#$6500
	stx	REG_VMADDL
	ldx	<L_OraVal
	ldy	#$0000
.Init_13	lda	#$00			;Second Line
	xba
	lda	!Test_Text+$10,x
	inx
	phx
	tax
	lda	>Intro_Char_ASCII,x
	rep	#$21
	rol	a
	clc
	adc	#$20
	ora	#$1c00
	sep	#$20
	sta	REG_VMDATAL
	xba
	sta	REG_VMDATAH
	plx
	iny
	cpy	#$10
	bne	.Init_13
.Exit2	rts
	Mode	A16X16
.Not_Second	cmp	#$bf
	bcc	.Exit2
	and	#$0007
	bne	.skioop
	lda	<Z_Add
	sec
	sbc	#$10
	bpl	.skiip

	lda	<L_OraVal
	clc
	adc	#$20
	cmp	#$0100
	bne	.Not_next_Part

	ldx	#$000f
	stx	<Dummy_Sin
.Not_next_Part	sta	<L_OraVal
	lda	#$0000
	sta	<Y_Add
.skiip	sta	<Z_Add
.skioop	sep	#$20
	rep	#$10
	rts



	Mode	A16X16
Intro_Effect	.word	Intro_Zoom_In
	.word	Intro_Rotate
	.word	Intro_Wobble
	.word	Intro_Fade_Out

Intro_Zoom_In	lda	<Script_Next
	inc	a
	cmp	#$100
	bne	.ship
	inc	<Script_Poi
	inc	<Script_Poi
	lda	#$0000
.ship	sta	<Script_Next
	sep	#$20
	ldy	#$0000
	lda	<L_DeltaX			;How Big Sinus is for Tab
	sta	REG_WRMPYA
	rep	#$21
	lda	<L_Incr2
	sbc	#$01		;adc	#$06
	and	#$1fe
	sta	<L_Incr2
	asl	a
	asl	a
	tax
	sep	#$20
	rts
	Mode	A16X16
Intro_Rotate	lda	<Script_Next
	inc	a
	cmp	#$200
	bne	.ship
	inc	<Script_Poi
	inc	<Script_Poi
	lda	#$0000
.ship	sta	<Script_Next
	sep	#$20
	ldy	#$0000
	inc	<L_Incr1			;Increase Rot Angle
	lda	<L_DeltaX			;How Big Sinus is for Tab
	sta	REG_WRMPYA
	rep	#$21
	lda	<L_Incr2
	adc	#$06
	and	#$1fe
	sta	<L_Incr2
	tax
	sep	#$20
	rts
Intro_Wobble	sep	#$20
	ldy	#$0000
	inc	<L_Incr1			;Increase Rot Angle
	lda	<L_DeltaX			;How Big Sinus is for Tab
	sta	REG_WRMPYA
	inc	<L_DeltaX
	bne	.skip
	dec	<L_DeltaX
.skip	rep	#$21
	lda	<L_Incr2
	adc	#$06
	and	#$1fe
	sta	<L_Incr2
	tax
	sep	#$20
	rts
Intro_Fade_Out	rts

RotateZoom	sep	#$20
	lda	<L_Incr1			;Rotation Counter
	rep	#$31
	rol	a
	rol	a
	rol	a
	and 	#$07fe
	tax
	sep	#$20
	lda	!sinus+512+1,x
	sta	<L_X2Pos
	lda	!sinus+1,x
	sta	<L_X2Pos+1
	ldy	#$0000
	rep	#$20
.rot1	lda	$1c00,y			;Zoom Adder
	sep	#$20
	sta	REG_M7A
	xba
	sta	REG_M7A

	lda	<L_X2Pos
	sta	REG_M7B
	rep	#$20
	lda	REG_MPYM
	sta	$1001,y

	sep	#$20
	lda	<L_X2Pos+1
	sta	REG_M7B
	rep	#$20
	lda	REG_MPYM

	sta	$1401,y
	eor	#$ffff
	inc	a
	sta	$1801,y
	iny
	iny
	iny
	cpy	#3*160
	bne	.rot1
	sep	#$20
	rts
;FOLD_END
;	VBR for the Picture Part
;	Not yet Implanted ...
;FOLD_OUT
VBR__09	rts
;FOLD_END
;

;	*************************************************
;	*** Main Sub-Routines for each Part (NON-VBR) ***
;	*************************************************

;	Sub-Routines for Part 1 (Filled Vektor Objects)
;	Including:
;		1) Rotate Points From Pointstrukture (3D) to WRAM (2D Coords)
;		2) Draw Object (Hidden Faces,Line Draw Routines)
;		3) Fill the Buffer in 2 Planes
;	Rotate Points around all 3 Axis
;FOLD_OUT
Rot_Points	php
	rep	#$30
	ldx	!OBuf_RotX	;Change X-Rotation Angle
	ldy	!sinus,x
	sty	!OBuf_XSin	;Sinus(Rot_X)
	ldy	!sinus+512,x
	sty	!OBuf_XCos	;Cosine(Rot_X)
	ldx	!OBuf_RotZ	;Change Z-Rotation Angle
	ldy	!sinus,x
	sty	!OBuf_ZSin	;Sinus(Rot_Z)
	ldy	!sinus+512,x
	sty	!OBuf_ZCos	;Cosine(Rot_Z)
	ldx	!OBuf_RotY	;Change Y-Rotation Angle
	ldy	!sinus,x
	sty	!OBuf_YSin	;Sinus(Rot_Y)
	ldy	!sinus+512,x
	sty	!OBuf_YCos	;Cosine(Rot_Y)
	sep	#$30
	ldy	#$00
	ldx	!OBuf_XSin	;Get LSB of Sin(Rot_X)
.RotX_Loop	stx	REG_M7A
	lda	!OBuf_XSin+1	;Get MSB of Sin(Rot_X)
	sta	REG_M7A
	iny
	lda	(Drw_PoiPoi),y	;Get Y-Position
	pha
	sta	REG_M7B
	rol	REG_MPYM
	lda	REG_MPYH		;Read Result (MSB of Y*sin(Rot_X)) [2's Complement]
	rol	a
	sta	Rot_Dummy1
	iny
	lda	(Drw_PoiPoi),y	;Get Z-Position
	pha
	sta	REG_M7B
	rol	REG_MPYM
	lda	REG_MPYH		;Read Result (MSB of Z*sin(Rot_X)) [2's Complement]
	rol	a
	eor	#$ff
	inc	a
	sta	Rot_Dummy2
	lda	!OBuf_XCos	;Get LSB of Cos(Rot_X)
	sta	REG_M7A
	lda	!OBuf_XCos+1	;Get MSB of Cos(Rot_X)
	sta	REG_M7A
	pla			;Get Z-Position
	sta	REG_M7B
	rol	REG_MPYM
	lda	REG_MPYH		;Read Result (MSB of z*cos(Rot_X)) [2's Complement]
	rol	a
	clc
	adc	Rot_Dummy1
	sta	!OBuf_RotPts-1,y	;NEW Y-Pos!
	pla			;Get Y-Position
	sta	REG_M7B
	rol	REG_MPYM
	lda	REG_MPYH		;Read Result (MSB of y*cos(Rot_X)) [2's Complement]
	rol	a
	clc
	adc	Rot_Dummy2
	sta	!OBuf_RotPts,y	;NEW Z-Pos!
	iny
	cpy	!OBuf_Points
	bne	.RotX_Loop

	ldy	#$00
	ldx	!OBuf_YSin	;Get LSB of Sin(Rot_Y)
.RotY_Loop	stx	REG_M7A
	lda	!OBuf_YSin+1	;Get MSB of Sin(Rot_Y)
	sta	REG_M7A
	lda	(Drw_PoiPoi),y	;Get X-Position
	pha
	sta	REG_M7B
	rol	REG_MPYM
	lda	REG_MPYH		;Read Result (MSB of X*sin(Rot_Y)) [2's Complement]
	rol	a
	sta	Rot_Dummy1
	lda	!OBuf_RotPts+2,y	;Get Z-Position
	pha
	sta	REG_M7B
	rol	REG_MPYM
	lda	REG_MPYH		;Read Result (MSB of Z*sin(Rot_Y)) [2's Complement]
	rol	a
	eor	#$ff
	inc	a
	sta	Rot_Dummy2
	lda	!OBuf_YCos	;Get LSB of Cos(Rot_Y)
	sta	REG_M7A
	lda	!OBuf_YCos+1	;Get MSB of Cos(Rot_Y)
	sta	REG_M7A
	pla			;Get Z-Position
	sta	REG_M7B
	rol	REG_MPYM
	lda	REG_MPYH		;Read Result (MSB of z*cos(Rot_Y)) [2's Complement]
	rol	a
	clc
	adc	Rot_Dummy1
	sta	!OBuf_RotPts,y	;NEW X-Pos!
	pla			;Get X-Position
	sta	REG_M7B
	rol	REG_MPYM
	lda	REG_MPYH		;Read Result (MSB of X*cos(Rot_Y)) [2's Complement]
	rol	a
	clc
	adc	Rot_Dummy2
	sta	!OBuf_RotPts+2,y	;NEW Z-Pos!
	iny
	iny
	iny
	cpy	!OBuf_Points
	bne	.RotY_Loop

	ldy	#$00
.RotZ_Loop	lda	!OBuf_ZSin	;Get LSB of Sin(Rot_Z)
	sta	REG_M7A
	lda	!OBuf_ZSin+1	;Get MSB of Sin(Rot_Z)
	sta	REG_M7A
	lda	!OBuf_RotPts,y	;Get X-Position
	pha
	sta	REG_M7B
	rol	REG_MPYM
	lda	REG_MPYH		;Read Result (MSB of x*sin(Rot_Z)) [2's Complement]
	rol	a
	sta	Rot_Dummy1
	lda	!OBuf_RotPts+1,y	;Get Y-Position
	pha
	sta	REG_M7B
	rol	REG_MPYM
	lda	REG_MPYH		;Read Result (MSB of y*sin(Rot_Z)) [2's Complement]
	rol	a
	eor	#$ff
	inc	a
	sta	Rot_Dummy2
	lda	!OBuf_ZCos	;Get LSB of Cos(Rot_Z)
	sta	REG_M7A
	lda	!OBuf_ZCos+1	;Get MSB of Cos(Rot_Z)
	sta	REG_M7A
	pla			;Get Y-Position
	sta	REG_M7B
	rol	REG_MPYM
	lda	REG_MPYH		;Read Result (MSB of y*cos(Rot_Z)) [2's Complement]
	rol	a
	clc
	adc	Rot_Dummy1
	sta	!OBuf_RotPts,y	;NEW X-Pos!
	pla			;Get X-Position
	sta	REG_M7B
	rol	REG_MPYM
	lda	REG_MPYH		;Read Result (MSB of x*cos(Rot_Z)) [2's Complement]
	rol	a
	clc
	adc	Rot_Dummy2
	sta	!OBuf_RotPts+1,y	;NEW Y-Pos!

	lda	#$00
	xba
	lda	!OBuf_RotPts+2,y	;Get Z-Position
	bpl	.skip1
	xba
	lda	#$ff
	xba
.skip1	rep	#$30
	clc
	adc	!OBuf_Dist
	asl	a
	tax
	lda	!DivsTab,x
	sep	#$30
	sta	REG_M7A		;Do Central Perspektive
	xba
	sta	REG_M7A
	lda	!OBuf_RotPts,y
	sta	REG_M7B
	lda	REG_MPYM
	clc
	adc	#104
	sta	!OBuf_RotPts,y	;Store 2D-X-Coordinate	[BYTE]
	lda	!OBuf_RotPts+1,y
	sta	REG_M7B
	lda	REG_MPYM
	clc
	adc	#104
	sta	!OBuf_RotPts+1,y	;Store 2D-Y-Coordinate	[BYTE]
	iny
	iny
	iny
	cpy	!OBuf_Points
	beq	.RotZ_Quit
	jmp	.RotZ_Loop
.RotZ_Quit	plp
	rts
;FOLD_END
;	Draw Object Routine (Hidden Lines)
;FOLD_OUT
Draw_Objekt	php
	rep	#$30
	ldy	#$0004
	lda	(Act_Object),y	;INITS
	sta	OBuf_Faces		;Number of Surfaces in Object
	lda	Act_Object		;Pointer to Surface List
	clc
	adc	#$0006
	sta	Drw_Face		;EO INITS


FaceLoop1	lda	(Drw_Face)		;Store Adress of Surface
	sta	Drw_Dummy
	inc	Drw_Face
	inc	Drw_Face
	lda	(Drw_Face)		;Store Number of Lines
	sta	OBuf_Lines
	inc	Drw_Face
	inc	Drw_Face
	lda	(Drw_Face)		;Store Color of Surface
	sta	OBuf_Color
	inc	Drw_Face
	inc	Drw_Face		;Set Pointer to next Surface


.HiddenLine	ldy	#$0002		;Check wether Surface is visible or NOT!
	lda	(Drw_Dummy),y
	tax
	sep	#$20
	lda	OBuf_RotPts,x	;x1

	clc
	ror	a

	rep	#$20
	sta	L_X1Pos
	sep	#$20
	lda	OBuf_RotPts+1,x	;y1

	clc
	ror	a

	rep	#$20
	sta	L_Y1Pos
	iny
	iny
	lda	(Drw_Dummy),y
	tax
	sep	#$20
	lda	OBuf_RotPts,x	;x2

	clc
	ror	a

	rep	#$20
	sec
	sbc	L_X1Pos
	sta	L_X2Pos		;x2-x1
	sep	#$20
	lda	OBuf_RotPts+1,x	;y2

	clc
	ror	a

	rep	#$20
	sec
	sbc	L_Y1Pos
	sta	L_Y2Pos		;y2-y1
	iny
	iny
	iny
	iny
	iny
	iny
	lda	(Drw_Dummy),y
	tax

	sep	#$20
	lda	OBuf_RotPts,x

	clc
	ror	a
	rep	#$20		;x3
	sec
	sbc	L_X1Pos
	sta	L_X1Pos		;x3-x1
	sep	#$20
	lda	OBuf_RotPts+1,x	;y3

	clc
	ror	a

	rep	#$20
	sec
	sbc	L_Y1Pos
	sta	L_Y1Pos		;y3-y1
	sep	#$20
	lda	L_X1Pos
	sta	REG_M7A
	lda	L_X1Pos+1
	sta	REG_M7A
	lda	L_Y2Pos
	sta	REG_M7B
	ldx	REG_MPYL		;(y2-y1)*(x3-x1)
	stx	L_X1Pos
	lda	L_X2Pos
	sta	REG_M7A
	lda	L_X2Pos+1
	sta	REG_M7A
	lda	L_Y1Pos
	sta	REG_M7B
	rep	#$20
	lda	REG_MPYL		;(y3-y1)*(x2-x1)
	sec
	sbc	L_X1Pos
	bpl	skipFace1		;(y3-y1)*(x2-x1)-(y2-y1)*(x3-x1)

	ldy	#$0000
LineLoop	iny			;Else get Point One
	iny
	lda	(Drw_Dummy),y
	iny
	iny
	phy
	tay
	sep	#$20
	lda	OBuf_RotPts,y	;and Store X
	rep	#$20
	sta	L_X1Pos
	iny
	sep	#$20
	lda	OBuf_RotPts,y
	rep	#$20
	sta	L_Y1Pos		;and Y Position
	ply
	lda	(Drw_Dummy),y	;and get Point Two
	iny
	iny
	phy
	tay
	sep	#$20
	lda	OBuf_RotPts,y
	rep	#$20
	sta	L_X2Pos		;Store X
	iny
	sep	#$20
	lda	OBuf_RotPts,y
	rep	#$20
	sta	L_Y2Pos		;and Y Position

	jmp	(OBuf_Color)	;and Draw the Line

Continue	ply
LineLoop2	dec	OBuf_Lines	;Do Next Line
	bne	LineLoop
skipFace1	dec	OBuf_Faces
	bmi	.out
	jmp	FaceLoop1
.out	plp
	rts
;FOLD_END
;	DRAW a LINE with 65816 and SNES			 |[ P2 is Somewhere here]
;							 |
;	x1 in $7c [W]					 | 3  /
;	y1 in $7e [W]			 	Swap P1	 |   /
;	x2 in $78 [W]			 	and P2 	 |  /
;	y2 in $7a [W]					 | /  Okt 2
;							 |/
;	Delta X will be stored at $80		---- P1->+------------
;	Delta Y will be stored at $82			 |\
;	Incr1 will be stored at	 $84		 Swap P1 | \
;	Incr2 will be stored at	 $86	 	 and P2  |  \ Okt 0
;	Dummy Pointer at		 $88			 |   \
;							 | 1  \
;	DRAW_LINE1 Draws a Line To Plane 1 Only
;	DRAW_LINE2 Draws a Line To Plane 2 Only
;	DRAW_LINE3 Draws a Line To Plane 1&2
;	Draw Line in Color 1:
;FOLD_OUT
Draw_Line1	lda	L_X2Pos
	sec
	sbc	L_X1Pos		;Delta x
	bpl	.Okt0123
.Okt4567	eor	#$ffff
	inc	a
	ldx	L_X2Pos
	ldy	L_X1Pos
	sty	L_X2Pos
	stx	L_X1Pos
	ldx	L_Y2Pos
	ldy	L_Y1Pos
	sty	L_Y2Pos
	stx	L_Y1Pos
.Okt0123	sta	L_DeltaX
	lda	L_Y2Pos
	sec
	sbc	L_Y1Pos		;Delta y
	bmi	.Okt23
.Okt01	sta	L_DeltaY
	cmp	L_DeltaX
	bcc	.Okt0
.Okt1	lda	L_DeltaX
	asl	a
	sta	L_Incr1		;Incr1=2*dY
	jmp	Okt1
.Okt0	asl	a
	sta	L_Incr1		;Incr1=2*dY
	jmp	Okt0
.Okt23	eor	#$ffff
	inc	a
	sta	L_DeltaY
	cmp	L_DeltaX
	bcc	.Okt2
.Okt3	lda	L_DeltaX
	asl	a
	sta	L_Incr1		;Incr1=2*dY
	jmp	Okt3
.Okt2	asl	a
	sta	L_Incr1		;Incr1=2*dY
	jmp	Okt2


Okt0	ldx	L_X1Pos		;Oktant 0
	ldy	L_Y1Pos
	txa
	sep	#$30
	pha
	lsr	a
	lsr	a
	and	#$3e
	tax
	rep	#$21
	lda	!Mulu_Tab,x
	adc	Act_Buffer
	adc	L_Y1Pos
	sta	L_Dummy
	sep	#$20
	plx
	lda	!OR_Table,x
	sta	L_OraVal		;Precalculate OR Mask and Screen Offset
	lda	#$7e
	pha
	plb
	rep	#$30
	lda	L_DeltaY
	sec
	sbc	L_DeltaX
	asl	a
	sta	L_Incr2		;Incr2=2*(dY-dX)

.loop	cpx	L_X2Pos
	bcs	.finished		;WHILE X<dX
	pha			;Plot (A,Y)
	sep	#$20
	lda	L_OraVal
	eor	(L_Dummy),y
	sta	(L_Dummy),y
	inx			;X=X+1
	ror	L_OraVal
	bcc	.skip
	ror	L_OraVal
	rep	#$21
	lda	#$01a0
	adc	L_Dummy
	sta	L_Dummy
.skip	rep	#$31
	pla			;IF D<0
	bpl	.incY
	adc	L_Incr1		;THEN D=D+Incr1
	bra	.loop
.incY	iny
	iny			;ELSE {Y=Y+1;D=D+Incr2}
	adc	L_Incr2
	bra	.loop
.finished	phk
	plb
	jmp	Continue


Okt1	lda	L_X1Pos		;X=L_X1Pos
	ldy	L_Y1Pos		;Y=L_Y1Pos
	sep	#$30
	pha
	lsr	a
	lsr	a
	and	#$3e
	tax
	rep	#$21
	lda	!Mulu_Tab,x
	adc	Act_Buffer
	adc	L_Y1Pos
	sta	L_Dummy
	sep	#$20
	plx
	lda	!OR_Table,x
	sta	L_OraVal
	lda	#$7e
	pha
	plb

	rep	#$30
	lda	L_DeltaX
	sec
	sbc	L_DeltaY
	asl	a
	sta	L_Incr2		;Incr2=2*(dY-dX)

.loop	cpy	L_Y2Pos
	bcs	.finished		;WHILE Y<dY
	inc	L_Dummy
	iny			;Y=Y+1
	bit	#$8000
	bne	.incY		;IF D<0
	pha
	sep	#$20
	lda	L_OraVal
	eor	(L_Dummy),y
	sta	(L_Dummy),y
	ror	L_OraVal
	bcc	.skip
	ror	L_OraVal
	rep	#$21
	lda	#$01a0
	adc	L_Dummy
	sta	L_Dummy
.skip	rep	#$21
	pla
	adc	L_Incr2		;ELSE {X=X+1;D=D+Incr2}
	bra	.loop
.incY	adc	L_Incr1		;THEN D=D+Incr1
	bra	.loop
.finished	phk
	plb
	jmp	Continue


Okt2	rep	#$30			;315 to 360 Degrees
	ldx	L_X1Pos		;X=0
	ldy	L_Y1Pos		;Y=0
	txa
	sep	#$30
	pha
	lsr	a
	lsr	a
	and	#$3e
	tax
	rep	#$21
	lda	!Mulu_Tab,x
	adc	Act_Buffer
	adc	L_Y1Pos
	sta	L_Dummy
	sep	#$20
	plx
	lda	!OR_Table,x
	sta	L_OraVal
	lda	#$7e
	pha
	plb
	rep	#$30
	lda	L_DeltaY
	sec
	sbc	L_DeltaX
	asl	a
	sta	L_Incr2		;Incr2=2*(dY-dX)

.loop	cpx	L_X2Pos
	bcs	.finished		;WHILE X<dX
	pha			;Plot (A,Y)
	sep	#$20
	lda	L_OraVal
	eor	(L_Dummy),y
	sta	(L_Dummy),y
	inx			;X=X+1
	ror	L_OraVal
	bcc	.skip
	ror	L_OraVal
	rep	#$21
	lda	#$01a0
	adc	L_Dummy
	sta	L_Dummy
.skip	rep	#$31
	pla			;IF D<0
	bpl	.incY
	adc	L_Incr1		;THEN D=D+Incr1
	bra	.loop
.incY	adc	L_Incr2
	dec	L_Dummy
	dey			;ELSE {Y=Y+1;D=D+Incr2}
	bra	.loop
.finished	phk
	plb
	jmp	Continue


Okt3	rep	#$30			;270 to 315 Degrees
	lda	L_X1Pos		;X=L_X1Pos
	ldy	L_Y1Pos		;Y=L_Y1Pos
	sep	#$30
	pha
	lsr	a
	lsr	a
	and	#$3e
	tax
	rep	#$21
	lda	!Mulu_Tab,x
	adc	Act_Buffer
	adc	L_Y1Pos
	sta	L_Dummy
	sep	#$20
	plx
	lda	!OR_Table,x
	sta	L_OraVal
	lda	#$7e
	pha
	plb
	rep	#$30
	lda	L_DeltaX
	sec
	sbc	L_DeltaY
	asl	a
	sta	L_Incr2		;Incr2=2*(dY-dX)
	inc	L_Y2Pos

.loop	cpy	L_Y2Pos
	bcc	.finished		;WHILE Y<dY
	dec	L_Dummy
	dey			;Y=Y+1
	bit	#$8000
	bne	.incY		;IF D<0
	inx
	pha
	sep	#$20
	lda	L_OraVal
	eor	(L_Dummy),y
	sta	(L_Dummy),y
	clc
	ror	L_OraVal
	bcc	.skip
	ror	L_OraVal
	rep	#$21
	lda	#$01a0
	adc	L_Dummy
	sta	L_Dummy
.skip	rep	#$21
	pla
	adc	L_Incr2		;ELSE {X=X+1;D=D+Incr2}
	bra	.loop
.incY	clc
	adc	L_Incr1		;THEN D=D+Incr1
	bra	.loop
.finished	phk
	plb
	jmp	Continue
;FOLD_END
;	Draw Line in Color 2:
;FOLD_OUT
Draw_Line2	lda	L_X2Pos
	sec
	sbc	L_X1Pos		;Delta x
	bpl	.Okt0123
.Okt4567	eor	#$ffff
	inc	a
	ldx	L_X2Pos
	ldy	L_X1Pos
	sty	L_X2Pos
	stx	L_X1Pos
	ldx	L_Y2Pos
	ldy	L_Y1Pos
	sty	L_Y2Pos
	stx	L_Y1Pos
.Okt0123	sta	L_DeltaX
	lda	L_Y2Pos
	sec
	sbc	L_Y1Pos		;Delta y
	bmi	.Okt23
.Okt01	sta	L_DeltaY
	cmp	L_DeltaX
	bcc	.Okt0
.Okt1	lda	L_DeltaX
	asl	a
	sta	L_Incr1		;Incr1=2*dY
	jmp	Okt21
.Okt0	asl	a
	sta	L_Incr1		;Incr1=2*dY
	jmp	Okt20
.Okt23	eor	#$ffff
	inc	a
	sta	L_DeltaY
	cmp	L_DeltaX
	bcc	.Okt2
.Okt3	lda	L_DeltaX
	asl	a
	sta	L_Incr1		;Incr1=2*dY
	jmp	Okt23
.Okt2	asl	a
	sta	L_Incr1		;Incr1=2*dY
	jmp	Okt22


Okt20	ldx	L_X1Pos
	ldy	L_Y1Pos
	txa
	sep	#$30
	pha
	lsr	a
	lsr	a
	and	#$3e
	tax
	rep	#$20
	lda	!Mulu_Tab,x
	sec
	adc	Act_Buffer
	adc	L_Y1Pos
	sta	L_Dummy

	sep	#$20
	plx
	lda	!OR_Table,x
	sta	L_OraVal
	lda	#$7e
	pha
	plb
	rep	#$30
	lda	L_DeltaY
	sec
	sbc	L_DeltaX
	asl	a
	sta	L_Incr2		;Incr2=2*(dY-dX)

.loop	cpx	L_X2Pos
	bcs	.finished		;WHILE X<dX
	pha			;Plot (A,Y)
	sep	#$20
	lda	L_OraVal
	eor	(L_Dummy),y
	sta	(L_Dummy),y
	inx			;X=X+1
	ror	L_OraVal
	bcc	.skip
	ror	L_OraVal
	rep	#$21
	lda	#$01a0
	adc	L_Dummy
	sta	L_Dummy
.skip	rep	#$31
	pla			;IF D<0
	bpl	.incY
	adc	L_Incr1		;THEN D=D+Incr1
	bra	.loop
.incY	iny
	iny			;ELSE {Y=Y+1;D=D+Incr2}
	adc	L_Incr2
	bra	.loop
.finished	phk
	plb
	jmp	Continue


Okt21	lda	L_X1Pos		;X=L_X1Pos
	ldy	L_Y1Pos		;Y=L_Y1Pos
	sep	#$30
	pha
	lsr	a
	lsr	a
	and	#$3e
	tax
	rep	#$20
	lda	!Mulu_Tab,x
	sec
	adc	Act_Buffer
	adc	L_Y1Pos
	sta	L_Dummy
	sep	#$20
	plx
	lda	!OR_Table,x
	sta	L_OraVal
	lda	#$7e
	pha
	plb

	rep	#$30
	lda	L_DeltaX
	sec
	sbc	L_DeltaY
	asl	a
	sta	L_Incr2		;Incr2=2*(dY-dX)

.loop	cpy	L_Y2Pos
	bcs	.finished		;WHILE Y<dY
	inc	L_Dummy
	iny			;Y=Y+1
	bit	#$8000
	bne	.incY		;IF D<0
	pha
	sep	#$20
	lda	L_OraVal
	eor	(L_Dummy),y
	sta	(L_Dummy),y
	ror	L_OraVal
	bcc	.skip
	ror	L_OraVal
	rep	#$21
	lda	#$01a0
	adc	L_Dummy
	sta	L_Dummy

.skip	rep	#$21
	pla
	adc	L_Incr2		;ELSE {X=X+1;D=D+Incr2}
	bra	.loop

.incY	adc	L_Incr1		;THEN D=D+Incr1
	bra	.loop
.finished	phk
	plb
	jmp	Continue


Okt22	rep	#$30			;315 to 360 Degrees
	ldx	L_X1Pos		;X=0
	ldy	L_Y1Pos		;Y=0
	txa
	sep	#$30
	pha
	lsr	a
	lsr	a
	and	#$3e
	tax
	rep	#$20
	lda	!Mulu_Tab,x
	sec
	adc	Act_Buffer
	adc	L_Y1Pos
	sta	L_Dummy
	sep	#$20
	plx
	lda	!OR_Table,x
	sta	L_OraVal
	lda	#$7e
	pha
	plb
	rep	#$30


	lda	L_DeltaY
	sec
	sbc	L_DeltaX
	asl	a
	sta	L_Incr2		;Incr2=2*(dY-dX)

.loop	cpx	L_X2Pos
	bcs	.finished		;WHILE X<dX
	pha			;Plot (A,Y)
	sep	#$20
	lda	L_OraVal
	eor	(L_Dummy),y
	sta	(L_Dummy),y
	inx			;X=X+1
	ror	L_OraVal
	bcc	.skip
	ror	L_OraVal
	rep	#$21
	lda	#$01a0
	adc	L_Dummy
	sta	L_Dummy
.skip	rep	#$31
	pla			;IF D<0
	bpl	.incY
	adc	L_Incr1		;THEN D=D+Incr1
	bra	.loop
.incY	dec	L_Dummy
	dey			;ELSE {Y=Y+1;D=D+Incr2}
	adc	L_Incr2
	bra	.loop
.finished	phk
	plb
	jmp	Continue


Okt23	rep	#$30			;270 to 315 Degrees
	lda	L_X1Pos		;X=L_X1Pos
	ldy	L_Y1Pos		;Y=L_Y1Pos
	sep	#$30
	pha
	lsr	a
	lsr	a
	and	#$3e
	tax
	rep	#$20
	lda	!Mulu_Tab,x
	sec
	adc	Act_Buffer
	adc	L_Y1Pos

	sta	L_Dummy
	sep	#$20
	plx
	lda	!OR_Table,x
	sta	L_OraVal
	lda	#$7e
	pha
	plb
	rep	#$30
	lda	L_DeltaX
	sec
	sbc	L_DeltaY
	asl	a
	sta	L_Incr2		;Incr2=2*(dY-dX)

	inc	L_Y2Pos

.loop	cpy	L_Y2Pos
	bcc	.finished		;WHILE Y<dY
	dec	L_Dummy
	dey			;Y=Y+1
	bit	#$8000
	bne	.incY		;IF D<0
	inx
	pha
	sep	#$20
	lda	L_OraVal
	eor	(L_Dummy),y
	sta	(L_Dummy),y
	clc
	ror	L_OraVal
	bcc	.skip
	ror	L_OraVal
	rep	#$21
	lda	#$01a0
	adc	L_Dummy
	sta	L_Dummy
.skip	rep	#$21
	pla
	adc	L_Incr2		;ELSE {X=X+1;D=D+Incr2}
	bra	.loop
.incY	clc
	adc	L_Incr1		;THEN D=D+Incr1
	bra	.loop
.finished	phk
	plb
	jmp	Continue
;FOLD_END
;	Draw Line in Color 3:
;FOLD_OUT
Draw_Line3	lda	L_X2Pos
	sec
	sbc	L_X1Pos		;Delta x
	bpl	.Okt0123

.Okt4567	eor	#$ffff
	inc	a
	ldx	L_X2Pos
	ldy	L_X1Pos
	sty	L_X2Pos
	stx	L_X1Pos
	ldx	L_Y2Pos
	ldy	L_Y1Pos
	sty	L_Y2Pos
	stx	L_Y1Pos
.Okt0123	sta	L_DeltaX
	lda	L_Y2Pos
	sec
	sbc	L_Y1Pos		;Delta y
	bmi	.Okt23
.Okt01	sta	L_DeltaY
	cmp	L_DeltaX
	bcc	.Okt0
.Okt1	lda	L_DeltaX
	asl	a
	sta	L_Incr1		;Incr1=2*dY
	jmp	Okt31
.Okt0	asl	a
	sta	L_Incr1		;Incr1=2*dY
	jmp	Okt30
.Okt23	eor	#$ffff
	inc	a
	sta	L_DeltaY
	cmp	L_DeltaX
	bcc	.Okt2
.Okt3	lda	L_DeltaX
	asl	a
	sta	L_Incr1		;Incr1=2*dY
	jmp	Okt33
.Okt2	asl	a
	sta	L_Incr1		;Incr1=2*dY
	jmp	Okt32


Okt30	ldx	L_X1Pos
	ldy	L_Y1Pos
	txa
	sep	#$30
	pha
	lsr	a
	lsr	a
	and	#$3e
	tax
	rep	#$21
	lda	!Mulu_Tab,x
	adc	Act_Buffer
	adc	L_Y1Pos
	sta	L_Dummy

	sep	#$20
	plx
	lda	!OR_Table,x
	sta	L_OraVal
	lda	#$7e
	pha
	plb
	rep	#$30
	lda	L_DeltaY
	sec
	sbc	L_DeltaX
	asl	a
	sta	L_Incr2		;Incr2=2*(dY-dX)

.loop	cpx	L_X2Pos
	bcs	.finished		;WHILE X<dX
	pha			;Plot (A,Y)
	sep	#$20
	lda	L_OraVal
	pha
	eor	(L_Dummy),y
	sta	(L_Dummy),y
	pla
	iny
	eor	(L_Dummy),y
	sta	(L_Dummy),y
	dey
	inx			;X=X+1
	ror	L_OraVal
	bcc	.skip
	ror	L_OraVal
	rep	#$21
	lda	#$01a0
	adc	L_Dummy
	sta	L_Dummy
.skip	rep	#$31
	pla			;IF D<0
	bpl	.incY
	adc	L_Incr1		;THEN D=D+Incr1
	bra	.loop
.incY	iny
	iny			;ELSE {Y=Y+1;D=D+Incr2}
	adc	L_Incr2
	bra	.loop
.finished	phk
	plb
	jmp	Continue


Okt31	lda	L_X1Pos		;X=L_X1Pos
	ldy	L_Y1Pos		;Y=L_Y1Pos
	sep	#$30
	pha
	lsr	a
	lsr	a
	and	#$3e
	tax
	rep	#$21
	lda	!Mulu_Tab,x
	adc	Act_Buffer
	adc	L_Y1Pos
	sta	L_Dummy
	sep	#$20
	plx
	lda	!OR_Table,x
	sta	L_OraVal
	lda	#$7e
	pha
	plb

	rep	#$30
	lda	L_DeltaX
	sec
	sbc	L_DeltaY
	asl	a
	sta	L_Incr2		;Incr2=2*(dY-dX)
.loop	cpy	L_Y2Pos
	bcs	.finished		;WHILE Y<dY
	inc	L_Dummy
	iny			;Y=Y+1
	bit	#$8000
	bne	.incY		;IF D<0
	pha
	sep	#$20
	lda	L_OraVal
	pha
	eor	(L_Dummy),y
	sta	(L_Dummy),y
	pla
	iny
	eor	(L_Dummy),y
	sta	(L_Dummy),y
	dey
	ror	L_OraVal
	bcc	.skip
	ror	L_OraVal
	rep	#$21
	lda	#$01a0
	adc	L_Dummy
	sta	L_Dummy
.skip	rep	#$21
	pla
	adc	L_Incr2		;ELSE {X=X+1;D=D+Incr2}
	bra	.loop
.incY	adc	L_Incr1		;THEN D=D+Incr1
	bra	.loop

.finished	phk
	plb
	jmp	Continue


Okt32	rep	#$30			;315 to 360 Degrees
	ldx	L_X1Pos		;X=0
	ldy	L_Y1Pos		;Y=0
	txa
	sep	#$30
	pha
	lsr	a
	lsr	a
	and	#$3e
	tax
	rep	#$21
	lda	!Mulu_Tab,x
	adc	Act_Buffer
	adc	L_Y1Pos
	sta	L_Dummy
	sep	#$20
	plx
	lda	!OR_Table,x
	sta	L_OraVal
	lda	#$7e
	pha
	plb
	rep	#$30
	lda	L_DeltaY
	sec
	sbc	L_DeltaX
	asl	a
	sta	L_Incr2		;Incr2=2*(dY-dX)

.loop	cpx	L_X2Pos
	bcs	.finished		;WHILE X<dX
	pha			;Plot (A,Y)
	sep	#$20
	lda	L_OraVal
	pha
	eor	(L_Dummy),y
	sta	(L_Dummy),y
	pla
	iny
	eor	(L_Dummy),y
	sta	(L_Dummy),y
	dey

	inx			;X=X+1
	ror	L_OraVal
	bcc	.skip
	ror	L_OraVal
	rep	#$21
	lda	#$01a0
	adc	L_Dummy
	sta	L_Dummy
.skip	rep	#$31
	pla			;IF D<0
	bpl	.incY
	adc	L_Incr1		;THEN D=D+Incr1
	bra	.loop
.incY	dec	L_Dummy
	dey			;ELSE {Y=Y+1;D=D+Incr2}
	adc	L_Incr2
	bra	.loop
.finished	phk
	plb
	jmp	Continue


Okt33	rep	#$30			;270 to 315 Degrees
	lda	L_X1Pos		;X=L_X1Pos
	ldy	L_Y1Pos		;Y=L_Y1Pos
	sep	#$30
	pha
	lsr	a
	lsr	a
	and	#$3e
	tax
	rep	#$21
	lda	!Mulu_Tab,x
	adc	Act_Buffer
	adc	L_Y1Pos
	sta	L_Dummy
	sep	#$20
	plx
	lda	!OR_Table,x
	sta	L_OraVal
	lda	#$7e
	pha
	plb
	rep	#$30
	lda	L_DeltaX
	sec
	sbc	L_DeltaY
	asl	a
	sta	L_Incr2		;Incr2=2*(dY-dX)
	inc	L_Y2Pos
.loop	cpy	L_Y2Pos
	bcc	.finished		;WHILE Y<dY
	dec	L_Dummy
	dey			;Y=Y+1
	bit	#$8000
	bne	.incY		;IF D<0
	inx
	pha
	sep	#$20
	lda	L_OraVal
	pha
	eor	(L_Dummy),y
	sta	(L_Dummy),y
	iny
	pla
	eor	(L_Dummy),y
	sta	(L_Dummy),y
	dey
	clc
	ror	L_OraVal
	bcc	.skip
	ror	L_OraVal
	rep	#$21
	lda	#$01a0
	adc	L_Dummy
	sta	L_Dummy
.skip	rep	#$21
	pla
	adc	L_Incr2		;ELSE {X=X+1;D=D+Incr2}
	bra	.loop
.incY	clc
	adc	L_Incr1		;THEN D=D+Incr1
	bra	.loop
.finished	phk
	plb
	jmp	Continue
;FOLD_END
;	Fill the Buffer (filled Vektors)
;FOLD_OUT
fill	php
	sep	#$20
	lda	#$7e
	pha
	plb
	rep	#$31
	lda	Act_Buffer
	adc	#416
	tax
	ldy	#$0001
Fillloop	lda	#$0000
xy	set	0
	.repeat 207 {
	eor	!xy,x
	sta	!xy,x
xy	set	xy+2
	}
	txa
	clc
	adc	#416
	tax
	iny
	cpy	#25
	beq	.skip
	jmp	Fillloop
.skip	phk
	plb
	plp
	rts	
;FOLD_END
;	Script Routines for Filled Vector Part:
;	1) Init an Object (NAME,Z-Pos)
;	2) Rotate an Object (X_Add,Y_Add,Z_Add,Number of Frames)
;	3) Move Object (OBuf_Dist add,Number of Frames)
;	4) Script Warp (No Arguments) Restarts Script
;FOLD_OUT
Exec_Script	php
	rep	#$30
	ldx	<Script_Poi
	jsr	(!Script_Data,x)
	plp
	rts

Script_Init	ldy	#$0000			;(Init first Object)
	lda	!Script_Data+2,x
	sta	Act_Object
	lda	(Act_Object)
	sta	Drw_PoiPoi		;Object Point Structure
	iny
	iny
	lda	(Act_Object),y
	sta	OBuf_Points		;Number of Points to be rotated
	iny
	iny
	lda	(Act_Object),y
	sta	OBuf_Faces		;Number of Surfaces in Object
	lda	Act_Object
	clc
	adc	#$0006
	sta	Drw_Face			;Pointer to Surface List
	lda	!Script_Data+4,x
	sta	OBuf_Dist
	stz	X_Add
	stz	Y_Add
	stz	Z_Add
	stz	OBuf_RotX
	stz	OBuf_RotY
	stz	OBuf_RotZ
	txa
	clc
	adc	#$0006
	sta	Script_Poi
	rts

Script_Move	lda	Script_Next
	bne	.Not_First
	lda	!Script_Data+4,x
	sta	Script_Next
.Not_First	lda	!Script_Data+2,x
	clc
	adc	OBuf_Dist
	sta	OBuf_Dist
	dec	Script_Next
	bne	.NotFinishd
	txa
	clc
	adc	#$0006
	sta	Script_Poi
.NotFinishd	rts

Script_Rota	lda	Script_Next
	bne	.Not_First
	lda	!Script_Data+8,x
	sta	Script_Next
	lda	!Script_Data+2,x
	sta	X_Add
	lda	!Script_Data+4,x
	sta	Y_Add
	lda	!Script_Data+6,x
	sta	Z_Add
.Not_First	dec	Script_Next
	bne	.NotFinishd
	txa
	clc
	adc	#$000a
	sta	Script_Poi
.NotFinishd	rts

Script_Warp	ldx	#$0000
	stx	Script_Poi
	stx	Script_Next
	rts

Script_Data	.word	Script_Init,Object1,$0380			;Dice
	.word	Script_Rota,$c,$4,$8,$0002
	.word	Script_Move,-$0008,$60
	.word	Script_Rota,$c,$4,$8,$0080
	.word	Script_Move,$0008,$60

	.word	Script_Init,Object3,$0380			;Octaeder
	.word	Script_Rota,$a,$8,$c,$0002
	.word	Script_Move,-$0008,32*3
	.word	Script_Rota,$a,$8,$c,$0080
	.word	Script_Move,$0008,32*3

	.word	Script_Init,Object4,$0380			;Pyramid
	.word	Script_Rota,$8,$4,$c,$0002
	.word	Script_Move,-$0008,30*3
	.word	Script_Rota,$8,$4,$c,$0040
	.word	Script_Move,$0008,30*3

	.word	Script_Init,Object5,$0380			;SpaceShip
	.word	Script_Rota,$6,$4,$c,$0002
	.word	Script_Move,-$0008,32*3
	.word	Script_Rota,$6,$4,$c,$0080
	.word	Script_Move,$0008,32*3

	.word	Script_Init,Object2,$0380			:Cheese
	.word	Script_Rota,$8,$4,$c,$0002
	.word	Script_Move,-$0008,30*3
	.word	Script_Rota,$8,$4,$c,$0080
	.word	Script_Move,$0008,30*3

	.word	Script_Warp
;FOLD_END
;	Subroutines for the Shade-Bob-Part:
;	Scribt,Rotate_n_Zoom,Shade_Bobs1,Put_Bob.
;FOLD_OUT
Scribt	;Small test shit Scribt
;FOLD_OUT
	php
	rep	#$30
	dec	Drw_PoiPoi	;Frames to Go!
	lda	Drw_PoiPoi
	bpl	.skip
	lda	L_OraVal
	clc
	adc	#$0a
	sta	L_OraVal
	tax
	lda	!Math_Scribt,x
	bne	.Not_Warp
	stz	L_OraVal
	stz	Drw_PoiPoi
	bra	.skip
.Not_Warp	sta	Drw_PoiPoi
	lda	!Math_Scribt+8,x
	bne	.Not_Clear
	lda	#$0002		;Switch to Clear Buffer and Screen (takes 128 Frames)
	sta	Drw_Dummy+6
	bra	.skip
.Not_Clear	bmi	.Not_Bobs
	sta	L_Dummy		;Put Number of Effect
	stz	Drw_Dummy+6	;Switch to Put Shade Bobs
	bra	.skip1
.Not_Bobs	eor	#$ffff
	inc	a
	sta	L_Dummy		;Put Number of Effect
	lda	#$0004
	sta	Drw_Dummy+6	;Switch to Calc and put Math Shit
.skip1	lda	!Math_Scribt+2,x	;Starting Angle
	sta	L_Incr1
	lda	!Math_Scribt+6,x	;Zoom Value
	sta	L_Incr2
.skip	ldx	L_OraVal		;Change Angle
	lda	!Math_Scribt+4,x
	clc
	adc	L_Incr1
	sta	L_Incr1
	lda	!Math_Scribt+6,x
	and	#$0001
	beq	.skip2
	lda	L_Incr1
	and	#$ff
	tax
	lda	!sinus2,x
	and	#$00ff
	clc
	adc	#$200
	sta	L_Incr2
.skip2	plp
	rts
;FOLD_END

;	words:	#ofFrames,Angle,AngleChangePerFrame,ZoomVal,Pos:ShadeBobEffect&Neg:MathEff.&0Clear

Math_Scribt	.word	0,0,0,0,6
	.word	$0300,$0000,$0000,$0200,$0006	;Shade Bob
	.word	$0080,$0000,$0002,$0200,$fffe	;X^2+Y^2/4
	.word	$0200,$0000,$0000,$0200,$0009	;Shade Bob
	.word	$0081,$0000,$0000,$0000,$0000	;Clear Screen
	.word	$0080,$0000,$0004,$0201,$fffc	;(X^2+Y^2)/16
	.word	$0300,$0000,$0004,$0201,$000c	;Shade Bob
	.word	$0081,$0000,$0000,$0000,$0000	;Clear Screen
	.word	$0200,$0000,$0002,$0300,$0003	;Shade Bob
	.word	$0080,$0000,$0000,$0200,$fff8	;X^2*Y+Y^2
	.word	$0200,$0000,$0002,$0200,$0003	;Shade Bob
	.word	$0081,$0000,$0000,$0000,$0000	;Clear Screen
	.word	$0200,$0000,$0002,$0200,$000f	;Shade Bob
	.word	$0200,$0000,$0001,$0200,$0012	;Shade Bob
	.word	$0200,$0000,$0000,$0200,$0018	;Shade Bob
	.word	$0080,$0100,$0000,$0200,$fffa	;X^2+Y^2
	.word	$0300,$0000,$fffe,$0200,$0015	;Shade Bob
	.word	$0080,$0000,$0000,$0200,$fff6	;X^3+y^2
	.word	$0280,$0000,$0000,$0200,$0018	;Shade Bob
	.word	$0081,$0000,$0000,$0000,$0000	;Clear Screen
	.word	$0000

Rotate_n_Zoom	;Rotate`n`Zoom Mode 7 Screen .. Simple Shit ofcause
;FOLD_OUT
	sep	#$20
	lda	L_Incr1			;Rotation Counter
	rep	#$31
	rol	a
	rol	a
	rol	a
	and 	#$07fe
	tax
	lda	L_Incr2			;Zoom Adder
	sep	#$20
	sta	REG_M7A
	xba
	sta	REG_M7A
	lda	!sinus+512+1,x
	sta	REG_M7B
	ldy	REG_MPYM
	lda	!sinus+1,x
	sta	REG_M7B
	rep	#$20
	lda	REG_MPYM
	pha
	tya
	sep	#$20
	sta	REG_M7A
	xba
	sta	REG_M7A
	rep	#$20
	pla
	sep	#$20
	sta	REG_M7B
	xba
	sta	REG_M7B
	xba
	rep	#$20
	eor	#$ffff
	inc	a
	sep	#$20
	sta	REG_M7C
	xba
	sta	REG_M7C
	rep	#$20
	tya
	sep	#$20
	sta	REG_M7D
	xba
	sta	REG_M7D
	rts
;FOLD_END

Add_Values	.byte	$00,$00,$00
	.byte	$03,$02,$fe
	.byte	$01,$02,$fd
	.byte	$fe,$ff,$01
	.byte	$ff,$01,$02
	.byte	$ff,$01,$ff
	.byte	$01,$ff,$01
	.byte	$01,$fd,$01
	.byte	$01,$ff,$fd

Shade_Bobs1	;Shade Bobs with Sinus Waves ... Calling Put_Bob
;FOLD_OUT
	lda	L_Y2Pos
	clc
	adc	!Add_Values,x
	sta	L_Y2Pos
	lda	L_X1Pos
	clc
	adc	!Add_Values+1,x
	sta	L_X1Pos
	lda	L_Y1Pos
	clc
	adc	!Add_Values+2,x
	sta	L_Y1Pos
	rep	#$20
	lda	L_Y2Pos
	asl	a
	tax
	clc
	adc	#$20
	and	#$01fe
	sta	L_DeltaX
	lda	>Sinus,x
	pha
	asl	a
	asl	a
	asl	a
	tay
	lda	L_X1Pos
	asl	a
	tax
	clc
	adc	#$20
	and	#$01fe
	sta	L_DeltaY
	lda	>Sinus,x
	pha
	txa
	asl	a
	tax
	pla
	clc
	adc	>Sinus,x
	ror	a
	pha
	sep	#$20
	jsr	!Put_Bob
	rep	#$20
	ldx	L_DeltaX
	lda	>Sinus,x
	asl	a
	asl	a
	asl	a
	tay
	ldx	L_DeltaY
	lda	>Sinus,x
	pha
	txa
	asl	a
	tax
	pla
	clc
	adc	>Sinus,x
	ror	a
	sep	#$20
	jsr	!Put_Bob
	rep	#$21
	pla
	sta	L_X2Pos
	pla
	adc	L_X2Pos
	clc
	ror	a
	asl	a
	asl	a
	asl	a
	tay
	lda	L_Y1Pos
	asl	a
	tax
	sep	#$20
	lda	>Sinus,x
	jsr	!Put_Bob
	rts
;FOLD_END

;	4 Faelle :
;1.	ddddxxxx|dddddddd	sonst
;2.	dddddxxx|xddddddd	x AND $7 = $5
;3.	ddddddxx|xxdddddd	x AND $7 = $6
;4.	dddddddx|xxxddddd	x AND $7 = $7

Put_Bob	;Copies "Bob" to VRam..
;FOLD_OUT
	pha
	sty	L_X2Pos
	rep	#$20
	and	#$0078
	xba
	clc
	ror	a
	adc	L_X2Pos		;Xpos Add
	sta	L_X2Pos
	sep	#$20
	pla
	and	#$07
	cmp	#$05
	bne	.notFall2

	rep	#$21
	lda	L_X2Pos
	adc	#$0005
	tax
	ldy	#$07
.loop2	sep	#$20
	lda	>$7f0000,x
	inc	a
	and	#$7f
	sta	>$7f0000,x
	stx	REG_VMADDL
	sta	REG_VMDATAH
	lda	>$7f0001,x
	inc	a
	and	#$7f
	sta	>$7f0001,x
	sta	REG_VMDATAH
	lda	>$7f0002,x
	inc	a
	and	#$7f
	sta	>$7f0002,x
	sta	REG_VMDATAH

	rep	#$21
	txa
	adc	#$400
	and	#$fff8
	tax

	sep	#$20
	lda	>$7f0000,x
	inc	a
	and	#$7f
	sta	>$7f0000,x
	stx	REG_VMADDL
	sta	REG_VMDATAH
	rep	#$20
	txa
	sec
	sbc	#$03f8-5
	tax
	dey
	bne	.loop2
	sep	#$20
	rts

.notFall2	cmp	#$06
	bne	.notFall3

	rep	#$21
	and	#$07
	adc	L_X2Pos
	tax
	ldy	#$07
.loop3	sep	#$20
	lda	>$7f0000,x
	inc	a
	and	#$7f
	sta	>$7f0000,x
	stx	REG_VMADDL
	sta	REG_VMDATAH
	lda	>$7f0001,x
	inc	a
	and	#$7f
	sta	>$7f0001,x
	sta	REG_VMDATAH

	rep	#$20
	txa
	clc
	adc	#$400
	and	#$fff8
	tax
	sep	#$20

	lda	>$7f0000,x
	inc	a
	and	#$7f
	sta	>$7f0000,x
	stx	REG_VMADDL
	sta	REG_VMDATAH
	lda	>$7f0001,x
	inc	a
	and	#$7f
	sta	>$7f0001,x
	sta	REG_VMDATAH
	rep	#$20
	txa
	sec
	sbc	#$03f8-6
	tax
	dey
	bne	.loop3
	sep	#$20
	rts


.notFall3	cmp	#$07
	bne	.notFall4
	rep	#$21
	and	#$07
	adc	L_X2Pos
	tax
	ldy	#$07
.loop4	sep	#$20
	lda	>$7f0000,x
	inc	a
	and	#$7f
	sta	>$7f0000,x
	stx	REG_VMADDL
	sta	REG_VMDATAH

	rep	#$21
	txa
	adc	#$400
	and	#$fff8
	tax
	sep	#$20

	lda	>$7f0000,x
	inc	a
	and	#$7f
	sta	>$7f0000,x
	stx	REG_VMADDL
	sta	REG_VMDATAH
	lda	>$7f0001,x
	inc	a
	and	#$7f
	sta	>$7f0001,x
	sta	REG_VMDATAH
	lda	>$7f0002,x
	inc	a
	and	#$7f
	sta	>$7f0002,x
	sta	REG_VMDATAH
	rep	#$20
	txa
	sec
	sbc	#$03f8-7
	tax
	dey
	bne	.loop4
	sep	#$20
	rts

.notFall4	rep	#$21
	and	#$07
	adc	L_X2Pos
	tax
	ldy	#$07
.loop1	sep	#$20
	lda	>$7f0000,x
	inc	a
	and	#$7f
	sta	>$7f0000,x
	stx	REG_VMADDL
	sta	REG_VMDATAH
	lda	>$7f0001,x
	inc	a
	and	#$7f
	sta	>$7f0001,x
	sta	REG_VMDATAH
	lda	>$7f0002,x
	inc	a
	and	#$7f
	sta	>$7f0002,x
	sta	REG_VMDATAH
	lda	>$7f0003,x
	inc	a
	and	#$7f
	sta	>$7f0003,x
	sta	REG_VMDATAH
	rep	#$20
	txa
	clc
	adc	#$08
	tax
	dey
	bne	.loop1
	sep	#$20
	rts
;FOLD_END
;FOLD_END
;	Objects for the Vektor-Bob Part
;	Four Included: 1.Square(Bob_Points1) 2.Dice(Bob_Points2) 3.Pipe(Bob_Points3) 4.Ball(.)
;FOLD_OUT
Bob_Points1	.word	64*3			;Starnge Square
xpos	set	-$38
	.repeat 8 {
ypos		set	-$38
		.repeat 8 {
		Coord	xpos,ypos,(-((xpos*xpos+ypos*ypos)/$60)-$40)
ypos		set	ypos+$10
		}
xpos	set	xpos+$10
	}	


Bob_Points2	.word	64*3			;Solid Dice
xpos	set	-$30
	.repeat 4 {
ypos		set	-$30
		.repeat 4 {
zpos			set	-$30
			.repeat 4 {
			Coord	xpos,ypos,zpos
zpos			set	zpos+$20
			}
ypos		set	ypos+$20
		}
xpos	set	xpos+$20
	}

Bob_Points3	.word	64*3			;Pipe
Radius	set	$30
angle	set	0
	.repeat 16 {
zpos	set	-$30
		.repeat 4 {
			Coord	(Radius*($100::DEG*angle/2))/$100,(Radius*($100::DEG*((angle+180)/2)))/$100,zpos
zpos			set	zpos+$20
		}
angle		set	angle+45
	}

Bob_Points4	.word	60*3			;Ball
angle	set	0
	.repeat 10 {
zpos	set	-$3c
Rad		set	28	
		.repeat 6 {
Radius			set	($50*($1000::DEG*Rad))/$1000
			Coord	(Radius*($100::DEG*angle))/$100,(Radius*($100::DEG*((angle+90))))/$100,zpos
zpos			set	zpos+$18
Rad			set	Rad+24
		}
angle		set	angle+36
	}
;FOLD_END
;	Rob Nothern Cruncher Depacking Routine for Mode 1!
	.include Sources:Magical_2nd_Demo/RNC_11.s

;	Music from the Game NINJAWARRIORS ... Init,Player and Tables 
;	Ripped,re-coded and re-allocated by the Pothead
;FOLD_OUT
Init_Musik	php					;Init the Music-replayer
	rep	#$30				;Transferes some neccesary Data to
	lda	#(Musik_Data+$10000)&&$ffff	;the Sound CPU..
	sta	Musik_ZP1
	lda	#^(Musik_Data+$10000)
	sta	Musik_ZP2
	jsr	Transfer_Musik
	lda	#(Musik_Data+$1AD8)&&$ffff
	sta	Musik_ZP1
	lda	#^Musik_Data
	sta	Musik_ZP2
	jsr	Transfer_Musik
	lda	#Musik_Data&&$ffff
	sta	Musik_ZP1
	lda	#^Musik_Data
	sta	Musik_ZP2
	jsr	Transfer_Musik
.loop	lda	REG_APUIO0
	ora	REG_APUIO2
	bne	.loop
	stz	Musik_RAM1
	stz	Musik_RAM2
	plp
	rts


	MODE	A16X16
Play_Musik	cmp	Musik_RAM1			;Start Playing a new Tune
	bne	.New_Song				;(from $01-$18 for different Tunes)
	rts					; $00 in Accu for STOP Playing

.New_Song	sta	Musik_RAM1			;Ripped and recoded by the Pothead
	asl	a				;NO 65816 Routines except the ones
	tax					;Below here...
	lda	Musik_Tab2,x			;Routine and SongData Freely reallocate-
	tax					;able.... 
	lda	!$0000,x
	cmp	Musik_RAM2
	beq	.Play1
	sta	Musik_RAM2
	phx
	jsr	Transfer_Sample
	plx
.Play1	lda	!$0002,x
	sta	REG_APUIO0
	rts

Transfer_Sample	ldx	Musik_RAM2
	ldy	#$0000
.Play4	lda	Musik_Tab1,y
	sta	REG_APUIO0
	lda	!$0000,x
	sta	Musik_ZP1
	lda	!$0002,x
	sta	Musik_ZP2
	phx
	phy
	jsr	Transfer_Musik
	ply
	plx
.Play3	lda	REG_APUIO0
	ora	REG_APUIO2
	bne	.Play3
	lda	!$0003,x
	beq	.Play2
	inx
	inx
	inx
	iny
	iny
	bra	.Play4
.Play2	rts


Transfer_Musik	php
	rep	#$30
	ldy	#$0000
	lda	#$BBAA
.musik1	cmp	REG_APUIO0
	bne	.musik1
	sep	#$20
	lda	#$CC
	bra	.musik3
.musik10	lda	[Musik_ZP1],y
	iny
	xba
	lda	#$00
	bra	.musik2
.musik5	xba
	lda	[Musik_ZP1],y
	iny
	xba
.musik4	cmp	REG_APUIO0
	bne	.musik4
	inc	a
.musik2	rep	#$20
	sta	REG_APUIO0
	sep	#$20
	dex
	bne	.musik5
.musik6	cmp	REG_APUIO0
	bne	.musik6
.musik7	adc	#$03
	beq	.musik7
.musik3	pha
	rep	#$20
	lda	[Musik_ZP1],y
	iny
	iny
	tax
	lda	[Musik_ZP1],y
	iny
	iny
	sta	REG_APUIO2
	sep	#$20
	cpx	#$0001
	lda	#$00
	rol	a
	sta	REG_APUIO1
	adc	#$7F
	pla
	sta	REG_APUIO0
	cpx	#$0001
	bcc	.musik8
.musik9	cmp	REG_APUIO0
	bne	.musik9
	bvs	.musik10
.musik8	plp
	rts

Musik_Tab1	.byte	$FF,$00,$FF,$00,$FE,$00,$FE,$00,$FE,$00,$FE,$00,$FE,$00,$FE,$00
	.byte	$FE,$00,$FE,$00,$FE,$00,$FE,$00,$FE,$00,$FE,$00,$FE,$00,$FE,$00

Musik_Tab2	.word	Sound01,Sound02,Sound03,Sound04,Sound05,Sound06,Sound07,Sound08
	.word	Sound09,Sound11,Sound12,Sound13,Sound14,Sound15,Sound16,Sound17
	.word	Sound18,Sound19,Sound20,Sound21,Sound22,Sound23,Sound24,Sound25
	.word	Sound26

Sound01	.word	Samples01,0
Sound02	.word	Samples07,1
Sound03	.word	Samples07,2
Sound04	.word	Samples15,1
Sound05	.word	Samples02,1
Sound06	.word	Samples05,1
Sound07	.word	Samples03,1
Sound08	.word	Samples01,1
Sound09	.word	Samples01,2
Sound11	.word	Samples04,1
Sound12	.word	Samples04,2
Sound13	.word	Samples06,1
Sound14	.word	Samples13,1
Sound15	.word	Samples12,1
Sound16	.word	Samples08,1
Sound17	.word	Samples09,1
Sound18	.word	Samples10,1
Sound19	.word	Samples10,2
Sound20	.word	Samples11,1
Sound21	.word	Samples14,1
Sound22	.word	Samples08,2
Sound23	.word	Samples06,2
Sound24	.word	Samples09,2
Sound25	.word	Samples13,2
Sound26	.word	Samples06,0

Samples01	dcr.t	Musik_Data+$14785,Musik_Data+$146A1,Musik_Data+$40000
	.word	$0000
Samples02	dcr.t	Musik_Data+$15D2D
	.word	$0000
Samples03	dcr.t	Musik_Data+$16415,Musik_Data+$146A1,Musik_Data+$40000
	.word	$0000
Samples04	dcr.t	Musik_Data+$1664E,Musik_Data+$146BD,Musik_Data+$40000,Musik_Data+$40707,Musik_Data+$40C67
	.word	$0000
Samples05	dcr.t	Musik_Data+$20000
	.word	$0000
Samples06	dcr.t	Musik_Data+$20248,Musik_Data+$146D1,Musik_Data+$41C6E,Musik_Data+$40000,Musik_Data+$42D89
	.word	$0000
Samples07	dcr.t	Musik_Data+$21BCD,Musik_Data+$146E5,Musik_Data+REG_JOY1LF,Musik_Data+$42D89,Musik_Data+$4226F
	.word	$0000
Samples08	dcr.t	Musik_Data+$22577,Musik_Data+$146F9,Musik_Data+$40000,Musik_Data+$42586,Musik_Data+$42D89,Musik_Data+$45D64
	.word	$0000
Samples09	dcr.t	Musik_Data+$23DCA,Musik_Data+$14711,Musik_Data+REG_A1T6LE,Musik_Data+$40000,Musik_Data+$42D89
	.word	$0000
Samples10	dcr.t	Musik_Data+$259E2,Musik_Data+$14725,Musik_Data+$42D89
	.word	$0000
Samples11	dcr.t	Musik_Data+$30000,Musik_Data+$14731,Musik_Data+$44233,Musik_Data+$44E38,Musik_Data+$45026,Musik_Data+$45523
	.word	$0000
Samples12	dcr.t	Musik_Data+$3119F,Musik_Data+$146F9,Musik_Data+$40000,Musik_Data+$42586,Musik_Data+$42D89
	.word	$0000
Samples13	dcr.t	Musik_Data+$3269D,Musik_Data+$14749,Musik_Data+$40000,Musik_Data+$44233,Musik_Data+REG_JOY1LF,Musik_Data+$42D89
	.word	$0000
Samples14	dcr.t	Musik_Data+$3459F,Musik_Data+$14761,Musik_Data+$40000,Musik_Data+$44E38
	.word	$0000
Samples15	dcr.t	Musik_Data+$351B7,Musik_Data+$14771,Musik_Data+$44233,Musik_Data+$42D89,Musik_Data+$45D14
	.word	$0000
;FOLD_END

;	**************************************
;	*** Tables for Filled Vector Parts ***
;	**************************************
;FOLD_OUT
OR_Table	.repeat 32 {
	.byte	$80,$40,$20,$10,$08,$04,$02,$01
	}

Mulu_Tab	.word	$d0*00,$d0*02,$d0*04,$d0*06,$d0*08,$d0*10,$d0*12,$d0*14,$d0*16,$d0*18
	.word	$d0*20,$d0*22,$d0*24,$d0*26,$d0*28,$d0*30,$d0*32,$d0*34,$d0*36,$d0*38
	.word	$d0*40,$d0*42,$d0*44,$d0*46,$d0*48,$d0*50
Test_Screen	
xy	set	0
	.repeat 26 {
	.word	0,0,0,$01+xy,$1b+xy,$35+xy,$4f+xy,$69+xy,$83+xy,$9d+xy,$b7+xy,$d1+xy,$eb+xy
	.word	$105+xy,$11f+xy,$139+xy,$153+xy,$16d+xy,$187+xy,$1a1+xy,$1bb+xy,$1d5+xy
	.word	$1ef+xy,$209+xy,$223+xy,$23d+xy,$257+xy,$271+xy,$28b+xy,0,0,0
xy	set	xy+1
	}
sinus	.word	$0000,$00D5,$0188,$025F,$0335,$03E8,$04BE,$0571	;Sinus Table with
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


xy	set	-228
	.repeat 32 {
	.word	($10000-$4000)/(xy+$100)
xy	set	xy+1
	}

DivsTab
xy	set	-196
	.repeat 1024+64 {
	.word	($10000-$4000)/(xy+$100)
xy	set	xy+1
	}
;FOLD_END

;	**********  Object Structure for 3-D Objects **********

;	Object1	;Object 1  Normal Cube 8 Points 6 Faces 12 Lines
;	Object2	;Object 2  Cheese 16 Points 9 Faces 48 Lines
;	Object3	;Object 3  Octaeder 5 Points 8 Faces 24 Lines
;	Object4	;Object 4  Pyramid 5 Points 5 Faces 16 Lines
;	Object5	;Object 5  Space Ship 6 Points 8 Faces 24 Lines

;FOLD_OUT
Object1	.word	Points			;Adress of Point Data
	.word	$8*3,$6-1			;Number of Points*3,Number of Surfaces-1
	.word	Surface1,4,Draw_Line1	;Adress of Surface Data,Number of Lines
	.word	Surface2,4,Draw_Line2	;Adress of Surface Data,Number of Lines
	.word	Surface3,4,Draw_Line1	;Adress of Surface Data,Number of Lines
	.word	Surface4,4,Draw_Line2	;Adress of Surface Data,Number of Lines
	.word	Surface5,4,Draw_Line3	;Adress of Surface Data,Number of Lines
	.word	Surface6,4,Draw_Line3	;Adress of Surface Data,Number of Lines
Points	Coord	+$30,+$30,+$30		;x,y,z Coords [Byte]
	Coord	+$30,-$30,+$30
	Coord	-$30,-$30,+$30
	Coord	-$30,+$30,+$30
	Coord	+$30,+$30,-$30
	Coord	+$30,-$30,-$30
	Coord	-$30,-$30,-$30
	Coord	-$30,+$30,-$30
Surface1	LineH	0,0,1	;a
	LineH	1,1,2	;b
	LineH	2,2,3	;c
	LineH	3,3,0	;d
Surface2	LineH	2,3,2	;c
	LineH	6,2,6	;g
	LineH	10,6,7	;k
	LineH	7,7,3	;h
Surface3	LineH	10,7,6	;k
	LineH	9,6,5	;j
	LineH	8,5,4	;i
	LineH	11,4,7	;l
Surface4	LineH	8,4,5	;i
	LineH	5,5,1	;f
	LineH	0,1,0	;a
	LineH	4,0,4	;e
Surface5	LineH	4,4,0	;e
	LineH	3,0,3	;d
	LineH	7,3,7	;h
	LineH	11,7,4	;l
Surface6	LineH	5,1,5	;f
	LineH	9,5,6	;j
	LineH	6,6,2	;g
	LineH	1,2,1	;b


Object2	.word	Points2
	.word	16*3,10-1
	.word	aSurface1,8,Draw_Line1
	.word	aSurface2,8,Draw_Line1
	.word	aSurface3,4,Draw_Line2
	.word	aSurface4,4,Draw_Line3
	.word	aSurface5,4,Draw_Line2
	.word	aSurface6,4,Draw_Line3
	.word	aSurface7,4,Draw_Line2
	.word	aSurface8,4,Draw_Line3
	.word	aSurface9,4,Draw_Line2
	.word	aSurfacea,4,Draw_Line3
Points2	Coord	$80/4,-$133/4,$40/4
	Coord	$133/4,-$80/4,$40/4
	Coord	$133/4,$80/4,$40/4
	Coord	$80/4,$133/4,$40/4
	Coord	-$80/4,$133/4,$40/4
	Coord	-$133/4,$80/4,$40/4
	Coord	-$133/4,-$80/4,$40/4
	Coord	-$80/4,-$133/4,$40/4
	Coord	$80/4,-$133/4,-$40/4
	Coord	$133/4,-$80/4,-$40/4
	Coord	$133/4,$80/4,-$40/4
	Coord	$80/4,$133/4,-$40/4
	Coord	-$80/4,$133/4,-$40/4
	Coord	-$133/4,$80/4,-$40/4
	Coord	-$133/4,-$80/4,-$40/4
	Coord	-$80/4,-$133/4,-$40/4
aSurface1	LineH	0,0/4,28/4
	LineH	0,28/4,24/4
	LineH	0,24/4,20/4
	LineH	0,20/4,16/4
	LineH	0,16/4,12/4
	LineH	0,12/4,8/4
	LineH	0,8/4,4/4
	LineH	0,4/4,0/4
aSurface2	LineH	0,32/4,36/4
	LineH	0,36/4,40/4
	LineH	0,40/4,44/4
	LineH	0,44/4,48/4
	LineH	0,48/4,52/4
	LineH	0,52/4,56/4
	LineH	0,56/4,60/4
	LineH	0,60/4,32/4
aSurface3	LineH	0,0/4,4/4
	LineH	0,4/4,36/4
	LineH	0,36/4,32/4
	LineH	0,32/4,0/4
aSurface4	LineH	0,4/4,8/4
	LineH	0,8/4,40/4
	LineH	0,40/4,36/4
	LineH	0,36/4,4/4
aSurface5	LineH	0,8/4,12/4
	LineH	0,12/4,44/4
	LineH	0,44/4,40/4
	LineH	0,40/4,8/4
aSurface6	LineH	0,12/4,16/4
	LineH	0,16/4,48/4
	LineH	0,48/4,44/4
	LineH	0,44/4,12/4
aSurface7	LineH	0,16/4,20/4
	LineH	0,20/4,52/4
	LineH	0,52/4,48/4
	LineH	0,48/4,16/4
aSurface8	LineH	0,20/4,24/4
	LineH	0,24/4,56/4
	LineH	0,56/4,52/4
	LineH	0,52/4,20/4
aSurface9	LineH	0,24/4,28/4
	LineH	0,28/4,60/4
	LineH	0,60/4,56/4
	LineH	0,56/4,24/4
aSurfacea	LineH	0,28/4,0/4
	LineH	0,0/4,32/4
	LineH	0,32/4,60/4
	LineH	0,60/4,28/4


Object3	.word	Points3
	.word	6*3,8-1
	.word	bSurface1,3,Draw_Line3
	.word	bSurface2,3,Draw_Line2
	.word	bSurface3,3,Draw_Line2
	.word	bSurface4,3,Draw_Line1
	.word	bSurface5,3,Draw_Line1
	.word	bSurface6,3,Draw_Line3
	.word	bSurface7,3,Draw_Line2
	.word	bSurface8,3,Draw_Line1
Points3	Coord	0,0,$199/5
	Coord	0,0,-$199/5
	Coord	$100/5,$100/5,0
	Coord	$100/5,-$100/5,0
	Coord	-$100/5,-$100/5,0
	Coord	-$100/5,$100/5,0
bSurface1	LineH	0,4/4,8/4
	LineH	0,8/4,20/4
	LineH	0,20/4,4/4
bSurface2	LineH	0,0/4,20/4
	LineH	0,20/4,8/4
	LineH	0,8/4,0/4
bSurface3	LineH	0,4/4,12/4
	LineH	0,12/4,8/4
	LineH	0,8/4,4/4
bSurface4	LineH	0,0/4,8/4
	LineH	0,8/4,12/4
	LineH	0,12/4,0/4
bSurface5	LineH	0,4/4,16/4
	LineH	0,16/4,12/4
	LineH	0,12/4,4/4
bSurface6	LineH	0,0/4,12/4
	LineH	0,12/4,16/4
	LineH	0,16/4,0/4
bSurface7	LineH	0,4/4,20/4
	LineH	0,20/4,16/4
	LineH	0,16/4,4/4
bSurface8	LineH	0,0/4,16/4
	LineH	0,16/4,20/4
	LineH	0,20/4,0/4


Object4	.word	Points4
	.word	5*3,5-1
	.word	cSurface1,4,Draw_Line3
	.word	cSurface2,3,Draw_Line1
	.word	cSurface3,3,Draw_Line2
	.word	cSurface4,3,Draw_Line1
	.word	cSurface5,3,Draw_Line2
Points4	Coord	0,$100/4,0
	Coord	-$100/4,-$100/4,$100/4
	Coord	$100/4,-$100/4,$100/4
	Coord	$100/4,-$100/4,-$100/4
	Coord	-$100/4,-$100/4,-$100/4
cSurface1	LineH	0,4/4,8/4
	LineH	0,8/4,12/4
	LineH	0,12/4,16/4
	LineH	0,16/4,4/4
cSurface2	LineH	0,8/4,4/4
	LineH	0,4/4,0/4
	LineH	0,0/4,8/4
cSurface3	LineH	0,12/4,8/4
	LineH	0,8/4,0/4
	LineH	0,0/4,12/4
cSurface4	LineH	0,16/4,12/4
	LineH	0,12/4,0/4
	LineH	0,0/4,16/4
cSurface5	LineH	0,4/4,16/4
	LineH	0,16/4,0/4
	LineH	0,0/4,4/4


Object5	.word	Points5
	.word	6*3,8-1
	.word	dSurface1,3,Draw_Line3
	.word	dSurface2,3,Draw_Line3
	.word	dSurface3,3,Draw_Line2
	.word	dSurface4,3,Draw_Line1;
	.word	dSurface5,3,Draw_Line1;
	.word	dSurface6,3,Draw_Line1;
	.word	dSurface7,3,Draw_Line2;
	.word	dSurface8,3,Draw_Line2;
Points5	Coord	0,$a0/4,-$100/4
	Coord	$100/4,0,-$a0/4
	Coord	0,-$a0/4,-$100/4
	Coord	-$100/4,0,-$a0/4
	Coord	-$a0/4,0,$100/4
	Coord	$a0/4,0,$100/4
dSurface1	LineH	0,8/4,4/4
	LineH	0,4/4,0/4
	LineH	0,0/4,8/4
dSurface2	LineH	0,12/4,8/4
	LineH	0,8/4,0/4
	LineH	0,0/4,12/4
dSurface3	LineH	0,8/4,16/4
	LineH	0,16/4,20/4
	LineH	0,20/4,8/4
dSurface4	LineH	0,8/4,12/4
	LineH	0,12/4,16/4
	LineH	0,16/4,8/4
dSurface5	LineH	0,0/4,20/4
	LineH	0,20/4,16/4
	LineH	0,16/4,0/4
dSurface6	LineH	0,4/4,8/4
	LineH	0,8/4,20/4
	LineH	0,20/4,4/4
dSurface7	LineH	0,16/4,12/4
	LineH	0,12/4,0/4
	LineH	0,0/4,16/4
dSurface8	LineH	0,4/4,20/4
	LineH	0,20/4,0/4
	LineH	0,0/4,4/4
;FOLD_END

sinus2	.byte	$3B,$3C,$3E,$3F,$41,$42,$44,$45,$47,$48,$49,$4B,$4C,$4E,$4F,$50
	.byte	$52,$53,$54,$56,$57,$58,$59,$5B,$5C,$5D,$5E,$5F,$60,$62,$63,$64
	.byte	$65,$66,$67,$68,$69,$6A,$6A,$6B,$6C,$6D,$6E,$6E,$6F,$70,$70,$71
	.byte	$72,$72,$73,$73,$73,$74,$74,$75,$75,$75,$75,$76,$76,$76,$76,$76
	.byte	$76,$76,$76,$76,$76,$76,$75,$75,$75,$75,$74,$74,$73,$73,$73,$72
	.byte	$72,$71,$70,$70,$6F,$6E,$6E,$6D,$6C,$6B,$6A,$69,$69,$68,$67,$66
	.byte	$65,$64,$63,$62,$60,$5F,$5E,$5D,$5C,$5B,$59,$58,$57,$55,$54,$53
	.byte	$52,$50,$4F,$4D,$4C,$4B,$49,$48,$47,$45,$44,$42,$41,$3F,$3E,$3C
	.byte	$3B,$3A,$38,$37,$35,$34,$32,$31,$2F,$2E,$2D,$2B,$2A,$28,$27,$26
	.byte	$24,$23,$22,$20,$1F,$1E,$1D,$1B,$1A,$19,$18,$17,$16,$14,$13,$12
	.byte	$11,$10,$0F,$0E,$0D,$0C,$0C,$0B,$0A,$09,$08,$08,$07,$06,$06,$05
	.byte	$04,$04,$03,$03,$03,$02,$02,$01,$01,$01,$01,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$02,$02,$03,$03,$03,$04
	.byte	$04,$05,$06,$06,$07,$08,$08,$09,$0A,$0B,$0C,$0D,$0D,$0E,$0F,$10
	.byte	$11,$12,$13,$14,$16,$17,$18,$19,$1A,$1B,$1D,$1E,$1F,$21,$22,$23
	.byte	$24,$26,$27,$29,$2A,$2B,$2D,$2E,$2F,$31,$32,$34,$35,$37,$38,$3A
	.byte	$3B,$3C,$3E,$3F,$41,$42,$44,$45,$47,$48,$49,$4B,$4C,$4E,$4F,$50
	.byte	$52,$53,$54,$56,$57,$58,$59,$5B,$5C,$5D,$5E,$5F,$60,$62,$63,$64
	.byte	$65,$66,$67,$68,$69,$6A,$6A,$6B,$6C,$6D,$6E,$6E,$6F,$70,$70,$71
	.byte	$72,$72,$73,$73,$73,$74,$74,$75,$75,$75,$75,$76,$76,$76,$76,$76
	.byte	$76,$76,$76,$76,$76,$76,$75,$75,$75,$75,$74,$74,$73,$73,$73,$72
	.byte	$72,$71,$70,$70,$6F,$6E,$6E,$6D,$6C,$6B,$6A,$69,$69,$68,$67,$66
	.byte	$65,$64,$63,$62,$60,$5F,$5E,$5D,$5C,$5B,$59,$58,$57,$55,$54,$53
	.byte	$52,$50,$4F,$4D,$4C,$4B,$49,$48,$47,$45,$44,$42,$41,$3F,$3E,$3C
	.byte	$3B,$3A,$38,$37,$35,$34,$32,$31,$2F,$2E,$2D,$2B,$2A,$28,$27,$26
	.byte	$24,$23,$22,$20,$1F,$1E,$1D,$1B,$1A,$19,$18,$17,$16,$14,$13,$12
	.byte	$11,$10,$0F,$0E,$0D,$0C,$0C,$0B,$0A,$09,$08,$08,$07,$06,$06,$05
	.byte	$04,$04,$03,$03,$03,$02,$02,$01,$01,$01,$01,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$02,$02,$03,$03,$03,$04
	.byte	$04,$05,$06,$06,$07,$08,$08,$09,$0A,$0B,$0C,$0D,$0D,$0E,$0F,$10
	.byte	$11,$12,$13,$14,$16,$17,$18,$19,$1A,$1B,$1D,$1E,$1F,$21,$22,$23
	.byte	$24,$26,$27,$29,$2A,$2B,$2D,$2E,$2F,$31,$32,$34,$35,$37,$38,$3A
	.byte	$3B,$3C,$3E,$3F,$41,$42,$44,$45,$47,$48,$49,$4B,$4C,$4E,$4F,$50
	.byte	$52,$53,$54,$56,$57,$58,$59,$5B,$5C,$5D,$5E,$5F,$60,$62,$63,$64
	.byte	$65,$66,$67,$68,$69,$6A,$6A,$6B,$6C,$6D,$6E,$6E,$6F,$70,$70,$71
	.byte	$72,$72,$73,$73,$73,$74,$74,$75,$75,$75,$75,$76,$76,$76,$76,$76
	.byte	$76,$76,$76,$76,$76,$76,$75,$75,$75,$75,$74,$74,$73,$73,$73,$72
	.byte	$72,$71,$70,$70,$6F,$6E,$6E,$6D,$6C,$6B,$6A,$69,$69,$68,$67,$66
	.byte	$65,$64,$63,$62,$60,$5F,$5E,$5D,$5C,$5B,$59,$58,$57,$55,$54,$53
	.byte	$52,$50,$4F,$4D,$4C,$4B,$49,$48,$47,$45,$44,$42,$41,$3F,$3E,$3C
	.byte	$3B,$3A,$38,$37,$35,$34,$32,$31,$2F,$2E,$2D,$2B,$2A,$28,$27,$26
	.byte	$24,$23,$22,$20,$1F,$1E,$1D,$1B,$1A,$19,$18,$17,$16,$14,$13,$12
	.byte	$11,$10,$0F,$0E,$0D,$0C,$0C,$0B,$0A,$09,$08,$08,$07,$06,$06,$05
	.byte	$04,$04,$03,$03,$03,$02,$02,$01,$01,$01,$01,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$02,$02,$03,$03,$03,$04
	.byte	$04,$05,$06,$06,$07,$08,$08,$09,$0A,$0B,$0C,$0D,$0D,$0E,$0F,$10
	.byte	$11,$12,$13,$14,$16,$17,$18,$19,$1A,$1B,$1D,$1E,$1F,$21,$22,$23
	.byte	$24,$26,$27,$29,$2A,$2B,$2D,$2E,$2F,$31,$32,$34,$35,$37,$38,$3A

Mode7Sin	.word	$000B*8,$000C*8,$000D*8,$000E*8,$000f*8,$0010*8,$0011*8,$0012*8
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

Mode7Text	.byte	" HELLO   ",3,"      DUE TO THE FACT ",2,"     THAT THIS SCROLLER IS"
	.byte	"TOTALLY UNREADABLE I WOULD JUST LIKE TO TELL YOU WHAT U ARE WATCHING"
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

ASCIISmall	.byte	39,39,39,39,39,39,39,39,39,39,39,39,39,39,39,39
	.byte	39,39,39,39,39,39,39,39,39,39,39,39,39,39,39,39
	.byte	39,38,39,39,39,39,39,39,39,39,39,39,39,39,37,39
	.byte	26,27,28,29,30,31,32,33,34,35,39,39,39,39,39,36
	.byte	39,00,01,02,03,04,05,06,07,08,09,10,11,12,13,14
	.byte	15,16,17,18,19,20,21,22,23,24,25,00,00,00,00,00

Out_Sin	.word	$00FE,$00FE,$00FE,$00FD,$00FD,$00FC,$00FB,$00FA
	.word	$00F9,$00F7,$00F6,$00F4,$00F2,$00F1,$00EE,$00EC
	.word	$00EA,$00E7,$00E5,$00E2,$00DF,$00DC,$00D9,$00D5
	.word	$00D2,$00CE,$00CA,$00C7,$00C3,$00BF,$00BA,$00B6
	.word	$00B2,$00AD,$00A8,$00A4,$009F,$009A,$0095,$0090
	.word	$008B,$0085,$0080,$007A,$0075,$006F,$006A,$0064
	.word	$005E,$0058,$0052,$004C,$0046,$0040,$003A,$0034
	.word	$002E,$0028,$0021,$001B,$0015,$000F,$0008,$0002
Out_Sin2	.word	$0000,$0005,$000C,$0012,$0018,$001E,$0025,$002B
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

EndOfBank00
	.say	Bytes free in Bank 0:
	exp=	(-EndOfBank00)&&$ffff

	org	$ffc0
	.byte	"2nd Demo by Pothead"
	org	$ffe4
	.word	NMI,NMI,NMI,NMI,Start,IRQ	;Nativ Mode Pointers
	org	$fff4
	.word	NMI,NMI,NMI,NMI,Start,IRQ	;Emulation Mode Pointers

Bank01
	;Incbins for Filled-Vector-Part

Packed_02	.bin	ram:Magical_2nd_Demo/incbins/Packed2.RNC
		;	Includes:
		;Logo1		Logo1.Snes	;12480
		;Logo1Col		Logo1.Col	;32

HDMAOne	.byte	$ff
	.byte	$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
	.byte	$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
	.byte	$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
	.byte	$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
	.byte	$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
	.byte	$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
	.byte	$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
	.byte	$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
	.byte	$80+81
	.byte	$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
	.byte	$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
	.byte	$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
	.byte	$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
	.byte	$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
	.byte	0,0
HDMASix	.byte	$14,$80,$6c,$0f,$47,$0f,$1,$80,0,0
HDMATwo	.byte	$ff
	.byte	$63,$14,$64,$18,$64,$18,$65,$1C,$65,$20,$66,$20,$66,$24,$67,$24
	.byte	$67,$28,$88,$2C,$88,$2C,$89,$30,$89,$34,$8A,$34,$8A,$38,$8B,$38
	.byte	$8B,$3C,$8C,$40,$8C,$40,$8D,$44,$AD,$44,$AE,$48,$AE,$4C,$AF,$4C
	.byte	$AF,$50,$B0,$50,$B0,$54,$B1,$58,$B1,$58,$B2,$5C,$B2,$60,$D3,$60
	.byte	$D3,$64,$D4,$64,$D4,$68,$D5,$68,$D4,$68,$D4,$68,$D4,$68,$D4,$64
	.byte	$D3,$64,$D3,$64,$D3,$64,$D3,$64,$D2,$64,$D2,$64,$D2,$64,$D2,$60
	.byte	$D1,$60,$D1,$60,$D1,$60,$D1,$60,$D0,$60,$D0,$60,$D0,$60,$D0,$5C
	.byte	$CF,$5C,$CF,$5C,$CF,$5C,$CF,$5C,$CE,$5C,$CE,$5C,$CE,$5C,$CE,$58
	.byte	$CD,$58,$CD,$58,$CD,$58,$CD,$58,$CC,$58,$CC,$58,$CC,$58,$CC,$54
	.byte	$CB,$54,$CB,$54,$CB,$54,$CB,$54,$CA,$54,$CA,$54,$CA,$54,$CA,$50
	.byte	$C9,$50,$C9,$50,$C9,$50,$C9,$50,$C8,$50,$C8,$50,$C8,$50,$C8,$4C
	.byte	$C7,$4C,$C7,$4C,$C7,$4C,$C7,$4C,$C6,$4C,$C6,$4C,$C6,$4C,$C6,$48
	.byte	$C5,$48,$C5,$48,$C5,$48,$C5,$48,$C4,$48,$C4,$48,$C4,$48,$C4,$44
	.byte	$C3,$44,$C3,$44,$C3,$44,$C3,$44,$C2,$44,$C2,$44,$C2,$44,$C2,$40
	.byte	$C1,$40,$C1,$40,$C1,$40,$C1,$40,$C0,$40,$C0,$40,$C0,$40,$C0,$3C
	.byte	$C0,$3C,$C0,$3C,$C0,$3C,$C0,$3C,$C0,$3C,$C0,$3C,$C0,$3C
	.byte	$80+80,$C0,$38
	.byte	$C0,$38,$C0,$38,$C0,$38,$C0,$38,$C0,$38,$C0,$38,$C0,$38,$C0,$34
	.byte	$C0,$34,$C0,$34,$C0,$34,$C0,$34,$C0,$34,$C0,$34,$C0,$34,$C0,$30
	.byte	$C0,$30,$C0,$30,$C0,$30,$C0,$30,$C0,$30,$C0,$30,$C0,$30,$C0,$2C
	.byte	$C0,$2C,$C0,$2C,$C0,$2C,$C0,$2C,$C0,$2C,$C0,$2C,$C0,$2C,$C0,$28
	.byte	$C0,$28,$C0,$28,$C0,$28,$C0,$28,$C0,$28,$C0,$28,$C0,$28,$C0,$24
	.byte	$C0,$24,$C0,$24,$C0,$24,$C0,$24,$C0,$24,$C0,$24,$C0,$24,$C0,$20
	.byte	$C0,$20,$C0,$20,$C0,$20,$C0,$20,$C0,$20,$C0,$20,$C0,$20,$C0,$1C
	.byte	$C0,$1C,$C0,$1C,$C0,$1C,$C0,$1C,$C0,$1C,$C0,$1C,$C0,$1C,$C0,$18
	.byte	$C0,$18,$C0,$18,$C0,$18,$C0,$18,$C0,$18,$C0,$18,$C0,$18,$C0,$14
	.byte	$C0,$14,$C0,$14,$C0,$14,$C0,$14,$C0,$14,$C0,$14,$00,$00,$00,$00
	.byte	0,0,0,0
HDMAThree	.byte	$ff
	.byte	$A4,$04,$C4,$04,$C4,$04,$C4,$04,$C4,$04,$C4,$04,$E4,$04,$E4,$04
	.byte	$E4,$08,$E4,$08,$04,$09,$04,$09,$04,$09,$24,$09,$24,$09,$24,$09
	.byte	$44,$09,$44,$09,$44,$09,$65,$09,$65,$09,$65,$09,$85,$09,$85,$09
	.byte	$85,$09,$A5,$09,$A5,$09,$A6,$09,$C6,$09,$C6,$09,$C6,$09,$C6,$09
	.byte	$C6,$09,$E6,$09,$E6,$09,$E6,$09,$E6,$0D,$07,$0E,$07,$0E,$07,$0E
	.byte	$07,$0E,$07,$0E,$27,$0E,$27,$0E,$27,$12,$28,$12,$48,$12,$48,$12
	.byte	$48,$12,$68,$12,$68,$12,$68,$12,$88,$12,$88,$12,$88,$12,$A9,$12
	.byte	$A9,$12,$A9,$12,$C9,$12,$C9,$12,$C9,$12,$E9,$12,$E9,$12,$EA,$12
	.byte	$0A,$13,$0A,$13,$0A,$13,$0A,$13,$2A,$13,$2A,$13,$2A,$13,$4A,$13
	.byte	$4A,$17,$4B,$17,$6B,$17,$6B,$17,$6B,$17,$8B,$17,$8B,$17,$8B,$17
	.byte	$AB,$17,$AB,$1B,$AC,$1B,$CC,$1B,$CC,$1B,$CC,$1B,$CC,$1B,$CC,$1F
	.byte	$CC,$1F,$CC,$1F,$CC,$1F,$CC,$23,$CD,$23,$CD,$23,$CD,$23,$CD,$23
	.byte	$CD,$27,$CD,$27,$CD,$27,$CD,$27,$CE,$2B,$CE,$2B,$CE,$2B,$CE,$2F
	.byte	$CE,$2F,$CE,$2F,$CF,$33,$CF,$33,$CF,$33,$CF,$37,$D0,$37,$D0,$37
	.byte	$D0,$3B,$D0,$3B,$D0,$3B,$D1,$3F,$D1,$3F,$D1,$3F,$D1,$43,$D2,$43
	.byte	$D2,$43,$D2,$43,$D2,$43,$D2,$47,$D3,$47,$D3,$47,$D3,$47
	.byte	$80+80,$D3,$4B
	.byte	$D4,$4B,$D4,$4B,$D4,$4B,$D4,$4B,$D4,$4F,$D5,$4F,$D5,$4F,$D5,$4F
	.byte	$D5,$53,$D6,$53,$D6,$53,$D6,$57,$D6,$57,$D6,$57,$D7,$5B,$D7,$5B
	.byte	$D7,$5B,$D7,$5F,$D8,$5F,$D8,$5F,$D8,$63,$D8,$63,$D8,$63,$D9,$67
	.byte	$D9,$67,$D9,$67,$D9,$6B,$DA,$6B,$DA,$6B,$DA,$6B,$DA,$6B,$DA,$6F
	.byte	$DB,$6F,$DB,$6F,$DB,$6F,$DB,$6F,$DB,$73,$DC,$73,$DC,$73,$DC,$73
	.byte	$DC,$77,$DD,$77,$DD,$77,$DD,$77,$DD,$77,$DD,$7B,$DE,$7B,$BD,$7B
	.byte	$BD,$7B,$9D,$7B,$9D,$7B,$7D,$7B,$7C,$7B,$7C,$7B,$5C,$7B,$5C,$7B
	.byte	$3B,$7B,$3B,$7B,$1B,$7B,$1B,$7B,$FB,$7A,$FA,$7A,$FA,$7A,$DA,$7A
	.byte	$DA,$7A,$BA,$7A,$B9,$7A,$99,$7A,$99,$7A,$79,$7A,$79,$7A,$79,$7A
	.byte	$59,$7A,$59,$7A,$39,$7A,$38,$7A,$18,$7A,$18,$7A,$F8,$79,$00,$00
	.byte	0,0,0,0
HDMAFour	.byte	$ff
	.byte	$BF,$74,$BF,$70,$BE,$70,$BE,$70,$BE,$6C,$BE,$6C,$BE,$6C,$BE,$68
	.byte	$BE,$68,$BE,$68,$BE,$64,$BE,$64,$BE,$64,$BD,$60,$9D,$60,$9D,$60
	.byte	$9D,$5C,$9D,$5C,$9D,$5C,$9D,$58,$9D,$58,$9D,$58,$9D,$54,$9D,$54
	.byte	$9C,$54,$9C,$50,$9C,$50,$9C,$50,$7C,$4C,$7C,$4C,$7C,$4C,$7C,$48
	.byte	$7C,$48,$7C,$48,$7C,$44,$7B,$44,$7B,$40,$7B,$40,$7B,$40,$7B,$3C
	.byte	$7B,$3C,$5B,$3C,$5B,$38,$5B,$38,$5B,$38,$5B,$34,$5A,$34,$5A,$34
	.byte	$5A,$30,$5A,$30,$5A,$30,$5A,$2C,$5A,$2C,$5A,$2C,$5A,$28,$3A,$28
	.byte	$39,$28,$39,$24,$39,$24,$39,$24,$39,$20,$39,$20,$39,$20,$39,$1C
	.byte	$39,$1C,$39,$1C,$39,$18,$38,$18,$38,$18,$18,$14,$18,$14,$18,$14
	.byte	$18,$10,$18,$10,$18,$10,$18,$0C,$18,$0C,$18,$0C,$17,$08,$17,$08
	.byte	$17,$04,$17,$04,$17,$04,$17,$04,$17,$04,$16,$04,$16,$04,$16,$04
	.byte	$16,$04,$16,$04,$16,$04,$35,$04,$35,$04,$35,$04,$35,$04,$35,$04
	.byte	$35,$04,$34,$04,$34,$04,$34,$04,$34,$04,$54,$04,$53,$04,$53,$04
	.byte	$53,$04,$53,$04,$53,$04,$53,$04,$52,$04,$52,$04,$52,$04,$52,$04
	.byte	$72,$04,$72,$04,$71,$04,$71,$04,$71,$00,$71,$00,$71,$00,$71,$00
	.byte	$70,$00,$70,$00,$90,$00,$90,$00,$90,$00,$90,$00,$8F,$00
	.byte	$80+80,$8F,$00
	.byte	$8F,$00,$8F,$00,$8F,$00,$8F,$00,$AE,$00,$AE,$00,$AE,$00,$AE,$00
	.byte	$AE,$00,$AE,$00,$AE,$00,$AE,$00,$8D,$00,$8D,$00,$8D,$00,$8D,$00
	.byte	$8D,$00,$8D,$00,$8D,$00,$8D,$00,$8C,$00,$8C,$00,$8C,$00,$8C,$00
	.byte	$8C,$00,$8C,$00,$8C,$00,$8C,$00,$8B,$00,$8B,$00,$8B,$00,$8B,$00
	.byte	$8B,$00,$8B,$00,$6B,$00,$6A,$00,$6A,$00,$6A,$00,$6A,$00,$6A,$00
	.byte	$6A,$00,$6A,$00,$6A,$00,$69,$00,$69,$00,$69,$00,$69,$00,$69,$00
	.byte	$69,$00,$69,$00,$68,$00,$68,$00,$68,$00,$68,$00,$68,$00,$68,$00
	.byte	$48,$00,$48,$00,$47,$00,$47,$00,$47,$00,$47,$00,$47,$00,$47,$00
	.byte	$47,$00,$47,$00,$46,$00,$46,$00,$46,$00,$46,$00,$46,$00,$46,$00
	.byte	$46,$00,$45,$00,$45,$00,$45,$00,$45,$00,$45,$00,$25,$00,$00,$00
	.byte	0,0,0,0
;	End Of Filled-Vector-Incbins

;	Incbins For Wobble-in-Between Part
DreiekSourc	.bin	ram:Magical_2nd_Demo/incbins/Dreieck.RNC
SmChar	.bin	ram:Magical_2nd_Demo/incbins/4ColChar.Snes
SmCols	.bin	ram:Magical_2nd_Demo/incbins/4ColChar.Col
	.byte	0,0,0
Texttech1	.byte	"    WELL ... FIRST OF ALL       "	;32*14 Chars per Page
	.byte	"  PREPARE FOR SOMETHING REALLY  "
	.byte	"WEIRD ....  A SINGLE PIXEL SINUS"
	.byte	"    SCROLLER IN 256 COLORS      "
	.byte	"                                "
	.byte	"   EXTREMELY BORING OFCAUSE     "
	.byte	"   BUT THIS DEMO WASNT MEANT    "
	.byte	"    TO ENTERTAIN YOU ANYWAY     "
	.byte	"                                "
	.byte	"       HEHEHEHE                 "
	.byte	"                                "
	.byte	"   A B A N D O N    WE REALLY   "
	.byte	"                      SUCK !    "
	.byte	"                                "
Texttech2	.byte	"    UP NEXT IS SOMETHING THAT   "
	.byte	"  REALLY TOOK ME A FEW WEEKS TO "
	.byte	"           CODE....             "
	.byte	"                                "
	.byte	"  IT IS REALLY NOTHING SPECIAL  "
	.byte	" FOR AN AMIGA OR PC. BUT ON THE "
	.byte	"  SUPERNINTENDO I AM THE FIRST  "
	.byte	" EVER TO CODE THIS LOUSY ROUTINE"
	.byte	"                                "
	.byte	"THE MOST BORIN THING IN DA WHOLE"
	.byte	"            WORLD :::           "
	.byte	"                                "
	.byte	"        FILL ME OR DIE !!!!     "
	.byte	"                                "
Texttech3	.byte	"   OK NOW COMES THE ONLY PART   "
	.byte	" WITH A SCROLLER THAT IS STILL  "
	.byte	" READABLE  SO HAVE FUN WITH IT  "
	.byte	"                                "
	.byte	"  JUST A VERY SPECIAL HELLO TO  "
	.byte	"   FLORIAN SAUER FOR CREATING   "
	.byte	" THE SASM   BEST ASSEMBLER EVER "
	.byte	"                                "
	.byte	" AND TO TWK PAN AND SIGMA SEVEN "
	.byte	"  FOR THEIR SUPPORT AND CHATS   "
	.byte	"                                "
	.byte	" OK DONT FORGET THE ATA SLOGAN  "
	.byte	"ABANDON WHEN ONE FARTH ISNT ENUF"
	.byte	"                                "
Texttech4	.byte	"  AFTER THIS NICE AND VEEERRYY  "
	.byte	"  SLOW ROUTINE   I AM EXTREMLY  "
	.byte	"   ASHAMED TO PRESENT TO YOU    "
	.byte	"                                "
	.byte	"    THE FIRST VEEERY BORING     "
	.byte	"      ROUTINE OF THE DAY        "
	.byte	"                                "
	.byte	"    MY AMIGA DOES IT BETTER     "
	.byte	"     BUT NO ONE EVER CARES      "
	.byte	"         OAMS RULE BOBS         "
	.byte	"                                "
	.byte	"   PRESS B BUTTON IN EACH PART  "
	.byte	"     TO PROCEED TO THE NEXT.    "
	.byte	"                                "
	;End Of Incbins for Wobble-in-Between

	;Incbins for Sinus-Scroller-Part
Packed_03	.bin	ram:Magical_2nd_Demo/incbins/packed3.RNC
	;		Includes:
	;Mode7Char		256ColChar.Snes	;2432
	;Mode7Cols		256ColChar.Col	;128
	;Mode7Logo		Logo2Upper.Snes	;8192
	;			Logo2Lower.Snes	;8192
	;Mode7LogoCols		Logo2.col	;32

Mode7Scr	.byte	$01,$05,$09,$0d,$11,$15,$19,$1d,$21,$25,$29,$2d,$31,$35,$39,$3d
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
HDMASeven	.byte	$22,$80,1,2,1,4,1,6,1,8,1,$a,1,$c,1,$e,$50,$0f
	.byte	1,$e,1,$c,1,$a,1,$8,1,6,1,$4,1,2,$01,$80,0,0
HDMASeven1	.byte	$30,$00,$48,$10,1,$00,0,0
	;End of Incbins for Sinus-Scroller-Part

	;Incbins for Shade-Bob Part
HDMAList2	.byte	$0a,$0f,1,$08,$46,$0c,1,$08,1,$0f,0,0
Colors	.byte	0,0
	.bin	ram:Magical_2nd_Demo/incbins/128Bobs1.Col
Sinus	.word	$003C,$003E,$003F,$0040,$0042,$0043,$0045,$0046
	.word	$0048,$0049,$004B,$004C,$004D,$004F,$0050,$0052
	.word	$0053,$0054,$0056,$0057,$0058,$005A,$005B,$005C
	.word	$005D,$005F,$0060,$0061,$0062,$0063,$0064,$0065
	.word	$0067,$0068,$0069,$006A,$006B,$006B,$006C,$006D
	.word	$006E,$006F,$0070,$0070,$0071,$0072,$0072,$0073
	.word	$0074,$0074,$0075,$0075,$0076,$0076,$0076,$0077
	.word	$0077,$0077,$0077,$0078,$0078,$0078,$0078,$0078
	.word	$0078,$0078,$0078,$0078,$0078,$0077,$0077,$0077
	.word	$0077,$0076,$0076,$0076,$0075,$0075,$0074,$0074
	.word	$0073,$0073,$0072,$0071,$0071,$0070,$006F,$006E
	.word	$006E,$006D,$006C,$006B,$006A,$0069,$0068,$0067
	.word	$0066,$0065,$0064,$0063,$0062,$0060,$005F,$005E
	.word	$005D,$005C,$005A,$0059,$0058,$0056,$0055,$0054
	.word	$0052,$0051,$0050,$004E,$004D,$004B,$004A,$0048
	.word	$0047,$0046,$0044,$0043,$0041,$0040,$003E,$003D
	.word	$003B,$003A,$0038,$0037,$0035,$0034,$0032,$0031
	.word	$0030,$002E,$002D,$002B,$002A,$0028,$0027,$0026
	.word	$0024,$0023,$0022,$0020,$001F,$001E,$001C,$001B
	.word	$001A,$0019,$0018,$0016,$0015,$0014,$0013,$0012
	.word	$0011,$0010,$000F,$000E,$000D,$000C,$000B,$000A
	.word	$000A,$0009,$0008,$0007,$0007,$0006,$0005,$0005
	.word	$0004,$0004,$0003,$0003,$0002,$0002,$0002,$0001
	.word	$0001,$0001,$0001,$0000,$0000,$0000,$0000,$0000
	.word	$0000,$0000,$0000,$0000,$0000,$0001,$0001,$0001
	.word	$0001,$0002,$0002,$0002,$0003,$0003,$0004,$0004
	.word	$0005,$0006,$0006,$0007,$0008,$0008,$0009,$000A
	.word	$000B,$000C,$000D,$000D,$000E,$000F,$0010,$0011
	.word	$0013,$0014,$0015,$0016,$0017,$0018,$0019,$001B
	.word	$001C,$001D,$001E,$0020,$0021,$0022,$0024,$0025
	.word	$0026,$0028,$0029,$002B,$002C,$002D,$002F,$0030
	.word	$0032,$0033,$0035,$0036,$0038,$0039,$003A,$003C
	.word	$003C,$003E,$003F,$0040,$0042,$0043,$0045,$0046
	.word	$0048,$0049,$004B,$004C,$004D,$004F,$0050,$0052
	.word	$0053,$0054,$0056,$0057,$0058,$005A,$005B,$005C
	.word	$005D,$005F,$0060,$0061,$0062,$0063,$0064,$0065
	.word	$0067,$0068,$0069,$006A,$006B,$006B,$006C,$006D
	.word	$006E,$006F,$0070,$0070,$0071,$0072,$0072,$0073
	.word	$0074,$0074,$0075,$0075,$0076,$0076,$0076,$0077
	.word	$0077,$0077,$0077,$0078,$0078,$0078,$0078,$0078
	.word	$0078,$0078,$0078,$0078,$0078,$0077,$0077,$0077
	.word	$0077,$0076,$0076,$0076,$0075,$0075,$0074,$0074
	.word	$0073,$0073,$0072,$0071,$0071,$0070,$006F,$006E
	.word	$006E,$006D,$006C,$006B,$006A,$0069,$0068,$0067
	.word	$0066,$0065,$0064,$0063,$0062,$0060,$005F,$005E
	.word	$005D,$005C,$005A,$0059,$0058,$0056,$0055,$0054
	.word	$0052,$0051,$0050,$004E,$004D,$004B,$004A,$0048
	.word	$0047,$0046,$0044,$0043,$0041,$0040,$003E,$003D
	.word	$003B,$003A,$0038,$0037,$0035,$0034,$0032,$0031
	.word	$0030,$002E,$002D,$002B,$002A,$0028,$0027,$0026
	.word	$0024,$0023,$0022,$0020,$001F,$001E,$001C,$001B
	.word	$001A,$0019,$0018,$0016,$0015,$0014,$0013,$0012
	.word	$0011,$0010,$000F,$000E,$000D,$000C,$000B,$000A
	.word	$000A,$0009,$0008,$0007,$0007,$0006,$0005,$0005
	.word	$0004,$0004,$0003,$0003,$0002,$0002,$0002,$0001
	.word	$0001,$0001,$0001,$0000,$0000,$0000,$0000,$0000
	.word	$0000,$0000,$0000,$0000,$0000,$0001,$0001,$0001
	.word	$0001,$0002,$0002,$0002,$0003,$0003,$0004,$0004
	.word	$0005,$0006,$0006,$0007,$0008,$0008,$0009,$000A
	.word	$000B,$000C,$000D,$000D,$000E,$000F,$0010,$0011
	.word	$0013,$0014,$0015,$0016,$0017,$0018,$0019,$001B
	.word	$001C,$001D,$001E,$0020,$0021,$0022,$0024,$0025
	.word	$0026,$0028,$0029,$002B,$002C,$002D,$002F,$0030
	.word	$0032,$0033,$0035,$0036,$0038,$0039,$003A,$003C

Packed_04	.bin	ram:Magical_2nd_Demo/incbins/Packed4.RNC
	;		Includes:
	;	Logo		32ColABNLogo.Snes	;8192
	;	Logo_Colors	32ColABNLogo.Col		;64

HDMAFive1	.byte	$7f,$07,$10,$07,$20,$15,0,0
HDMAFive2	.byte	$7f,$40,$00,$10,$40,$00,0,0,0
HDMAFive3	.byte	$7f,$0f,1,$0f,1,$e,1,$d,1,$c,1,$b,1,$a,1,9,1,8,1,7,1,6,1,5,1,4,1,3,1,2,1,1
	.byte	1,0,1,$f,0,0
Math_Text	.byte	" Hello and Welcome to the Shade Bob and Mathshit Part  .."
	.byte	" This Scroller is mainly for Greetings, so if ya ever met me "
	.byte	"or whatever you might get Greetings ... as usual i forget 90 "
	.byte	"Percent of the guys , so sorry in advance .."
	.byte	" Very Special Hellos fly out to all ABANDON rowdies :"
	.byte	" Sigma Seven,Ceres,Dave,Lucifer ATA,Crap,Hoax,Ozone STOCK,"
	.byte	"Megawatt,Norbert and PETER ... ok special thanks to The White "
	.byte	"Knight and Paninaro of ATX for being helpfull and nice all the Time"
	.byte	" MEGA Special Hip Hops to our Super-Family-Tennis-All-Wednesday-"
	.byte	"Night-Competition-Paderborners Dirk and Arne AMR."
	.byte	"  Also hi to Geggin and Sir Jinx of Censor ... Wolverine on IRC "
	.byte	" ... Big Boss .. Nosferatu ... the whole PREMIERE crew .. Irata,"
	.byte	"Flynn and the Beermacht fellows."
	.byte	"Also thanks to the guys who had to watch this demo half a year, cause"
	.byte	" i spent much time on Coding it: Piepen Ceres and Noogman "
	.byte	" Ok... there wernt to many Scene Greetings, but i really dont spent"
	.byte	" much call out anymore, so i forgot most of my old friends ..."
	.byte	" Just Greetings to my old MAGiCAL Crewmates : Killer , Papillon , "
	.byte	"Jarre , Rotox , Gaston , Sigma Seven , Dave  and all the others ..."
	.byte	" Now to something a little more Important  ..  This Demo was written"
	.byte	" using the SASM written by Florian Sauer, so if u think about programming"
	.byte	" the Super Nintendo, you should get a registered Version of the SASM."
	.byte	"The SASM is a very fast One Pass Macro Cross Assembler for the Amiga "
	.byte	" to produce SNES Programms... It can send the Programm to the Snes via"
	.byte	" Parallel Port and is a very powerfull Assembler ... you can get the SASM"
	.byte	" if you send 70 Dollars or 100 German Marks to the Following Adress:"
	.byte	" Florian Sauer , Hachumerstrasse 48 , 31167 Bockenem , Germany ..."
	.byte	" PLEASE NOTE That the Author of the Sasm has NOTHING to do with this Demo"
	.byte	" ... I just put his Adress in here, to support his brilliant Work ! .. "
	.byte	" Ok i told you enuff .... just one last hint ... there is a Secret Part in"
	.byte	" this Demo  .. and you can reach it , after u reached the Last Part Of this "
	.byte	" Demo.....      ok ..... WARP Dr. Zooloo ... "
	.byte	"   Good Bye     ",0
	;End of Incbins for Shade-Bob-Part

Bobs_Logo	.bin	ram:Magical_2nd_Demo/incbins/BobLogo.Snes
Bobs_Logo_Col	.bin	ram:Magical_2nd_Demo/incbins/BobLogo.Col


EndOfBank01	.say	Bytes free in Bank 1:
	exp=	((-EndOfBank01)&&$ffff)


	.pad
Musik_Data	.bin	ram:Magical_2nd_Demo/incbins/ninja.bin
	.say	Bytes free in Bank 2: FULL
	.say	Bytes free in Bank 3: FULL
	.say	Bytes free in Bank 4: FULL
	.say	Bytes free in Bank 5: FULL
	.say	Bytes free in Bank 6: FULL
EndPic	.bin	ram:Magical_2nd_Demo/incbins/End_pic.Snes
	.say	Bytes free in Bank 7: FULL
EndPic_Cols	.bin	ram:Magical_2nd_Demo/incbins/End_pic.Col
EndPic_Char	.bin	ram:Magical_2nd_Demo/incbins/16ColChar.Snes
End_Text	.byte	"                "
	.byte	"   This is The  "
	.byte	"     E N D !    "
	.byte	"                "
	.byte	"  Hope You were "
	.byte	"  able to Enjoy "
	.byte	"   This Small   "
	.byte	" Super Nintendo "
	.byte	"  Demonstration "
	.byte	"                "
	.byte	" Credits are on "
	.byte	"     the Way    "

	.byte	"   THE CREDITS  "
	.byte	"                "
	.byte	"  This Picture  "
	.byte	" was scanned in "
	.byte	"  by an Unknown "
	.byte	"      Dude      "
	.byte	" Sorry for Using"
	.byte	"   it Noogie!   "
	.byte	"                "
	.byte	"  Nice Tunes by "
	.byte	"  The Makers of "
	.byte	" Ninja Warriors "

	.byte	" All Graphix by "
	.byte	" The One n Only "
	.byte	"                "
	.byte	" N O O G M A N! "
	.byte	"   of Complex   "
	.byte	"                "
	.byte	" And the Char in"
	.byte	"The Introduction"
	.byte	" Was Pixeled by "
	.byte	"   Graffiti of  "
	.byte	"     ANTHROX    "
	.byte	"                "

	.byte	" All Coding was "
	.byte	"    done by     "
	.byte	"  The Pothead   "
	.byte	"   of Anthrox   "
	.byte	"                "
	.byte	"   Thanks for   "
	.byte	"   Whatching!   "
	.byte	"                "
	.byte	" Ok Dont Really "
	.byte	" know what else "
	.byte	"   to tell ya   "
	.byte	"                "

	.byte	"                "
	.byte	"  Ok enuff Shit "
	.byte	" This Text Will "
	.byte	"    WARP now!   "
	.byte	"                "
	.byte	"                "
	.byte	" SASM register  "
	.byte	"  now for the   "
	.byte	" ULTIMATE SNES  "
	.byte	"   Assembler!   "
	.byte	"                "
	.byte	"   L8ter Dudez! "

	.byte	"                "
	.byte	"                "
	.byte	"                "
	.byte	"                "
	.byte	"                "
	.byte	"                "
	.byte	"                "
	.byte	"                "
	.byte	"                "
	.byte	"                "
	.byte	"                "
	.byte	"                "
ASCIIEnd	.word	$18ee,$18ee,$18ee,$18ee,$18ee,$18ee,$18ee,$18ee,$18ee,$18ee,$18ee,$18ee,$18ee,$18ee,$18ee,$18ee
	.word	$18ee,$18ee,$18ee,$18ee,$18ee,$18ee,$18ee,$18ee,$18ee,$18ee,$18ee,$18ee,$18ee,$18ee,$18ee,$18ee
	.word	$18ee,$18ec,$18ee,$18ee,$18ee,$18ee,$18ee,$18ee,$18ee,$18ee,$18ee,$18ee,$18ee,$18ee,$18ee,$18ee
	.word	$18c8,$18ca,$18cc,$18ce,$18e0,$18e2,$18e4,$18e6,$18e8,$18ea,$18ee,$18ee,$18ee,$18ee,$18ee,$18ee
	.word	$18ee,$1800,$1802,$1804,$1806,$1808,$180a,$180c,$180e,$1820,$1822,$1824,$1826,$1828,$182a,$182c
	.word	$182e,$1840,$1842,$1844,$1846,$1848,$184a,$184c,$184e,$1860,$1862,$18ee,$18ee,$18ee,$18ee,$18ee
	.word	$18ee,$1864,$1866,$1868,$186a,$186c,$186e,$1880,$1882,$1884,$1886,$1888,$188a,$188c,$188e,$18a0
	.word	$18a2,$18a4,$18a6,$18a8,$18aa,$18ac,$18ae,$18c0,$18c2,$18c4,$18ee,$18ee,$18ee,$18ee,$18ee,$18ee


EndOfBank08	.say	Bytes free in Bank $8:
	exp=	(-EndOfBank08)&&$ffff
	.pad

Land_Angle_Table	.bin	ram:Magical_2nd_Demo/incbins/Landscape.Table1a
	.say	Bytes free in Bank $9: FULL
	.say	Bytes free in Bank $a: FULL

	;Voxel Space Routine for 65816
	;Hardly any Comments, cause it was a quickly written thing.

Do_Landscape	sep	#$20
	rep	#$10

	lda	#$7e
	pha
	plb

	rep	#$21
	lda	<L_DeltaX			;Change Angle

xz	set	0
	.repeat 9 {
xy		set	0
		.repeat 8 {

		rep	#$31			;Init for One Ray
		ldy	#$01f8
		sty	<L_DeltaY		;Reset Actual Height in Row
		ldy	#$3000			;Reset Perspective Pointer
		sty	<X_Add
		stz	<L_Incr1		;HeightMax this Row   (ACHTUNG A8 Sometimes)

.loop1		tax				;Get Actual Angle
		bpl	.bank1
		lda	>Land_Angle_Table+$8000,x
		bra	.bank2
.bank1		lda	>Land_Angle_Table,x	;Get Ray for Raytracing
.bank2		inx
		inx
		phx
		sep	#$20
		asl	a
		clc
		adc	<L_X2Pos
		xba
		clc
		adc	<L_X2Pos+1
		xba
		tax				;Start Ray at XPos,YPos
		lda	#$00
		xba
		lda	!$8000,x		;Check What Color was Found
		tay
		lda	(<X_Add),y		;Do Central Perspectiv (Only Z and Y)
		inc	<X_Add+1
		cmp	<L_Incr1		;Higher than Previously Drawn Row?
		bcc	.skip			;No -> Nothing New

		sta	<L_Incr1		;Else this is new Max Height for dis Row
		adc	#$03			;Negate Height
		eor	#$fc
		and	#$fc
		rep	#$20
		asl	a			;and Save it as Destination Height
		sta	<L_Incr2
		ldy	<L_DeltaY
		cpy	<L_Incr2
		bcc	.skip1
		txa
		bmi	.Bank1
		lda	>Land_Landshade1,x
		bra	.Bank2
.Bank1		lda	>Land_Landshade1+$8000,x
.Bank2		tax
.loop2		sep	#$20			;Draw Row from Actual Y-Pos to
		txa				;Destination Y-Pos (Max Height)
		sta	!$1000+xy+xz,y
		rep	#$21
		tya
		sbc	#$07
		tay
		cpy	<L_Incr2
		bcs	.loop2
		sty	<L_DeltaY
.skip		rep	#$21			;This Step of Raytrace Finshed
.skip1		pla
		bit	#$7e
		bne	.loop1			;One Row Drawn

xy		set	xy+1			;Eight Rows Drawn (Tiles 00,10,20,..,70)
		}
xz	set	xz+$200				;All 112 Rows Drawn..(20 Frames L8er!)
	}
	sep	#$20
	rep	#$10
	lda	#$80
	sta	<Comm_Bit
	rtl					;Return to Main Routine

OAM_Change	.byte	1,$42,$7f,$42,1,$43,0,0

Intro_Logo	.bin	ram:Magical_2nd_Demo/incbins/Mode7Mamor.Snes	;16384
Intro_Logo_Colors	.bin	ram:Magical_2nd_Demo/incbins/Mode7Mamor.Col	;256
HDMAFade	.byte	1,$2,1,$4,1,$6,1,$8,1,$a,1,$c,1,$e,1,$f,$7f,$f,$10,$f,1,$e,1,$c,1,$a,1,$8
	.byte	1,$6,1,$4,1,$2,1,$00,$10,$8f,1,$0f,0,0
HDMAScrMode	.byte	8,$07,$7f,$07,$10,$07,8,$07,1,$31,0,0


GlassBob	.bin	ram:Magical_2nd_Demo/incbins/GlassBob.Snes
GlassBob_Cols	.bin	ram:Magical_2nd_Demo/incbins/GlassBob.Pal
Bobs_Back	.bin	ram:Magical_2nd_Demo/incbins/BobBack.Snes
Bobs_Back1	.bin	ram:Magical_2nd_Demo/incbins/BobBack1.Snes


EndOfBank0d	.say	Bytes free in Bank $0b:
	exp=	(-EndOfBank0d)&&$ffff

	.pad
Land_Divs_Table	.bin	ram:Magical_2nd_Demo/incbins/Landscape.Table21	;16384
Intro_Char	.bin	ram:Magical_2nd_Demo/incbins/16x32Char.Snes		;12280
Intro_Char_Colors	.bin	ram:Magical_2nd_Demo/incbins/16x32Char.Col		;128
	.byte	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
Intro_Char_ASCII	.byte	$a2,$a2,$a2,$a2,$a2,$a2,$a2,$a2,$a2,$a2,$a2,$a2,$a2,$a2,$a2,$a2
	.byte	$a2,$a2,$a2,$a2,$a2,$a2,$a2,$a2,$a2,$a2,$a2,$a2,$a2,$a2,$a2,$a2
	.byte	$a2,$85,$a2,$a2,$a2,$a2,$a2,$a2,$a2,$a2,$a2,$a2,$87,$a1,$86,$a2
	.byte	$63,$64,$65,$66,$67,$80,$81,$82,$83,$84,$a2,$a2,$a2,$a2,$a2,$a0
	.byte	$00,$01,$02,$03,$04,$05,$06,$07,$20,$21,$22,$23,$24,$25,$26,$27
	.byte	$40,$41,$42,$43,$44,$45,$46,$47,$60,$61,$62,$a2,$a2,$a2,$a2,$a2
Land_Colors	.bin	ram:Magical_2nd_Demo/incbins/fractal.Col
	.bin	ram:Magical_2nd_Demo/incbins/64ColLogo.Col

EndOfBank0e	.say	Bytes free in Bank $0c:
	exp=	(-EndOfBank0e)&&$ffff

	.pad
Land_Landscape1	.bin	ram:Magical_2nd_Demo/incbins/fractal.Land
Land_Landshade1	.bin	ram:Magical_2nd_Demo/incbins/fractal.Shade
Land_Landscape2	=	Land_Landscape1+$10000
Land_Landshade2	=	Land_Landshade1+$10000
	.say	Bytes free in Bank $d: FULL
	.say	Bytes free in Bank $e: FULL
	.say	Bytes free in Bank $f: FULL
	.say	Bytes free in Bank $10: FULL

Land_Logo	.bin	ram:Magical_2nd_Demo/incbins/64ColLogo.Snes
	.say	Bytes free in Bank $11: FULL

Intro_Logo2	.bin	ram:Magical_2nd_Demo/incbins/Intro320x160.Logo.Snes
Intro_TextScr	.bin	ram:Magical_2nd_Demo/incbins/Intro.Screen.Snes
Intro_TextScrScr	.bin	ram:Magical_2nd_Demo/incbins/Intro.Screen.Snes.screen
Intro_Logo2Col	.bin	ram:Magical_2nd_Demo/incbins/Intro.Screen.Col
EndOfBank12	.say	Bytes free in Bank $12:
	exp=	(-EndOfBank12)&&$ffff

	.pad
Music	.bin	ram:Magical_2nd_Demo/incbins/delta.bin
	.say	Bytes free in Bank $13: FULL
Hidden_Logo	.bin	ram:Magical_2nd_Demo/incbins/HiddenLogo.Snes
Hidden_Char	.bin	ram:Magical_2nd_Demo/incbins/HiddenChar.Snes
Hidden_Colors	.bin	ram:Magical_2nd_Demo/incbins/Hidden.col
EndOfBank14	.say	Bytes free in Bank $14:
	exp=	(-EndOfBank14)&&$ffff

	.pad
Picture_1_Tiles	.bin	ram:Magical_2nd_Demo/incbins/Face.Snes
	.say	Bytes free in Bank $15: FULL
Picture_1_Screen	.bin	ram:Magical_2nd_Demo/incbins/Face.Snes.screen
Picture_1_Col	.bin	ram:Magical_2nd_Demo/incbins/Face.Col
EndOfBank16	.say	Bytes free in Bank $16:
	exp=	(-EndOfBank16)&&$ffff
