;-------------------------------------------------------------------------;
.include "hdma_wave.inc"
.include "snes.inc"
.include "snes_zvars.inc"
;-------------------------------------------------------------------------;
.export RAM_SINE
.export HDMAColorBars, SetupHDMAColorBars
.export hwave_other, hwave_speed
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
MAX_BARS = 08h
RAM_CGADD = 0400h
RAM_CGDATA = 0600h
RAM_SINE = 0900h
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
.bss
;/////////////////////////////////////////////////////////////////////////;


;-------------------------------------------------------------------------;
hwave_bars:
	.res 2
hwave_offset:
	.res 2
hwave_other:
	.res 2
hwave_other_ofs:
	.res 2
hwave_speed:
	.res 2
storage:
	.res 2
;-------------------------------------------------------------------------;


;=========================================================================;
;      Code (c) 1993-94 -Pan-/ANTHROX  All code can be used at will!
;               Music is copyrighted by its respectful owners
;                      and was used without permission
;=========================================================================;


;/////////////////////////////////////////////////////////////////////////;
	.code
;/////////////////////////////////////////////////////////////////////////;


	.a8
	.i16


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
SetupHDMAColorBars:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	;sta	colorbar_ptr+2	; could use a pointer... or specific ram
	;stx	colorbar_ptr	; location if you want to alter the colors
				; could do the same thing with RAM_SINE
	ldx	#0000h
	stx	hwave_offset	; HDMA wave offset
	stx	hwave_other_ofs	; HDMA waves offset
	lda	#MAX_BARS
	sta	hwave_bars	; number of HDMA waves		
	sta	hwave_other	; WIDTH between "other bars"
	lda	#01h
	sta	hwave_speed	; speed of HDMA wave

	lda	#01h		; 1 scan line width
	ldx	#0000h
	txy			; transfer x to y, that way Y=X (y=#$0000)
;-------------------------------------------------------------------------;
:	sta	RAM_CGADD,x	; scan line width
	inx
	stz	RAM_CGADD,x	; color # 0
	inx
	cpx	#241*2		; number of scan lines/2
	bne	:-
;-------------------------------------------------------------------------;
	stz	RAM_CGADD-2,x	; end of hdma (0 scan line width=end)
;-------------------------------------------------------------------------;
	tyx
;-------------------------------------------------------------------------;
:	sta	RAM_CGDATA,x	; scan line width
	inx
	stz	RAM_CGDATA,x	; color for color #0 = black
	inx
	stz	RAM_CGDATA,x	; black (high byte)
	inx
	cpx	#241*3		; # of lines to make/3
	bne	:-
;-------------------------------------------------------------------------;
	stz	RAM_CGDATA-3,x	; end hdma
;-------------------------------------------------------------------------;
	stz	REG_DMAP0	; type of byte pattern? 0=1 byte register
	lda	#<REG_CGADD	; 21xx   this makes it register 2121 (pallete)
	sta	REG_BBAD0
	ldx	#RAM_CGADD
	stx	REG_A1T0L
	stz	REG_A1B0	; bank of data location in ram
				; next HDMA
	lda	#DMAP_XFER_MODE_2
	sta	REG_DMAP1	; 2= 2 bytes per register (not a word!)
	lda	#<REG_CGDATA
	sta	REG_BBAD1	; 21xx   this is 2122 (colors)
	ldx	#RAM_CGDATA
	stx	REG_A1T1L
	stz	REG_A1B1

	rts


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
HDMAColorBars:			; HDMA red waving bars routine
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	stz	hwave_other_ofs	; reset the "other bars" offset
	jsr	Hwsetup		; go to sine offset routine
	ldy	#0020h		; get start of BLACK colors offset
	lda	#40h		; get end of BLACK colors offset
	sta	storage
	stz	storage+1	
	jsr	CopyHwave	; draw colors
;-------------------------------------------------------------------------;
Hwaverout:
;-------------------------------------------------------------------------;
	jsr	Hwsetup		; go to sine offset routine
	ldy	#0006h		; get start of RED colors
	lda	#18h		; get end of RED colors
	sta	storage
	jsr	CopyHwave	; draw colors
	dec	hwave_bars	; decrease # of bars to draw
	lda	hwave_bars
	bne	Hwaverout	; did it hit 0?
	lda	#MAX_BARS
	sta	hwave_bars	; yes, put 8 back in for next time
	lda	hwave_offset
	clc
	adc	hwave_speed	; increase sine data offset
	sta	hwave_offset
	rts

;=========================================================================;
Hwsetup:
;=========================================================================;
	rep	#30h

	lda	hwave_offset	; get sine data offset
	clc
	adc	hwave_other_ofs	; add "other bars" offset so we can see
				; the other bars!

	and	#00ffh		; make sure it doesn't go past 256 bytes
				; in sine data		
	tax
	sep	#20h
	lda	RAM_SINE,x	; read sine data and store it
	sta	storage
	stz	storage+1
	rep	#30h
	lda	storage		; get sine data back
	clc
	adc	#0040h		; add #$40 to get it centered in the screen 
	sta	storage		; store it
	asl a			; multiply it by 2 by shifting left
	clc
	adc	storage		; add it with itself to get *3
				; we do this because the HDMA color data
				; is stored as WIDTH, Colorlo, Colorhi
				; if we wanted the second line it would be this
				; 1*2+1=3
				; the first line would be:
				; 0*2+0=0
	inc a			; add 1 to it to skip the WIDTH byte
	clc
	tax

	sep	#20h

	rts


;=========================================================================;
CopyHwave:
;=========================================================================;
	lda	COLORBAR,y	; read the color data
	;lda	(colorbar_ptr),y
	;lda	RAM_COLORBAR,y
	sta	RAM_CGDATA,x	; store it in HDMA color list
	iny
	inx			
	lda	COLORBAR,y	; get next color byte 
	;lda	(colorbar_ptr),y
	;lda	RAM_COLORBAR,y
	sta	RAM_CGDATA,x	; store in HDMA color list
	inx
	inx			; increase X again to skip the WIDTH byte
	iny
	cpy	storage		; did it copy all the needed colors?
	bne	CopyHwave

	lda	hwave_other_ofs
	clc
	adc	hwave_other	; add to the "other bars" offset
				; changing this number makes the bars closer
				; together or further apart
	sta	hwave_other_ofs

	rts


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
COLORBAR:	;    red bars
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
		;    red bars
	.word	$0000,$0000,$0000,$201A,$28DC,$315C,$3A1E,$429E
	.word	$3A1E,$315C,$28DC,$201A,$0000,$0000,$0000,$0000
		;    black bars (used to erase the red bars)
		;    although you'll notice on some patterns the red bars
		;    appear to "leak" through.. this is due to the reading
		;    of the sine data (it skips some lines, so it may skip a
		;    red line as well)
	.word	$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	.word	$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
