;--------------------------------------------------------------------------
.include "snes.inc"
.include "snes_decompress.inc"
.include "snesmod.inc"
.include "soundbank.inc"
;--------------------------------------------------------------------------
.import clear_vram, oam_table
;--------------------------------------------------------------------------
.importzp frame_ready
;--------------------------------------------------------------------------
.export DoStreet
;--------------------------------------------------------------------------
BG1GFX = 00000h
BG1MAP = 04000h
BG2GFX = 06000h
BG2MAP = 04400h
BG3MAP = 04c00h
SPRGFX = 0c000h

PLANE1_OFFSET	=	7e9800h
PLANE2_OFFSET1	=	7e1e00h
PLANE2_OFFSET2	=	PLANE2_OFFSET1+40h

oam = oam_table

;--------------------------------------------------------------------------
.bss
;--------------------------------------------------------------------------
xstorage1:	.res 2
xstorage2:	.res 2
pointeroffset:	.res 2
pointertimer:	.res 2
joydata:	.res 2
pointHV:	.res 2
babyunioffset:	.res 2
xstorage3:	.res 2
xstorage4:	.res 2
sineoffset:	.res 2
turtanim:	.res 2
turttimer:	.res 2
turthpos:	.res 2
Turtshellanim:	.res 2
Turtshelltimer:	.res 2
Turtshellhpos:	.res 2
chunkenanim:	.res 2
chunkentimer:	.res 2

;--------------------------------------------------------------------------
.segment "XCODE"
;--------------------------------------------------------------------------

;==========================================================================
;        Code (c) 1994 -Pan-/ANTHROX   All code can be used at will!
;==========================================================================                     
DoStreet:

	rep     #10h		; X,Y fixed -> 16 bit mode
	sep     #20h		; Accumulator ->  8 bit mode

	jsr	clear_vram

	ldx	#MOD_BIONIC
        jsr     spcl

	lda	#BGMODE_3	; mode 1, 8/8 dot
	sta	REG_BGMODE	
	lda	#TM_OBJ|TM_BG2|TM_BG1
	sta	REG_TM
	lda	#BG1MAP>>8
	sta	REG_BG1SC
	lda	#BG2MAP>>8
	sta	REG_BG2SC
	lda	#BG3MAP>>8
	sta	REG_BG3SC	; sine wave storage

	lda	#BG2GFX>>9+BG1GFX>>9
	sta	REG_BG12NBA

	jsr	Copy_Gfx	; Put graf-x in vram

	DoCopyPalette Colors, 0, 80
	DoCopyPalette Sprcol,  128, 48

	jsr	Make_tiles	; set up the screen
	jsr	HDMA		; set up HDMA
	jsr	Sprite_setup	; set up sprites

	rep	#10h
	sep	#20h

	ldx	#0000h
	stx	pointeroffset
	stx	pointertimer
	stx	babyunioffset
	stx	sineoffset
	stx	turtanim
	stx	turttimer
	stx	Turtshellanim 
	stx	Turtshelltimer
	stx	chunkenanim 
	stx	chunkentimer

	ldx	#0080h
	stx	turthpos

	ldx	#00a0h
	stx	Turtshellhpos

	ldx	#0a820h
	stx	pointHV

	lda	#63h
	sta	REG_OBSEL

	lda	#1
	sta	frame_ready

	lda	#0fh
	sta	REG_INIDISP	; turn the screen on

Waitloop:
	jsr	WaitVb		; wait for vertical blank
	jsr	snowfall
	jsr	chunkenanimation
	jsr	pointer
	jsr	babyuni
	jsr	Turtle
	jsr	Turtleshell

	jsr	joybutton
	jsr	Joypad
	jsr	Plane1hHDMA
	bra	Waitloop	; constant loop

;==========================================================================
;                       Cheezy Snow Fall Routine :)
;==========================================================================

snowfall:

	rep	#30h
	sep	#20h
	
				; start of General DMA graphics copy routine!
	lda	#DMAP_XFER_MODE_1
	sta	REG_DMAP7	; 1= 1 word per register
	lda	#<REG_VMDATA
	sta	REG_BBAD7	; 2118   this is 2118 (VRAM)

	rep	#30h
	lda	pointertimer
	asl a
	tay

	ldx	plane2offsetaddress,y
	stx	REG_A1T7L	; get address and bank of offsets

	ldx	pointertimer
	sep	#20h

	lda	plane2offsetbank,x
	sta	REG_A1B7	; bank address of data in ram
	ldx	#040h
	stx	REG_DAS7L	; # of bytes to be transferred

	rep	#30h
	lda	pointertimer
	asl a
	tay
	sep	#20h

	ldx	plane3vramaddress,y
	stx	REG_VMADDL

	lda	#80h		; turn on bit 7 (%10000000=$80) of G-DMA channel
	sta	REG_MDMAEN

	ldx	pointertimer
	lda	plane3address,x
	sta	REG_BG3SC

	rep	#30h
	ldx	#0000h
	txy
makesnowfall1:
	lda	PLANE2_OFFSET1,x
	dec a
	and	#00ffh
	ora	#0c000h
	sta	PLANE2_OFFSET1,x

	lda	PLANE2_OFFSET2,x
	dec a
	sec
	sbc	pointertimer
	and	#00ffh
	ora	#0c000h
	sta	PLANE2_OFFSET2,x

	lda	PLANE2_OFFSET1+2,x
	dec a
	dec a
	and	#00ffh
	ora	#0c000h
	sta	PLANE2_OFFSET1+2,x

	lda	PLANE2_OFFSET2+2,x
	sec
	sbc	pointertimer		; move every other frame!
	and	#00ffh
	ora	#0c000h
	sta	PLANE2_OFFSET2+2,x

	inx
	inx
	inx
	inx
	iny
	cpy	#0010h
	bne	makesnowfall1

	sep	#20h

	rts
	

;==========================================================================
;                     Street Fighter Animation Routine
;==========================================================================

chunkenanimation:
	rep	#30h
	sep	#20h
				; start of General DMA graphics copy routine!
	lda	#01h
	sta	REG_DMAP7	; 1= 1 word per register
	lda	#<REG_VMDATA
	sta	REG_BBAD7	; 2118   this is 2118 (VRAM)

	rep	#30h
	lda	chunkenanim	
	asl a
	tax

	lda	chunkenaddress,x
	sta	REG_A1T7L	; get address and bank of tiles

	lda	chunkenanim
	tax
	sep	#20h

	lda	chunkenbank,x
	sta	REG_A1B7	; bank address of data in ram
	ldx	#0300h
	stx	REG_DAS7L	; # of bytes to be transferred

	ldx	#4640h
	stx	REG_VMADDL

	lda	#80h		; turn on bit 7 (%10000000=$80) of G-DMA channel
	sta	REG_MDMAEN

	inc	chunkentimer
	lda	chunkentimer
	cmp	#07h
	beq	incchunkenanim
	
	rts

incchunkenanim:
	stz	chunkentimer

	lda	chunkenanim
	inc a
	and	#03h
	sta	chunkenanim

	rts


;=========================================================================
;                         Turtle Animation Routine
;=========================================================================

Turtle:
	rep	#30h

	lda	turthpos
	dec a				; move turtle left
	dec a
	sta	turthpos
	cmp	#0ffeeh			; allow to go all the way left
	bne	noturtposreset
	lda	#00feh			; in case it goes too far left
	sta	turthpos		; set it back to the right
	
noturtposreset:
	sep	#20h

	lda	turthpos+1		; let's fix the Most Significant Bit
	and	#80h			; so he won't pop off the screen
	asl a				; when he goes past H pos $0000
	rol a
					; get Most Significant Bit ($80) and
					; shift left to get the Carry bit
					; then rotate left to put the carry
					; bit to the Least Significant Bit ($1)
	
	sta	xstorage1		; store it

	ldx	#0203h			; get offset for OAM size and MSB bit
	lda	oam,x			; data
	and	#%11111110		; mask out the other sprite's info
	ora	xstorage1		; put in our LSB instead
	sta	oam,x			; save it!

	asl 	xstorage1		; shift it left twice so we can write
	asl 	xstorage1		; the LSB to the net sprite

	lda	oam,x
	and	#%11111011		; mask out the other sprite's info
	ora	xstorage1		; put in our LSB and save it
	sta	oam,x

	ldx	#0030h			; get sprite # offset
	lda	turthpos		; sprites need 4 bytes of data
	sta	oam,x			; so to figure out this sprite's #
					; you just divide by 4 ($30/4=$c)
	ldx	#0034h	
	sta	oam,x			; let's save the Turtle's H pos
					; for both sprites
turtnomove:
	lda	turttimer
	inc a
	and	#07h			; this is the animation frame timer
	sta	turttimer		; the Turtle will only animate
	bne	Turtleend		; every 8th vertical blank

	lda	turtanim
	eor	#01h			; the Turtle only has 2 frames of
	sta	turtanim		; animation.. we only need one bit
					; for the offset (1 bit=2 numbers!)

	ldy	#0030h			; sprite # offset ($30/4=$c)
					; $c*4=$30!
	ldx	turtanim		; get frame offset
	lda	turtframe1,x		; read frame #
	sta	oam+2,y			; store the info in OAM

	ldy	#0034h			; get the next sprite (bottom of Turtle)

	lda	turtframe2,x		; get the frame #
	sta	oam+2,y			; store it in OAM

Turtleend:
	rts				; the end of Turtle Routine


;=========================================================================
;                         Turtleshell Animation Routine
;=========================================================================

Turtleshell:
	rep	#30h

	lda	Turtshellhpos
	dec a				; move Turtleshell left
	dec a
	sta	Turtshellhpos
	cmp	#0ffeeh			; allow to go all the way left
	bne	noTurtshellposreset
	lda	#00feh			; in case it goes too far left
	sta	Turtshellhpos		; set it back to the right
	
noTurtshellposreset:

	sep	#20h

	lda	Turtshellhpos+1		; let's fix the Most Significant Bit
	and	#80h			; so he won't pop off the screen
	asl a				; when he goes past H pos $0000
	rol a
					; get Most Significant Bit ($80) and
					; shift left to get the Carry bit
					; then rotate left to put the carry
					; bit to the Least Significant Bit ($1)
	
	sta	xstorage1		; store it

	asl	xstorage1
	asl	xstorage1		; move it to get to the correct
	asl	xstorage1		; MSB pos
	asl	xstorage1

	ldx	#0203h			; get offset for OAM size and MSB bit
	lda	oam,x			; data
	and	#%11101111		; mask out the other sprite's info
	ora	xstorage1		; put in our LSB instead
	sta	oam,x			; save it!

	ldx	#0038h			; get sprite # offset
	lda	Turtshellhpos		; sprites need 4 bytes of data
	sta	oam,x			; so to figure out this sprite's #

Turtshellnomove:
	lda	Turtshelltimer
	inc a
	and	#03h			; this is the animation frame timer
	sta	Turtshelltimer		; the Turtleshell will only animate
	bne	Turtleshellend		; every 4th vertical blank

	lda	Turtshellanim
	inc a
	cmp	#04h
	bne	Turtshellanimnoreset
	lda	#00h			; reset if past three frames
Turtshellanimnoreset:
					; the Turtleshell has 4 frames of
	sta	Turtshellanim		; animation..but only 3 images
	ldy	#0038h			; sprite # offset ($38/4=$e)
					; $e*4=$38!
	ldx	Turtshellanim		; get frame offset
	lda	Turtshellframe1,x	; read frame #
	sta	oam+2,y			; store the info in OAM
	lda	Turtshellframe2,x
	sta	oam+3,y

Turtleshellend:
	rts				; the end of Turtleshell Routine

;=========================================================================
;                      Plane 1 HDMA swing left/right
;=========================================================================

Plane1hHDMA:
	sep	#20h
	inc	sineoffset		; increase sine offset ($00 - $ff)

	rep	#30h
	lda	sineoffset		; get sine offset
	asl a				; multiply by 2 to read sine data
					; stored as words
	tax
	lda	SINE,x			; read sine data in another bank
	sta	xstorage1		; bottom h pos offset
	stz	xstorage2		; clear xstorage2 (becomes remainder)

					; top line's position is always $0	
					; bottom line's position goes
					; in accordance with sine data

					; to calculate the slope for the
					; other lines we divide the
					; bottom's h position by
					; the bottom line v position
					; (which line it's located)
					; the bottom line v pos is 128
					; so this is the calculaton we need:
					; bottomHpos/bottomVpos = slope value

					; what's important to know is that
					; we need the remainder to create
					; a smooth slope

	lda	xstorage1		; get the bottom line's H pos

	lsr a				; divide by 128 and get remainder
	ror	xstorage2		; 
	lsr a				; quotient
	ror	xstorage2		; remainder
	lsr a				; 
	ror	xstorage2		;
	lsr a				; we shift the accumulator right
	ror	xstorage2		; and send the carried bit to the
	lsr a				; remainder through ROR
	ror	xstorage2		; quotient remainder
	lsr a				; 01010101 01000000
	ror	xstorage2		;  after division by 2 (shift to right)
	lsr a				; 00101010 10100000
	ror	xstorage2		;

					; after getting to many strange
					; effects while using the SNES'
					; built in division I resorted to
					; using a fool proof method:
					; my own code!

	sta	xstorage1		; store the quotient

	stz	xstorage3		; counter
	
	stz	xstorage4		; decimal counter

	ldx	#0000h
	ldy	#0080h			; # of lines = 128
hposdrawloop2:
	inx			; skip first byte of HDMA list

	lda	xstorage3	; store counter (H pos offset) in HDMA list
	sta	$7e9803,x
	
	inx			; jump over the 2 bytes of HDMA list to get
	inx			; to the next line of the list

	lda	xstorage4	; get decimal counter
	clc
	adc	xstorage2	; add the remainder of the division
	sta	xstorage4	; store it back into the decimal counter
	bcc	nohposadd2	; if the carry bit is set (the addition value
	inc	xstorage3	; becomes more than $ffff) then increase
				; Whole number counter by one
nohposadd2:
	lda	xstorage3	; get whole number counter 
	clc
	adc	xstorage1	; add qoutient
	sta	xstorage3	; store it into the whole number counter again

	dey			; decrease # of lines left to draw
	bne	hposdrawloop2	; if it's not 0, then do the whole thing again!
	sep	#20h
	rts

;=========================================================================
;                     Baby Uni-Cycle Animation Routine
;=========================================================================

babyuni:
	lda	pointertimer		; since the animation only runs
	beq	babyend			; every other vertical blank
					; we can use the pointer's timer!

	ldy	#002ch			; sprite #'s data offset
	ldx	babyunioffset		; get the baby unicycle's offset
	lda	babyuniframe,x		; read the frame #
	sta	oam+2,y			; store it in OAM list
	
	inc	babyunioffset		; increase frame offset
	lda	babyunioffset
	cmp	#14h			; is it past $14?
	bne	babyend
	stz	babyunioffset		; if so, then set it to 0
babyend:
	rts


;=========================================================================
;                              Pointer Routine
;=========================================================================

pointer:
	rep	#30h

	lda	pointHV			; get pointer's H and V pos
	sta	oam			; H is the low byte, V is the high

	lda	pointertimer		; 
	eor	#01h			; timer only needs to know odd
	sta	pointertimer		; and even intervals (this makes it
	beq	pointerend		; every other frame!)

	lda	pointeroffset		; get pointer's frame offset
	inc a
	and	#000fh			; increase it and allow only 16 frames
	sta	pointeroffset		; store it
	asl a				; multiply by 2 to get offset stored
	tax				; as words
	lda	pointerframes,x
	ora	#3000h			; set the priority bits (sprites
	sta	oam+2			; will get higher priority)

pointerend:
	sep	#20h
	rts

;===========================================================================
;                        Start Of Joypad Routine
;===========================================================================

Joypad:
	lda	REG_HVBJOY	; test if it's ok to read pad
	and	#01h
	bne	Joypad		; nope, go back!

	rep	#30h

	lda	REG_JOY1L	; read Controller 1
	sta	joydata		; store data

	sep	#20h
	lda	joydata+1
	bit	#01h
	bne	movepointright1	; did the controller move right?
	bit	#02h
	bne	movepointleft1	; did the controller move left?

testjoy2:
	sep	#20h
	lda	joydata+1
	bit	#04h
	bne 	movepointdown1	; did the controller move down?
	bit	#08h
	bne	movepointup1	; did the controller move up?
	rts	

movepointright1:
	jsr	movepointright2	; go to the right routine
	jmp	testjoy2	; go back and check up/down
movepointleft1:
	jsr	movepointleft2	; go to the left routine
	jmp	testjoy2	; go back and check up/down
movepointdown1:
	jmp	movepointdown2	; go to the down routine
movepointup1:
	jmp	movepointup2	; go to the up routine

movepointright2:
	rep	#30h
	lda	pointHV
	and	#00ffh		; get only Horiz pos
	cmp	#00deh		; this is the right most limit
	bne	okmovepointright2
	sep	#20h
	rts

okmovepointright2:
	rep	#30h
	lda	pointHV
	and	#0ff00h
	sta	xstorage1

	lda	pointHV
	inc a			; increase H pos by two (move right two dots)
	inc a
	and	#00ffh
	ora	xstorage1

	sta	pointHV
	sep	#20h
	rts

movepointleft2:
	rep	#30h
	lda	pointHV
	and	#00ffh		; get only Horiz pos
	cmp	#0000h
	bne	okmovepointleft2
	sep	#20h
	rts

okmovepointleft2:
	rep	#30h
	lda	pointHV
	and	#0ff00h
	sta	xstorage1

	lda	pointHV
	dec a			; move left two dots
	dec a
	and	#00ffh
	ora	xstorage1

	sta	pointHV
	sep	#20h
	rts
movepointdown2:
	rep	#30h
	lda	pointHV
	and	#0ff00h		; get only vert pos
	cmp	#0c000h
	bne	okmovepointdown2
	sep	#20h
	rts

okmovepointdown2:
	rep	#30h

	lda	pointHV
	and	#00ffh
	sta	xstorage1

	lda	pointHV
	xba
	inc a			; move down two lines
	inc a
	and	#00ffh
	xba
	ora	xstorage1

	sta	pointHV
	sep	#20h
	rts
movepointup2:
	rep	#30h
	lda	pointHV
	and	#0ff00h		; get only vert pos
	cmp	#9000h
	bne	okmovepointup2

	sep	#20h
	rts

okmovepointup2:
	rep	#30h
	lda	pointHV
	and	#00ffh
	sta	xstorage1

	lda	pointHV
	xba
	dec a			; move up two lines
	dec a
	and	#00ffh
	xba
	ora	xstorage1

	sta	pointHV
	sep	#20h
	rts

;==========================================================================
;                              Joy Button Routine
;==========================================================================

joybutton:
	rep	#30h
	lda	joydata
	and	#0c0c0h		; check if a,b,x,y was pressed
	bne	buttonabxy
	sep	#20h
	rts

buttonabxy:
	sep	#20h

	lda	pointHV+1		; pointer's vertical possition
	clc
	adc	#10h			; add 16 to center it 

	cmp	#0b0h			; is it higher than the numbers?
	bcc	collisionfailed
	cmp	#00c0h			; is it lower?
	bcs	collisionfailed

	sep	#20h
	lda	pointHV			; get pointer's horizontal position
	clc
	adc	#17h			; add $17 to get right most of point
	lsr a
	lsr a		            	; divide by 8 to get tile column pos
	lsr a				; it's easier to check for 32 bytes
	sta	xstorage1		; than 256 bits!

	ldx	#0000h
findselection:
	lda	musicnumber,x		; check numbers column position
	cmp	xstorage1		; with pointer's column position
	beq	selectionfound
	lda	xstorage1
	inc a				; since the #s are 16*16 we should
	cmp	musicnumber,x		; check for 2 positions...
	beq	selectionfound		; this will check for the left most
	inx
	cpx	#0009h			; keep checking until it hits a 
	bne	findselection		; number, or goes past too many numbers

collisionfailed:
	rts				; nothing interesting happened..

selectionfound:
	phx
	ldx	#0
	ldy	#8
	jsr	spcFadeModuleVolume
	jsr	spcProcess
	plx

	stx	xstorage1		; store the offset of the column pos

	lda	musicnumber,x		; get the column pos
	asl a
	asl a		; * 8		; multiply by 8 to get sprite pos
	asl a
	
	ldx	#0028h
	sta	oam,x			; store highlight box H pos!

	ldx	#002ch
	sta	oam,x			; store baby uni-cycle h pos!

	rep	#30h

	lda	xstorage1		;music number offset = song #!
	and	#00ffh
	asl a
	tay
	ldx	music,y

	sep	#20h

spcl:	jsr	spcLoad

	ldx	#0
	jsr	spcPlay

	ldx	#127
	jsr	spcSetModuleVolume

	jsr	spcFlush

	rts


;==========================================================================
;                        Vertical Blank Wait Routine
;==========================================================================

WaitVb:	lda	REG_RDNMI
	bpl     WaitVb	; is the number higher than #$7f? (#$80-$ff)
			; bpl tests bit #7 ($80) if this bit is set it means
			; the byte is negative (BMI, Branch on Minus)
			; BPL (Branch on Plus) if bit #7 is set in REG_RDNMI
			; it means that it is at the start of V-Blank
			; if not it will keep testing REG_RDNMI until bit #7
			; is on (which would make it a negative (BMI)
WaitVb2:
	lda	REG_RDNMI
	bmi	WaitVb2
	rts

;==========================================================================
;       	     SETUP ROUTINES FOR PROGRAM
;==========================================================================

;==========================================================================
;                         Copy graf-x data
;==========================================================================

Copy_Gfx:

	rep	#30h

	ldx	#0000h
	stx	REG_VMADDL	; gfx for background at $0000
copylogo:
	lda	logogfx,x	;  load up the GFX from $logogfx
	sta	REG_VMDATAL	;  read from another bank
	inx
	inx
	cpx	#8544
	bne	copylogo

	ldx	#SPRGFX/2
	stx	REG_VMADDL
	ldx	#0000h
copySPRITE_GFX:
	lda	f:SPRITE_GFX,x	; read sprite gfx from another bank
	sta	REG_VMDATAL
	inx
	inx
	cpx	#4000h
	bne	copySPRITE_GFX

	ldx	#BG2GFX/2
	stx	REG_VMADDL
	ldx	#0000h
copystreet:
	lda	f:STREET_GFX,x
	sta	REG_VMDATAL
	inx
	inx
	cpx	#6336
	bne	copystreet

	sep	#20h
	rts

;==========================================================================
;                      Make Tiles
;==========================================================================

Make_tiles:
	rep	#30h
	ldx	#BG1MAP
	stx	REG_VMADDL

	ldx	#0000h
copytiles1:
	lda	logotiles,x	; read tiles from another bank
	sta	REG_VMDATAL
	inx
	inx
	cpx	#0200h
	bne	copytiles1

copytiles2:
	lda	logotiles,x	; read tiles again from another bank
	ora	#0400h		; make these tiles use the green palette
	sta	REG_VMDATAL
	inx
	inx
	cpx	#03c0h
	bne	copytiles2

	ldx	#BG2MAP+240h		; screen at $4400
	stx	REG_VMADDL

	ldx	#0000h
	stx	xstorage1
copystreettiles:
	ldy	xstorage1
	lda	STREET_ANIM1,x
	sta	REG_VMDATAL

	lda	xstorage1
	inc a
	inc a
	and	#3fh
	sta	xstorage1

	inx
	inx
	cpx	#0300h
	bne	copystreettiles

	ldx	#BG2MAP+400h
	stx	REG_VMADDL
	ldx	#0000h
copysnowtiles:
	lda	snowtiles,x
	sta	REG_VMDATAL
	inx
	inx
	cpx	#0800h
	bne	copysnowtiles

	ldx	#BG3MAP
	stx	REG_VMADDL
	ldx	#0000h
	lda	#4080h
shiftflakes:
	sta	REG_VMDATAL
	inx
	cpx	#0020h
	bne	shiftflakes	

	sep	#20h
	rts


;==========================================================================
;                         HDMA Setup Routine
;==========================================================================

HDMA:
	ldx	#0000h
	txy
	lda	#00h
plane1hsetup:
	ina
	sta	PLANE1_OFFSET,x	; set up plane 1 H pos HDMA
	dea
	inx
	sta	PLANE1_OFFSET,x
	inx
	sta	PLANE1_OFFSET,x
	inx
	iny
	cpy	#00ffh
	bne	plane1hsetup

	sta	PLANE1_OFFSET,x
	sta	PLANE1_OFFSET+01h,x
	sta	PLANE1_OFFSET+02h,x

	jsr	Plane1hHDMA	; draw first lines
	
	stz	REG_DMAP0	; 0= 1 byte per register (not a word!)
	lda	#<REG_CGADD
	sta	REG_BBAD0	; 21xx   this is 2121 (color palette)
	ldx	#LIST_CGADD	; the address of where it's located
	stx	REG_A1T0L
	stz	REG_A1B0	; bank address of data in ram

	lda	#DMAP_XFER_MODE_2; write twice
	sta	REG_DMAP1
	sta	REG_DMAP2
	lda	#<REG_CGDATA	; color register
	sta	REG_BBAD1
	ldx	#LIST_CGDATA	; address where the list is located
	stx	REG_A1T1L
	stz	REG_A1B1

	lda	#<REG_BG1HOFS	; $210d, plane 1 H pos offset
	sta	REG_BBAD2
	ldx	#PLANE1_OFFSET
	stx	REG_A1T2L
	lda	#^PLANE1_OFFSET
	sta	REG_A1B2

	stz	REG_DMAP3
	lda	#<REG_BGMODE	; $2105, screen mode, tile size.. etc
	sta	REG_BBAD3
	ldx	#LIST_BGMODE
	stx	REG_A1T3L
	stz	REG_A1B3

	stz	REG_DMAP4
	lda	#<REG_BG2SC
	sta	REG_BBAD4	; $2108 (plane 2 tile location)
	ldx	#LIST_PLANE2
	stx	REG_A1T4L
	stz	REG_A1B4

	stz	REG_DMAP5
	lda	#<REG_BG12NBA
	sta	REG_BBAD5	; $210b (plane 1&2 gfx location)
	ldx	#LIST_BG12NBA
	stx	REG_A1T5L
	stz	REG_A1B5

	jsr	WaitVb
	lda	#%111111
	sta	REG_HDMAEN
	rts


;==========================================================================
;                              Sprite Setup Routine
;==========================================================================

Sprite_setup:
	ldx	#0000h
	txy
sprtclear:
	stz	oam,x		; H pos
	inx
	lda	#0e0h
	sta	oam,x		; V pos
	inx
	stz	oam,x		; object
	inx
	stz	oam,x		;priority
	inx
	iny
	cpy	#0080h
	bne	sprtclear
	ldx	#0000h
sprtdataclear:
	stz	oam,x
	inx
	stz	oam,x
	inx
	cpx	#0020h
	bne	sprtdataclear

	ldx	#200h


	lda	#%00000010
	sta	oam,x



	lda	#50h
	sta	oam
	sta	oam+1
	lda	#08h
	sta	oam+2		; pointer's sprite info
	lda	#31h
	sta	oam+3

	ldx	#0000h
	txy	

	lda	#18h
	sta	xstorage1

copynumbersprites:
	lda	xstorage1
	sta	oam+4,x
	lda	#0b0h
	sta	oam+5,x
	
	lda	numbers1,y	; song # sprites 1-9
	sta	oam+6,x
	lda	#33h
	sta	oam+7,x

	lda	xstorage1
	clc
	adc	#18h
	sta	xstorage1

	inx
	inx
	inx
	inx
	iny
	cpy	#0009h
	bne	copynumbersprites

	ldx	#0028h
	lda	#18h
	sta	oam,x
	lda	#0b0h
	sta	oam+1,x
	lda	#64h		; selected song # highlight box
	sta	oam+2,x
	lda	#31h
	sta	oam+3,x



	ldx	#002ch
	lda	#18h
	sta	oam,x
	lda	#0a0h
	sta	oam+1,x
	lda	#66h		; selected song # baby uni sprite data
	sta	oam+2,x
	lda	#31h
	sta	oam+3,x


	ldx	#30h
	lda	#80h
	sta	oam,x
	lda	#68h
	sta	oam+1,x
	lda	#02h		; top of Turtle
	sta	oam+2,x
	lda	#34h
	sta	oam+3,x

	ldx	#34h
	lda	#80h
	sta	oam,x
	lda	#78h
	sta	oam+1,x		; bottom of Turtle
	lda	#22h
	sta	oam+2,x
	lda	#34h
	sta	oam+3,x


	ldx	#38h
	lda	#0a0h
	sta	oam,x
	lda	#78h
	sta	oam+1,x
	lda	#06h		; Turtle Shell
	sta	oam+2,x
	lda	#34h
	sta	oam+3,x




	rts


.code


LIST_BG12NBA:
	.byte	$40,0,$40,0
	.byte	1,$32,0,0

LIST_BGMODE:
	.byte	$40,2,$40,2
	.byte	1,1,0,0

LIST_PLANE2:
	.byte	$40,$48,$40,$48
	.byte	1,$44,0,0


LIST_CGADD:
	.byte	$40,0,$40,0
	.byte	1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0
	.byte	1,0,1,0,1,0,1,0,1,0,1,0
	.byte	0,0

LIST_CGDATA:
	.byte	$40
	.word	$0000
	.byte	$40
	.word	$0000
	.byte	1
	.word	$0421
	.byte	1
	.word	$0842
	.byte	1
	.word	$0C63
	.byte	1
	.word	$1084
	.byte	1
	.word	$14A5
	.byte	1
	.word	$18C6
	.byte	1
	.word	$1CE7
	.byte	1
	.word	$2108
	.byte	1
	.word	$2529
	.byte	1
	.word	$294A
	.byte	1
	.word	$2D6B
	.byte	1
	.word	$318C
	.byte	0
	.word	0 

babyuniframe:
	.byte	$66,$68,$6a,$6c,$6e,$80,$82,$84,$86,$88,$8a
	.byte	$88,$86,$84,$82,$80,$6e,$6c,$6a,$68

musicnumber:
	.byte	3,6,9,$c,$f,$12,$15,$18,$1b	; column position..

music:	.word	MOD_BIONIC,  MOD_COMMODOR,MOD_DAISYCHA,MOD_EINSTEIN
	.word	MOD_GARYANDD,MOD_PCHIPINT,MOD_STEPBYST,MOD_SUNSETPA
	.word	MOD_YUMMYGAP

plane3vramaddress:
	.word	$4c20,$4420
plane2offsetaddress:
	.word	PLANE2_OFFSET1,PLANE2_OFFSET2

turtframe1:
	.byte	2,4

turtframe2:
	.byte	$22,$24

numbers1:
	.byte	$42,$44,$46,$48,$4a,$4c,$4e,$60,$62


pointerframes:
	.word	$40,$44,$48,$4c
	.word	$80,$84,$88,$8c
	.word	$c0,$c4,$c8,$cc
	.word	$100,$104,$108,$10c

Turtshellframe1:	.byte	$a,$6,$8,$6
Turtshellframe2:	.byte	$34,$34,$34,$74
plane3address:		.byte	$4c,$44
plane2offsetbank:	.byte	^PLANE2_OFFSET1,^PLANE2_OFFSET1

chunkenaddress:
        .word   .LOWORD(STREET_ANIM1),.LOWORD(STREET_ANIM2),.LOWORD(STREET_ANIM3),.LOWORD(STREET_ANIM2)
chunkenbank:
        .byte   ^STREET_ANIM1,^STREET_ANIM2,^STREET_ANIM3,^STREET_ANIM2

Colors:	; BG colors
	.incbin	"../dist/xmas1.col"
	.incbin	"../dist/xmas2.col"
	.incbin	"../dist/street1.col"
	.incbin	"../dist/street2.col"

	; snow colors
	.word	$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	.word	$0000,$0000,$0000,$0000,$7fff,$0000,$4210,$0000 

	;sprite colors
Sprcol:	.incbin	"../dist/unipoint.col"
	.incbin	"../dist/unifont.col"
	.incbin	"../dist/turt.col"
	
logogfx:
	.incbin	"../dist/xmas1.gfx"

logotiles:
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2005,$2006,$2007,$2008,$2009
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$200A,$200B,$200C,$200D,$200E
	.word	$2000,$200F,$2010,$2011,$2012,$2000,$2013,$2014
	.word	$2015,$2016,$2017,$2000,$2018,$2019,$201A,$201B
	.word	$201C,$201D,$201E,$2000,$201F,$2020,$2000,$2000
	.word	$2000,$2000,$2021,$2022,$2023,$2024,$2025,$2026
	.word	$2027,$2028,$2029,$202A,$202B,$202C,$202D,$202E
	.word	$202F,$2030,$2031,$2032,$2033,$2034,$2035,$2036
	.word	$2037,$2038,$2039,$203A,$203B,$203C,$2000,$2000
	.word	$2000,$2000,$203D,$203E,$203F,$2040,$2041,$2042
	.word	$2043,$2044,$2045,$2046,$2047,$2048,$2049,$204A
	.word	$204B,$204C,$204D,$204E,$204F,$2050,$2051,$2052
	.word	$2000,$2053,$2054,$2055,$2056,$2000,$2000,$2000
	.word	$2000,$2000,$2057,$2058,$2059,$2000,$205A,$205B
	.word	$205C,$205D,$205E,$205F,$2060,$2061,$2062,$2063
	.word	$2000,$2000,$2000,$2064,$2065,$2000,$2000,$2000
	.word	$2000,$2066,$2067,$2068,$2069,$2000,$2000,$2000
	.word	$2000,$2000,$206A,$206B,$2000,$2000,$206C,$206D
	.word	$206E,$206F,$2070,$2071,$2072,$2073,$2074,$2075
	.word	$2000,$2000,$2000,$2076,$2077,$2000,$2000,$2000
	.word	$2078,$2079,$207A,$207B,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$207C,$207D,$207E,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$207F,$2080,$2081,$2082,$2083
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2084,$2085
	.word	$2086,$2087,$2088,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2089,$208A,$208B,$208C,$208D
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$208E,$208F
	.word	$2090,$2091,$2092,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2093,$2094,$2095,$2096,$2000
	.word	$2097,$2098,$2099,$209A,$209B,$209C,$209D,$209E
	.word	$209F,$20A0,$20A1,$20A2,$20A3,$20A4,$20A5,$20A6
	.word	$2000,$20A7,$20A8,$20A9,$20AA,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$20AB,$20AC,$20AD,$2000
	.word	$20AE,$20AF,$20B0,$20B1,$20B2,$20B3,$20B4,$20B5
	.word	$20B6,$20B7,$20B8,$20B9,$20BA,$20BB,$20BC,$20BD
	.word	$20BE,$20BF,$20C0,$20C1,$20C2,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$20C3,$20C4,$20C5,$20C6,$20C7
	.word	$20C8,$20C9,$20CA,$20CB,$20CC,$20CD,$20CE,$20CF
	.word	$20D0,$20D1,$20D2,$20D3,$20D4,$20D5,$20D6,$20D7
	.word	$20D8,$20D9,$20DA,$20DB,$20DC,$201E,$2000,$2000
	.word	$2000,$2000,$20DD,$20DE,$20DF,$20E0,$20E1,$20E2
	.word	$20E3,$2000,$2000,$2000,$2000,$20E4,$20E5,$20E6
	.word	$20E7,$20E8,$20E9,$20EA,$20EB,$20EC,$20ED,$20EE
	.word	$20EF,$20F0,$20F1,$20F2,$20F3,$20F4,$2000,$2000
	.word	$2000,$2000,$20F5,$20F6,$20F7,$20F8,$20F9,$20FA
	.word	$20FB,$2000,$2000,$2000,$2000,$20FC,$20FD,$2000
	.word	$20FE,$20FF,$2100,$2101,$2102,$2103,$2104,$2105
	.word	$2106,$2107,$2108,$2109,$210A,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
	.word	$2000,$2000,$2000,$2000,$2000,$2000,$2000,$2000
 
snowtiles:
	.word	$3000,$3001,$3000,$3000,$3000,$3000,$3003,$3000
	.word	$3000,$3000,$3004,$3000,$3000,$3000,$3002,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3001,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3003
	.word	$3000,$3000,$3000,$3000,$3000,$3002,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3003,$3000
	.word	$3000,$3000,$3004,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3001,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3001,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3004,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3002
	.word	$3000,$3000,$3004,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3004,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3004,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3003,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3004,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3002,$3000,$3000,$3000,$3000,$3003,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3001
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3003,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3003,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3002,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3004,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3003,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3004,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3001,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3002,$3000,$3000,$3004
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3004,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3001,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3003,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3002,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3004
	.word	$3000,$3000,$3000,$3002,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3001,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3004,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3004,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3003
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3001,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3004,$3000,$3000,$3001,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3004,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3003,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3002,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3003,$3000
	.word	$3000,$3003,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3003,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3003,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3003,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3004,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3004,$3000,$3000
	.word	$3000,$3001,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3001,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3001,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3001,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3002,$3000,$3000,$3000
	.word	$3004,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3004,$3000
	.word	$3000,$3000,$3003,$3000,$3000,$3000,$3000,$3000
	.word	$3003,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3004,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3002,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3000,$3000,$3000,$3000
	.word	$3000,$3000,$3000,$3000,$3001,$3000,$3000,$3000
	.word	$3000,$3001,$3000,$3000,$3003,$3000,$3000,$3001
	.word	$3000,$3000,$3003,$3000,$3000,$3002,$3000,$3000

SINE:
 .word  -1,6,12,18,25,31,37,43,49,55,62,68,74,80,86,91,97,103,109,114
 .word  120,125,131,136,141,147,152,157,162,166,171,176,180,185,189
 .word  193,197,201,205,208,212,215,219,222,225,228,230,233,236,238
 .word  240,242,244,246,247,249,250,251,252,253,254,254,255,255,255
 .word  255,255,254,254,253,252,251,250,249,247,246,244,242,240,238
 .word  236,233,230,228,225,222,219,215,212,208,205,201,197,193,189
 .word  185,180,176,171,166,162,157,152,147,141,136,131,125,120,114
 .word  109,103,97,91,86,80,74,68,62,55,49,43,37,31,25,18,12,6,-1,-7
 .word  -13,-19,-26,-32,-38,-44,-50,-56,-63,-69,-75,-81,-87,-92,-98
 .word  -104,-110,-115,-121,-126,-132,-137,-142,-148,-153,-158,-163
 .word  -167,-172,-177,-181,-186,-190,-194,-198,-202,-206,-209,-213
 .word  -216,-220,-223,-226,-229,-231,-234,-237,-239,-241,-243,-245
 .word  -247,-248,-250,-251,-252,-253,-254,-255,-255,-256,-256,-256
 .word  -256,-256,-255,-255,-254,-253,-252,-251,-250,-248,-247,-245
 .word  -243,-241,-239,-237,-234,-231,-229,-226,-223,-220,-216,-213
 .word  -209,-206,-202,-198,-194,-190,-186,-181,-177,-172,-167,-163
 .word  -158,-153,-148,-142,-137,-132,-126,-121,-115,-110,-104,-98
 .word  -92,-87,-81,-75,-69,-63,-56,-50,-44,-38,-32,-26,-19,-13,-7

.segment "GRAPHICS"

STREET_GFX:	.incbin	"../dist/street.gfx"

SPRITE_GFX:	.incbin "../dist/unipoint.gfx"

STREET_ANIM1:

	.word	$2800
	.word	$2800,$2800,$2800,$2800,$2801,$2802,$2800,$2800
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00
	.word	$2c50,$2c51,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00
	.word	$2800,$2800,$2800,$2807,$2808,$2809,$2800,$2800
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00
	.word	$2c5A,$2c5B,$2c5C,$2c5D,$2c00,$2c00,$2c00,$2c00
	.word	$2800,$2800,$2800,$280E,$280F,$2810,$2811,$2800
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00
	.word	$2c66,$2c67,$2c68,$2c69,$2c00,$2c00,$2c00,$2c00
	.word	$2800,$2800,$2800,$2819,$281A,$281B,$281C,$2800
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00
	.word	$2c73,$2c74,$2c75,$2c76,$2c00,$2c00,$2c00,$2c00
	.word	$2800,$2800,$2825,$2826,$2827,$2828,$2800,$2800
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00
	.word	$2c80,$2c81,$2c82,$2c83,$2c00,$2c00,$2c00,$2c00
	.word	$2800,$2800,$2831,$2832,$2833,$2834,$2800,$2800
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00
	.word	$2c8C,$2c8D,$2c8E,$2c8F,$2c00,$2c00,$2c00,$2c00
	.word	$2800,$2800,$2836,$2837,$2838,$2839,$283A,$2800
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00
	.word	$2c98,$2c99,$2c9A,$2c9B,$2c00,$2c00,$2c00,$2c00
	.word	$2800,$2800,$283B,$283C,$283D,$283E,$283F,$2800
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2cA6
	.word	$2cA7,$2cA8,$2cA9,$2cAA,$2c00,$2c00,$2c00,$2c00
	.word	$2800,$2800,$2840,$2841,$2842,$2800,$2843,$2800
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2cB5
	.word	$2cB6,$2cB7,$2cB8,$2cB9,$2c00,$2c00,$2c00,$2c00
	.word	$2800,$2800,$2844,$2845,$2800,$2800,$2846,$2847
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2cC2
	.word	$2cC3,$2c00,$2cC4,$2cC5,$2c00,$2c00,$2c00,$2c00
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00

STREET_ANIM2:
	.word	$2800
	.word	$2800,$2800,$2800,$2800,$2803,$2804,$2800,$2800
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00
	.word	$2c4C,$2c4D,$2c4E,$2c4F,$2c00,$2c00,$2c00,$2c00
	.word	$2800,$2800,$2800,$2800,$280A,$280B,$2800,$2800
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00
	.word	$2c56,$2c57,$2c58,$2c59,$2c00,$2c00,$2c00,$2c00
	.word	$2800,$2800,$2800,$2812,$2813,$2814,$2815,$2800
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00
	.word	$2c62,$2c63,$2c64,$2c65,$2c00,$2c00,$2c00,$2c00
	.word	$2800,$2800,$2800,$281D,$281E,$281F,$2820,$2800
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c6E
	.word	$2c6F,$2c70,$2c71,$2c72,$2c00,$2c00,$2c00,$2c00
	.word	$2800,$2800,$2825,$2829,$282A,$282B,$282C,$2800
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c7B
	.word	$2c7C,$2c7D,$2c7E,$2c7F,$2c00,$2c00,$2c00,$2c00
	.word	$2800,$2800,$2831,$2832,$2833,$2834,$2800,$2800
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00
	.word	$2c88,$2c89,$2c8A,$2c8B,$2c00,$2c00,$2c00,$2c00
	.word	$2800,$2800,$2836,$2837,$2838,$2839,$283A,$2800
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00
	.word	$2c94,$2c95,$2c96,$2c97,$2c00,$2c00,$2c00,$2c00
	.word	$2800,$2800,$283B,$283C,$283D,$283E,$283F,$2800
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2cA1
	.word	$2cA2,$2cA3,$2cA4,$2cA5,$2c00,$2c00,$2c00,$2c00
	.word	$2800,$2800,$2840,$2841,$2842,$2800,$2843,$2800
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2cB0
	.word	$2cB1,$2cB2,$2cB3,$2cB4,$2c00,$2c00,$2c00,$2c00
	.word	$2800,$2800,$2844,$2845,$2800,$2800,$2846,$2847
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2cBE
	.word	$2cBF,$2c00,$2cC0,$2cC1,$2c00,$2c00,$2c00,$2c00
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00

STREET_ANIM3:
	.word	$2800
	.word	$2800,$2800,$2800,$2800,$2805,$2806,$2800,$2800
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00
	.word	$2c48,$2c49,$2c4A,$2c4B,$2c00,$2c00,$2c00,$2c00
	.word	$2800,$2800,$2800,$2800,$280C,$280D,$2800,$2800
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00
	.word	$2c52,$2c53,$2c54,$2c55,$2c00,$2c00,$2c00,$2c00
	.word	$2800,$2800,$2800,$2816,$2817,$2818,$2800,$2800
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00
	.word	$2c5E,$2c5F,$2c60,$2c61,$2c00,$2c00,$2c00,$2c00
	.word	$2800,$2800,$2800,$2821,$2822,$2823,$2824,$2800
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00
	.word	$2c6A,$2c6B,$2c6C,$2c6D,$2c00,$2c00,$2c00,$2c00
	.word	$2800,$2800,$2825,$282D,$282E,$282F,$2830,$2800
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00
	.word	$2c77,$2c78,$2c79,$2c7A,$2c00,$2c00,$2c00,$2c00
	.word	$2800,$2800,$2831,$2832,$2835,$2834,$2800,$2800
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00
	.word	$2c84,$2c85,$2c86,$2c87,$2c00,$2c00,$2c00,$2c00
	.word	$2800,$2800,$2836,$2837,$2838,$2839,$283A,$2800
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00
	.word	$2c90,$2c91,$2c92,$2c93,$2c00,$2c00,$2c00,$2c00
	.word	$2800,$2800,$283B,$283C,$283D,$283E,$283F,$2800
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c9C
	.word	$2c9D,$2c9E,$2c9F,$2cA0,$2c00,$2c00,$2c00,$2c00
	.word	$2800,$2800,$2840,$2841,$2842,$2800,$2843,$2800
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2cAB
	.word	$2cAC,$2cAD,$2cAE,$2cAF,$2c00,$2c00,$2c00,$2c00
	.word	$2800,$2800,$2844,$2845,$2800,$2800,$2846,$2847
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2cBA
	.word	$2cBB,$2c00,$2cBC,$2cBD,$2c00,$2c00,$2c00,$2c00
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2800,$2800,$2800,$2800,$2800,$2800,$2800,$2800
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00
	.word	$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00,$2c00
 
