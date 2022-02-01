.ifndef __MACROS_INC
__MACROS_INC = 1

;====================================================================
.include "snes.inc"
.include "snes_decompress.inc"
.include "snes_zvars.inc"
.include "snesmod.inc"
.include "soundbank.inc"
;====================================================================
.macro mod_play module, volume
;====================================================================
	ldx	#module
	jsr	spcLoad
	ldx	#0
	jsr	spcPlay
;--------------------------------------------------------------------
	ldx	#volume
	jsr	spcSetModuleVolume
;--------------------------------------------------------------------
	jsr	spcFlush
;--------------------------------------------------------------------
.endmacro
;====================================================================
.macro mod_stop
;====================================================================
	lda	#1
	sta	fadeout, S
	ldx	#0
	ldy	#8
	jsr	spcFadeModuleVolume
	jsr	spcProcess		; PROCESS SPC stuff
;--------------------------------------------------------------------
.endmacro
;====================================================================
.macro ReadButton button, routine, sub, branch
;====================================================================
        rep     #20h
        lda     joy1_down
        bit     #(button)
        sep     #20h
        beq     branch
	jsr	sub			; for different fade outs
        jmp     routine
branch:
;--------------------------------------------------------------------
.endmacro
;====================================================================
.endif
