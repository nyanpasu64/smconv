;--------------------------------------------------------------------------
.include "snes.inc"
.include "snes_decompress.inc"
.include "graphics.inc"
;--------------------------------------------------------------------------
.export DoDYCP
;--------------------------------------------------------------------------

SCROLLBUFFER	=	0a00h
SINEBUFFER	=	0200h

BG1MAP	=	07800h
BG2MAP	=	07400h
BG3MAP	=	08000h
BG3GFX	=	0a000h


;--------------------------------------------------------------------------
        .zeropage
;--------------------------------------------------------------------------
dsinepos:
	.res 2
scrollend:
	.res 2
column:
	.res 2
ysine:
	.res 2
xsine:
	.res 2
dsinexpos:
	.res 2
scrollgfxoffset:
	.res 2
bitcounter:
	.res 2
ysinestore:
	.res 2
xsinestore:
	.res 2
bitoffset:
	.res 2
scrollcharoffset:
	.res 2
scrollbitoffset:
	.res 2

;--------------------------------------------------------------------------
	.code
;--------------------------------------------------------------------------

;==========================================================================
;        Code (c) 1994 -Pan-/ANTHROX   All code can be used at will
;==========================================================================

;==========================================================================
DoDYCP:
;==========================================================================

	rep	#10h
	sep	#20h

	lda	#80h
	sta	REG_INIDISP

	ldx	#0000h
	stx	REG_VMADDL
cleardsvram:
	stz	REG_VMDATAL
	stz	REG_VMDATAH
	inx
	cpx	#4000h
	bne	cleardsvram

	ldx	#BG2MAP
	stx	REG_VMADDL
	ldx	#0000h
	lda	#01h
cleardtram:
	stz	REG_VMDATAL
	sta	REG_VMDATAH
	inx
	cpx	#0400h
	bne	cleardtram

	ldx	#BG1MAP
	stx	REG_VMADDL
	ldx	#0000h
	lda	#01h
cleardtram2:
	stz	REG_VMDATAL
	sta	REG_VMDATAH
	inx
	cpx	#0400h
	bne	cleardtram2

	ldx	#BG2MAP+0c1h
	stx	REG_VMADDL

	ldx	#0000h
copydotscreen:
	lda	dscreen1,x
	sta	REG_VMDATAL
	lda	dscreen2,x
	sta	REG_VMDATAH
	inx
	cpx	#0200h
	bne	copydotscreen

	ldx	#BG1MAP+0c1h
	stx	REG_VMADDL
	ldx	#0000h
copydotscreen2:
	lda	dscreen1,x
	sta	REG_VMDATAL
	lda	dscreen2,x
	sta	REG_VMDATAH
	inx
	cpx	#0200h
	bne	copydotscreen2

	DoDecompressDataVram gfx_boardsTiles, BG3GFX
	DoDecompressDataVram gfx_boardsMap, BG3MAP
	DoCopyPalette gfx_boardsPal, 64, 8

	ldx	#SINEBUFFER
zerogfxram:
	stz	0000h,x
	inx
	cpx	#SCROLLBUFFER+90h
	bne	zerogfxram

	lda	#1
	sta	REG_CGADD
	ldx	#7fffh
	stx	REG_CGDATA
	stx	REG_CGDATA

	lda	#33
	sta	REG_CGADD
	ldx	#7eeeh
	stx	REG_CGDATA
	stx	REG_CGDATA

	stz	REG_BGMODE		; mode 0, 8/8 dot

	lda	#(BG3MAP>>9)		; plane 3 map address $8000
	sta	REG_BG3SC
	lda	#(BG2MAP>>8)
	sta	REG_BG2SC		; plane 2 map address $7400
	lda	#(BG1MAP>>8)
	sta	REG_BG1SC		; plane 1 map address $7800

	stz	REG_BG12NBA		; plane 1&2 graphics data $0000
	lda	#(BG3GFX>>13)
	sta	REG_BG34NBA		; plane 3 graphics data $a000
	lda	#01h
	sta	REG_BG1HOFS		; shift first image of scroll right
	stz	REG_BG1HOFS
	sta	REG_BG1VOFS		; shift first image of scroll up
	stz	REG_BG1VOFS
	lda	#TM_BG3|TM_BG2|TM_BG1	;  Plane 1,2,3 Enabled
	sta	REG_TM

	ldx	#0000h
	stx	dsinepos		; reset sine position

	;ldx	#0000h
	stx	scrollend		; end scroll flag

	;ldx	#0000h
	stx	bitoffset
	stx	xsinestore
	stx	xsine
	stx	ysinestore
	stx	ysine

	;ldx	#0000h
	stx	scrollcharoffset

	;ldx	#0000h
	stx	scrollbitoffset

	ldx	#0100h
	stx	dsinexpos		; reset sine pos for X pos

	lda	#NMI_JOYPAD
	sta	REG_NMITIMEN

	lda	#0fh
	sta	REG_INIDISP
	
	ldx	#002ah
looptonotskip:
	jsr	DWaitVb
	dex
	bne	looptonotskip


;===========================================================================
;                            Start of DYXCP scroll
;===========================================================================
waitthis:
	jsr	DWaitVb

	jsr	MoveSVD
	jsr	dotscrsine
	jsr	movebscd

Dotjoypad:
	lda	REG_HVBJOY		; test if it's ok to read pad
	and	#01h
	bne	Dotjoypad		; nope, go back

	lda	REG_JOY1L		; read Controller 1
	ora	REG_JOY1H
	ora	scrollend		; check if scroll is ended
	bit	#0c0h
	beq	waitthis

	jsr	DWaitVb
	lda	#80h
	sta	REG_INIDISP
	stz	REG_HDMAEN
	stz	REG_TM
	jmp	DoDYCP

MoveSVD:
	rep	#10h			; x,y = 16 bit
	sep	#20h			; a = 8 bit
					; start of General DMA graphics copy routine
	stz	REG_DMAP3		; 0= 1 byte per register (not a word)
	lda	#<REG_VMDATA
	sta	REG_BBAD3		; 21xx   this is 2118 (VRAM)
	stz	REG_A1T3L
	lda	#>SINEBUFFER		; address = $7e0200
	sta	REG_A1T3H
	stz	REG_A1B3		; bank address of data in ram
	ldx	#0800h
	stx	REG_DAS3L		; # of bytes to be transferred
	stz	REG_VMAIN		; increase V-Ram address after writing to
					; $2118
	ldx	#0000h
	stx	REG_VMADDL		; address of VRAM to copy garphics in
	lda	#08h			; turn on bit 4 (%1000=8) of G-DMA channel
	sta	REG_MDMAEN
	lda	#80h			; increase V-Ram address after writing to
	sta	REG_VMAIN		; $2119
	rts


;==========================================================================
;                    Plot positions for each char's pixel
;==========================================================================
dotscrsine:
	rep	#30h

shootd:
	jsr	cleardsinebuffer	; clear gfx buffer

	ldx	#0000h			; column #
	stx	column
	stx	ysine			; reset column, y&xsine counters
	stx	xsine

	lda	dsinepos
	clc
	adc	#03h			; y speed and direction
	and	#01ffh
	sta	dsinepos
	sta	ysine			; store this value


	lda	dsinexpos
	clc
	adc	#01feh
	and	#01ffh			; x speed and direction
	sta	dsinexpos
	sta	xsine			; store this value

	ldx	#0000h			; scroll char gfx offset
	stx	scrollgfxoffset

	ldx	#0008h
	stx	bitcounter		; reset the counter

	ldx	ysine
	rep	#30h
	lda	DSCROLLSINE,x		; read sine data
	and	#00ffh			; get only 1 byte	y position
	sta	ysinestore		; store it

	ldx	xsine
	lda	DSCROLLSINEX,x		; get X position
	and	#0007h
	sta	xsinestore

	lda	DSCROLLSINEX,x
	and	#%11111000		; highest 5 bit and multiply by 16
	asl a
	asl a
	asl a				; *16
	asl a
	;clc
	adc	ysinestore
	sta	ysinestore

	sep	#20h

	ldy	#0000h
	sty	bitoffset		; clear bitoffset for scrollchar

beforesined:
	ldy	scrollgfxoffset		; current scrollgfx offset
scrollersined:
	ldx	bitoffset		;current bit offset (0-7)
	lda	SCROLLBUFFER,y
	and	BITON,x			; get bit position value
	beq	overbitd		; in case of 0, don't draw pixel
	ldx	ysinestore	
	lda	SINEBUFFER,x		; draw bit on the screen
	ldx	xsinestore
	ora	BITON,x			; get bit # to put on screen
	ldx	ysinestore

	sta	SINEBUFFER,x
overbitd:
	iny				; get next char
	ldx	ysinestore
	inx
	inx
	stx	ysinestore		; increase the sine data (to reach next line)
					; character counter
	dec	bitcounter
	;lda	bitcounter
	bne	scrollersined
	lda	#08h
	sta	bitcounter		; reset the counter

	jsr	incds
	ldy	scrollgfxoffset		; get current scroll char location
					; increase bit offset
	inc	bitoffset
	lda	bitoffset
	cmp	#08h			; increase scroll bit offset
	bne	scrollersined

	stz	bitoffset		; yes; reset bit offset
	lda	#08h
	sta	bitcounter		; reset char counter offset

	rep	#30h
	lda	scrollgfxoffset
	clc
	adc	#0008h			; add 8 to char buffer offset
	sta	scrollgfxoffset

	sep	#20h
	inc	column			; increase # of columns
	jsr	incds

	lda	column
	cmp	#0eh
	bne	beforesined

	rts


incds:
	rep	#30h
	lda	xsine
	inc a
	inc a				; increase X angle
	inc a
	and	#01ffh
	sta	xsine

	lda	ysine
	inc a				; increase Y angle
	inc a
	and	#01ffh
	sta	ysine

	ldx	ysine
	rep	#30h
	lda	DSCROLLSINE,x		; read sine data
	and	#00ffh			; get only 1 byte	y position
	sta	ysinestore		; store it
	ldx	xsine
	lda	DSCROLLSINEX,x		; get X position
	and	#0007h
	sta	xsinestore
	lda	DSCROLLSINEX,x
	and	#%11111000
	asl a
	asl a
	asl a
	asl a
	;clc
	adc	ysinestore
	sta	ysinestore
	sep	#20h
	rts

movebscd:
	rep	#30h
	lda	#SCROLLBUFFER
	tcd
	sep	#20h

	asl	80h
	rol	78h
	rol	70h
	rol	68h
	rol	60h
	rol	58h
	rol	50h
	rol	48h
	rol	40h
	rol	38h
	rol	30h
	rol	28h
	rol	20h
	rol	18h
	rol	10h
	rol	08h
	rol	00h

	asl	81h
	rol	79h
	rol	71h
	rol	69h
	rol	61h
	rol	59h
	rol	51h
	rol	49h
	rol	41h
	rol	39h
	rol	31h
	rol	29h
	rol	21h
	rol	19h
	rol	11h
	rol	09h
	rol	01h

	asl	82h
	rol	7ah
	rol	72h
	rol	6ah
	rol	62h
	rol	5ah
	rol	52h
	rol	4ah
	rol	42h
	rol	3ah
	rol	32h
	rol	2ah
	rol	22h
	rol	1ah
	rol	12h
	rol	0ah
	rol	02h

	asl	83h
	rol	7bh
	rol	73h
	rol	6bh
	rol	63h
	rol	5bh
	rol	53h
	rol	4bh
	rol	43h
	rol	3bh
	rol	33h
	rol	2bh
	rol	23h
	rol	1bh
	rol	13h
	rol	0bh
	rol	03h

	asl	84h
	rol	7ch
	rol	74h
	rol	6ch
	rol	64h
	rol	5ch
	rol	54h
	rol	4ch
	rol	44h
	rol	3ch
	rol	34h
	rol	2ch
	rol	24h
	rol	1ch
	rol	14h
	rol	0ch
	rol	04h

	asl	85h
	rol	7dh
	rol	75h
	rol	6dh
	rol	65h
	rol	5dh
	rol	55h
	rol	4dh
	rol	45h
	rol	3dh
	rol	35h
	rol	2dh
	rol	25h
	rol	1dh
	rol	15h
	rol	0dh
	rol	05h

	asl	86h
	rol	7eh
	rol	76h
	rol	6eh
	rol	66h
	rol	5eh
	rol	56h
	rol	4eh
	rol	46h
	rol	3eh
	rol	36h
	rol	2eh
	rol	26h
	rol	1eh
	rol	16h
	rol	0eh
	rol	06h

	asl	87h
	rol	7fh
	rol	77h
	rol	6fh
	rol	67h
	rol	5fh
	rol	57h
	rol	4fh
	rol	47h
	rol	3fh
	rol	37h
	rol	2fh
	rol	27h
	rol	1fh
	rol	17h
	rol	0fh
	rol	07h

	rep	#30h
	lda	#0000h
	tcd
	sep	#20h

	lda	scrollbitoffset
	inc a
	and	#07h
	sta	scrollbitoffset
	beq	Getchard
	rts

Getchard:
	rep	#30h
	ldx	scrollcharoffset
	lda	dscrolltxt,x
	beq	resetbscrposd
	and	#003fh
	asl a
	asl a
	asl a
	tax
	sep	#20h
	ldy	#0000h
copybscrdatad:
	lda	Dscrollchar,x
	sta	SCROLLBUFFER+80h,y
	inx
	iny
	cpy	#08h
	bne	copybscrdatad
	ldx	scrollcharoffset
	inx
	stx	scrollcharoffset
	rts

resetbscrposd:
	rep	#30h
	lda	#00c0h
	sta	scrollend
	ldx	#0000h
	stx	scrollcharoffset
	bra	Getchard


;==========================================================================
;                        Vertical Blank Wait Routine
;==========================================================================
DWaitVb:	
	lda	REG_RDNMI
	bpl     DWaitVb	; is the number higher than #$7f? (#$80-$ff)
			; bpl tests bit #7 ($80) if this bit is set it means
			; the byte is negative (BMI, Branch on Minus)
			; BPL (Branch on Plus) if bit #7 is set in REG_RDNMI
			; it means that it is at the start of V-Blank
			; if not it will keep testing REG_RDNMI until bit #7
			; is on (which would make it a negative (BMI)
DWaitVb2:
	lda	REG_RDNMI
	bmi	DWaitVb2
	rts

;==========================================================================

cleardsinebuffer:
	ldx	#SINEBUFFER
:	stz	00h,x
	inx
	cpx	#SINEBUFFER+0ffh
	bne	:-

	ldx	#SINEBUFFER+100h
:	stz	00h,x
	inx
	cpx	#SINEBUFFER+1ffh
	bne	:-

	ldx	#SINEBUFFER+200h
:	stz	00h,x
	inx
	cpx	#SINEBUFFER+2ffh
	bne	:-

	ldx	#SINEBUFFER+300h
:	stz	00h,x
	inx
	cpx	#SINEBUFFER+3ffh
	bne	:-

	ldx	#SINEBUFFER+400h
:	stz	00h,x
	inx
	cpx	#SINEBUFFER+4ffh
	bne	:-

	ldx	#SINEBUFFER+500h
:	stz	00h,x
	inx
	cpx	#SINEBUFFER+5ffh
	bne	:-

	ldx	#SINEBUFFER+600h
:	stz	00h,x
	inx
	cpx	#SINEBUFFER+6ffh
	bne	:-

	ldx	#SINEBUFFER+700h
:	stz	00h,x
	inx
	cpx	#SINEBUFFER+7ffh
	bne	:-

	rts


Dscrollchar:
;============================================================================
;= Cyber Font-Editor V1.4  Rel. by Frantic (c) 1991-1992 Sanity Productions =
;============================================================================
	.byte	$3c,$66,$6e,$6e,$60,$62,$3c,$00	;' '
	.byte	$18,$3c,$66,$7e,$66,$66,$66,$00	;'!'
	.byte	$7c,$66,$66,$7c,$66,$66,$7c,$00	;'"'
	.byte	$3c,$66,$60,$60,$60,$66,$3c,$00	;'#'
	.byte	$78,$6c,$66,$66,$66,$6c,$78,$00	;'$'
	.byte	$7e,$60,$60,$78,$60,$60,$7e,$00	;'%'
	.byte	$7e,$60,$60,$78,$60,$60,$60,$00	;'&'
	.byte	$3c,$66,$60,$6e,$66,$66,$3c,$00	;'''
	.byte	$66,$66,$66,$7e,$66,$66,$66,$00	;'('
	.byte	$3c,$18,$18,$18,$18,$18,$3c,$00	;')'
	.byte	$1e,$0c,$0c,$0c,$0c,$6c,$38,$00	;'*'
	.byte	$66,$6c,$78,$70,$78,$6c,$66,$00	;'+'
	.byte	$60,$60,$60,$60,$60,$60,$7e,$00	;','
	.byte	$63,$77,$7f,$6b,$63,$63,$63,$00	;'-'
	.byte	$66,$76,$7e,$7e,$6e,$66,$66,$00	;'.'
	.byte	$3c,$66,$66,$66,$66,$66,$3c,$00	;'/'
	.byte	$7c,$66,$66,$7c,$60,$60,$60,$00	;'0'
	.byte	$3c,$66,$66,$66,$66,$3c,$0e,$00	;'1'
	.byte	$7c,$66,$66,$7c,$78,$6c,$66,$00	;'2'
	.byte	$3c,$66,$60,$3c,$06,$66,$3c,$00	;'3'
	.byte	$7e,$18,$18,$18,$18,$18,$18,$00	;'4'
	.byte	$66,$66,$66,$66,$66,$66,$3c,$00	;'5'
	.byte	$66,$66,$66,$66,$66,$3c,$18,$00	;'6'
	.byte	$63,$63,$63,$6b,$7f,$77,$63,$00	;'7'
	.byte	$66,$66,$3c,$18,$3c,$66,$66,$00	;'8'
	.byte	$66,$66,$66,$3c,$18,$18,$18,$00	;'9'
	.byte	$7e,$06,$0c,$18,$30,$60,$7e,$00	;':'
	.byte	$3c,$30,$30,$30,$30,$30,$3c,$00	;';'
	.byte	$00,$60,$30,$18,$0c,$06,$03,$00	;'<'
	.byte	$3c,$0c,$0c,$0c,$0c,$0c,$3c,$00	;'='
	.byte	$10,$38,$6c,$c6,$00,$00,$00,$00	;'>'
	.byte	$00,$00,$00,$00,$00,$00,$00,$7e	;'?'
	.byte	$00,$00,$00,$00,$00,$00,$00,$00	;'@'
	.byte	$18,$18,$18,$18,$00,$00,$18,$00	;'A'
	.byte	$66,$66,$66,$00,$00,$00,$00,$00	;'B'
	.byte	$66,$66,$ff,$66,$ff,$66,$66,$00	;'C'
	.byte	$18,$3e,$60,$3c,$06,$7c,$18,$00	;'D'
	.byte	$62,$66,$0c,$18,$30,$66,$46,$00	;'E'
	.byte	$3c,$66,$3c,$38,$67,$66,$3f,$00	;'F'
	.byte	$06,$0c,$18,$00,$00,$00,$00,$00	;'G'
	.byte	$0c,$18,$30,$30,$30,$18,$0c,$00	;'H'
	.byte	$30,$18,$0c,$0c,$0c,$18,$30,$00	;'I'
	.byte	$00,$66,$3c,$ff,$3c,$66,$00,$00	;'J'
	.byte	$00,$18,$18,$7e,$18,$18,$00,$00	;'K'
	.byte	$00,$00,$00,$00,$00,$18,$18,$30	;'L'
	.byte	$00,$00,$00,$7e,$00,$00,$00,$00	;'M'
	.byte	$00,$00,$00,$00,$00,$18,$18,$00	;'N'
	.byte	$00,$03,$06,$0c,$18,$30,$60,$00	;'O'
	.byte	$3c,$66,$6e,$76,$66,$66,$3c,$00	;'P'
	.byte	$18,$18,$38,$18,$18,$18,$7e,$00	;'Q'
	.byte	$3c,$66,$06,$0c,$30,$60,$7e,$00	;'R'
	.byte	$3c,$66,$06,$1c,$06,$66,$3c,$00	;'S'
	.byte	$06,$0e,$1e,$66,$7f,$06,$06,$00	;'T'
	.byte	$7e,$60,$7c,$06,$06,$66,$3c,$00	;'U'
	.byte	$3c,$66,$60,$7c,$66,$66,$3c,$00	;'V'
	.byte	$7e,$66,$0c,$18,$18,$18,$18,$00	;'W'
	.byte	$3c,$66,$66,$3c,$66,$66,$3c,$00	;'X'
	.byte	$3c,$66,$66,$3e,$06,$66,$3c,$00	;'Y'
	.byte	$00,$00,$18,$00,$00,$18,$00,$00	;'Z'
	.byte	$00,$00,$18,$00,$00,$18,$18,$30	;'['
	.byte	$0e,$18,$30,$60,$30,$18,$0e,$00	;'\'
	.byte	$00,$00,$7e,$00,$7e,$00,$00,$00	;']'
	.byte	$70,$18,$0c,$06,$0c,$18,$70,$00	;'^'
	.byte	$3c,$66,$06,$0c,$18,$00,$18,$00	;'_'

dscrolltxt:
	;	different y-x bit position scroll
	.byte	"    D-Y-X-B-P    YET ANOTHER ROUTINE NEVER SEEN ON THIS "
	.byte	"MACHINE THIS CODE IS OLD, BUT I NEVER USED IT.. SO HERE IT "
	.byte	"IS FOR YOU TO PLAY WITH WHY DOES IT SEEM LIKE I'M THE "
	.byte	"ONLY GUY GIVING OUT SOURCE CODES? THERE'RE SO MANY CHEAPOS OUT "
	.byte	"THERE THAT WOULDN'T EVEN GIVE OUT THEIR DIRTY UNDERWEAR  "
	.byte	"UNBELIEVABLE.... LET'S JUST GO TO THE NEXT PART....   "
	.byte	"                   ",0,0

BITON:
	.byte	$80,$40,$20,$10,$8,$4,$2,$1

DSCROLLSINE:
 .byte  56,57,57,58,59,59,60,61,61,62,63,64,64,65,66,66,67,68,68,69
 .byte  70,70,71,72,72,73,74,74,75,76,76,77,77,78,79,79,80,81,81,82
 .byte  82,83,84,84,85,85,86,87,87,88,88,89,89,90,90,91,92,92,93,93
 .byte  94,94,95,95,96,96,97,97,97,98,98,99,99,100,100,101,101,101
 .byte  102,102,103,103,103,104,104,104,105,105,105,106,106,106,107
 .byte  107,107,107,108,108,108,108,109,109,109,109,110,110,110,110
 .byte  110,110,111,111,111,111,111,111,111,111,112,112,112,112,112
 .byte  112,112,112,112,112,112,112,112,112,112,112,112,112,112,112
 .byte  112,111,111,111,111,111,111,111,111,110,110,110,110,110,110
 .byte  109,109,109,109,108,108,108,108,107,107,107,107,106,106,106
 .byte  105,105,105,104,104,104,103,103,103,102,102,101,101,101,100
 .byte  100,99,99,98,98,97,97,97,96,96,95,95,94,94,93,93,92,92,91,90
 .byte  90,89,89,88,88,87,87,86,85,85,84,84,83,82,82,81,81,80,79,79
 .byte  78,77,77,76,76,75,74,74,73,72,72,71,70,70,69,68,68,67,66,66
 .byte  65,64,64,63,62,61,61,60,59,59,58,57,57,56,55,55,54,53,53,52
 .byte  51,51,50,49,48,48,47,46,46,45,44,44,43,42,42,41,40,40,39,38
 .byte  38,37,36,36,35,35,34,33,33,32,31,31,30,30,29,28,28,27,27,26
 .byte  25,25,24,24,23,23,22,22,21,20,20,19,19,18,18,17,17,16,16,15
 .byte  15,15,14,14,13,13,12,12,11,11,11,10,10,9,9,9,8,8,8,7,7,7,6
 .byte  6,6,5,5,5,5,4,4,4,4,3,3,3,3,2,2,2,2,2,2,1,1,1,1,1,1,1,1,0,0
 .byte  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,2,2,2
 .byte  2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,6,6,6,7,7,7,8,8,8,9,9,9,10,10
 .byte  11,11,11,12,12,13,13,14,14,15,15,15,16,16,17,17,18,18,19,19
 .byte  20,20,21,22,22,23,23,24,24,25,25,26,27,27,28,28,29,30,30,31
 .byte  31,32,33,33,34,35,35,36,36,37,38,38,39,40,40,41,42,42,43,44
 .byte  44,45,46,46,47,48,48,49,50,51,51,52,53,53,54,55

 .byte  56,57,57,58,59,59,60,61,61,62,63,64,64,65,66,66,67,68,68,69
 .byte  70,70,71,72,72,73,74,74,75,76,76,77,77,78,79,79,80,81,81,82
 .byte  82,83,84,84,85,85,86,87,87,88,88,89,89,90,90,91,92,92,93,93
 .byte  94,94,95,95,96,96,97,97,97,98,98,99,99,100,100,101,101,101
 .byte  102,102,103,103,103,104,104,104,105,105,105,106,106,106,107
 .byte  107,107,107,108,108,108,108,109,109,109,109,110,110,110,110
 .byte  110,110,111,111,111,111,111,111,111,111,112,112,112,112,112
 .byte  112,112,112,112,112,112,112,112,112,112,112,112,112,112,112
 .byte  112,111,111,111,111,111,111,111,111,110,110,110,110,110,110
 .byte  109,109,109,109,108,108,108,108,107,107,107,107,106,106,106
 .byte  105,105,105,104,104,104,103,103,103,102,102,101,101,101,100
 .byte  100,99,99,98,98,97,97,97,96,96,95,95,94,94,93,93,92,92,91,90
 .byte  90,89,89,88,88,87,87,86,85,85,84,84,83,82,82,81,81,80,79,79
 .byte  78,77,77,76,76,75,74,74,73,72,72,71,70,70,69,68,68,67,66,66
 .byte  65,64,64,63,62,61,61,60,59,59,58,57,57,56,55,55,54,53,53,52
 .byte  51,51,50,49,48,48,47,46,46,45,44,44,43,42,42,41,40,40,39,38
 .byte  38,37,36,36,35,35,34,33,33,32,31,31,30,30,29,28,28,27,27,26
 .byte  25,25,24,24,23,23,22,22,21,20,20,19,19,18,18,17,17,16,16,15
 .byte  15,15,14,14,13,13,12,12,11,11,11,10,10,9,9,9,8,8,8,7,7,7,6
 .byte  6,6,5,5,5,5,4,4,4,4,3,3,3,3,2,2,2,2,2,2,1,1,1,1,1,1,1,1,0,0
 .byte  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,2,2,2
 .byte  2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,6,6,6,7,7,7,8,8,8,9,9,9,10,10
 .byte  11,11,11,12,12,13,13,14,14,15,15,15,16,16,17,17,18,18,19,19
 .byte  20,20,21,22,22,23,23,24,24,25,25,26,27,27,28,28,29,30,30,31
 .byte  31,32,33,33,34,35,35,36,36,37,38,38,39,40,40,41,42,42,43,44
 .byte  44,45,46,46,47,48,48,49,50,51,51,52,53,53,54,55

DSCROLLSINEX:
 .byte  60,61,61,62,63,64,64,65,66,67,67,68,69,70,70,71,72,72,73,74
 .byte  75,75,76,77,77,78,79,80,80,81,82,82,83,84,84,85,86,86,87,88
 .byte  88,89,90,90,91,91,92,93,93,94,95,95,96,96,97,97,98,99,99,100
 .byte  100,101,101,102,102,103,103,104,104,105,105,106,106,107,107
 .byte  108,108,109,109,109,110,110,111,111,111,112,112,113,113,113
 .byte  114,114,114,115,115,115,115,116,116,116,116,117,117,117,117
 .byte  118,118,118,118,118,119,119,119,119,119,119,119,119,120,120
 .byte  120,120,120,120,120,120,120,120,120,120,120,120,120,120,120
 .byte  120,120,120,120,119,119,119,119,119,119,119,119,118,118,118
 .byte  118,118,117,117,117,117,116,116,116,116,115,115,115,115,114
 .byte  114,114,113,113,113,112,112,111,111,111,110,110,109,109,109
 .byte  108,108,107,107,106,106,105,105,104,104,103,103,102,102,101
 .byte  101,100,100,99,99,98,97,97,96,96,95,95,94,93,93,92,91,91,90
 .byte  90,89,88,88,87,86,86,85,84,84,83,82,82,81,80,80,79,78,77,77
 .byte  76,75,75,74,73,72,72,71,70,70,69,68,67,67,66,65,64,64,63,62
 .byte  61,61,60,59,59,58,57,56,56,55,54,53,53,52,51,50,50,49,48,48
 .byte  47,46,45,45,44,43,43,42,41,40,40,39,38,38,37,36,36,35,34,34
 .byte  33,32,32,31,30,30,29,29,28,27,27,26,25,25,24,24,23,23,22,21
 .byte  21,20,20,19,19,18,18,17,17,16,16,15,15,14,14,13,13,12,12,11
 .byte  11,11,10,10,9,9,9,8,8,7,7,7,6,6,6,5,5,5,5,4,4,4,4,3,3,3,3,2
 .byte  2,2,2,2,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 .byte  0,0,0,1,1,1,1,1,1,1,1,2,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,6,6
 .byte  6,7,7,7,8,8,9,9,9,10,10,11,11,11,12,12,13,13,14,14,15,15,16
 .byte  16,17,17,18,18,19,19,20,20,21,21,22,23,23,24,24,25,25,26,27
 .byte  27,28,29,29,30,30,31,32,32,33,34,34,35,36,36,37,38,38,39,40
 .byte  40,41,42,43,43,44,45,45,46,47,48,48,49,50,50,51,52,53,53,54
 .byte  55,56,56,57,58,59


 .byte  60,61,61,62,63,64,64,65,66,67,67,68,69,70,70,71,72,72,73,74
 .byte  75,75,76,77,77,78,79,80,80,81,82,82,83,84,84,85,86,86,87,88
 .byte  88,89,90,90,91,91,92,93,93,94,95,95,96,96,97,97,98,99,99,100
 .byte  100,101,101,102,102,103,103,104,104,105,105,106,106,107,107
 .byte  108,108,109,109,109,110,110,111,111,111,112,112,113,113,113
 .byte  114,114,114,115,115,115,115,116,116,116,116,117,117,117,117
 .byte  118,118,118,118,118,119,119,119,119,119,119,119,119,120,120
 .byte  120,120,120,120,120,120,120,120,120,120,120,120,120,120,120
 .byte  120,120,120,120,119,119,119,119,119,119,119,119,118,118,118
 .byte  118,118,117,117,117,117,116,116,116,116,115,115,115,115,114
 .byte  114,114,113,113,113,112,112,111,111,111,110,110,109,109,109
 .byte  108,108,107,107,106,106,105,105,104,104,103,103,102,102,101
 .byte  101,100,100,99,99,98,97,97,96,96,95,95,94,93,93,92,91,91,90
 .byte  90,89,88,88,87,86,86,85,84,84,83,82,82,81,80,80,79,78,77,77
 .byte  76,75,75,74,73,72,72,71,70,70,69,68,67,67,66,65,64,64,63,62
 .byte  61,61,60,59,59,58,57,56,56,55,54,53,53,52,51,50,50,49,48,48
 .byte  47,46,45,45,44,43,43,42,41,40,40,39,38,38,37,36,36,35,34,34
 .byte  33,32,32,31,30,30,29,29,28,27,27,26,25,25,24,24,23,23,22,21
 .byte  21,20,20,19,19,18,18,17,17,16,16,15,15,14,14,13,13,12,12,11
 .byte  11,11,10,10,9,9,9,8,8,7,7,7,6,6,6,5,5,5,5,4,4,4,4,3,3,3,3,2
 .byte  2,2,2,2,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 .byte  0,0,0,1,1,1,1,1,1,1,1,2,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,6,6
 .byte  6,7,7,7,8,8,9,9,9,10,10,11,11,11,12,12,13,13,14,14,15,15,16
 .byte  16,17,17,18,18,19,19,20,20,21,21,22,23,23,24,24,25,25,26,27
 .byte  27,28,29,29,30,30,31,32,32,33,34,34,35,36,36,37,38,38,39,40
 .byte  40,41,42,43,43,44,45,45,46,47,48,48,49,50,50,51,52,53,53,54
 .byte  55,56,56,57,58,59

dscreen1:
	.byte	0,$0,$0,$0,$0,$0,$0,$0,$0,$10,$20,$30,$40,$50,$60,$70,$80,$90,$a0,$b0,$c0,$d0,$e0,$f0,$0,$0,$0,$0,$0,$0,$0,$0
	.byte	0,$0,$0,$0,$0,$0,$0,$0,$1,$11,$21,$31,$41,$51,$61,$71,$81,$91,$a1,$b1,$c1,$d1,$e1,$f1,$0,$0,$0,$0,$0,$0,$0,$0
	.byte	0,$0,$0,$0,$0,$0,$0,$0,$2,$12,$22,$32,$42,$52,$62,$72,$82,$92,$a2,$b2,$c2,$d2,$e2,$f2,$0,$0,$0,$0,$0,$0,$0,$0
	.byte	0,$0,$0,$0,$0,$0,$0,$0,$3,$13,$23,$33,$43,$53,$63,$73,$83,$93,$a3,$b3,$c3,$d3,$e3,$f3,$0,$0,$0,$0,$0,$0,$0,$0
	.byte	0,$0,$0,$0,$0,$0,$0,$0,$4,$14,$24,$34,$44,$54,$64,$74,$84,$94,$a4,$b4,$c4,$d4,$e4,$f4,$0,$0,$0,$0,$0,$0,$0,$0
	.byte	0,$0,$0,$0,$0,$0,$0,$0,$5,$15,$25,$35,$45,$55,$65,$75,$85,$95,$a5,$b5,$c5,$d5,$e5,$f5,$0,$0,$0,$0,$0,$0,$0,$0
	.byte	0,$0,$0,$0,$0,$0,$0,$0,$6,$16,$26,$36,$46,$56,$66,$76,$86,$96,$a6,$b6,$c6,$d6,$e6,$f6,$0,$0,$0,$0,$0,$0,$0,$0
	.byte	0,$0,$0,$0,$0,$0,$0,$0,$7,$17,$27,$37,$47,$57,$67,$77,$87,$97,$a7,$b7,$c7,$d7,$e7,$f7,$0,$0,$0,$0,$0,$0,$0,$0
	.byte	0,$0,$0,$0,$0,$0,$0,$0,$8,$18,$28,$38,$48,$58,$68,$78,$88,$98,$a8,$b8,$c8,$d8,$e8,$f8,$0,$0,$0,$0,$0,$0,$0,$0
	.byte	0,$0,$0,$0,$0,$0,$0,$0,$9,$19,$29,$39,$49,$59,$69,$79,$89,$99,$a9,$b9,$c9,$d9,$e9,$f9,$0,$0,$0,$0,$0,$0,$0,$0
	.byte	0,$0,$0,$0,$0,$0,$0,$0,$a,$1a,$2a,$3a,$4a,$5a,$6a,$7a,$8a,$9a,$aa,$ba,$ca,$da,$ea,$fa,$0,$0,$0,$0,$0,$0,$0,$0
	.byte	0,$0,$0,$0,$0,$0,$0,$0,$b,$1b,$2b,$3b,$4b,$5b,$6b,$7b,$8b,$9b,$ab,$bb,$cb,$db,$eb,$fb,$0,$0,$0,$0,$0,$0,$0,$0
	.byte	0,$0,$0,$0,$0,$0,$0,$0,$c,$1c,$2c,$3c,$4c,$5c,$6c,$7c,$8c,$9c,$ac,$bc,$cc,$dc,$ec,$fc,$0,$0,$0,$0,$0,$0,$0,$0
	.byte	0,$0,$0,$0,$0,$0,$0,$0,$d,$1d,$2d,$3d,$4d,$5d,$6d,$7d,$8d,$9d,$ad,$bd,$cd,$dd,$ed,$fd,$0,$0,$0,$0,$0,$0,$0,$0
	.byte	0,$0,$0,$0,$0,$0,$0,$0,$e,$1e,$2e,$3e,$4e,$5e,$6e,$7e,$8e,$9e,$ae,$be,$ce,$de,$ee,$fe,$0,$0,$0,$0,$0,$0,$0,$0
	.byte	0,$0,$0,$0,$0,$0,$0,$0,$f,$1f,$2f,$3f,$4f,$5f,$6f,$7f,$8f,$9f,$af,$bf,$cf,$df,$ef,$ff,$0,$0,$0,$0,$0,$0,$0,$0

dscreen2:
	.byte	1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1
	.byte	1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1
	.byte	1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1
	.byte	1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1
	.byte	1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1
	.byte	1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1
	.byte	1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1
	.byte	1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1
	.byte	1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1
	.byte	1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1
	.byte	1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1
	.byte	1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1
	.byte	1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1
	.byte	1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1
	.byte	1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1
	.byte	1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1

