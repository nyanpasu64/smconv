; ABNOFX and SUPERNOFX

.export spcChangeWaveTable, spcSetPosition, spcSetWaveTableBank

.export spcAllocateSoundRegion, spcEffect, spcLoadEffect
.export spcPlaySound, spcPlaySoundV, spcPlaySoundEx
.export spcProcessStream, spcSetSoundTable, spcTest


SPC_BOOT = 0380h	; spc entry/load address

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
.zeropage
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
digi_active:
	.res 1
wavetable_bank:
	.res 1

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
.code
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;

.i16
.a8

;**********************************************************************
;* x length
;* y sample
;* transfer brr samples
;**********************************************************************
spcChangeWaveTable:
;----------------------------------------------------------------------
	sty	z:spc_ptr
	lda	wavetable_bank
	sta	z:spc_ptr+2

	lda	z:spc_v		; sync with SPC
	pha
:	cmp	REG_APUIO1	;
	bne	:-		;--------------------------------------
	lda	#CMD_LOADWT	; write message
	sta	REG_APUIO0	;--------------------------------------
	pla			; dispatch message and wait
	eor	#80h		;
	ora	#01h		;
	sta	z:spc_v		;
	sta	REG_APUIO1	;
:	cmp	REG_APUIO1	;
	bne	:-		;--------------------------------------
	ldy	#0		;
	jsr	do_transfer	; transfer data
	rts			;--------------------------------------

;**********************************************************************
; x = pattern to jump to
;**********************************************************************
spcSetPosition:
	txa
	sta	z:spc1+1
	lda	#CMD_POS
	jmp	QueueMessage

;**********************************************************************
; a = bank
;**********************************************************************
spcSetWaveTableBank:
	sta	wavetable_bank

spcLoadEffect:
spcEffect:
spcSetSoundTable:
spcAllocateSoundRegion:
spcPlaySound:
spcPlaySoundV:
spcPlaySoundEx:
spcProcessStream:
spcTest:

	rts
