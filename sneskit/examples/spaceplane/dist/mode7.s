	heap	O=1024k			;max 128k object buffer                
	size	4			;4 32kblocks                          
                                                                                  
	SMC+				;yes, we want a smc header            
	lrom				;yes, please split in 32k hunks       

Storage		equ	$1100
Storage2	equ	Storage+2
Storage3	equ	Storage2+2
HDMAoffset	equ	Storage3+2
HDMAoffset2	equ	HDMAoffset+2

HDMAdis1	equ	HDMAoffset2+2
HDMAdis2	equ	HDMAdis1+2
blendrightoffset	equ	HDMAdis2+2
blendleftoffset		equ	blendrightoffset+2
HDMAdis3	equ	blendleftoffset+2
HDMAdis4	equ	HDMAdis3+2
blendbrightoffset	equ	HDMAdis4+2
blend2130		equ	blendbrightoffset+2
blend2131		equ	blend2130+2
blendflip		equ	blend2131+2
blendflip2		equ	blendflip+2
blendbitsoffset		equ	blendflip2+2
	
;==========================================================================
;      Code (c) 1993-94 -Pan-/ANTHROX   All code can be used at will!
;==========================================================================                     


Start:  
	phk			; Put current bank on stack
	plb			; make it current programming bank
				; if this program were used as an intro
				; and it was located at bank $20 then an
				; LDA $8000 would actually read from
				; $008000 if it were not changed!
				; JSRs and JMPs work fine, but LDAs do not! 
	clc			; Clear Carry flag
	xce			; Native 16 bit mode  (no 6502 Emulation!) 
	REP #$30  

	

 
	LDA #$1FFF 
	TCS        
	LDA #$0000 
	TCD

;==========================================================================
	jsr	Snes_Init	; Cool Init routine! use it in your own code!!



	rep	#$30

	ldx	#$0000
	
	lda	#$0000

clearall:

	;sta	>$7e0000,x
	;sta	>$7f0000,x
	inx
	inx
	bne	clearall

	rep     #$10		; X,Y fixed -> 16 bit mode
	sep     #$20		; Accumulator ->  8 bit mode

	lda	#$07		; mode 0, 8/8 dot
	sta	$2105	
	lda	#$01		; Mode 7 Plane Enabled
	sta	$212c
	lda	#$00		; area outside of mode-7 screen
	sta	$211a		; is color 0  (you can change it to
				; repetition of screen or place a single
				; character throughout)


	lda	#$33		; planes 0-3 uses Window 1
	sta	$2123
	stz	$2134

	lda	#$c3		; Color window uses window 2
	sta	$2125		; Obj window uses window 1
	
	lda	#$00		; window 1 start
	sta	$2126
	lda	#$ff		; window 1 end
	sta	$2127

	lda	#$00		; window 2 start
	sta	$2128
	lda	#$a0		; Window 2 end
	sta	$2129

	lda	#$0c		; Color Window Logic 0 = or
	sta	$212b		; 4 =and , 8 = xor, c = xnor

	lda	#%11111		; Main screen mask belongs to obj, and planes
	sta	$212e		; same with subscreen
	lda	#$00
	sta	$212f

	lda	#$00		; sub screen window, effect happens INSIDE
	sta	$2130		; window	; 30 = turn effect OFF
						; 20 = turn effect on in window
		;  1				; 00 = on ALWAYS
	lda	#%10101111	; Color addition
 	sta	$2131		; add,not 1/2 bright, back, no obj, bg0-3

	lda	#%10100111	; blue off, green on, red off
	sta	$2132		; lowest 5 bits = brightness
	


	jsr	Copy_Gfx	; Put graf-x in vram
	jsr	Copy_colors	; put colors into color ram
	jsr	Make_tiles	; set up the screen


	rep	#$30
	sep	#$20

	ldx	#$0000
	stx	$1000		; Matrix A offset
	stx	$1002		; Matrix B offset
	stx	$1004		; Matrix C offset
	stx	$1006		; Matrix D offset
	ldx	#$0080
	stx	$1008		; X center coordinate position
	ldx	#$0070
	stx	$100a		; Y center coordinate position

	ldx	#$0000		; dummy vram address for copying text to
	stx	$100c		; vram


	stx	$100e		; counter for text copy
	
	ldx	#$0000		; change this to move entire screen X
	stx	$1010		; horizontal screen position
	ldx	#$0000		; change this to move entire screen Y
	stx	$1012		; vertical screen position
	
	ldx	#sine1		; read address of SINE data and store it
	stx	$10
	stx	$12		; store it again

	ldx	#$0100
	stx	$1014		; offset for COS data (Matrix A)
	ldx	#$0000		;
	stx	$1016		; offset for SIN data (Matrix B)
	ldx	#$0200		; 
	stx	$1018		; offset for -SIN data (Matrix C)
	ldx	#$0100		; 
	stx	$101a		; offset for COS data (Matrix D)

	ldx	#$0000
	stx	$101c		; clear controller 1 data

	stz	$101e		; Spin on/off flag (0=spin)

	ldx	#$0000
	stx	HDMAoffset
	stx	HDMAoffset2
	stx	HDMAdis1
	stx	HDMAdis2
	stx	HDMAdis3
	stx	HDMAdis4
	stx	blendrightoffset
	stx	blendleftoffset
	stx	blendbrightoffset
	stx	blendflip
	stx	blendflip2
	ldx	#$0003
	stx	blendbitsoffset

	ldx	#$0000
	stx	blend2130
	ldx	#%10101111
	stx	blend2131

	jsr	HDMAmover2
	jsr	HDMA
	
	lda	$1008
	sta	$211f
	lda	$1009	; X center co-ordinate
	sta	$211f

	lda	$100a
	sta	$2120
	lda	$100b	; Y center co-ordinate
	sta	$2120

	lda	#$01
	sta	$4200







	lda	#$0f
	sta	$2100		; turn the screen on
Waitloop:
	jsr	WaitVb		; wait for vertical blank
	
	jsr	Joypad
	jsr	Mode7
	jsr	HDMAmover
	jsr	Colorblend
	bra	Waitloop	; constant loop


;============================================================================
;                    Blend Color Change Effect Routine
;============================================================================
Colorblend:
	
	rep	#$30
	sep	#$20


	
	lda	blendflip2
	eor	#$ff
	sta	blendflip2
	beq	blendotherhalf
	rts

blendotherhalf:

	ldx	blendbrightoffset
	lda	blendbright,x
	ldx	blendbitsoffset
	ora	blendbits,x
	sta	$2132
	lda	blendbrightoffset
	inc a
	and	#$3f
	sta	blendbrightoffset
	beq	blend2131flip
	rts
blend2131flip:
	lda	blend2131
	eor	#$80
	sta	blend2131
	sta	$2131

	lda	blendflip
	eor	#$ff
	sta	blendflip
	beq	blendotherhalf2
	rts

blendotherhalf2:
	
	lda	blendbitsoffset
	inc a
	and	#$03
	sta	blendbitsoffset
	rts
	
blendbright:

	dc.b	0,1,2,3,4,5,6,7,8,9,$a,$b,$c,$d,$e,$f,$10,$11,$12,$13,$14,$15
	dc.b	$16,$17,$18,$19,$1a,$1b,$1c,$1d,$1e,$1f,$1f,$1e,$1d,$1c,$1b,$1a
	dc.b	$19,$18,$17,$16,$15,$14,$13,$12,$11,$10,$f,$e,$d,$c,$b,$a,$9,$8
	dc.b	$7,$6,$5,$4,$3,$2,$1,0
blendbits:
	dc.b	%00100000,%00000000,%10000000,%10100000
	
	

;============================================================================
;                    Start HDMA routine to setup plane on/off HDMA
;============================================================================


HDMAmover:
	rep	#$30
	sep	#$20

	ldx	HDMAdis1
	inx
	cpx	#$0200
	bne	HDMAdis1ok
	ldx	#$0000
HDMAdis1ok:
	stx	HDMAdis1

	ldx	HDMAdis2
	inx
	inx
	cpx	#$0200
	bne	HDMAdis2ok
	ldx	#$0000
HDMAdis2ok:
	stx	HDMAdis2



	rep	#$30
	lda	HDMAdis1
	asl a
	clc
	adc	HDMAdis1
	sta	Storage

	lda	Storage
	clc
	adc	#$0000
	sta	$4302
	sta	$4322

	lda	HDMAdis2
	asl a
	clc
	adc	HDMAdis2
	sta	Storage

	lda	Storage
	clc
	adc	#$5000
	sta	$4312


	rts




;========================================================================
;                        Sets up HDMA tables in ram
;========================================================================

HDMAmover2:
	rep	#$30
	sep	#$20

	ldy	#$0000
	sty	Storage

	ldx	HDMAoffset
	stx	Storage2



CopyHDMAcolse:

	ldx	Storage
	lda	#$01
	sta	>$7f0000,x		; length of bar
	inx
	stx	Storage
	
	ldx	Storage2
	lda	sine1,x		; first byte of color
	inx
	stx	Storage2
	
	ldx	Storage
	sta	>$7f0000,x		
	inx
	stx	Storage
	
	
	ldx	Storage2
	lda	sine1,x		; second byte of color
	inx
	stx	Storage2
	
	ldx	Storage
	sta	>$7f0000,x
	inx
	stx	Storage
	
	ldx	HDMAoffset
	inx
	inx
	inx
	inx
	cpx	#$0400
	bne	noresetHDMAoffsete
	ldx	#$0000
noresetHDMAoffsete:
	stx	HDMAoffset


	iny
	cpy	#$1800
	bne	CopyHDMAcolse



	ldy	#$0000
	sty	Storage
	ldx	HDMAoffset2
	stx	Storage2

CopyHDMAcols2f:
	ldx	Storage
	lda	#$01
	sta	>$7f5000,x		; length of bar
	inx
	stx	Storage
	
	ldx	Storage2
	lda	sine1,x		; first byte of color
	inx
	stx	Storage2
	
	ldx	Storage
	sta	>$7f5000,x		
	inx
	stx	Storage
	
	
	ldx	Storage2
	lda	sine1,x		; second byte of color
	inx
	stx	Storage2
	
	ldx	Storage
	sta	>$7f5000,x
	inx
	stx	Storage


	
	ldx	HDMAoffset2
	inx
	inx
	;inx
	;inx
	cpx	#$0400
	bne	noresetHDMAoffsetf
	ldx	#$0000
noresetHDMAoffsetf:
	stx	HDMAoffset2


	iny
	cpy	#$1800
	bne	CopyHDMAcols2f


	rts
;===========================================================================
;                    HDMA setup routine
;===========================================================================
HDMA:

	lda	#$02
	sta	$4300		; 0= 1 byte per register (not a word!)
	lda	#$1c
	sta	$4301		; 21xx   this is 211b (Matrix A)
	ldx	#$0000		; the address of where it's located
	stx	$4302
	lda	#$7f	
	sta	$4304		; bank address of data in ram

	lda	#$02
	sta	$4310
	lda	#$1d		; Matrix B
	sta	$4311
	ldx	#$5000		; the colors will be at $7f8000!!
	stx	$4312
	lda	#$7f
	sta	$4314

	lda	#$02
	sta	$4320		; 0= 1 byte per register (not a word!)
	lda	#$1b
	sta	$4321		; 21xx   this is 211b (Matrix A)
	ldx	#$0000		; the address of where it's located
	stx	$4322
	lda	#$7f
	sta	$4324		; bank address of data in ram

	jsr	WaitVb
	lda	#%0000111
	sta	$420c

	rts

;===========================================================================
;                        Start Of Joypad Routine
;===========================================================================

Joypad:
	lda	$4212		; test if it's ok to read pad
	and	#$01
	bne	Joypad		; nope, go back!
	lda	$4219		; read Controller 1
	bit	#$20
	bne	yayjoy
	rts
yayjoy:
	and	#$0f
	cmp	#$09
	bcc	yay08
	lda	#$08
yay08
	sta	Storage
	stz	Storage+1
	rep	#$30
	sep	#$20
	rts


;===========================================================================
;                     Start Of Mode 7 Routine
;===========================================================================


Mode7:
	ldy	$1000	; get sine offset spin
	;rep	#$20	; A = 16 bit
	;lda	$10	; get address of sine data
	;clc
	;adc	$1014	; add Matrix A offset
	;sta	$12
	;lda	($12),y	; read 16 bit word of COS data
	;sep	#$20	; A = 8 bit
	;sta	$211b	; store first 8 bit into Matrix A register
	;xba		; exchange bytes (like swap) to get the other 8 bits
	;sta	$211b	; store it

	;rep	#$20	; A = 16 bit
	;lda	$10	; get address of sine data
	;clc
	;adc	$1016	; add Matrix B offset
	;sta	$12
	;lda	($12),y	; read 16 bit word of SIN data
	;sep	#$20	; A = 8 bit
	;sta	$211c	; store into Matrix B register
	;xba		; swap lo-hi bytes
	;sta	$211c	; store it 

	;rep	#$20	; A = 16 bit
	;lda	$10	; get address of sine data
	;clc
	;adc	$1018	; add Matrix C offset
	;sta	$12
	;lda	($12),y	; read 16 bit word of -SIN data
	;sep	#$20	; A = 8 bit 
	;sta	$211d	; store into Matrix C register
	;xba		; swap lo-hi bytes
	;sta	$211d	; store it

	rep	#$20	; A = 16 bit
	lda	$10	; get address of sine data
	clc
	adc	$101a	; add Matrix D offset
	sta	$12
	lda	($12),y	; read 16 bit word of COS data
	sep	#$20	; A = 8 bit
	sta	$211e	; store into Matrix D register
	xba		; swap lo-hi bytes
	sta	$211e	; store it


	lda	$1008	;8
	sta	$211F
	lda	$1009	; X center co-ordinate
	sta	$211F

	lda	$100a	; a
	sta	$2120
	lda	$100b	; Y center co-ordinate
	sta	$2120

	lda	$1010
	sta	$210d
	lda	$1011   ; X screen position
	sta	$210d

	lda	$1012
	sta	$210e
	lda	$1013	; Y screen position
	sta	$210e

	lda	$101e
	beq	Spinsine
	rts
Spinsine:
	rep	#$20
	lda	$1000
	clc
	adc	#$0002
	cmp	#$0400
	bne	noclear
	lda	#$0000
noclear:
	sta	$1000
	sep	#$20
	rts




;==========================================================================
;                        Vertical Blank Wait Routine
;==========================================================================
WaitVb:	
	lda	$4210
	bpl     WaitVb	
WaitVb2:
	lda	$4210
	bmi	WaitVb2
	rts

;==========================================================================
;       	     SETUP ROUTINES FOR PROGRAM
;==========================================================================

;==========================================================================
;                         Copy graf-x data
;==========================================================================

Copy_Gfx:
	ldx	#$0000		; Vram address $0000 (Mode 7 is always
	stx	$2116		; located at VRAM address 0
	ldx	#$0000
Clearvr:
	stz	$2118		; clear entire Vram
	stz	$2119
	inx
	cpx	#$0000		;
	bne	Clearvr

	ldx	#$0000
	stx	$2116
	lda	#$3f
	ldy	#$0000
copychars:
	sta	$2119		;  
	iny
	cpy	#$0040
	bne	copychars	; set up plasma gfx
	ldy	#$0000
	dec a
	and	#$3f
	inx			;  
	cpx	#$0040		;  
	bne	copychars
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
	rep	#$10
	stz	$2115		; putting #$00 into $2115 will
	ldx	#$0000		; increase the VRAM address when writing
	stx	$2116		; to $2118
	ldx	#$0000
	stx	Storage
	stx	Storage2
clearscreen:
	ldy	Storage
	lda	Plasmascreen,y
	sta	$2118		;
				;   Draw Plasma tiles
	inc	Storage

	lda	Storage2
	inc a
	and	#$7f
	sta	Storage2
	bne	NoIncPlasma
	lda	Storage
	and	#$7f
	inc a
	sta	Storage
NoIncPlasma:
	inx			;
	cpx	#$4000		;   Mode 7 uses a 128*128 tile screen
	bne	clearscreen	;   128*128 = 16384 = $4000


	rts


Plasmascreen:
	dc.b	0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63
	dc.b	63,62,61,60,59,58,57,56,55,54,53,52,51,50,49,48,47,46,45,44,43,42,41,40,39,38,37,36,35,34,33,32,31,30,29,28,27,26,25,24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0
	
	dc.b	0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63
	dc.b	63,62,61,60,59,58,57,56,55,54,53,52,51,50,49,48,47,46,45,44,43,42,41,40,39,38,37,36,35,34,33,32,31,30,29,28,27,26,25,24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0
	
	dc.b	0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63
	dc.b	63,62,61,60,59,58,57,56,55,54,53,52,51,50,49,48,47,46,45,44,43,42,41,40,39,38,37,36,35,34,33,32,31,30,29,28,27,26,25,24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0
	
	dc.b	0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63
	dc.b	63,62,61,60,59,58,57,56,55,54,53,52,51,50,49,48,47,46,45,44,43,42,41,40,39,38,37,36,35,34,33,32,31,30,29,28,27,26,25,24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0
	
	

;==========================================================================
;                    SNES Register Initialization Routine
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

;===========================================================================
;                         Start Of Sine Data
;===========================================================================

sine1:


 dcr.w  128,131,134,137,140,144,147,150,153,156,159,162,165,168,171
 dcr.w  174,177,179,182,185,188,191,193,196,199,201,204,206,209,211
 dcr.w  213,216,218,220,222,224,226,228,230,232,234,235,237,239,240
 dcr.w  241,243,244,245,246,248,249,250,250,251,252,253,253,254,254
 dcr.w  254,255,255,255,255,255,255,255,254,254,254,253,253,252,251
 dcr.w  250,250,249,248,246,245,244,243,241,240,239,237,235,234,232
 dcr.w  230,228,226,224,222,220,218,216,213,211,209,206,204,201,199
 dcr.w  196,193,191,188,185,182,179,177,174,171,168,165,162,159,156
 dcr.w  153,150,147,144,140,137,134,131,128,125,122,119,116,112,109
 dcr.w  106,103,100,97,94,91,88,85,82,79,77,74,71,68,65,63,60,57,55
 dcr.w  52,50,47,45,43,40,38,36,34,32,30,28,26,24,22,21,19,17,16,15
 dcr.w  13,12,11,10,8,7,6,6,5,4,3,3,2,2,2,1,1,1,1,1,1,1,2,2,2,3,3,4
 dcr.w  5,6,6,7,8,10,11,12,13,15,16,17,19,21,22,24,26,28,30,32,34,36
 dcr.w  38,40,43,45,47,50,52,55,57,60,63,65,68,71,74,77,79,82,85,88
 dcr.w  91,94,97,100,103,106,109,112,116,119,122,125


 dcr.w  128,131,134,137,140,144,147,150,153,156,159,162,165,168,171
 dcr.w  174,177,179,182,185,188,191,193,196,199,201,204,206,209,211
 dcr.w  213,216,218,220,222,224,226,228,230,232,234,235,237,239,240
 dcr.w  241,243,244,245,246,248,249,250,250,251,252,253,253,254,254
 dcr.w  254,255,255,255,255,255,255,255,254,254,254,253,253,252,251
 dcr.w  250,250,249,248,246,245,244,243,241,240,239,237,235,234,232
 dcr.w  230,228,226,224,222,220,218,216,213,211,209,206,204,201,199
 dcr.w  196,193,191,188,185,182,179,177,174,171,168,165,162,159,156
 dcr.w  153,150,147,144,140,137,134,131,128,125,122,119,116,112,109
 dcr.w  106,103,100,97,94,91,88,85,82,79,77,74,71,68,65,63,60,57,55
 dcr.w  52,50,47,45,43,40,38,36,34,32,30,28,26,24,22,21,19,17,16,15
 dcr.w  13,12,11,10,8,7,6,6,5,4,3,3,2,2,2,1,1,1,1,1,1,1,2,2,2,3,3,4
 dcr.w  5,6,6,7,8,10,11,12,13,15,16,17,19,21,22,24,26,28,30,32,34,36
 dcr.w  38,40,43,45,47,50,52,55,57,60,63,65,68,71,74,77,79,82,85,88
 dcr.w  91,94,97,100,103,106,109,112,116,119,122,125


 dcr.w  128,131,134,137,140,144,147,150,153,156,159,162,165,168,171
 dcr.w  174,177,179,182,185,188,191,193,196,199,201,204,206,209,211
 dcr.w  213,216,218,220,222,224,226,228,230,232,234,235,237,239,240
 dcr.w  241,243,244,245,246,248,249,250,250,251,252,253,253,254,254
 dcr.w  254,255,255,255,255,255,255,255,254,254,254,253,253,252,251
 dcr.w  250,250,249,248,246,245,244,243,241,240,239,237,235,234,232
 dcr.w  230,228,226,224,222,220,218,216,213,211,209,206,204,201,199
 dcr.w  196,193,191,188,185,182,179,177,174,171,168,165,162,159,156
 dcr.w  153,150,147,144,140,137,134,131,128,125,122,119,116,112,109
 dcr.w  106,103,100,97,94,91,88,85,82,79,77,74,71,68,65,63,60,57,55
 dcr.w  52,50,47,45,43,40,38,36,34,32,30,28,26,24,22,21,19,17,16,15
 dcr.w  13,12,11,10,8,7,6,6,5,4,3,3,2,2,2,1,1,1,1,1,1,1,2,2,2,3,3,4
 dcr.w  5,6,6,7,8,10,11,12,13,15,16,17,19,21,22,24,26,28,30,32,34,36
 dcr.w  38,40,43,45,47,50,52,55,57,60,63,65,68,71,74,77,79,82,85,88
 dcr.w  91,94,97,100,103,106,109,112,116,119,122,125


 dcr.w  128,131,134,137,140,144,147,150,153,156,159,162,165,168,171
 dcr.w  174,177,179,182,185,188,191,193,196,199,201,204,206,209,211
 dcr.w  213,216,218,220,222,224,226,228,230,232,234,235,237,239,240
 dcr.w  241,243,244,245,246,248,249,250,250,251,252,253,253,254,254
 dcr.w  254,255,255,255,255,255,255,255,254,254,254,253,253,252,251
 dcr.w  250,250,249,248,246,245,244,243,241,240,239,237,235,234,232
 dcr.w  230,228,226,224,222,220,218,216,213,211,209,206,204,201,199
 dcr.w  196,193,191,188,185,182,179,177,174,171,168,165,162,159,156
 dcr.w  153,150,147,144,140,137,134,131,128,125,122,119,116,112,109
 dcr.w  106,103,100,97,94,91,88,85,82,79,77,74,71,68,65,63,60,57,55
 dcr.w  52,50,47,45,43,40,38,36,34,32,30,28,26,24,22,21,19,17,16,15
 dcr.w  13,12,11,10,8,7,6,6,5,4,3,3,2,2,2,1,1,1,1,1,1,1,2,2,2,3,3,4
 dcr.w  5,6,6,7,8,10,11,12,13,15,16,17,19,21,22,24,26,28,30,32,34,36
 dcr.w  38,40,43,45,47,50,52,55,57,60,63,65,68,71,74,77,79,82,85,88
 dcr.w  91,94,97,100,103,106,109,112,116,119,122,125







Colors:


	dcr.w	$0180,$01C0,$05E0,$0600,$0A20,$0E40,$1280,$12A0
	dcr.w	$16C0,$1AE0,$1F00,$2720,$2B60,$2F80,$37A0,$3BC0

	dcr.w	$43E0,$47A0,$4B60,$4F20,$52E0,$56A0,$5A60,$5E20
	dcr.w	$61C0,$6580,$6940,$6D00,$70C0,$7480,$7840,$7C00

	dcr.w	$7442,$6C84,$64C6,$5D08,$554A,$4D8C,$45CE,$4210
	dcr.w	$3A31,$3273,$2AB5,$22F7,$1B39,$137B,$0BBD,$03FF

	dcr.w	$03BF,$037F,$033F,$02FF,$02BF,$027F,$023F,$021F
	dcr.w	$01DF,$019F,$015F,$011F,$00DF,$009F,$005F,$001F


	org	$fffc	;reset vector in 6502 mode
	dcr.w	Start
	.pad
