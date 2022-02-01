;-------------------------------------------------------------------------;
.include "graphics.inc"
.include "snes.inc"
.include "snes_decompress.inc"
.include "snes_zvars.inc"
;-------------------------------------------------------------------------;
.importzp frame_ready, joy1_down
;-------------------------------------------------------------------------;
.import ASCIIMAP, oam_hitable, oam_table
;-------------------------------------------------------------------------;
.export DoXkaliberShit
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
BG3_SPEED = 2
BG3_VOFS = 0fh
CITY_TILES = 32*9		; number of tiles using city palette (w*h)
CITY_PALETTE_START = 32*9	; first tile to use city palette (w*h)
REFLECTION_HEIGHT = 2
SPRITE_PROP = OAM_PRI2
WATER_START = 102		; water effect starts at line
SCROLLTEXT_YPOS = 136
SUNSET_START = WATER_START-34	; sunset hdma start line
;-------------------------------------------------------------------------;

;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
RAM_WATER = 0500h
RAM_CGADD   = 0f00h
RAM_CGDATA  = RAM_CGADD+(LIST_CGADD_END-LIST_CGADD)
RAM_BG2VOFS = RAM_CGDATA+(LIST_CGDATA_END-LIST_CGDATA)
PTR_BG3HOFS = RAM_BG2VOFS+(LIST_BG2VOFS_END-LIST_BG2VOFS)
RAM_BG3HOFS = PTR_BG3HOFS+(LIST_BG3HOFS_END-LIST_BG3HOFS)
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
BG1GFX = 00000h
BG1MAP = 0e800h
BG2GFX = 04000h
BG2MAP = 0f000h
BG3GFX = 00000h
BG3MAP = 0f800h
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
.zeropage
;/////////////////////////////////////////////////////////////////////////;


;-------------------------------------------------------------------------;
bg3_stuff:
	.res 2
bg3hofs:
	.res 2
bg3_speed:
	.res 1
bg3_src_offset:
	.res 1
copy_src:
	.res 3
copy_dest:
	.res 3
reflection_height:
	.res 1
src_offset:
	.res 1
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
.code
;/////////////////////////////////////////////////////////////////////////;


;-------------------------------------------------------------------------;
	.a8
	.i16
;-------------------------------------------------------------------------;


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
DoXkaliberShit:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	rep	#10h
	sep	#20h

	stz	bg3_src_offset
	stz	copy_dest+2
	stz	copy_src+2

	ldx	#0000h
	stx	bg3hofs

	lda	#04h
	sta	reflection_height

	; in order for the clouds and city tilemaps to use the correct
	; palette the associated .grit files must contain the correct
	; map offset (-ma)
	DoCopyPalette gfx_cloudsPal, 8, 4	; -ma 3072 (2bpp palette 2)
	DoCopyPalette gfx_reflectionPal, 80, 16
	DoCopyPalette gfx_cityPal, 96, 16	; -ma 1024 (4bpp palette 1)

	DoDecompressDataVram gfx_cloudsTiles, BG3GFX
	DoDecompressDataVram gfx_cloudsMap, BG3MAP

	DoDecompressDataVram gfx_cityTiles, BG2GFX
	DoDecompressDataVram gfx_cityMap, BG2MAP

	lda	#VMAIN_INCH
	sta	REG_VMAIN

	ldx	#BG2MAP/2+CITY_PALETTE_START	; starting at this address
	stx	REG_VMADDL			; we'll switch the tiles to
						; use palette 6
	ldx	#CITY_TILES			; number of tiles which will
	lda	REG_VMDATALREAD			; use palette 6
:	lda	REG_VMDATALREAD
	lda	#PALETTE6
	sta	REG_VMDATAH
	dex
	bne	:-

	lda	#BGMODE_1
	sta	REG_BGMODE

	lda	#BG1MAP>>9
	sta	REG_BG1SC

	lda	#BG2MAP>>9
	sta	REG_BG2SC

	lda	#BG3MAP>>9
	sta	REG_BG3SC

	lda	#(BG2GFX>>9)+(BG1GFX>>13)
	sta	REG_BG12NBA

	lda	#BG3GFX>>9
	sta	REG_BG34NBA

	lda	#BG3_VOFS
	sta	REG_BG3VOFS
	stz	REG_BG3VOFS

	lda	#TM_BG2
	sta	REG_TM

	lda	#TM_BG3
	sta	REG_TS

	lda	#%00110011
	sta	REG_CGADSUB

	lda	#02h
	sta	REG_CGSWSEL

	lda	#0e0h
	sta	REG_COLDATA

	rep	#30h

	lda	#LIST_BG3HOFS_END-LIST_CGADD
	ldx	#LIST_CGADD
	ldy	#RAM_CGADD
	sty	REG_A1T0L
	mvn	80h,^LIST_CGADD

	sep	#20h

	stz	REG_DMAP0
	lda	#<REG_CGADD
	sta	REG_BBAD0
	ldx	#LIST_CGADD
	stx	REG_A1T0L
	stz	REG_A1B0

	lda	#DMAP_XFER_MODE_2
	sta	REG_DMAP1
	lda	#<REG_CGDATA
	sta	REG_BBAD1
	ldx	#RAM_CGDATA
	stx	REG_A1T1L
	stz	REG_A1B1

	lda	#DMAP_POINTERS|DMAP_XFER_MODE_2
	sta	REG_DMAP4
	lda	#<REG_BG3HOFS
	sta	REG_BBAD4
	ldx	#PTR_BG3HOFS
	stx	REG_A1T4
	stz	REG_A1B4
	stz	REG_DASB4

	lda	#DMAP_XFER_MODE_2
	sta	REG_DMAP5
	lda	#<REG_BG2VOFS
	sta	REG_BBAD5
	ldx	#RAM_BG2VOFS
	stx	REG_A1T5
	stz	REG_A1B5
	stz	REG_DASB5

	lda	#%00110011
	sta	REG_HDMAEN

	lda	#NMI_ON|NMI_JOYPAD
	sta	REG_NMITIMEN

	cli

	lda	#0fh
	sta	REG_INIDISP
;-------------------------------------------------------------------------;
Loop:	lda	REG_RDNMI
	bpl	Loop
;-------------------------------------------------------------------------;
	jsr	Water
	jsr	Clouds

	inc	bg3_speed
	lda	bg3_speed
	cmp	#BG3_SPEED
	bne	Loop
;-------------------------------------------------------------------------;
	stz	bg3_speed
	inc	bg3hofs
	inc	bg3_src_offset

	bra	Loop
;-------------------------------------------------------------------------;


;=========================================================================;
Water:
;=========================================================================;
	rep	#20h

	lda	#WATER_REFLECTION_Y
	sta	copy_src
	lda	#RAM_WATER
	sta	copy_dest

	sep	#10h

	ldy	#10h
;-------------------------------------------------------------------------;
:	lda	(copy_src)
	clc	
	adc	reflection_height
	sta	(copy_dest)
	inc	copy_src
	inc	copy_src
	inc	copy_dest
	inc	copy_dest
	dey	
	bne	:-
;-------------------------------------------------------------------------;
	lda	#RAM_BG2VOFS+07h
	sta	copy_dest

	sep	#20h

	inc	src_offset
	lda	src_offset
	and	#3ch
	lsr	a
	lsr	a
	sta	copy_src
	ldy	#60h
;-------------------------------------------------------------------------;
:	lda	copy_src
	inc	a
	and	#0fh
	sta	copy_src
	asl	a
	tax	

	rep	#20h

	lda	RAM_WATER,x
	clc
	adc	#09h
	sta	(copy_dest)
	inc	copy_dest
	inc	copy_dest

	sep	#20h

	dey	
	bne	:-
;-------------------------------------------------------------------------;
	rep	#10h

	rts


;=========================================================================;
Clouds:
;=========================================================================;
	rep	#20h

	inc	bg3_stuff
	lda	bg3_stuff
	lsr	a
	lsr	a

	sep	#20h

	clc	
	adc	bg3_src_offset
	and	#3fh
	sta	copy_src
	ldy	#RAM_BG3HOFS
	sty	copy_dest

	sep	#10h

	ldy	#40h
;-------------------------------------------------------------------------;
:	inc	copy_src
	lda	copy_src
	asl	a
	and	#7fh
	tax	
	lda	CLOUD_SWIRL,x
	clc	
	adc	bg3hofs
	sta	(copy_dest)

	rep	#20h

	inc	copy_dest
	inc	copy_dest

	sep	#20h

	dey	
	bne	:-
;-------------------------------------------------------------------------;
	rep	#10h

	rts


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
WATER_REFLECTION_Y:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$03,$00,$03,$00,$02,$00,$02,$00
	.byte	$02,$00,$01,$00,$01,$00,$01,$00
	.byte	$01,$00,$01,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
CLOUD_SWIRL:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$00,$00,$00,$00,$01,$00,$01,$00
	.byte	$02,$00,$02,$00,$02,$00,$03,$00
	.byte	$03,$00,$03,$00,$03,$00,$04,$00
	.byte	$04,$00,$04,$00,$04,$00,$04,$00
	.byte	$04,$00,$04,$00,$04,$00,$04,$00
	.byte	$04,$00,$04,$00,$03,$00,$03,$00
	.byte	$03,$00,$03,$00,$02,$00,$02,$00
	.byte	$02,$00,$01,$00,$01,$00,$00,$00
	.byte	$00,$00,$00,$00,$ff,$ff,$ff,$ff
	.byte	$fe,$ff,$fe,$ff,$fe,$ff,$fd,$ff
	.byte	$fd,$ff,$fd,$ff,$fd,$ff,$fc,$ff
	.byte	$fc,$ff,$fc,$ff,$fc,$ff,$fc,$ff
	.byte	$fc,$ff,$fc,$ff,$fc,$ff,$fc,$ff
	.byte	$fc,$ff,$fc,$ff,$fd,$ff,$fd,$ff
	.byte	$fd,$ff,$fd,$ff,$fe,$ff,$fe,$ff
	.byte	$fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_CGADD:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte SUNSET_START,$00
	.byte $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
	.byte $02,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
	.byte $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
	.byte $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
	.byte $01,$00,$02,$00,$02,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
	.byte $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
	.byte $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
	.byte $01,$00,$09,$00

	.byte $01,$00,$01,$00,$01,$00,$01,$00,$02,$00,$01,$00,$01,$00,$01,$00
	.byte $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$02,$00
	.byte $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
	.byte $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
	.byte $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
	.byte $01,$00,$01,$00,$01,$00
	.byte 0
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_CGADD_END:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_CGDATA:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte SUNSET_START
	.word $0000
	.byte $01
	.word $0400
	.byte $01
	.word $0800
	.byte $01
	.word $0801
	.byte $01
	.word $0c01
	.byte $01
	.word $1001
	.byte $01
	.word $1002
	.byte $01
	.word $1402
	.byte $02
	.word $1802
	.byte $01
	.word $1c03
	.byte $01
	.word $2004
	.byte $01
	.word $2024
	.byte $01
	.word $2425
	.byte $01
	.word $2445
	.byte $01
	.word $2846
	.byte $01
	.word $2866
	.byte $01
	.word $2c67
	.byte $01
	.word $2c87
	.byte $01
	.word $3088
	.byte $01
	.word $30a8
	.byte $01
	.word $34a9
	.byte $01
	.word $34c9
	.byte $01
	.word $38ca
	.byte $01
	.word $38ea
	.byte $01
	.word $3ceb
	.byte $01
	.word $3d0b
	.byte $01
	.word $410c
	.byte $01
	.word $412c
	.byte $01
	.word $452d
	.byte $01
	.word $454d
	.byte $01
	.word $454f
	.byte $01
	.word $456f
	.byte $01
	.word $4570
	.byte $02
	.word $4571
	.byte $02	
	.word $4592
	.byte $01
	.word $45b2
	.byte $01
	.word $45b3
	.byte $01
	.word $45d3
	.byte $01
	.word $45d4
	.byte $01
	.word $45d5
	.byte $01
	.word $45f5
	.byte $01
	.word $45f6
	.byte $01
	.word $4616
	.byte $01
	.word $4617
	.byte $01
	.word $4618
	.byte $01
	.word $4638
	.byte $01
	.word $4639
	.byte $01
	.word $463a
	.byte $01
	.word $465a
	.byte $01
	.word $465b
	.byte $01
	.word $467b
	.byte $01
	.word $467c
	.byte $01
	.word $469c
	.byte $01
	.word $46bc
	.byte $01
	.word $46dc
	.byte $01
	.word $46fc
	.byte $01
	.word $471c
	.byte $09
	.word $473c

	.byte $01
	.word $2956
	.byte $01
	.word $2936
	.byte $01
	.word $2536
	.byte $01
	.word $2535
	.byte $02
	.word $2515
	.byte $01
	.word $2115
	.byte $01
	.word $2114
	.byte $01
	.word $20f4
	.byte $01
	.word $20f3
	.byte $01
	.word $1cf3
	.byte $01
	.word $1cf2
	.byte $01
	.word $1cd2
	.byte $01
	.word $18d2
	.byte $01
	.word $18d1
	.byte $01
	.word $18b1
	.byte $02
	.word $14b1

	.byte $01
	.word $14b0
	.byte $01
	.word $1490
	.byte $01
	.word $148f
	.byte $01
	.word $108f
	.byte $01
	.word $108e
	.byte $01
	.word $106e
	.byte $01
	.word $106d
	.byte $01
	.word $0c6d
	.byte $01
	.word $0c6c
	.byte $01
	.word $0c4c
	.byte $01
	.word $084c
	.byte $01
	.word $084b
	.byte $01
	.word $082b
	.byte $01
	.word $042b
	.byte $01
	.word $042a
	.byte $01
	.word $0429
	.byte $01
	.word $0409
	.byte $01
	.word $0408
	.byte $01
	.word $0008
	.byte $01
	.word $0009
	.byte $01
	.word $0007
	.byte $01
	.word $0006
	.byte $01
	.word $0005
	.byte $01
	.word $0004
	.byte $01
	.word $0003
	.byte $01
	.word $0002
	.byte $01
	.word $0000
	.byte 0
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_CGDATA_END:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_BG2VOFS:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$20,$10,$00,WATER_START,$09,$00,$e0,$09
	.byte	$00,$09,$00,$0c,$00,$0c,$00,$0b
	.byte	$00,$0b,$00,$0b,$00,$0a,$00,$0a
	.byte	$00,$0a,$00,$0a,$00,$0a,$00,$09
	.byte	$00,$09,$00,$09,$00,$09,$00,$09
	.byte	$00,$09,$00,$0c,$00,$0c,$00,$0b
	.byte	$00,$0b,$00,$0b,$00,$0a,$00,$0a
	.byte	$00,$0a,$00,$0a,$00,$0a,$00,$09
	.byte	$00,$09,$00,$09,$00,$09,$00,$09
	.byte	$00,$09,$00,$0c,$00,$0c,$00,$0b
	.byte	$00,$0b,$00,$0b,$00,$0a,$00,$0a
	.byte	$00,$0a,$00,$0a,$00,$0a,$00,$09
	.byte	$00,$09,$00,$09,$00,$09,$00,$09
	.byte	$00,$09,$00,$0c,$00,$0c,$00,$0b
	.byte	$00,$0b,$00,$0b,$00,$0a,$00,$0a
	.byte	$00,$0a,$00,$0a,$00,$0a,$00,$09
	.byte	$00,$09,$00,$09,$00,$09,$00,$09
	.byte	$00,$09,$00,$0c,$00,$0c,$00,$0b
	.byte	$00,$0b,$00,$0b,$00,$0a,$00,$0a
	.byte	$00,$0a,$00,$0a,$00,$0a,$00,$09
	.byte	$00,$09,$00,$09,$00,$09,$00,$09
	.byte	$00,$09,$00,$0c,$00,$0c,$00,$0b
	.byte	$00,$0b,$00,$0b,$00,$0a,$00,$0a
	.byte	$00,$0a,$00,$0a,$00,$0a,$00,$09
	.byte	$00,$09,$00,$09,$00,$09,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_BG2VOFS_END:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_BG3HOFS:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	160
	.word	RAM_BG3HOFS
	.byte	160
	.word	RAM_BG3HOFS+40h
	.byte	160
	.word	RAM_BG3HOFS
	.byte	160
	.word	RAM_BG3HOFS+40h
	.byte	160
	.word	RAM_BG3HOFS
	.byte	160
	.word	RAM_BG3HOFS+40h
	.byte	160
	.word	RAM_BG3HOFS
	.byte	0
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_BG3HOFS_END:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
