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

;==========================================================================
;      Code (c) 1993-94 -Pan-/ANTHROX   All code can be used at will!
;==========================================================================                     




begin:
	LDA #$00
          PHA
          PLB
          dc.b    $5c,$08,$80,$00
Start:
          jmp     Start1
          org     $8020
  
	dc.b	" Screen Text starts here    --->"
TEXT:		;********************************
	dc.b	"    anthrox proudly presents    "
	dc.b	"                                "
	dc.b	"           nba jam 2            "
	dc.b	"                                "
	dc.b	"       supplied by kirk         "
	dc.b	"                                "
	dc.b	"     call u.s.s. enterprise     "
	dc.b	"                                "
	dc.b	"   for the latest atx releases  "
	dc.b	"                                "
	dc.b	"                                "
	dc.b	"                                "
	dc.b	"                                "
	dc.b	"<----  Screen text ends here    "

	dc.b	"scroll text begins here ------->"

bscrolltxt:
	dc.b	"yeah boy!! another kickin' intro"
	dc.b	" by -pan-!  nothing can stop me "
	dc.b	"now! the power of the bit scroll"
	dc.b	" will take me far!     see you a"
	dc.b	"gain!                          ",0
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
	dc.b	"                               ",0
	dc.b	"<- scroll text ends here!       "

Start1:
	

	phk			; Put current bank on stack
	plb			; make it current programming bank
				; if this program were used as an intro
				; and it was located at bank $20 then an
				; LDA $8000 would actually read from
				; $008000 if it were not changed!
				; JSRs and JMPs work fine, but LDAs do not! 
	clc			; Clear Carry flag
	xce			; Native 16 bit mode  (no 6502 Emulation!) 
;===========================type ===============================================



	rep	#$30
	sep	#$20
	jsr	Snes_Init	; Cool Init routine! use it in your own code!!
	rep	#$30
	sep	#$20
	jsr	Copy_Gfx
	jsr	Copy_colors
	jsr	Make_tiles
	jsr	HDMA


	rep     #$10		; X,Y fixed -> 16 bit mode
	sep     #$20		; Accumulator ->  8 bit mode



	Lda	#$09		; mode 0, 8/8 dot
	Sta	$2105


	lda	#$10
	sta	$2109		; BG3 Tile address $1000

	lda	#$40
	sta	$2107		; bg1 tile at $4000

	lda	#$44
	sta	$2108

	lda	#$52
	sta	$210b		; BG1 graphics data $2000

	lda	#$00
	sta	$210c		; bg3 gfx at $0000

	Lda	#$07		; BG3 BG1 Plane Enabled
	Sta	$212c

	lda	#$04
	sta	$210f
	stz	$210f

	sta	$2110
	stz	$2110


	ldx	#$0000
clearscrollbuff:
	stz	$0200,x		; erase data in scroll vram buffer
	inx
	cpx	#$0888
	bne	clearscrollbuff
	

	ldx	#$0000
	stx	$02		; reset sine position

	stx	$1002		; reset scroll text offset
	stx	$1004		; vert waver sine offset

	lda	#$02
	sta	$12		; sine position data

	lda	#$ff
	sta	$14		; sine inc offset


	lda	#$01
	sta	$4200

	lda	#$0f
	sta	$2100

;==========================================================================
;                                 Core of Program
;==========================================================================


Mainprog:
	lda	$4210
	jsr	WaitVb
	jsr	MoveSV		; move sine gfx during VB
	jsr	bitsine
testjoy:
	lda	$4212
	and	#$01
	bne	testjoy
	lda	$4219
	cmp	#$10
	beq	startpressed
	jmp	Mainprog

startpressed:
	
	jsr	Snes_Init
	sep	#$30
	lda	#$8f
	sta	$2100
	jmp	begin
	rep	#$30
	sep	#$20



;========================================================================
;                        Move Scroll gfx in v-blank
;========================================================================


MoveSV:


	lda	#$00
	sta	$4370		; 0= 1 byte per register (not a word!)
	lda	#$18
	sta	$4371		; 21xx   this is 2118 (VRAM)
	lda	#$00
	sta	$4372
	lda	#$02		; address = $7e8000
	sta	$4373
	lda	#$7e
	sta	$4374		; bank address of data in ram
	ldx	#$0800
	stx	$4375		; # of bytes to be transferred
	lda	#$00
	sta	$2115		; increase V-Ram address after writing to
				; $2118
	ldx	#$0000
	stx	$2116		; address of VRAM to copy garphics in
	lda	#%10000000	; turn on bit 7 (%10000000=80) of G-DMA channel
	sta	$420b


	lda	#$80
	sta	$4370		; 0= 1 byte per register (not a word!)
	lda	#$39
	sta	$4371		; 21xx   this is 2118 (VRAM)
	lda	#$00
	sta	$4372
	lda	#$02		; address = $7e8000
	sta	$4373
	lda	#$7e
	sta	$4374		; bank address of data in ram
	ldx	#$0800
	stx	$4375		; # of bytes to be transferred
	lda	#$00
	sta	$2115		; increase V-Ram address after writing to
				; $2118
	ldx	#$800
	stx	$2116		; address of VRAM to copy garphics in


	lda	#%10000000		; turn on bit 4 (%1000=8) of G-DMA channel
	sta	$420b
	


	lda	#$80		; increase V-Ram address after writing to
	sta	$2115		; $2119
	rts


;=======================================================================
;                  Bit scroll routine
;=======================================================================



bitsine:
	
	ldx	#$0000		; column #
	stx	$0a
	stx	$0c
	lda	$02
	clc
	adc	$12		; speed and direction!
	sta	$02
	sta	$0c

	ldx	#$0000		; scroll char gfx offset
	stx	$06
	

	ldx	#$0008
	stx	$08		; reset the counter


	ldx	$0c
	rep	#$30
	lda	SCROLLSINE,x	; read sine data
	and	#$00ff		; get only 1 byte
	sta	$10		; store it
	lda	$0a
	asl a
	asl a
	asl a
	asl a
	asl a
	asl a
	clc
	adc	$10
	sta	$10
	sep	#$20



	ldy	#$0000
	sty	$04

beforesine:
	ldy	$06		; current scrollchar offset
scrollersine:



	ldx	$04		 ;current bit offset (0-7)
	lda	$0a00,y		 ; read char scroll
	and	BITON,x		 ; read certain bit
biton:	
	ldx	$10
	ora	$0200,x		; ora it with the v-ram buffer
	sta	$0200,x		; store it into v-ram buffer
	;sta	$0201,x
overbit:
	iny			; get next char
	ldx	$10
	inx
	;inx
	stx	$10		; increase the sine data (to reach next line)

				; character counter
	dec	$08
	bne	scrollersine
	lda	#$08
	sta	$08		; reset the counter

	jsr	incbs
	ldy	$06		; get current scroll char location

				; increase bit offset
	inc	$04
	;inc	$04
	lda	$04
	cmp	#$08
	bne	scrollersine

	;lda	#$00
	stz	$04		; yes; reset bit offset
	lda	#$08
	sta	$08		; reset char counter offset
	rep	#$30
	lda	$06
	clc
	adc	#$0008		; add 8 to char buffer offset
	sta	$06
	sep	#$20
	inc	$0a		; increase # of columns
	jsr	incbs
	lda	$0a
	cmp	#$10	; 
	bne	beforesine

endscroll:

	jsr	movebsc
	;jsr	movebsc

	rts
BITON:
	dc.b	$80,$40,$20,$10,$8,$4,$2,$1

	

incbs:
	lda	$0c
	clc
	adc	$14		; make this for angle
	sta	$0c
	ldx	$0c
	rep	#$30
	lda	SCROLLSINE,x	; read sine data
	and	#$00ff		; get only 1 byte
	sta	$10		; store it
	lda	$0a
	asl a
	asl a
	asl a
	asl a
	asl a
	asl a
	clc
	adc	$10
	sta	$10
	sep	#$20
	rts

movebsc:

	ldx	#$0000
	rep	#$30
	lda	#$0a00
	tcd
	sep	#$20
Rollscroll:


	asl	$80,x
	rol	$78,x
	rol	$70,x
	rol	$68,x
	rol	$60,x
	rol	$58,x
	rol	$50,x
	rol	$48,x
	rol	$40,x
	rol	$38,x
	rol	$30,x
	rol	$28,x
	rol	$20,x
	rol	$18,x
	rol	$10,x
	rol	$08,x
	rol	$00,x
	inx
	cpx	#$0008
	bne	Rollscroll
	rep	#$30
	lda	#$0000
	tcd
	sep	#$20
	lda	$1004
	inc a
	and	#$07
	sta	$1004
	beq	Getchar
	rts
Getchar:
	ldx	$1002
	lda	bscrolltxt,x
	beq	resetbscrpos
	rep	#$30
	and	#$00ff
	sec
	sbc	#$0020
	asl a
	asl a
	asl a
	tax
	sep	#$20
	ldy	#$0000
copybscrdata:
	lda	scrollchar,x
	sta	$0a80,y
	inx
	iny
	cpy	#$08
	bne	copybscrdata
	ldx	$1002
	inx
	stx	$1002
	rts
resetbscrpos:
	ldx	#$0000
	stx	$1002
	jmp	Getchar



;==========================================================================
;       	     SETUP ROUTINES FOR PROGRAM
;==========================================================================

;==========================================================================
;                         Copy graf-x data
;==========================================================================

Copy_Gfx:
	rep	#$30
	sep	#$20
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

	ldx	#$2000
	stx	$2116
	
	ldx	#$0000

copylogogfx:
	lda	>$7e8000,x
	sta	$2118
	inx
	lda	>$7e8000,x
	sta	$2119
	inx
	cpx	#$3400
	bne	copylogogfx

	ldx	#$0000
copyPlategfx:
	lda	Plategfx,x
	sta	$2118
	inx
	lda	Plategfx,x
	sta	$2119
	inx
	cpx	#$0480
	bne	copyPlategfx



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

	ldx	#$5000
	stx	$2116
	
	ldx	#$0000

copychargfx:
	lda	>$7e8000,x
	sta	$2118
	inx
	lda	>$7e8000,x
	sta	$2119
	inx
	cpx	#$0c00
	bne	copychargfx


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

	;lda	#$80
	;sta	$2121
	;ldx	#$0000
;Copsprtcol:
	;lda	Spritecol,x
	;sta	$2122
	;inx
	;cpx	#$0020
	;bne	Copsprtcol
	rts
;==========================================================================
;                      Make Tiles
;==========================================================================

Make_tiles:
	rep	#$30

	ldx	#$4000
	stx	$2116

	lda	#$0000
drawlogotiles:
	pha
	ora	#$0400
	sta	$2118
	pla
	inc a
	cmp	#$01a0		; plates lie at $1a0 char!
	bne	drawlogotiles

	ldx	#$41a0
	stx	$2116
	rep	#$30
	ldx	#$0000
copyPlateTiles:
	lda	Platetiles,x
	and	#$00ff

	clc
	adc	#$019f
	ora	#$0400
	sta	$2118
	inx
	cpx	#$0040
	bne	copyPlateTiles


	rep	#$30
	sep	#$20

	ldx	#$4600
	stx	$2116

	ldx	#$0000
copytextstuff:
	lda	TEXT,x
	sec	
	sbc	#$20
	sta	$2118
	lda	#$08
	sta	$2119
	inx
	cpx	#$01a0
	bne	copytextstuff

	ldx	#$45c0
	stx	$2116

	ldx	#$0000
copyright:
	lda	right,x
	eor	#$23
	sec
	sbc	#$20
	sta	$2118
	lda	#$2c
	sta	$2119
	inx
	cpx	#$0020
	bne	copyright

;=============================================================================
;                           Start of Scroll Setup
;=============================================================================
scroll:
	rep	#$10
	sep	#$20



	ldx	#$1000
	stx	$2116

	ldx	#$0000

clear7400:
	lda	#$80
	sta	$2118
	stz	$2119
	inx
	cpx	#$0400
	bne	clear7400


	ldx	#$0000
	stx	$1002		; scroll text offset
	stx	$1004		; scroll counter

	rep	#$30
	sep	#$20

	lda	#$20
	sta	$1002

	ldx	#$122b
	jsr	drawingsine

	stz	$1002

	rts


right:		;*******************************
	;dc.b	"   I N T r o   b y   - p a n -  "
	dc.b	$03,$03,$03,$6A,$03,$6D,$03,$77,$03,$51,$03,$4C,$03,$03,$03,$41
	dc.b	$03,$5A,$03,$03,$03,$0E,$03,$53,$03,$42,$03,$4D,$03,$0E,$03,$03

;==========================================================================
;                Sine tile screen set up subroutine
;==========================================================================




drawingsine:
	stx	$2116
	lda	#$80
	sta	$2115
	ldx	#$0000
	stx	$1000
drawchar:
	lda	$1000		; get first char 
	sta	$1001		; make it the current char
drawflexpattern:
	lda	$1001		;current char
	sta	$2118		; write it into V-Ram
	lda	$1002
	sta	$2119
	lda	$1001
	clc
	adc	#$08		; add #8 to the current char value
				; since our grid will be 32 columns
				; and 8 rows we add #8 to the current
				; char value for the next character
				; store it back
	sta	$1001

	inx
	cpx	#$0010		; did we do 32 columns?
	bne	drawflexpattern
	ldx	#$0010
spaceout:
	lda	#$80
	sta	$2118
	lda	$1002
	sta	$2119
	dex
	bne	spaceout
	ldx	#$0000		; set X back to $0
	inc	$1000		; increase Row counter
	lda	$1000
	cmp	#$08		; did we do all 8 rows?
	bne	drawchar	
	rts




;=============================================================================
;                              HDMA setup routine
;=============================================================================

HDMA:
	
	ldx	#$0000
	txy
HDMAgxpos:
	lda	#$01
	sta	$1100,x		; 1 scan line width
	inx
	lda	#$00		; clear it
	sta	$1100,x
	inx
	lda	#$00		; clear it
	sta	$1100,x
	inx
	iny
	cpy	#$0073		; # of lines to make
	bne	HDMAgxpos
	stz	$1100,x		; end hdma
	inx
	stz	$1100,x
	inx
	stz	$1100,x

	lda	#$80
	sta	$1100
	lda	#$01
	sta	$1103


	ldx	#$0000
	txy
HDMAgypos:
	lda	#$01
	sta	$1300,x		; 1 scan line width
	inx
	lda	#$00		; clear it
	sta	$1300,x
	inx
	lda	#$00		; clear it
	sta	$1300,x
	inx
	iny
	cpy	#$0073		; # of lines to make
	bne	HDMAgypos
	stz	$1300,x		; end hdma
	inx
	stz	$1300,x
	inx
	stz	$1300,x

	lda	#$80
	sta	$1300
	lda	#$01
	sta	$1303




	ldx	#$0000
	txy
HDMApal:
	lda	#$01
	sta	$1500,x		; 1 scan line width
	inx
	lda	#$01		; clear it
	sta	$1500,x
	inx
	iny
	cpy	#$0073		; # of lines to make
	bne	HDMApal
	lda	#$20
	sta	$1500,x		; end hdma
	inx
	stz	$1500,x
	inx
	stz	$1500,x


	lda	#$80
	sta	$1500
	lda	#$08
	sta	$1503

	lda	#$12
	sta	$1544



	ldx	#$0000
	txy
HDMAcol:
	lda	#$01
	sta	$1600,x		; 1 scan line width
	inx
	lda	#$50		; clear it
	sta	$1600,x
	inx
	lda	#$ff		; clear it
	sta	$1600,x
	inx
	iny
	cpy	#$0073		; # of lines to make
	bne	HDMAcol
	lda	#$20
	sta	$1600,x		; end hdma
	inx
	stz	$1600,x
	inx
	stz	$1600,x
	inx
	stz	$1600,x

	lda	#$80
	sta	$1600
	lda	#$08
	sta	$1603








;=======================================================================
;                                    Vert Waver
;=======================================================================

vertwave:
	ldx	#$0000
	stx	$1004

	rep	#$30
	sep	#$20
	ldy	#$0000		; number of lines to create
vertwavemake:
	ldx	$1004		; read offset for sine data
	lda	SCROLLSINE,x
	lsr a
	sec
	sbc	SCROLLSINE,x
	;lsr a

	iny
	sta	$1303,y
	iny
	iny
	dec	$1004
	dec	$1004
	cpy	#$0153
	bne	vertwavemake
	lda	#$00
	sta	$1303,y



horizwave:
	ldx	#$0000
	stx	$1004

	rep	#$30
	sep	#$20
	ldy	#$0000		; number of lines to create
horizwavemake:
	ldx	$1004		; read offset for sine data
	lda	SCROLLSINE,x
	iny
	sta	$1103,y
	iny
	iny
	inc	$1004
	inc	$1004
	cpy	#$0153
	bne	horizwavemake
	lda	#$00
	sta	$1103,y





colorwave:
	ldx	#$0000
	stx	$1004

	rep	#$30
	sep	#$20
	ldy	#$0000		; number of lines to create
colorwavemake:
	ldx	$1004		; read offset for sine data
	lda	HCols,x
	iny
	sta	$1606,y
	iny
	inx
	lda	HCols,x
	;ora	#$70
	;lda	#$00
	sta	$1606,y
	iny
	inc	$1004
	inc	$1004
	cpy	#$0153
	bne	colorwavemake
	lda	#$00
	sta	$1606,y

	lda	#$10
	sta	$1672



	lda	#$02
	sta	$4300		; 2= 2 bytes per register (not a word!)
	lda	#$11
	sta	$4301		; 21xx   this is 2112 
	lda	#$00
	sta	$4302
	lda	#$11		; address = $1100
	sta	$4303
	lda	#$7e
	sta	$4304		; bank address of data in ram


	lda	#$02
	sta	$4310		; 2= 2 bytes per register (not a word!)
	lda	#$12
	sta	$4311		; 21xx   this is 2112 
	lda	#$00
	sta	$4312
	lda	#$13		; address = $1300
	sta	$4313
	lda	#$7e
	sta	$4314		; bank address of data in ram

	lda	#$00
	sta	$4320		; 0= 1 bytes per register (not a word!)
	lda	#$21
	sta	$4321		; 21xx   this is 2121 
	lda	#$00
	sta	$4322
	lda	#$15		; address = $1500
	sta	$4323
	lda	#$7e
	sta	$4324		; bank address of data in ram


	lda	#$02
	sta	$4330		; 2= 2 bytes per register (not a word!)
	lda	#$22
	sta	$4331		; 21xx   this is 2121 
	lda	#$00
	sta	$4332
	lda	#$16		; address = $1300
	sta	$4333
	lda	#$7e
	sta	$4334		; bank address of data in ram


	jsr	WaitVb
	lda	#%00001111	; turn on the HDMA
	sta	$420c
	rts


HCols:
	dc.w	$0800,$0A00,$0A00,$0C00,$0E00,$1000,$1000,$1200
	dc.w	$1400,$1600,$1800,$1800,$1A00,$1C00,$1E00,$1E00 
 

	dc.w	$9E10,$DE18,$1E21,$5E21,$5E29,$9E31,$DE39,$1E42
	dc.w	$5E42,$9E4A,$DE52,$1E5B,$1E63,$5E63,$9E6B,$DE73 
 



	dc.w	$DE73,$9E6B,$5E63,$1E63,$1E5B,$DE52,$9E4A,$5E42
	dc.w	$1E42,$DE39,$9E31,$5E29,$5E21,$1E21,$DE18,$9E10


	dc.w	$1e00,$1E00,$1C00,$1A00,$1800,$1800,$1600,$1400
	dc.w	$1200,$1000,$1000,$0E00,$0C00,$0A00,$0A00,$0800


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
	dc.w	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.bin	new:logo.col
	.bin	new:char.col
	.bin	new:char2.col
Picture:
	.bin	new:logo.rnc

Charset:
	.bin	new:char.rnc

Plategfx:
	.bin	plate.gfx
Platetiles:
	dc.b	1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2
	dc.b	3,4,3,4,3,4,3,4,3,4,3,4,3,4,3,4,3,4,3,4,3,4,3,4,3,4,3,4,3,4,3,4

SCROLLSINE:

 dc.b  24,25,25,26,26,27,28,28,29,29,30,30,31,32,32,33,33,34,34,35
 dc.b  35,36,36,37,37,38,38,39,39,40,40,41,41,41,42,42,43,43,43,44
 dc.b  44,44,45,45,45,45,46,46,46,46,47,47,47,47,47,47,48,48,48,48
 dc.b  48,48,48,48,48,48,48,48,48,48,48,48,48,47,47,47,47,47,47,46
 dc.b  46,46,46,45,45,45,45,44,44,44,43,43,43,42,42,41,41,41,40,40
 dc.b  39,39,38,38,37,37,36,36,35,35,34,34,33,33,32,32,31,30,30,29
 dc.b  29,28,28,27,26,26,25,25,24,23,23,22,22,21,20,20,19,19,18,18
 dc.b  17,16,16,15,15,14,14,13,13,12,12,11,11,10,10,9,9,8,8,7,7,7
 dc.b  6,6,5,5,5,4,4,4,3,3,3,3,2,2,2,2,1,1,1,1,1,1,0,0,0,0,0,0,0,0
 dc.b  0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,5,5,5,6
 dc.b  6,7,7,7,8,8,9,9,10,10,11,11,12,12,13,13,14,14,15,15,16,16,17
 dc.b  18,18,19,19,20,20,21,22,22,23,23


scrollchar:
;============================================================================
;= Cyber Font-Editor V1.4  Rel. by Frantic (c) 1991-1992 Sanity Productions =
;============================================================================
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	;' '
	dc.b	$18,$18,$18,$18,$00,$18,$18,$00	;'!'
	dc.b	$66,$66,$66,$00,$00,$00,$00,$00	;'"'
	dc.b	$6c,$fe,$6c,$6c,$6c,$fe,$6c,$00	;'#'
	dc.b	$10,$7e,$d0,$7c,$16,$fc,$10,$00	;'$'
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	;'%'
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	;'&'
	dc.b	$18,$18,$18,$00,$00,$00,$00,$00	;'''
	dc.b	$18,$30,$60,$60,$60,$30,$18,$00	;'('
	dc.b	$30,$18,$0c,$0c,$0c,$18,$30,$00	;')'
	dc.b	$00,$54,$38,$7c,$38,$54,$00,$00	;'*'
	dc.b	$00,$18,$18,$7e,$7e,$18,$18,$00	;'+'
	dc.b	$00,$00,$00,$00,$00,$18,$18,$30	;','
	dc.b	$00,$00,$00,$7e,$00,$00,$00,$00	;'-'
	dc.b	$00,$00,$00,$00,$00,$18,$18,$00	;'.'
	dc.b	$00,$03,$06,$0c,$18,$30,$60,$00	;'/'
	dc.b	$7c,$fe,$ce,$d6,$e6,$fe,$7c,$00	;'0'
	dc.b	$30,$70,$30,$30,$30,$fc,$fc,$00	;'1'
	dc.b	$fc,$fe,$0e,$3c,$f0,$fe,$fe,$00	;'2'
	dc.b	$fc,$fe,$06,$7c,$06,$fe,$fc,$00	;'3'
	dc.b	$c0,$c0,$cc,$cc,$fe,$fe,$0c,$00	;'4'
	dc.b	$fe,$fe,$c0,$fc,$0e,$fe,$fc,$00	;'5'
	dc.b	$7e,$fe,$c0,$fc,$c6,$fe,$7c,$00	;'6'
	dc.b	$fe,$fe,$0e,$1c,$38,$38,$38,$00	;'7'
	dc.b	$7c,$fe,$c6,$7c,$c6,$fe,$7c,$00	;'8'
	dc.b	$7c,$fe,$c6,$fe,$06,$fe,$7c,$00	;'9'
	dc.b	$00,$30,$30,$00,$30,$30,$00,$00	;':'
	dc.b	$00,$18,$18,$00,$18,$18,$30,$00	;';'
	dc.b	$0e,$18,$30,$60,$30,$18,$0e,$00	;'<'
	dc.b	$00,$00,$7e,$00,$7e,$00,$00,$00	;'='
	dc.b	$70,$18,$0c,$06,$0c,$18,$70,$00	;'>'
	dc.b	$3c,$66,$06,$0c,$18,$00,$18,$00	;'?'
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	;'@'
	dc.b	$0c,$3e,$36,$66,$7e,$c6,$c6,$00	;'A'
	dc.b	$fc,$fe,$06,$fc,$c6,$fe,$fc,$00	;'B'
	dc.b	$7c,$fe,$c6,$c0,$c6,$fe,$7c,$00	;'C'
	dc.b	$fc,$fe,$06,$c6,$c6,$fe,$fc,$00	;'D'
	dc.b	$7e,$fe,$c0,$fe,$c0,$fe,$7e,$00	;'E'
	dc.b	$fe,$fe,$00,$fc,$c0,$c0,$c0,$00	;'F'
	dc.b	$7c,$fe,$c0,$ce,$c6,$fe,$7c,$00	;'G'
	dc.b	$c6,$c6,$c6,$f6,$c6,$c6,$c6,$00	;'H'
	dc.b	$7e,$7e,$18,$18,$18,$7e,$7e,$00	;'I'
	dc.b	$7e,$7e,$0c,$cc,$cc,$fc,$78,$00	;'J'
	dc.b	$c6,$cc,$d8,$f0,$d8,$cc,$c6,$00	;'K'
	dc.b	$c0,$c0,$c0,$c0,$c0,$fe,$7e,$00	;'L'
	dc.b	$c6,$ee,$fe,$fe,$d6,$c6,$c6,$00	;'M'
	dc.b	$cc,$ec,$fc,$fc,$dc,$cc,$cc,$00	;'N'
	dc.b	$7c,$fe,$c6,$c6,$c6,$fe,$7c,$00	;'O'
	dc.b	$fc,$fe,$06,$fc,$c0,$c0,$c0,$00	;'P'
	dc.b	$7c,$fe,$c6,$c6,$c6,$fe,$7b,$00	;'Q'
	dc.b	$f8,$fe,$06,$fc,$c6,$c6,$c6,$00	;'R'
	dc.b	$7e,$fe,$c0,$7c,$06,$fe,$fc,$00	;'S'
	dc.b	$f8,$fc,$0c,$0c,$0c,$0c,$0c,$00	;'T'
	dc.b	$c6,$c6,$c6,$c6,$c6,$fe,$7c,$00	;'U'
	dc.b	$c6,$c6,$c6,$c6,$ee,$7c,$38,$00	;'V'
	dc.b	$c6,$c6,$d6,$fe,$fe,$ee,$c6,$00	;'W'
	dc.b	$c6,$ee,$7c,$38,$7c,$ee,$c6,$00	;'X'
	dc.b	$66,$66,$66,$3c,$18,$18,$18,$00	;'Y'
	dc.b	$fe,$fe,$1c,$38,$70,$fe,$fe,$00	;'Z'
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	;'['
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	;'\'
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	;']'
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	;'^'
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	;'_'
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	;'`'
	dc.b	$0c,$3e,$36,$66,$7e,$c6,$c6,$00	;'a'
	dc.b	$fc,$fe,$06,$fc,$c6,$fe,$fc,$00	;'b'
	dc.b	$7c,$fe,$c6,$c0,$c6,$fe,$7c,$00	;'c'
	dc.b	$fc,$fe,$06,$c6,$c6,$fe,$fc,$00	;'d'
	dc.b	$7e,$fe,$c0,$fe,$c0,$fe,$7e,$00	;'e'
	dc.b	$fe,$fe,$00,$fc,$c0,$c0,$c0,$00	;'f'
	dc.b	$7c,$fe,$c0,$ce,$c6,$fe,$7c,$00	;'g'
	dc.b	$c6,$c6,$c6,$f6,$c6,$c6,$c6,$00	;'h'
	dc.b	$7e,$7e,$18,$18,$18,$7e,$7e,$00	;'i'
	dc.b	$7e,$7e,$0c,$cc,$cc,$fc,$78,$00	;'j'
	dc.b	$c6,$cc,$d8,$f0,$d8,$cc,$c6,$00	;'k'
	dc.b	$c0,$c0,$c0,$c0,$c0,$fe,$7e,$00	;'l'
	dc.b	$c6,$ee,$fe,$fe,$d6,$c6,$c6,$00	;'m'
	dc.b	$cc,$ec,$fc,$fc,$dc,$cc,$cc,$00	;'n'
	dc.b	$7c,$fe,$c6,$c6,$c6,$fe,$7c,$00	;'o'
	dc.b	$fc,$fe,$06,$fc,$c0,$c0,$c0,$00	;'p'
	dc.b	$7c,$fe,$c6,$c6,$c6,$fe,$7b,$00	;'q'
	dc.b	$f8,$fe,$06,$fc,$c6,$c6,$c6,$00	;'r'
	dc.b	$7e,$fe,$c0,$7c,$06,$fe,$fc,$00	;'s'
	dc.b	$f8,$fc,$0c,$0c,$0c,$0c,$0c,$00	;'t'
	dc.b	$c6,$c6,$c6,$c6,$c6,$fe,$7c,$00	;'u'
	dc.b	$c6,$c6,$c6,$c6,$ee,$7c,$38,$00	;'v'
	dc.b	$c6,$c6,$d6,$fe,$fe,$ee,$c6,$00	;'w'
	dc.b	$c6,$ee,$7c,$38,$7c,$ee,$c6,$00	;'x'
	dc.b	$66,$66,$66,$3c,$18,$18,$18,$00	;'y'
	dc.b	$fe,$fe,$1c,$38,$70,$fe,$fe,$00	;'z'
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	;'{'
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	;'|'
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	;'}'
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	;'~'
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	;''




	;org	$c000

	org	$fffc	;reset vector in 6502 mode
	dcr.w	Start
	.pad
