;--------------------------------------------------------------------------
.include "c64_font_to_mode7.inc"
.include "snes.inc"
.include "snes_joypad.inc"
;--------------------------------------------------------------------------
.export DoMode7
;--------------------------------------------------------------------------
;
;
;
;           CODE: THE WHITE KNIGHT
;       COMPUTER: AMIGA 2000/030/25Mhz/4Mb RAM
;      ASSEMBLER: SASM 1.0
;         EDITOR: CygnusEd Professional V3.5
;           FONT: from a COMMODORE 64 COLLECTION
;
; HARDWARE TOOLS: SUPER MAGICOM from FRONT FAREAST
;                 AMIGA <-> SUPER MAGICOM TRANSFER CABLE
;                 YES! all Hobbyists tools!  No need to pay $8,000.00 or
;                 whatever the other commercial tools cost
;
; for more info, EMAIL: ANTIROX@TNP.COM
;
;
;
;
;
;
;
;
;--------------------------------------------------------------------------
BG1GFX	= 4000h
BG1MAP	= 2000h
RAM_M7A = 0300h
STARTOPT = 0a00h

SRAM = 708000h
;--------------------------------------------------------------------------
	.zeropage
;--------------------------------------------------------------------------
credit_text:
	.res 2
credit_text_switch:
	.res 2
current_pos:
	.res 2
;--------------------------------------------------------------------------
	.code
;--------------------------------------------------------------------------
DoMode7:

main:	rep	#30h	; X,Y,A fixed -> 16 bit mode
	sep	#20h	; Accumulator ->  8 bit mode

	lda	#80h
	sta	REG_INIDISP
	sta	REG_VMAIN
	ldx	#0000h
	stx	REG_VMADDL
	lda	#20h
vram:	sta	REG_VMDATAL
	stz	REG_VMDATAH
	inx
	cpx	#8000h
	bne	vram
	
	jsr	screen
	jsr	color
	jsr	texton
	jsr	HDMA
	jsr	loadx

	ldx	#0000h
	stx	credit_text
	stx	credit_text_switch
	stx	current_pos
	stx	font_conv
orig:	lda	STARTAT,x
	sta	STARTOPT,x
	inx
	cpx	#10
	bne	orig

	lda	#NMI_ON|NMI_JOYPAD
	sta	REG_NMITIMEN

	cli

	lda	#0fh
	sta	REG_INIDISP

forever:
	jsr	vrtb
	jsr	loadx
	jsr	boards
	jsr	joypad2
	bra	forever

screen:	lda	#BG1MAP>>9	; Plane 1 TILES @ $1000
	sta	REG_BG1SC
	lda	#BG1GFX>>9	; Plane 1 @ $2000
	sta	REG_BG12NBA
	lda	#BGMODE_7	; MODE 7
	sta	REG_BGMODE

	lda	#TM_BG1
	sta	REG_TM

	lda	#FONT_STANDARD	; only other option is FONT_INVERT
	xba
	lda	#^FONT
	ldx	#FONT
	ldy	#0000h
	jsr	C64ToMode7Convert

	lda	#0e0h
        sta	REG_M7A
        stz	REG_M7A
        stz	REG_M7B
        stz	REG_M7B
        stz	REG_M7C
        stz	REG_M7C
        stz	REG_M7D
        lda	#01
        sta	REG_M7D
	lda	#80h
        sta	REG_M7X
        stz	REG_M7X
	lda	#0c3h
        sta	REG_M7Y
        stz	REG_M7Y
	
	stz	REG_BG1HOFS
	stz	REG_BG1HOFS
	lda	#01h
	sta	REG_BG1VOFS
	stz	REG_BG1VOFS
	rts

color:	stz	REG_CGADD
	ldx	#0000h
fill: 	lda	COL,x
	sta	REG_CGDATA
	inx
	cpx	#12h
	bmi	fill

	rts

texton:	stz	REG_VMAIN
	ldx	#640
	stx	REG_VMADDL
	ldy	#0000h
	tyx
textprt:
	lda	MENU,x
	and	#3fh
	beq	endit

	sta	REG_VMDATAL
	iny
	cpy	#32
	bne	noclrit

	ldy	#0000h
cleart:	lda	#20h
	sta	REG_VMDATAL
	iny
	cpy	#96
	bne	cleart

	ldy	#0000h
noclrit:
	inx
	bra	textprt
endit:	rts



HDMA:   ldx	#0000h		; HDMA LIST TABLE for
hdmlp2:	lda	LIST_M7A,x	; REG_CGDATA at $001200
	sta	RAM_M7A,x	; is TRANSFERRED
	sta	RAM_M7A+20h,x
	sta	RAM_M7A+40h,x
	inx			;
	cpx	#07h*3		;
	bmi	hdmlp2		;

	lda	#DMAP_XFER_MODE_2
	sta	REG_DMAP0	; 1 BYTE for this HDMA CHANNEL
	sta	REG_DMAP1	; 1 BYTE for this HDMA CHANNEL
	sta	REG_DMAP2	; 1 BYTE for this HDMA CHANNEL

	lda	#<REG_M7A	;
	sta	REG_BBAD0
	lda	#<REG_M7D	;
	sta	REG_BBAD1
	lda	#<REG_M7X	;
	sta	REG_BBAD2

	stz	REG_A1T0L	;
	lda	#20h
	sta	REG_A1T1L	;
	lda	#40h
	sta	REG_A1T2L	;
	lda	#>RAM_M7A	; HDMA LIST 1 AT LOCATION $000?00
	sta	REG_A1T0H	;			  $000?20
	stz	REG_A1B0	;			  $000?40
	sta	REG_A1T1H	;
	stz	REG_A1B1	;
	sta	REG_A1T2H	;
	stz	REG_A1B2	;
	lda	#%111		;ENABLE 3 HDMAs
	sta	REG_HDMAEN

	lda	#80h
	sta	RAM_M7A+41h
	sta	RAM_M7A+44h
	sta	RAM_M7A+47h
	sta	RAM_M7A+4ah
	sta	RAM_M7A+4dh
	stz	RAM_M7A+50h
	rts

loadx:	ldx	font_conv
	lda	SINE,x
	sec
	sbc	#40h
	sta	REG_WRMPYA
	lda	#02h
	sta	REG_WRMPYB
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	lda	REG_RDMPYL
	sta	RAM_M7A+07h
	lda	REG_RDMPYH
	sta	RAM_M7A+08h
	inx
	stx	font_conv
	lda	SINE,x
	bne	noreset

	ldx	#0000h
	stx	font_conv
noreset:
	ldx	credit_text_switch
	lda	SINE2,x
	sta	REG_WRMPYA
	lda	#02h
	sta	REG_WRMPYB
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	lda	REG_RDMPYL
	sta	RAM_M7A+0dh
	sta	RAM_M7A+2dh
	lda	REG_RDMPYH
	inx
	stx	credit_text_switch
	lda	SINE2,x
	bne	noreset2

	ldx	#0000h
	stx	credit_text_switch
noreset2:
	rts

vrtb:	lda	REG_RDNMI
	and	#80h
	beq	vrtb
	rts

end:	stz	REG_HDMAEN
	jmp	DoMode7

joypad2:
	lda	joy1_down
	ora	joy2_down
	bit	#JOYPAD_A
	bne	increase

	lda	joy1_down+1
	ora	joy1_down+1
	lsr			; right
	bcs	increase
	lsr			; left
	bcs	decrease
	lsr			; down
	bcs	down
	lsr			; up
	bcs	up
	lsr			; start
	bcs	end
	lsr			; select
	bcs	end
	lsr			; y
	lsr			; b
	bcs	decrease

	jsr	choicedisp

	rts

decrease:
	ldx	current_pos
	lda	TYPE,x
	beq	exclusive

numdown:
	lda	STARTOPT,x
	cmp	MIN,x
	beq	numdcm 

	dec	STARTOPT,x
numdcm: rts

increase:
	ldx	current_pos
	lda	TYPE,x
	beq	exclusive

numup:  lda	STARTOPT,x
	cmp	MAX,x
	beq	numucm 

	inc	STARTOPT,x
numucm:	rts

exclusive:
	lda	STARTOPT,x
	eor	#0ffh
	sta	STARTOPT,x	
	rts

down:	lda	current_pos
	cmp	NUMO
	beq	nodown

	lda	RAM_M7A+03h
	clc
	adc	#08h
	jsr	store03_23_43
	sec
	sbc	#08h
	jsr	store09_29_49
	inc	current_pos
nodown:	rts

up:	lda	current_pos
	beq	noup
	lda	RAM_M7A+03h
	sec
	sbc	#08h
	jsr	store03_23_43
	clc
	adc	#08h
	jsr	store09_29_49
	dec	current_pos
noup:	rts

store03_23_43:
	sta	RAM_M7A+03h
	sta	RAM_M7A+23h
	sta	RAM_M7A+43h
	lda	RAM_M7A+09h
	rts

store09_29_49:
	sta	RAM_M7A+09h
	sta	RAM_M7A+29h
	sta	RAM_M7A+49h
	rts

choicedisp:
	ldy	#666
	ldx	#0000h
btnloop:
	sty	REG_VMADDL
	lda	TYPE,x
	bne	trynum

	lda	STARTOPT,x
	bne	sayyes

	jsr	no
	bra	yano

sayyes:	jsr	yes
	bra	yano

trynum:	jsr	num
yano:	rep	#30h	; X,Y,A fixed -> 16 bit mode

	tya
	clc
	adc	#128
	tay

	sep	#20h	; Accumulator ->  8 bit mode

	cpx	NUMO
	beq	done

	inx
	bra	btnloop

done:	rts

num:	lda	STARTOPT,x
	and	#0f0h
	lsr a
	lsr a
	lsr a
	lsr a
	cmp	#0ah
	bpl	letter

	clc
	adc	#30h
	sta	REG_VMDATAL
	bra	numcom

letter:	sec
	sbc	#09h
	sta	REG_VMDATAL
numcom:	lda	STARTOPT,x
	and	#0fh
	cmp	#0ah
	bpl	letter2

	clc
	adc	#30h
	sta	REG_VMDATAL
	bra	numend

letter2:
	sec
	sbc	#09h
	sta	REG_VMDATAL
numend:	rts

yes:	lda	#25
	sta	REG_VMDATAL
	lda	#05
	sta	REG_VMDATAL
	lda	#19
	sta	REG_VMDATAL
	rts
no:	lda	#14
	sta	REG_VMDATAL
	inc	a
	sta	REG_VMDATAL
	lda	#32
	sta	REG_VMDATAL
	rts

LIST_M7A:
	.byte $06,$ff,$0			; TOP DELAY
	.byte $20,$ff,$0			; TOP WAIT
	.byte $08,$ff,$0			; SELECTION LINE
	.byte $78,$ff,$0			; BOTTOM WAIT
	.byte $30,$ff,$0
        .byte $00,$0,$0				; END LIST

boards:	ldx	credit_text_switch
	beq	brdnums
	rts

brdnums:
	lda	#8fh
	sta	REG_INIDISP
	ldx	#3072
	stx	REG_VMADDL
bbsy:	ldx	credit_text
	ldy	#0000h
bbs:	lda	CREDITS,x
	bne	resetbb

	ldx	#0000h
	stx	credit_text
	bra	bbsy

resetbb:
	and	#3fh
	sta	REG_VMDATAL
	iny
	inx
	cpy	#32
	bne	bbs

	lda	CREDITS,x
	sta	RAM_M7A+4dh
	inx
	stx	credit_text
	lda	#0fh
	sta	REG_INIDISP
	rts

SINE2:
 .byte  128,131,134,137,140,143,146,149,152,155,158,162,165,167,170
 .byte  173,176,179,182,185,188,190,193,196,198,201,203,206,208,211
 .byte  213,215,218,220,222,224,226,228,230,232,234,235,237,238,240
 .byte  241,243,244,245,246,248,249,250,250,251,252,253,253,254,254
 .byte  255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
 .byte  255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
 .byte  255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
 .byte  255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
 .byte  254,254,253,253,252,251
 .byte  250,250,249,248,246,245,244,243,241,240,238,237,235,234,232
 .byte  230,228,226,224,222,220,218,215,213,211,208,206,203,201,198
 .byte  196,193,190,188,185,182,179,176,173,170,167,165,162,158,155
 .byte  152,149,146,143,140,137,134,131
 .byte  0


;reset:	stz	REG_HDMAEN
;	ldx	#0
;battery:
;	lda	STARTOPT,x
;	sta	SRAM,x
;	inx
;	cpx	#0ah
;	bne	battery
;	sep	#30h
;	lda	#00h
;	pha
;	plb
;	.byte $5c,$08,$80,$20



COL:    .word   $6464,$ffff,$7B87,$7350,$64CC,$5A48,$49C4,$3940,$38C0

FONT:	.incbin "../gfx/CHAR0"

SINE:
 .byte  128,131,134,137,140,143,146,149,152,155,158,162,165,167,170
 .byte  173,176,179,182,185,188,190,193,196,198,201,203,206,208,211
 .byte  213,215,218,220,222,224,226,228,230,232,234,235,237,238,240
 .byte  241,243,244,245,246,248,249,250,250,251,252,253,253,254,254
 .byte  254,255,255,255,255,255,255,255,254,254,254,253,253,252,251
 .byte  250,250,249,248,246,245,244,243,241,240,238,237,235,234,232
 .byte  230,228,226,224,222,220,218,215,213,211,208,206,203,201,198
 .byte  196,193,190,188,185,182,179,176,173,170,167,165,162,158,155
 .byte  152,149,146,143,140,137,134,131
 .byte 0

	     ;65432109876543211234567890123456
MENU:	.byte "    SLOW ROM FIX:         NO    "
	.byte "    UNLIMITED CONTINUES:  NO    "
	.byte "    UNLIMITED HP:         NO    "
	.byte "    UNLIMITED SP:         NO    "
	.byte "    START W/MORE POWER:   NO    "
	.byte "                                "
	.byte "                                "
	.byte "                                "
	.byte "           CYBORG 009           "
	.byte "      TRAINED BY -PAN-/ATX      "
	.byte "                                "
	.byte "           ON 2-13-94           "
	.byte "         CALL ANTHROX AT:       "
	.byte "         (718) 630-9818         "
	.byte 0

CREDITS:
	.byte "       TRAINED BY: -PAN-        ",$80
	.byte "   INTRO BY: THE WHITE KNIGHT   ",$80
	.byte 0


TYPE:
        .byte $00,$00,$00,$00,$00,$00,$01,$00,$00,$00
STARTAT:
        .byte $00,$00,$00,$00,$00,$00,$01,$00,$00,$00

;--------------------------------------------------------------------------
;
;options section
;
;--------------------------------------------------------------------------

NUMO:
	.byte 4,0	;# options -1
MIN:
	.byte $00,$00,$00,$00,$00,$00,$01,$00,$00,$00
MAX:
	.byte $01,$01,$01,$01,$00,$00,$04,$00,$00,$00



;slow:
;	pha
;	php
;	sep	#$30
;	.byte	$af,$00,$80,$70
;	beq	noslowrom
;	.byte	$a9,$00,$8d,$0d,$42
;	plp
;	pla
;	rtl
;noslowrom:
;	.byte	$a9,$01,$8d,$0d,$42
;	plp
;	pla
;	rtl
	
cheat:
	.byte	$ad,$1a,$42
	.byte	$8d,$5e,$04
	phy
	pha
	phx
	php
	sep	#$30
	.byte	$af,$01,$80,$70
	beq	l2
	.byte	$a9,$03,$8d,$31,$1a

l2:
	.byte	$af,$02,$80,$70
	beq	l3
	.byte	$a9,$3c,$8d,$e1,$0a
l3:
	.byte	$af,$03,$80,$70
	beq	l4
	.byte	$a9,$3c,$8d,$e3,$0a
l4:
	
	plp
	plx
	pla
	ply
	rts
copy:
	.byte	$a9,$00,$40,$8d,$e7,$19
	php
	.byte	$af,$04,$80,$70
	bne	copygood
	plp
	.byte	$5c,$12,$b5,$19

copygood:

	rep	#$30
	sep	#$20
	ldx	#$0000
copysnazz:
	lda	>SNAZZ,x
	sta	$06cd,x
	inx
	cpx	#$0080
	bne	copysnazz
	plp
	.byte	$5c,$23,$b5,$19

SNAZZ:
	.byte	$88,$13,$88,$13,$0A,$00,$B8,$0B,$C4,$09,$08,$00,$00,$00,$00,$00
	.byte	$A0,$0F,$A0,$0F,$B8,$0B,$B8,$0B,$B8,$0B,$0A,$00,$00,$00,$00,$00
	.byte	$7C,$15,$7C,$15,$B8,$0B,$B8,$0B,$40,$1F,$19,$00,$00,$00,$00,$00
	.byte	$70,$17,$70,$17,$0A,$00,$08,$52,$08,$52,$19,$00,$00,$00,$00,$00
	.byte	$A0,$0F,$A0,$0F,$0A,$00,$A0,$0F,$10,$27,$0A,$00,$00,$00,$00,$00
	.byte	$B8,$0B,$B8,$0B,$0A,$00,$B8,$0B,$C4,$09,$0A,$00,$00,$00,$00,$00
	.byte	$B8,$0B,$B8,$0B,$05,$00,$B8,$0B,$C4,$09,$19,$00,$00,$00,$00,$00
	.byte	$88,$13,$88,$13,$0F,$00,$B8,$0B,$40,$1F,$19,$00,$00,$00,$00,$00


