;*************************************************************************;
; SNESKit template
;*************************************************************************;

;-------------------------------------------------------------------------;
.include "snes.inc"
.include "snes_joypad.inc"
.include "snesmod.inc"
.include "soundbank.inc"
;-------------------------------------------------------------------------;
.global _nmi, main
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
.zeropage
;/////////////////////////////////////////////////////////////////////////;


;-------------------------------------------------------------------------;
bg_color:
	.res	2
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
.code
;/////////////////////////////////////////////////////////////////////////;


;-------------------------------------------------------------------------;
	.a8
	.i16
;-------------------------------------------------------------------------;


;.........................................................................;
; program entry point
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
main:
;:::::::::::::::::::::::::::::::::::::::;:::::::::::::::::::::::::::::::::;
	jsr	spcBoot			; boot SPC
	lda	#^__SOUNDBANK__		; setup soundbank
	jsr	spcSetBank		;
					;
	ldx	#MOD_POLLEN8		; load module into SPC
	jsr	spcLoad			;
					;
	lda	#39			; (*256 bytes = largest sound size)
	jsr	spcAllocateSoundRegion	;
					;
	lda	#^SoundTable|80h	; set sound table address
	ldy	#.LOWORD(SoundTable)	;
	jsr	spcSetSoundTable	;
					;
	ldx	#0			; play module starting at position 0
	jsr	spcPlay			;
					;
	ldx	#75			; lower the music volume a bit (75/255)
	jsr	spcSetModuleVolume	;
					;
	lda	#NMI_ON|NMI_JOYPAD	; enable IRQ, joypad
	sta	REG_NMITIMEN		;
					;
	lda	#0fh			; enable screen
	sta	REG_INIDISP		;
					;
main_loop:				;
					;
	lda	joy1_down		; on keypress A:
	bit	#JOYPAD_A		;
	beq	@nkeypress_a		;
					;
	spcPlaySoundM SND_TEST		; play sound using all default parameters

@nkeypress_a:

	jsr	spcProcess		; update SPC
	jsr	spcFlush

	wai
	
	rep	#20h

	inc	bg_color		; increment bg_color
	lda	bg_color

	sep	#20h

	stz	REG_CGADD
	sta	REG_CGDATA
	xba
	sta	REG_CGDATA
	bra	main_loop


;.........................................................................;
; NMI irq handler
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
_nmi:
;:::::::::::::::::::::::::::::::::::::::;:::::::::::::::::::::::::::::::::;
	rep	#30h			; a,x,y = 16-biy
					;
	pha				; push a,x,y
	phx				;
	phy				;
					;
	sep	#20h			; a = 16-bit
					;--------------------------
	jsr	joyRead			; read joypads
					;--------------------------
	lda	REG_TIMEUP		; read from REG_TIMEUP
					;
	rep	#30h			; a,x,y = 16-bit
					;
	ply				; pop y,x,a
	plx				;
	pla				;
	rti				; return


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
; Here is an example sound table. The sound table defines the sounds that
; will be used as streamed sound effects. The sound effect data must be in
; BRR format. This can be done with the SNESBRR tool by DMV47
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SoundTable:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SND_TEST = 0
	.byte	4			; DEFAULT PITCH (1..8) (hz = PITCH*2000)
	.byte	8			; DEFAULT PANNING (0..15)
	.byte	15			; DEFAULT VOLUME (0..15)
	.word	(TEST_END-TEST)/9	; NUMBER OF BRR CHUNKS IN SAMPLE (BYTES/9)
	.word	.loword(TEST)		; ADDRESS OF BRR SAMPLE
	.byte	^TEST			; ADDRESS BANK
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;/////////////////////////////////////////////////////////////////////////;
.segment "SOUNDS"
;/////////////////////////////////////////////////////////////////////////;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
TEST:				; include brr data into program
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
.incbin "../sound/tada.brr"	; tada sound, converted with snesbrr.exe
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
TEST_END:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;/////////////////////////////////////////////////////////////////////////;
.segment "HDATA"
;/////////////////////////////////////////////////////////////////////////;
.segment "HRAM"
;/////////////////////////////////////////////////////////////////////////;
.segment "HRAM2"
;/////////////////////////////////////////////////////////////////////////;
