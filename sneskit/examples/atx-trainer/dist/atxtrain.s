	heap	O=128k			;max 128k object buffer                
	size	4			;4 32kblocks                          
                                                                                  
	SMC+				;yes, we want a smc header            
	lrom				;yes, please split in 32k hunks       

UnpackBuffr     EQU     $7e8000
Buff2	EQU	$000200	; 24-bit address of $1A0 byte buffer
in	EQU	$65
out	EQU	$68
wrkbuf	EQU	$6a
counts	EQU	$6d
blocks	EQU	$4f
bitbufl	EQU	$51
bitbufh	EQU	$43
bufbits	EQU	$55
bitlen	EQU	$57
hufcde	EQU	$59
hufbse	EQU	$5b
temp1	EQU	$5d
temp2	EQU	$5f
temp3	EQU	$61
temp4	EQU	$63
tmptab	EQU	0	; indexed from Buff2
rawtab	EQU	$20	; indexed from Buff2
postab	EQU	$a0	; indexed from Buff2
slntab	EQU	$120	; indexed from Buff2
toggle	EQU	$1ffe
;==========================================================================
;      Code (c) 1993-94 -Pan-/ANTHROX   All code can be used at will!
;==========================================================================                     

	jmp	Slow
	;jmp	Cheat
	jmp	IRQ
	jmp	LEVEL
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
;==========================================================================

	rep	#$30
	sep	#$20
	lda	#$0f
	sta	$2100

	jsr	musique

	jsr	tune


	rep	#$30
	sep	#$20

	ldx	#$000f
Darken1:
	ldy	#$0005
Darken2:
	jsr	WaitVb
	dey
	bne	Darken2
	sep	#$30
	stx	$2100
	rep	#$30
	sep	#$20
	dex
	bne	Darken1




	rep	#$30
	sep	#$20
	jsr	Snes_Init	; Cool Init routine! use it in your own code!!

	rep     #$10		; X,Y fixed -> 16 bit mode
	sep     #$20		; Accumulator ->  8 bit mode


	jsr	Copy_Gfx	; Put graf-x in vram
	jsr	Copy_colors	; put colors into color ram
	jsr	Make_tiles	; set up the screen
	jsr	Sprite_Setup

	jsr	Option_Setup
	jsr	HDMA

	stz	$1ffe
	stz	$1fff

	

	ldx	#$0000
	stx	$1f00		; scroll text offset

	stx	$1f02		; scroll screen position

	stx	$1f04		; Joypad data storage

	ldx	#$0084
	stx	$1f06		; Options vertical scroll position

	ldx	#$0000
	stx	$1f08		; Option flag (is the option currently moving?)

	stx	$1f0a		; scroll direction: 0 = down; 1 = up

	stx	$1f0c		; second opt scroll timer

	stx	$1f0e		; ball Y sine offset

	stx	$1f10		; X ball position

	ldx	#$0001
	stx	$1f12		; X ball direction 0 = left; 1 = right

	ldx	#$0000
	stx	$1f14		; offset for ring

	stx	$1f16		; storage for X register counter
	
	stx	$1f18		; bend in progress flag; 1 = bending

	stx	$1f1a		; storage for address

	ldx	#$0000
	stx	$1f1c		; current option counter 

	lda	Number
	dec a	
	sta	$1f1e		; high # of options
	stz	$1f1f


	stx	$1f20		; storage for conversion of hex-> decimal
	stx	$1f22		;
	stx	$1f24		;  same as the above
	stx	$1f26		; same as above

	stx	$1f28		; put number here to be converted

	stx	$1f2a		; output of conversion
	stx	$1f2c		; output of conversion
	

	stx	$1f2e		; counter timer for Joypad presses

	ldx	#$00ff
	stx	$1f30		; fix for left most scroll y pos

	ldx	#$0007
	stx	$1f32		; timer for ball randomization

	ldx	#$0001
	stx	$1f34		; timer for selection bar fade

	ldx	#$0000
	stx	$1f36		; offset for color
	
	stx	$1f38		; offset for char anim
	
	stx	$1f3a		; offset for char color
	stx	$1f3c		; offset for background sine
	ldx	#$0001
	stx	$1f3e		; timer for char anim
	
	ldx	#$0000
	stx	$1f40		; storage for calculation of HDMAwave offset

	stx	$1f42		; first line offset

	ldx	#$0004
	stx	$1f44
	ldx	#$0008
	stx	$1f46
	ldx	#$000c
	stx	$1f48

	inx
	inx
	inx
	inx
	stx	$1f4a

	
	inx
	inx
	inx
	inx
	stx	$1f4c

	
	inx
	inx
	inx
	inx
	stx	$1f4e

	
	inx
	inx
	inx
	inx
	stx	$1f50


;===========================================================================
;                         Start of Core Program
;===========================================================================

Waitloop:
	lda	#$01
	sta	$4200
	jsr	WaitVb		; wait for vertical blank
	;jsr	Joypad
	lda	$1f05
	cmp	#$10
	bne	nevermind
	jmp	RESETMACHINE
nevermind:

	jsr	Optselect

	lda	#$03
	sta	$2105

	lda	#$04
	sta	$210d
	stz	$210d	

	lda	#$11		; Plane 1 enabled only
	sta	$212c

	lda	#$2c
	sta	$2107		; @ $2c00

	lda	#$00
	sta	$210b		; gfx at $0000
	stz	$210e
	stz	$210e


	;===================================================
	;  ^^^ Logo stuff ^^^                              ;
	;===================================================

	jsr	scroll
	jsr	ballbounce
	jsr	optmove
	jsr	Bend
	jsr	Charanim
	jsr	background
	;jsr	Joypad
	jsr	Selectcol
	lda	#$0f
	sta	$2100

	lda     #$21
        sta     $4200

        lda     #$57
        sta     $4209           ; wait for bottom of logo 
        stz     $420a

Waitvert:
        lda     $4211

Waitvert2:
        lda     $4211
        and     #$80
        beq     Waitvert2

	lda	#$10
	sta	$212c
	
	stz	$210d
	stz	$210d

	lda	$1f06
	sta	$210e
	stz	$210e


	lda	#$02
	sta	$2105

	lda	#$3c
	sta	$2107		; @ $3c00

	lda	#$73
	sta	$210b		; gfx at $0000

	
	lda	#$7c
	sta	$2108

	lda	#$74
	sta	$2109

Waithoriz:
	lda	$4212
	asl a
	bpl	Waithoriz

	ldx	$1f3c
	lda	backsine,x
	sta	$2110
	stz	$2110


	lda	#$13
	sta	$212c
	;===================================================
	;^^^^^  middle option text screen stuff
	;===================================================

	jsr	HDMAWAVE


	lda     #$21
        sta     $4200

        lda     #$a7
        sta     $4209           ; wait for bottom of options 
        stz     $420a


        lda     $4211

Waitvert3:
        lda     $4211
        and     #$80
        beq     Waitvert3


Waithoriz2:
	lda	$4212
	asl a
	bpl	Waithoriz2


	stz	$2110
	stz	$2110
	lda	#$10
	sta	$212c

	lda	$1f30
	sta	$210e
	stz	$210e

	lda	$1f02
	sta	$210d
	stz	$210d

	lda	#$02
	sta	$2105

	lda	#$41
	sta	$2107
	sta	$2109	; the data for sine bounce vram location

	lda	#$50
	sta	$2108


	lda	#$33
	sta	$210b


Waithoriz3:
	lda	$4212
	asl a
	bpl	Waithoriz3



	lda	#$13
	sta	$212c
	
	;=======================================================
	;^^^^^^^^^   scroll stuff!                             
	;=======================================================
	jsr	Joypad

	jmp	Waitloop	; constant loop



;==========================================================================
;                         Option Selection
;==========================================================================
Optselect:

	lda	$1f2e
	eor	#$01
	sta	$1f2e
	beq	OkOptSel
	rts

OkOptSel:

optmoveok:
	lda	$1f0c
	beq	OkOptSel2
	dec	$1f0c
	rts
OkOptSel2:
	lda	#$01
	sta	$1f0c
	lda	$1f05
	cmp	#$80
	beq	OptB
	cmp	#$02
	beq	OptB
	cmp	#$01
	beq	OptA
	lda	$1f04
	cmp	#$80
	beq	OptA
	rts

OptA:
	jmp	Incopt
OptB:
	jmp	Decopt

Incopt:
	ldx	$1f1c		; get current option line
	lda	Type,x
	beq	Textopt
	jmp	Numberopt
Textopt:
	lda	#$01
	sta	$1c00,x
	jmp	displayyn	

Numberopt:
	lda	$1c00,x
	cmp	Max,x
	bne	Incnumber
	rts
Incnumber:
	inc	$1c00,x
	lda	$1c00,x
PrintDec:
	sta	$1f28
	jsr	Hex2Dec

	rep	#$30
	lda	$1f1c
	asl a
	asl a
	asl a
	asl a
	asl a
	clc
	adc	#$3c18
	sta	$2116
	sep	#$20
	lda	$1f2a
	clc
	adc	#$10
	sta	$2118
	stz	$2119
	lda	$1f2b
	clc
	adc	#$10
	sta	$2118
	stz	$2119
	lda	$1f2c
	clc
	adc	#$10
	sta	$2118
	stz	$2119
	rts




Decopt:
	ldx	$1f1c		; get current option line
	lda	Type,x
	beq	Textopt1
	jmp	Numberopt1
Textopt1:
	lda	#$00
	sta	$1c00,x
	jmp	displayyn	

Numberopt1:
	lda	$1c00,x
	cmp	Min,x
	bne	Decnumber
	rts
Decnumber:
	dec	$1c00,x
	lda	$1c00,x
	sta	$1f28
	jsr	Hex2Dec

	rep	#$30
	lda	$1f1c
	asl a
	asl a
	asl a
	asl a
	asl a
	clc
	adc	#$3c18
	sta	$2116
	sep	#$20
	lda	$1f2a
	clc
	adc	#$10
	sta	$2118
	stz	$2119
	lda	$1f2b
	clc
	adc	#$10
	sta	$2118
	stz	$2119
	lda	$1f2c
	clc
	adc	#$10
	sta	$2118
	stz	$2119
	rts




displayyn:
	rep	#$30
	lda	$1f1c
	asl a
	asl a
	asl a
	asl a
	asl a
	clc
	adc	#$3c18
	sta	$2116
	sep	#$20
	lda	$1c00,x
	beq	TxtNo
	ldx	#$0000
copyyes:
	lda	YES,x
	sec
	sbc	#$20
	sta	$2118
	stz	$2119
	inx
	cpx	#$03
	bne	copyyes
	rts
TxtNo:
	ldx	#$0000
copyno:
	lda	NO,x
	sec
	sbc	#$20
	sta	$2118
	stz	$2119
	inx
	cpx	#$03
	bne	copyno
	rts


	
	
;=========================================================================
;                           Selection Background mover
;=========================================================================

background:
	ldx	#$7420
	stx	$2116
	rep	#$30
	lda	$1f3c
	tax
	inx
	sep	#$20
	ldy	#$0000
copybacksine:
	lda	backsine,x
	sta	$2118
	lda	#$c0
	sta	$2119
	inx
	iny
	cpy	#$20
	bne	copybacksine
	lda	$1f3c
	inc a
	and	#$3f
	sta	$1f3c
	rts
backsine:
	
 dc.b  32,35,38,41,44,47,50,52,55,57,59,60,62,63,63,64,64,64,63,63
 dc.b  62,60,59,57,55,52,50,47,44,41,38,35,32,29,26,23,20,17,14,12
 dc.b  9,7,5,4,2,1,1,0,0,0,1,1,2,4,5,7,9,12,14,17,20,23,26,29


	
 dc.b  32,35,38,41,44,47,50,52,55,57,59,60,62,63,63,64,64,64,63,63
 dc.b  62,60,59,57,55,52,50,47,44,41,38,35,32,29,26,23,20,17,14,12
 dc.b  9,7,5,4,2,1,1,0,0,0,1,1,2,4,5,7,9,12,14,17,20,23,26,29,32








;==========================================================================
;                            ball bouncer
;==========================================================================

ballbounce:

	stz	$2102
	stz	$2103

	ldx	$1f0e
	lda	$1f10
	sta	$2104
	lda	Ballsine,x
	inc a
	inc a
	sta	$2104
	inc	$1f0e
	inc	$1f0e


	dec	$1f32
	lda	$1f32
	bne	norandom
	
	ldx	$1f00
	lda	SCROLLTEXT,x
	and	#$1f
	clc
	adc	#$51
	sta	$1f32
	inc	$1f0e
	inc	$1f0e


norandom:
	lda	$1f12
	beq	ballleft
	inc	$1f10
	lda	$1f10
	cmp	#$e8
	beq	changedir
	rts	
changedir:
	lda	$1f12
	eor	#$01
	sta	$1f12
	rts
ballleft:
	dec	$1f10
	lda	$1f10
	cmp	#$08
	beq	changedir
	rts

;=========================================================================
;                              HDMA Color Wave
;=========================================================================

HDMAWAVE:
	ldx	#$0000
	txy
clearDMAcolor:
	stz	$1a1c,x
	stz	$1a1d,x
	inx
	inx
	inx
	iny
	cpy	#$2f
	bne	clearDMAcolor

	ldx	$1f42
	ldy	#$14a5
	jsr	drawline

	lda	$1f42
	inc a
	and	#$7f
	sta	$1f42

	ldx	$1f44
	ldy	#$2529
	jsr	drawline

	lda	$1f44
	inc a
	and	#$7f
	sta	$1f44


	ldx	$1f46
	ldy	#$35ad
	jsr	drawline

	lda	$1f46
	inc a
	and	#$7f
	sta	$1f46


	ldx	$1f48
	ldy	#$4631
	jsr	drawline

	lda	$1f48
	inc a
	and	#$7f
	sta	$1f48



	ldx	$1f4a
	ldy	#$5294
	jsr	drawline

	lda	$1f4a
	inc a
	and	#$7f
	sta	$1f4a



	ldx	$1f4c
	ldy	#$6318
	jsr	drawline

	lda	$1f4c
	inc a
	and	#$7f
	sta	$1f4c


	ldx	$1f4e
	ldy	#$739c
	jsr	drawline

	lda	$1f4e
	inc a
	and	#$7f
	sta	$1f4e



	ldx	$1f50
	ldy	#$7fff
	jsr	drawline

	lda	$1f50
	inc a
	and	#$7f
	sta	$1f50



	rts

drawline:
	rep	#$30
	lda	hdmasine,x
	and	#$00ff
	sta	$1f40		; storage
	asl a
	clc
	adc	$1f40
	tax
	tya
	sta	$1a1c,x
	sep	#$20
	rts


hdmasine:
	
 dc.b  0,0,0,0,0,0,1,1,1,1,1,2,2,2,3,3,4,4,5,5,6,6,7,7,8,9,9,10,11
 dc.b  11,12,13,14,15,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29
 dc.b  30,31,32,33,34,36,37,38,39,40,41,42,44,45,46

	dc.b	46,45,44,42,41,40,39,38,37,36,34,33,32,31,30,29,28,27,26,25,24,23,22
	dc.b	21,20,19,18,17,16,15,15,14,13,12,11,11,10,9,9,8,7,7,6,6,5,5,4,4,3,3
	dc.b	2,2,2,1,1,1,1,1,0,0,0,0,0,0


;=========================================================================
;                        Character Animation
;=========================================================================

Charanim:
	dec	$1f3e
	lda	$1f3e
	beq	Charanimation
	rts
Charanimation:
	lda	#$07
	sta	$1f3e
	rep	#$30
	lda	$1f38
	;asl a
	;asl a
	;asl a
	tax
	ldy	#$0008
	lda	#$7000
	sta	$2116
	;sep	#$20

	lda	Animoffset,x
	and	#$00ff
	asl a
	asl a
	asl a
	tax
	sep	#$20
copyCharanimGFX:
	lda	AnimGFX,x
	sta	$2118
	stz	$2119
	inx
	dey
	bne	copyCharanimGFX
	ldx	$1f38
	inx
	stx	$1f38
CheckAnimoff:
	ldx	$1f38
	lda	Animoffset,x
	cmp	#$fe
	beq	Changeanimcol
	cmp	#$ff
	beq	Fixcharoops
	rts
Fixcharoops:
	rep	#$30
	stz	$1f38
	sep	#$20
	rts

Changeanimcol:
	rep	#$30
	inc	$1f38
	sep	#$20
	lda	$1f3a
	inc a
	and	#$07
	sta	$1f3a
	rep	#$30
	lda	$1f3a
	asl a
	tax
	lda	AnimColors,x
	sta	$1a01
	sep	#$20
	jmp	CheckAnimoff

Animoffset:
	dc.b	0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,14,14,14,14,14,14,14
	dc.b	14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14
	dc.b	14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14
	dc.b	14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14
	dc.b	14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14
	dc.b	14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14
	dc.b	$fe,$ff
	
AnimColors:
	dcr.w	$01e0,$2312,$01DF,$4010,$7E68,$291C,$3666,$7D3D




AnimGFX:

;============================================================================
;= Cyber Font-Editor V1.4  Rel. by Frantic (c) 1991-1992 Sanity Productions =
;============================================================================
	; diamond


	dc.b	$00,$00,$00,$00,$08,$00,$00,$00	;' '
	dc.b	$00,$00,$00,$18,$18,$00,$00,$00	;'!'
	dc.b	$00,$00,$18,$3c,$3c,$18,$00,$00	;'"'
	dc.b	$00,$18,$3c,$7e,$7e,$3c,$18,$00	;'#'
	dc.b	$18,$3c,$7e,$ff,$ff,$7e,$3c,$18	;'$'
	dc.b	$3c,$7e,$ff,$ff,$ff,$ff,$7e,$3c	;'%'
	dc.b	$7e,$ff,$ff,$ff,$ff,$ff,$ff,$7e	;'&'
	dc.b	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff	;'''
	dc.b	$7e,$ff,$ff,$ff,$ff,$ff,$ff,$7e	;'('
	dc.b	$3c,$7e,$ff,$ff,$ff,$ff,$7e,$3c	;')'
	dc.b	$18,$3c,$7e,$ff,$ff,$7e,$3c,$18	;'*'
	dc.b	$00,$18,$3c,$7e,$7e,$3c,$18,$00	;'+'
	dc.b	$00,$00,$18,$3c,$3c,$18,$00,$00	;','
	dc.b	$00,$00,$00,$18,$18,$00,$00,$00	;'-'
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	;'.'
	


;==========================================================================
;                       Scroll Bend
;==========================================================================

Bend:
	lda	$1f18
	beq	okbendtest
	jmp	bendring

okbendtest:

	lda	$1f0e
	cmp	#$7a
	beq	Hitscroll
	cmp	#$7b
	beq	Hitscroll
	cmp	#$7c
	beq	Hitscroll
	rts
Hitscroll:
	rep	#$30
	lda	$1f10
	and	#$00ff
	lsr a
	lsr a
	lsr a
	clc
	adc	#$401b
	sta	$1f1a
	
	sep	#$20
	inc	$1f18
	rts

bendring:


	ldx	$1f1a
	stx	$2116
	ldx	#$0000
copybounce:
	lda	$1e00,x
	eor	#$ff
	sta	$2118
	lda	#$20
	sta	$2119
	inx
	cpx	#$09
	bne	copybounce
	
	ldx	#$401b
	stx	$2116

	stz	$2118
	stz	$2119
	stz	$2118
	stz	$2119
	stz	$2118
	stz	$2119
	stz	$2118
	stz	$2119
	stz	$2118
	stz	$2119


	ldx	$1f14		; current offset for ring

	lda	ring,x
	sta	$1f16
	
	ldx	$1f16
	ldy	#$0000

	lda	bounce1,x
	
	sta	$1e00
	lda	bounce2,x
	
	sta	$1e01
	lda	bounce3,x
	
	sta	$1e02
	lda	bounce4,x
	
	sta	$1e03
	lda	bounce5,x
	
	sta	$1e04
	lda	bounce6,x
	
	sta	$1e05
	lda	bounce7,x
	
	sta	$1e06
	lda	bounce8,x
	
	sta	$1e07
	lda	bounce9,x
	
	sta	$1e08


	ldx	$1f1a
	cpx	#$4020
	bcs	noborder
	
	
	ldx	$1f14		; current offset for ring

	lda	ring,x
	sta	$1f16
	
	ldx	$1f16
	lda     bounce4,x
	eor	#$ff
	sta	$1f30



noborder:

	inc	$1f14
	lda	$1f14
	cmp	#$38
	beq	resetring
	rts
resetring:
	stz	$1f14
	stz	$1f18
	rts


;==========================================================================
;                    Options Mover
;==========================================================================

optmove:
	lda	$1f08
	beq	optmoveok2		;0 = ok to select, >= in movement
	dec	$1f08
	lda	$1f0a
	beq	movesdown
	inc	$1f06
	rts
movesdown:
	dec	$1f06
	rts


optmoveok2:

	lda	$1f05			; read joypad data
	cmp	#$04
	beq	optup
	cmp	#$08
	beq	optdown
	rts
optup:
	jmp	optup2
optdown:
	jmp	optdown2
optup2:
	lda	$1f1c		; read current option
	cmp	$1f1e		; compare with # of options
	beq	sorrynogo

	lda	#$01
	sta	$1f0a		; direction is up
	lda	#$08
	sta	$1f08		; set the # of lines to scroll through
	inc	$1f1c		; increase # of current option
sorrynogo:
	rts
optdown2:

	lda	$1f1c
	beq	sorrynogo

	stz	$1f0a
	lda	#$08
	sta	$1f08
	lda	#$02
	sta	$1f0c
	dec	$1f1c
	rts
	


	

	




;==========================================================================
;                  Joypad Routine
;==========================================================================
Joypad:
	lda	$4212
	and     #$01  
	bne     Joypad
	
	ldx	$4218
	stx	$1f04
	rts

;==========================================================================
;             Scroll Routine
;==========================================================================

scroll:

	lda	$1f02
	inc a
	and	#$07
	sta	$1f02
	beq	scrollit
	rts
scrollit:
	ldx	#$42e0
	stx	$2116

	ldx	$1f00
	ldy	#$0000
copyscroll:
	lda	SCROLLTEXT,x
	beq	wrapscroll
	sec
	sbc	#$20
	sta	$2118
	lda	#$08
	sta	$2119
	inx
	iny
	cpy	#$0020
	bne	copyscroll
	lda	SCROLLTEXT,x
	sec
	sbc	#$20
	ldx	#$46e0
	stx	$2116
	sta	$2118
	lda	#$08
	sta	$2119
	ldx	$1f00
	inx
	stx	$1f00
	rts
	
wrapscroll:

	ldx	#$0000
	stx	$1f00
	bra	copyscroll




;=========================================================================
;                            Selection Bar Glow Routine
;=========================================================================


Selectcol:
	dec	$1f34
	beq	Selectglow
	rts
Selectglow:
	lda	#$02
	sta	$1f34
	rep	#$30
	lda	$1f36
	asl a
	tax
	lda	HDMACOLIST,x
	sta	$1a0d
	sep	#$20
	lda	$1f36
	inc a
	and	#$1f
	sta	$1f36
	rts


HDMACOLIST:


	;dcr.w	$0000,$0400,$0820,$0C20,$1040,$1460,$1860,$1C80
	;dcr.w	$1C80,$20A0,$24C0,$28C0,$2CE0,$3100,$3500,$3920 
	;dcr.w	$3920,$3500,$3100,$2CE0,$28C0,$24C0,$20A0,$1C80
	;dcr.w	$1C80,$1860,$1460,$1040,$0C20,$0820,$0400,$0000 

	;* BinCon (c)1992 by H.Bühler, Codex Design *

	dc.w	$0000,$0008,$0010,$0018,$0020,$0028,$0030,$0038
	dc.w	$0040,$0048,$0050,$0058,$0060,$0068,$0070,$007C 
 	dc.w	$007C,$0070,$0068,$0060,$0058,$0050,$0048,$0040
	dc.w	$0038,$0030,$0028,$0020,$0018,$0010,$0008,$0000
	;* 32 bytes from 'color' saved. *



;=========================================================================
;                         Hex to Decimal Conversion
;=========================================================================

Hex2Dec:

	;lda	#$8f
	;sta	$1f28		; number to be converted

	rep	#$30
	lda	$1f28
	and	#$000f
	asl a
	asl a
	tax
	sep	#$20
	inx
	inx
	inx
	lda	LOW,x
	sta	$1f22
	dex
	lda	LOW,x
	sta	$1f21
	dex
	lda	LOW,x
	sta	$1f20

	rep	#$30
	lda	$1f28
	and	#$00f0
	lsr a
	lsr a
	lsr a
	lsr a
	asl a
	asl a
	tax
	sep	#$20
	inx
	inx
	inx
	lda	HIGH,x
	sta	$1f26
	dex	
	lda	HIGH,x
	sta	$1f25
	dex
	lda	HIGH,x
	sta	$1f24

oneadd:
	lda	$1f26
	clc
	adc	$1f22
	cmp	#$0a
	bcs	onehigh
	stz	$1f2a
	sta	$1f2c
	bra	tenadd
onehigh:
	sec
	sbc	#$0a
	sta	$1f2c
	lda	#$01
	sta	$1f2a

tenadd:
	lda	$1f25
	clc
	adc	$1f21
	clc
	adc	$1f2a

	cmp	#$0a
	bcs	tenhigh
	stz	$1f2a
	sta	$1f2b
	bra	hundadd
tenhigh:
	sec	
	sbc	#$0a
	sta	$1f2b
	lda	#$01
	sta	$1f2a
	
hundadd:
	lda	$1f24
	clc
	adc	$1f20
	clc
	adc	$1f2a
	sta	$1f2a
	rts

;==========================================================================
;                            Option Setup Routine
;==========================================================================

Option_Setup:

	
	ldx	#$0000
clearopts:
	stz	$1c00,x
	inx
	cpx	#$0100
	bne	clearopts

	ldx	#$0000
SetOptRam:
	lda	Type,x
	bne	Numberthing
SetRamOpt:
	inx
	cpx	Number
	bne	SetOptRam
	jmp	thisthat

Numberthing:
	lda	Begin,x
	sta	$1c00,x
	bra	SetRamOpt


thisthat:

	
	ldx	#$0000
	stx	$1f1c
	
printopt:
	ldx	$1f1c
	lda	Type,x
	bne	numbtype
	jsr	displayyn
contOptram:
	ldx	$1f1c
	inx
	stx	$1f1c
	ldx	$1f1c
	cpx	Number
	bne	printopt
	rts
numbtype:
	
	ldx	$1f1c
	lda	$1c00,x
	jsr	PrintDec
	bra	contOptram

	




	





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
	ldx	#$0000		; Vram address $0000 (Mode 7 is always
	stx	$2116		; located at VRAM address 0
	ldx	#$0000
Clearvr:
	stz	$2118		; clear entire Vram
	stz	$2119
	inx
	cpx	#$0000		;
	bne	Clearvr

	rep	#$10
	sep	#$20
	ldx	#Picture		; CRUNCHED FILE
	stx	$65
	phk
	pla
	;lda	#^Picture1		; CRUNCHED FILE BANK
	sta	$67
	ldx	#UnpackBuffr		; LOW WORD UNPACK BUFFER
	stx	$68
	lda	#^UnpackBuffr		; UNPACK BUFFER BANK
	pha
	plb
	jsr	UNPACK				;Requires A[8] XY[16]

	phk
	plb

	rep	#$30
	sep	#$20

	ldx	#$0000
	stx	$2116
	
copylogogfx:
	lda	>$7e8000,x
	sta	$2118
	inx
	lda	>$7e8000,x
	sta	$2119
	inx
	cpx	#$5800
	bne	copylogogfx



	rep	#$10
	sep	#$20
	ldx	#Charset		; CRUNCHED FILE
	stx	$65
	phk
	pla
	;lda	#^Picture1		; CRUNCHED FILE BANK
	sta	$67
	ldx	#UnpackBuffr		; LOW WORD UNPACK BUFFER
	stx	$68
	lda	#^UnpackBuffr		; UNPACK BUFFER BANK
	pha
	plb
	jsr	UNPACK				;Requires A[8] XY[16]

	phk
	plb

	rep	#$30
	sep	#$20




	ldx	#$3000
	stx	$2116
	ldx	#$0000
copychardata:
	lda	>$7e8000,x
	sta	$2118
	inx
	lda	>$7e8000,x
	sta	$2119
	inx
	cpx	#$0c00
	bne	copychardata



	rep	#$10
	sep	#$20
	ldx	#Spritedata		; CRUNCHED FILE
	stx	$65
	phk
	pla
	;lda	#^Picture1		; CRUNCHED FILE BANK
	sta	$67
	ldx	#UnpackBuffr		; LOW WORD UNPACK BUFFER
	stx	$68
	lda	#^UnpackBuffr		; UNPACK BUFFER BANK
	pha
	plb
	jsr	UNPACK				;Requires A[8] XY[16]

	phk
	plb

	rep	#$30
	sep	#$20


	ldx	#$6000
	stx	$2116
	ldx	#$000
copyspritegfx:
	lda	>$7e8000,x
	sta	$2118
	inx
	lda	>$7e8000,x
	sta	$2119
	inx
	cpx	#$080
	bne	copyspritegfx

	ldx	#$6100
	stx	$2116
	ldx	#$0080
copyspritegfx2:
	lda	>$7e8000,x
	sta	$2118
	inx
	lda	>$7e8000,x
	sta	$2119
	inx
	cpx	#$0100
	bne	copyspritegfx2



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

	lda	#$80
	sta	$2121
	ldx	#$0000
Copsprtcol:
	lda	Spritecol,x
	sta	$2122
	inx
	cpx	#$0020
	bne	Copsprtcol
	rts
;==========================================================================
;                      Make Tiles
;==========================================================================

Make_tiles:
	ldx	#$2c01
	stx	$2116
	rep	#$30
	lda	#$0000
drawlogotiles:
	sta	$2118
	inc a
	cmp	#$0160
	bne	drawlogotiles
	sep	#$20

	ldx	#$3c00
	stx	$2116
	ldx	#$0000
copyoptiontext:
	lda	OPTTEXT,x
	sec
	sbc	#$20
	sta	$2118
	lda	#$0c
	sta	$2119
	inx
	cpx	#$0400
	bne	copyoptiontext




	ldx	#$4020
	stx	$2116
	ldx	#$0000
setbounce:
	lda	#$ff
	sta	$2118
	lda	#$20
	sta	$2119
	inx
	cpx	#$0020
	bne	setbounce

	ldx	#$5320
	stx	$2116
	
	ldx	#$0000
CopyMyRight
	lda	Copyright,x
	eor	#$54
	sec
	sbc	#$20
	sta	$2118
	lda	#$14
	sta	$2119
	inx
	cpx	#$0020
	bne	CopyMyRight


	ldx	#$7c00
	stx	$2116
	ldx	#$0000
copymiddlebkack:
	stz	$2118
	lda	#$18
	sta	$2119
	inx
	cpx	#$0400
	bne	copymiddlebkack


	rts


Copyright:
		;********************************
	dc.b	$74,$74,$74,$74,$74,$74,$1D,$3A,$20,$26,$3B,$74,$17,$3B,$30,$31
	dc.b	$74,$16,$2D,$74,$79,$04,$35,$3A,$79,$74,$74,$74,$74,$74,$74,$74





;==========================================================================
;                              Sprite Setup Routine
;==========================================================================

Sprite_Setup:
	lda	#$03
	sta	$2101
	stz	$2102
	stz	$2103
	ldx	#$0000
sprtclear:
	lda	#$00
	sta	$2104		; Horizontal position
	lda	#$e0
	sta	$2104		; Vertical position
	lda	#$00
	sta	$2104		; sprite object = 0
	lda	#%00110000
	sta	$2104		; pallete = 0, priority = %11, h;v flip = 0
	inx
	cpx	#$0080		; (128 sprites)
	bne	sprtclear
	ldx	#$0000
sprtdataclear:
	stz	$2104		; clear H-position 
	stz	$2104		; and make size large
	inx
	cpx	#$0020		; 32 extra bytes for sprite data
				; info
	bne	sprtdataclear

	ldx	#$0100
	stx	$2102
	lda	#%00000010
	sta	$2104

	stz	$2102
	stz	$2103
	stz	$2104
	lda	#$c0
	sta	$2104
	lda	#$02
	sta	$2104
	lda	#%00110000
	sta	$2104


	rts











;==========================================================================
;                     Start of HDMA routine
;==========================================================================

HDMA:

	lda	#$00
	sta	$4300
	lda	#$21
	sta	$4301
	ldx	#HDMAPALLETE
	stx	$4302
	phk
	pla
	sta	$4304

      

	lda     #$02                                                     
	sta     $4310           ; 2= 2 bytes per register (not a word!)  
	lda     #$22                                                     
	sta     $4311           ; 21xx   this is 2122                    
	ldx     #$1a00                                                     
	stx     $4312                                                         
	stz     $4314           ; bank address of data in ram


	ldx	#$0000
BackupHCol:
	lda	HDMACOLORS,x
	sta	$1a00,x
	inx
	cpx	#$0200
	bne	BackupHCol


	jsr	WaitVb

	lda	#%00000011
	sta	$420c		; STA!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	rts

HDMACOLORS:
	dc.b	$1,$e0,$01
	dc.b	$55,$00,$00
	dc.b	$01,$ff,$ff
	dc.b	$24,$00,$00
	dc.b	$08,$80,$30
	dc.b	$01,$00,$00
	dc.b	$23,$00,$00
	dc.b	$01,$ff,$ff
	dc.b	$01,$00,$00


	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00

	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	

	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	;dc.b	$01,$00,$00

	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	;dc.b	$01,$00,$00

	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	;dc.b	$01,$00,$00

	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	dc.b	$01,$00,$00
	;dc.b	$01,$00,$00


	dc.b	$00,$00,$00

HDMAPALLETE:
	dc.b	$1,$61
	dc.b	$55,$00
	dc.b	$01,$00
	dc.b	$24,$00
	dc.b	$08,$00
	dc.b	$01,$00
	dc.b	$23,$00
	dc.b	$01,$00
	dc.b	$01,$00

	dc.b	$01,$00
	dc.b	$01,$00
	dc.b	$01,$00
	dc.b	$01,$00	;1
	dc.b	$01,$00
	dc.b	$01,$00
	dc.b	$01,$00
	dc.b	$01,$00

	dc.b	$01,$00
	dc.b	$01,$00
	dc.b	$01,$00
	dc.b	$01,$00
	dc.b	$01,$00	;2
	dc.b	$01,$00
	dc.b	$01,$00
	dc.b	$01,$00

	dc.b	$01,$00
	dc.b	$01,$00
	dc.b	$01,$00
	dc.b	$01,$00
	dc.b	$01,$00	;3
	dc.b	$01,$00
	dc.b	$01,$00
	dc.b	$01,$00


	dc.b	$01,$00
	dc.b	$01,$00
	dc.b	$01,$00
	dc.b	$01,$00
	dc.b	$01,$00	;4
	dc.b	$01,$00
	dc.b	$01,$00
	dc.b	$01,$00


	dc.b	$01,$00
	dc.b	$01,$00
	dc.b	$01,$00
	dc.b	$01,$00
	dc.b	$01,$00	;5
	dc.b	$01,$00
	dc.b	$01,$00
	dc.b	$01,$00


	dc.b	$01,$00
	dc.b	$01,$00
	dc.b	$01,$00
	dc.b	$01,$00
	dc.b	$01,$00	;6
	dc.b	$01,$00
	dc.b	$01,$00
	dc.b	$01,$00


	dc.b	$00,$00


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

;===========================================================================
;                         Start Of Unpack Routine
;===========================================================================

;---------------------------------------------------------
; PRO-PACK Unpack Source Code - Super NES, Method 1
;
; Copyright (c) 1992 Rob Northen Computing
;
; File: RNC_1.S
;
; Date: 9.03.92
;---------------------------------------------------------
;---------------------------------------------------------
; Unpack Routine - Super NES, Method 1
;
; To unpack a packed file (in any data bank) to an output
; buffer (in any data bank) Note: the packed and unpacked
; files are limited to 65536 bytes in length.
;
; To call (assumes 16-bit accumulator)
;
;
; On exit,
;
; A, X, Y undefined, M=0, X=0
;---------------------------------------------------------
;---------------------------------------------------------
; Equates
;---------------------------------------------------------


;---------------------------------------------------------
UNPACK	rep	#$39	; 16-bit AXY, clear D and C
	lda	#Buff2
	sta	wrkbuf
	lda	#^Buff2
	sta	wrkbuf+2
	lda	#17
	adc	in
	sta	in
	lda	[in]
	and	#$00ff
	sta	blocks
	inc	in
	lda	[in]
	sta	bitbufl
	stz	bufbits
	lda	#2
	jsr	gtbits
unpack2	ldy	#rawtab
	jsr	makehuff
	ldy	#postab
	jsr	makehuff
	ldy	#slntab
	jsr	makehuff
	lda	#16
	jsr	gtbits
	sta	counts
	jmp	unpack8
unpack3	ldy	#postab
	jsr	gtval
	sta	temp2
	lda	out
	clc
	sbc	temp2
	sta	temp3
	ldy	#slntab
	jsr	gtval
	inc	a
	inc	a
	lsr	a
	tax
	ldy	#0
	lda	temp2
	bne	unpack5
	sep	#$20	; 8-bit accumulator
	lda	(temp3),y
	xba
	lda	(temp3),y
	rep	#$20	; 16-bit accumulator
unpack4	sta	(out),y
	iny
	iny
	dex
	bne	unpack4
	bra	unpack6
unpack5	lda	(temp3),y
	sta	(out),y
	iny
	iny
	dex
	bne	unpack5
unpack6	bcc	unpack7
	sep	#$20	; 8-bit accumulator
	lda	(temp3),y
	sta	(out),y
	iny
	rep	#$21	; 16-bit accumulator, clear carry
unpack7	tya
	adc	out
	sta	out
unpack8	ldy	#rawtab
	jsr	gtval
	tax
	beq	unpack14
	ldy	#0
	lsr	a
	beq	unpack10
	tax
unpack9	lda	[in],y
	sta	(out),y
	iny
	iny
	dex
	bne	unpack9
unpack10	bcc	unpack11
	sep	#$20	; 8-bit accumulator
	lda	[in],y
	sta	(out),y
	rep	#$21	; 16-bit accumulator, clear carry
	iny
unpack11	tya
	adc	in
	sta	in
	tya
	adc	out
	sta	out
	stz	bitbufh
	lda	bufbits
	tay
	asl	a
	tax
	lda	[in]
	cpy	#0
	beq	unpack13
unpack12	asl	a
	rol	bitbufh
	dey
	bne	unpack12
unpack13	sta	temp1
	phb
	phk
	plb
	lda	msktab,x		;>
	plb
	and	bitbufl
	ora	temp1
	sta	bitbufl
unpack14	dec	counts
	beq	.Mark1
	jmp	unpack3
.Mark1	dec	blocks
	beq	.Mark2
	jmp	unpack2
.Mark2	rts
;-----------------------------------------------------------
gtval	ldx	bitbufl
	bra	gtval3
gtval2	iny
	iny
gtval3	txa
	and	[wrkbuf],y
	iny
	iny
	cmp	[wrkbuf],y
	bne	gtval2
	tya
	adc	#(15*4+1)
	tay
	lda	[wrkbuf],y
	pha
	xba
	and	#$ff
	jsr	gtbits
	pla
	and	#$ff
	cmp	#2
	bcc	gtval4
	dec	a
	asl	a
	pha
	lsr	a
	jsr	gtbits
	plx
	phb
	phk
	plb
	ora	bittab,x		;>
	plb
gtval4	rts
bittab	dcr.w	1
	dcr.w	2
	dcr.w	4
	dcr.w	8
	dcr.w	$10
	dcr.w	$20
	dcr.w	$40
	dcr.w	$80
	dcr.w	$100
	dcr.w	$200
	dcr.w	$400
	dcr.w	$800
	dcr.w	$1000
	dcr.w	$2000
	dcr.w	$4000
	dcr.w	$8000
;-----------------------------------------------------------
gtbits	tay
	asl	a
	tax
	phb
	phk
	plb
	lda	msktab,x		;>
	plb
	and	bitbufl
	pha
	lda	bitbufh
	ldx	bufbits
	beq	gtbits3
gtbits2	lsr	a
	ror	bitbufl
	dey
	beq	gtbits4
	dex
	beq	gtbits3
	lsr	a
	ror	bitbufl
	dey
	beq	gtbits4
	dex
	bne	gtbits2
gtbits3	inc	in
	inc	in
	lda	[in]
	ldx	#16
	bra	gtbits2
gtbits4	dex
	stx	bufbits
	sta	bitbufh
	pla
gtbits5	rts
msktab	dcr.w	0
	dcr.w	1
	dcr.w	3
	dcr.w	7
	dcr.w	$f
	dcr.w	$1f
	dcr.w	$3f
	dcr.w	$7f
	dcr.w	$ff
	dcr.w	$1ff
	dcr.w	$3ff
	dcr.w	$7ff
	dcr.w	$fff
	dcr.w	$1fff
	dcr.w	$3fff
	dcr.w	$7fff
	dcr.w	$ffff
;-----------------------------------------------------------
makehuff	sty	temp4
	lda	#5
	jsr	gtbits
	beq	gtbits5
	sta	temp1
	sta	temp2
	ldy	#0
makehuff2	phy
	lda	#4
	jsr	gtbits
	ply
	sta	[wrkbuf],y
	iny
	iny
	dec	temp2
	bne	makehuff2
	stz	hufcde
	lda	#$8000
	sta	hufbse
	lda	#1
	sta	bitlen
makehuff3	lda	bitlen
	ldx	temp1
	ldy	#0
makehuff4	cmp	[wrkbuf],y
	bne	makehuff8
	phx
	sty	temp3
	asl	a
	tax
	phb
	phk
	plb
	lda	msktab,x		;>
	plb
	ldy	temp4
	sta	[wrkbuf],y
	iny
	iny
	lda	#16
	sec
	sbc	bitlen
	pha
	lda	hufcde
	sta	temp2
	ldx	bitlen
makehuff5	asl	temp2
	ror	a
	dex
	bne	makehuff5
	plx
	beq	makehuff7
makehuff6	lsr	a
	dex
	bne	makehuff6
makehuff7	sta	[wrkbuf],y
	iny
	iny
	sty	temp4
	tya
	clc
	adc	#(15*4)
	tay
	lda	bitlen
	xba
	sep	#$20	; 8-bit accumulator
	lda	temp3
	lsr	a
	rep	#$21	; 16-bit accumulator, clear carry
	sta	[wrkbuf],y
	lda	hufbse
	adc	hufcde
	sta	hufcde
	lda	bitlen
	ldy	temp3
	plx
makehuff8	iny
	iny
	dex
	bne	makehuff4
	lsr	hufbse
	inc	bitlen
	cmp	#16
	bne	makehuff3
	rts



;============================================================================
;                            Start of Graf-x Data
;============================================================================


Colors:
	;.bin	pic1.col

	dcr.w	$0000,$7737,$6EF3,$6671,$5E2E,$55CC,$4D8A,$4548
	dcr.w	$3906,$38C4,$3084,$2842,$2042,$1800,$1000,$0800
	dcr.w	$7FFF,$673B,$56B7,$4635,$3191,$294E,$294C,$210A
	dcr.w	$18C8,$0886,$0044,$0042,$6739,$6F7B,$77BD,$7FFF 

	;.bin	gold.col
* BinCon (c)1992 by H.Bühler, Codex Design *

	dcr.w	$01C0,$0A02,$1245,$1A88,$22EA,$2B2D,$3370,$3BD2
	dcr.w	$42F3,$4B13,$5333,$5B73,$6393,$6BB3,$73D3,$0000
 
* 32 bytes from 'shit.col' saved. *


	
	.bin	blue.col

	

	dcr.w	$0,$01e0,$1245,$1A88,$22EA,$2B2D,$3370,$3BD2
	dcr.w	$42F3,$4B13,$5333,$5B73,$6393,$6BB3,$73D3,$0000

	.bin	gold.col
 
	dcr.w	$0,$0095



Picture:
	.bin	pic1.rnc
Charset:
	.bin	char.rnc
Spritedata:
	.bin	ball.rnc
Spritecol:
	.bin	ball.col

Ballsine:
	
 dc.b  0,0,0,0,0,0,0,1,1,1,1,2,2,2,3,3,3,4,4,5,5,6,6,7,8,8,9,10,10
 dc.b  11,12,13,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,30
 dc.b  31,32,33,35,36,37,39,40,41,43,44,46,47,49,50,52,53,55,56,58
 dc.b  59,61,63,64,66,68,69,71,73,75,76,78,80,82,84,86,87,89,91,93
 dc.b  95,97,99,101,103,105,107,109,111,113,115,117,119,121,123,125
 dc.b  127,129,131,133,135,137,140,142,144,146,148,150,152,154,157
 dc.b  159,161,163,165,167,170,172

 dc.b  172,170,167,165,163,161,159,157,154,152,150,148,146,144,142,140,137
 dc.b  135,133,131,129,127,125,123,121,119,117,115,113,111,109,107,105,103
 dc.b  101,99,97,95,93,91,89,87,86,84,82,80,78,76,75,73,71,69,68,66,64,63
 dc.b  61,59,58,56,55,53,52,50,49,47,46,44,43,41,40,39,37,36,35,33,32,31
 dc.b 30,28,27,26,25,24,23,22,21,20,19,18,17,16,15,14,13,13,12,11,10,10
 dc.b 9,8,8,7,6,6,5,5,4,4,3,3,3,2,2,2,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0



;bounce1:	dc.b	0,0,0,0,0,0,0,1,1,1,1
;bounce2:	dc.b	0,0,0,0,0,1,1,2,2,2,2
;bounce3:	dc.b	0,0,0,1,1,2,2,3,3,3,3
;bounce4:	dc.b	0,0,1,2,2,3,3,4,4,4,4
;bounce5:	dc.b	0,1,2,3,3,4,4,5,5,5,5
;bounce6:	dc.b	0,0,1,2,2,3,3,4,4,4,4
;bounce7:	dc.b	0,0,0,1,1,2,2,3,3,3,3
;bounce8:	dc.b	0,0,0,0,0,1,1,2,2,2,2
;bounce9:	dc.b	0,0,0,0,0,0,0,1,1,1,1

bounce1:	dc.b	0,0,0,0,0,0,0,1,1,1,1
bounce2:	dc.b	0,0,0,0,0,1,1,2,2,2,2
bounce3:	dc.b	0,0,0,1,1,2,2,3,3,4,5
bounce4:	dc.b	0,0,1,2,3,3,4,4,5,6,7
bounce5:	dc.b	0,1,2,3,3,4,5,6,7,8,8
bounce6:	dc.b	0,0,1,2,3,3,4,4,5,6,7
bounce7:	dc.b	0,0,0,1,1,2,2,3,3,4,5
bounce8:	dc.b	0,0,0,0,0,1,1,2,2,2,2
bounce9:	dc.b	0,0,0,0,0,0,0,1,1,1,1

ring:	dc.b	0,1,2,3,4,5,6,7,8,9,$a
	dc.b	9,8,7,6,5,4,3,2,1,0,1
	dc.b	2,3,4,5,6,7,8,7,6,5,4
	dc.b	3,2,1,0,1,2,3,4,5,4,3
	dc.b	2,1,0,1,0,1,2,3,2,1,0
	dc.b	1,0
	

YES:	dc.b	"YES"

NO:
	dc.b	"NO "

LOW:
	dc.b	0,0,0,0
	dc.b	0,0,0,1
	dc.b	0,0,0,2
	dc.b	0,0,0,3
	dc.b	0,0,0,4
	dc.b	0,0,0,5
	dc.b	0,0,0,6
	dc.b	0,0,0,7
	dc.b	0,0,0,8
	dc.b	0,0,0,9
	dc.b	0,0,1,0
	dc.b	0,0,1,1
	dc.b	0,0,1,2
	dc.b	0,0,1,3
	dc.b	0,0,1,4
	dc.b	0,0,1,5
	
HIGH:
	dc.b	0,0,0,0
	dc.b	0,0,1,6
	dc.b	0,0,3,2
	dc.b	0,0,4,8
	dc.b	0,0,6,4
	dc.b	0,0,8,0
	dc.b	0,0,9,6
	dc.b	0,1,1,2
	dc.b	0,1,2,8
	dc.b	0,1,4,4
	dc.b	0,1,6,0
	dc.b	0,1,7,6
	dc.b	0,1,9,2
	dc.b	0,2,0,8
	dc.b	0,2,2,4
	dc.b	0,2,4,0


RESETMACHINE:

	jsr	Snes_Init
	rep	#$30
	sep	#$20
	ldx	#$0000
copyallopts:
	lda	$1c00,x
	sta	>$708000,x
	inx
	cpx	#$0100
	bne	copyallopts

	jsr	tuneoff

	sep	#$30
	lda	#$00
	pha
	plb
	dc.b	$5c,$00,$f4,$00		; jump to game




OPTTEXT:
		;********************************
	
	dc.b	"    Slow Rom Fix:       Yes     "
	dc.b	"    Unlimited Lives:    Yes     "
	dc.b	"    Unlimited Health:   Yes     "
	dc.b	"    Invincibility:      Yes     "
	dc.b	"    Unlimited Credits:  Yes     "
	dc.b	"    Start at Level:     001     "
	dc.b	"                                "
	dc.b	"                                "
	dc.b	"                                "
	dc.b	"                                "
	dc.b	"                                "
	dc.b	"                                "
	dc.b	"                                "
	dc.b	"                                "
	dc.b	"                                "
	dc.b	"                                "
	dc.b	"                                "
	dc.b	"                                "
	dc.b	"                                "
	dc.b	"                                "
	dc.b	"                                "
	dc.b	"                                "
	dc.b	"                                "
	dc.b	"                                "
	dc.b	"                                "
	dc.b	"                                "
	dc.b	"                                "
	dc.b	"                                "
	dc.b	"        Bobby's World +5        "
	dc.b	"     Trained by -Pan- & TWK     "
	dc.b	"      Sound by The Doctor       "
	dc.b	"                                "
	dc.b	"                                "
	dc.b	"                                "
	dc.b	"                                "
	dc.b	"                                "
	dc.b	"                                "	
	

SCROLLTEXT:
	dc.b	"                                "
	dc.b	" -Pan- presents another kickin' trainer "
	dc.b	"on October 10, 1994        "
	dc.b	"    A few small hellos to: "
	dc.b	"Censor, Nightfall, Premiere, Accumulators, "
	dc.b	"Cyber Force,  Mystic..      "
	dc.b	"To order copiers call 718-630-9869!        "
	dc.b	" Wild Card DX arrives THIS WEEK! YA!!      "
	dc.b	"           "
	dc.b	" -Pan-                  "
	dc.b	"                                ",0


Number:
	dcr.w	6		; number of options

Options:
		; 0 = yes/no ; 1 = number
Type:
	dc.b	0,0,0,0,0,1,1,1,0

Min:	
	dc.b	1,0,1,1,0,1,1,1,1

Max:
	dc.b	9,5,5,5,5,5,$a,8,5

Begin:
	dc.b	2,4,4,1,0,1,1,1,3


Slow:
	php
	sep	#$30
	dc.b	$af,$00,$80,$70
	and	#$01
	eor	#$01
	sta	$420d
	plp
	rtl




Cheat:
	dc.b	$ad,$18,$42
	dc.b	$85,$7a
	pha
	php
	sep	#$30
	dc.b	$af,$01,$80,$70
	beq	Livesoff
	lda	#$09
	sta	$1da1
	sta	$1da3
Livesoff:
	dc.b	$af,$02,$80,$70
	beq	Damage
	lda	#$0a
	sta	$1d09
	sta	$1d0b

Damage:
	;dc.b	$af,$03,$80,$70
	;beq	noammo
	;lda	#$99
	;sta	$1096
noammo:
	dc.b	$af,$03,$80,$70
	beq	nohyper
	lda	#$01
	sta	$1db1
	sta	$1db3

nohyper:
	dc.b	$af,$04,$80,$70
	beq	nothingy
	lda	#$01
	dc.b	$8f,$e0,$65,$7e
nothingy:
	;dc.b	$af,$05,$80,$70
	;beq	nojumpy
	;rep	#$30
	;dc.b	$a5,$7a
	;cmp	#$2020
	;bne	nojumpy
	;stz	$7a
	;sep	#$20
	;stz	$1e05

nojumpy:
	sep	#$20
	
	plp
	pla
	rtl
Time1:

	php
	sep	#$20
	dc.b	$af,$03,$80,$70
	beq	timeoff
	plp
	dc.b	$5c,$ab,$89,$01
	rtl
timeoff:
	plp
	dc.b	$a9,$e5,$04
	dc.b	$85,$e9
	dc.b	$5c,$9f,$89,$01
	;rtl
LEVEL:
	php
	rep	#$30
	dc.b	$af,$05,$80,$70
	dec a
	dc.b    $8f,$ff,$ff,$70
	and	#$00ff
	asl a
	clc
	adc	>$70ffff
	and	#$00ff
	sta	>$7e137b
	plp
	rtl

leveljunk:
	dc.b	0,3,6,9,$c

IRQ:
	pha
	php
	sep	#$20
	dc.b	$af,$01,$80,$70
	beq	IRQtime
	lda	#$03
	sta	>$7e1395
IRQtime:
	dc.b	$af,$02,$80,$70
	beq	IRQmoney
	lda	#$03
	sta	>$7e139b
	sta	>$7e139d
IRQmoney:
	dc.b	$af,$03,$80,$70
	beq	IRQcreds
	lda	#$78
	sta	>$7e1b05
IRQcreds:
	dc.b	$af,$04,$80,$70
	beq	IRQend
	lda	#$03
	sta	>$7e1397

IRQend:
	plp
	pla
	dc.b	$5c,$f7,$f4,$00

MOFF	equ	$0200	;stop music 
MBONUS	equ	$0201	;timer bonus countdown
MCHEAT	equ	$0202	;cheat mode enabled
MCLICK	equ	$0203	;button click
MOVER	equ	$0204	;game over/time up
MTRING	equ	$0205	;tring for startup of the wildcard
MSOLVED	equ	$0206	;puzzle solved tune
MTUNE	equ	$0207	;New tune....
MWINDOW	equ	$0208	;Open selection window
MSELECT	equ	$0209	;Move cursor up and down
MRESET	equ	$0400	; reset the music controller

tune	rep #$30
	lda #MTUNE
	jsr NewSound_l
	sep #$20
 	rts

tuneoff:
	rep	#$30
	lda	#MRESET
	jsr	NewSound_l
	sep	#$20
	rts


	rep 	#$30
NewSound_l 
	ora	toggle 
	sta	$2140 
	lda	toggle 
	eor	#$0100 
	sta	toggle 
	rts


musique:
 	sep	#$20
	phb
	pla
	inc a
	sta $a5 
	lda #>music 
	sta $a4 
	lda #<music
	sta $a3 
 
	php       
	rep     #$30  
	ldy     #$0000  
	lda     #$bbaa  
L00f7b6 cmp     $2140 
	bne     L00f7b6  
	sep     #$20  
	lda     #$cc  
	bra     L00f7f5 
L00f7c1 lda     [$a3],y  
	iny       
	bpl     L00f7cb		; check for bank overflow 
	ldy     #$0000 		; if so, zero y 
	inc     $a5		; and inc work reg bank 
L00f7cb xba       
	lda     #$00  
	bra     L00f7e2 
L00f7d0 xba       
	lda     [$a3],y  
	iny       
	bpl     L00f7db    	; check for bank overflow 
	ldy     #$0000		; if so, zero y 
	inc     $a5 		; and inc work reg bank 
L00f7db xba       
L00f7dc cmp     $2140 
	bne     L00f7dc  
	inc     a  
L00f7e2 rep     #$20  
	sta     $2140 
	sep     #$20  
	dex       
	bne     L00f7d0  
L00f7ec cmp     $2140 
	bne     L00f7ec  
L00f7f1 adc     #$03  
	beq     L00f7f1  
L00f7f5 pha       
	rep     #$20  
	lda     [$a3],y  
	iny       
	iny       
	tax       
	lda     [$a3],y  
	iny       
	iny       
	sta     $2142 
	sep     #$20  
	cpx     #$0001  
	lda     #$00  
	rol     a  
	sta     $2141 
	adc     #$7f  
	pla       
	sta     $2140 
L00f815 cmp     $2140 
	bne     L00f815  
	bvs     L00f7c1  
	plp       
	sep     #$30  
	rts       


	;org	$c000


	org	$fffc	;reset vector in 6502 mode
	dcr.w	Start
	.pad

music:
	.bin	delta.bin
	.pad
	;org	$2c000
