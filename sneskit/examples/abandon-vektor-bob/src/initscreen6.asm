;--------------------------------------------------------------------
.include "snes.inc"
.include "snes_decompress.inc"
.include "snes_joypad.inc"
.include "graphics.inc"
;--------------------------------------------------------------------
.import oam_table, sprite_init, wait_vb
;--------------------------------------------------------------------
.importzp frame_ready, joy1_down
;--------------------------------------------------------------------
.global DoVektorBobs
;--------------------------------------------------------------------
;	Author:	Kay Struve
;	E-Mail:	pothead@uni-paderborn.de
;	Telephone:	++49-(0)5251-65459
;	Date:		Beginning of 1994
;	Machine:	Super Nintendo (65816)
;	Assembled with:	SASM V1.81,V2.00

Object_Buf	=	7e0800h
SPRITE_PROP	=	%00000000
SPRITE_XY	=	0e810h

OBuf_Points	=	0800h			;Number of Points Object is using
OBuf_Faces	=	OBuf_Points+2		;Number of Surfaces Object is using
OBuf_Lines	=	OBuf_Faces+2		;Number of Lines Surface is using
OBuf_RotX	=	OBuf_Lines+2		;Angle for X-Rotation
OBuf_XSin	=	OBuf_RotX+2		;Sinus of X-Rot Angle
OBuf_XCos	=	OBuf_XSin+2		;Cosin of X-Rot Angle
OBuf_RotY	=	OBuf_XCos+2		;Angle for Y-Rotation
OBuf_YSin	=	OBuf_RotY+2		;Sinus of Y-Rot Angle
OBuf_YCos	=	OBuf_YSin+2		;Cosin of Y-Rot Angle
OBuf_RotZ	=	OBuf_YCos+2		;Angle for Z-Rotation
OBuf_ZSin	=	OBuf_RotZ+2		;Sinus of Z-Rot Angle
OBuf_ZCos	=	OBuf_ZSin+2		;Cosin of Z-Rot Angle
OBuf_Color	=	OBuf_ZCos+2		;Color of Surface Buffer
OBuf_Dist	=	OBuf_Color+2		;Distance of Object to eye (Z) ($80-$3c0)
OBuf_RotPts	=	OBuf_Dist+2		;Buffer for rotated Points 3*MAXPOINTS (16)

.macro Coord	one,two,three		; Datatype for 3d Coordinates
        .byte   one,two,three
.endmacro

BG1GFX = 00000h
BG1MAP = 04400h
BG2GFX = 06000h
BG2MAP = 04800h
BG3GFX = 04000h
BG3MAP = 04c00h
SPRGFX = 0c000h

;--////////////////////////////////////////////////////////////////--
.zeropage
;--////////////////////////////////////////////////////////////////--

Act_Object:
	.res 2
Drw_PoiPoi:
	.res 2
Dummy_Sin:
	.res 2
L_DeltaX:
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

;--////////////////////////////////////////////////////////////////--
.segment "XCODE"
;--////////////////////////////////////////////////////////////////--
.a8
.i16

;FOLD_END
;	Init for Vektor-Bobs Part
;FOLD_OUT

;====================================================================
DoVektorBobs:
;====================================================================
	rep	#10h			; X,Y = 16-bit
	sep	#20h			; A = 8-bit

	sei

	lda	#00h
	ldx	#0030h
:	sta	OBuf_RotPts,x
	dex
	beq	:-

	lda	#80h
	sta	REG_VMAIN

	rep	#20h			; A = 16-bit

	lda	#0000h
	sta	X_Add

	ldx	#BG1MAP
	stx	REG_VMADDL
	ldy	#03h
Init_12:
	ldx	#0000h
Init_11:
	lda	Bob_Logo_Data,x
	clc
	adc	X_Add
	sta	REG_VMDATAL
	inx
	inx
	cpx	#40h
	bne	Init_11
	lda	X_Add
	clc
	adc	#20h
	sta	X_Add
	dey
	bne	Init_12

	ldx	#BG2MAP
	stx	REG_VMADDL
	ldy	#0000h
Init_14:
	lda	#0020h
	ldx	Back_Tab,y
		; +-------------- palette 2
Init_15:	; | +------------ tile 0
	phx	; | |
	ldx	#0800h
	stx	REG_VMDATAL
	plx
	dea
	dex
	bne	Init_15

	ldx	#0802h
Init_16:
	stx	REG_VMDATAL
	dea
	bne	Init_16
	iny
	iny
	cpy	#11*2
	bne	Init_14

	ldx	#BG3MAP
	stx	REG_VMADDL
	ldy	#0000h
Init_18:
	lda	#0010h
	ldx	Back_Tab,y
:	pha
	lda	#1000h
	sta	REG_VMDATAL
	pla
	dea
	dex
	bne	:-

		; +-------------- bg3 priority (20h) + palette (10h)
		; | +------------ tile 2
		; | |
	ldx	#3002h
:	stx	REG_VMDATAL
	dea
	bne	:-

	lda	#1000h
	ldx	#10h
:	sta	REG_VMDATAL
	dex
	bne	:-
	iny
	iny
	cpy	#11*2
	bne	Init_18

	sep	#20h			; A = 8-bit

	DoDecompressDataVram gfx_spr_glassTiles, SPRGFX
	DoDecompressDataVram gfx_bobs_back1Tiles, BG2GFX
	DoDecompressDataVram gfx_bobs_back2Tiles, BG3GFX
	DoDecompressDataVram gfx_bobs_logoTiles, BG1GFX
        
	DoCopyPalette gfx_spr_glassPal, 128, 9
	DoCopyPalette gfx_bobs_back1Pal, 32, 2
	DoCopyPalette gfx_bobs_back2Pal, 16, 2
	DoCopyPalette gfx_bobs_logoPal, 0, 15

	lda	#02h
	sta	REG_CGSWSEL		; Fixed Color Addition OFF
	dec
	sta	REG_TS
	lda	#0e0h
	sta	REG_COLDATA
	stz	REG_CGADSUB

	lda	#BG1MAP>>8
	sta	REG_BG1SC
	lda	#BG2MAP>>8
	sta	REG_BG2SC
	lda	#BG3MAP>>8
	sta	REG_BG3SC

	lda	#(BG2GFX>>9)+(BG1GFX>>13)
	sta	REG_BG12NBA
	lda	#BG3GFX>>13
	sta	REG_BG34NBA

	lda	#0c0h
	sta	REG_BG1HOFS
	lda	#0ffh
	sta	REG_BG1HOFS
	lda	#50h
	sta	REG_BG1VOFS
	lda	#0ffh
	sta	REG_BG1VOFS

	stz	REG_BG2HOFS
	stz	REG_BG2HOFS
	stz	REG_BG3HOFS
	stz	REG_BG3HOFS
	stz	REG_BG2VOFS
	stz	REG_BG2VOFS
	stz	REG_BG3VOFS
	stz	REG_BG3VOFS

	lda	#OBSEL_16_32 | OBSEL_BASE(SPRGFX) | OBSEL_NN_16K
	sta	REG_OBSEL
	stz	REG_OAMADDL
	stz	REG_OAMADDH
	ldx	#80h
	lda	#SPRITE_PROP
	xba
	lda	#0e0h
:	stz	REG_OAMDATA		; Init OAM Ram
	sta	REG_OAMDATA
	xba
	stz	REG_OAMDATA
	sta	REG_OAMDATA
	xba
	dex
	bne	:-

:	stz	REG_OAMDATA
	inx
	cpx	#20h
	bne	:-

	ldx	#0000h
:	pha
	lda	#00h
	sta	oam_table,x		; Init OAM Mirror Image
	pla
	sta	oam_table+1,x
	xba
	pha
	lda	#00h
	sta	oam_table+2,x
	pla
	sta	oam_table+3,x
	xba
	inx
	inx
	inx
	inx
	cpx	#0200h
	bne	:-

	ldx	#OBuf_RotPts-OBuf_Points
:	stz	OBuf_Points,x
	dex
	bpl	:-

	inx
	;ldx	#0000h
	;stx	OBuf_Faces		; Number of Bobs NOT to be displayed
	;stx	OBuf_RotX		; X-Rotation-Angle ($0000-$07fe)
	;stx	OBuf_XSin		; Used in Rotation Sub Routine
	;stx	OBuf_XCos		; Used in Rotation Sub Routine
	;stx	OBuf_RotY		; Y-Rotation-Angle
	;stx	OBuf_YSin		; Used in Rotation Sub Routine
	;stx	OBuf_YCos		; Used in Rotation Sub Routine
	;stx	OBuf_RotZ		; Z-Rotation-Angle
	;stx	OBuf_ZSin		; Used in Rotation Sub Routine
	;stx	OBuf_ZCos		; Used in Rotation Sub Routine
	;stx	OBuf_Dist		; Offset to z Coord (Eye Coord)
	stx	Script_Poi		; Pointer for Script
	stx	Script_Next		; Counter for the Script
	stx	X_Add			; Add to x-rotation-angle (Every Frame)
	stx	Y_Add			; Add to y-rotation-angle (Every Frame)
	stx	Z_Add			; Add to z-rotation-angle (Every Frame)
	stx	Dummy_Sin		; Screen Open Scroll
	dex
	stx	Act_Object		; Screen Close Scroll
	ldx	#Bob_Points2&&$ffff
	stx	OBuf_Color		; Actual Object (Pointer)

	stz	REG_DMAP0
	lda	#<REG_BGMODE
	sta	REG_BBAD0
	ldx	#ScrMode
	stx	REG_A1T0L
	lda	#^ScrMode
	sta	REG_A1B0

	stz	REG_DMAP1
	lda	#<REG_TM
	sta	REG_BBAD1
	ldx	#ScrMode1
	stx	REG_A1T1L
	lda	#^ScrMode1
	sta	REG_A1B1

	lda	#%11
	sta	REG_HDMAEN

	lda	#0e1h			; Vertical Timer IRQ at Line $0e8
	sta	REG_VTIMEL
	stz	REG_VTIMEH

	sep	#20h			; A = 8-bit
					;     n-yx---a
	lda	#NMI_ON|NMI_JOYPAD	;21 = 00100001
	sta	REG_NMITIMEN		;81 = 10000001

	cli

	lda	#1
	sta	frame_ready

	lda	#0fh
	sta	REG_INIDISP
;--------------------------------------------------------------------
Loop:
;--------------------------------------------------------------------
	jsr	Main__06

	lda	Dummy_Sin
	cmp	#70h
	bne	Loop

	rep	#20h
	lda	joy1_down
	bit	#(JOYPAD_START)
	sep	#20h
	beq	Loop			; start not pressed

	ldx	#0070h			; start pressed
	stx	Act_Object		; end demo
	bra	Loop

;====================================================================
Ending:
;====================================================================

	jmp	DoVektorBobs

;--------------------------------------------------------------------
;	Main Routine for the Vector-Bob Part
;	Rotates Bobs and Copies Coords to OAM-Mirror-Ram..
;====================================================================
Main__06:
;====================================================================
	lda	REG_RDNMI
	bpl	Main__06

	rep	#30h			; A,X,Y = 16-bit

	lda	Act_Object
	bmi	Continue
	dea
	bmi	Ending

	sta	Act_Object

	rep	#10h			; X,Y = 16-bit
	sep	#20h			; A = 8-bit

	sta	REG_BG2HOFS
	xba
	sta	REG_BG2HOFS
	xba

	rep	#20h			; A = 16-bit

	eor	#0ffffh
	ina

	sep	#20h			; A = 8-bit

	sta	REG_BG3HOFS
	xba
	sta	REG_BG3HOFS

	rep	#20h			; A = 16-bit

	bra	Not_In

Continue:
	lda	Dummy_Sin
	cmp	#0070h
	beq	Not_In

	ina
	sta	Dummy_Sin

	sep	#20h			; A = 8-bit

	sta	REG_BG2HOFS
	xba
	sta	REG_BG2HOFS
	xba

	rep	#20h			; A = 16-bit

	eor	#0ffffh
	ina

	sep	#20h			; A = 8-bit

	sta	REG_BG3HOFS
	xba
	sta	REG_BG3HOFS

	rep	#20h			; A = 16-bit

Not_In:	jsr	Script			; Do Script
	lda	#00a0h
	sta	OBuf_Dist
	lda	OBuf_Color
	tax
	ina
	ina
	sta	Drw_PoiPoi		; Object Point Structure
	lda	0000h,x
	sta	OBuf_Points		; Number of Points to be rotated
	jsr	Rot_Points		; Rotate Object Points

	rep	#30h			; A,X,Y = 16-bit

	ldx	OBuf_Color
	lda	0000h,x
	sec
	sbc	OBuf_Faces
	beq	skip1
;--------------------------------------------------------------------
	tax
	ldy	#0000h
;--------------------------------------------------------------------
PutLoop1:
;--------------------------------------------------------------------
	lda	OBuf_RotPts-3,x		; Transfer Position of Used Bobs
	clc				; to OAM_Ram Mirror
	adc	#SPRITE_XY
	sta	oam_table,y
	iny
	iny
	iny
	iny
	dex
	dex
	dex
	bne	PutLoop1
;--------------------------------------------------------------------
skip1:	lda	#0e000h			; And "Clear" the Rest by Putting them
	ldx	OBuf_Faces		; to Position $00,$e0
	cpx	#0000h
	beq	skip2
;--------------------------------------------------------------------
PutLoop2:
;--------------------------------------------------------------------
	sta	oam_table,y
	iny
	iny
	iny
	iny
	dex
	dex
	dex
	bne	PutLoop2
;--------------------------------------------------------------------
skip2:	lda	OBuf_RotX		; Change X-Rotation Angle
	clc
	adc	X_Add
	and	#07feh
	sta	OBuf_RotX
	lda	OBuf_RotY		; Change Y-Rotation Angle
	clc
	adc	Y_Add
	and	#07feh
	sta	OBuf_RotY
	lda	OBuf_RotZ		; Change Z-Rotation Angle
	clc
	adc	Z_Add
	and	#07feh
	sta	OBuf_RotZ

	sep	#20h			; A = 8-bit

	rts

Script:	rep	#30h			; A,X,Y = 16-bit
	lda	Script_Next
	beq	Init
	bmi	Increase_Visible
	cmp	#0001h
	beq	Decrease_Visible
	dea
	sta	Script_Next

	rts
;--------------------------------------------------------------------
Decrease_Visible:
;--------------------------------------------------------------------
	dec	L_OraVal
	bne	not3
;--------------------------------------------------------------------
	inc	L_OraVal
	inc	L_OraVal
	inc	L_OraVal
	lda	OBuf_Faces		; Decrease Number of Visible Bobs by One
	clc
	adc	#03h
	ldx	OBuf_Color
	cmp	0000h,x
	bcc	not1
;--------------------------------------------------------------------
	stz	Script_Next
	sec
	sbc	#03h
;--------------------------------------------------------------------
not1:	sta	OBuf_Faces
;--------------------------------------------------------------------
not3:	rts
;--------------------------------------------------------------------
Increase_Visible:
;--------------------------------------------------------------------
	dec	L_OraVal
	bne	not4
;--------------------------------------------------------------------
	inc	L_OraVal
	inc	L_OraVal
	inc	L_OraVal
	lda	OBuf_Faces		; Increase Number of Visible Bobs by One
	sec
	sbc	#03h
	bne	not2
;--------------------------------------------------------------------
	ldx	Script_Poi
	lda	Bob_Script-2,x		; Get Number of Frames this Obj. is shown.
	sta	Script_Next
	lda	#0000h
;--------------------------------------------------------------------
not2:	sta	OBuf_Faces
;--------------------------------------------------------------------
not4:	rts
;--------------------------------------------------------------------
Init:	dea
	sta	Script_Next		; Negativ Value to Script_Next => .Increase_Visible
	ldx	Script_Poi
	lda	Bob_Script,x
	bne	Not_Warp
;--------------------------------------------------------------------
	lda	#0000h
	sta	Script_Poi
	bra	Init
;--------------------------------------------------------------------
Not_Warp:
;--------------------------------------------------------------------
	sta	OBuf_Color		; New Object Structure
	lda	Bob_Script+2,x
	sta	X_Add			; New X_Add
	lda	Bob_Script+4,x
	sta	Y_Add			; New Y_Add
	lda	Bob_Script+6,x
	sta	Z_Add			; New Z_Add
	txa
	clc
	adc	#0ah			; Increase Script_Poi(nter)
	sta	Script_Poi
	ldx	OBuf_Color		; Number of Bobs to be Displayed = 0
	lda	0000h,x
	sta	OBuf_Faces
	lda	#0003h
	sta	L_OraVal

	rts
;--------------------------------------------------------------------
;	Sub-Routines for Part 1 (Filled Vektor Objects)
;	Including:
;		1) Rotate Points From Pointstrukture (3D) to WRAM (2D Coords)
;		2) Draw Object (Hidden Faces,Line Draw Routines)
;		3) Fill the Buffer in 2 Planes
;	Rotate Points around all 3 Axis
;====================================================================
Rot_Points:
;====================================================================
	rep	#30h		; A,X,Y = 16-bit

	ldx	OBuf_RotX	; Change X-Rotation Angle
	lda	SINUS,x
	sta	OBuf_XSin	; Sinus(Rot_X)
	lda	SINUS+512,x
	sta	OBuf_XCos	; Cosine(Rot_X)
	ldx	OBuf_RotZ	; Change Z-Rotation Angle
	lda	SINUS,x
	sta	OBuf_ZSin	; Sinus(Rot_Z)
	lda	SINUS+512,x
	sta	OBuf_ZCos	; Cosine(Rot_Z)
	ldx	OBuf_RotY	; Change Y-Rotation Angle
	lda	SINUS,x
	sta	OBuf_YSin	; Sinus(Rot_Y)
	lda	SINUS+512,x
	sta	OBuf_YCos	; Cosine(Rot_Y)

	sep	#30h		; A,X,Y 8-bit

	ldy	#00h
	ldx	OBuf_XSin	; Get LSB of Sin(Rot_X)
;--------------------------------------------------------------------
RotX_Loop:
;--------------------------------------------------------------------
	stx	REG_M7A
	lda	OBuf_XSin+1	; Get MSB of Sin(Rot_X)
	sta	REG_M7A
	iny
	lda	(Drw_PoiPoi),y	; Get Y-Position
	pha
	sta	REG_M7B
	rol	REG_MPYM
	lda	REG_MPYH	; Read Result (MSB of Y*sin(Rot_X)) [2's Complement]
	rol	a
	sta	Rot_Dummy1
	iny
	lda	(Drw_PoiPoi),y	; Get Z-Position
	pha
	sta	REG_M7B
	rol	REG_MPYM
	lda	REG_MPYH	; Read Result (MSB of Z*sin(Rot_X)) [2's Complement]
	rol	a
	eor	#0ffh
	ina
	sta	Rot_Dummy2
	lda	OBuf_XCos	; Get LSB of Cos(Rot_X)
	sta	REG_M7A
	lda	OBuf_XCos+1	; Get MSB of Cos(Rot_X)
	sta	REG_M7A
	pla			; Get Z-Position
	sta	REG_M7B
	rol	REG_MPYM
	lda	REG_MPYH	; Read Result (MSB of z*cos(Rot_X)) [2's Complement]
	rol	a
	clc
	adc	Rot_Dummy1
	sta	OBuf_RotPts-1,y	; NEW Y-Pos!
	pla			; Get Y-Position
	sta	REG_M7B
	rol	REG_MPYM
	lda	REG_MPYH	; Read Result (MSB of y*cos(Rot_X)) [2's Complement]
	rol	a
	clc
	adc	Rot_Dummy2
	sta	OBuf_RotPts,y	; NEW Z-Pos!
	iny
	cpy	OBuf_Points
	bne	RotX_Loop
;--------------------------------------------------------------------
	ldy	#00h
	ldx	OBuf_YSin	; Get LSB of Sin(Rot_Y)
;--------------------------------------------------------------------
RotY_Loop:
;--------------------------------------------------------------------
	stx	REG_M7A
	lda	OBuf_YSin+1	; Get MSB of Sin(Rot_Y)
	sta	REG_M7A
	lda	(Drw_PoiPoi),y	; Get X-Position
	pha
	sta	REG_M7B
	rol	REG_MPYM
	lda	REG_MPYH	; Read Result (MSB of X*sin(Rot_Y)) [2's Complement]
	rol	a
	sta	Rot_Dummy1
	lda	OBuf_RotPts+2,y	; Get Z-Position
	pha
	sta	REG_M7B
	rol	REG_MPYM
	lda	REG_MPYH	; Read Result (MSB of Z*sin(Rot_Y)) [2's Complement]
	rol	a
	eor	#0ffh
	ina
	sta	Rot_Dummy2
	lda	OBuf_YCos	; Get LSB of Cos(Rot_Y)
	sta	REG_M7A
	lda	OBuf_YCos+1	; Get MSB of Cos(Rot_Y)
	sta	REG_M7A
	pla			; Get Z-Position
	sta	REG_M7B
	rol	REG_MPYM
	lda	REG_MPYH	; Read Result (MSB of z*cos(Rot_Y)) [2's Complement]
	rol	a
	clc
	adc	Rot_Dummy1
	sta	OBuf_RotPts,y	; NEW X-Pos!
	pla			; Get X-Position
	sta	REG_M7B
	rol	REG_MPYM
	lda	REG_MPYH	; Read Result (MSB of X*cos(Rot_Y)) [2's Complement]
	rol	a
	clc
	adc	Rot_Dummy2
	sta	OBuf_RotPts+2,y	; NEW Z-Pos!
	iny
	iny
	iny
	cpy	OBuf_Points
	bne	RotY_Loop
;--------------------------------------------------------------------
	ldy	#00h
;--------------------------------------------------------------------
RotZ_Loop:
;--------------------------------------------------------------------
	lda	OBuf_ZSin	; Get LSB of Sin(Rot_Z)
	sta	REG_M7A
	lda	OBuf_ZSin+1	; Get MSB of Sin(Rot_Z)
	sta	REG_M7A
	lda	OBuf_RotPts,y	; Get X-Position
	pha
	sta	REG_M7B
	rol	REG_MPYM
	lda	REG_MPYH	; Read Result (MSB of x*sin(Rot_Z)) [2's Complement]
	rol	a
	sta	Rot_Dummy1
	lda	OBuf_RotPts+1,y	;Get Y-Position
	pha
	sta	REG_M7B
	rol	REG_MPYM
	lda	REG_MPYH	; Read Result (MSB of y*sin(Rot_Z)) [2's Complement]
	rol	a
	eor	#0ffh
	ina
	sta	Rot_Dummy2
	lda	OBuf_ZCos	; Get LSB of Cos(Rot_Z)
	sta	REG_M7A
	lda	OBuf_ZCos+1	; Get MSB of Cos(Rot_Z)
	sta	REG_M7A
	pla			; Get Y-Position
	sta	REG_M7B
	rol	REG_MPYM
	lda	REG_MPYH	; Read Result (MSB of y*cos(Rot_Z)) [2's Complement]
	rol	a
	clc
	adc	Rot_Dummy1
	sta	OBuf_RotPts,y	; NEW X-Pos!
	pla			; Get X-Position
	sta	REG_M7B
	rol	REG_MPYM
	lda	REG_MPYH	; Read Result (MSB of x*cos(Rot_Z)) [2's Complement]
	rol	a
	clc
	adc	Rot_Dummy2
	sta	OBuf_RotPts+1,y	; NEW Y-Pos!

	lda	#00h
	xba
	lda	OBuf_RotPts+2,y	; Get Z-Position
;--------------------------------------------------------------------
	bpl	:+
;--------------------------------------------------------------------
	xba
	lda	#0ffh
	xba
;--------------------------------------------------------------------
:	rep	#30h		; A,X,Y 16-bit

	clc
	adc	OBuf_Dist
	asl	a
	tax
	lda	DivsTab,x

	sep	#30h		; A,X,Y 8-bit

	sta	REG_M7A		; Do Central Perspektive
	xba
	sta	REG_M7A
	lda	OBuf_RotPts,y
	sta	REG_M7B
	lda	REG_MPYM
	clc
	adc	#104
	sta	OBuf_RotPts,y	; Store 2D-X-Coordinate	[BYTE]
	lda	OBuf_RotPts+1,y
	sta	REG_M7B
	lda	REG_MPYM
	clc
	adc	#104
	sta	OBuf_RotPts+1,y	; Store 2D-Y-Coordinate	[BYTE]
	iny
	iny
	iny
	cpy	OBuf_Points
	beq	RotZ_Quit
;--------------------------------------------------------------------
	jmp	RotZ_Loop
;--------------------------------------------------------------------
RotZ_Quit:
;--------------------------------------------------------------------
	rts

;--////////////////////////////////////////////////////////////////--
.code
;--////////////////////////////////////////////////////////////////--


;--------------------------------------------------------------------
Back_Tab:
;--------------------------------------------------------------------
	.word	8,9,8,7,8,6,7,9,8,10,8
;--------------------------------------------------------------------


;--------------------------------------------------------------------
Bob_Script:	;Object,    X_Add,Y_Add,Z_Add,#Frames
;--------------------------------------------------------------------
	.word	Bob_Points1,$000c,$0008,$fff5,$0200
	.word	Bob_Points2,$0006,$000c,$fff7,$0200
	.word	Bob_Points3,$000c,$0004,$fff3,$0200
	.word	Bob_Points4,$000e,$0002,$fff5,$0200
	.word	0
;--------------------------------------------------------------------


;--------------------------------------------------------------------
;--[ OBJECTS ]
;	Objects for the Vektor-Bob Part
;	Four Included: 1.Square(Bob_Points1) 2.Dice(Bob_Points2)
;	3.Pipe(Bob_Points3) 4.Ball(.)
;FOLD_OUT
;--------------------------------------------------------------------
Bob_Points1:
;--------------------------------------------------------------------
	.incbin	"../data/bobpoints1.bin"
;--------------------------------------------------------------------


;--------------------------------------------------------------------
Bob_Points2:
;--------------------------------------------------------------------
	.word	64*3				; Solid Dice
xpos	.set	$00d0
	.repeat 4
ypos		.set	$00d0
		.repeat 4
zpos			.set	$ffcf
			.repeat 4
			Coord	xpos,ypos,zpos
zpos			.set	zpos+$0020
			.endrepeat
ypos		.set	ypos+$0020
		.endrepeat
xpos	.set	xpos+$0020
	.endrepeat
;--------------------------------------------------------------------


;--------------------------------------------------------------------
Bob_Points3:					; Pipe
;--------------------------------------------------------------------
	.incbin "../data/bobpoints3.bin"
;--------------------------------------------------------------------


;--------------------------------------------------------------------
Bob_Points4:					; Ball
;--------------------------------------------------------------------
	.incbin "../data/bobpoints4.bin"
;--------------------------------------------------------------------


;--------------------------------------------------------------------
SINUS:	; Sinus Table with 1024 Entries Words	
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


;--------------------------------------------------------------------
DivsTab:
;--------------------------------------------------------------------
xy	.set	-196
	.repeat 1024+64
	.word	($10000-$4000)/(xy+$100)
xy	.set	xy+1
	.endrepeat
;--------------------------------------------------------------------


;--------------------------------------------------------------------
Bob_Logo_Data:	.word	$00,$02,$04,$06,$08,$0a,$0c,$0e
		.word	$60,$62,$64,$66,$68,$6a,$6c,$6e
		.word	$c0,$c2,$c4,$c6,$c8,$ca,$cc,$ce
		.word	$ce,$ce,$ce,$ce,$ce,$ce,$ce,$ce
;--------------------------------------------------------------------


;--------------------------------------------------------------------
ScrMode:	.byte	$7f,$f9,$30,$f9,$1,$f5,0,0
;--------------------------------------------------------------------
ScrMode1:	.byte	$7f,$16,$30,$16,$1,$01,0,0
;--------------------------------------------------------------------
