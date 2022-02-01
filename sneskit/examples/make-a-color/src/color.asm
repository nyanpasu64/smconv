;---------------------------------------------------------------------------
.include "c64_pal.inc"
.include "color_change.inc"
.include "snes.inc"
.include "snes_joypad.inc"
;---------------------------------------------------------------------------
.export DoColor
;---------------------------------------------------------------------------
 
BG1MAP	=	1000h
BG1GFX	=	4000h


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
.code
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;


DoColor:
;-------------------------------;-----------------------------------------;
;				;   START OF INIT ROUTINE
;-------------------------------;-----------------------------------------;
	rep	#30h		; X,Y,A fixed -> 16 bit mode
	sep	#20h		; Accumulator ->  8 bit mode

	lda	#8fh
	sta	REG_INIDISP

	lda	#(BG1MAP>>8)	; Screen map data @ VRAM location $1000
	sta	REG_BG1SC	; Plane 0 Map location register
	lda	#(BG1GFX>>13)	; Plane 0 Tile graphics @ $2000
	sta	REG_BG12NBA	; Plane 0 Tile graphics register
	stz	REG_BGMODE	; MODE 0 value Graphics mode register
	lda	#TM_BG1		; Plane 0 value (bit one)
	sta	REG_TM		; Plane enable register
	sta	cc_cgadd	; TM_BG1 = 1 which is the color address needed

	lda	#03h		; Set text color
	sta	REG_CGADD
	lda	#<LT_GREY
	sta	REG_CGDATA
	lda	#>LT_GREY
	sta	REG_CGDATA
;-------------------------------;-----------------------------------------;
;				; Start transfer of graphics to VRAM
;-------------------------------;-----------------------------------------;
	ldx	#BG1GFX/2	; Assign VRAM location $2000 to $2116/7
	stx	REG_VMADDL	; writing to REG_VMDATAL/9 will store data here!
	ldx	#0000h
	txy
loadtile:
	lda	CHARSET,x	; Get CHARACTER SET DATA (Font DATA)
	sta	REG_VMDATAL	; store bitplane 1
	stz	REG_VMDATAH	; clear bitplane 2 and increase VRAM address
	inx
	cpx	#0008h		; Transfer $0007 bytes
	bne	loadtile

loadtile2:
	lda	CHARSET,x
	sta	REG_VMDATAL
	sta	REG_VMDATAH
	inx
	cpx	#0200h		; Transfer remaining bytes
	bne	loadtile2

	ldx	#BG1MAP		; Assign VRAM location $1000 to $2116/7
	stx	REG_VMADDL
text:	lda	SCREEN,y	; Get ASCII text data, x = 0 from bne
	and	#3fh		; we only want the first 64 characters
				; convert ascii to C64 screen code
	sta	REG_VMDATAL
	stz	REG_VMDATAH	; clear unwanted bits, no H/V flipping
	iny
	cpy	#0400h		; transfer entire screen
				; $20*$20=$0400  (1024 bytes)
	bne	text

	lda	#>LT_RED	; ** change this to change the starting
	sta	cc_cgdata+1
	lda	#<LT_RED	; ** color.
	sta	cc_cgdata

	lda	#NMI_ON|NMI_JOYPAD
	sta	REG_NMITIMEN
;-------------------------------------------------------------------------;
Run:    lda	REG_RDNMI
	bpl	Run
;-------------------------------------------------------------------------;
	jsr	Loop
	jsr	Joypad
	bra	Run


;-------------------------------------------------------------------------;
START1:	JMP	DoColor
;=========================================================================;
Joypad:		;r l d u
;=========================================================================;
	lda	joy1_held+1
	lsr		;r
	bcc	:+
	jmp	IncreaseGreen
:	lsr		;l
	bcc	:+
	jmp	DecreaseGreen
:	lsr		;d
	bcc	:+
	jmp	DecreaseRed
:	lsr		;u
	bcc	:+
	jmp	IncreaseRed
:	lsr		;start
	bcs	START1
	lsr		;select
	bcs	START1
	lsr		;y
	bcc	:+
	jmp	IncreaseBlue
:	lsr		;b
	bcc	:+
	jmp	DecreaseBlue
:	rts


;=========================================================================;
Loop:
;=========================================================================;
	lda	REG_RDNMI
	and	#80h
	beq	Loop
;-------------------------------------------------------------------------;
	lda	#8fh
	sta	REG_INIDISP

	ldx	#1243h
	stx	REG_VMADDL

	lda	cc_cgdata+1
	jsr	ror4and0f

	lda	cc_cgdata+1
	jsr	and0f
	
	lda	cc_cgdata
	jsr	ror4and0f

	lda	cc_cgdata
	jsr	and0f

	lda	#20h
	sta	REG_VMDATAL
	stz	REG_VMDATAH
	sta	REG_VMDATAL
	stz	REG_VMDATAH
	
	lda	cc_cgdata+1
	and	#80h
	jsr	rol1
;	   
	lda	#20h
	sta	REG_VMDATAL
	stz	REG_VMDATAH
;
	lda	cc_cgdata+1
	and	#40h
	jsr	rol2

	lda	cc_cgdata+1
	and	#20h
	jsr	rol3

	lda	cc_cgdata+1
	and	#10h
	jsr	rol4

	lda	cc_cgdata+1
	and	#08h
	jsr	ror3

	lda	cc_cgdata+1
	and	#04h
	jsr	ror2
;
	lda	#20h
	sta	REG_VMDATAL
	stz	REG_VMDATAH
;
	lda	cc_cgdata+1
	and	#02h
	jsr	ror1

	lda	cc_cgdata+1
	and	#01h
	jsr	adc30

	lda	cc_cgdata
	and	#80h
	jsr	rol1

	lda	cc_cgdata
	and	#40h
	jsr	rol2

	lda	cc_cgdata
	and	#20h
	jsr	rol3
;
	lda	#20h
	sta	REG_VMDATAL
	stz	REG_VMDATAH
;
	lda	cc_cgdata
	and	#10h
	jsr	rol4

	lda	cc_cgdata
	and	#08h
	jsr	ror3

	lda	cc_cgdata
	and	#04h
	jsr	ror2

	lda	cc_cgdata
	and	#02h
	jsr	ror1

	lda	cc_cgdata
	and	#01h
	jsr	adc30

	sec				; see color-change.inc
	jmp	SetColor


;-------------------------------------------------------------------------;
and0f:	and	#0fh
	clc
	bra	adc30
;-------------------------------------------------------------------------;
rol4:	rol	a
rol3:	rol	a
rol2:	rol	a
rol1:	rol	a
;-------------------------------------------------------------------------;
adc30:	adc	#30h
	sta	REG_VMDATAL
	stz	REG_VMDATAH
	rts
;-------------------------------------------------------------------------;
ror4:	ror	a
ror3:	ror	a
ror2:	ror	a
ror1:	ror	a
	bra	adc30
;-------------------------------------------------------------------------;
ror4and0f:
;-------------------------------------------------------------------------;
	ror	a
	ror	a
	ror	a
	ror	a
	bra	and0f


;==========================================================================
;= Cyber Font-Editor V1.4 Rel by Frantic (c) 1991-1992 Sanity Productions =
;==========================================================================

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
CHARSET:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ;'@'
	.byte	$00,$3c,$66,$7e,$66,$66,$66,$00 ;'A'
	.byte	$00,$7c,$66,$7c,$66,$66,$7c,$00 ;'B'
	.byte	$00,$3c,$66,$60,$60,$66,$3c,$00 ;'C'3
	.byte	$00,$78,$6c,$66,$66,$6c,$78,$00 ;'D'
	.byte	$00,$7e,$60,$78,$60,$60,$7e,$00 ;'E'
	.byte	$00,$7e,$60,$78,$60,$60,$60,$00 ;'F'
	.byte	$00,$3c,$66,$60,$6e,$66,$3c,$00 ;'G'7
	.byte	$00,$66,$66,$7e,$66,$66,$66,$00 ;'H'
	.byte	$00,$3c,$18,$18,$18,$18,$3c,$00 ;'I'
	.byte	$00,$1e,$0c,$0c,$0c,$6c,$38,$00 ;'J'
	.byte	$00,$6c,$78,$70,$78,$6c,$66,$00 ;'K'
	.byte	$00,$60,$60,$60,$60,$60,$7e,$00 ;'L'
	.byte	$00,$63,$77,$7f,$6b,$63,$63,$00 ;'M'
	.byte	$00,$66,$76,$7e,$7e,$6e,$66,$00 ;'N'
	.byte	$00,$3c,$66,$66,$66,$66,$3c,$00 ;'O'f
	.byte	$00,$7c,$66,$66,$7c,$60,$60,$00 ;'P'
	.byte	$00,$3c,$66,$66,$66,$3c,$0e,$00 ;'Q'
	.byte	$00,$7c,$66,$66,$7c,$6c,$66,$00 ;'R'
	.byte	$00,$3e,$60,$3c,$06,$66,$3c,$00 ;'S'
	.byte	$00,$7e,$18,$18,$18,$18,$18,$00 ;'T'
	.byte	$00,$66,$66,$66,$66,$66,$3c,$00 ;'U'
	.byte	$00,$66,$66,$66,$66,$3c,$18,$00 ;'V'
	.byte	$00,$63,$63,$6b,$7f,$77,$63,$00 ;'W'17
	.byte	$00,$66,$3c,$18,$3c,$66,$66,$00 ;'X'
	.byte	$00,$66,$66,$3c,$18,$18,$18,$00 ;'Y'
	.byte	$00,$7e,$0c,$18,$30,$60,$7e,$00 ;'Z'
	.byte	$00,$00,$FF,$00,$00,$00,$00,$0F ;'['
	;.byte	$00,$3c,$66,$7e,$66,$66,$66,$00 ;'A'
	.byte	$00,$00,$FF,$00,$00,$00,$00,$00 ;'\'
	.byte	$03,$1D,$E1,$01,$01,$01,$01,$01 ;']'
	.byte	$80,$80,$80,$80,$80,$80,$80,$80 ;'^'
	.byte	$07,$03,$03,$07,$07,$0F,$0F,$1F ;'_'1f
	.byte	$00,$00,$00,$00,$00,$00,$00,$00 ;' '
	.byte	$C0,$E0,$F0,$F0,$F0,$F8,$F8,$F8 ;'!'
	.byte	$01,$01,$01,$01,$01,$01,$01,$01 ;'"'
	.byte	$80,$80,$80,$81,$87,$8F,$9F,$9F ;'#'
	.byte	$1F,$1F,$0F,$C0,$E1,$F3,$F7,$F7 ;'$'
	.byte	$F8,$F0,$E0,$06,$8F,$CF,$EF,$EF ;'%'
	.byte	$01,$01,$01,$09,$99,$F9,$F9,$F9 ;'&'
	.byte	$9F,$99,$50,$40,$40,$40,$40,$20 ;'''27
	.byte	$F3,$F1,$60,$07,$0F,$1F,$1F,$1F ;'('
	.byte	$CF,$87,$03,$F0,$F8,$F8,$F8,$F0 ;')'
	.byte	$F1,$E1,$82,$02,$02,$02,$02,$04 ;'*'
	.byte	$20,$20,$10,$10,$08,$08,$04,$04 ;'+'
	.byte	$00,$00,$00,$00,$00,$18,$18,$30 ;','
	.byte	$F0,$E0,$E0,$C0,$C0,$E0,$F0,$00 ;'-'
	.byte	$00,$00,$00,$00,$00,$18,$18,$00 ;'.'
	.byte	$04,$04,$08,$08,$10,$10,$20,$20 ;'/'2f

	.byte	$00,$3c,$66,$6e,$76,$66,$3c,$00 ;'0'
	.byte	$00,$18,$38,$18,$18,$18,$7e,$00 ;'1'
	.byte	$00,$7c,$06,$0c,$30,$60,$7e,$00 ;'2'
	.byte	$00,$7e,$06,$1c,$06,$66,$3c,$00 ;'3'
	.byte	$00,$0e,$1e,$36,$7f,$06,$06,$00 ;'4'
	.byte	$00,$7e,$60,$7c,$06,$66,$3c,$00 ;'5'
	.byte	$00,$3e,$60,$7c,$66,$66,$3c,$00 ;'6'
	.byte	$00,$7e,$06,$0c,$0c,$0c,$0c,$00 ;'7'
	.byte	$00,$3c,$66,$3c,$66,$66,$3c,$00 ;'8'
	.byte	$00,$3c,$66,$3e,$06,$66,$3c,$00 ;'9'
	.byte	$00,$3c,$66,$7e,$66,$66,$66,$00 ;'A'
	.byte	$00,$7c,$66,$7c,$66,$66,$7c,$00 ;'B'
	.byte	$00,$3c,$66,$60,$60,$66,$3c,$00 ;'C'
	.byte	$00,$78,$6c,$66,$66,$6c,$78,$00 ;'D'
	.byte	$00,$7e,$60,$78,$60,$60,$7e,$00 ;'E'
	.byte	$00,$7e,$60,$78,$60,$60,$60,$00 ;'F'
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SCREEN:		  ;12345678901234567890123456789012
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte     "                                "
	.byte     "                                "
	.byte     "                                "
	.byte     "                                "
	.byte     "                                "
	.byte     "                                "
	.byte     "                                "
	.byte     "                                "
	.byte     "        HERE IS THE COLOR       "
	.byte     "                                "
	.byte     "  @@@@@@@@@@@@@@@@@@@@@@@@@@@@  "
	.byte     "  @@@@@@@@@@@@@@@@@@@@@@@@@@@@  "
	.byte     "  @@@@@@@@@@@@@@@@@@@@@@@@@@@@  "
	.byte     "                                "
	.byte     "        Y DEC B INC  BLUE       "
	.byte     "        L DEC R INC  GREEN      "
	.byte     "        D DEC U INC  RED        "
	.byte     "                                "
	.byte     "                                "
	.byte     "           BLUE  GREEN RED      "
	.byte     "                                "
	.byte     "     FIXED TO BE MORE USEFUL    "
	.byte     "     I LIKE SWITCHING TO DOS    "
	.byte     "                                "
	.byte     "         BY XAD/NIGHTFALL       "
	.byte     "                                "
	.byte     "   USE RESET OR START TO EXIT   "
	.byte     "                                "
	.byte     "                                "
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
