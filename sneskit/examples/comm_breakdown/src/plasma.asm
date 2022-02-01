;-------------------------------------------------------------------------;
.include "copying.inc"
.include "graphics.inc"
.include "oam.inc"
.include "random.inc"
.include "snes.inc"
.include "snes_decompress.inc"
.include "snes_joypad.inc"
.include "snes_zvars.inc"
;-------------------------------------------------------------------------;
.import init_reg
;-------------------------------------------------------------------------;
.export DoCDPlasma
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
RAM_M7A	=	0e00h
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
plasma1 = m5
plasma2 = m6
plamsa3 = m7
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
.code
;/////////////////////////////////////////////////////////////////////////;


;-------------------------------------------------------------------------;
	.a8
	.i16
;-------------------------------------------------------------------------;


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
DoCDPlasma:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	rep	#10h
	sep	#20h

	sei
	jsr	init_reg

	lda	r_init
	bne	:+
;-------------------------------------------------------------------------;
	jsr	Seed
;-------------------------------------------------------------------------;
:	jsr	Random
	rep	#30h

	lda	random
	and	#0fffeh
	sta	plasma1
	eor	#0c87ah
	and	#0fffeh
	sta	plasma2
	stz	plamsa3

	sep	#20h

	lda	#BGMODE_7
	sta	REG_BGMODE
	stz	REG_M7SEL
	lda	#TM_BG1
	sta	REG_TM
	lda	#02h
	sta	REG_CGSWSEL
	lda	#31h
	sta	REG_CGADSUB

	stz	m0		; row
	stz	REG_VMAIN

; it's not much but this saves 17 bytes over the original map routine
	lda	#0		; starting tile
	ldx	#0000h
	stx	m4
	stx	REG_VMADDL
	ldy	#0008h		; ypos
;-------------------------------------------------------------------------;
reset_x:
;-------------------------------------------------------------------------;
	ldx	#0080h		; xpos
;-------------------------------------------------------------------------;
create_map:
;-------------------------------------------------------------------------;
	and	#0fh		; tiles = y0h - yfh; y = 0-f
	clc
	adc	m0		; until we add the row
	ina			; tile is always +1, we never want tile 0
	bne	:+
;-------------------------------------------------------------------------;
	dea			; whoops, don't skip tile 0ffh
	sta	REG_VMDATAL	; this is inelegant
	ina
	bra	:++
;-------------------------------------------------------------------------;
:	sta	REG_VMDATAL
;-------------------------------------------------------------------------;
:	dex
	bne	create_map
;-------------------------------------------------------------------------;
	lda	m0
	clc
	adc	#10h
	bne	:+
;-------------------------------------------------------------------------;
	dey
	beq	map_done
;-------------------------------------------------------------------------;
:	sta	m0
	bra	reset_x
;-------------------------------------------------------------------------;
map_done:
;-------------------------------------------------------------------------;
	lda	#VMAIN_INCH
	sta	REG_VMAIN

	lda	#^M7GFX
	ldx	#M7GFX
	ldy	#1900h
	jsr	M7DMAtoVRAM

	stz	REG_CGADD

	stz	REG_DMAP0
	lda	#<REG_CGDATA
	sta	REG_BBAD0
	ldx	#PLASMA_PALETTE
	stx	REG_A1T0L
	lda	#^PLASMA_PALETTE
	sta	REG_A1B0
	ldx	#0200h
	stx	REG_DAS0L
	lda	#01h
	sta	REG_MDMAEN
;-------------------------------------------------------------------------;
	ldx	#0000h
;-------------------------------------------------------------------------;
:	lda	LIST_M7A,x
	sta	RAM_M7A,x
	inx
	cpx	#LIST_M7A_END-LIST_M7A
	bne	:-
;-------------------------------------------------------------------------;
	lda	#80h
	sta	REG_M7X
	stz	REG_M7X
	sta	REG_M7Y
	stz	REG_M7Y

	jsr	Plasma
	jsr	PlasmaHDMA

	lda	#NMI_ON|NMI_JOYPAD
	sta	REG_NMITIMEN

	cli

	lda	#0fh
	sta	REG_INIDISP
	sta	m0
;-------------------------------------------------------------------------;
Loop:
;-------------------------------------------------------------------------;
	lda	REG_RDNMI
	bpl	Loop

	jsr	Plasma
	lda	joy1_down
	eor	joy1_down+1
	beq	Loop
;-------------------------------------------------------------------------;
Loop2:
;-------------------------------------------------------------------------;
	lda	REG_RDNMI
	bpl	Loop2
;-------------------------------------------------------------------------;
	lda	m4
	sec
	sbc	#04h
	sta	m4
	bne	:+

	dec	m4+1
	
:	sta	REG_M7X
	lda	m4+1
	sta	REG_M7X

	dec	m0
	bmi	:+

	lda	m0
	sta	REG_INIDISP
	wai
	bra	Loop2

:	jsr	init_reg
	rts


;=========================================================================;
Plasma:
;=========================================================================;
	rep	#30h

	lda	plasma1
	and	#01ffh
	sta	plasma1
	lda	#PLASMA_SINE
	clc
	adc	plasma1
	tax				; x = src
	ldy	#1700h			; y = dest
	lda	#01bfh			; a = len
	mvn	80h,^PLASMA_SINE	; src bank, dest bank

	lda	plasma2
	and	#01ffh
	sta	plasma2
	lda	#PLASMA_SINE+1d0h
	clc
	adc	plasma2
	tax				; x = src
	ldy	#1900h			; y = dest $1900    
	lda	#01bfh			; a = len $1bf
	mvn	80h,^PLASMA_SINE
	inc	plasma1
	inc	plasma1

	sep	#20h

	rts


;=========================================================================;
PlasmaHDMA:
;=========================================================================;
	lda	#DMAP_POINTERS|DMAP_XFER_MODE_2
	sta	REG_DMAP0
	sta	REG_DMAP1
	sta	REG_DMAP2
	sta	REG_DMAP3
	sta	REG_DMAP4
	sta	REG_DMAP5

	lda	#<REG_M7A
	sta	REG_BBAD0
	ldx	#RAM_M7A
	stx	REG_A1T0L
	stz	REG_A1B0
	stz	REG_DASB0

	lda	#<REG_M7B
	sta	REG_BBAD1
	ldx	#RAM_M7A+(LIST_M7B-LIST_M7A)
	stx	REG_A1T1L
	stz	REG_A1B1
	stz	REG_DASB1

	lda	#<REG_M7C
	sta	REG_BBAD2
	ldx	#RAM_M7A
	stx	REG_A1T2L
	stz	REG_A1B2
	stz	REG_DASB2

	lda	#<REG_M7D
	sta	REG_BBAD3
	ldx	#RAM_M7A+(LIST_M7B-LIST_M7A)
	stx	REG_A1T3L
	stz	REG_A1B3
	stz	REG_DASB3

	lda	#<REG_BG1VOFS
	sta	REG_BBAD4
	ldx	#RAM_M7A
	stx	REG_A1T4L
	stz	REG_A1B4
	stz	REG_DASB4

	lda	#<REG_BG1HOFS
	sta	REG_BBAD5
	ldx	#RAM_M7A+(LIST_M7B-LIST_M7A)
	stx	REG_A1T5L
	stz	REG_A1B5
	stz	REG_DASB5

	lda	#%111111
	sta	REG_HDMAEN
	rts


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_M7A:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$f0,$00,$17		; 7e1700h
	.byte	$f0,$e0,$17		; 7e17e0h
	.byte	$80
;-------------------------------------------------------------------------;
LIST_M7B:
;-------------------------------------------------------------------------;
	.byte	$f0,$00,$19		; 7e1900h
	.byte	$f0,$e0,$19		; 7e19e0h
	.byte	$80
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_M7A_END:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;



;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
PLASMA_SINE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$01,$00,$03,$00,$04,$00,$06,$00
	.byte	$07,$00,$09,$00,$0a,$00,$0c,$00
	.byte	$0e,$00,$0f,$00,$11,$00,$12,$00
	.byte	$14,$00,$15,$00,$17,$00,$18,$00
	.byte	$19,$00,$1b,$00,$1c,$00,$1e,$00
	.byte	$1f,$00,$20,$00,$22,$00,$23,$00
	.byte	$24,$00,$26,$00,$27,$00,$28,$00
	.byte	$29,$00,$2b,$00,$2c,$00,$2d,$00
	.byte	$2e,$00,$2f,$00,$30,$00,$31,$00
	.byte	$32,$00,$33,$00,$34,$00,$35,$00
	.byte	$36,$00,$37,$00,$37,$00,$38,$00
	.byte	$39,$00,$3a,$00,$3a,$00,$3b,$00
	.byte	$3b,$00,$3c,$00,$3d,$00,$3d,$00
	.byte	$3d,$00,$3e,$00,$3e,$00,$3f,$00
	.byte	$3f,$00,$3f,$00,$3f,$00,$40,$00
	.byte	$40,$00,$40,$00,$40,$00,$40,$00
	.byte	$40,$00,$40,$00,$40,$00,$40,$00
	.byte	$40,$00,$3f,$00,$3f,$00,$3f,$00
	.byte	$3f,$00,$3e,$00,$3e,$00,$3d,$00
	.byte	$3d,$00,$3d,$00,$3c,$00,$3b,$00
	.byte	$3b,$00,$3a,$00,$3a,$00,$39,$00
	.byte	$38,$00,$37,$00,$37,$00,$36,$00
	.byte	$35,$00,$34,$00,$33,$00,$32,$00
	.byte	$31,$00,$30,$00,$2f,$00,$2e,$00
	.byte	$2d,$00,$2c,$00,$2a,$00,$29,$00
	.byte	$28,$00,$27,$00,$26,$00,$24,$00
	.byte	$23,$00,$22,$00,$20,$00,$1f,$00
	.byte	$1e,$00,$1c,$00,$1b,$00,$19,$00
	.byte	$18,$00,$16,$00,$15,$00,$13,$00
	.byte	$12,$00,$10,$00,$0f,$00,$0d,$00
	.byte	$0c,$00,$0a,$00,$09,$00,$07,$00
	.byte	$06,$00,$04,$00,$03,$00,$01,$00
	.byte	$ff,$ff,$fe,$ff,$fc,$ff,$fb,$ff
	.byte	$f9,$ff,$f8,$ff,$f6,$ff,$f5,$ff
	.byte	$f3,$ff,$f1,$ff,$f0,$ff,$ee,$ff
	.byte	$ed,$ff,$eb,$ff,$ea,$ff,$e9,$ff
	.byte	$e7,$ff,$e6,$ff,$e4,$ff,$e3,$ff
	.byte	$e1,$ff,$e0,$ff,$df,$ff,$dd,$ff
	.byte	$dc,$ff,$db,$ff,$da,$ff,$d8,$ff
	.byte	$d7,$ff,$d6,$ff,$d5,$ff,$d4,$ff
	.byte	$d2,$ff,$d1,$ff,$d0,$ff,$cf,$ff
	.byte	$ce,$ff,$cd,$ff,$cc,$ff,$cb,$ff
	.byte	$cb,$ff,$ca,$ff,$c9,$ff,$c8,$ff
	.byte	$c7,$ff,$c7,$ff,$c6,$ff,$c5,$ff
	.byte	$c5,$ff,$c4,$ff,$c4,$ff,$c3,$ff
	.byte	$c3,$ff,$c2,$ff,$c2,$ff,$c1,$ff
	.byte	$c1,$ff,$c1,$ff,$c1,$ff,$c0,$ff
	.byte	$c0,$ff,$c0,$ff,$c0,$ff,$c0,$ff
	.byte	$c0,$ff,$c0,$ff,$c0,$ff,$c0,$ff
	.byte	$c0,$ff,$c1,$ff,$c1,$ff,$c1,$ff
	.byte	$c1,$ff,$c2,$ff,$c2,$ff,$c2,$ff
	.byte	$c3,$ff,$c3,$ff,$c4,$ff,$c4,$ff
	.byte	$c5,$ff,$c6,$ff,$c6,$ff,$c7,$ff
	.byte	$c8,$ff,$c8,$ff,$c9,$ff,$ca,$ff
	.byte	$cb,$ff,$cc,$ff,$cd,$ff,$ce,$ff
	.byte	$cf,$ff,$d0,$ff,$d1,$ff,$d2,$ff
	.byte	$d3,$ff,$d4,$ff,$d5,$ff,$d6,$ff
	.byte	$d7,$ff,$d9,$ff,$da,$ff,$db,$ff
	.byte	$dd,$ff,$de,$ff,$df,$ff,$e1,$ff
	.byte	$e2,$ff,$e3,$ff,$e5,$ff,$e6,$ff
	.byte	$e8,$ff,$e9,$ff,$ea,$ff,$ec,$ff
	.byte	$ed,$ff,$ef,$ff,$f0,$ff,$f2,$ff
	.byte	$f4,$ff,$f5,$ff,$f7,$ff,$f8,$ff
	.byte	$fa,$ff,$fb,$ff,$fd,$ff,$fe,$ff
	.byte	$01,$00,$03,$00,$04,$00,$06,$00
	.byte	$07,$00,$09,$00,$0a,$00,$0c,$00
	.byte	$0e,$00,$0f,$00,$11,$00,$12,$00
	.byte	$14,$00,$15,$00,$17,$00,$18,$00
	.byte	$19,$00,$1b,$00,$1c,$00,$1e,$00
	.byte	$1f,$00,$20,$00,$22,$00,$23,$00
	.byte	$24,$00,$26,$00,$27,$00,$28,$00
	.byte	$29,$00,$2b,$00,$2c,$00,$2d,$00
	.byte	$2e,$00,$2f,$00,$30,$00,$31,$00
	.byte	$32,$00,$33,$00,$34,$00,$35,$00
	.byte	$36,$00,$37,$00,$37,$00,$38,$00
	.byte	$39,$00,$3a,$00,$3a,$00,$3b,$00
	.byte	$3b,$00,$3c,$00,$3d,$00,$3d,$00
	.byte	$3d,$00,$3e,$00,$3e,$00,$3f,$00
	.byte	$3f,$00,$3f,$00,$3f,$00,$40,$00
	.byte	$40,$00,$40,$00,$40,$00,$40,$00
	.byte	$40,$00,$40,$00,$40,$00,$40,$00
	.byte	$40,$00,$3f,$00,$3f,$00,$3f,$00
	.byte	$3f,$00,$3e,$00,$3e,$00,$3d,$00
	.byte	$3d,$00,$3d,$00,$3c,$00,$3b,$00
	.byte	$3b,$00,$3a,$00,$3a,$00,$39,$00
	.byte	$38,$00,$37,$00,$37,$00,$36,$00
	.byte	$35,$00,$34,$00,$33,$00,$32,$00
	.byte	$31,$00,$30,$00,$2f,$00,$2e,$00
	.byte	$2d,$00,$2c,$00,$2a,$00,$29,$00
	.byte	$28,$00,$27,$00,$26,$00,$24,$00
	.byte	$23,$00,$22,$00,$20,$00,$1f,$00
	.byte	$1e,$00,$1c,$00,$1b,$00,$19,$00
	.byte	$18,$00,$16,$00,$15,$00,$13,$00
	.byte	$12,$00,$10,$00,$0f,$00,$0d,$00
	.byte	$0c,$00,$0a,$00,$09,$00,$07,$00
	.byte	$06,$00,$04,$00,$03,$00,$01,$00
	.byte	$ff,$ff,$fe,$ff,$fc,$ff,$fb,$ff
	.byte	$f9,$ff,$f8,$ff,$f6,$ff,$f5,$ff
	.byte	$f3,$ff,$f1,$ff,$f0,$ff,$ee,$ff
	.byte	$ed,$ff,$eb,$ff,$ea,$ff,$e9,$ff
	.byte	$e7,$ff,$e6,$ff,$e4,$ff,$e3,$ff
	.byte	$e1,$ff,$e0,$ff,$df,$ff,$dd,$ff
	.byte	$dc,$ff,$db,$ff,$da,$ff,$d8,$ff
	.byte	$d7,$ff,$d6,$ff,$d5,$ff,$d4,$ff
	.byte	$d2,$ff,$d1,$ff,$d0,$ff,$cf,$ff
	.byte	$ce,$ff,$cd,$ff,$cc,$ff,$cb,$ff
	.byte	$cb,$ff,$ca,$ff,$c9,$ff,$c8,$ff
	.byte	$c7,$ff,$c7,$ff,$c6,$ff,$c5,$ff
	.byte	$c5,$ff,$c4,$ff,$c4,$ff,$c3,$ff
	.byte	$c3,$ff,$c2,$ff,$c2,$ff,$c1,$ff
	.byte	$c1,$ff,$c1,$ff,$c1,$ff,$c0,$ff
	.byte	$c0,$ff,$c0,$ff,$c0,$ff,$c0,$ff
	.byte	$c0,$ff,$c0,$ff,$c0,$ff,$c0,$ff
	.byte	$c0,$ff,$c1,$ff,$c1,$ff,$c1,$ff
	.byte	$c1,$ff,$c2,$ff,$c2,$ff,$c2,$ff
	.byte	$c3,$ff,$c3,$ff,$c4,$ff,$c4,$ff
	.byte	$c5,$ff,$c6,$ff,$c6,$ff,$c7,$ff
	.byte	$c8,$ff,$c8,$ff,$c9,$ff,$ca,$ff
	.byte	$cb,$ff,$cc,$ff,$cd,$ff,$ce,$ff
	.byte	$cf,$ff,$d0,$ff,$d1,$ff,$d2,$ff
	.byte	$d3,$ff,$d4,$ff,$d5,$ff,$d6,$ff
	.byte	$d7,$ff,$d9,$ff,$da,$ff,$db,$ff
	.byte	$dd,$ff,$de,$ff,$df,$ff,$e1,$ff
	.byte	$e2,$ff,$e3,$ff,$e5,$ff,$e6,$ff
	.byte	$e8,$ff,$e9,$ff,$ea,$ff,$ec,$ff
	.byte	$ed,$ff,$ef,$ff,$f0,$ff,$f2,$ff
	.byte	$f4,$ff,$f5,$ff,$f7,$ff,$f8,$ff
	.byte	$fa,$ff,$fb,$ff,$fd,$ff,$fe,$ff
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
PLASMA_PALETTE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.incbin	"../mode7gfx/128x128.pal"
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
M7GFX:	.incbin	"../mode7gfx/128x128.pc7"
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;

