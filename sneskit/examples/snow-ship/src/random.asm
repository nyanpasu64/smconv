;-------------------------------------------------------------------------;
.include "random.inc"
.include "snes.inc"
.include "snes_joypad.inc"
;-------------------------------------------------------------------------;
.importzp joy1_down, timer
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
.zeropage
;/////////////////////////////////////////////////////////////////////////;


;-------------------------------------------------------------------------;
random:
	.res 2
temp:	.res 1
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
.code ;             by Blargg based on a PRNG posted on 6502.org          ;
;/////////////////////////////////////////////////////////////////////////;
; Requires two bytes in memory that don't get modified by anything else.
; They don't need to be next to each other. Set them to reseed the generator.

; Generate pseudo-random 8-bit value and return in A.
; Preserved: X, Y
	; See "linear-congruential random number generator" for more.
	;   [ http://6502.org/source/integers/random/random.html ]
.a8	; rand = (rand * 5 + 0x3611) & 0xffff;
.i16	; return (rand >> 8) & 0xff;


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
Random:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	lda	random+1
	sta	temp
	lda	random
	asl	a		; rand = rand * 4 + rand
	rol	temp
	asl	a
	rol	temp
	clc
	adc	random
	pha
	lda	temp
	adc	random+1
	sta	random+1
	pla			; rand = rand + 0x3611
	clc
	adc	#11h
	sta	random
	lda	random+1
	adc	#36h
	sta	random+1
	rts			; return high 8 bits


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
Seed: 
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	sta	temp		; seed values from White Flame
	adc	REG_OPHCT
	adc	timer		; use timer value
	eor	joy1_down	; use button presses
	eor	joy1_down+1
	eor	joy2_down
	eor	joy2_down+1

;/////////////////////////////////////////////////////////////////////////;
;                    by White Flame (aka David Holz)                      ;
;/////////////////////////////////////////////////////////////////////////;

	beq	doeor		; if 0 force eor
	asl			; shift left if high bit set do eor
	beq	noeor
	bcc	noeor
doeor:	eor	temp
noeor:	sta	random+1

	rts
