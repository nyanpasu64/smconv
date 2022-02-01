;-------------------------------------------------------------------------;
.include "graphics.inc"
.include "hdma_wave.inc"
.include "print_letter.inc"
.include "snes.inc"
.include "snes_decompress.inc"
.include "snes_joypad.inc"
.include "snes_zvars.inc"
;-------------------------------------------------------------------------;
.import oam_table
;-------------------------------------------------------------------------;
.importzp frame_ready
;-------------------------------------------------------------------------;
.export DoHappy
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
BORDER_BOTTOM = 0c0h
BORDER_LEFT = 018h
BORDER_RIGHT = 0e0h
BORDER_TOP = 018h

MAX_BAR_WIDTH = 08h
MAX_SINE_ANGLE = 20h
MAX_SOUND = 07h
MAX_WAVE_SPEED = 07h
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
BG1GFX = 00000h
BG1MAP = 0e800h
BG2GFX = 06000h
BG2MAP = 0e000h
BG3MAP = 0f000h
OAMGFX = BG1GFX
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
.bss
;/////////////////////////////////////////////////////////////////////////;


;-------------------------------------------------------------------------;
oam_counter:
	.res 1
oam_hmov:
	.res 1
oam_hoff:
	.res 2
oam_vmov:
	.res 1
oam_voff:
	.res 2
oam_dir_lr:
	.res 1
oam_dir_ud:
	.res 1
sine_offset:
	.res 2
sine_speed:
	.res 1
sine_angle:
	.res 2
song_index:
	.res 1
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
DoHappy:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	rep	#10h
	sep	#20h
	;jsr	Snes_Init	; Cool Init routine! use it in your own code!!
	jsl	f:SONG		; jsl to sound
				; note: this sound is AMAZING! it took
				; 2 seconds to rip and 3 seconds to relocate!
				; all that you must do to relocate is change
				; the long LDA bank address and the one
				; lda #$02 pha plb
				; change it to the bank you need!
				; quite nice!
	rep     #10h		; X,Y fixed -> 16 bit mode
	sep     #20h		; Accumulator ->  8 bit mode

	lda	#BGMODE_2	; mode 2, 8/8 dot
	sta	REG_BGMODE	

	lda	#BG1MAP>>9	; BG0 Tile Address $7400
	sta	REG_BG1SC
	lda	#BG2MAP>>9	; BG1 Tile Address $7000
	sta	REG_BG2SC	
	lda	#BG3MAP>>9	; BG2 location, also sine wave location
				; Address $7800
	sta	REG_BG3SC
	lda	#BG2GFX>>9+BG1GFX>>13
	sta	REG_BG12NBA	; BG0 Graphics data 0000h
				; BG1 Graphics data 3000h
	lda	#TM_OBJ|TM_BG2|TM_BG1
	sta	REG_TM
	jsr	MakeTiles

	DoDecompressDataVram gfx_hnyTiles, BG2GFX
	DoDecompressDataVram gfx_hnyMap, BG2MAP+300h
	DoDecompressDataVram gfx_chrTiles, BG1GFX

	lda	#80h		; DecompressDataVram leaves REG_VMAIN 00h
	sta	REG_VMAIN

	DoCopyPalette gfx_1994Pal, 0 ,8
	DoCopyPalette gfx_hnyPal, 16, 16	; -ma1024 in grit file
	DoCopyPalette gfx_chrPal, 32, 16
	DoCopyPalette gfx_sprPal, 128, 16

	ldx	#BG2MAP/2+300h
	stx	REG_VMADDL

	ldx	#0100h
	lda	REG_VMDATALREAD
:	lda	REG_VMDATALREAD
	stz	REG_VMDATAH	; use palette 0 for 1994
	dex
	bne	:-

	rep	#30h

	lda	#SINE_END-SINE
	pha
	ldx	#SINE
	phx
	ldy	#RAM_SINE

	mvn	00h,00h

	plx			; copy sine data twice since
	pla			; RAM_SINE+60 will exceed 256
	ldy	#RAM_SINE+(SINE_END-SINE)

	mvn	80h,^SINE

	sep	#20h

	jsr	SpriteSetup

	ldx	#0000h
	stx	sine_offset	; sine offset lo
	lda	#0fdh
	sta	sine_speed	; 000h-0ffh
	lda	#01h		; sine angle
	sta	sine_angle	; sine angle	0-1fh
	stz	sine_angle+1	; sine angle high byte

	lda	#PALETTE2
	xba
	lda	#^TEXT
	ldx	#TEXT
	ldy	#BG1MAP/2
	jsr	SetupPrintLetter

	lda	#03h
	sta	song_index	; song # (2-7)

	jsr	SetupHDMAColorBars

	stz	oam_counter	; counter for # of sprites
	stz	oam_hoff	; sprite horizontal sine offset low
	stz	oam_hoff+1	; sprite horizontal sine offset high
	stz	oam_voff	; sprite vertical sine offset low
	stz	oam_voff+1	; sprite vertical sine offset high
	stz	oam_hmov	; sprite movement (horizontal)
	stz	oam_vmov	; sprite movement (vertical)
	stz	oam_dir_lr	; sprite flag for left/right movement
	stz	oam_dir_ud	; sprite flag for up/down movement
	jsr	WaitVb		; start HDMA in vertical blank

	lda	#%11
	sta	REG_HDMAEN	; enable first two HDMAs

	lda	#0fh
	sta	REG_INIDISP	; enable screen

	lda	song_index
	sta	REG_APUIO0	; turn on the MUSIC!!

	lda	#NMI_ON|NMI_JOYPAD
	sta	REG_NMITIMEN	; turn on vertical blank IRQ and joypad

	lda	#1
	sta	frame_ready

Waitloop:
	jsr	WaitVb		; wait for vertical blank

;===========================================================================
;                     Start of Vertical Blank Interrupt Routine
;===========================================================================

	ldx	#BG3MAP/2+20h	; set vram address to store vertical sine data
	stx	REG_VMADDL
	ldx	sine_offset	; get sine offset
	ldy	#0000h
SineWaver:
	lda	RAM_SINE,x
	sta	REG_VMDATAL	; store sine value in v-ram
	lda	#40h		; sine wave to affect second plane only!
	sta	REG_VMDATAH	; setting this to $60 affects both plane 0
				; and plane 1
	rep	#30h

	txa
	clc
	adc	sine_angle	; create sine angle by adding to the offset
	and	#00ffh		; make sure it doesn't go past 256 bytes in the
				; sine data!
	tax	

	sep	#20h

	iny
	cpy	#0020h		; only #32 needed, only 32 chars per line!
	bne	SineWaver

	lda	sine_offset
	clc
	adc	sine_speed	; add sine speed
	sta	sine_offset

	jsr	ClearTextScreen	; do backwards clear
	jsr	Joypad		; examine joypad readings
	jsr	PrintLetter	; prints 1 letter of text

Continue1:
	jsr	HDMAColorBars	; this does the red HDMA bar wave
	jsr	SpriteMover	; this moves the circular bouncing sprites

	bra	Waitloop


;=========================================================================;
;                      Joypad Control Routine
;=========================================================================;

Joypad:
	lda	joy1_down	; read lo-byte of joypad1 data
	ora	joy2_down
	bit	#JOYPAD_R	; was it Top Right?
	bne	DecreaseSineAngle
	bit	#JOYPAD_L	; was it Top Left?
	bne	IncreaseSineAngle
	bit	#JOYPAD_X	; was it X?
	bne	IncreaseBarWidth
	bit	#JOYPAD_A	; was it A?
	bne	IncreaseWaveSpeed

	lda	joy1_down+1	; read high byte of joypad data
	ora	joy2_down+1
	bit	#JOYPADH_RIGHT	; was it Right?
	bne	IncreaseSineSpeed
	bit	#JOYPADH_LEFT	; was it Left?
	bne	DecreaseSineSpeed
	bit	#JOYPADH_Y	; was it Y?
	bne	DecreaseBarWidth
	bit	#JOYPADH_B	; was it B?
	bne	DecreaseWaveSpeed
	bit	#JOYPADH_SELECT	; was it select
	bne	ChangeSound
	rts

;-------------------------------------------------------------------------;
DecreaseSineAngle:		; decrease sine angle data offset
;-------------------------------------------------------------------------;
	lda	sine_angle
	beq	ibwok
	dea
:	sta	sine_angle
	rts
;-------------------------------------------------------------------------;
IncreaseSineAngle:		; increase sine angle data offset
;-------------------------------------------------------------------------;
	lda	sine_angle
	ina
	cmp	#MAX_SINE_ANGLE
	bne	:-
	rts
;-------------------------------------------------------------------------;
DecreaseBarWidth:
;-------------------------------------------------------------------------;
	lda	hwave_other
	beq	ibwok
	dea
:	sta	hwave_other
	rts
;-------------------------------------------------------------------------;
IncreaseBarWidth:
;-------------------------------------------------------------------------;
	lda	hwave_other
	ina
	cmp	#MAX_BAR_WIDTH+1; not higher than 8!
	bne	:-
ibwok:	rts
;-------------------------------------------------------------------------;
DecreaseSineSpeed:		; slow down/reverse
;-------------------------------------------------------------------------;
	lda	sine_speed
	beq	ibwok
	dea
:	sta	sine_speed
	rts
;-------------------------------------------------------------------------;
IncreaseSineSpeed:		; speed up/forward
;-------------------------------------------------------------------------;
	lda	sine_speed
	ina
	bne	:-
	rts
;-------------------------------------------------------------------------;
ChangeSound:
;-------------------------------------------------------------------------;
	inc	song_index
	lda	song_index
	cmp	#MAX_SOUND+1	; did it go past sound 7?
	beq	OopsSound
:	sta	REG_APUIO0
	rts
;-------------------------------------------------------------------------;
OopsSound:
;-------------------------------------------------------------------------;
	lda	#02h		; set it to sound 2 (first sound)
	bra	:-
;-------------------------------------------------------------------------;
DecreaseWaveSpeed:
;-------------------------------------------------------------------------;
	lda	hwave_speed
	dea
	beq	ibwok
:	sta	hwave_speed
	rts
;-------------------------------------------------------------------------;
IncreaseWaveSpeed:
;-------------------------------------------------------------------------;
	lda	hwave_speed
	ina
	cmp	#MAX_WAVE_SPEED
	bne	:-
	rts


;===========================================================================
;                              Sprite Circle Maker
;===========================================================================

SpriteMover:			; Start of Sprite Sine draw routine

	rep	#30h
	sep	#20h

	ldy	#0000h
Sprtinfo_setup:
	ldx	oam_hoff	; Get offset for first sine (Horizontal)
	lda	RAM_SINE,x
	clc
	adc	oam_hmov	; add with horizontal movement (left/right)
	cmp	#BORDER_LEFT	; is it past the left border?
	bcs	lookhoriz	; no! it's more or equal to #$18
	lda	#BORDER_LEFT	; yes, stay at #$18
	bra	okhoriz

lookhoriz:
	cmp	#BORDER_RIGHT	; is it past the right border?
	bcc	okhoriz		; no! it is less than #$e0

	lda	#BORDER_RIGHT	; make it #$e0 if its greater than
okhoriz:
	sta	oam_table,y
	iny
	ldx	oam_voff	; get offset for second sine (Vertical)
	lda	RAM_SINE+60,x	; get SINE+60 to create co-sine and make
				; a circle
	clc
	adc	oam_vmov	; add vertical movement (up/down)
	cmp	#BORDER_TOP	; did it go past top border?
	bcs	lookvert	; no! it's greater than/equal to #$18
	lda	#BORDER_TOP	; yes! make it #$18
	bra	okvert
lookvert:
	cmp	#BORDER_BOTTOM	; did it go past bottom border?
	bcc	okvert		; no! it's less than #$c0
	lda	#BORDER_BOTTOM	; yes! make it #$c0
okvert:

	sta	oam_table,y
	iny
	lda	#2ah		; get asterisk * for star (the sprite object)
	sta	oam_table,y
	iny
	lda	#00h		; palette 0, set priority, no h/v flips
	sta	oam_table,y
	iny
	lda	oam_hoff
	clc
	adc	#08h		; space out the stars (by skipping 8)
	sta	oam_hoff
	lda	oam_voff
	sec
	sbc	#08h		; space out the stars (by skipping 8)
	sta	oam_voff
	inc	oam_counter	; ok we did a sprite
	lda	oam_counter
	cmp	#20h		; did we do 32 sprites?
	bne	Sprtinfo_setup	; no! finish the rest!

	stz	oam_counter	; ok all done! let's reset it for next time!

				; now to make the sprites move in a direction
	lda	oam_dir_lr	; do we move left or right? 0=right
	bne	decrease1e	; not right! we jump to the left!
				; ok, it's right
	dec	oam_hoff	; dec 18, inc 1a = move clockwise
	inc	oam_voff	;
	inc	oam_hmov	; inc 1e = right (2 INCs are twice as fast)
	inc	oam_hmov	; inc 1e = right
	lda	oam_hmov
	cmp	#98h		; is it time to go left?
	bcc	testvertical	; nope! it's less than #$98

	inc	oam_dir_lr	; ok turn on the move left flag; 1=left
	bra	testvertical	; jump to the vertical test

decrease1e:
	inc	oam_hoff	; when we move left we want the spin to
				; change too! now it's counter-clockwise!
	dec	oam_voff	;
	dec	oam_hmov	; dec 1e = left
	dec	oam_hmov	; dec 1e = left
	lda	oam_hmov
	cmp	#01h		; is it time to go right?
	bcs	testvertical	; nope.. it's higher than #$01

	dec	oam_dir_lr	; yes, set the move right flag; 0=right
testvertical:
	lda	oam_dir_ud	; do we move up or down? 0=down
	bne	decrease1f	; nope! move up!

	inc	oam_vmov	; inc 1f = down
	inc	oam_vmov	; inc 1f = down
	inc	oam_vmov	; inc 1f = down
				; 3 incs to add an oddity, making the bounce
				; go every where on the screen
	lda	oam_vmov
	cmp	#80h		; is it time to go up?
	bcc	endhvtest	; nope! it's less! go end the tests

	inc	oam_dir_ud	; yes! set the move up flag; 1=up
	bra	endhvtest	; go end the test

decrease1f:
	dec	oam_vmov	; dec 1f = up
	dec	oam_vmov	; dec 1f = up
	lda	oam_vmov
	cmp	#02h		; time to go down yet?
	bcs	endhvtest	; nope! its more than 2!

	dec	oam_dir_ud	; yes! set move down flag; 0=down
endhvtest:
	rts			; end of this routine!



;=========================================================================;
;                        Vertical Blank Wait Routine
;=========================================================================;
WaitVb:	
	lda	REG_RDNMI
	bpl     WaitVb	; is the number higher than #$7f? (#$80-$ff)
			; bpl tests bit #7 ($80) if this bit is set it means
			; the byte is negative (BMI, Branch on Minus)
			; BPL (Branch on Plus) if bit #7 is set in REG_RDNMI
			; it means that it is at the start of V-Blank
			; if not it will keep testing REG_RDNMI until bit #7
			; is on (which would make it a negative (BMI)
	rts

;=========================================================================;
;       	     SETUP ROUTINES FOR PROGRAM
;=========================================================================;

;=========================================================================;
;                                Make Tiles
;=========================================================================;

MakeTiles:
	ldx	#BG2MAP/2	; Select Vram Address $7000
	stx	REG_VMADDL
	ldx	#0000h
	txy
clearscreen1:			;
	stz	REG_VMDATAL	;    clear the whole graphics screen
	stz	REG_VMDATAH	;    by placing a blank tile on the matrix
	inx			;
	cpx	#0400h		;
	bne	clearscreen1	;

	ldx	#BG1MAP/2
	stx	REG_VMADDL
	tyx
clearscreen2:
	lda	#20h		; 
	sta	REG_VMDATAL	;
	stz	REG_VMDATAH	;   clear the text screen (fill with spaces)
	inx			;
	cpx	#0400h		;
	bne	clearscreen2	;

	ldx	#BG3MAP/2	
	stx	REG_VMADDL
	tyx
clearscreen3:			;
	stz	REG_VMDATAL	;   make sure that the Horizontal and Vertical
	stz	REG_VMDATAH	;   shifts are cleared (especially the Horiz.)  
	inx			;
	cpx	#0040h		;  32*2=60 = $40  (first 32 are the horizontal)
	bne	clearscreen3

	rts

;=========================================================================;
;                      Sprite (OAM) Initialization Routine
;=========================================================================;
SpriteSetup:
	stz	REG_OBSEL	; must be set before writing to sprite ram!
	stz	REG_OAMADDL	;
	stz	REG_OAMADDH	; sets sprite size and location in VRAM
				; for graf-x (points to location $0000)
				; same as the character set (text font)
	ldx	#oam_table&65535
	stx	REG_WMADDL
	lda	#^oam_table
	sta	REG_WMADDH

	lda	#20h
	ldx	#0000h
sprtclear:
	stz	REG_WMDATA	; Horizontal position = 0
	stz	REG_WMDATA	; Vertical position = 0
	sta	REG_WMDATA	; sprite object = 20 (space char)
				; invisible on the screen
	stz	REG_WMDATA	; palette = 0, priority = 0, h;v flip = 0
	inx
	cpx	#0080h		; (128 sprites)
	bne	sprtclear

sprtdataclear:
	stz	REG_WMDATA	; clear H-position MSB and make size small
	inx
	cpx	#00a0h		; 32 extra bytes for sprite data info
	bne	sprtdataclear
	jsr	SpriteMover	; set up the first sprites
	rts



;=========================================================================;
;                              Start of Data
;=========================================================================;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
TEXT:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
		;---[---[---[---||---]---]---]---
		;12345678901234567890123456789012
	.byte	"  "
	.byte	PL_CR,PL_CR,PL_CR,PL_CR
	.byte	"          HAPPY NEW YEAR",PL_CR
	.byte	"            ! 1994 !",PL_CR,PL_CR,PL_CR
	.byte	"  HERE'S A LATE CHRISTMAS GIFT "
	.byte	"   TO THE NEW SNES CODERS",PL_CR
	.byte	" WAITING TO DO SOMETHING IN THE "
	.byte	" NEW YEAR! THIS THING WAS CODED "
	.byte	" IN A FEW HOURS JUST OUT OF THE "
	.byte	" USUAL BOREDOME OF THE HOLIDAYS "
	.byte	PL_CR,PL_CR
	.byte	"  USE THE JOYPAD TO PLAY WITH",PL_CR
	.byte	"         THE SINUS WAVE",PL_CR
	.byte	"  TOP LEFT: DECREASE SINE ANGLE "
	.byte	" TOP RIGHT: INCREASE SINE ANGLE "
	.byte	"      LEFT: DECREASE SINE SPEED "
	.byte	"     RIGHT: INCREASE SINE SPEED "
	.byte	"    SELECT: CHANGE SONG",PL_CR
	.byte	"         X: INCREASE BAR WIDTH",PL_CR
	.byte	"         Y: DECREASE BAR WIDTH",PL_CR
	.byte	"         A: INCREASE WAVE SPEED "
	.byte	"         B: DECREASE WAVE SPEED "
	.byte	"                                "
	.byte	"                                "
	.byte	PL_STOP_TEXT
	.byte	"  ",PL_CR,PL_CR,PL_CR
	.byte	"     CHEAP CODING BY -PAN-",PL_CR,PL_CR
	.byte	"     FONT WAS MADE BY -PAN-",PL_CR,PL_CR
	.byte	" FONTS FOR GRAPHICS ARE UNKNOWN ",PL_CR
	.byte	" I TOOK THEM FROM A COLLECTION",PL_CR
	.byte	"   OF FONTS ON SOME NEW AMIGA",PL_CR
	.byte	" COLOR FONT EDITOR...",PL_CR,PL_CR
	.byte	"  THE MUSIC IS FROM BIO-METAL",PL_CR
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	PL_STOP_TEXT
	.byte	"  ",PL_CR,PL_CR,PL_CR
	.byte	"          GREETINGS TO:"
	.byte	PL_CR
	.byte	"        THE WHITE KNIGHT",PL_CR
	.byte	"              MICRO",PL_CR
	.byte	"          XAD/NIGHTFALL",PL_CR
	.byte	"           SIGMA SEVEN!",PL_CR
	.byte	"             POTHEAD",PL_CR
	.byte	"             SLAPSHOT",PL_CR
	.byte	"             LOVERMAN",PL_CR
	.byte	"            BELGARION",PL_CR
	.byte	"              PICARD",PL_CR
	.byte	"            AYATOLLAH",PL_CR
	.byte	"      ALL ANTHROX MEMBERS",PL_CR
	.byte	"             AND YOU!",PL_CR
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte PL_RESET_TEXT
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SINE:		; sine data  wave form: 0-100   length 256 bytes
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
 .byte  050,051,052,054,055,056,057,059,060,061,062,063,065,066,067,068
 .byte	069,070,071,072,074,075,076,077,078,079,080,081,082,083,084,084
 .byte	085,086,087,088,089,089,090,091,092,092,093,094,094,095,095,096
 .byte	096,097,097,097,098,098,099,099,099,099,099,100,100,100,100,100
 .byte	100,100,100,100,100,100,099,099,099,099,099,098,098,097,097,097
 .byte	096,096,095,095,094,094,093,092,092,091,090,089,089,088,087,086
 .byte	085,084,084,083,082,081,080,079,078,077,076,075,074,072,071,070
 .byte	069,068,067,066,065,063,062,061,060,059,057,056,055,054,052,051
 .byte	050,049,048,046,045,044,043,041,040,039,038,037,035,034,033,032
 .byte	031,030,029,028,026,025,024,023,022,021,020,019,018,017,016,016
 .byte	015,014,013,012,011,011,010,009,008,008,007,006,006,005,005,004
 .byte	004,003,003,003,002,002,001,001,001,001,001,000,000,000,000,000
 .byte	000,000,000,000,000,000,001,001,001,001,001,002,002,003,003,003
 .byte	004,004,005,005,006,006,007,008,008,009,010,011,011,012,013,014
 .byte	015,016,016,017,018,019,020,021,022,023,024,025,026,028,029,030
 .byte	031,032,033,034,035,037,038,039,040,041,043,044,045,046,048,049
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SINE_END:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;==========================================================================
;                             Start Of Bank #$02
;==========================================================================
.segment "DATA"

SONG:
	.incbin "../dat/spc_b1"	; include the song data!
				; since the data is 32768 bytes long it
				; will use up the entire bank
				; so there's no need to .pad out the rest
;==========================================================================
;                                  THE END
;==========================================================================
; BTW: this whole demo can be made on any BASIC compiler using these
; 3 lines:
; 10 Print "-Pan- Rules",
; 20 Print ":) :) :) :)",
; 30 Goto 10
;
; although it doesn't give the same colorful effect it will work!
