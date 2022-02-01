;-------------------------------------------------------------------------;
.include "oam.inc"
.include "options.inc"
.include "reset.inc"
.include "shadow_ram.inc"
.include "snes.inc"
.include "snes_init.inc"
.include "snes_zvars.inc"
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
.code
;/////////////////////////////////////////////////////////////////////////;


	.a8
	.i16


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
ResetReg:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	sei
	lda	#80h
	sta	REG_INIDISP
	stz	REG_HDMAEN
	stz	REG_NMITIMEN

	stz	options
	stz	reg_inidisp

	jsr	InitReg

	lda	#00h
	ldx	#0500h
	ldy	#0affh
	jsr	ClearRAM
	jsr	ClearWorkRAM7E
	jsr	ClearWorkRAM7F

	lda	#0ffh
	sta	REG_BG1VOFS
	stz	REG_BG1VOFS
	sta	REG_BG2VOFS
	stz	REG_BG2VOFS
	sta	REG_BG3VOFS
	stz	REG_BG3VOFS

	lda	#02h
	sta	REG_CGSWSEL

	lda	#0e0h
	sta	REG_COLDATA

	ldx	#16
:	stz	m0,x
	dex
	bpl	:-

	ldx	#oam_table
	stx	REG_WMADDL
	stz	REG_WMADDH

	ldx	#0080h
	lda	#0e0h
:	sta	REG_WMDATA
	sta	REG_WMDATA
	stz	REG_WMDATA
	stz	REG_WMDATA
	dex
	bpl	:-

	ldx	#oam_hitable
	stx	REG_WMADDL
	ldx	#0010h
:	stz	REG_WMDATA
	stz	REG_WMDATA
	dex
	bpl	:-

	rts
