	heap	O=512k			;max 128k object buffer                
	size	8			;4 32kblocks                          
                                                                                  
	SMC+				;yes, we want a smc header            
	lrom				;yes, please split in 32k hunks 
      


cosangle	equ	$0200
sinangle	equ	cosangle+2
storage1	equ	sinangle+2
storage2	equ	storage1+2
storage3	equ	storage2+2
cosangle2	equ	storage3+2
sinangle2	equ	cosangle2+2
starcosangle	equ	sinangle2+2
starsinangle	equ	starcosangle+2
stardirection	equ	starsinangle+2
startoggle	equ	stardirection+2
startoggle2	equ	startoggle+2
atxsine		equ	startoggle2+2
atxlogodelay	equ	atxsine+2
scrollval  	equ	atxlogodelay+2
scrolltext 	equ	scrollval+2
scrollcount	equ	scrolltext+2
scrollcol	equ	scrollcount+2
scrollstorage1	equ	scrollcol+2
scrollstorage2	equ	scrollstorage1+2
xstorage1	equ	scrollstorage2+2
xstorage2	equ	xstorage1+2
xstorage3	equ	xstorage2+2
xstorage4	equ	xstorage3+2
sineoffset	equ	xstorage4+2
joydata		equ	sineoffset+2
linecounter	equ	joydata+2
linedelay	equ	linecounter+2
storage4	equ	linedelay+2
signx		equ	storage4+2
signy		equ	signx+2
sign		equ	signy+2
storage5	equ	sign+2

x2table		equ	$0800
z2table		equ	$0900
starxtable	equ	$0a00
starxtable2	equ	starxtable+64
starytable	equ	starxtable2+64
starytable2	equ	starytable+64
starztable	equ	starytable2+64
starx2table	equ	starztable+64
stary2table	equ	starx2table+64
hdma210d	equ	stary2table+64
hdma2107	equ	hdma210d+10
hdma210f	equ	hdma2107+10
HDMALINES	equ	hdma210f+20



;==========================================================================
;      Code (c) 1995 -Pan-/ANTHROX   All code can be used at will!
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
;==========================================================================
	




	jsr	Snes_Init


	rep	#$30
	sep	#$20
	jsr	Copy_Gfx
	jsr	Make_tiles
	jsr	Copy_colors
	jsr	Sprite_setup
	jsr	setupstars
	jsr	HDMA
	

	lda	#$01
	sta	$2105
	
	lda	#$17
	sta	$212c
	
	lda	#$05
	sta	$210b

	lda	#$06
	sta	$210c

	lda	#$11
	sta	$2108

	lda	#$68
	sta	$2109

	

	lda	#$03
	sta	$2110
	stz	$2110

	lda	#$fe
	sta	$2112
	stz	$2112

	ldx	#$0000
	stx	sinangle
	ldx	#$0040
	stx	cosangle

	ldx	#$0040
	stx	cosangle2
	ldx	#$0000
	stx	sinangle2

	ldx	#$0040
	stx	starcosangle
	ldx	#$0000
	stx	starsinangle
	
	ldx	#$0000
	stx	stardirection
	ldx	#$00ff
	stx	startoggle2
	ldx	#$0000
	stx	startoggle   

	ldx	#$00bf
	stx	atxsine

	ldx	#$0001
	stx	atxlogodelay

	ldx	#$0090
	stx	scrollval
	lda	#$0010
	stx	scrollcount
 
	ldx	#$0000
	stx	scrolltext

	ldx	#$000f
	stx	scrollcol

	ldx	#$1000
	stx	scrollstorage1
	stx	scrollstorage2
	ldx	#$0000
	stx	sineoffset





	jsr	logomotion
	jsr	WaitVb

	lda	#$01
	sta	$4200

	lda	#$0f
	sta	$2100

Waitloop:
	jsr	WaitVb
	;lda	#$00
	;sta	$212c
	jsr	spriteDMA
	jsr	scroll
	jsr	logomotion
	jsr	joypad

	jsr	scrollsquish


	jsr	rotation1
	jsr	rotation2

	jsr	tablepri
	jsr	tablepri2
	jsr	starz
	jsr	starrotate
	jsr	starrottoggle


	inc	cosangle
	inc	cosangle

	inc	sinangle
	inc	sinangle


	dec	cosangle2
	dec	cosangle2
	
	dec	sinangle2
	dec	sinangle2



	;lda	#$10
	;sta	$212c

	lda	joydata+1
	and	#$10
	bne	endtheintro

	bra	Waitloop

endtheintro:
	jsr	WaitVb
	jsr	Snes_Init
	rep	#$30
	sep	#$20
	lda	#$01
	sta	$4200
	jsr	Copy_colors2
	jsr	HDMA2
	lda	#$01
	sta	$2105
	lda	#$02
	sta	$210b
	lda	#$30
	sta	$2107
	lda	#$01
	sta	$212c

	ldx	#$0300
	stx	linecounter

	ldx	#$0000
	stx	linedelay



	lda	#$0f
	sta	$2100

Waitagain:
	sep	#$20
	jsr	WaitVb
	rep	#$30
	lda     #HDMALINES
	clc
	adc	linecounter
	sta     $4302         

	lda	linedelay
	eor	#$0001
	sta	linedelay
	bne	Waitagain


	lda	linecounter
	sec
	sbc	#$03
	sta	linecounter
	bne	Waitagain

	sep	#$20

Waitagain2:
	jsr	WaitVb	

	bra	Waitagain2


;==========================================================================
;                          Joypad Routine
;==========================================================================

joypad:
	;lda	$4212
	;and	#$01
	;beq	joypad
joypad2:
	lda	$4212
	and	#$01
	bne	joypad2

	ldx	$4218
	stx	joydata
	rts


;=========================================================================
;                      Plane 1 HDMA swing left/right
;=========================================================================
scrollsquish:


	sep	#$20
	inc	sineoffset		; increase sine offset ($00 - $ff)



	rep	#$30

	ldx	#$0010
	stx	xstorage1

	
	ldx	#$0000
	
	lda	sineoffset
	sta	xstorage2
	asl a
	tay




hdmaswish:
	inx			 

	
	lda	xstorage2
	asl a
	tay

	lda	vsine,y
	clc
	adc	scrollval
			 
	sta	hdma210f+3,x
	
	inc	xstorage2

	inx			 
	inx
	dec	xstorage1
	bne	hdmaswish

	sep	#$20
	rts




;==========================================================================
;                              Scroll Routine
;==========================================================================

scroll:
	rep	#$30
	sep	#$20

	ldx	scrollval
	inx
	inx
	stx	scrollval

	dec	scrollcount
	dec	scrollcount
	lda	scrollcount
	beq	scrollok
	rts

scrollok:

	lda	#$10
	sta	scrollcount

	lda	scrollcol
	inc a			; increase scroll column
	and	#$1f
	sta	scrollcol


	rep	#$30
	lda	scrollcol
	and	#$000f
	asl a
	clc
	adc	#$11a0
	sta	scrollstorage1

	lda	scrollcol
	and	#$0010
	bne	eq400

	lda	scrollstorage1	
	sta	scrollstorage2		; the address
	bra	not400

eq400:
	lda	scrollstorage1
	clc
	adc	#$0400
	sta	scrollstorage2

not400:
	ldx	scrolltext
	lda	scrtxt,x
	and	#$00ff
	bne	noresetscroll
	ldx	#$0000
	stx	scrolltext
	bra	not400


noresetscroll:

	cmp	#$005f
	bcc	allcapital
	sec
	sbc	#$0020


allcapital:

	sec
	sbc	#$0020
	asl a
	ora	#$0c00
	ldx	scrollstorage2
	stx	$2116
	sta	$2118
	inc a
	sta	$2118
	dec a
	pha
	lda	scrollstorage2
	clc
	adc	#$0020
	sta	scrollstorage2
	pla
	ldx	scrollstorage2
	stx	$2116
	clc
	adc	#$0080
	sta	$2118
	inc a
	sta	$2118
	
	sep	#$20
	ldx	scrolltext
	inx
	stx	scrolltext
	rts




;=========================================================================
;                               Logos Swinger
;=========================================================================

logomotion:

	rep	#$30

	dec	atxlogodelay
	lda	atxlogodelay
	beq	logomotionok
	sep	#$20
	rts
	
logomotionok:

	rep	#$30
	lda	#$01
	sta	atxlogodelay

	ldx	atxsine
	
	lda	logosine,x
	and	#$00ff

	sta	hdma210d+1
	txa
	lda	atxsine
	and	#$00ff
	cmp	#$40
	bne	logonoflip1
	
	lda	hdma2107+1
	eor	#$08
	sta	hdma2107+1

logonoflip1:
	lda	atxsine
	and	#$00ff
	eor	#$00ff
	tax
	lda	logosine,x
	and	#$00ff
	clc
	adc	#$0100	
	sta	hdma210d+4
	txa
	cmp	#$c0
	bne	logonoflip2
	
	lda	hdma2107+3
	eor	#$08
	sta	hdma2107+3

logonoflip2:
	
	sep	#$20
	inc	atxsine
	lda	atxsine
	cmp	#$c0
	beq	atxlogodelayon
	rts
	
atxlogodelayon:
	rep	#$30
	lda	#$01ff
	sta	atxlogodelay
	sep	#$20
	rts

;==========================================================================
;                          Star Rotation Toggle
;==========================================================================

starrottoggle:
	lda	startoggle
	bne	starroton
	


	dec	startoggle2
	lda	startoggle2
	bne	startrotoff
	lda	#$ff
	sta	startoggle
	lda	stardirection
	eor	#$ff
	sta	stardirection

startrotoff:
	rts
starroton:

	lda	#$ff
	sta	startoggle2

	lda	stardirection
	beq	starcounter

	dec	starcosangle
	dec	starcosangle
	dec	starsinangle
	dec	starsinangle
	dec	startoggle
	rts

starcounter:
	inc	starcosangle
	inc	starcosangle
	inc	starsinangle
	inc	starsinangle

	dec	startoggle
	rts



;==========================================================================
;                      Calculate the Y rotation of ATX logo
;==========================================================================


rotation1:
	
	ldy	#$0000


rotate1:
	lda	x1table,y
	stz	$211b
	sta	$211b

	ldx	cosangle
	lda	sine,x
	sta	$211c
	lda	$2136
	sta	storage1

	lda	z1table,y
	stz	$211b
	sta	$211b
	ldx	sinangle
	lda	sine,x
	sta	$211c
	lda	$2136
	sta	storage2

	lda	storage1
	sec
	sbc	storage2
	sta	x2table,y




	lda	x1table,y
	stz	$211b
	sta	$211b
	
	ldx	sinangle
	lda	sine,x
	sta	$211c
	lda	$2136
	sta	storage1

	lda	z1table,y
	stz	$211b
	sta	$211b
	ldx	cosangle
	lda	sine,x
	sta	$211c
	lda	$2136
	sta	storage2

	lda	storage1
	sec
	sbc	storage2
	sta	z2table,y

	iny
	cpy	#27
	beq	quitit
	brl	rotate1

quitit:

	rts



x1table:

	dc.b $c0,$f0,$00,$10,$28,$58
	dc.b $b4,$cc,$00,$34,$4c
	dc.b $b0,$c0,$d0,$00,$00,$40
	dc.b $b0,$d0,$00,$34,$4c
	dc.b $b0,$d0,$00,$28,$58




y1table:

	dc.b $10,$10,$10,$10,$10,$10
	dc.b $08,$08,$08,$08,$08
	dc.b $00,$00,$00,$00,$00,$00
	dc.b $f8,$f8,$f8,$f8,$f8
	dc.b $f0,$f0,$f0,$f0,$f0




z1table:

	dc.b $10,$10,$10,$10,$10,$10
	dc.b $10,$10,$10,$10,$10
	dc.b $10,$10,$10,$10,$10,$10
	dc.b $10,$10,$10,$10,$10
	dc.b $10,$10,$10,$10,$10






;==========================================================================
;                 Convert X2 and Z2 table to OAM data
;==========================================================================


tablepri:
	lda	sinangle
	bpl	table2oam1
	brl	table2oam2
	

table2oam1:

	ldy	#$0000
	ldx	#$001a

transoam1:
	lda	x2table,x

	sta	storage1
	bpl	skipx11
	eor	#$ff


skipx11:
	stz	$4204
	and	#$7f
	sta	$4205

	lda	z2table,x		; z2table,x
	eor	#$ff
	clc
	adc	#$80

	
	sta	$4206
	;nop
	;nop
	;nop
	;nop
	;nop
	;nop
	;nop
	;nop

	lda	storage1
	and	#$80
	sta	storage1

	stz	storage3

	lda	storage1
	beq	skipx1

	;lda	#$ff
	dec	storage3

skipx1:
	lda	$4214
	lsr a
	eor	storage3

	



	sec
	sbc	#$80
	sta	$0500,y
	iny


	lda	y1table,x

	sta	storage1

	bpl	skipy11
	eor	#$ff


skipy11:

	stz	$4204
	and	#$7f
	sta	$4205

	lda	z2table,x		; z2table,x
	eor	#$ff
	clc
	adc	#$80


	sta	$4206
	;nop
	;nop
	;nop
	;nop
	;nop
	;nop
	;nop
	;nop
	lda	storage1
	and	#$80
	sta	storage1


	stz	storage3

	lda	storage1
	beq	skipy1

	;lda	#$ff
	dec	storage3

skipy1:
	lda	$4214
	lsr a
	eor	storage3


	

	clc
	adc	#$80
	eor	#$ff

	sec
	sbc	#$5c


	sta	$0500,y
	iny
	     ;lda	#$00
	;lda	z2table,x		; z2table,x
	;eor	#$ff
	;clc
	;adc	#$80
	;lsr a
	;lsr a
	;lsr a
	;lsr a
	;lsr a
	;lsr a
	lda	#$01
	
	;and	#$07
	sta	$0500,y
	iny
	;lda	#$00
	;sta	$0500,y
	iny
	dex
	cpx	#$ffff
	beq	endtransoam1
	brl	transoam1
endtransoam1:
	rts


table2oam2:


	ldy	#$0000
	ldx	#$0000

transoam2:
	lda	x2table,x

	sta	storage1
	bpl	skipx12
	eor	#$ff


skipx12:
	stz	$4204
	and	#$7f
	sta	$4205

	lda	z2table,x		; z2table,x
	eor	#$ff
	clc
	adc	#$80

	
	sta	$4206
	;nop
	;nop
	;nop
	;nop
	;nop
	;nop
	;nop
	;nop

	lda	storage1
	and	#$80
	sta	storage1

	stz	storage3

	lda	storage1
	beq	skipx2

	;lda	#$ff
	dec	storage3

skipx2:
	lda	$4214
	lsr a
	eor	storage3

	



	sec
	sbc	#$80
	sta	$0500,y
	iny


	lda	y1table,x

	sta	storage1

	bpl	skipy12
	eor	#$ff


skipy12:

	stz	$4204
	and	#$7f
	sta	$4205

	lda	z2table,x		; z2table,x
	eor	#$ff
	clc
	adc	#$80


	sta	$4206
	;nop
	;nop
	;nop
	;nop
	;nop
	;nop
	;nop
	;nop
	lda	storage1
	and	#$80
	sta	storage1


	stz	storage3

	lda	storage1
	beq	skipy2

	;lda	#$ff
	dec	storage3

skipy2:
	lda	$4214
	lsr a
	eor	storage3


	

	clc
	adc	#$80
	eor	#$ff
	sec
	sbc	#$5c




	sta	$0500,y
	iny
	 ;lda	#$00
	;lda	z2table,x		; z2table,x
	;eor	#$ff
	;clc
	;adc	#$80
	;lsr a
	;lsr a
	;lsr a
	;lsr a
	;lsr a
	;lsr a
	
	lda	#$01
	;and	#$07
	sta	$0500,y
	iny
	;lda	#$00
	;sta	$0500,y
	iny
	inx
	cpx	#$001b
	beq	endtransoam2
	brl	transoam2
endtransoam2:


	rts








;==========================================================================
;                      Calculate the Y rotation of SWAT logo
;==========================================================================


rotation2:
	
	ldy	#$0000


rotate2:
	lda	x1table2,y
	stz	$211b
	sta	$211b

	ldx	cosangle2
	lda	sine,x
	sta	$211c
	lda	$2136
	sta	storage1

	lda	z1table2,y
	stz	$211b
	sta	$211b
	ldx	sinangle2
	lda	sine,x
	sta	$211c
	lda	$2136
	sta	storage2

	lda	storage1
	sec
	sbc	storage2
	sta	x2table+27,y




	lda	x1table2,y
	stz	$211b
	sta	$211b
	
	ldx	sinangle2
	lda	sine,x
	sta	$211c
	lda	$2136
	sta	storage1

	lda	z1table2,y
	stz	$211b
	sta	$211b
	ldx	cosangle2
	lda	sine,x
	sta	$211c
	lda	$2136
	sta	storage2

	lda	storage1
	sec
	sbc	storage2
	sta	z2table+27,y

	iny
	cpy	#38
	beq	quitit2
	brl	rotate2

quitit2:

	rts



x1table2:

	dc.b $a0,$b0,$d0,$00,$30,$50,$60,$70
	dc.b $90,$d0,$00,$24,$3c,$60
	dc.b $a0,$d0,$e8,$00,$20,$30,$40,$60
	dc.b $b0,$d0,$e0,$f0,$00,$20,$40,$60
	dc.b $90,$a0,$d0,$00,$20,$40,$60




y1table2:

	dc.b $10,$10,$10,$10,$10,$10,$10,$10
	dc.b $08,$08,$08,$08,$08,$08
	dc.b $00,$00,$00,$00,$00,$00,$00,$00
	dc.b $f8,$f8,$f8,$f8,$f8,$f8,$f8,$f8
	dc.b $f0,$f0,$f0,$f0,$f0,$f0,$f0




z1table2:

	dc.b $10,$10,$10,$10,$10,$10,$10,$10
	dc.b $10,$10,$10,$10,$10,$10
	dc.b $10,$10,$10,$10,$10,$10,$10,$10
	dc.b $10,$10,$10,$10,$10,$10,$10,$10
	dc.b $10,$10,$10,$10,$10,$10,$10



;==========================================================================
;                 Convert X2 and Z2 table to OAM data
;==========================================================================


tablepri2:
	lda	sinangle2
	bpl	table2oam12
	brl	table2oam22
	

table2oam12:

	ldy	#$006c
	ldx	#$0024

transoam12:
	lda	x2table+27,x

	sta	storage1
	bpl	skipx112
	eor	#$ff


skipx112:
	stz	$4204
	and	#$7f
	sta	$4205

	lda	z2table+27,x		; z2table,x
	eor	#$ff
	clc
	adc	#$80
	
	
	sta	$4206
	;nop
	;nop
	;nop
	;nop
	;nop
	;nop
	;nop
	;nop

	lda	storage1
	and	#$80
	sta	storage1

	stz	storage3

	lda	storage1
	beq	skipx1112

	;lda	#$ff
	dec	storage3

skipx1112:
	lda	$4214
	lsr a
	eor	storage3

	



	sec
	sbc	#$80
	sta	$0500,y
	iny


	lda	y1table2,x

	sta	storage1

	bpl	skipy1112
	eor	#$ff


skipy1112:

	stz	$4204
	and	#$7f
	sta	$4205

	lda	z2table+27,x		; z2table,x
	eor	#$ff
	clc
	adc	#$80


	sta	$4206
	;nop
	;nop
	;nop
	;nop
	;nop
	;nop
	;nop
	;nop
	lda	storage1
	and	#$80
	sta	storage1


	stz	storage3

	lda	storage1
	beq	skipy112

	;lda	#$ff
	dec	storage3

skipy112:
	lda	$4214
	lsr a
	eor	storage3


	

	clc
	adc	#$80
	eor	#$ff

	clc
	adc	#$2c


	sta	$0500,y
	iny
	   ;lda	#$00
	;lda	z2table+27,x		; z2table,x
	;eor	#$ff
	;clc
	;adc	#$80
	;lsr a
	;lsr a
	;lsr a
	;lsr a
	;lsr a
	;lsr a
	
	;and	#$07

	lda	#$01
	sta	$0500,y
	iny
	;lda	#$00
	;sta	$0500,y
	iny
	dex
	cpx	#$ffff
	beq	endtransoam12
	brl	transoam12
endtransoam12:
	rts


table2oam22:


	ldy	#$006c
	ldx	#$0000

transoam22:
	lda	x2table+27,x

	sta	storage1
	bpl	skipx122
	eor	#$ff


skipx122:
	stz	$4204
	and	#$7f
	sta	$4205

	lda	z2table+27,x		; z2table,x
	eor	#$ff
	clc
	adc	#$80

	
	sta	$4206
	;nop
	;nop
	;nop
	;nop
	;nop
	;nop
	;nop
	;nop

	lda	storage1
	and	#$80
	sta	storage1

	stz	storage3

	lda	storage1
	beq	skipx22

	;lda	#$ff
	dec	storage3

skipx22:
	lda	$4214
	lsr a
	eor	storage3

	



	sec
	sbc	#$80
	sta	$0500,y
	iny


	lda	y1table2,x

	sta	storage1

	bpl	skipy122
	eor	#$ff


skipy122:

	stz	$4204
	and	#$7f
	sta	$4205

	lda	z2table+27,x		; z2table,x
	eor	#$ff
	clc
	adc	#$80
	

	sta	$4206
	;nop
	;nop
	;nop
	;nop
	;nop
	;nop
	;nop
	;nop
	lda	storage1
	and	#$80
	sta	storage1


	stz	storage3

	lda	storage1
	beq	skipy22

	;lda	#$ff
	dec	storage3

skipy22:
	lda	$4214
	lsr a
	eor	storage3


	

	clc
	adc	#$80
	eor	#$ff

	clc
	adc	#$2c



	sta	$0500,y
	iny
	  ;;lda	#$00
	;lda	z2table+27,x		; z2table,x
	;eor	#$ff
	;clc
	;adc	#$80
	;lsr a
	;lsr a
	;lsr a
	;lsr a
	;lsr a
	;lsr a
	
	;and	#$07
	lda	#$01
	sta	$0500,y
	iny
	;lda	#$00
	;sta	$0500,y
	iny
	inx
	cpx	#$25
	beq	endtransoam22
	brl	transoam22
endtransoam22:


	rts




;==========================================================================
;               Calculate Star Rotation and transfer 2 OAM
;==========================================================================


starrotate:
	
	ldy	#$0000
	sty	storage3
	sty	storage4


rotate3:
	lda	starx2table,y
	stz	$211b
	sta	$211b

	ldx	starcosangle
	lda	sine,x
	sta	$211c

	rep	#$30
	lda	$2135
	sta	storage1


	sep	#$20

	lda	stary2table,y
	stz	$211b
	sta	$211b
	ldx	starsinangle
	lda	sine,x
	sta	$211c
	rep	#$30
	lda	$2135
	sta	storage2


	lda	storage1
	sec
	sbc	storage2
	sta	storage2
	sep	#$20

signispos1:

	stz	signy

	lda	storage2+1
	phy
	ldy	storage3

	sec
	sbc	#$80
	sec
	sbc	#$40
	cmp	#$78
	bcc	signxok2
	lda	#$01
	sta	signy

signxok2:


	cmp	#$08
	bcs	signok3
	lda	#$01
	sta	signy

signok3:

	asl a
	bcc	signxok		; here1
	lda	#$00


signxok:
	sta	$0600,y
	inc	storage3
	ply


	lda	starx2table,y

	stz	$211b
	sta	$211b
	
	ldx	starsinangle
	lda	sine,x
	sta	$211c
	rep	#$30
	lda	$2135
	sta	storage1
	sep	#$20


	lda	stary2table,y
	stz	$211b
	sta	$211b
	ldx	starcosangle
	lda	sine,x
	sta	$211c
	rep	#$30
	lda	$2135
	sta	storage2

	lda	storage1
	clc
	adc	storage2
	sta	storage2


	sep	#$20

	phy
	ldy	storage3


	lda	signy
	beq	signyok1
	lda	#$f5
	bra	signyok

signyok1:
	lda	storage2+1

	clc
	adc	#$80
	eor	#$ff
	sec
	sbc	#$40
	cmp	#$70
	bcc	signok2
	lda	#$78

signok2:



	cmp	#$08
	bcs	signyok3
	lda	#$78

signyok3:


	asl a		; here2


signyok:
	
	sta	$0600,y
	inc	storage3
	phx
	ldx	storage4
	lda	starztable,x
	plx
	eor	#$ff
	lsr a
	lsr a
	lsr a
	lsr a
	lsr a


	clc
	adc	#$08				; HERERERERE!!

	ldy	storage3
	sta	$0600,y
	inc	storage3
	inc	storage3

	ply


	

	lda	starztable,y
	inc a
	inc a
	inc a
	bcs	resetstar
	sta	starztable,y
	
noresetstar:
	inc	storage4
	iny
	cpy	#21			;# of stars
	beq	quitit3
	brl	rotate3

quitit3:

	rts


resetstar:
	lda	starxtable,y
	sec
	sbc	#$03
	sta	starxtable,y

	lda	starytable,y
	clc
	adc	#$53
	sta	starxtable,y


	bra	noresetstar



;==========================================================================
;                      Star Z axis Routine
;==========================================================================

starz:

	ldx	#$0000
	ldy	#$0000
	
star2oamrout:
	lda	starxtable,x

	stz	$4204



	sta	storage1
	bpl	skipx122star
	eor	#$ff


skipx122star:
	and	#$7f
	sta	$4205

	lda	starztable,x		; z2table,x
	eor	#$ff	
	sta	$4206


	lda	storage1
	and	#$80
	sta	storage1

	stz	storage3

	lda	storage1
	beq	skipx22star

	;lda	#$ff
	dec	storage3

skipx22star:

	lda	$4215
	beq	starxok	; is star off screen after division?

starxnotok:
	brl	staroutrange

starxok:

	lda	$4214
	bmi	starxnotok
	;lsr a
	eor	storage3


	sta	starx2table,y

	

	lda	starytable,x

	stz	$4204



	sta	storage1

	bpl	skipy122star
	eor	#$ff


skipy122star:

	and	#$7f
	sta	$4205

	lda	starztable,x		; z2table,x
	eor	#$ff
	

	sta	$4206
	
	lda	storage1
	and	#$80
	sta	storage1


	stz	storage3

	lda	storage1
	beq	skipy22star

	;lda	#$ff
	dec	storage3

skipy22star:

	lda	$4215
	beq	staryok
starynotok:


	bra	staroutrange

staryok:
	lda	$4214
	bmi	starynotok
	;lsr a
	eor	storage3


	sta	stary2table,y

starcont:
	iny
	inx
	cpx	#21			; # of stars
	beq	star2oamend
	brl	star2oamrout
star2oamend:
	rts

staroutrange:

	lda	starxtable,x
	clc
	adc	#$03
	sta	starxtable,x

	lda	starytable,x
	clc
	adc	#$53
	sta	starytable,x

	lda	#$00
	sta	starztable,x


	lda	#$7f
	sta	starx2table,y
	sta	stary2table,y
	bra	starcont



;==========================================================================
;                         Wait For Vertical Blank
;==========================================================================
WaitVb:
	lda	$4210
	bpl	WaitVb
WaitVb2:
	lda	$4210
	bmi	WaitVb2
	rts




;==========================================================================
;                      Sprite Transfer Routine
;==========================================================================

spriteDMA:
	rep	#$10	; x,y = 16 bit
	sep	#$20	; a = 8 bit
			; start of General DMA graphics copy routine!
	lda	#$00
	sta	$4370		; 0= 1 byte per register (not a word!)
	lda	#$04
	sta	$4371		; 21xx   this is 2104 (VRAM)
	lda	#$00
	sta	$4372
	lda	#$05		; address = $7e0500
	sta	$4373
	lda	#$7e
	sta	$4374		; bank address of data in ram
	ldx	#$0200
	stx	$4375		; # of bytes to be transferred

	ldx	#$0000
	stx	$2102


	lda	#$80
	sta	$420b

	rts



;==========================================================================
;                           Start of HDMA routine
;==========================================================================

HDMA:
	rep	#$10
	sep	#$20


	ldx	#$0000
copy210dlist:
	lda	list210d,x
	sta	hdma210d,x
	inx
	cpx	#$0009
	bne	copy210dlist

	ldx	#$0000
copy2107list:
	lda	list2107,x
	sta	hdma2107,x
	inx
	cpx	#$0006
	bne	copy2107list


	ldx	#$0000
	txy

	lda	#$64
	sta	hdma210f,x
	inx
	lda	#$00
	sta	hdma210f,x
	inx
	sta	hdma210f,x
	inx


set210flist:
	lda	#$01
	sta	hdma210f,x
	inx
	lda	#$00
	sta	hdma210f,x
	inx
	sta	hdma210f,x
	inx
	iny
	cpy	#$0010
	bne	set210flist
	lda	#$00
	sta	hdma210f,x
	inx
	sta	hdma210f,x
	inx
	sta	hdma210f,x
	


	lda     #$02       
	sta     $4300         
	lda     #$0d
	sta     $4301         
	ldx     #hdma210d 
	stx     $4302         
	lda	#$7e          
	sta     $4304



	lda     #$00      
	sta     $4310         
	lda     #$07
	sta     $4311         
	ldx     #hdma2107 
	stx     $4312         
	lda	#$7e          
	sta     $4314



	lda	#$00
	sta	$4320
	lda	#$21
	sta	$4321
	ldx	#list2121
	stx	$4322
	lda	#$00
	sta	$4324

	lda	#$02
	sta	$4330
	lda	#$22
	sta	$4331
	ldx	#list2122
	stx	$4332
	lda	#$00
	sta	$4334


	lda     #$02       
	sta     $4340         
	lda     #$0f
	sta     $4341         
	ldx     #hdma210f
	stx     $4342         
	lda	#$7e          
	sta     $4344
	


	jsr	WaitVb
	lda	#%00011111
	sta	$420c
	rts


list210d:
	dc.b	$6f,$00,$00,$4f,$00,$00
	dc.b	0,0,0

list2107:
	dc.b	$6f,$71,$4f,$71,0,0

list2121:
	dc.b	1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0
	dc.b	1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0
	dc.b	$70,0,$36,0

	dc.b	1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0
	dc.b	1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0
	dc.b	1,0,0,0


list2122:
	

	dc.b	1


	dcr.w	$4DEC
	dc.b 1
	dcr.w $49CB
	dc.b 1
	dcr.w $49AA
	dc.b 1
	dcr.w $4589
	dc.b 1
	dcr.w $4168
	dc.b 1
	dcr.w $4147
	dc.b 1
	dcr.w $3D26
	dc.b	1
	dcr.w	$3906
	dc.b 1
	dcr.w $38E5
	dc.b 1
	dcr.w $34E4
	dc.b 1
	dcr.w $34C4
	dc.b 1
	dcr.w $30A3
	dc.b 1
	dcr.w $2C83
	dc.b 1
	dcr.w $2C82
	dc.b 1
	dcr.w $2862
	dc.b	1
	dcr.w	$2862
	dc.b 1
	dcr.w $2441
	dc.b 1
	dcr.w $2021
	dc.b 1
	dcr.w $2020	
	dc.b 1
	dcr.w $1C00
	dc.b 1
	dcr.w $1800
	dc.b	1
	dcr.w	$1400
	dc.b 1
	dcr.w $1000
	dc.b 1
	dcr.w $0C00
	dc.b 1
	dcr.w $0800
	dc.b 1
	dcr.w $0400
	dc.b 1
	dcr.w $0000
	dc.b 1
	dcr.w $0000 
 
 



	dc.b	1
	dcr.w	$0000 

	dc.b	$70
 
	dcr.w	$0000

	dc.b	$36
	dcr.w	$0000


	dc.b	1

	dcr.w	$0000
	dc.b 1
	dcr.w $0000
	dc.b 1
	dcr.w $0400
	dc.b 1
	dcr.w $0800
	dc.b 1
	dcr.w $0C00
	dc.b 1
	dcr.w $1000
	dc.b 1
	dcr.w $1400
	dc.b	1
	dcr.w	$1800
	dc.b 1
	dcr.w $1C00
	dc.b 1
	dcr.w $2020
	dc.b 1
	dcr.w $2021
	dc.b 1
	dcr.w $2441
	dc.b	1
	dcr.w	$2862
	dc.b 1
	dcr.w $2C82
	dc.b 1
	dcr.w $2C83
	dc.b 1
	dcr.w $30A3
	dc.b 1
	dcr.w $34C4
	dc.b 1
	dcr.w $34E4
	dc.b 1
	dcr.w $38E5
	dc.b 1
	dcr.w $3906
	dc.b	1
	dcr.w	$3D26
	dc.b 1
	dcr.w $4147
	dc.b 1
	dcr.w $4168
	dc.b 1
	dcr.w $4168
	dc.b 1
	dcr.w $4589
	dc.b 1
	dcr.w $49AA
	dc.b 1
	dcr.w $49CB
	dc.b 1
	dcr.w $4DEC 
 



	
	dc.b	1
 
	dcr.w	$0000
	dc.b	0
	dcr.w	0

	dc.b	0
	dcr.w	0


HDMA2:
	ldx	#$0000
	ldy	#$0000

drawlines0:
	lda	#$01
	sta	HDMALINES,x
	inx
	lda	#$00
	sta	HDMALINES,x
	inx
	sta	HDMALINES,x
	inx
	iny
	cpy	#$0100
	bne	drawlines0



	ldx	#$0300
	ldy	#$0000
	lda	#$ff
	sta	storage1

drawlines1:
	lda	#$01
	sta	HDMALINES,x
	inx
	lda	storage1
	sta	HDMALINES,x
	inx
	lda	#$00
	sta	HDMALINES,x
	inx
	dec	storage1
	iny
	cpy	#$0100
	bne	drawlines1






	lda     #$02       
	sta     $4300         
	lda     #$0e
	sta     $4301         
	ldx     #HDMALINES+$0300
	stx     $4302         
	lda	#$7e          
	sta     $4304
	jsr	WaitVb
	lda	#$01
	sta	$420c

	rts


;==========================================================================
;       	     SETUP ROUTINES FOR PROGRAM
;==========================================================================



;==========================================================================
;                         Copy graf-x data
;==========================================================================

Copy_Gfx:
	ldx	#$0000		; Vram address $0000 
	stx	$2116		; 
	ldx	#$0000
Clearvr:
	stz	$2118		; clear entire Vram
	stz	$2119
	inx
	bne	Clearvr

	rep	#$30


	ldx	#$4000
	stx	$2116


	ldx	#$0000
	
copyballsgfx:
	lda	ballsgfx,x
	sta	$2118
	inx
	inx
	cpx	#$0200
	bne	copyballsgfx
	
	ldx	#$5000
	stx	$2116
	
	ldx	#$0000
	
copylogogfx:
	lda	logogfx,x
	sta	$2118
	inx
	inx
	cpx	#3968
	bne	copylogogfx



	ldx	#$0000
	stx	$2116

	ldx	#$0000

copyscrollgfx:
	lda	scrollgfx,x
	sta	$2118
	inx
	inx
	cpx	#8192
	bne	copyscrollgfx

	ldx	#$2000
	stx	$2116

	ldx	#$0000
copycredgfx:
	lda	credgfx,x
	sta	$2118
	inx
	inx
	cpx	#7168
	bne	copycredgfx

	ldx	#$6000
	stx	$2116

	ldx	#$0000
copywwwgfx:
	lda	wwwgfx,x
	sta	$2118
	inx
	inx
	cpx	#416
	bne	copywwwgfx


	sep	#$20

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
	cpx	#$0200 		; copy 32 colors ($20*2)
	bne	CopCol
	rts

; for the credits screen 


Copy_colors2:

	stz	$2121
	ldx	#$0000

CopCol2:
	lda	Colors2,X
	sta	$2122
	inx
	cpx	#$0040 		; copy 32 colors ($20*2)
	bne	CopCol2

	rts

;==========================================================================
;                      Make Tiles
;==========================================================================

Make_tiles:

	rep	#$30

	ldx	#$7800
	stx	$2116

	ldx	#$0000
copytiles1:
	lda	logotiles,x
	xba
	and	#$c3ff
	ora	#$0800
	sta	$2118
	inx
	inx
	cpx	#$0400
	bne	copytiles1

copytiles2:
	lda	logotiles,x
	xba
	and	#$c3ff
	ora	#$0400
	sta	$2118
	inx
	inx
	cpx	#$0800
	bne	copytiles2


	ldx	#$7100
	stx	$2116

	ldx	#$0400
copytiles3:
	lda	logotiles,x
	xba
	and	#$c3ff
	ora	#$0800
	sta	$2118
	inx
	inx
	cpx	#$0600
	bne	copytiles3

	ldx	#$0200

copytiles4:
	lda	logotiles,x
	xba
	and	#$c3ff
	ora	#$0400
	sta	$2118
	inx
	inx
	cpx	#$0380
	bne	copytiles4


	ldx	#$6800
	stx	$2116


	ldx	#$0000
clearwwwscreen:
	
	lda	#$0000
	sta	$2118
	inx
	inx
	cpx	#$0400
	bne	clearwwwscreen

	
	ldx	#$69c0
	stx	$2116

	ldx	#$0000

copywwwtiles:
	lda	wwwtiles,x
	sta	$2118
	inx
	inx
	cpx	#128
	bne	copywwwtiles


	ldx	#$3000
	stx	$2116


	ldx	#$0000
copycredtiles:
	lda	credtiles,x
	and	#$00ff
	sec
	sbc	#$0020
	sta	$2118
	inx
	cpx	#32*14
	bne	copycredtiles
	phx

	ldx	#$0000
copypantiles:
	lda	pantiles,x
	and	#$00ff
	sta	$2118
	inx
	cpx	#$0040
	bne	copypantiles

copypantiles2:
	lda	pantiles,x
	and	#$00ff
	ora	#$0400
	sta	$2118
	inx
	cpx	#$0080
	bne	copypantiles2


	plx

copycredtiles2:
	lda	credtiles,x
	and	#$00ff
	sec
	sbc	#$0020
	sta	$2118
	inx
	cpx	#$0400-64
	bne	copycredtiles2


	sep	#$20
	rts


pantiles:
	;dc.b	"********************************"

	dc.b	$0060,$0061,$0062,$0063,$0064,$0065,$0066,$0067
	dc.b	$0068,$0069,$006A,$006B,$006C,$006D,$006E,$006F
	dc.b	$0070,$0071,$0072,$0073,$0074,$0075,$0076,$0077
	dc.b	$0078,$0079,$007A,$007B,$007C,$007D,$007E,$007F 

	dc.b	$0080,$0081,$0082,$0083,$0084,$0085,$0086,$0087
	dc.b	$0088,$0089,$008A,$008B,$008C,$008D,$008E,$008F
	dc.b	$0090,$0091,$0092,$0093,$0094,$0095,$0096,$0097
	dc.b	$0098,$0099,$009A,$009B,$009C,$009D,$009E,$009F
	dc.b	$00A0,$00A1,$00A2,$00A3,$00A4,$00A5,$00A6,$00A7
	dc.b	$00A8,$00A9,$00AA,$00AB,$00AC,$00AD,$00AE,$00AF
	dc.b	$00B0,$00B1,$00B2,$00B3,$00B4,$00B5,$00B6,$00B7
	dc.b	$00B8,$00B9,$00BA,$00BB,$00BC,$00BD,$00BE,$00BF
	dc.b	$00C0,$00C1,$00C2,$00C3,$00C4,$00C5,$00C6,$00C7
	dc.b	$00C8,$00C9,$00CA,$00CB,$00CC,$00CD,$00CE,$00CF
	dc.b	$00D0,$00D1,$00D2,$00D3,$00D4,$00D5,$00D6,$00D7
	dc.b	$00D8,$00D9,$00DA,$00DB,$00DC,$00DD,$00DE,$00DF 
 
credtiles:
	dc.b	"    Call These ANTHROX Boards   "
	dc.b	"                                "
	dc.b	"  USS ENTERPRISE 1-412-233-0805 "
	dc.b	"        SYSOP: PICARD           "
	dc.b	"  TRADE LINE    +1-514-PRI-VATE "
	dc.b	"        SYSOP: WILDFIRE         "
	dc.b	"    DIAL HARD  ++41-7350-0155   "
	dc.b	"        SYSOP: FURY             "
	dc.b	" SMALL VEG PTCH  +44-1619452712 "
	dc.b	"        SYSOP: MAD TURNIP       "
	dc.b	"     SYNERGY   +49-PRI-VATE     "
	dc.b	"        SYSOP: SIGMA-SEVEN      "
	dc.b	"     VENGENCE  +61-PRI-VATE     "
	dc.b	"        SYSOP: THE CAUSE        "
	dc.b	"     Call These SWAT Boards     "
	dc.b	"                                "
	dc.b	" MECH RESISTENCE +1-310-PRI-VATE"
	dc.b	"        SYSOP: MR GOODWRENCH    "
	dc.b	" RESURRECTION  +44-PRI-VATE     "
	dc.b	"        SYSOP: R2D2             "
	dc.b	"  KODE ABODE II +1-TOO-PRI-VATE "
	dc.b	"        SYSOP: DRUNKFUX         "
	dc.b	"                                "
	dc.b	"                                "
	dc.b	"                                "
	dc.b	"                                "
	dc.b	"                                "


;==========================================================================
;                           Sprite Setup routine
;==========================================================================

Sprite_setup:
	lda	#$02
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

	ldx	#$0000
clearspritememory1:
	lda	#$f0
	sta	$0500,x
	inx
	lda	#$f0
	sta	$0500,x
	inx
	lda	#$00
	sta	$0500,x
	inx
	lda	#$3a
	sta	$0500,x
	inx
	cpx	#$06c
	bne	clearspritememory1

clearspritememory3:
	lda	#$f0
	sta	$0500,x
	inx
	lda	#$f0
	sta	$0500,x
	inx
	lda	#$00
	sta	$0500,x
	inx
	lda	#$30
	sta	$0500,x
	inx
	cpx	#$200
	bne	clearspritememory3



clearspritememory2:
	lda	#$00
	sta	$0500,x

	inx
	cpx	#$0220
	bne	clearspritememory2

	rts


;==========================================================================
;                           Setup Star Tables
;==========================================================================

setupstars:
	ldx	#$0000
	txy
setstars:
	lda	randomnumbers,x
	sta	starxtable,x
	lda	randomnumbers+64,x
	sta	starytable,x
	lda	randomnumbers+128,x
	sta	starztable,x
	inx
	cpx	#32
	bne	setstars


	ldx	#$0000
	txy
starcolor:
	inx
	inx
	inx
	lda	randomnumbers,y
	lsr a
	lsr a
	and	#$03
	asl a
	sta	$0600,x
	inx
	iny
	cpy	#32
	bne	starcolor

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



Colors:

	; 4 color plane colors

	; blue; white



	dc.w	$0000,$0028,$4051,$FF7F 
 

 

 

	;grey
	dc.w	$0200,$FF7F,$D65A,$8C31 
 

	; orange

	dc.w	$0200,$FF03,$D602,$CE01 
 

	; purple

	dc.w	$0200,$1F59,$9A48,$1638 
 

	; atx colors (cyan blue)


	dc.w	$0000,$967F,$127F,$8E6A,$0A5A,$8649,$0239,$C051
	dc.w	$8051,$4051,$0049,$C048,$8048,$4040,$4040,$0040 
 
 

 
	; swat colors (yellow red)


	dc.w	$0000,$967F,$127F,$8E6A,$0A5A,$8649,$0239,$D401
	dc.w	$9401,$5401,$1201,$D200,$9200,$5000,$5000,$1000 
 
 


	; scroll font colors 
	;                   gold



	dcr.w	$0000,$0487,$26DD,$1E7A,$1638,$0DF6,$0594,$0151 
 	dcr.w	$0000,$0487,$26DD,$1E7A,$1638,$0DF6,$0594,$0151
 


	;                   blue
	dc.w	$0000,$E47F,$447F,$8272,$C059,$0049,$8030,$0020 
 	dc.w	$0000,$E47F,$447F,$8272,$C059,$0049,$8030,$0020

	;                   green

	dc.w	$0000,$E003,$E003,$4003,$C002,$0002,$4001,$8000 
	dc.w	$0000,$E003,$E003,$4003,$C002,$0002,$4001,$8000


	;		    red

	dc.w	$0000,$1F28,$1C20,$1818,$1410,$1008,$0E00,$0A00 
 	dc.w	$0000,$1F28,$1C20,$1818,$1410,$1008,$0E00,$0A00


	;		    silver

	dc.w	$0000,$FF7F,$9A7F,$5873,$166B,$D462,$925A,$5052
	dc.w	$0E4A,$CC41,$8A39,$4831,$0629,$C420,$8218,$4010 

	;			; green


	;		sprite colors


	;                   red


	dc.w	$0000,$1A42,$9A39,$5A31,$1829,$D820,$9818,$5810
	dc.w	$1608,$1400,$1200,$0E00,$0A00,$0600,$FF7F,$FF7F 
 

	;		 green

	dc.w	$0000,$EE03,$8C03,$4A03,$0A03,$C802,$8802,$4602
	dc.w	$0402,$C401,$8201,$4201,$0001,$C000,$FC7F,$FC7F 
 

	;                blue

	dc.w	$0000,$807D,$8071,$4069,$4061,$0059,$C050,$C048
	dc.w	$8040,$8038,$4030,$4028,$0020,$0018,$FC7F,$FC7F 


 	
 

	;		grey


	dc.w	$0000,$FF7F,$9C73,$5A6B,$1863,$D65A,$9452,$524A
	dc.w	$1042,$CE39,$8C31,$4A29,$0821,$C618,$FC7F,$FC7F 
 


	;                 cyan

	dc.w	$0000,$E07F,$8073,$406B,$0063,$C05A,$8052,$404A
	dc.w	$0042,$8039,$4031,$0029,$C020,$8018,$FC7F,$FC7F 

	;		blue


	dc.w	$0000,$807D,$8071,$4069,$4061,$0059,$C050,$C048
	dc.w	$8040,$8038,$4030,$4028,$0020,$0018,$FC7F,$FC7F 
 
 
	;		purple

	dc.w	$0000,$DC5A,$9A5A,$1852,$D649,$9441,$5039,$CE30
	dc.w	$8C28,$4A28,$4820,$0818,$0618,$0610,$0410,$0408 
 	;                yellow

	dc.w	$0000,$DC5A,$9A52,$9A4A,$983A,$5632,$542A,$121A
	dc.w	$1212,$D009,$CE01,$8C01,$8C01,$4A01,$0801,$C600 

Colors2:
	

	dcr.w	$2080,$7FFF,$577D,$32F9,$19D5,$0911,$000C,$6504
	dcr.w	$7ED3,$7670,$6E0D,$65CA,$6166,$5923,$50C0,$0000 

	dcr.w	$20E0,$7FFF,$577D,$32F9,$19D5,$0911,$000C,$6504
	dcr.w	$4E9E,$423B,$35B9,$2956,$18D4,$0C71,$000E,$0000 
 

 



randomnumbers:
	dc.w	$3AA7,$3ECB,$3A50,$9684,$6807,$6DBA,$0FA0
	dc.w	$C455,$722F,$3280,$630A,$A402,$244E,$3FF7,$FBB5
	dc.w	$83F4,$7210,$2165,$6688,$1248,$516B,$43BB,$E409
	dc.w	$656A,$7144,$7525,$C2AE,$E455,$B7A9,$9087,$5E33
	dc.w	$8C23,$072A,$33B1,$A61E,$1989,$E1AA,$FC54,$8A0B
	dc.w	$1722,$1FEE,$9226,$079B,$68D5,$1090,$FEC8,$3B4C
	dc.w	$10DA,$EF06,$A471,$46B7,$4D47,$1984,$3F3F,$FC58
	dc.w	$D0E2,$B601,$ECF3,$5647,$4113,$738B,$305F,$914A
	dc.w	$8665,$420B,$D45B,$8825,$F3B6,$F2C1,$ABEF,$96CA
	dc.w	$4BD7,$A1D4,$8D0C,$A6B1,$EF4C,$033E,$8FAF,$CE49
	dc.w	$4975,$72FD,$9552,$1366,$3FBE,$67F9,$61BF,$307C
	dc.w	$2B57,$0FBF,$05C1,$FAA3,$0E8E,$DA0D,$6BDA,$E101
	dc.w	$DF3D,$CBF2,$8C3A,$0D97,$BED5,$FAD5,$30D9,$361D
	dc.w	$9C81,$3C27,$5BBD,$45EE,$2C62,$8B21,$5424,$1976
	dc.w	$3D5B,$3778,$7599,$3EB8,$6A92,$3C30,$BF88,$2F27
	dc.w	$ABE4,$C50F,$256F,$15AF,$FB7C,$BF5C,$3407,$DCCE
	dc.w	$361A
 


sine:

	.bin	as:sine-256
	.bin	as:sine-256

logosine:

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

vsine:



 dcr.w  108,109,111,112,113,114,115,115,116,117,118,119,120,120,121
 dcr.w  122,122,123,123,124,124,125,125,125,126,126,126,127,127,127
 dcr.w  127,127,127,127,127,127,127,127,126,126,126,125,125,125,124
 dcr.w  124,123,123,122,122,121,120,120,119,118,117,116,115,115,114
 dcr.w  113,112,111,109,108,107,106,105,104,103,101,100,99,97,96,95
 dcr.w  93,92,91,89,88,86,85,83,82,80,79,77,76,74,73,71,70,68,67,65
 dcr.w  64,62,60,59,57,56,54,53,51,50,48,47,45,44,42,41,39,38,36,35
 dcr.w  34,32,31,30,28,27,26,24,23,22,21,20,19,18,16,15,14,13,12,12
 dcr.w  11,10,9,8,7,7,6,5,5,4,4,3,3,2,2,2,1,1,1,0,0,0,0,0,0,0,0,0,0
 dcr.w  0,1,1,1,2,2,2,3,3,4,4,5,5,6,7,7,8,9,10,11,12,12,13,14,15,16
 dcr.w  18,19,20,21,22,23,24,26,27,28,30,31,32,34,35,36,38,39,41,42
 dcr.w  44,45,47,48,50,51,53,54,56,57,59,60,62,64,65,67,68,70,71,73
 dcr.w  74,76,77,79,80,82,83,85,86,88,89,91,92,93,95,96,97,99,100,101
 dcr.w  103,104,105,106,107

 dcr.w  108,109,111,112,113,114,115,115,116,117,118,119,120,120,121
 dcr.w  122,122,123,123,124,124,125,125,125,126,126,126,127,127,127
 dcr.w  127,127,127,127,127,127,127,127,126,126,126,125,125,125,124
 dcr.w  124,123,123,122,122,121,120,120,119,118,117,116,115,115,114
 dcr.w  113,112,111,109,108,107,106,105,104,103,101,100,99,97,96,95
 dcr.w  93,92,91,89,88,86,85,83,82,80,79,77,76,74,73,71,70,68,67,65
 dcr.w  64,62,60,59,57,56,54,53,51,50,48,47,45,44,42,41,39,38,36,35
 dcr.w  34,32,31,30,28,27,26,24,23,22,21,20,19,18,16,15,14,13,12,12
 dcr.w  11,10,9,8,7,7,6,5,5,4,4,3,3,2,2,2,1,1,1,0,0,0,0,0,0,0,0,0,0
 dcr.w  0,1,1,1,2,2,2,3,3,4,4,5,5,6,7,7,8,9,10,11,12,12,13,14,15,16
 dcr.w  18,19,20,21,22,23,24,26,27,28,30,31,32,34,35,36,38,39,41,42
 dcr.w  44,45,47,48,50,51,53,54,56,57,59,60,62,64,65,67,68,70,71,73
 dcr.w  74,76,77,79,80,82,83,85,86,88,89,91,92,93,95,96,97,99,100,101
 dcr.w  103,104,105,106,107









scrtxt:
	dc.b	" -pan- is back! and another intro appears to the awaiting "
	dc.b	"masses of fans. this time it contains more 3d effects than"
	dc.b	" the previous intros            ",0

ballsgfx:
	.bin	as:balls2.dat

logogfx:
	.bin	as:logo2.dat
logotiles:
	.bin	as:logo2.char
scrollgfx:
	.bin	as:scroll.dat2
credgfx:
	.bin	as:cred.dat
wwwgfx:
	.bin	as:www.dat
wwwtiles:
	.bin	as:www.char


	org	$fffc	;reset vector in 6502 mode
	dcr.w	Start
	.pad


