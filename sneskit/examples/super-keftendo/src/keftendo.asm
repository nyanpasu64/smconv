;-------------------------------------------------------------------------;
.include "snes.inc"
;-------------------------------------------------------------------------;
.export DoKeftendo
;-------------------------------------------------------------------------;
; "Super Keftendo" 256-byte SNES intro source code
; by Revenant
;
; http:www.pouet.net/prod.php?which=70163
;
; This is an attempt at implementing the "Kefrens bars" effect on the SNES,
; using less than 256 bytes of ROM. The technique used here is to set up a
; 256-color line buffer using Mode 7, then rendering a few pixels directly
; to CGRAM every scanline and resetting the Y-scroll position to display
; the same buffer on every visible scanline as it is repeatedly rendered to.
; Some more information about specific size optimizations are detailed later.
;
; This was originally made using my own assembler "xkas-plus", but it
; should be compatible with the original xkas v14, and it should also be
; trivial to port to any other assembler.
;
; (weird comment syntax for github syntax highlighting purposes
;-------------------------------------------------------------------------;
; this code is 240 bytes w/o joypad & End; 281 with... although keep in
; mind that the included sneskit code (snes_init) adds 327 bytes
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
SCRATCH_TABLE = 0600h
SINE_TABLE    = SCRATCH_TABLE+40h
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
.zeropage
;/////////////////////////////////////////////////////////////////////////;


FrameSinePos:
	.res 1
Direction:
	.res 1


;/////////////////////////////////////////////////////////////////////////;
.code
;/////////////////////////////////////////////////////////////////////////;


	.a8
	.i16


;=========================================================================;
End:
;=========================================================================;
	rep	#38h

	lda	#0000h			; restore direct page to 0
	tcd

	sep	#20h

	lda	#80h
	sta	<REG_INIDISP

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
DoKeftendo:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;

	sep	#30h
				; Set up the sine table here. y should be 0
	ldx	#20h		; here, but it saves a byte to do this, then
	txy			; subtract 0x20 from the table addresses
;-------------------------------------------------------------------------;
:	lda	INIT_SINE_TABLE-20h,y	; The table in ROM only covers a
	sta	SCRATCH_TABLE-20h,y	; little more than half a sine wave
	iny				; (0 <=x < 185 or so degrees) but we
	eor	#7fh			; can extrapolate this to a full wave
	sta	SCRATCH_TABLE+1fh,x	; which takes up 64 bytes and looks
	dex				; continuous enough to be usable
	bne	:-
;-------------------------------------------------------------------------;
				; x is now 0 here
;-------------------------------------------------------------------------;
:	lda	SCRATCH_TABLE,x	; Now repeat the 64-bit sine table across a
	sta	SINE_TABLE,x	; full 256 bytes so that we can easily index
	inx			; it with a full 8-bit index
	bne	:-
;-------------------------------------------------------------------------;
				; x is now 0 here again

	rep	#10h

	; We will be using 16-bit index registers in order to write register
	; pairs and using $2100 as the direct page, since from this point on
	; about 98% of reads or writes will be to the B-bus

	pea	REG_INIDISP
	pld

	; REG_INIDISP has already been set to $80 by snes_init
	; original comment follows:
	; disable the display so we can start setting up VRAM
	; (C will already be set from previous XCE, so we can do it in 2 bytes
	; like this

	;ror	<REG_INIDISP	; REG_INIDISP == 80h
	stz	<REG_SETINI	; disable hires, interlace, etc.
	
	stz	<REG_M7D	; $211b-1e: rotate 90 degrees clockwise so we
	stz	<REG_M7D	; can fill in pixels the way we
	lda	#0ffh		; want (This puts the leftmost column of the
	stz	<REG_M7C	; BG at the topmost row of the screen)
	sta	<REG_M7C

	sta	<REG_BG1HOFS	; while $ff is loaded set bg
	sta	<REG_BG1HOFS	; x-position, slightly offset

	lda	#01h		; the next few STAs assume a == 1
	stz	<REG_M7B
	sta	<REG_M7B	

	stz	<REG_M7A
	stz	<REG_M7A
	
	sta	<REG_M7SEL	; flip screen horizontally
	
	; REG_MEMSEL: enable fastrom
	; (This is necessary since we will be doing important stuff in hblank,
	;  but there is not enough space to set up DMA or HDMA

	sta	REG_MEMSEL	; enable fastrom
	sta	<REG_TM		; enable layer 1

	; the following is not needed because snes_init has already been called
	;stx	<REG_TMW	; $212e-2f: disable window
	;stx	<REG_CGSWSEL	; $2130-31: disable color math

	inc			; a is now 2 here

	; REG_VMAIN: increment on write to REG_VMDATAL (low bytes and advance
	; by 128 words per write. This allows us to write the first tile of
	; each row in a tight loop, which becomes the topmost row of tiles on
	; our rotated background

	sta	<REG_VMAIN
	stx	<REG_VMADD	; start at VRAM $0000

	lda	#00h		; Set up Mode 7 tilemap
;-------------------------------------------------------------------------;
:	sta	<REG_VMDATA	; make a row of increasing tile numbers
	inc			; across the top of the screen
	bpl	:-
;-------------------------------------------------------------------------;
	dea			; a is now 7fh here
	sta	<REG_M7X	; center mode 7 bg at (127, 127)
	stz	<REG_M7X
	sta	<REG_M7Y
	stz	<REG_M7Y

	lda	#VMAIN_INCH

	; REG_VMAIN: increment on write to REG_VMDATAH (high bytes and advance
	; by 1 word per write. With the way we have set up the screen and tile
	; map, this allows us to create a 256-color line buffer by writing
	; increasing palette index values to the "pixel" part of mode 7 VRAM
	; (aka the high bytes).

	sta	<REG_VMAIN
	stx	<REG_VMADD	; start at VRAM $0000 again
;-------------------------------------------------------------------------;
	sep	#10h		; return to 8-bit index registers

	ldx	#BGMODE_7	; use mode 7 (see below for the reason this
	stx	<REG_BGMODE	; is done here and not earlier
;-------------------------------------------------------------------------;
	lda	#00h
;-------------------------------------------------------------------------;
@palloop:
;-------------------------------------------------------------------------;
	sta	<REG_VMDATAH	; fill in palette entry

	; The value 0x07 from the write to REG_BGMODE is reused here as a loop
	; counter since we need to write 7 rows of dummy pixels for each actual
	; pixel

	txy
;-------------------------------------------------------------------------;
:	stz	<REG_VMDATAH	; fill in dummy pixels
	dey
	bne	:-
;-------------------------------------------------------------------------;
	inc
	bne	@palloop
;-------------------------------------------------------------------------;
	lda	#NMI_JOYPAD
	sta	REG_NMITIMEN

	; Forced blanking is still on at this point, but we wait for vblank
	; to ensure we start rendering the effect at the top of the screen
	; on the first frame

;-------------------------------------------------------------------------;
:	bit	REG_HVBJOY	; wait until start of vblank
	bpl	:-
;-------------------------------------------------------------------------;
	lda	#0fh		; enable screen
	sta	<REG_INIDISP
;-------------------------------------------------------------------------;
VBlank:
;-------------------------------------------------------------------------;
	stz	<REG_CGADD	; clear CGRAM line buffer
	lda	#00h
;-------------------------------------------------------------------------;
:	stz	<REG_CGDATA
	stz	<REG_CGDATA
	inc
	bne	:-
;-------------------------------------------------------------------------;
:	lda	REG_HVBJOY
	and	#01h
	bne	:-

:	lda	REG_HVBJOY
	and	#01h
	bne	:-
;--------------------------------------------------------------------
	rep	#20h

	lda	a:REG_JOY1L
	ora	a:REG_JOY2L
	beq	:+
;--------------------------------------------------------------------
	jmp	End
;--------------------------------------------------------------------
:	sep	#20h
;-------------------------------------------------------------------------;
:	bit	REG_HVBJOY	; wait until end of vblank
	bmi	:-
;-------------------------------------------------------------------------;
Start:
;-------------------------------------------------------------------------;
	; x = current index into sine table
	;     (incremented in memory every frame, incremented in register every
	;      scanline)
	; y = vertical scroll position (decremented in register every scanline)

	inc	a:FrameSinePos
	ldx	a:FrameSinePos

	ldy	#00h
;--------------------------------------------------------------------
Loop:
;--------------------------------------------------------------------
	dey
	phy			; Do something like
	txa			; "a = sin(x) + sin(x/4 + y)"
	lsr
	lsr
	clc
	adc	1,s
	tay			; We could have the bars span the whole screen,
	lda	SINE_TABLE,y	; but with the limited size of both the sine
	ply			; table and the individual bars, it looks kind
	adc	SINE_TABLE,x	; of crappy, in my opinion.
				;
	lsr			; Instead, condense the bars...
	clc			; 
	adc	#40h		; ...and get them roughly centered on screen
				;
	inx			; Increment x for the next scanline
;-------------------------------------------------------------------------;
:	bit	REG_HVBJOY	; wait until hblank or vblank
	bmi	VBlank		; currently in vblank, clear the buffer
	bvc	:-		; currently not in hblank
;-------------------------------------------------------------------------;
				; hblank - render the next line. Use the
				; current sine value as the CGRAM address
	sta	<REG_CGADD	; to write to. With our line buffer setup,
				; this now also equals the X pos on screen
				;
	lda	#63h		; Reset v-scroll. Doing this after the actual
	sty	<REG_BG1VOFS	; rendering can be visibly glitchy, due to
	sta	<REG_BG1VOFS	; slightly overrunning the hblank period
				;
	stz	<REG_CGDATA	; $2122: render the bar!
	sta	<REG_CGDATA	; This uses only 1 byte for color blue +
	lsr			; partial green channels, and then shifts the
	stz	<REG_CGDATA	; value to create additional colors. Looks
	sta	<REG_CGDATA	; like crap, but saves bytes.
	lsr			;
	stz	<REG_CGDATA	; Unfortunately hblank time is scarce
	sta	<REG_CGDATA	; so we can only draw 4 pixels this way
	stz	<REG_CGDATA
	sta	<REG_CGDATA
	
	bra	Loop		; Repeat until vblank


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
INIT_SINE_TABLE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte   64, 69, 74, 78, 83, 87, 91, 95
	.byte   99,102,105,107,109,110,111,112
	.byte  112,111,111,109,107,105,102, 99
	.byte   96, 92, 88, 83, 79, 74, 69, 65
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
