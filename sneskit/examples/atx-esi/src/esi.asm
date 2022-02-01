;--------------------------------------------------------------------------
.include "snes.inc"
.include "snes_decompress.inc"
.include "snes_joypad.inc"
.include "graphics.inc"
;--------------------------------------------------------------------------
.import clear_vram
;--------------------------------------------------------------------------
.export DoESI
;--------------------------------------------------------------------------

BG1MAP	=	0a000h
BG3MAP	=	07400h
BG3GFX	=	04000h

BUFFER1	=	0b00h
BUFFER2	=	7e0a00h

TM_RAM	=	7e8000h

;--------------------------------------------------------------------------
	.bss
;--------------------------------------------------------------------------

hdmaplaneon:
	.res 2
currentline:
	.res 2
drawonoff:
	.res 2
scrollxoffset:
	.res 2
scrolltextoffset:
	.res 2
cycleoffset:
	.res 2
doublechar:
	.res 2
scrollonoff:
	.res 2
speedtoggle:
	.res 2

;--------------------------------------------------------------------------
	.code
;--------------------------------------------------------------------------

;==========================================================================
;                        Start of ESI intro routine
;==========================================================================
DoESI:
;==========================================================================

	rep     #30h		; X,Y,A fixed -> 16 bit mode
	sep     #20h		; Accumulator ->  8 bit mode

	jsr	clear_vram

	lda	#TM_BG1		; mode 1, 8/8 dot
	sta	REG_BGMODE	

	lda	#(BG1MAP>>9)	; Start MAP Adress BG1 $a000
	sta	REG_BG1SC	
	stz	REG_BG12NBA	; Start GFX in Vram  $0000

	lda	#(BG3MAP>>8)	; Start MAP Address BG3 $7400
	sta	REG_BG3SC
	lda	#(BG3GFX>>8)+(BG3GFX>>12)
	sta	REG_BG34NBA
	
	lda	#0fch
	sta	REG_BG3VOFS
	lda	#07h
	sta	REG_BG3VOFS

	stz	REG_TM

;==========================================================================
;                       Copy Graphics To Vram
;==========================================================================

	DoDecompressDataVram gfx_esiTiles, 0000h

;==========================================================================
;                      Copy Colors
;==========================================================================

	DoCopyPalette gfx_esiPal, 0, 7
	lda	#09h
	sta	REG_CGADD
	lda	#18h
	sta	REG_CGDATA
	lda	#63h
	sta	REG_CGDATA
	lda	#0dh
	sta	REG_CGADD
	lda	#0ffh
	sta	REG_CGDATA
	sta	REG_CGDATA

;==========================================================================
;                      Make Tiles
;==========================================================================

	DoDecompressDataVram gfx_esiMap, BG1MAP

	ldx	#BG3MAP
	stx	REG_VMADDL
	ldx	#0000h
ESIplane2:
	lda	#20h
	sta	REG_VMDATAL
	stz	REG_VMDATAH
	inx
	cpx	#0400h
	bne	ESIplane2

	ldx	#BG3MAP+320h
	stx	REG_VMADDL
	ldx	#0000h
	lda	#00h
ESIdrawplane2:
	sta	REG_VMDATAL
	pha
	lda	#0ch
	sta	REG_VMDATAH
	pla
	inc a
	inx
	cpx	#0020h
	bne	ESIdrawplane2

	stz	hdmaplaneon	; value for HDMA planes (# planes on)
	jsr	ESIHDMA
	ldx	#0000
	stx	currentline	; current # of line
	stx	drawonoff	; toggle hdma plane draw on/off 0=on
	stx	scrollonoff
	stx	speedtoggle
	lda	#NMI_ON|NMI_JOYPAD
	sta	REG_NMITIMEN


	lda	#0fh		; Screen Blanker Enabled
	sta	REG_INIDISP	;
;======================= End Init =========================================

ESIWait1:
	jsr	ESIWaitVb

	lda	drawonoff
	bne	Planestop

	jsr	Planedraw
	bra	ESIWait1

Planestop:
	lda	#TM_BG3|TM_BG1
	sta	REG_TM
ESIWait2:
	jsr	ESIcleanram
	ldx	#0000h
	stx	scrollxoffset		; scroll x offset
	stx	scrolltextoffset	; scroll text offset
	stx	cycleoffset		; cycle offset
	stx	scrollonoff		; scroll stop  1=stop
	ldx	#00ffh
	stx	doublechar
ESIWait3:
	jsr	ESIWaitVb
	jsr	ESIscr
	jsr	ESIcyc
	jsr	ESIscroll
	jsr	ESIcount

	lda	speedtoggle
	eor	#01h
	sta	speedtoggle
	beq	ESIskipframe

	jsr	ESIscroll
	jsr	ESIcount

ESIskipframe:
	rep	#30h

	lda	joy1_down
	ora	joy2_down
	and	#JOYPAD_B|JOYPAD_Y|JOYPAD_A|JOYPAD_X
	bne	End

	sep	#20h

	bra	ESIWait3

End:
	sep	#20h

	jsr	ESIWaitVb
	stz	REG_HDMAEN
	lda	#80h
	sta	REG_INIDISP
	stz	REG_TM
	jmp	DoESI


;==========================================================================
;                         Start of ESI Scroll routine
;==========================================================================

ESIcyc:
	ldx	#BG3MAP+320h
	stx	REG_VMADDL

	ldx	cycleoffset
	ldy	#0000h
ESIcopESIcyc:
	lda	ESIcycle,x
	sta	REG_VMDATAH
	inx
	iny
	cpy	#0020h
	bne	ESIcopESIcyc	

	inc	cycleoffset
	lda	cycleoffset
	cmp	#20h
	beq	ESIcycreset

	rts

ESIcycreset:
	stz	cycleoffset
	rts

ESIscr:
	stz	REG_DMAP3	; 0= 1 byte per register (not a word!)
	lda	#<REG_VMDATA
	sta	REG_BBAD3	; 21xx   this is 2118 (VRAM)
	stz	REG_A1T3L
	lda	#>BUFFER2	; address = $7e0a00
	sta	REG_A1T3H
	lda	#^BUFFER2
	sta	REG_A1B3	; bank address of data in ram
	ldx	#0100h
	stx	REG_DAS3L	; # of bytes to be transferred
	stz	REG_VMAIN	; increase V-Ram address after writing to
				; $2118
	ldx	#BG3GFX
	stx	REG_VMADDL	; address of VRAM to copy garphics in
	lda	#08h		; turn on bit 4 (%1000=8) of G-DMA channel
	sta	REG_MDMAEN
	lda	#80h		; increase V-Ram address after writing to
	sta	REG_VMAIN	; $2119
	rts


ESIscroll:
	rep	#30h

	lda	#BUFFER2
	tcd
	sep	#20h

	ldx	#0000h
RollESI:
	lda	doublechar
	beq	Rollcopybit1
	lda	BUFFER1,x
	asl a
	bra	Rollcopybit2

Rollcopybit1:
	asl	BUFFER1,x
Rollcopybit2:
	rol	0af8h,x
	rol	0af0h,x
	rol	0ae8h,x
	rol	0ae0h,x
	rol	0ad8h,x
	rol	0ad0h,x
	rol	0ac8h,x
	rol	0ac0h,x
	rol	0ab8h,x
	rol	0ab0h,x
	rol	0aa8h,x
	rol	0aa0h,x
	rol	0a98h,x
	rol	0a90h,x
	rol	0a88h,x
	rol	0a80h,x
	rol	0a78h,x
	rol	0a70h,x
	rol	0a68h,x
	rol	0a60h,x
	rol	0a58h,x
	rol	0a50h,x
	rol	0a48h,x
	rol	0a40h,x
	rol	0a38h,x
	rol	0a30h,x
	rol	0a28h,x
	rol	0a20h,x
	rol	0a18h,x
	rol	0a10h,x
	rol	0a08h,x
	rol	0a00h,x
	inx
	cpx	#0008h
	bne	RollESI

	rep	#30h

	lda	#0000h
	tcd

	sep	#20h

	lda	doublechar
	eor	#0ffh
	sta	doublechar
	rts

ESIcount:
	lda	scrollxoffset
	inc a
	and	#0fh
	sta	scrollxoffset
	beq	GetESI
	rts

GetESI:
	ldx	scrolltextoffset
	lda	ESIscrolltxt,x
	beq	ESIresetbscrpos

	rep	#30h

	and	#003fh
	asl a
	asl a
	asl a
	tax

	sep	#20h

	ldy	#0000h
ESIcopybscrdata:
	lda	scrollchar,x
	sta	BUFFER1,y
	inx
	iny
	cpy	#08h
	bne	ESIcopybscrdata

	ldx	scrolltextoffset
	inx
	stx	scrolltextoffset
	rts
ESIresetbscrpos:
	inc	scrollonoff
	ldx	#0000h
	stx	scrolltextoffset
	bra	GetESI



;==========================================================================
;                        Start Vertical Blank
;==========================================================================
ESIWaitVb:
	lda	REG_RDNMI	; NMI Enable (Begin V-Blank)
	bpl	ESIWaitVb	; 
	lda	REG_RDNMI	; Reset NMI Flag By Reading it
	rts

;==========================================================================
;                         Clean Ram For Scroll
;==========================================================================

ESIcleanram:
	ldx	#BUFFER2
ESIcleanr:
	stz	0000h,x
	inx
	cpx	#BUFFER1+08h
	bne	ESIcleanr
	rts

;============================================================================
;                    Start ESIHDMA routine to setup plane on/off HDMA
;============================================================================


ESIHDMA:
	rep	#30h
	sep	#20h

	ldx	#0000h
	lda	#00h
ESIcleanHram:
	sta	TM_RAM,x
	inx
	cpx	#8000h
	bne	ESIcleanHram		; clean up ram, we need clean ram!!

	ldx	#0000h
	txy
Planesetup:
	lda	#TM_BG1
	sta	TM_RAM,x		; line width = 1
	inx
	lda	hdmaplaneon		; planes on: 1 
	sta	TM_RAM,x
	inx
	iny
	cpy	#00ffh
	bne	Planesetup

	lda	#00h			; width = 0; end HDMA
	sta	TM_RAM,x
	sta	TM_RAM+1,x

	stz	REG_DMAP0		; 0= 1 byte per register (not a word!)
	lda	#<REG_TM
	sta	REG_BBAD0
	ldx	#TM_RAM
	stx	REG_A1T0L
	lda	#^TM_RAM
	sta	REG_A1B0		; bank address of data in ram

	jsr	ESIWaitVb
	lda	#01h
	sta	REG_HDMAEN
	rts

;============================================================================
;                       Start of HDMA Plane Draw Routine
;============================================================================
Planedraw:

	rep	#30h

	lda	currentline
	asl a			; multiply by 2
	inc a
	tax
	sep	#20h
	lda	#01h
	sta	TM_RAM,x	; turn on plane on in HDMA
	
	inc	currentline
	lda	currentline
	cmp	#0c8h
	beq	StopPlaneDraw

	rts

StopPlaneDraw:
	inc	drawonoff
	stz	REG_HDMAEN
	lda	#TM_BG1
	sta	REG_TM
	rts

	; the following text for this ESI intro was taken from PIRATES!
	; cracked by ESI on the C64, text is exactly as it is in intro.
ESIscrolltxt:
	.byte	"    -=*> 1994 CHRISTMAS LEFTOVERS <*=- WAS CRACKED BY EAGLE SOFT "
	.byte	"INCORPORATED ON MAY 16TH, 1987...  AS USUAL MICROPROSE ANOTHER"
	.byte	" FINE JOB! AND AS USUAL UCF IN PANIC!  WELL LOOKIE, LOOKIE "
	.byte	"THAT MAKES TWO IN A ROW...     GREETINGS TO NEPA, THE ALLIANCE, "
	.byte	"PFI, SRI, JAZZCAT, DYNAMIC DUO, UPN, AND ALL FLYERS FANS!!!"
	.byte	"       QUESTION: WHY DO ALL LOOSER GROUPS START WITH THE LETTER "
	.byte	"'U'?    FOR EXAMPLE UCF, UAN, AND USSPE...    ESI & RUSH ROCKS THE"
	.byte	" USA...       WAITING FOR THE WINDS OF CHANGE TO SWEEP THE CLOUDS "
	.byte	"A WAY.  WAITING FOR THE RAINDOW'S END TO CAST ITS GOLD YOUR WAY"
	.byte	",  COUNTLESS THE WAYS YOU PASS YOUR DAYS, WAITING FOR SOMEONE TO "
	.byte	"COME AND TURN YOUR WORLD AROUND,  LOOKING FOR AN ANSWER FOR THE"
	.byte	" QUESTION YOU HAVE FOUND,  LOOKING FOR AN OPEN DOOR!   YOU DON'T"
	.byte	" GET SOMETHING FOR NOTHING.  YOU CAN'T HAVE FREEDOM FOR FREE,  "
	.byte	"YOU WON'T GET WISE WITH THE SLEEP STILL IN YOUR EYES, NO MATTER "
	.byte	"WHAT YOUR DREAM MIGHT BE!     RUSH #1      FLYERS #1      OILERS #0"
	.byte	"      UCF #0              J.J. LEARN ANYTHING FROM LEADER BOARD YET?"
	.byte	"                   ",0

ESIcycle:
	.byte	$0,$0,$0,$0,$4,$4,$4,$4,$8,$8,$8,$8,$c,$c,$c,$c
	.byte	$8,$8,$8,$8,$4,$4,$4,$4,$0,$0,$0,$0,$0,$0,$0,$0
	.byte	$0,$0,$0,$0,$4,$4,$4,$4,$8,$8,$8,$8,$c,$c,$c,$c
	.byte	$8,$8,$8,$8,$4,$4,$4,$4,$0,$0,$0,$0,$0,$0,$0,$0

	;.byte	$0,$0,$0,$4,$4,$4,$8,$8,$8,$c,$c,$c,$8,$8,$8,$4,$4,$4
	;.byte	$0,$0,$0,$4,$4,$4,$8,$8,$8,$c,$c,$c,$8,$8,$8,$4,$4,$4

scrollchar:

;============================================================================
;= Cyber Font-Editor V1.4  Rel. by Frantic (c) 1991-1992 Sanity Productions =
;============================================================================
	.byte	$00,$00,$00,$00,$00,$00,$00,$00	;' '
	.byte	$0c,$3e,$36,$66,$7e,$c6,$c6,$00	;'!'
	.byte	$fc,$fe,$06,$fc,$c6,$fe,$fc,$00	;'"'
	.byte	$7c,$fe,$c6,$c0,$c6,$fe,$7c,$00	;'#'
	.byte	$fc,$fe,$06,$c6,$c6,$fe,$fc,$00	;'$'
	.byte	$7e,$fe,$c0,$fe,$c0,$fe,$7e,$00	;'%'
	.byte	$fe,$fe,$00,$fc,$c0,$c0,$c0,$00	;'&'
	.byte	$7c,$fe,$c0,$ce,$c6,$fe,$7c,$00	;'''
	.byte	$c6,$c6,$c6,$f6,$c6,$c6,$c6,$00	;'('
	.byte	$7e,$7e,$18,$18,$18,$7e,$7e,$00	;')'
	.byte	$7e,$7e,$0c,$cc,$cc,$fc,$78,$00	;'*'
	.byte	$c6,$cc,$d8,$f0,$d8,$cc,$c6,$00	;'+'
	.byte	$c0,$c0,$c0,$c0,$c0,$fe,$7e,$00	;','
	.byte	$c6,$ee,$fe,$fe,$d6,$c6,$c6,$00	;'-'
	.byte	$cc,$ec,$fc,$fc,$dc,$cc,$cc,$00	;'.'
	.byte	$7c,$fe,$c6,$c6,$c6,$fe,$7c,$00	;'/'
	.byte	$fc,$fe,$06,$fc,$c0,$c0,$c0,$00	;'0'
	.byte	$7c,$fe,$c6,$c6,$c6,$fe,$7b,$00	;'1'
	.byte	$f8,$fe,$06,$fc,$c6,$c6,$c6,$00	;'2'
	.byte	$7e,$fe,$c0,$7c,$06,$fe,$fc,$00	;'3'
	.byte	$f8,$fc,$0c,$0c,$0c,$0c,$0c,$00	;'4'
	.byte	$c6,$c6,$c6,$c6,$c6,$fe,$7c,$00	;'5'
	.byte	$c6,$c6,$c6,$c6,$ee,$7c,$38,$00	;'6'
	.byte	$c6,$c6,$d6,$fe,$fe,$ee,$c6,$00	;'7'
	.byte	$c6,$ee,$7c,$38,$7c,$ee,$c6,$00	;'8'
	.byte	$66,$66,$66,$3c,$18,$18,$18,$00	;'9'
	.byte	$fe,$fe,$1c,$38,$70,$fe,$fe,$00	;':'
	.byte	$00,$00,$00,$00,$00,$00,$00,$00	;';'
	.byte	$00,$00,$00,$00,$00,$00,$00,$00	;'<'
	.byte	$00,$00,$00,$00,$00,$00,$00,$00	;'='
	.byte	$00,$00,$00,$00,$00,$00,$00,$00	;'>'
	.byte	$00,$00,$00,$00,$00,$00,$00,$00	;'?'
	.byte	$00,$00,$00,$00,$00,$00,$00,$00	;'@'
	.byte	$18,$18,$18,$18,$00,$18,$18,$00	;'A'
	.byte	$66,$66,$66,$00,$00,$00,$00,$00	;'B'
	.byte	$6c,$fe,$6c,$6c,$6c,$fe,$6c,$00	;'C'
	.byte	$10,$7e,$d0,$7c,$16,$fc,$10,$00	;'D'
	.byte	$00,$00,$00,$00,$00,$00,$00,$00	;'E'
	.byte	$78,$cc,$78,$70,$de,$cc,$7e,$00	;'F'	
	.byte	$18,$18,$18,$00,$00,$00,$00,$00	;'G'
	.byte	$18,$30,$60,$60,$60,$30,$18,$00	;'H'
	.byte	$30,$18,$0c,$0c,$0c,$18,$30,$00	;'I'
	.byte	$00,$54,$38,$7c,$38,$54,$00,$00	;'J'
	.byte	$00,$18,$18,$7e,$7e,$18,$18,$00	;'K'
	.byte	$00,$00,$00,$00,$00,$18,$18,$30	;'L'
	.byte	$00,$00,$00,$7e,$00,$00,$00,$00	;'M'
	.byte	$00,$00,$00,$00,$00,$18,$18,$00	;'N'
	.byte	$00,$03,$06,$0c,$18,$30,$60,$00	;'O'
	.byte	$7c,$fe,$ce,$d6,$e6,$fe,$7c,$00	;'P'
	.byte	$30,$70,$30,$30,$30,$fc,$fc,$00	;'Q'
	.byte	$fc,$fe,$0e,$3c,$f0,$fe,$fe,$00	;'R'
	.byte	$fc,$fe,$06,$7c,$06,$fe,$fc,$00	;'S'
	.byte	$c0,$c0,$cc,$cc,$fe,$fe,$0c,$00	;'T'
	.byte	$fe,$fe,$c0,$fc,$0e,$fe,$fc,$00	;'U'
	.byte	$7e,$fe,$c0,$fc,$c6,$fe,$7c,$00	;'V'
	.byte	$fe,$fe,$0e,$1c,$38,$38,$38,$00	;'W'
	.byte	$7c,$fe,$c6,$7c,$c6,$fe,$7c,$00	;'X'
	.byte	$7c,$fe,$c6,$fe,$06,$fe,$7c,$00	;'Y'
	.byte	$00,$30,$30,$00,$30,$30,$00,$00	;'Z'
	.byte	$00,$18,$18,$00,$18,$18,$30,$00	;'['
	.byte	$0e,$18,$30,$60,$30,$18,$0e,$00	;'\'
	.byte	$00,$00,$7e,$00,$7e,$00,$00,$00	;']'
	.byte	$70,$18,$0c,$06,$0c,$18,$70,$00	;'^'
	.byte	$3c,$66,$06,$0c,$18,$00,$18,$00	;'_'
