.ifndef __MACROS_INC__
__MACROS_INC__ = 1


;=========================================================================;
.macro	ClearDMA			;No Arguments reqired
;=========================================================================;
	lda	#$ff
	sta	REG_WRIO
	ldx	#$000b
Clear1:	stz	REG_WRMPYA,x
	dex
	bpl	Clear1
	ldx	#$007f
Clear2:	stz	REG_DMAP0,x
	dex
	bpl	Clear2
;-------------------------------------------------------------------------;
.endmacro
;-------------------------------------------------------------------------;


;=========================================================================;
.macro	InitHDMA source,source_bank,list_length,reg_address,table_length,bank,ram
;=========================================================================;
	rep	#30h

	lda	#list_length
	ldx	#source
	ldy	#ram

	mvn	80h,source_bank

	ldx	#0000h
	txy
;-------------------------------------------------------------------------;
HDMAinit:
;-------------------------------------------------------------------------;
	lda	reg_address,x
	sta	REG_DMAP0,y
	inx
	inx
	lda	reg_address,x
	sta	REG_A1T0L,y
	inx
	inx
	lda	#bank
	sta	REG_A1B0,y
	tya
	clc
	adc	#10h
	tay
	cpx	#table_length
	bne	HDMAinit
;-------------------------------------------------------------------------;
	sep	#20h
;-------------------------------------------------------------------------;
.endmacro
;-------------------------------------------------------------------------;


.endif

