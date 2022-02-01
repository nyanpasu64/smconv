; graphic decompression functions

.ifndef __SNES_DECOMPRESS__
__SNES_DECOMPRESS__ = 1

;*************************************************************************;
; x = source address
; y = vram address
; a = bank number
; (does not preserve memptr)
;*************************************************************************;
.global DecompressDataVram


;*************************************************************************;
; Copy data from memory/rom to cgram
;
; A = source bank
; B = palette index
; Y = source address
; X = number of colours
; (does not preserve memptr)
;*************************************************************************;
.global CopyPalette


;-------------------------------------------------------------------------;
.macro DoCopyPalette source, index, colors
;-------------------------------------------------------------------------;
	lda	#index
	xba
	lda	#^source
	ldy	#.LOWORD(source)
	ldx	#colors
	jsl	CopyPalette
;-------------------------------------------------------------------------;
.endmacro
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
.macro DoDecompressDataVram source, dest
;-------------------------------------------------------------------------;
	lda	#^source
	ldx	#.LOWORD(source)
	ldy	#dest
	jsl	DecompressDataVram
;-------------------------------------------------------------------------;
.endmacro
;-------------------------------------------------------------------------;


.endif
