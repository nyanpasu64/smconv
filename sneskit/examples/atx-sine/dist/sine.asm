Sine Dot Intro Source

The following source code was written on an Amiga 4000/040 computer using
CygnusEd (text editor), SASM (snes assembler), IFF2SNES (gfx converter).
This is a horrible piece of code and shows very sloppy work.
The only equates used are by the un-packer (which was hand written and
is a simple sequence unpacker, the packer itself was written in 68000 by
me using ASM-One). 



	heap	O=512k			;max 512k object buffer                
	size	4			;4 32kblocks                          
                                                                                  
	SMC+				;yes, we want a smc header 
	lrom				;yes, please split in 32k hunks       

Crunch		equ	$60
RamCrunch	equ	$63
LengthCrunch	equ	$66
StoreCrunch	equ	$69
Unpackoffset	equ	$6b
EffectCrunch	equ	$6e

;==========================================================================
;      Code (c) 1993-94 -Pan-/ANTHROX   All code can be used at will!
;==========================================================================                     
game:
	lda	#$00
	pha
	plb
	dc.b	$5c,08,$80,00
Start:
	jmp	Start2
		;*********************

	dc.b	"Scroll starts here ->"
scrolltext:
	dc.b	"<><>  -Pan- presents another awesome intro! the 128 sine-dot "
	dc.b	"background effect makes this whole intro totally COOL! "
	dc.b	"           ",0
	dc.b	"                                                          "
	dc.b	"                                                          "
	dc.b	"                                                          "
	dc.b	"                                                          "
	dc.b	"                                                          "
	dc.b	"                                                          "
	dc.b	"                                                          "
	dc.b	"                                                          "
	dc.b	"                                                          "
	dc.b	"                                                          "
	dc.b	"                                                          "
	dc.b	"                                                          "
	dc.b	"                                                          "
	dc.b	"                                                          "
	dc.b	"                     ",0,"<- End of Scroll text         "




Start2:  
	phk			; Put current bank on stack
	plb			; make it current programming bank
				; if this program were used as an intro
				; and it was located at bank $20 then an
				; LDA $8000 would actually read from
				; $008000 if it were not changed!
				; JSRs and JMPs work fine, but LDAs do not! 
	clc			; Clear Carry flag
	xce			; Native 16 bit mode  (no 6502 Emulation!)

;==========================================================================
	lda	#$0f
	sta	$2100
	stz	$212c

	rep	#$30
	sep	#$20
	ldx	#font
	stx	Crunch		; address of Crunched file
	phk
	pla
	;lda	#^font
	sta	Crunch+2	; bank it's in

	ldx	#$0000
	stx	RamCrunch	; unpack ram
	lda	#$7f
	sta	RamCrunch+2	; unpack bank


	ldx	#$2122		; play with color register
	stx	EffectCrunch
	stz	EffectCrunch+2

	
	jsr	unpack
	ldx	#logo
	stx	Crunch		; address of Crunched file
	;lda	#^logo
	phk
	pla
	sta	Crunch+2	; bank it's in

	ldx	#$2000
	stx	RamCrunch	; unpack ram
	lda	#$7f
	sta	RamCrunch+2	; unpack bank


	ldx	#$2122		; play with color register
	stx	EffectCrunch
	stz	EffectCrunch+2

	
	jsr	unpack

	ldx	#credgfx
	stx	Crunch		; address of Crunched file
	;lda	#^credgfx
	phk
	pla
	sta	Crunch+2	; bank it's in

	ldx	#$4000
	stx	RamCrunch	; unpack ram
	lda	#$7f
	sta	RamCrunch+2	; unpack bank


	ldx	#$2122		; play with color register
	stx	EffectCrunch
	stz	EffectCrunch+2

	
	jsr	unpack



	sep #$30   
	jsr	Snes_Init	; Cool Init routine! use it in your own code!!
	rep     #$10		; X,Y fixed -> 16 bit mode
	sep     #$20		; Accumulator ->  8 bit mode
	Lda	#$01		; mode 0, 8/8 dot
	Sta	$2105	

	Lda	#$6c		; BG2 Tile Address $6c00
	Sta	$2109

	lda	#$79
	sta	$2108

	lda	#$71
	sta	$2107		; BG0 tile address $7000
	lda	#$22
	Sta	$210b		; BG0 Graphics data $2000
	lda	#$06
	sta	$210c		; BG2 graphics data $0000

	lda	#$80

	sta	$2110
	stz	$2110


	lda	#$17
	sta	$212c		; enable 3 planes

	LDA	#$33
	STA	$2123
	lda	#$03
	sta	$2134
	LDA	#$00
	STA	$2126
	LDA	#$Ff
	STA	$2127
	LDA	#$13
	STA	$212E
	LDA	#$02
	STA	$2130
	LDA	#$53
	STA	$2131
	LDA	#$00
	STA	$2132
	LDA	#$12
	STA	$212D

	





	jsr	Copy_Gfx	; Put graf-x in vram
	jsr	Copy_colors	; put colors into color ram
	jsr	Make_tiles	; set up the screen
	jsr	Clear_ram	; clear ram "V-Ram" buffer for dot routine
	jsr	Sprite_setup

	ldx	#$0000
	stx	$a2		; x sine offset storage

	ldx	#$0000
	stx	$a4		; y sine offset storage

	ldx	#$0000
	stx	$a6		; number of dots to make storage

	ldx	#$0000
	stx	$a8		; graf-x ram location offset

	ldx	#$0000
	stx	$aa		; X bit offset
	
	ldx	#$0000
	stx	$ac		; sine data location offset
	
	ldx	#$0000
	stx	$ae		; X sine offset

	ldx	#$0000
	stx	$b0		; Y sine offset

	ldx	#$80
	stx	$b2		; # of dots to draw



	ldx	#$0000
	stx	$100b		; generic timer for any use

	ldx	#$0000
	stx	$100d		; generic timer for routine counters

	lda	#$01
	sta	$1010		; sine increase value
	sta	$1011		; x increase
	sta	$1012		; y increase
	lda	#$03
	sta	$1013		; x distance
	lda	#$04
	sta	$1014		; y distance
	
	ldx	#$0000
	stx	$1015		; offset for sine positions


	stx	$1100		; offset for logo1 H
	ldx	#$0045
	stx	$1102		; offset for logo1 V
	ldx	#$0000
	stx	$1104		; offset for logo2 H
	stx	$1106		; offset for logo2 V
	ldx	#$0001
	stx	$1110		; scroll H pos
	ldx	#$0000
	stx	$1112		; scroll text position
	stx	$1114		; sprite H pos offset counter
	stx	$1116		; scroll text ram offset
	stx	$1118		; MSB for first sprite

	stx	$1200
	stx	$1202
	stx	$1204
	stx	$1206


	stx	$111a		; offset for sprite sine
	stx	$111c		; offset for sprite sine
	stx	$111e		; offset for sprite color
	stx	$1120		; storage for offset of color

	stx	$1122		; timer for sprite color

	stx	$1124		; red bars offset
	stx	$1126		; storage

	stx	$1128		; timer for fadein/fadeout
	stx	$112a		; $2100 register

	stx	$112c		; flag to stop intro

	lda	#$00
	sta	$10
	lda	#$80		; this puts #$7e8000 into address $10
	sta	$11		; in zero page
	lda	#$7e		; lda [$10] is equal to lda $7e8000
	sta	$12

	ldx	#SINE
	stx	$13



	ldx	$1015
	lda	SINEPOS1,x
	sta	$1010
	lda	SINEPOS2,x
	sta	$1011
	lda	SINEPOS3,x
	sta	$1012
	lda	SINEPOS4,x
	sta	$1013
	lda	SINEPOS5,x
	sta	$1014

	jsr	HDMA

	

	lda	#$01
	sta	$4200


	ldx	#$0200		; timer for sine values
	stx	$100b	

	ldx	#$000a		; # of sine patterns
	stx	$100d

	lda	#$80
	sta	$1128

	
Wait4:
	jsr	WaitVb
	lda	$112a
	sta	$2100
	and	#$0f
	eor	#$0f
	asl a
	asl a
	asl a
	asl a
	ora	#$07
	sta	$2106
	jsr	Joypad
Wait5:
	jsr	Sprglow		; Make sprite glow from blue<->gold
	jsr	Registers	; write to H/V scroll positions (move logo)
	jsr	Sprscroll	; Copy Sprite Scroll
	jsr	Dotrout		; go do the dot routines
	jsr	Otherrouts	; Other routines

	lda	$112c
	beq	noendintro	; test flag to see if we should end intro

	jmp	CREDS		; jump to end of intro!

noendintro:
	ldx	$100b
	dex
	stx	$100b
	bne	Wait4
	ldx	#$0200
	stx	$100b

	inc	$1015
	ldx	$1015
	lda	SINEPOS1,x
	sta	$1010
	lda	SINEPOS2,x
	sta	$1011
	lda	SINEPOS3,x
	sta	$1012
	lda	SINEPOS4,x
	sta	$1013
	lda	SINEPOS5,x
	sta	$1014

	ldx	$100d
	dex			; decrease routine timer
	stx	$100d
	cpx	#$0000
	bne	Wait4

	ldx	#$000a
	stx	$100d

	ldx	#$0000
	stx	$1015


	
	ldx	#$0000
	stx	$ac		; sine data location offset
	
	ldx	#$0000
	stx	$ae		; X sine offset

	ldx	#$0000
	stx	$b0		; Y sine offset

	ldx	#$80
	stx	$b2		; # of dots to draw




	lda	#$01
	sta	$1010		; sine increase value
	sta	$1011		; x increase
	sta	$1012		; y increase
	lda	#$03
	sta	$1013		; x distance
	lda	#$04
	sta	$1014		; y distance
	
	ldx	#$0000
	stx	$1015		; offset for sine positions





	ldx	$1015
	lda	SINEPOS1,x
	sta	$1010
	lda	SINEPOS2,x
	sta	$1011
	lda	SINEPOS3,x
	sta	$1012
	lda	SINEPOS4,x
	sta	$1013
	lda	SINEPOS5,x
	sta	$1014



	jmp	Wait4

;===========================================================================
;                              Start Of Routines
;===========================================================================



Registers:
	rep	#$30
	lda	$1200
	sec
	sbc	#$80
	sep	#$20
	sta	$210d
	xba
	sta	$210d
	
	rep	#$30
	lda	$1202
	sec
	sbc	#$80
	sep	#$20
	sta	$210e
	xba
	sta	$210e



	rep	#$30
	lda	$1204
	sec
	sbc	#$80
	sep	#$20
	sta	$210f
	xba
	sta	$210f

	rep	#$30
	lda	$1206
	sec
	sbc	#$80
	sep	#$20
	sta	$2110
	xba
	sta	$2110

	rts

;===========================================================================
;                       Start of sprite color glow
;===========================================================================
Sprglow:
	lda	#$00
	sta	$4330		; 0= 1 byte per register (not a word!)
	lda	#$22
	sta	$4331		; 21xx   this is 2118 (VRAM)
	rep	#$30
	lda	#Spritecolglow
	clc
	adc	$1120		; add offset to read color pos.
	tax
	sep	#$20
	stx	$4332
	phk
	pla
	sta	$4334		; bank address of data in ram
	ldx	#$0020
	stx	$4335		; # of bytes to be transferred
	lda	#$80
	sta	$2121		; address of VRAM to copy garphics in
	lda	#$08		; turn on bit 4 (%1000=8) of G-DMA channel
	sta	$420b


	lda	$1122
	dec a
	and	#$0f
	sta	$1122
	bne	endcolor	

	rep	#$30
	lda	$111e
	inc a
	and	#$000f
	sta	$111e
	asl a
	asl a
	asl a
	asl a
	asl a
	sta	$1120
	sep	#$20	
endcolor:

	rts


Spritecolglow:

	;	-100
	dc.w	$0000,$9F03,$9F02,$DA01,$5001,$C800,$8800,$1801
	dc.w	$DF02,$5F02,$DA01,$0E01,$9F02,$DF01,$1F03,$1F03 
 
 
	;	-75

	dc.w	$0000,$9F1B,$9F12,$D609,$4E09,$C600,$8800,$1601
	dc.w	$DF1A,$5C1A,$D611,$0C11,$9F0A,$DF09,$1F13,$1F23 
 
 
	;	-50


	dc.w	$0000,$9F33,$9C22,$D219,$4C11,$C608,$8600,$1209
	dc.w	$DF3A,$5832,$D429,$0A21,$9F1A,$DC09,$1F23,$1F43 
 


	;	-25

	dc.w	$0000,$9F53,$963A,$D029,$4A19,$C410,$8400,$0E09
	dc.w	$DA5A,$544A,$D041,$0831,$9C22,$D811,$1F33,$1F63 
 
 

	; 0 %
	dc.w	$0000,$9A6B,$924A,$CC31,$4821,$C418,$8408,$0C11
	dc.w	$D67E,$5062,$CC51,$0639,$9632,$D219,$1A43,$1C7F 
 
	;+25


	dc.w	$0000,$947F,$8E5A,$CA41,$4629,$C220,$8208,$0811
	dc.w	$D07E,$4C7E,$CA69,$0449,$903A,$CE21,$1453,$167F 
 

	;+50

	dc.w	$0000,$8C7F,$8872,$C651,$4431,$C228,$8208,$0619
	dc.w	$CA7E,$487E,$C67D,$0259,$8A4A,$C829,$0C63,$0E7F 
 
 
	;+75
	dc.w	$0000,$867F,$847E,$C261,$4239,$C030,$8008,$0219
	dc.w	$C47E,$447E,$C27D,$0269,$845A,$C431,$0673,$067F 
 
 
	;+100


	dc.w	$0000,$807F,$807E,$C069,$4041,$C030,$8010,$0021
	dc.w	$C07E,$407E,$C07D,$007D,$8062,$C039,$007F,$007F 
 
 
	;+75
	dc.w	$0000,$867F,$847E,$C261,$4239,$C030,$8008,$0219
	dc.w	$C47E,$447E,$C27D,$0269,$845A,$C431,$0673,$067F 
 
	;+50

	dc.w	$0000,$8C7F,$8872,$C651,$4431,$C228,$8208,$0619
	dc.w	$CA7E,$487E,$C67D,$0259,$8A4A,$C829,$0C63,$0E7F 
	;+25


	dc.w	$0000,$947F,$8E5A,$CA41,$4629,$C220,$8208,$0811
	dc.w	$D07E,$4C7E,$CA69,$0449,$903A,$CE21,$1453,$167F 
 

	; 0 %
	dc.w	$0000,$9A6B,$924A,$CC31,$4821,$C418,$8408,$0C11
	dc.w	$D67E,$5062,$CC51,$0639,$9632,$D219,$1A43,$1C7F 

	;	-25

	dc.w	$0000,$9F53,$963A,$D029,$4A19,$C410,$8400,$0E09
	dc.w	$DA5A,$544A,$D041,$0831,$9C22,$D811,$1F33,$1F63 
	;	-50


	dc.w	$0000,$9F33,$9C22,$D219,$4C11,$C608,$8600,$1209
	dc.w	$DF3A,$5832,$D429,$0A21,$9F1A,$DC09,$1F23,$1F43 

	;	-75

	dc.w	$0000,$9F1B,$9F12,$D609,$4E09,$C600,$8800,$1601
	dc.w	$DF1A,$5C1A,$D611,$0C11,$9F0A,$DF09,$1F13,$1F23 



;===========================================================================
;                       Start of "Other Routs" to bypass bne range
;===========================================================================

Otherrouts:

	jsr	Movelogo1	; move logo 1 position
	jsr	Movelogo2	; move logo 2 position
	jsr	Movescroll	; scroll routine
	jsr	HFX		; HDMA color bars
	jsr	fade		; fade in/fade out 
	inc     $1017
	inc     $1017
	dec     $1019
	inc     $101b
	rts

Movelogo1:
	ldx	$1100
	lda	horizsine,x
	sta	$1200
	inc	$1100

	ldx	$1102
	lda	vertsine,x
	clc
	adc	#$04
	sta	$1202
	inc	$1102
	inc	$1102
	rts
	

Movelogo2:
	ldx	$1104
	lda	horizsine,x
	sta	$1204
	dec	$1104

	ldx	$1106
	lda	vertsine,x
	clc
	adc	#$04
	sta	$1206
	dec	$1106
	dec	$1106
	rts



;==========================================================================
;                               Joypad routine!
;==========================================================================
Joypad:
	lda	$4212
	and	#$01
	bne	Joypad
	lda	$1128
	and	#$40
	beq	joystuff
	rts
joystuff:
	lda	$4219
	cmp	#$10
	beq	endintro2
	rts
endintro2:
	lda	#$40
	sta	$1128
	rts
	

;==========================================================================
;                           Fade routine
;==========================================================================
fade:
	lda	$1128
	and	#$80
	bne	fadeinwork
	jmp	testfadeout
fadeinwork:
	lda	$1128
	and	#$07
	inc a
	and	#$07
	ora	#$80
	sta	$1128
	and	#$07
	beq	increasefade
	rts
increasefade:
	inc	$112a
	lda	$112a
	cmp	#$10
	beq	fademuch
	rts
fademuch:
	dec	$112a
	stz	$1128
	rts
testfadeout:
	lda	$1128
	and	#$40
	bne	fadeout
	rts
fadeout:
	lda	$1128
	and	#$07
	inc a
	and	#$07
	ora	#$40
	sta	$1128
	and	#$07
	beq	decreasefade
	rts
decreasefade:
	dec	$112a
	lda	$112a
	cmp	#$ff
	beq	fadeless
	rts
fadeless:
	inc	$112a
	stz	$1128
	inc	$112c
	rts
	

;==========================================================================
;                      HDMA Setup
;==========================================================================
HDMA:
	rep	#$30
	sep	#$20
	ldx	#$0000
	lda	#$00
cleanHram
	sta	$7e8000,x
	inx
	cpx	#$8000
	bne	cleanHram
	ldx	#$0000
	txy
Palsetup:
	lda	#$01
	sta	$7e8000,x
	inx
	lda	#$00
	sta	$7e8000,x
	inx
	iny
	cpy	#$00ff
	bne	Palsetup
	lda	#$00
	sta	$7e8000,x
	sta	$7e8001,x

	ldx	#$0000
	txy
Colsetup:
	lda	#$01
	sta	$7e8500,x
	inx
	lda	#$00
	sta	$7e8500,x
	inx
	lda	#$00
	sta	$7e8500,x
	inx
	iny
	cpy	#$00ff
	bne	Colsetup
	lda	#$00
	sta	$7e8500,x
	sta	$7e8501,x
	sta	$7e8502,x



	lda	#$00
	sta	$4300		; 0= 1 byte per register (not a word!)
	lda	#$21
	sta	$4301		; 21xx   this is 2118 (VRAM)
	lda	#$00
	sta	$4302
	lda	#$80		; address = $7e8000
	sta	$4303
	lda	#$7e
	sta	$4304		; bank address of data in ram

	lda	#$02
	sta	$4310		; 0= 1 byte per register (not a word!)
	lda	#$22
	sta	$4311		; 21xx   this is 2118 (VRAM)
	lda	#$00
	sta	$4312
	lda	#$85		; address = $7e8500
	sta	$4313
	lda	#$7e
	sta	$4314		; bank address of data in ram

	jsr	WaitVb
	lda	#$03
	sta	$420c

	ldx     #$0000                                 
	stx     $1017           ; si e offset for red  
	stx     $1019           ; sine offset for green
	ldx	#$0030
	stx     $101b           ; sine offset for blue
	stx	$101d		; storage
	ldx	#$0020
	stx	$101f
	ldx	#$0400
	stx	$100d



HFX:

	
	lda	#$7e
	pha
	plb
	ldx	#$0000
	ldy	#$0000
copyFXcolors:
	lda	$a000,x
	sta	$8501,y
	inx
	iny
	lda	$a000,x
	sta	$8501,y
	inx
	iny
	lda	#$01
	sta	$8501,y
	iny
	cpx	#$0200
	bne	copyFXcolors
	phk
	plb

	ldx	#$0000
	rep	#$30
	lda	#$00
clearcolorram:
	sta	$7ea000,x
	inx
	inx
	cpx	#$0200
	bne	clearcolorram
	sep	#$20

	ldy	$1017
	rep	#$30
	lda	COLORSINE,y
	and	#$00ff
	asl a
	sta	$101d
	sep	#$20
	ldx	$101d
	ldy	#$0000
copyreds:
	lda	reds,y
	ora	$7ea000,x
	sta	$7ea000,x
	lda	reds,y
	ora	$7ea002,x
	sta	$7ea002,x
	lda	reds+1,y
	ora	$7ea001,x
	sta	$7ea001,x
	lda	reds+1,y
	ora	$7ea003,x
	sta	$7ea003,x
	inx
	inx
	inx
	inx
	iny
	iny
	cpy	#$0020
	bne	copyreds

	ldy	$1019
	rep	#$30
	lda	COLORSINE,y
	and	#$00ff
	asl a
	sta	$101d
	sep	#$20
	ldx	$101d
	ldy	#$0000
copygreens:
	lda	greens,y
	ora	$7ea000,x
	sta	$7ea000,x
	lda	greens,y
	ora	$7ea002,x
	sta	$7ea002,x
	lda	greens+1,y
	ora	$7ea001,x
	sta	$7ea001,x
	lda	greens+1,y
	ora	$7ea003,x
	sta	$7ea003,x
	inx
	inx
	inx
	inx
	iny
	iny
	cpy	#$0020
	bne	copygreens

	
	ldy	$101b
	rep	#$30
	lda	COLORSINE,y
	and	#$00ff
	asl a
	sta	$101d
	sep	#$20
	ldx	$101d
	ldy	#$0000
copyblues:
	lda	blues,y
	ora	$7ea000,x
	sta	$7ea000,x
	lda	blues,y
	ora	$7ea002,x
	sta	$7ea002,x
	lda	blues+1,y
	ora	$7ea001,x
	sta	$7ea001,x
	lda	blues+1,y
	ora	$7ea003,x
	sta	$7ea003,x
	inx
	inx
	inx
	inx
	iny
	iny
	cpy	#$0020
	bne	copyblues
	rts


reds:


	dc.w	$0600,$0800,$0A00,$0C00,$0E00,$1000,$1200,$1400
	dc.w	$1400,$1200,$1000,$0e00,$0c00,$0A00,$0800,$0600 

greens:
	

	dc.w	$C000,$0001,$4001,$8001,$C001,$0002,$4002,$8002
	dc.w	$8002,$4002,$0002,$c001,$8001,$4001,$0001,$C000 
blues:
	
	dc.w	$0018,$0020,$0028,$0030,$0038,$0040,$0048,$0050
	dc.w	$0050,$0048,$0040,$0038,$0030,$0028,$0020,$0018 
 


;==========================================================================
;                       Credits part!
;==========================================================================

CREDS:
	sep	#$30
	jsr	Snes_Init
	rep	#$30
	sep	#$20
	lda	#$05
	sta	$212c
	lda     #$42                                     
	sta     $2107           ; BG0 tile address $4000 
	lda     #$00                                     
	Sta     $210b           ; BG0 Graphics data $0000
	lda	#$01
	sta	$2105


	lda     #$06                                     
	sta     $210c           ; BG2 graphics data $0000
	lda	#$6c
	sta	$2109

	ldx	#$0100
	stx	$1000

	ldx	#$0000
	stx	$1002
	stx	$1004



	lda	$1000
	sta	$210e
	lda	$1001
	sta	$210e


	lda	#$80
	sta	$2100

	ldx	#$4000
	stx	$2116

	ldx	#$0000
clearcredscreen2:
	stz	$2118
	stz	$2119
	inx
	cpx	#$0800
	bne	clearcredscreen2

	ldx	#$4000
	stx	$2116

	ldx	#$0000
copycred:

	lda	credtext,x
	sta	$2118
	inx
	lda	credtext,x
	sta	$2119
	inx
	cpx	#$0640
	bne	copycred


	
	ldx	#$0000
	stx	$2116
	 
	ldx	#$0000
copycredgfx:
	lda	>$7f4000,x
	sta	$2118
	inx
	lda	>$7f4000,x
	sta	$2119
	inx
	cpx	#$1d40
	bne	copycredgfx



	lda	#$80
	sta	$1128
	lda	#$00
	sta	$112a
	ldx	#$0000
	stx 	$112c

	lda	#$03
	sta	$420c

	
Wait6:
	jsr	WaitVb
	lda	$112a
	sta	$2100

	lda	$1000
	sta	$210e
	lda	$1001
	sta	$210e
	jsr	Dotrout
	jsr	HFX
	inc     $1017
	inc     $1017
	dec     $1019
	inc     $101b
	jsr	scrollup
	jsr	fade
	jmp	Waitt77
scrollup:
	sep	#$20
	lda	$1004
	bne	stopall
	rep	#$30
	lda	$1000
	cmp	#$01fe
	beq	noscrollup
	inc a
	inc a
	sta	$1000
stopall:
	sep	#$20
	rts

noscrollup:
	rep	#$30
	lda	$1000
	cmp	#$01fe
	beq	timethis
	sep	#$20
	rts
timethis:
	rep	#$30
	inc	$1002
	lda	$1002
	cmp	#$150
	beq	timeover
	sep	#$20
	rts
timeover:
	sep	#$20
	inc	$1004
	lda     #$40 
	sta     $1128

	rts
	

Waitt77:
	sep	#$20
	lda	$1004
	bne	Waitt
	jmp	Wait7
Waitt:
	lda	$112a
	beq	theend
	jmp	Wait7
theend:
	sep     #$30     
	stz	$420c
	jsr     Snes_Init	
	sep	#$30
	jmp	game

Wait7:
	rep	#$30
	sep	#$20
	ldx	$100b
	dex
	stx	$100b
	beq	Waitr7776
	jmp	Wait6
Waitr7776:
	ldx	#$0200
	stx	$100b

	inc	$1015
	ldx	$1015
	lda	SINEPOS1,x
	sta	$1010
	lda	SINEPOS2,x
	sta	$1011
	lda	SINEPOS3,x
	sta	$1012
	lda	SINEPOS4,x
	sta	$1013
	lda	SINEPOS5,x
	sta	$1014

	ldx	$100d
	dex			; decrease routine timer
	stx	$100d
	cpx	#$0000
	beq	reststuff
	jmp	Wait6

reststuff:
	ldx	#$000a
	stx	$100d

	ldx	#$0000
	stx	$1015


	
	ldx	#$0000
	stx	$ac		; sine data location offset
	
	ldx	#$0000
	stx	$ae		; X sine offset

	ldx	#$0000
	stx	$b0		; Y sine offset

	ldx	#$80
	stx	$b2		; # of dots to draw




	lda	#$01
	sta	$1010		; sine increase value
	sta	$1011		; x increase
	sta	$1012		; y increase
	lda	#$03
	sta	$1013		; x distance
	lda	#$04
	sta	$1014		; y distance
	
	ldx	#$0000
	stx	$1015		; offset for sine positions





	ldx	$1015
	lda	SINEPOS1,x
	sta	$1010
	lda	SINEPOS2,x
	sta	$1011
	lda	SINEPOS3,x
	sta	$1012
	lda	SINEPOS4,x
	sta	$1013
	lda	SINEPOS5,x
	sta	$1014
	jmp	Wait6


credtext:

	.bin	cred.dat.screen

credgfx:
	;.bin	cred.dat
	.bin	cred.pan

;==========================================================================
;                      Sprite Scroll Routine
;==========================================================================

Sprscroll:
	rep	#$10	; x,y = 16 bit
	sep	#$20	; a = 8 bit
			; start of General DMA graphics copy routine!
	lda	#$00
	sta	$4330		; 0= 1 byte per register (not a word!)
	lda	#$04
	sta	$4331		; 21xx   this is 2118 (VRAM)
	lda	#$00
	sta	$4332
	lda	#$05		; address = $7e0500
	sta	$4333
	lda	#$7e
	sta	$4334		; bank address of data in ram
	ldx	#$0044
	stx	$4335		; # of bytes to be transferred

	ldx	#$0000
	stx	$2102

	lda	#$08		; turn on bit 4 (%1000=8) of G-DMA channel
	sta	$420b
	ldx	#$0100
	stx	$2102
	lda	$1118
	sta	$2104
	rts




Movescroll:



	stz	$1118
	lda	$1110
	sta	$111c
	sec
	sbc	#$11
	sta	$1114

	and	#$80
	asl a
	rol	$1118
	

	ldx	#$0000
	stx	$1116


	ldx	#$0000
	txy
				; $1110 = current scroll H pos
				; $1114 = storage scroll h pos
				; $1112 = current scroll text pos
				; $1116	= storage scroll text pos
				; $1118 = storage of MSB

scrollwriter:
	lda	$1114	
	sta	$0500,x
	inx
	phx
	rep	#$30
	lda	$111c
	clc
	adc	$111a
	and	#$00ff
	tax
	sep	#$20
	lda	vertsine2,x		; vert pos
	clc
	adc	#$48
	plx
	sta	$0500,x
	inx
	rep	#$30

	

	phy
	ldy	$1116
	lda	$0550,y
	ply

	and	#$0ff
	sec
	sbc	#$20
	phx
	tax
	sep	#$20
	lda	fontpos,x	
	plx
	sta	$0500,x
	inx
	lda	#%00110000
	sta	$0500,x
	inx

	phx
	ldx	$1116
	inx
	stx	$1116
	plx


	lda	$111c
	clc
	adc	#$10
	sta	$111c


	lda	$1114
	clc
	adc	#$10
	sta	$1114
	iny
	cpy	#$0011
	bne	scrollwriter

	inc	$111a
	inc	$111a
	inc	$111a

	dec	$1110
	lda	$1110
	beq	movescrolltext
	rts
movescrolltext:
	lda	#$10
	sta	$1110

	inc	$1102
	inc	$1106


	ldx	#$0000
	sep	#$20
copyscrolltext:
	lda	$0551,x
	sta	$0550,x
	inx
	cpx	#$0010
	bne	copyscrolltext


readtext:


	ldx	$1112
	lda	scrolltext,x
	beq	endscroll
	cmp	#$60
	bcc	noand5f
	and	#$5f
noand5f:
	sta	$0560
	ldx	$1112
	inx
	stx	$1112
	rts


endscroll:
	ldx	#$0000
	stx	$1112
	bra	readtext


;===========================================================================
;                               Start of Dot Setup
;===========================================================================

Dotrout:
	rep	#$10	; x,y = 16 bit
	sep	#$20	; a = 8 bit
			; start of General DMA graphics copy routine!
	lda	#$00
	sta	$4330		; 0= 1 byte per register (not a word!)
	lda	#$18
	sta	$4331		; 21xx   this is 2118 (VRAM)
	lda	#$00
	sta	$4332
	lda	#$02		; address = $7e0200
	sta	$4333
	lda	#$7e
	sta	$4334		; bank address of data in ram
	ldx	#$0200
	stx	$4335		; # of bytes to be transferred
	lda	#$00
	sta	$2115		; increase V-Ram address after writing to
				; $2118
	ldx	#$6000
	stx	$2116		; address of VRAM to copy garphics in
	lda	#$08		; turn on bit 4 (%1000=8) of G-DMA channel
	sta	$420b
	lda	#$80		; increase V-Ram address after writing to
	sta	$2115		; $2119
	jsr	Dots		; go to dot routine
	rts



;============================================================================
;                           Start Of Dot Routine
;============================================================================

Dots:
	rep	#$30	
	ldy	#$0200
	lda	#$0000
cleardots:
	sta	$0200,y
	dey
	dey
	bpl	cleardots	
	sep	#$20

	rep	#$30
	ldx	#SINE		; get address of SINE data location
	stx	$13
	lda	$13
	clc
	adc	$ac		; add an offset to it
	sta	$13
	sep	#$20
	lda	$ac
	clc
	adc	$1010		; increase sine offset for SINE data location
	sta	$ac

	lda	$ae
	clc
	adc	$1011		; increase Y position
	sta	$ae

	lda	$b0
	clc
	adc	$1012		; increase X position
	sta	$b0


	ldy	$ae
	sty	$a2
	ldy	$b0
	sty	$a4

	ldx	$b2
	stx	$a6		; number of dots to make
dotdraw:
	ldy	$a2		; read REAL sine offset
	ldx	$a4		; 
				; 
				; 
	lda	SINE,x		; get SINE for column offset (x position)
	lsr a			; 
	lsr a			;
	lsr a			; divide by 8 (to get column offset) [0-1f)
	sta	$a8
	stz	$a9
	rep	#$30
	lda	$a8
	asl a 			;
	asl a 			;
	asl a			; multiply by 64 to get offset to write data 
	asl a			; to graphics buffer
	asl a			; the grid is 32 columns*8 rows (8*8=64)
	asl a			;
	sta	$a8
	sep	#$20
	lda	($13),y
	;clc			; add to get row offset
	adc	$a8
	sta	$a8
	lda	SINE,x		; get column bit offset
	and	#$07
	sta	$aa
	;stz	$ab
	ldx	$aa
	ldy	$a8
	;lda	[$10],y
	lda	$0200,y
	ora	OFFSET,x
	sta	$0200,y
	;sta	[$10],y

	lda	$a2		; increase REAL sine offset to get movement
	;clc
	adc	$1013
	sta	$a2

				; 2 incs move the sine faster
	lda	$a4
	;clc
	adc	$1014
	sta	$a4
	

	dec	$a6
	bne	dotdraw

	rts
OFFSET:
	dc.b	$80,$40,$20,$10,$08,$04,$02,$01

;==========================================================================
;                        Vertical Blank Wait Routine
;==========================================================================
WaitVb:	
	lda	$4210
	bpl     WaitVb	; is the number higher than #$7f? (#$80-$ff)
			; bpl tests bit #7 ($80) if this bit is set it means
			; the byte is negative (BMI, Branch on Minus)
			; BPL (Branch on Plus) if bit #7 is set in $4210
			; it means that it is at the start of V-Blank
			; if not it will keep testing $4210 until bit #7
			; is on (which would make it a negative (BMI)
	rts

;==========================================================================
;       	     SETUP ROUTINES FOR PROGRAM
;==========================================================================


;==========================================================================
;                         Copy graf-x data
;==========================================================================

Copy_Gfx:
	ldx	#$0000		; Vram address $0000
	stx	$2116
	ldx	#$0000
Clearvr:
	stz	$2118		; clear entire Vram
	stz	$2119
	inx
	cpx	#$0000		;
	bne	Clearvr
	
	ldx	#$2000
	stx	$2116
	ldx	#$0000
copylogo:
	lda	>$7f2000,x
	sta	$2118
	inx
	lda	>$7f2000,x
	sta	$2119
	inx
	;cpx	#$1b40
	cpx	#$1e40
	bne	copylogo









	ldx	#$0000
	stx	$2116
copysprgfx:
	lda	>$7f0000,x
	sta	$2118
	inx
	lda	>$7f0000,x
	sta	$2119
	inx
	cpx	#$2000
	bne	copysprgfx

	rts


;==========================================================================
;                      Copy Colors
;==========================================================================
Copy_colors:
	stz	$2121		; Select Color Register 1
	ldx	#$0000
CopCol:	
	lda	Colors,X
	sta	$2122
	inx
	cpx	#$0100 		; copy all colors
	bne	CopCol
	rts

;==========================================================================
;                      Make Tiles
;==========================================================================

Make_tiles:
	ldx	#$6c00		
	stx	$2116
	ldx	#$0000
clearscreen:
	lda	#$40
	sta	$2118		;
	stz	$2119		;   clear the text screen (with unused tile)
	inx			;
	cpx	#$0400		;
	bne	clearscreen	;


	ldx	#$6c40
	stx	$2116
	ldx	#$0000
copyscreen:
	lda	screen,x
	sta	$2118
	lda	#$00
	sta	$2119
	inx
	cpx	#$0300
	bne	copyscreen

	ldx	#$7000
	stx	$2116

	ldx	#$0000
clearlogo:
	lda	#$00
	sta	$2118
	stz	$2119
	inx
	cpx	#$1000
	bne	clearlogo
	
	ldx	#$7000
	stx	$2116


	ldx	#$0000
	rep	#$30
copylogoscreen:
	lda	logoscreen,x
	;xba
	ora	#$0800
	sta	$2118
	inx
	inx
	cpx	#$0700
	bne	copylogoscreen


	ldx	#$7800
	stx	$2116


	ldx	#$0000
	rep	#$30
copylogoscreen2:
	lda	logoscreen,x
	;xba
	ora	#$0400
	sta	$2118
	inx
	inx
	cpx	#$0700
	bne	copylogoscreen2


	sep	#$20
	rts
	


;============================================================================
;                                  Clear Ram Bank
;============================================================================

Clear_ram:
	ldx	#$0000
clearram:
	lda	#$00		; clear dot graphics buffer
	sta	$7e0200,x
	inx
	cpx	#$0200		; clear 512 bytes of ram
	bne	clearram

	ldx	#$0000
clearsprram:
	lda	#$00
	sta	$7e0500,x	; clear some ram for sprite data
	inx
	cpx	#$0040
	bne	clearsprram

	ldx	#$0000
clearsprtext:
	lda	#$20
	sta	$7e0550,x
	inx
	cpx	#$0011
	bne	clearsprtext

	rts



;==========================================================================
;                           Sprite Setup routine
;==========================================================================

Sprite_setup:
	lda	#$60
	sta	$2101
	stz	$2102
	stz	$2103
	ldx	#$0000
sprtclear:
	stz	$2104		; Horizontal position
	lda	#$f0
	sta	$2104		; Vertical position
	stz	$2104		; sprite object = 0
	lda	#%00110000
	sta	$2104		; pallete = 0, priority = 0, h;v flip = 0
	inx
	cpx	#$0080		; (128 sprites)
	bne	sprtclear
	ldx	#$0000
sprtdataclear:
	stz	$2104		; clear H-position MSB
	stz	$2104		; and make size small
	inx
	cpx	#$0020		; 32 extra bytes for sprite data
				; info
	bne	sprtdataclear

	
	rts

;==========================================================================
;                   SNES Register Initialization routine
;==========================================================================
Snes_Init:
	sep 	#$30    ; X,Y,A are 8 bit numbers
	lda 	#$8F    ; screen off, full brightness
	sta 	$2100   ; brightness + screen enable register 
	stz 	$2101   ; Sprite register (size + address in VRAM)
	stz 	$2102   ; Sprite registers (address of sprite memory [OAM])
	stz 	$2103   ;    ""                       ""
	stz 	$2105   ; Mode 0, = Graphic mode register
	stz 	$2106   ; noplanes, no mosaic, = Mosaic register
	stz 	$2107   ; Plane 0 map VRAM location
	stz 	$2108   ; Plane 1 map VRAM location
	stz 	$2109   ; Plane 2 map VRAM location
	stz 	$210A   ; Plane 3 map VRAM location
	stz 	$210B   ; Plane 0+1 Tile data location
	stz 	$210C   ; Plane 2+3 Tile data location
	stz 	$210D   ; Plane 0 scroll x (first 8 bits)
	stz 	$210D   ; Plane 0 scroll x (last 3 bits) #$0 - #$07ff
	stz 	$210E   ; Plane 0 scroll y (first 8 bits)
	stz 	$210E   ; Plane 0 scroll y (last 3 bits) #$0 - #$07ff
	stz 	$210F   ; Plane 1 scroll x (first 8 bits)
	stz 	$210F   ; Plane 1 scroll x (last 3 bits) #$0 - #$07ff
	stz 	$2110   ; Plane 1 scroll y (first 8 bits)
	stz 	$2110   ; Plane 1 scroll y (last 3 bits) #$0 - #$07ff
	stz 	$2111   ; Plane 2 scroll x (first 8 bits)
	stz 	$2111   ; Plane 2 scroll x (last 3 bits) #$0 - #$07ff
	stz 	$2112   ; Plane 2 scroll y (first 8 bits)
	stz 	$2112   ; Plane 2 scroll y (last 3 bits) #$0 - #$07ff
	stz 	$2113   ; Plane 3 scroll x (first 8 bits)
	stz 	$2113   ; Plane 3 scroll x (last 3 bits) #$0 - #$07ff
	stz 	$2114   ; Plane 3 scroll y (first 8 bits)
	stz 	$2114   ; Plane 3 scroll y (last 3 bits) #$0 - #$07ff
	lda 	#$80    ; increase VRAM address after writing to $2119
	sta 	$2115   ; VRAM address increment register
	stz 	$2116   ; VRAM address low
	stz 	$2117   ; VRAM address high
	stz 	$211A   ; Initial Mode 7 setting register
	stz 	$211B   ; Mode 7 matrix parameter A register (low)
	lda 	#$01
	sta 	$211B   ; Mode 7 matrix parameter A register (high)
	stz 	$211C   ; Mode 7 matrix parameter B register (low)
	stz 	$211C   ; Mode 7 matrix parameter B register (high)
	stz 	$211D   ; Mode 7 matrix parameter C register (low)
	stz 	$211D   ; Mode 7 matrix parameter C register (high)
	stz 	$211E   ; Mode 7 matrix parameter D register (low)
	sta 	$211E   ; Mode 7 matrix parameter D register (high)
	stz 	$211F   ; Mode 7 center position X register (low)
	stz 	$211F   ; Mode 7 center position X register (high)
	stz 	$2120   ; Mode 7 center position Y register (low)
	stz 	$2120   ; Mode 7 center position Y register (high)
	stz 	$2121   ; Color number register ($0-ff)
	stz 	$2123   ; BG1 & BG2 Window mask setting register
	stz 	$2124   ; BG3 & BG4 Window mask setting register
	stz 	$2125   ; OBJ & Color Window mask setting register
	stz 	$2126   ; Window 1 left position register
	stz 	$2127   ; Window 2 left position register
	stz 	$2128   ; Window 3 left position register
	stz 	$2129   ; Window 4 left position register
	stz 	$212A   ; BG1, BG2, BG3, BG4 Window Logic register
	stz 	$212B   ; OBJ, Color Window Logic Register (or,and,xor,xnor)
	sta 	$212C   ; Main Screen designation (planes, sprites enable)
	stz 	$212D   ; Sub Screen designation
	stz 	$212E   ; Window mask for Main Screen
	stz 	$212F   ; Window mask for Sub Screen
	lda 	#$30
	sta 	$2130   ; Color addition & screen addition init setting
	stz 	$2131   ; Add/Sub sub designation for screen, sprite, color
	lda 	#$E0
	sta 	$2132   ; color data for addition/subtraction
	stz 	$2133   ; Screen setting (interlace x,y/enable SFX data)
	stz 	$4200   ; Enable V-blank, interrupt, Joypad register
	lda 	#$FF
	sta 	$4201   ; Programmable I/O port
	stz 	$4202   ; Multiplicand A
	stz 	$4203   ; Multiplier B
	stz 	$4204   ; Multiplier C
	stz 	$4205   ; Multiplicand C
	stz 	$4206   ; Divisor B
	stz 	$4207   ; Horizontal Count Timer
	stz 	$4208   ; Horizontal Count Timer MSB (most significant bit)
	stz 	$4209   ; Vertical Count Timer
	stz 	$420A   ; Vertical Count Timer MSB
	stz 	$420B   ; General DMA enable (bits 0-7)
	stz 	$420C   ; Horizontal DMA (HDMA) enable (bits 0-7)
	stz 	$420D	; Access cycle designation (slow/fast rom)
	rts
                             
SINE:


 dc.b  32,32,33,34,35,35,36,37,38,38,39,40,41,41,42,43,44,44,45,46
 dc.b  46,47,48,48,49,50,50,51,51,52,53,53,54,54,55,55,56,56,57,57
 dc.b  58,58,59,59,59,60,60,60,61,61,61,61,62,62,62,62,62,63,63,63
 dc.b  63,63,63,63,63,63,63,63,63,63,63,63,62,62,62,62,62,61,61,61
 dc.b  61,60,60,60,59,59,59,58,58,57,57,56,56,55,55,54,54,53,53,52
 dc.b  51,51,50,50,49,48,48,47,46,46,45,44,44,43,42,41,41,40,39,38
 dc.b  38,37,36,35,35,34,33,32,32,31,30,29,28,28,27,26,25,25,24,23
 dc.b  22,22,21,20,19,19,18,17,17,16,15,15,14,13,13,12,12,11,10,10
 dc.b  9,9,8,8,7,7,6,6,5,5,4,4,4,3,3,3,2,2,2,2,1,1,1,1,1,0,0,0,0,0
 dc.b  0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,2,2,2,2,3,3,3,4,4,4,5,5,6,6,7
 dc.b  7,8,8,9,9,10,10,11,12,12,13,13,14,15,15,16,17,17,18,19,19,20
 dc.b  21,22,22,23,24,25,25,26,27,28,28,29,30,31

 dc.b  32,32,33,34,35,35,36,37,38,38,39,40,41,41,42,43,44,44,45,46
 dc.b  46,47,48,48,49,50,50,51,51,52,53,53,54,54,55,55,56,56,57,57
 dc.b  58,58,59,59,59,60,60,60,61,61,61,61,62,62,62,62,62,63,63,63
 dc.b  63,63,63,63,63,63,63,63,63,63,63,63,62,62,62,62,62,61,61,61
 dc.b  61,60,60,60,59,59,59,58,58,57,57,56,56,55,55,54,54,53,53,52
 dc.b  51,51,50,50,49,48,48,47,46,46,45,44,44,43,42,41,41,40,39,38
 dc.b  38,37,36,35,35,34,33,32,32,31,30,29,28,28,27,26,25,25,24,23
 dc.b  22,22,21,20,19,19,18,17,17,16,15,15,14,13,13,12,12,11,10,10
 dc.b  9,9,8,8,7,7,6,6,5,5,4,4,4,3,3,3,2,2,2,2,1,1,1,1,1,0,0,0,0,0
 dc.b  0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,2,2,2,2,3,3,3,4,4,4,5,5,6,6,7
 dc.b  7,8,8,9,9,10,10,11,12,12,13,13,14,15,15,16,17,17,18,19,19,20
 dc.b  21,22,22,23,24,25,25,26,27,28,28,29,30,31



horizsine:

 dc.b  128,131,134,137,140,143,146,149,152,155,158,162,165,167,170
 dc.b  173,176,179,182,185,188,190,193,196,198,201,203,206,208,211
 dc.b  213,215,218,220,222,224,226,228,230,232,234,235,237,238,240
 dc.b  241,243,244,245,246,248,249,250,250,251,252,253,253,254,254
 dc.b  254,255,255,255,255,255,255,255,254,254,254,253,253,252,251
 dc.b  250,250,249,248,246,245,244,243,241,240,238,237,235,234,232
 dc.b  230,228,226,224,222,220,218,215,213,211,208,206,203,201,198
 dc.b  196,193,190,188,185,182,179,176,173,170,167,165,162,158,155
 dc.b  152,149,146,143,140,137,134,131,128,124,121,118,115,112,109
 dc.b  106,103,100,97,93,90,88,85,82,79,76,73,70,67,65,62,59,57,54
 dc.b  52,49,47,44,42,40,37,35,33,31,29,27,25,23,21,20,18,17,15,14
 dc.b  12,11,10,9,7,6,5,5,4,3,2,2,1,1,1,0,0,0,0,0,0,0,1,1,1,2,2,3
 dc.b  4,5,5,6,7,9,10,11,12,14,15,17,18,20,21,23,25,27,29,31,33,35
 dc.b  37,40,42,44,47,49,52,54,57,59,62,65,67,70,73,76,79,82,85,88
 dc.b  90,93,97,100,103,106,109,112,115,118,121,124

vertsine:

 dc.b  64,66,67,69,70,72,73,75,76,78,80,81,83,84,86,87,88,90,91,93
 dc.b  94,96,97,98,100,101,102,103,105,106,107,108,109,110,111,112
 dc.b  113,114,115,116,117,118,119,120,120,121,122,123,123,124,124
 dc.b  125,125,126,126,126,127,127,127,128,128,128,128,128,128,128
 dc.b  128,128,128,128,127,127,127,126,126,126,125,125,124,124,123
 dc.b  123,122,121,120,120,119,118,117,116,115,114,113,112,111,110
 dc.b  109,108,107,106,105,103,102,101,100,98,97,96,94,93,91,90,88
 dc.b  87,86,84,83,81,80,78,76,75,73,72,70,69,67,66,64,62,61,59,58
 dc.b  56,55,53,52,50,48,47,45,44,42,41,40,38,37,35,34,32,31,30,28
 dc.b  27,26,25,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9,8,8,7
 dc.b  6,5,5,4,4,3,3,2,2,2,1,1,1,0,0,0,0,0,0,0,0,0,0,0,1,1,1,2,2,2
 dc.b  3,3,4,4,5,5,6,7,8,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22
 dc.b  23,25,26,27,28,30,31,32,34,35,37,38,40,41,42,44,45,47,48,50
 dc.b  52,53,55,56,58,59,61,62
vertsine2:
 dc.b 64,64,64

 ;dc.b  32,33,34,34,35,36,37,37,38,39,40,41,41,42,43,44,44,45,46,46
 ;dc.b  47,48,48,49,50,50,51,52,52,53,53,54,55,55,56,56,57,57,58,58
 ;dc.b  59,59,59,60,60,61,61,61,62,62,62,62,63,63,63,63,63

 dc.b  64,64,64,64,64,64,64,64,64,64,64,64,63,63,63,63,63,62,62,62
 dc.b  62,61,61,61,60,60,59,59,59,58,58,57,57,56,56,55,55,54,53,53
 dc.b  52,52,51,50,50,49,48,48,47,46,46,45,44,44,43,42,41,41,40,39
 dc.b  38,37,37,36,35,34,34,33,32,31,30,30,29,28,27,27,26,25,24,23
 dc.b  23,22,21,20,20,19,18,18,17,16,16,15,14,14,13,12,12,11,11,10
 dc.b  9,9,8,8,7,7,6,6,5,5,5,4,4,3,3,3,2,2,2,2,1,1,1,1,1,0,0,0,0,0
 dc.b  0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,2,2,2,2,3,3,3,4,4,5,5,5,6,6,7
 dc.b  7,8,8,9,9,10,11,11,12,12,13,14,14,15,16,16,17,18,18,19,20,20
 dc.b  21,22,23,23,24,25,26,27,27,28,29,30,30,31
 dc.b  32,33,34,34,35,36,37,37,38,39,40,41,41,42,43,44,44,45,46,46 
 dc.b  47,48,48,49,50,50,51,52,52,53,53,54,55,55,56,56,57,57,58,58 
 dc.b  59,59,59,60,60,61,61,61,62,62,62,62,63,63,63,63,63


COLORSINE:
	
 dc.b  91,93,95,98,100,102,104,107,109,111,113,115,117,120,122,124
 dc.b  126,128,130,132,134,136,138,140,142,143,145,147,149,150,152
 dc.b  154,155,157,158,160,161,163,164,165,167,168,169,170,171,172
 dc.b  173,174,175,176,177,177,178,179,179,180,180,181,181,181,182
 dc.b  182,182,182,182,182,182,182,182,181,181,181,180,180,179,179
 dc.b  178,177,177,176,175,174,173,172,171,170,169,168,167,165,164
 dc.b  163,161,160,158,157,155,154,152,150,149,147,145,143,142,140
 dc.b  138,136,134,132,130,128,126,124,122,120,117,115,113,111,109
 dc.b  107,104,102,100,98,95,93,91,89,87,84,82,80,78,75,73,71,69,67
 dc.b  65,62,60,58,56,54,52,50,48,46,44,42,40,39,37,35,33,32,30,28
 dc.b  27,25,24,22,21,19,18,17,15,14,13,12,11,10,9,8,7,6,5,5,4,3,3
 dc.b  2,2,1,1,1,0,0,0,0,0,0,0,0,0,1,1,1,2,2,3,3,4,5,5,6,7,8,9,10
 dc.b  11,12,13,14,15,17,18,19,21,22,24,25,27,28,30,32,33,35,37,39
 dc.b  40,42,44,46,48,50,52,54,56,58,60,62,65,67,69,71,73,75,78,80
 dc.b  82,84,87,89



screen:

	dc.b	$00,$08,$10,$18,$20,$28,$30,$38
	dc.b	$00,$08,$10,$18,$20,$28,$30,$38
	dc.b	$00,$08,$10,$18,$20,$28,$30,$38
	dc.b	$00,$08,$10,$18,$20,$28,$30,$38
	dc.b	$01,$09,$11,$19,$21,$29,$31,$39
	dc.b	$01,$09,$11,$19,$21,$29,$31,$39
	dc.b	$01,$09,$11,$19,$21,$29,$31,$39
	dc.b	$01,$09,$11,$19,$21,$29,$31,$39
	dc.b	$02,$0a,$12,$1a,$22,$2a,$32,$3a
	dc.b	$02,$0a,$12,$1a,$22,$2a,$32,$3a
	dc.b	$02,$0a,$12,$1a,$22,$2a,$32,$3a
	dc.b	$02,$0a,$12,$1a,$22,$2a,$32,$3a
	dc.b	$03,$0b,$13,$1b,$23,$2b,$33,$3b
	dc.b	$03,$0b,$13,$1b,$23,$2b,$33,$3b
	dc.b	$03,$0b,$13,$1b,$23,$2b,$33,$3b
	dc.b	$03,$0b,$13,$1b,$23,$2b,$33,$3b
	dc.b	$04,$0c,$14,$1c,$24,$2c,$34,$3c
	dc.b	$04,$0c,$14,$1c,$24,$2c,$34,$3c
	dc.b	$04,$0c,$14,$1c,$24,$2c,$34,$3c
	dc.b	$04,$0c,$14,$1c,$24,$2c,$34,$3c
	dc.b	$05,$0d,$15,$1d,$25,$2d,$35,$3d
	dc.b	$05,$0d,$15,$1d,$25,$2d,$35,$3d
	dc.b	$05,$0d,$15,$1d,$25,$2d,$35,$3d
	dc.b	$05,$0d,$15,$1d,$25,$2d,$35,$3d
	dc.b	$06,$0e,$16,$1e,$26,$2e,$36,$3e
	dc.b	$06,$0e,$16,$1e,$26,$2e,$36,$3e
	dc.b	$06,$0e,$16,$1e,$26,$2e,$36,$3e
	dc.b	$06,$0e,$16,$1e,$26,$2e,$36,$3e
	dc.b	$07,$0f,$17,$1f,$27,$2f,$37,$3f
	dc.b	$07,$0f,$17,$1f,$27,$2f,$37,$3f
	dc.b	$07,$0f,$17,$1f,$27,$2f,$37,$3f
	dc.b	$07,$0f,$17,$1f,$27,$2f,$37,$3f

	dc.b	$00,$08,$10,$18,$20,$28,$30,$38
	dc.b	$00,$08,$10,$18,$20,$28,$30,$38
	dc.b	$00,$08,$10,$18,$20,$28,$30,$38
	dc.b	$00,$08,$10,$18,$20,$28,$30,$38
	dc.b	$01,$09,$11,$19,$21,$29,$31,$39
	dc.b	$01,$09,$11,$19,$21,$29,$31,$39
	dc.b	$01,$09,$11,$19,$21,$29,$31,$39
	dc.b	$01,$09,$11,$19,$21,$29,$31,$39
	dc.b	$02,$0a,$12,$1a,$22,$2a,$32,$3a
	dc.b	$02,$0a,$12,$1a,$22,$2a,$32,$3a
	dc.b	$02,$0a,$12,$1a,$22,$2a,$32,$3a
	dc.b	$02,$0a,$12,$1a,$22,$2a,$32,$3a
	dc.b	$03,$0b,$13,$1b,$23,$2b,$33,$3b
	dc.b	$03,$0b,$13,$1b,$23,$2b,$33,$3b
	dc.b	$03,$0b,$13,$1b,$23,$2b,$33,$3b
	dc.b	$03,$0b,$13,$1b,$23,$2b,$33,$3b
	dc.b	$04,$0c,$14,$1c,$24,$2c,$34,$3c
	dc.b	$04,$0c,$14,$1c,$24,$2c,$34,$3c
	dc.b	$04,$0c,$14,$1c,$24,$2c,$34,$3c
	dc.b	$04,$0c,$14,$1c,$24,$2c,$34,$3c
	dc.b	$05,$0d,$15,$1d,$25,$2d,$35,$3d
	dc.b	$05,$0d,$15,$1d,$25,$2d,$35,$3d
	dc.b	$05,$0d,$15,$1d,$25,$2d,$35,$3d
	dc.b	$05,$0d,$15,$1d,$25,$2d,$35,$3d
	dc.b	$06,$0e,$16,$1e,$26,$2e,$36,$3e
	dc.b	$06,$0e,$16,$1e,$26,$2e,$36,$3e
	dc.b	$06,$0e,$16,$1e,$26,$2e,$36,$3e
	dc.b	$06,$0e,$16,$1e,$26,$2e,$36,$3e
	dc.b	$07,$0f,$17,$1f,$27,$2f,$37,$3f
	dc.b	$07,$0f,$17,$1f,$27,$2f,$37,$3f
	dc.b	$07,$0f,$17,$1f,$27,$2f,$37,$3f
	dc.b	$07,$0f,$17,$1f,$27,$2f,$37,$3f

	dc.b	$00,$08,$10,$18,$20,$28,$30,$38
	dc.b	$00,$08,$10,$18,$20,$28,$30,$38
	dc.b	$00,$08,$10,$18,$20,$28,$30,$38
	dc.b	$00,$08,$10,$18,$20,$28,$30,$38
	dc.b	$01,$09,$11,$19,$21,$29,$31,$39
	dc.b	$01,$09,$11,$19,$21,$29,$31,$39
	dc.b	$01,$09,$11,$19,$21,$29,$31,$39
	dc.b	$01,$09,$11,$19,$21,$29,$31,$39
	dc.b	$02,$0a,$12,$1a,$22,$2a,$32,$3a
	dc.b	$02,$0a,$12,$1a,$22,$2a,$32,$3a
	dc.b	$02,$0a,$12,$1a,$22,$2a,$32,$3a
	dc.b	$02,$0a,$12,$1a,$22,$2a,$32,$3a
	dc.b	$03,$0b,$13,$1b,$23,$2b,$33,$3b
	dc.b	$03,$0b,$13,$1b,$23,$2b,$33,$3b
	dc.b	$03,$0b,$13,$1b,$23,$2b,$33,$3b
	dc.b	$03,$0b,$13,$1b,$23,$2b,$33,$3b
	dc.b	$04,$0c,$14,$1c,$24,$2c,$34,$3c
	dc.b	$04,$0c,$14,$1c,$24,$2c,$34,$3c
	dc.b	$04,$0c,$14,$1c,$24,$2c,$34,$3c
	dc.b	$04,$0c,$14,$1c,$24,$2c,$34,$3c
	dc.b	$05,$0d,$15,$1d,$25,$2d,$35,$3d
	dc.b	$05,$0d,$15,$1d,$25,$2d,$35,$3d
	dc.b	$05,$0d,$15,$1d,$25,$2d,$35,$3d
	dc.b	$05,$0d,$15,$1d,$25,$2d,$35,$3d
	dc.b	$06,$0e,$16,$1e,$26,$2e,$36,$3e
	dc.b	$06,$0e,$16,$1e,$26,$2e,$36,$3e
	dc.b	$06,$0e,$16,$1e,$26,$2e,$36,$3e
	dc.b	$06,$0e,$16,$1e,$26,$2e,$36,$3e
	dc.b	$07,$0f,$17,$1f,$27,$2f,$37,$3f
	dc.b	$07,$0f,$17,$1f,$27,$2f,$37,$3f
	dc.b	$07,$0f,$17,$1f,$27,$2f,$37,$3f
	dc.b	$07,$0f,$17,$1f,$27,$2f,$37,$3f

SINEPOS1:
	dc.b	3,2,1,0,$fe,$ff,1,1,$01,$02
SINEPOS2:
	dc.b	$fe,$2,$4,1,1,3,1,2,$01,$1
SINEPOS3:
	dc.b	1,2,$ff,2,3,$fe,0,$fe,$fe,$01
SINEPOS4:
	dc.b	$fe,2,1,$fe,2,$ff,1,1,1,$05
SINEPOS5:
	dc.b	$05,2,1,4,1,2,2,$ff,$3f,$03



fontpos:
	dc.b	0	;SP
	dc.b	2	;!
	dc.b	4	;"
	dc.b	0	;#
	dc.b	0 ;$
	dc.b	0 ;%
	dc.b	$c	;&
	dc.b	$e	;'
	dc.b	$22	;(
	dc.b	$24	;)
	dc.b	$26	;* HE
	dc.b	$28	;+
	dc.b	$2a	;,
	dc.b	$2c	;-
	dc.b	$2e	;.
	dc.b	$40	;/
	dc.b	$42	;0
	dc.b	$44	;1
	dc.b	$46	;2
	dc.b	$48	;3
	dc.b	$4a	;4
	dc.b	$4c	;5
	dc.b	$4e	;6
	dc.b	$60	;7
	dc.b	$62	;8
	dc.b	$64	;9
	dc.b	$66	;:
	dc.b	$68	;;
	dc.b	$6a	;<
	dc.b	$2c	;=
	dc.b	$6c	;>
	dc.b	$6e	;?
	dc.b	$80	;@
	dc.b	$82	;A
	dc.b	$84	;B
	dc.b	$86	;C
	dc.b	$88	;D
	dc.b	$8a	;E
	dc.b	$8c	;F
	dc.b	$8e	;G
	dc.b	$a0	;H
	dc.b	$a2	;I
	dc.b	$a4	;J
	dc.b	$a6	;k
	dc.b	$a8	;l
	dc.b	$aa	;m
	dc.b	$ac	;n
	dc.b	$ae	;o
	dc.b	$c0	;p
	dc.b	$c2	;q
	dc.b	$c4	;r
	dc.b	$c6	;s
	dc.b	$c8	;t
	dc.b	$ca	;u
	dc.b	$cc	;v
	dc.b	$ce	;w
	dc.b	$e0	;x
	dc.b	$e2	;y
	dc.b	$e4	;z
HCOLP:

	dc.b	8,0,8,0,8,0,8,0,8,0,8,0,8,0,8,0,8,0,8,0,8,0,8,0,8,0,8,0,8,0,8,0
	dc.b	8,0,8,0,8,0,8,0,8,0,8,0,8,0,8,0,8,0,8,0,8,0,8,0,8,0,8,0,8,0,8,0
	dc.b	8,0,0,0
HCOLC:
	dc.b	8,0,0
	dc.b	8,1,0
	dc.b	8,2,0
	dc.b	8,3,0
	dc.b	8,4,0
	dc.b	8,5,0
	dc.b	8,6,0
	dc.b	8,7,0
	dc.b	8,8,0
	dc.b	8,9,0
	dc.b	8,$a,0
	dc.b	8,$b,0
	dc.b	8,$c,0
	dc.b	8,$d,0
	dc.b	8,$e,0
	dc.b	8,$f,0
	dc.b	8,$10,0
	dc.b	8,$11,0
	dc.b	8,$12,0
	dc.b	8,$13,0
	dc.b	8,$14,0
	dc.b	8,$15,0
	dc.b	8,$16,0
	dc.b	8,$17,0
	dc.b	8,$18,0
	dc.b	8,$19,0
	dc.b	8,$1a,0
	dc.b	8,$1b,0
	dc.b	8,$1c,0
	dc.b	8,$1d,0
	dc.b	8,$1e,0
	dc.b	8,$1f,0
	dc.b	0,0,0



Colors:


	dcr.w	$0000,$5A94,$3148,$398A,$418C,$41CC,$49CC,$49CE
	dcr.w	$7316,$6AD4,$5210,$5A52,$2106,$6AD6,$6B18,$735A 



	dc.w	$0000,$FF7F,$9F7F,$5C7F,$5A73,$1873,$D66A,$946A
	dc.w	$5262,$1062,$CE59,$8C59,$4A51,$0A51,$C850,$8648 
 


	dc.w	$0000,$FF7F,$9F73,$5F6B,$5C63,$1C5B,$DA52,$9A4A
	dc.w	$5842,$1832,$D629,$9621,$5419,$1411,$D208,$9200 


	dc.w	$0000,$FF7F,$5A73,$946A,$1062,$4A59,$8450,$0048
	dc.w	$0000,$FF7F,$5C6B,$9A52,$1842,$5629,$9410,$1200 
 
 
      
;============================================================================
;                             Start of Unpacker
;============================================================================

unpack:



;=========================================================================
;                              The unpack routine
;=========================================================================

	php
	rep	#$30
	;lda	Crunch
	;clc
	;adc	#$0006
	;sta	Crunch
	
	jsr	Inc2Unpack
	jsr	Inc2Unpack
	jsr	Inc2Unpack

	lda	[Crunch]
	xba
	sta	LengthCrunch		; get length of crunched file
	;lda	Crunch
	;clc
	;adc	#$0002
	;sta	Crunch		; get start of crunched data

	jsr	Inc2Unpack

	
	ldy	#$0000		; offset for unpack ram
	sty	Unpackoffset


ReadControl:
	rep	#$30
	lda	[Crunch]

	and	#$007f		; get the control byte (what type of crunch)
	asl a
	tax
	jmp	(UnpackRouts,x)	; jump to that sub-routine

UnpackRouts:
	dcr.w	Nopack		
	dcr.w	EqualCharpack
	dcr.w	HiCharpack
	dcr.w	LoCharpack
;============================================================================
;                       No Packed Data Routine
;============================================================================



Nopack:	
	sep	#$20
	lda	[Crunch]
	;and	#$80		; is the data length in words?
	;beq	Nopack8
	bpl	Nopack8


	jsr	Inc1Unpack
	rep	#$30
	lda	[Crunch]
	xba			; it is, get the data length
	tax
	jsr	Inc2Unpack
	bra	Nopack2

Nopack8:
	jsr	Inc1Unpack	; get # of bytes to re-write

	rep	#$30
	lda	[Crunch]
	and	#$00ff		; get only 8 bits
	tax
	jsr	Inc1Unpack	; get address of data to re-write with

Nopack2:	
	ldy	Unpackoffset	; read the unpack offset

	sep	#$20
CopyNoPackBytes:
	lda	[Crunch]	; read the crunch byte
	sta	[EffectCrunch]
	sta	[RamCrunch],y	; store it in ram
	jsr	Inc1Unpack	; increase crunch address
	iny			; increase unpack offset
	sty	Unpackoffset
	cpy	LengthCrunch
	bne	Npack11
	jmp	Endpack
Npack11:
	dex			; decrease data number		
	bne	CopyNoPackBytes ; if not 0, then keep loop going
	;sty	Unpackoffset	; store new unpack offset
	;cpy	LengthCrunch	; is it the same as the unpacklength?
	;beq	Endpack		; if yes, then end
	;bcs	Endpack		; if higher, then end
	jmp	ReadControl	; nope, go back to Read Control for next instruction

;===========================================================================
;                   Equal Character Unpacker Routine
;===========================================================================

EqualCharpack:

	sep	#$20
	lda	[Crunch]
	;and	#$80		; is data length in words?
	;beq	Equalpack8
	bpl	Equalpack8

	jsr	Inc1Unpack
	rep	#$30
	lda	[Crunch]
	xba			; yes, get the data length
	tax
	jsr	Inc2Unpack
	bra	Equalpack2

Equalpack8:


	jsr	Inc1Unpack	; nope only 8 bits
	rep	#$30
	lda	[Crunch]
	and	#$00ff
	tax			; get the length
	jsr	Inc1Unpack	; increase crunched data address

Equalpack2:	
	ldy	Unpackoffset
	sep	#$20

	lda	[Crunch]	; get byte to unpack
CopyEqualCharbytes:
	sta	[EffectCrunch]
	sta	[RamCrunch],y	; store in ram
	iny			; increase unpack offset
	dex			; decrease byte unpack counter
	bne	CopyEqualCharbytes
	jsr	Inc1Unpack	; increase crunch address
	sty	Unpackoffset	; store unpack offset
	cpy	LengthCrunch	; compare with length of unpacked data
	beq	CopyEqualend	; if equal then end...
	;bcs	Endpack
	jmp	ReadControl	; not equal, get next instruction

CopyEqualend:
	jmp	Endpack



;==========================================================================
;                       Hi Nibble Compression
;==========================================================================

HiCharpack:

	sep	#$20
	lda	[Crunch]
	;and	#$80		; is the data length in words?
	;beq	Hicharpack8
	bpl	Hicharpack8

	jsr	Inc1Unpack
	rep	#$30
	lda	[Crunch]
	xba			; it is, get the data length
	tax
	jsr	Inc2Unpack
	bra	Hicharpack2

Hicharpack8:
	jsr	Inc1Unpack	; get # of bytes to re-write

	rep	#$30
	lda	[Crunch]
	and	#$00ff		; get only 8 bits
	tax
	jsr	Inc1Unpack	; get address of data to re-write with

Hicharpack2:	
	ldy	Unpackoffset	; read the unpack offset

	sep	#$20
	lda	[Crunch]
	sta	StoreCrunch	; store high nibble data!
	
	jsr	Inc1Unpack


CopyHiPackBytes:
	lda	[Crunch]	; read the crunch byte
	lsr a
	lsr a
	lsr a
	lsr a
	ora	StoreCrunch
	sta	[EffectCrunch]
	sta	[RamCrunch],y	; store it in ram
	;jsr	Inc1Unpack	; increase crunch address
	iny			; increase unpack offset
	dex			; decrease data number		
	beq	CopyHiPackBytes3 ; if not 0, then keep loop going
	lda	[Crunch]
	and	#$0f
	ora	StoreCrunch
	sta	[EffectCrunch]
	sta	[RamCrunch],y
	jsr	Inc1Unpack
	iny
	dex
	bne	CopyHiPackBytes
	bra	CopyHiPackBytes2
CopyHiPackBytes3:
	jsr	Inc1Unpack

CopyHiPackBytes2:
	sty	Unpackoffset	; store new unpack offset
	cpy	LengthCrunch	; is it the same as the unpacklength?
	beq	Endpack		; if yes, then end
	bcs	Endpack		; if higher, then end
	jmp	ReadControl	; nope, go back to Read Control for next instruction
	


;==========================================================================
;                       Lo Nibble Compression
;==========================================================================

LoCharpack:

	sep	#$20
	lda	[Crunch]
	;and	#$80		; is the data length in words?
	;beq	Locharpack8
	bpl	Locharpack8

	jsr	Inc1Unpack
	rep	#$30
	lda	[Crunch]
	xba			; it is, get the data length
	tax
	jsr	Inc2Unpack
	bra	Locharpack2

Locharpack8:
	jsr	Inc1Unpack	; get # of bytes to re-write

	rep	#$30
	lda	[Crunch]
	and	#$00ff		; get only 8 bits
	tax
	jsr	Inc1Unpack	; get address of data to re-write with

Locharpack2:	
	ldy	Unpackoffset	; read the unpack offset

	sep	#$20
	lda	[Crunch]
	sta	StoreCrunch	; store low nibble data!
	
	jsr	Inc1Unpack


CopyLoPackBytes:
	lda	[Crunch]	; read the crunch byte
	and	#$f0
	ora	StoreCrunch
	sta	[EffectCrunch]
	sta	[RamCrunch],y	; store it in ram
	;jsr	Inc1Unpack	; increase crunch address
	iny			; increase unpack offset
	dex			; decrease data number		
	beq	CopyLoPackBytes3 ; if not 0, then keep loop going
	lda	[Crunch]
	asl a
	asl a
	asl a
	asl a
	ora	StoreCrunch
	sta	[EffectCrunch]
	sta	[RamCrunch],y
	jsr	Inc1Unpack
	iny
	dex
	bne	CopyLoPackBytes
	bra	CopyLoPackBytes2
CopyLoPackBytes3:
	jsr	Inc1Unpack

CopyLoPackBytes2:
	sty	Unpackoffset	; store new unpack offset
	cpy	LengthCrunch	; is it the same as the unpacklength?
	beq	Endpack		; if yes, then end
	bcs	Endpack		; if higher, then end
	jmp	ReadControl	; nope, go back to Read Control for next instruction
	


Endpack:
	plp			; end of unpacker routine
	rts


Inc2Unpack:
	php
	rep	#$30
	lda	Crunch
	inc a
	inc a			; increase crunch address by 2
	sta	Crunch
	cmp	#$8000
	bcc	fixunpackaddy
	plp
	rts

Inc1Unpack:
	php
	rep	#$30
	lda	Crunch
	inc a			; increase Crunched data address by 1
	sta	Crunch
	cmp	#$8000
	bcc	fixunpackaddy
	plp
	rts	
fixunpackaddy:
	lda	Crunch
	clc
	adc	#$8000
	sta	Crunch
	inc	Crunch+2
	plp
	rts



logo:

	.bin	thing.pan
logoscreen:
	.bin	thing.dat.screen
font:
	.bin	scroll.pan
fontcolors:
	.bin	scroll.col

	org	$fffc	;reset vector in 6502 mode
	dcr.w	Start
	.pad

