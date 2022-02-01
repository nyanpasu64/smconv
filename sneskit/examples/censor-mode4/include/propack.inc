.ifndef __PROPACK_INC__
__PROPACK_INC__ = 1
;--------------------------------------------------------------------
; y = destination address
; x = source address
; a = bank number
;--------------------------------------------------------------------
.global Unpack
;--------------------------------------------------------------------

;--------------------------------------------------------------------
.macro DoDecompressPP source, destination
	ldx	#.loword(source)

.ifnblank addr
		lda	#^destination
		ldy	#.loword(destination)
.else
		lda	#7fh
		ldy	#0000h
.endif

	xba
	lda	#^source

	jsl	Unpack
.endmacro
;--------------------------------------------------------------------
.endif
