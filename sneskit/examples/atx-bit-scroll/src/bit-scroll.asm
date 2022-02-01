;-------------------------------------------------------------------------;
.include "graphics.inc"
.include "render_string.inc"
.include "snes.inc"
.include "snes_decompress.inc"
.include "snes_joypad.inc"
.include "snes_zvars.inc"
;-------------------------------------------------------------------------;
.import clear_vram
;-------------------------------------------------------------------------;
.export DoBitScroll
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
VRAM_BUFFER	=	0200h
CHAR_SCROLL	=	0a00h
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
HDMA_GX		=	1100h
HDMA_GY		=	1300h
HDMA_PAL	=	1500h
HDMA_PAL44	=	1544h
HDMA_COL	=	1600h
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
BG1GFX = 0a000h
BG2GFX = 0c000h
BG1MAP = 01800h
BG2MAP = 04000h
BG3MAP = 01000h
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
.zeropage
;/////////////////////////////////////////////////////////////////////////;


;-------------------------------------------------------------------------;
char:
	.res 1
cur_char:
	.res 1
scrolltext_offset:
	.res 1
vert_offs:
	.res 1
sine_pos:
	.res 2
bit_offs:
	.res 2
scroll_char:
	.res 2
counter:
	.res 2
colh:
	.res 2
coll:
	.res 2
sine_data:
	.res 2
sine_pos_data:
	.res 2
sine_inc_offs:
	.res 2
;--------------------------------------------------------------------------


;/////////////////////////////////////////////////////////////////////////;
	.code
;/////////////////////////////////////////////////////////////////////////;


;=========================================================================;
;      Code (c) 1993-94 -Pan-/ANTHROX   All code can be used at will!
;=========================================================================;                     

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
DoBitScroll:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;

	rep	#10h
	sep	#20h

	jsr	clear_vram

;-------------------------------------------------------------------------;
;                            Copy graf-x data
;-------------------------------------------------------------------------;

	DoDecompressDataVram gfx_logoTiles, BG2GFX
	DoDecompressDataVram gfx_charTiles, BG1GFX

;-------------------------------------------------------------------------;
;                               Copy Colors
;-------------------------------------------------------------------------;

	DoCopyPalette gfx_logoPal, 16, 16
	DoCopyPalette gfx_char2Pal, 32, 16
	DoCopyPalette gfx_charPal, 48,16

;-------------------------------------------------------------------------;
;                               Make Tiles
;-------------------------------------------------------------------------;

	DoDecompressDataVram gfx_logoMap, BG2MAP

;-------------------------------------------------------------------------;
;                          Start of Scroll Setup
;-------------------------------------------------------------------------;

	lda	#02h
	sta	sine_pos_data   	; sine position data
	lda	#0ffh
	sta	sine_inc_offs		; sine inc offset

	ldx	#BG3MAP
	stx	REG_VMADDL

	ldx	#0000h
	stx	scrolltext_offset	; reset scroll text offset
	stx	sine_pos		; reset sine position
	stx	vert_offs		; scroll counter
	stx	vert_offs		; vert waver sine offset

	lda	#80h
clear7400:
	sta	REG_VMDATAL
	stz	REG_VMDATAH
	inx
	cpx	#0400h
	bne	clear7400

	lda	#20h
	sta	scrolltext_offset

	ldx	#122bh
drawingsine:
	stx	REG_VMADDL
	lda	#80h
	sta	REG_VMAIN
	ldx	#0000h
	stx	char
drawchar:
	lda	char		; get first char 
	sta	cur_char	; make it the current char
drawflexpattern:
	lda	cur_char	;current char
	sta	REG_VMDATAL	; write it into V-Ram
	lda	scrolltext_offset
	sta	REG_VMDATAH
	lda	cur_char
	clc
	adc	#08h		; add #8 to the current char value
				; since our grid will be 32 columns
				; and 8 rows we add #8 to the current
				; char value for the next character
				; store it back
	sta	cur_char

	inx
	cpx	#0010h		; did we do 32 columns?
	bne	drawflexpattern

spaceout:
	lda	#80h
	sta	REG_VMDATAL
	lda	scrolltext_offset
	sta	REG_VMDATAH
	dex
	bne	spaceout

	ldx	#0000h		; set X back to $0
	inc	char		; increase Row counter
	lda	char
	cmp	#08h		; did we do all 8 rows?
	bne	drawchar	

	stz	scrolltext_offset

	lda	#80h
	sta	REG_VMAIN
	
	ldx	#BG1MAP
	stx	REG_VMADD
	ldx	#1024
	ldy	#0
:	sty	REG_VMDATA
	dex
	bne	:-

	jsr	HDMA

	lda	#BGMODE_PRIO|BGMODE_1
	sta	REG_BGMODE

	lda	#BG3MAP>>8
	sta	REG_BG3SC

	lda	#BG2MAP>>9
	sta	REG_BG2SC

	lda	#(BG1MAP/1024)<<2
	sta	REG_BG1SC

	lda	#^TEXT_00
	jsr	RenderStringSetBank	; use GRAPHICS bank

	lda	#PALETTE3		; palette to use
	ldx	#TEXT_00		; string to render
	ldy	#BG1MAP+5+14*32		; location to render text
	jsr	RenderString

	lda	#PALETTE2
	ldx	#TEXT_01
	ldy	#BG1MAP+4+16*32
	jsr	RenderStringBank0	; before rendering string set bank to 0

	lda	#PALETTE2
	jsr	RenderStringSetPalette
	ldx	#TEXT_02
	ldy	#BG1MAP+10+18*32
	jsr	RenderStringGetPalette

	ldx	#TEXT_03
	ldy	#BG1MAP+8+20*32
	jsr	RenderStringGetPalette

	ldx	#TEXT_04
	ldy	#BG1MAP+5+22*32
	jsr	RenderStringGetPalette

	ldx	#TEXT_05
	ldy	#BG1MAP+3+24*32
	jsr	RenderStringGetPalette

	lda	#(BG2GFX>>9)+(BG1GFX>>13)
	sta	REG_BG12NBA	; BG2 gfx @ $a000 BG1 gfx data $c000
	stz	REG_BG34NBA	; bg3 gfx at $0000

	lda	#TM_BG3|TM_BG2|TM_BG1
	sta	REG_TM

	lda	#0fch
	sta	REG_BG2HOFS
	stz	REG_BG2HOFS

	sta	REG_BG2VOFS
	stz	REG_BG2VOFS

	ldx	#0888h
clearscrollbuff:
	stz	VRAM_BUFFER,x	; erase data in scroll vram buffer
	dex
	bne	clearscrollbuff

	lda	#NMI_ON|NMI_JOYPAD
	sta	REG_NMITIMEN

	cli

	lda	#0fh
	sta	REG_INIDISP

;==========================================================================
;                                 Core of Program
;==========================================================================


Mainprog:
	jsr	WaitVb
	jsr	MoveSV		; move sine gfx during VB
	jsr	bitsine

	lda	joy1_down+1
	ora	joy2_down+1
	bit	#JOYPADH_START
	beq	Mainprog

	lda	#80h
	sta	REG_INIDISP
	stz	REG_HDMAEN
	jmp	DoBitScroll

;========================================================================
;                        Move Scroll gfx in v-blank
;========================================================================

MoveSV:
	stz	REG_DMAP7	; 0= 1 byte per register (not a word!)
	lda	#<REG_VMDATA
	sta	REG_BBAD7	; 21xx   this is 2118 (VRAM)
	stz	REG_A1T7L
	lda	#>VRAM_BUFFER	; address = $7e0200
	sta	REG_A1T7H
	stz	REG_A1B7	; bank address of data in ram
	ldx	#0800h
	stx	REG_DAS7L	; # of bytes to be transferred
	stz	REG_VMAIN	; increase V-Ram address after writing to
				; REG_VMDATAL
	ldx	#0000h
	stx	REG_VMADDL	; address of VRAM to copy garphics in
	lda	#%10000000	; turn on bit 7 (%10000000=80) of G-DMA channel
	sta	REG_MDMAEN

	;   this will read a vram address and send it to wram
	lda	#DMAP_PPU_TO_CPU
	sta	REG_DMAP7	; 0= 1 byte per register (not a word!)
	lda	#<REG_VMDATAREAD
	sta	REG_BBAD7	; 21xx   this is 2139 (VRAM read)
	stz	REG_A1T7L
	lda	#>VRAM_BUFFER	; address = $7e0200
	sta	REG_A1T7H
	stz	REG_A1B7	; bank address of ram
	ldx	#0800h
	stx	REG_DAS7L	; # of bytes to be transferred
	stz	REG_VMAIN	; increase V-Ram address after writing to
				; $2118
	ldx	#0800h
	stx	REG_VMADDL	; address of VRAM to copy graphics from

	lda	#%10000000	; turn on bit 4 (%1000=8) of G-DMA channel
	sta	REG_MDMAEN

	lda	#80h		; increase V-Ram address after writing to
	sta	REG_VMAIN	; $2119

	rts

;=======================================================================
;                  Bit scroll routine
;=======================================================================

bitsine:
	ldx	#0000h		; column #
	stx	colh
	stx	coll
	stx	scroll_char	; scroll char gfx offset
	lda	sine_pos
	clc
	adc	sine_pos_data	; speed and direction!
	sta	sine_pos
	sta	coll

	ldx	#0008h
	stx	counter		; reset the counter

	ldx	coll

	rep	#30h

	lda	SCROLL_SINE,x	; read sine data
	and	#00ffh		; get only 1 byte
	sta	sine_data	; store it
	lda	colh
	asl a
	asl a
	asl a
	asl a
	asl a
	asl a
	clc
	adc	sine_data
	sta	sine_data
	sep	#20h

	ldy	#0000h
	sty	bit_offs

beforesine:
	ldy	scroll_char	; current scrollchar offset
scrollersine:
	ldx	bit_offs	; current bit offset (0-7)
	lda	CHAR_SCROLL,y	; read char scroll
	and	BITON,x		; read certain bit
biton:	
	ldx	sine_data
	ora	VRAM_BUFFER,x	; ora it with the v-ram buffer
	sta	VRAM_BUFFER,x	; store it into v-ram buffer
overbit:
	iny			; get next char
	ldx	sine_data
	inx
	;inx
	stx	sine_data	; increase the sine data (to reach next line)

				; character counter
	dec	counter
	bne	scrollersine
	lda	#08h
	sta	counter		; reset the counter

	jsr	incbs
	ldy	scroll_char	; get current scroll char location

				; increase bit offset
	inc	bit_offs
	;inc	bit_offs
	lda	bit_offs
	cmp	counter
	bne	scrollersine

	stz	bit_offs	; yes; reset bit offset
	lda	#08h
	sta	counter		; reset char counter offset
	rep	#30h
	lda	scroll_char	
	clc
	adc	#0008h		; add 8 to char buffer offset
	sta	scroll_char
	sep	#20h
	inc	colh		; increase # of columns
	jsr	incbs
	lda	colh
	cmp	#10h		; 
	bne	beforesine

endscroll:
	jsr	movebsc

	rts

incbs:
	lda	coll
	clc
	adc	sine_inc_offs	; make this for angle
	sta	coll
	ldx	coll

	rep	#30h

	lda	SCROLL_SINE,x	; read sine data
	and	#00ffh		; get only 1 byte
	sta	sine_data	; store it
	lda	colh
	asl a
	asl a
	asl a
	asl a
	asl a
	asl a
	clc
	adc	sine_data
	sta	sine_data

	sep	#20h

	rts

movebsc:
	ldx	#0000h
	rep	#30h
	lda	#CHAR_SCROLL
	tcd
	sep	#20h

Rollscroll:
	asl	$80,x
	rol	$78,x
	rol	$70,x
	rol	$68,x
	rol	$60,x
	rol	$58,x
	rol	$50,x
	rol	$48,x
	rol	$40,x
	rol	$38,x
	rol	$30,x
	rol	$28,x
	rol	$20,x
	rol	$18,x
	rol	$10,x
	rol	$08,x
	rol	$00,x
	inx
	cpx	#0008h
	bne	Rollscroll

	rep	#30h

	lda	#0000h
	tcd

	sep	#20h

	lda	vert_offs
	inc a
	and	#07h
	sta	vert_offs
	beq	Getchar
	rts

Getchar:
	ldx	scrolltext_offset
	lda	BIT_SCROLLTEXT,x
	beq	resetbscrpos

	rep	#30h

	and	#00ffh
	sec
	sbc	#0020h
	asl a
	asl a
	asl a
	tax

	sep	#20h

	ldy	#0000h
copybscrdata:
	lda	SCROLL_CHAR,x
	sta	CHAR_SCROLL+80h,y
	inx
	iny
	cpy	#08h
	bne	copybscrdata

	ldx	scrolltext_offset
	inx
	stx	scrolltext_offset
	rts

resetbscrpos:
	ldx	#0000h
	stx	scrolltext_offset
	bra	Getchar


;==========================================================================
;       	     SETUP ROUTINES FOR PROGRAM
;==========================================================================

;=============================================================================
;                              HDMA setup routine
;=============================================================================

HDMA:	ldx	#0000h
	txy

	lda	#01h
HDMAgxpos:
	sta	HDMA_GX,x	; 1 scan line width
	inx
	stz	HDMA_GX,x	; clear it
	inx
	stz	HDMA_GX,x	; clear it
	inx
	iny
	cpy	#0073h		; # of lines to make
	bne	HDMAgxpos

	stz	HDMA_GX,x	; end hdma
	stz	HDMA_GX+01h,x
	stz	HDMA_GX+02h,x

	ldx	#0000h
	txy
HDMAgypos:
	sta	HDMA_GY,x	; 1 scan line width
	inx
	stz	HDMA_GY,x	; clear it
	inx
	stz	HDMA_GY,x	; clear it
	inx
	iny
	cpy	#0073h		; # of lines to make
	bne	HDMAgypos

	stz	HDMA_GY,x	; end hdma
	stz	HDMA_GY+1,x
	stz	HDMA_GY+2,x

	ldx	#0000h
	txy
HDMApal:
	sta	HDMA_PAL,x	; 1 scan line width
	inx
	sta	HDMA_PAL,x
	inx
	iny
	cpy	#0073h		; # of lines to make
	bne	HDMApal

	lda	#20h
	sta	HDMA_PAL,x	; end hdma
	stz	HDMA_PAL+1,x
	stz	HDMA_PAL+2,x

	lda	#12h
	sta	HDMA_PAL+44h

	ldx	#0000h
	txy
HDMAcol:
	lda	#01h
	sta	HDMA_COL,x	; 1 scan line width
	inx
	lda	#50h		; clear it
	sta	HDMA_COL,x
	inx
	lda	#0ffh		; clear it
	sta	HDMA_COL,x
	inx
	iny
	cpy	#0073h		; # of lines to make
	bne	HDMAcol

	lda	#20h
	sta	HDMA_COL,x	; end hdma
	stz	HDMA_COL+1,x
	stz	HDMA_COL+2,x
	stz	HDMA_COL+3,x

	lda	#80h
	sta	HDMA_COL
	sta	HDMA_GX
	sta	HDMA_GY
	sta	HDMA_PAL

	lda	#08h
	sta	HDMA_COL+3
	sta	HDMA_PAL+3

	lda	#01h
	sta	HDMA_GX+1
	sta	HDMA_GY+3

;=======================================================================
;                                    Vert Waver
;=======================================================================

vertwave:
	ldx	#0000h
	stx	vert_offs
	txy			; number of lines to create

	rep	#30h
	sep	#20h

vertwavemake:
	ldx	vert_offs	; read offset for sine data
	lda	f:SCROLL_SINE,x
	lsr a
	sec
	sbc	f:SCROLL_SINE,x
	;lsr a

	iny
	sta	HDMA_GY+03h,y
	iny
	iny
	dec	vert_offs
	dec	vert_offs
	cpy	#0153h
	bne	vertwavemake

	lda	#00h
	sta	HDMA_GY+03h,y

horizwave:
	ldx	#0000h
	stx	vert_offs
	txy			; number of lines to create

	rep	#30h
	sep	#20h

horizwavemake:
	ldx	vert_offs	; read offset for sine data
	lda	f:SCROLL_SINE,x
	iny
	sta	HDMA_GX+03h,y
	iny
	iny
	inc	vert_offs
	inc	vert_offs
	cpy	#0153h
	bne	horizwavemake

	lda	#00h
	sta	HDMA_GX+03h,y

colorwave:
	ldx	#0000h
	stx	vert_offs
	txy			; number of lines to create

	rep	#30h
	sep	#20h

colorwavemake:
	ldx	vert_offs	; read offset for sine data
	lda	HDMA_COLORS,x
	iny
	sta	HDMA_COL+06h,y
	iny
	inx
	lda	HDMA_COLORS,x
	;ora	#70h
	sta	HDMA_COL+06h,y
	iny
	inc	vert_offs
	inc	vert_offs
	cpy	#0153h
	bne	colorwavemake

	lda	#00h
	sta	HDMA_COL+06h,y

	lda	#10h
	sta	HDMA_COL+72h

	lda	#DMAP_XFER_MODE_2
	sta	REG_DMAP0
	sta	REG_DMAP1
	sta	REG_DMAP3

	lda	#<REG_BG3HOFS
	sta	REG_BBAD0
	stz	REG_A1T0L
	lda	#>HDMA_GX	; address = $1100
	sta	REG_A1T0H
	stz	REG_A1B0	; bank address of data in ram

	lda	#<REG_BG3VOFS
	sta	REG_BBAD1	;
	stz	REG_A1T1L
	lda	#>HDMA_GY	; address = $1300
	sta	REG_A1T1H
	stz	REG_A1B1	; bank address of data in ram

	stz	REG_DMAP2	; 0= 1 bytes per register (not a word!)
	lda	#<REG_CGADD
	sta	REG_BBAD2	; 21xx   this is 2121 
	stz	REG_A1T2L
	lda	#>HDMA_PAL	; address = $1500
	sta	REG_A1T2H
	stz	REG_A1B2	; bank address of data in ram

	lda	#<REG_CGDATA
	sta	REG_BBAD3	; 
	stz	REG_A1T3L
	lda	#>HDMA_COL	; address = $1600
	sta	REG_A1T3H
	stz	REG_A1B3	; bank address of data in ram

	jsr	WaitVb
	lda	#%00001111	; turn on the HDMA
	sta	REG_HDMAEN

	rts

;==========================================================================
;                        Vertical Blank Wait Routine
;==========================================================================
WaitVb:	
	lda	REG_RDNMI
	bpl     WaitVb	; is the number higher than #$7f? (#$80-$ff)
			; bpl tests bit #7 ($80) if this bit is set it means
			; the byte is negative (BMI, Branch on Minus)
			; BPL (Branch on Plus) if bit #7 is set in REG_RDNMI
			; it means that it is at the start of V-Blank
			; if not it will keep testing REG_RDNMI until bit #7
			; is on (which would make it a negative (BMI)
	rts

;============================================================================


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
BITON:	.byte	$80,$40,$20,$10,$08,$04,$02,$01
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
HDMA_COLORS:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.word	$0008,$000A,$000A,$000C,$000E,$0010,$0010,$0012
	.word	$0014,$0016,$0018,$0018,$001A,$001C,$001E,$001E

	.word	$109E,$18DE,$211E,$215E,$295E,$319E,$39DE,$421E
	.word	$425E,$4A9E,$52DE,$5B1E,$631E,$635E,$6B9E,$73DE

	.word	$73DE,$6B9E,$635E,$631E,$5B1E,$52DE,$4A9E,$425E
	.word	$421E,$39DE,$319E,$295E,$215E,$211E,$18DE,$109E

	.word	$001E,$001E,$001C,$001A,$0018,$0018,$0016,$0014
	.word	$0012,$0010,$0010,$000E,$000c,$000A,$000A,$0008
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SCROLL_SINE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
 .byte	024,025,025,026,026,027,028,028,029,029,030,030,031,032,032,033
 .byte	033,034,034,035,035,036,036,037,037,038,038,039,039,040,040,041
 .byte	041,041,042,042,043,043,043,044,044,044,045,045,045,045,046,046
 .byte	046,046,047,047,047,047,047,047,048,048,048,048,048,048,048,048
 .byte	048,048,048,048,048,048,048,048,048,047,047,047,047,047,047,046
 .byte	046,046,046,045,045,045,045,044,044,044,043,043,043,042,042,041
 .byte	041,041,040,040,039,039,038,038,037,037,036,036,035,035,034,034
 .byte	033,033,032,032,031,030,030,029,029,028,028,027,026,026,025,025
 .byte	024,023,023,022,022,021,020,020,019,019,018,018,017,016,016,015
 .byte	015,014,014,013,013,012,012,011,011,010,010,009,009,008,008,007
 .byte	007,007,006,006,005,005,005,004,004,004,003,003,003,003,002,002
 .byte	002,002,001,001,001,001,001,001,000,000,000,000,000,000,000,000
 .byte	000,000,000,000,000,000,000,000,000,001,001,001,001,001,001,002
 .byte	002,002,002,003,003,003,003,004,004,004,005,005,005,006,006,007
 .byte	007,007,008,008,009,009,010,010,011,011,012,012,013,013,014,014
 .byte	015,015,016,016,017,018,018,019,019,020,020,021,022,022,023,023
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SCROLL_CHAR:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
;-Cyber Font-Editor V1.4 Rel. by Frantic (c) 1991-1992 Sanity Productions-;
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$00,$00,$00,$00,$00,$00,$00,$00	;' '
	.byte	$18,$18,$18,$18,$00,$18,$18,$00	;'!'
	.byte	$66,$66,$66,$00,$00,$00,$00,$00	;'"'
	.byte	$6c,$fe,$6c,$6c,$6c,$fe,$6c,$00	;'#'
	.byte	$10,$7e,$d0,$7c,$16,$fc,$10,$00	;'$'
	.byte	$00,$00,$00,$00,$00,$00,$00,$00	;'%'
	.byte	$00,$00,$00,$00,$00,$00,$00,$00	;'&'
	.byte	$18,$18,$18,$00,$00,$00,$00,$00	;'''
	.byte	$18,$30,$60,$60,$60,$30,$18,$00	;'('
	.byte	$30,$18,$0c,$0c,$0c,$18,$30,$00	;')'
	.byte	$00,$54,$38,$7c,$38,$54,$00,$00	;'*'
	.byte	$00,$18,$18,$7e,$7e,$18,$18,$00	;'+'
	.byte	$00,$00,$00,$00,$00,$18,$18,$30	;','
	.byte	$00,$00,$00,$7e,$00,$00,$00,$00	;'-'
	.byte	$00,$00,$00,$00,$00,$18,$18,$00	;'.'
	.byte	$00,$03,$06,$0c,$18,$30,$60,$00	;'/'
	.byte	$7c,$fe,$ce,$d6,$e6,$fe,$7c,$00	;'0'
	.byte	$30,$70,$30,$30,$30,$fc,$fc,$00	;'1'
	.byte	$fc,$fe,$0e,$3c,$f0,$fe,$fe,$00	;'2'
	.byte	$fc,$fe,$06,$7c,$06,$fe,$fc,$00	;'3'
	.byte	$c0,$c0,$cc,$cc,$fe,$fe,$0c,$00	;'4'
	.byte	$fe,$fe,$c0,$fc,$0e,$fe,$fc,$00	;'5'
	.byte	$7e,$fe,$c0,$fc,$c6,$fe,$7c,$00	;'6'
	.byte	$fe,$fe,$0e,$1c,$38,$38,$38,$00	;'7'
	.byte	$7c,$fe,$c6,$7c,$c6,$fe,$7c,$00	;'8'
	.byte	$7c,$fe,$c6,$fe,$06,$fe,$7c,$00	;'9'
	.byte	$00,$30,$30,$00,$30,$30,$00,$00	;':'
	.byte	$00,$18,$18,$00,$18,$18,$30,$00	;';'
	.byte	$0e,$18,$30,$60,$30,$18,$0e,$00	;'<'
	.byte	$00,$00,$7e,$00,$7e,$00,$00,$00	;'='
	.byte	$70,$18,$0c,$06,$0c,$18,$70,$00	;'>'
	.byte	$3c,$66,$06,$0c,$18,$00,$18,$00	;'?'
	.byte	$00,$00,$00,$00,$00,$00,$00,$00	;'@'
	.byte	$0c,$3e,$36,$66,$7e,$c6,$c6,$00	;'A'
	.byte	$fc,$fe,$06,$fc,$c6,$fe,$fc,$00	;'B'
	.byte	$7c,$fe,$c6,$c0,$c6,$fe,$7c,$00	;'C'
	.byte	$fc,$fe,$06,$c6,$c6,$fe,$fc,$00	;'D'
	.byte	$7e,$fe,$c0,$fe,$c0,$fe,$7e,$00	;'E'
	.byte	$fe,$fe,$00,$fc,$c0,$c0,$c0,$00	;'F'
	.byte	$7c,$fe,$c0,$ce,$c6,$fe,$7c,$00	;'G'
	.byte	$c6,$c6,$c6,$f6,$c6,$c6,$c6,$00	;'H'
	.byte	$7e,$7e,$18,$18,$18,$7e,$7e,$00	;'I'
	.byte	$7e,$7e,$0c,$cc,$cc,$fc,$78,$00	;'J'
	.byte	$c6,$cc,$d8,$f0,$d8,$cc,$c6,$00	;'K'
	.byte	$c0,$c0,$c0,$c0,$c0,$fe,$7e,$00	;'L'
	.byte	$c6,$ee,$fe,$fe,$d6,$c6,$c6,$00	;'M'
	.byte	$cc,$ec,$fc,$fc,$dc,$cc,$cc,$00	;'N'
	.byte	$7c,$fe,$c6,$c6,$c6,$fe,$7c,$00	;'O'
	.byte	$fc,$fe,$06,$fc,$c0,$c0,$c0,$00	;'P'
	.byte	$7c,$fe,$c6,$c6,$c6,$fe,$7b,$00	;'Q'
	.byte	$f8,$fe,$06,$fc,$c6,$c6,$c6,$00	;'R'
	.byte	$7e,$fe,$c0,$7c,$06,$fe,$fc,$00	;'S'
	.byte	$f8,$fc,$0c,$0c,$0c,$0c,$0c,$00	;'T'
	.byte	$c6,$c6,$c6,$c6,$c6,$fe,$7c,$00	;'U'
	.byte	$c6,$c6,$c6,$c6,$ee,$7c,$38,$00	;'V'
	.byte	$c6,$c6,$d6,$fe,$fe,$ee,$c6,$00	;'W'
	.byte	$c6,$ee,$7c,$38,$7c,$ee,$c6,$00	;'X'
	.byte	$66,$66,$66,$3c,$18,$18,$18,$00	;'Y'
	.byte	$fe,$fe,$1c,$38,$70,$fe,$fe,$00	;'Z'
	.byte	$00,$00,$00,$00,$00,$00,$00,$00	;'['
	.byte	$00,$00,$00,$00,$00,$00,$00,$00	;'\'
	.byte	$00,$00,$00,$00,$00,$00,$00,$00	;']'
	.byte	$00,$00,$00,$00,$00,$00,$00,$00	;'^'
	.byte	$00,$00,$00,$00,$00,$00,$00,$00	;'_'
	.byte	$00,$00,$00,$00,$00,$00,$00,$00	;'`'
	.byte	$0c,$3e,$36,$66,$7e,$c6,$c6,$00	;'a'
	.byte	$fc,$fe,$06,$fc,$c6,$fe,$fc,$00	;'b'
	.byte	$7c,$fe,$c6,$c0,$c6,$fe,$7c,$00	;'c'
	.byte	$fc,$fe,$06,$c6,$c6,$fe,$fc,$00	;'d'
	.byte	$7e,$fe,$c0,$fe,$c0,$fe,$7e,$00	;'e'
	.byte	$fe,$fe,$00,$fc,$c0,$c0,$c0,$00	;'f'
	.byte	$7c,$fe,$c0,$ce,$c6,$fe,$7c,$00	;'g'
	.byte	$c6,$c6,$c6,$f6,$c6,$c6,$c6,$00	;'h'
	.byte	$7e,$7e,$18,$18,$18,$7e,$7e,$00	;'i'
	.byte	$7e,$7e,$0c,$cc,$cc,$fc,$78,$00	;'j'
	.byte	$c6,$cc,$d8,$f0,$d8,$cc,$c6,$00	;'k'
	.byte	$c0,$c0,$c0,$c0,$c0,$fe,$7e,$00	;'l'
	.byte	$c6,$ee,$fe,$fe,$d6,$c6,$c6,$00	;'m'
	.byte	$cc,$ec,$fc,$fc,$dc,$cc,$cc,$00	;'n'
	.byte	$7c,$fe,$c6,$c6,$c6,$fe,$7c,$00	;'o'
	.byte	$fc,$fe,$06,$fc,$c0,$c0,$c0,$00	;'p'
	.byte	$7c,$fe,$c6,$c6,$c6,$fe,$7b,$00	;'q'
	.byte	$f8,$fe,$06,$fc,$c6,$c6,$c6,$00	;'r'
	.byte	$7e,$fe,$c0,$7c,$06,$fe,$fc,$00	;'s'
	.byte	$f8,$fc,$0c,$0c,$0c,$0c,$0c,$00	;'t'
	.byte	$c6,$c6,$c6,$c6,$c6,$fe,$7c,$00	;'u'
	.byte	$c6,$c6,$c6,$c6,$ee,$7c,$38,$00	;'v'
	.byte	$c6,$c6,$d6,$fe,$fe,$ee,$c6,$00	;'w'
	.byte	$c6,$ee,$7c,$38,$7c,$ee,$c6,$00	;'x'
	.byte	$66,$66,$66,$3c,$18,$18,$18,$00	;'y'
	.byte	$fe,$fe,$1c,$38,$70,$fe,$fe,$00	;'z'
	.byte	$00,$00,$00,$00,$00,$00,$00,$00	;'{'
	.byte	$00,$00,$00,$00,$00,$00,$00,$00	;'|'
	.byte	$00,$00,$00,$00,$00,$00,$00,$00	;'}'
	.byte	$00,$00,$00,$00,$00,$00,$00,$00	;'~'
	.byte	$00,$00,$00,$00,$00,$00,$00,$00	;''
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


	.byte	" Screen Text starts here    --->"
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
TEXT_01:	.asciiz	"ANTHROX PROUDLY PRESENTS"
TEXT_02:	.asciiz	"ANOTHER GAME"
TEXT_03:	.asciiz "SUPPLIED BY KIRK"
TEXT_04:	.asciiz "CALL U.S.S. ENTERPRISE"
TEXT_05:	.asciiz "FOR THE LATEST ATX RELEASES"
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


	.byte	"scroll text begins here ------->"
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
BIT_SCROLLTEXT:
	.byte	"yeah boy!! another kickin' intro"
	.byte	" by -pan-!  nothing can stop me "
	.byte	"now! the power of the bit scroll"
	.byte	" will take me far!     see you a"
	.byte	"gain!                          ",0
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	"<- scroll text ends here!       "


;/////////////////////////////////////////////////////////////////////////;
.segment "GRAPHICS"
;/////////////////////////////////////////////////////////////////////////;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
TEXT_00:	.asciiz	"I N T R O   B Y   P A N"
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
