;-------------------------------------------------------------------------;
.include "snes.inc"
.include "snes_decompress.inc"
.include "snes_zvars.inc"
.include "snes_joypad.inc"
.include "graphics.inc"
;-------------------------------------------------------------------------;
.export DoTranslucent
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
BG1GFX = 00800h
BG1MAP = 0f000h
BG2GFX = 00000h
BG2MAP = 0f800h
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
reg_bg2hofs = m4
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
	.code
;/////////////////////////////////////////////////////////////////////////;


;-------------------------------------------------------------------------;
	.a8
	.i16
;-------------------------------------------------------------------------;


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
DoTranslucent:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;

	; gfx_ghosthouse.grit should contain -ma64 since the gfx
	; are stored at 0800h

	; gfx_clouds.grit should contain -ma1024 since it used the 2nd
	; palette

	DoDecompressDataVram gfx_snowMap, BG1MAP
	DoDecompressDataVram gfx_snowTiles, BG1GFX
	DoCopyPalette gfx_snowPal, 0, 12
	DoCopyPalette gfx_cloudsPal, 16, 4
	DoDecompressDataVram gfx_cloudsMap, BG2MAP
	DoDecompressDataVram gfx_cloudsTiles, BG2GFX

	lda	#BG1MAP>>9
	sta	REG_BG1SC
	lda	#BG2MAP>>9
	sta	REG_BG2SC
	lda	#(BG2GFX>>9)+(BG1GFX>>13)
	sta	REG_BG12NBA

	stz	REG_BG1HOFS
	stz	REG_BG1HOFS
	stz	REG_BG2HOFS
	stz	REG_BG2HOFS
	lda	#0ffh
	sta	REG_BG1VOFS
	stz	REG_BG1VOFS
	sta	REG_BG2VOFS
	stz	REG_BG2VOFS

	lda	#BGMODE_PRIO|BGMODE_1
	sta	REG_BGMODE
	lda	#TM_BG1
	sta	REG_TM
	lda	#TM_BG2
	sta	REG_TS

	lda	#02h
	sta	REG_CGSWSEL
	lda	#%00100001
	sta	REG_CGADSUB
	lda	#0e0h
	sta	REG_COLDATA
	lda	#0fh
	sta	REG_INIDISP
;-------------------------------------------------------------------------;
:
;-------------------------------------------------------------------------;
	lda	REG_RDNMI
	bpl	:-

	rep	#20h

	inc	reg_bg2hofs
	inc	reg_bg2hofs
	lda	reg_bg2hofs
	lsr
	lsr

	sep	#20h

	sta	REG_BG2HOFS
	stz	REG_BG2HOFS
;-------------------------------------------------------------------------;
	bra     :-
