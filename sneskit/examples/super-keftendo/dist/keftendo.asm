; "Super Keftendo" 256-byte SNES intro source code
; by Revenant

; http://www.pouet.net/prod.php?which=70163

; This is an attempt at implementing the "Kefrens bars" effect on the SNES, using less than
; 256 bytes of ROM. The technique used here is to set up a 256-color line buffer using
; Mode 7, then rendering a few pixels directly to CGRAM every scanline and resetting the
; Y-scroll position to display the same buffer on every visible scanline as it is repeatedly
; rendered to. Some more information about specific size optimizations are detailed later.

; This was made using my own assembler "xkas-plus", but it should be compatible with the 
; original xkas v14, and it should also be trivial to port to any other assembler.

; (weird comment syntax for github syntax highlighting purposes)

arch snes.cpu
lorom

define FrameSinePos $0000
define ScratchTable $01 //;$0200
define SineTable    {ScratchTable}+$40

org $80ff00

//; 32 bytes (ff00 - ff1f)
InitSineTable:
db  64,  69,  74,  78,  83,  87,  91,  95
db  99,  102,  105,  107,  109,  110,  111,  112
db  112,  111,  111,  109,  107,  105,  102,  99
db  96,  92,  88,  83,  79,  74,  69,  65

//; ff20 - ...
Reset:

	//; Use the "high" part of address space (A23=1) 
	jml   +
+
	//; We could SEI here to disable interrupts, and we have a free byte to do so,
	//; but raster IRQs are never active on power on and we never enable them ourselves
	clc
	xce
	php
	
	//; Set up the rest of the sine table here
	ldx   #$20
	//; y "should" be 0 here, but it saves a byte to just do this 
	//; and then subtract $20 from the table addresses instead
	txy
-

	//; The table in ROM only covers a little more than half a sine wave 
	//; (0 <=x < 185 or so degrees), but we can extrapolate this to a full wave
	//; which takes up 64 bytes and looks continuous enough to be usable
	lda.w InitSineTable-$20,y
	sta.w {ScratchTable}-$20,y
	iny
	eor.b #$7f
	sta.b {ScratchTable}+$1f,x
	dex
	bne   -
	//; x is now 0 here
	//; Now repeat the 64-bit sine table across a full 256 bytes so that we can
	//; easily index it with a full 8-bit index
-
	lda.b {ScratchTable},x
	sta.b {SineTable},x
	inx
	bne   -
	
	//; x is now 0 here again
	//; We will be using 16-bit index registers in order to write register pairs...
	rep   #$10
	//; ...and using $2100 as the direct page, since from this point on about 98% of
	//; reads or writes will be to the B-bus
	pea   $2100
	pld
	
	//; $2100: disable the display so we can start setting up VRAM
	//; (C will already be set from previous XCE, so we can do it in 2 bytes like this)
	ror   $00
	
	//; $2133: disable hires, interlace, etc
	stz   $33
	
	//; $210d: set mode 7 bg x-position, slightly offset
	lda   #$ff
	sta   $0d
	sta   $0d
	
	//; $211f-20: center mode 7 bg at (127, 127)
	lda   #$7f
	sta   $1f
	stz   $1f
	sta   $20
	stz   $20
	
	//; $211b-1e: rotate 90 degrees clockwise so we can fill in pixels the way we want
	//; (This puts the leftmost column of the BG at the topmost row of the screen)
	stz   $1e
	stz   $1e
	lda.b #$ff
	stz   $1d
	sta   $1d
	lda.b #$01
	stz   $1c
	sta   $1c	
	stz   $1b
	stz   $1b
	
	//; the next few STAs assume a == 1
	//; $211a: flip screen horizontally
	//; (This puts the "topmost" tile in VRAM at the left edge of the screen)
	sta   $1a
	
	//; $420d: enable fastrom
	//; (This is necessary since we will be doing important stuff in hblank, but there
	//;  is not enough space to set up DMA or HDMA)
	sta   $420d
	
	//; $212c: enable layer 1
	sta   $2c
	
	//; $212e-2f: disable window
	stx   $2e

	//; $2130-31: disable color math
	stx   $30
	
	//; Set up Mode 7 tilemap
	lda.b #$02
	//; $2115: increment on write to $2118 (low bytes) and advance by 128 words per write
	//; This allows us to write the first tile of each row in a tight loop, which becomes
	//; the topmost row of tiles on our rotated background
	sta   $15 
	//; $2116: start at VRAM $0000
	stx   $16
	
	lda.b #$00
-
	sta   $18 //; make a row of increasing tile numbers across the top of the screen
	inc
	bpl   -
	
	lda.b #$80
	//; $2115: increment on write to $2119 (high bytes) and advance by 1 word per write
	//; With the way we have set up the screen and tile map, this allows us to create a
	//; 256-color line buffer by writing increasing palette index values to the "pixel" 
	//; part of mode 7 VRAM (aka the high bytes).
	sta   $15
	//; $2116: start at VRAM $0000 again
	stx   $16
	
	ldx.w #$07
	//; $2105: use mode 7 (see below for the reason this is done here and not earlier)
	//; $2106: disable mosaic filter
	stx   $05
	
	//; Hardware init is done so we can return to using 8-bit index registers
	plp
	lda.b #$00
.palloop:
	sta   $19 //; fill in palette entry
	//; The value 0x07 from the write to $2105 is reused here as a loop counter
	//; since we need to write 7 rows of dummy pixels for each actual pixel
	txy
-
	stz   $19 //; fill in dummy pixels
	dey
	bne   -
	inc
	bne   .palloop
	
	//; wait until start of vblank
	//; (Forced blanking is still on at this point, but this ensures we start to render
	//; the effect at the top of the screen on the first frame)
-
	bit   $4212
	bpl   -
	
VBlank:
	//; $2121-22: clear CGRAM line buffer
	stz   $21
	lda   #$00
-
	stz   $22
	stz   $22
	inc
	bne   -
	
	//; $210f: enable screen
	lda.b #$0f
	sta   $00
	
	//; Wait until end of vblank
-
	bit   $4212
	bmi   -
	
Start:	
	//; x = current index into sine table
	//;     (incremented in memory every frame, incremented in register every scanline)
	inc.w {FrameSinePos}
	ldx.w {FrameSinePos}
	//; y = vertical scroll position (decremented in register every scanline)
	ldy.b #$ff
	
Loop:
	//; Do something like "a = sin(x) + sin(x/4 + y)"
	phy
	txa
	lsr
	lsr
	clc
	adc   1,s
	tay
	lda.w {SineTable},y
	ply
	adc.w {SineTable},x
	
	//; We could have the bars spanning the whole screen, but with the limited size of
	//; both the sine table and the individual bars, it looks kind of crappy, in my 
	//; opinion. Instead, condense the bars and get them roughly centered on screen
	lsr
	clc
	adc   #$40
	
	//; Increment x for the next scanline
	inx
	
	//; Wait until either hblank (to render the next line) or vblank (to clear the buffer)
-
	bit   $4212
	bmi   VBlank //; currently in vblank
	bvc   - //; currently not in hblank
	
	//; $2121: use the current sine value as the CGRAM address to write to.
	//; With our line buffer setup, this now also equals the X position on screen
	sta   $21
	
	//; $210e: reset v-scroll
	//; (Doing this after the actual rendering can be visibly glitchy, due to slightly
	//;  overrunning the hblank period)
	lda   #$3f
	sty   $0e
	sta   $0e
	
	//; $2122: render the bar!
	//; This uses only 1 byte for color (blue + partial green channels), and then
	//; shifts the value to create additional colors. Looks like crap, but saves bytes.
	//; Unfortunately hblank time is scarce, so we can only draw 4 pixels this way
	lda   #$63
	stz   $22
	sta   $22
	lsr
	stz   $22
	sta   $22
	lsr
	stz   $22
	sta   $22
	stz   $22
	sta   $22
	
	//; Repeat until vblank
	dey
	bra   Loop

//; The reset vector. Try not to trash this
warnpc $80fffd
org $fffc
dw Reset
dw 0
