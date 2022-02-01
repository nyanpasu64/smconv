;-------------------------------------------------------------------------;
.include "graphics.inc"
.include "snes.inc"
.include "snes_decompress.inc"
.include "snes_joypad.inc"
.include "snes_zvars.inc"
;-------------------------------------------------------------------------;
.export DoClouds
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
BG1GFX = 00000h
BG1MAP = 0f000h
BG2GFX = 08000h
BG2MAP = 0f800h
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
bg2hofs = m3
bg2vofs = m4
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
.code
;/////////////////////////////////////////////////////////////////////////;


	.a8
	.i16


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
DoClouds:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;


	rep	#10h
	sep	#20h

	lda	#8fh
	sta	REG_INIDISP

	lda	#BGMODE_1
	sta	REG_BGMODE

	DoDecompressDataVram gfx_cloudsTiles, BG2GFX
	DoDecompressDataVram gfx_cloudsMap, BG2MAP
	DoCopyPalette gfx_cloudsPal, 48, 16

	lda	#BG2MAP>>9
	sta	REG_BG2SC

	lda	#(BG2GFX>>9)+(BG1GFX>>13)
	sta	REG_BG12NBA

	lda	#%10100001
	sta	REG_CGADSUB

	lda	#02h
	sta	REG_CGSWSEL

	lda	#0e0h
	sta	REG_COLDATA

	lda	#TM_BG2
	sta	REG_TS

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
	ldx	#LIST_CGDATA
	stx	REG_A1T1L
	stz	REG_A1B1

	lda	#%11
	sta	REG_HDMAEN

	lda	#NMI_ON|NMI_JOYPAD
	sta	REG_NMITIMEN

	cli

	lda	#0fh
	sta	REG_INIDISP
;=========================================================================;
Loop:
;=========================================================================;
	wai
	dec	bg2hofs
	lda	bg2hofs
	sta	REG_BG2HOFS
	stz	REG_BG2HOFS
	sta	REG_BG2VOFS
	stz	REG_BG2VOFS
	bra	Loop


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_CGADD:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte $47,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
	.byte $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
	.byte $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
	.byte $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$0a,$00
	.byte $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
	.byte $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
	.byte $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
	.byte $01,$00,$01,$00,$01,$00,$28,$00,$01,$00,$01,$00,$01,$00,$01,$00
	.byte $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
	.byte $01,$00,$04,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
	.byte $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
	.byte 0
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_CGADD_END:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_CGDATA:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$47
	.word $0000
	.byte	$01
	.word $0421
	.byte	$01
	.word $0842
	.byte	$01
	.word $0c63
	.byte	$01
	.word $1084
	.byte	$01
	.word $14a5
	.byte	$01
	.word $18c6
	.byte	$01
	.word $1ce7
	.byte	$01
	.word $2108
	.byte	$01
	.word $2529
	.byte	$01
	.word $294a
	.byte	$01
	.word $2d6b
	.byte	$01
	.word $318c
	.byte	$01
	.word $35ad
	.byte	$01
	.word $39ce
	.byte	$01
	.word $3def
	.byte	$01
	.word $4210
	.byte	$01
	.word $4631
	.byte	$01
	.word $4a52
	.byte	$01
	.word $4e73
	.byte	$01
	.word $5294
	.byte	$01
	.word $56b5
	.byte	$01
	.word $5ad6
	.byte	$01
	.word $5ef7
	.byte	$01
	.word $6318
	.byte	$01
	.word $6739
	.byte	$01
	.word $6b5a
	.byte	$01
	.word $6f7b
	.byte	$01
	.word $739c
	.byte	$01
	.word $77bd
	.byte	$0a
	.word $7bde
	.byte	$01
	.word $77bd
	.byte	$01
	.word $739c
	.byte	$01
	.word $6f7b
	.byte	$01
	.word $6b5a
	.byte	$01
	.word $6739
	.byte	$01
	.word $6318
	.byte	$01
	.word $5ef7
	.byte	$01
	.word $5ad6
	.byte	$01
	.word $56b5
	.byte	$01
	.word $5294
	.byte	$01
	.word $4e73
	.byte	$01
	.word $4a52
	.byte	$01
	.word $4631
	.byte	$01
	.word $4210
	.byte	$01
	.word $3def
	.byte	$01
	.word $39ce
	.byte	$01
	.word $35ad
	.byte	$01
	.word $318c
	.byte	$01
	.word $2d6b
	.byte	$01
	.word $294a
	.byte	$01
	.word $2529
	.byte	$01
	.word $2108
	.byte	$01
	.word $1ce7
	.byte	$01
	.word $18c6
	.byte	$01
	.word $14a5
	.byte	$01
	.word $1084
	.byte	$01
	.word $0c63
	.byte	$01
	.word $0842
	.byte	$01
	.word $0421
	.byte	$28
	.word $0000
	.byte	$01
	.word $0842
	.byte	$01
	.word $0c63
	.byte	$01
	.word $1084
	.byte	$01
	.word $14a5
	.byte	$01
	.word $18c6
	.byte	$01
	.word $1ce7
	.byte	$01
	.word $2108
	.byte	$01
	.word $2529
	.byte	$01
	.word $294a
	.byte	$01
	.word $2d6b
	.byte	$01
	.word $318c
	.byte	$01
	.word $35ad
	.byte	$04
	.word $39ce
	.byte	$01
	.word $35ad
	.byte	$01
	.word $318c
	.byte	$01
	.word $2d6b
	.byte	$01
	.word $294a
	.byte	$01
	.word $2529
	.byte	$01
	.word $2108
	.byte	$01
	.word $1ce7
	.byte	$01
	.word $18c6
	.byte	$01
	.word $14a5
	.byte	$01
	.word $1084
	.byte	$01
	.word $0c63
	.byte	$01
	.word $0842
	.byte	$01
	.word $0421
	.byte	$01
	.word $0000
	.byte 0
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_CGDATA_END:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
