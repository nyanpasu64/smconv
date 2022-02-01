;-------------------------------------------------------------------------;
.include "copying.inc"
.include "graphics.inc"
.include "snes.inc"
.include "snes_decompress.inc"
.include "snes_zvars.inc"
.include "starfield.inc"
;-------------------------------------------------------------------------;
.importzp frame_ready, joy1_down
;-------------------------------------------------------------------------;
.import clear_vram, oam_hitable, oam_table
;-------------------------------------------------------------------------;
.export DoRings
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
BG1GFX = 04000h
BG1MAP = 06000h
BG2GFX = 0a000h
BG2MAP = 0e800h
BG3GFX = 08000h
BG3MAP = 0f000h
BG4MAP = 0f800h
OAMGFX = 00000h
;-------------------------------------------------------------------------;


;---------------;---------------------------------------------------------;
		; tile reduction is enabled for bg1gfx so these will change
TOP_BAR = 0bah	; depending on if you change the graphics... for simplicity
BOT_BAR = 0bbh	; it could make sense to place it in the ascii charset since
		; each character within the charset should be unique
;---------------;---------------------------------------------------------;


;-------------------------------------------------------------------------;
RAM_STUFF	=	0320h
RAM_BG1HOFS	=	0700h
RAM_BG1VOFS	=	RAM_BG1HOFS+100h
RAM_CGDATA0	=	RAM_BG1VOFS+100h
RAM_CGDATA1	=	RAM_CGDATA0+100h
RAM_CGDATA2	=	RAM_CGDATA1+100h
RAM_CGDATA3	=	RAM_CGDATA2+100h
RAM_LOGO_MAP	=	7f0000h
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
logo_pal_index = m5
logo_pal_timer = m6
ram_cgdata = m7
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
.code
;/////////////////////////////////////////////////////////////////////////;


;-------------------------------------------------------------------------;
	.a8
	.i16
;-------------------------------------------------------------------------;


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
DoRings:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	rep	#10h
	sep	#20h

	jsr	clear_vram

	sep	#30h

	jsr	Setup

	lda	#%111111
	sta	REG_HDMAEN
;-------------------------------------------------------------------------;
Loop:
;-------------------------------------------------------------------------;
	lda	REG_RDNMI
	and	#80h
	beq	Loop

	lda	REG_RDNMI
	lda	RAM_STUFF+040h
	clc
	adc	#80h
	sta	REG_INIDISP

	jsr	Pal2CGDATA
	jsr	BG3HV
	jsr	BG2HV

	lda	#<oam_table
	sta	REG_WMADDL
	lda	#>oam_table
	sta	REG_WMADDM
	lda	#^oam_table
	sta	REG_WMADDH

	jsr	SmallSpriteRing
	jsr	LargeSpriteRing
	jsr	CreditSprite
	jsr	ContactSpritePal
	jsr	CopyScrollTextToVram
	jsr	CreditPal

	lda	RAM_STUFF+040h
	sta	REG_INIDISP
	jsr	MoveRings
	lda	#TM_BG4|TM_BG1
	sta	REG_TM
	lda	#TM_OBJ|TM_BG3|TM_BG2
	sta	REG_TS

	jsr	MoveBG1Horiz
	jsr	BG3Ring
	jsr	BG2Ring
	jsr	StarField
	jsr	Scrolltext
	jsr	MoveBG1Vert
	jsr	LogoPal1
	jsr	LogoPal2
	jsr	LogoPal3
	jsr	ContactSpriteFadeIn
	jsr	FadeIn
	jsr	Joypad
	jsr	FadeOut
	jsr	ContactSprite
	jsr	CenterTextPal

	bra	Loop
;-------------------------------------------------------------------------;

:	rts
;=========================================================================;
CenterTextPal:
;=========================================================================;
	inc	RAM_STUFF+046h
	lda	RAM_STUFF+046h
	and	#03h
	bne	:-
;-------------------------------------------------------------------------;
	ldx	#00h
	lda	#70h
	sta	RAM_CGDATA1,x
	sta	RAM_CGDATA2,x
	sta	RAM_CGDATA3,x
	inx
	lda	#1dh
	sta	RAM_CGDATA1,x
	ina
	sta	RAM_CGDATA2,x
	ina
	sta	RAM_CGDATA3,x
	inx
	lda	#1dh
	sta	RAM_CGDATA1,x
	ina
	sta	RAM_CGDATA2,x
	ina
	sta	RAM_CGDATA3,x
	inx
	lda	#08h
	sta	RAM_CGDATA1,x
	lda	#29h
	sta	RAM_CGDATA2,x
	lda	#4ah
	sta	RAM_CGDATA3,x
	inx
	lda	#21h
	sta	RAM_CGDATA1,x
	lda	#25h
	sta	RAM_CGDATA2,x
	lda	#29h
	sta	RAM_CGDATA3,x
	inx
	lda	#08h
	sta	RAM_CGDATA1,x
	sta	RAM_CGDATA2,x
	sta	RAM_CGDATA3,x
	inx
	lda	#1dh
	sta	RAM_CGDATA1,x
	ina
	sta	RAM_CGDATA2,x
	ina
	sta	RAM_CGDATA3,x
	inx
	lda	#1dh
	sta	RAM_CGDATA1,x
	ina
	sta	RAM_CGDATA2,x
	ina
	sta	RAM_CGDATA3,x
	inx
	ldy	RAM_STUFF+047h
	lda	CENTER_TEXT_PAL1,y
	sta	RAM_CGDATA1,x
	sta	RAM_CGDATA2,x
	sta	RAM_CGDATA3,x
	inx
	lda	CENTER_TEXT_PAL1+01h,y
	sta	RAM_CGDATA1,x
	sta	RAM_CGDATA2,x
	sta	RAM_CGDATA3,x
	inx
	lda	#04h
	sta	RAM_CGDATA1,x
	sta	RAM_CGDATA2,x
	sta	RAM_CGDATA3,x
	inx
	lda	#1dh
	sta	RAM_CGDATA1,x
	ina
	sta	RAM_CGDATA2,x
	ina
	sta	RAM_CGDATA3,x
	inx
	lda	#1dh
	sta	RAM_CGDATA1,x
	ina
	sta	RAM_CGDATA2,x
	ina
	sta	RAM_CGDATA3,x
	inx
	stz	RAM_CGDATA1,x
	stz	RAM_CGDATA2,x
	stz	RAM_CGDATA3,x
	inx
	stz	RAM_CGDATA1,x
	stz	RAM_CGDATA2,x
	stz	RAM_CGDATA3,x
	inx
	lda	#0a8h
	sta	RAM_CGDATA1,x
	sta	RAM_CGDATA2,x
	sta	RAM_CGDATA3,x
	inx

	ldy	RAM_STUFF+04bh
;-------------------------------------------------------------------------;
:	lda	#1dh
	sta	RAM_CGDATA1,x
	sta	RAM_CGDATA1+1,x
	ina
	sta	RAM_CGDATA2,x
	sta	RAM_CGDATA2+1,x
	ina
	sta	RAM_CGDATA3,x
	sta	RAM_CGDATA3+1,x
	inx
	inx
	lda	CENTER_TEXT_PAL2,y
	sta	RAM_CGDATA1,x
	lda	CENTER_TEXT_PAL3,y
	sta	RAM_CGDATA2,x
	lda	CENTER_TEXT_PAL4,y
	sta	RAM_CGDATA3,x
	iny
	inx
	lda	CENTER_TEXT_PAL2,y
	sta	RAM_CGDATA1,x
	lda	CENTER_TEXT_PAL3,y
	sta	RAM_CGDATA2,x
	lda	CENTER_TEXT_PAL4,y
	sta	RAM_CGDATA3,x
	iny
	inx
	cpx	#0b0h
	bne	:-
;-------------------------------------------------------------------------;
	lda	#08h
	sta	RAM_CGDATA1,x
	sta	RAM_CGDATA2,x
	sta	RAM_CGDATA3,x
	inx
	lda	#1dh
	sta	RAM_CGDATA1,x
	sta	RAM_CGDATA1+1,x
	ina
	sta	RAM_CGDATA2,x
	sta	RAM_CGDATA2+1,x
	ina
	sta	RAM_CGDATA3,x
	sta	RAM_CGDATA3+1,x
	inx
	inx
	lda	#08h
	sta	RAM_CGDATA1,x
	lda	#29h
	sta	RAM_CGDATA2,x
	lda	#4ah
	sta	RAM_CGDATA3,x
	inx
	lda	#21h
	sta	RAM_CGDATA1,x
	lda	#25h
	sta	RAM_CGDATA2,x
	lda	#29h
	sta	RAM_CGDATA3,x
	inx
	stz	RAM_CGDATA1,x
	stz	RAM_CGDATA2,x
	stz	RAM_CGDATA3,x
	inc	RAM_STUFF+047h
	inc	RAM_STUFF+047h
	lda	RAM_STUFF+047h
	and	#3fh
	sta	RAM_STUFF+047h
	inc	RAM_STUFF+04bh
	inc	RAM_STUFF+04bh
	lda	RAM_STUFF+04bh
	cmp	#50h
	bne	:+
;-------------------------------------------------------------------------;
	stz	RAM_STUFF+04bh
:	rts


;=========================================================================;
CopyScrollTextToVram:
;=========================================================================;
	rep	#10h

	ldx	RAM_STUFF+01dh
	stx	REG_VMADDL

	ldx	RAM_STUFF+01bh
	lda	SCROLLTEXT,x
	sec
	sbc	#20h
	sta	REG_VMDATAL
	stz	REG_VMDATAH

	sep	#10h

	rts


;=========================================================================;
CreditPal:
;=========================================================================;
	lda	#161
	sta	REG_CGADD
	ldx	RAM_STUFF+024h
	lda	CREDIT_SPRITE_PAL,x
	sta	REG_CGDATA
	inx
	lda	CREDIT_SPRITE_PAL,x
	sta	REG_CGDATA
	inc	RAM_STUFF+024h
	inc	RAM_STUFF+024h
	lda	RAM_STUFF+024h
	cmp	#26h
	bne	:+
;-------------------------------------------------------------------------;
	stz	RAM_STUFF+024h
;-------------------------------------------------------------------------;
:	rts


;=========================================================================;
Joypad:
;=========================================================================;
	lda	RAM_STUFF+041h
	bne	:+
;-------------------------------------------------------------------------;
	lda	joy1_down+1
	ora	joy1_down+1
	ror
	bcs	JoyRight
	ror
	bcs	JoyLeft
	ror
	bcs	JoyDown
	ror
	bcs	JoyUp
	ror
	bcs	JoyStart
:	rts
;-------------------------------------------------------------------------;
JoyRight:
JoyLeft:
JoyDown:
JoyUp:
;-------------------------------------------------------------------------;
	rts
;-------------------------------------------------------------------------;
JoyStart:
;-------------------------------------------------------------------------;
	lda	#01h
	sta	RAM_STUFF+02dh
	sta	RAM_STUFF+041h
	rts


;=========================================================================;
FadeOut:
;=========================================================================;
	lda	RAM_STUFF+02dh
	beq	:+
;-------------------------------------------------------------------------;
	inc	RAM_STUFF+02dh
	inc	RAM_STUFF+02eh
	lda	RAM_STUFF+02eh
	cmp	#20h
	beq	End
;-------------------------------------------------------------------------;
	tax
	lda	LIST_INIDISP,x
	sta	RAM_STUFF+040h
:	rts
;-------------------------------------------------------------------------;
End:	stz	REG_HDMAEN
	jmp	DoRings
;-------------------------------------------------------------------------;


;=========================================================================;
FadeIn:
;=========================================================================;
	lda	RAM_STUFF+02fh
	cmp	#01h
	bne	:+
;-------------------------------------------------------------------------;
	lda	RAM_STUFF+030h
	sta	RAM_STUFF+040h
	inc	RAM_STUFF+030h
	ina
	cmp	#10h
	bne	:+
;-------------------------------------------------------------------------;
	stz	RAM_STUFF+02fh
	stz	RAM_STUFF+030h
:	rts


;=========================================================================;
Pal2CGDATA:
;=========================================================================;
	lda	#04h
	sta	REG_CGADD
	ldx	#00h
;-------------------------------------------------------------------------;
:	lda	RAM_CGDATA0,x
	sta	REG_CGDATA
	inx
	cpx	#30h
	bne	:-
;-------------------------------------------------------------------------;
	rts


;=========================================================================;
LogoPal3:
;=========================================================================;
	rep	#30h

	lda	#RAM_STUFF+029h
	ldx	#RAM_STUFF+02ah
	ldy	#RAM_CGDATA0+20h
	bra	LogoPal

;=========================================================================;
LogoPal2:
;=========================================================================;
	rep	#30h

	lda	#RAM_STUFF+027h
	ldx	#RAM_STUFF+028h
	ldy	#RAM_CGDATA0+10h
	bra	LogoPal

;=========================================================================;
LogoPal1:
;=========================================================================;
	rep	#30h

	lda	#RAM_STUFF+025h
	ldx	#RAM_STUFF+026h
	ldy	#RAM_CGDATA0
;-------------------------------------------------------------------------;
LogoPal:
;-------------------------------------------------------------------------;
	sty	ram_cgdata
	stx	logo_pal_timer
	sta	logo_pal_index

	sep	#30h

	lda	(logo_pal_timer)
	inc
	bne	logo_exit
;-------------------------------------------------------------------------;
	lda	#0feh
	sta	(logo_pal_timer)
	lda	(logo_pal_index)
	tax
	ldy	#00h
;-------------------------------------------------------------------------;
:	lda	#00h
	sta	(ram_cgdata),y
	iny
	sta	(ram_cgdata),y
	iny
	lda	LOGO_PAL,x
	sta	(ram_cgdata),y
	inx
	iny
	lda	LOGO_PAL,x
	sta	(ram_cgdata),y
	inx
	iny
	lda	LOGO_PAL,x
	sta	(ram_cgdata),y
	inx
	iny
	lda	LOGO_PAL,x
	sta	(ram_cgdata),y
	inx
	iny
	lda	LOGO_PAL,x
	sta	(ram_cgdata),y
	inx
	iny
	lda	LOGO_PAL,x
	sta	(ram_cgdata),y
	dex
	iny
	cpy	#10h
	bne	:-
;-------------------------------------------------------------------------;
	lda	(logo_pal_index)
	dec
	dec
	sta	(logo_pal_index)
	bne	:+
;-------------------------------------------------------------------------;
	lda	#56h
	sta	(logo_pal_index)
;-------------------------------------------------------------------------;
:	cmp	#30h
	bne	:+
;-------------------------------------------------------------------------;
	lda	#26h
	sta	(logo_pal_index)
;-------------------------------------------------------------------------;
:	cmp	#0ch
	bne	:+
;-------------------------------------------------------------------------;
	lda	#00h
	sta	(logo_pal_timer)
;-------------------------------------------------------------------------;
:	cmp	#3ch
	bne	:+
;-------------------------------------------------------------------------;
	lda	#00h
;-------------------------------------------------------------------------;
logo_exit:
;-------------------------------------------------------------------------;
	sta	(logo_pal_timer)
:	rts


;=========================================================================;
Scrolltext:
;=========================================================================;
	inc	RAM_STUFF+01fh
	lda	RAM_STUFF+01fh
	cmp	#04h
	bne	:-
;-------------------------------------------------------------------------;
	stz	RAM_STUFF+01fh

	rep	#10h

	ldx	RAM_STUFF+01bh
	inx
	lda	SCROLLTEXT,x
	bne	:+
;-------------------------------------------------------------------------;
	ldx	#0000h
;-------------------------------------------------------------------------;
:	stx	RAM_STUFF+01bh
	inc	RAM_STUFF+01dh
	lda	RAM_STUFF+01dh
	cmp	#00e0h
	bne	:+
;-------------------------------------------------------------------------;
	lda	#0c0h
	sta	RAM_STUFF+01dh
	lda	RAM_STUFF+01eh
	eor	#04h
	sta	RAM_STUFF+01eh
;-------------------------------------------------------------------------;
:	sep	#10h
	rts

;=========================================================================;
CreditSprite:
;=========================================================================;
	sep	#30h

	ldx	RAM_STUFF+015h
	ldy	#00h
;-------------------------------------------------------------------------;
:	lda	CREDIT_SPRITE_XPOS,y
	sta	REG_WMDATA
	lda	CREDIT_SPRITE_YPOS,x
	sbc	#08h
	sta	REG_WMDATA
	lda	CREDIT_SPRITE_TILE,y
	sec
	sbc	#20h
	sta	REG_WMDATA
	lda	#OAM_PAL2
	ora	RAM_STUFF+023h
	sta	REG_WMDATA
	dex
	dex
	dex
	dex
	iny
	cpy	#CREDIT_SPRITE_TILE_END-CREDIT_SPRITE_TILE
	bne	:-
;-------------------------------------------------------------------------;
	inc	RAM_STUFF+015h
	lda	RAM_STUFF+015h
	cmp	#38h
	bne	:+
;-------------------------------------------------------------------------;
	lda	#18h
	sta	RAM_STUFF+015h
:	rts


;=========================================================================;
ContactSpritePal:
;=========================================================================;
	lda	#177
	sta	REG_CGADD
	lda	RAM_STUFF+02bh
	sta	REG_CGDATA
	lda	RAM_STUFF+02ch
	sta	REG_CGDATA
	rts


;=========================================================================;
ContactSpriteFadeIn:
;=========================================================================;
	inc	RAM_STUFF+017h
	bne	:+++
;-------------------------------------------------------------------------;
	lda	#0fch
	sta	RAM_STUFF+017h
	ldx	RAM_STUFF+018h
	lda	CONTACT_SPRITE_PAL,x
	sta	RAM_STUFF+02bh
	inx
	lda	CONTACT_SPRITE_PAL,x
	sta	RAM_STUFF+02ch
	inc	RAM_STUFF+018h
	inc	RAM_STUFF+018h
	lda	RAM_STUFF+018h
	cmp	#22h
	bne	:+
;-------------------------------------------------------------------------;
	stz	RAM_STUFF+018h
	stz	RAM_STUFF+017h
	rts
;-------------------------------------------------------------------------;
:	cmp	#12h
	bne	:++
;-------------------------------------------------------------------------;
	lda	RAM_STUFF+016h
	cmp	#20h
	beq	:+
;-------------------------------------------------------------------------;
	clc
	adc	#20h
	sta	RAM_STUFF+016h
	rts
;-------------------------------------------------------------------------;
:	stz	RAM_STUFF+016h
:	rts


;=========================================================================;
ContactSprite:
;=========================================================================;
	ldx	#00h
	ldy	RAM_STUFF+016h
;-------------------------------------------------------------------------;
:	lda	CONTACT_SPRITE_XPOS,x
	clc
	adc	#0ch
	sta	REG_WMDATA
	lda	CONTACT_SPRITE_YPOS,x
	clc
	adc	#0bch
	sta	REG_WMDATA
	lda	CONTACT_SPRITE_TILE,y
	iny
	sta	REG_WMDATA
	lda	#OAM_PAL3|OAM_NT1
	ora	RAM_STUFF+022h
	sta	REG_WMDATA
	inc	RAM_STUFF+016h
	inx
	cpx	#20h
	bne	:-
;-------------------------------------------------------------------------;
	lda	RAM_STUFF+016h
	sec
	sbc	#20h
	sta	RAM_STUFF+016h
	rts


;=========================================================================;
MoveBG1Vert:
;=========================================================================;
	lda	#0e9h
	sta	RAM_BG1VOFS
	ldy	#01h
	ldx	RAM_STUFF+011h
;-------------------------------------------------------------------------;
:	lda	RAM_STUFF+012h
	clc
	adc	LIST_BG1VOFS,x
	sta	RAM_STUFF+012h
	sta	RAM_BG1VOFS,y
	iny
	lda	#01h
	sta	RAM_BG1VOFS,y
	inx
	iny
	cpy	#0d1h
	bne	:-
;-------------------------------------------------------------------------;
	lda	#0e2h
	sta	RAM_BG1VOFS,y
	iny
	lda	#01h
	sta	RAM_BG1VOFS,y
	iny
	lda	#0fh
	sta	RAM_BG1VOFS,y
	iny
	lda	#0e8h
	sta	RAM_BG1VOFS,y
	iny
	lda	#01h
	sta	RAM_BG1VOFS,y
	iny
	lda	#30h
	sta	RAM_BG1VOFS,y
	iny
	lda	#0e4h
	sta	RAM_BG1VOFS,y
	iny
	lda	#01h
	sta	RAM_BG1VOFS,y
	iny
	lda	#04h
	sta	RAM_BG1VOFS,y
	iny
	lda	#18h
	sta	RAM_BG1VOFS,y
	iny
	lda	#00h
	sta	RAM_BG1VOFS,y
	iny
	lda	#30h
	sta	RAM_BG1VOFS,y
	iny
	ldx	RAM_STUFF+00fh
	lda	SCROLLTEXT_VOFS,x
	clc
	adc	#18h
	sta	RAM_BG1VOFS,y
	iny
	lda	#00h
	sta	RAM_BG1VOFS,y
	iny
	sta	RAM_BG1VOFS,y
	lda	#0ffh
	sta	RAM_STUFF+012h
	inc	RAM_STUFF+013h
	ldx	RAM_STUFF+013h
	lda	LOGO_BG1VOFS,x
	sta	RAM_STUFF+011h
	rts


;=========================================================================;
MoveBG1Horiz:
;=========================================================================;
	lda	#0e9h
	sta	RAM_BG1HOFS
	ldx	#01h
	ldy	RAM_STUFF+00fh
;-------------------------------------------------------------------------;
:	lda	LIST_BG1HOFS,y
	clc
	adc	RAM_STUFF+014h
	sbc	#04h
	sta	RAM_BG1HOFS,x
	inx
	lda	#01h
	sta	RAM_BG1HOFS,x
	iny
	inx
	cpx	#0d1h
	bne	:-
;-------------------------------------------------------------------------;
	stz	RAM_BG1HOFS,x
	inx
	stz	RAM_BG1HOFS,x
	inx
	lda	#45h
	sta	RAM_BG1HOFS,x
	inx
	stz	RAM_BG1HOFS,x
	inx
	stz	RAM_BG1HOFS,x
	inx
	lda	#30h
	sta	RAM_BG1HOFS,x
	inx
	lda	RAM_STUFF+021h
	sta	RAM_BG1HOFS,x
	inx
	lda	RAM_STUFF+020h
	ldy	RAM_STUFF+021h
	bne	:+
;-------------------------------------------------------------------------;
	eor	#01h
	sta	RAM_STUFF+020h
;-------------------------------------------------------------------------;
:	sta	RAM_BG1HOFS,x
	inx
	stz	RAM_BG1HOFS,x
	inc	RAM_STUFF+0fh
	ldy	RAM_STUFF+0fh
	lda	LIST_BG1HOFS_OFFSET,y
	sta	RAM_STUFF+014h
	inc	RAM_STUFF+021h
	inc	RAM_STUFF+021h
	lda	RAM_STUFF+021h
	cmp	#48h
	beq	:+
;-------------------------------------------------------------------------;
	rts
;-------------------------------------------------------------------------;
:	lda	RAM_STUFF+022h
	eor	#OAM_PRI2
	sta	RAM_STUFF+022h
	lda	RAM_STUFF+023h
	eor	#OAM_PRI2
	sta	RAM_STUFF+023h
	rts


;=========================================================================;
BG3Ring:
;=========================================================================;
	ldx	RAM_STUFF+00eh
	lda	BG3_HSINE,x
	sta	RAM_STUFF+008h
	lda	BG3_VSINE,x
	sta	RAM_STUFF+009h
	inc	RAM_STUFF+00eh
	rts


;=========================================================================;
MoveRings:
;=========================================================================;
	ldx	RAM_STUFF+00bh
	lda	RING_SINE,x
	cmp	#0d3h
	bne	:+
;-------------------------------------------------------------------------;
	lda	#0d4h
;-------------------------------------------------------------------------;
:	sta	RAM_STUFF+006h
	adc	#2dh
	tax
	lda	LIST_M7A,x
	sta	REG_M7A
	stz	REG_M7A
	ldx	RAM_STUFF+00ch
	lda	LIST_M7B,x
	sta	REG_M7B

	rep	#20h

	lda	REG_MPYL
	lsr
	lsr
	lsr
	lsr
	lsr
	lsr
	lsr

	sep	#20h

	sta	RAM_STUFF+007h
	lda	RAM_STUFF+006h
	bmi	:+
;-------------------------------------------------------------------------;
	jsr	Times2DivideBy3
	sta	RAM_STUFF+004h
	lsr
	sta	RAM_STUFF+002h
	bra	:+++
;-------------------------------------------------------------------------;
:	eor	#0ffh
	jsr	Times2DivideBy3
	tax
	eor	#0ffh
	cmp	#0e2h
	bne	:+
;-------------------------------------------------------------------------;
	lda	#0e3h
;-------------------------------------------------------------------------;
:	sta	RAM_STUFF+004h
	txa
	lsr
	eor	#0ffh
	sta	RAM_STUFF+002h
;-------------------------------------------------------------------------;
:	lda	RAM_STUFF+007h
	bmi	:+
;-------------------------------------------------------------------------;
	jsr	Times2DivideBy3
	sta	RAM_STUFF+005h
	lsr
	sta	RAM_STUFF+003h
	bra	:++
;-------------------------------------------------------------------------;
:	eor	#0ffh
	jsr	Times2DivideBy3
	tax
	eor	#0ffh
	sta	RAM_STUFF+005h
	txa
	lsr
	eor	#0ffh
	sta	RAM_STUFF+003h
;-------------------------------------------------------------------------;
:	inc	RAM_STUFF+00bh
	inc	RAM_STUFF+00ch
	inc	RAM_STUFF+00ch
	rts


;=========================================================================;
Times2DivideBy3:
;=========================================================================;
	asl
	sta	REG_WRDIVL
	stz	REG_WRDIVH
	lda	#03h
	sta	REG_WRDIVB
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	lda	REG_RDDIVL
	rts


;=========================================================================;
BG3HV:
;=========================================================================;
	lda	RAM_STUFF+008h
	eor	#0ffh
	sta	REG_BG3HOFS
	stz	REG_BG3HOFS
	lda	RAM_STUFF+009h
	eor	#0ffh
	sta	REG_BG3VOFS
	stz	REG_BG3VOFS
	rts


;=========================================================================;
BG2Ring:
;=========================================================================;
	lda	RAM_STUFF+008h
	eor	#0ffh
	sta	RAM_STUFF+00ah
	lda	RAM_STUFF+002h
	eor	#0ffh
	clc
	adc	#0e8h
	adc	RAM_STUFF+00ah
	sta	RAM_STUFF+019h
	lda	RAM_STUFF+009h
	eor	#0ffh
	sta	RAM_STUFF+00ah
	lda	RAM_STUFF+003h
	eor	#0ffh
	clc
	adc	#0e8h
	adc	RAM_STUFF+00ah
	sta	RAM_STUFF+01ah
	rts


;=========================================================================;
BG2HV:
;=========================================================================;
	lda	RAM_STUFF+019h
	sta	REG_BG2HOFS
	stz	REG_BG2HOFS
	lda	RAM_STUFF+01ah
	sta	REG_BG2VOFS
	stz	REG_BG2VOFS
	rts


;=========================================================================;
LargeSpriteRing:
;=========================================================================;
	ldy	#00h
;-------------------------------------------------------------------------;
:	lda	LARGE_RING_SPRITE_XPOS,y
	clc
	adc	RAM_STUFF+004h
	clc
	adc	RAM_STUFF+008h
	clc
	adc	#31h
	sta	REG_WMDATA
	lda	LARGE_RING_SPRITE_YPOS,y
	clc
	adc	RAM_STUFF+005h
	clc
	adc	RAM_STUFF+009h
	clc
	adc	#30h
	sta	REG_WMDATA
	lda	LARGE_RING_SPRITE_TILE,y
	sta	REG_WMDATA
	lda	#OAM_PRI2|OAM_NT1
	sta	REG_WMDATA
	iny
	cpy	#39h
	bne	:-

	rts


;=========================================================================;
SmallSpriteRing:
;=========================================================================;
	ldy	#00h
;-------------------------------------------------------------------------;
:	lda	SMALL_RING_SPRITE_XPOS,y
	clc
	adc	RAM_STUFF+006h
	clc
	adc	RAM_STUFF+008h
	clc
	adc	#49h
	sta	REG_WMDATA
	lda	SMALL_RING_SPRITE_YPOS,y
	clc
	adc	RAM_STUFF+007h
	clc
	adc	RAM_STUFF+009h
	clc
	adc	#48h
	sta	REG_WMDATA
	lda	SMALL_RING_SPRITE_TILE,y
	sta	REG_WMDATA
	lda	#OAM_PRI2|OAM_NT1
	sta	REG_WMDATA
	iny
	cpy	#18h
	bne	:-
	rts


;=========================================================================;
Setup:
;=========================================================================;
	lda	#01h
	stz	REG_M7A
	sta	REG_M7A
	stz	REG_M7D
	sta	REG_M7D
	sta	RAM_STUFF+02fh
	sta	RAM_STUFF+044h

	ina
	sta	REG_CGSWSEL
	lda	#37h
	sta	REG_CGADSUB
	lda	#0e0h
	sta	REG_COLDATA
	sta	RAM_STUFF+043h

	lda	#18h
	sta	RAM_STUFF+009h

	lda	#2ah
	sta	RAM_STUFF+008h

	lda	#30h
	sta	RAM_STUFF+022h

	stz	RAM_STUFF
	stz	RAM_STUFF+001h
	stz	RAM_STUFF+002h
	stz	RAM_STUFF+003h
	stz	RAM_STUFF+004h
	stz	RAM_STUFF+005h
	stz	RAM_STUFF+006h
	stz	RAM_STUFF+007h
	stz	RAM_STUFF+00Bh

	lda	#40h
	sta	RAM_STUFF+00ch
	stz	RAM_STUFF+00dh
	stz	RAM_STUFF+00eh
	stz	RAM_STUFF+00fh
	stz	RAM_STUFF+011h

	lda	#0fah
	sta	RAM_STUFF+012h
	stz	RAM_STUFF+013h

	lda	#18h
	sta	RAM_STUFF+015h
	stz	RAM_STUFF+016h
	stz	RAM_STUFF+017h
	stz	RAM_STUFF+018h
	stz	RAM_STUFF+002h
	stz	RAM_STUFF+003h
	stz	RAM_STUFF+01bh
	stz	RAM_STUFF+01ch

	lda	#0d0h
	sta	RAM_STUFF+01dh

	lda	#33h
	sta	RAM_STUFF+01eh
	stz	RAM_STUFF+01fh
	stz	RAM_STUFF+020h
	stz	RAM_STUFF+021h

	lda	#OAM_PRI1
	sta	RAM_STUFF+023h
	stz	RAM_STUFF+024h

	lda	#0ch
	sta	RAM_STUFF+025h
	sta	RAM_STUFF+027h
	sta	RAM_STUFF+029h
	sta	RAM_STUFF+02ah

	lda	#06h
	sta	RAM_STUFF+028h
	lda	#80h
	sta	RAM_STUFF+02bh
	lda	#7ah
	sta	RAM_STUFF+02ch

	stz	RAM_STUFF+026h
	stz	RAM_STUFF+02dh
	stz	RAM_STUFF+02eh
	stz	RAM_STUFF+030h
	stz	RAM_STUFF+040h
	stz	RAM_STUFF+041h
	stz	RAM_STUFF+042h
	stz	RAM_STUFF+046h
	stz	RAM_STUFF+047h
	stz	RAM_STUFF+04bh
	stz	RAM_STUFF+04ch

	lda	#BG1MAP>>9|SC_64x64
	sta	REG_BG1SC
	lda	#BG2MAP>>9
	sta	REG_BG2SC
	lda	#BG3MAP>>9
	sta	REG_BG3SC
	lda	#BG4MAP>>9
	sta	REG_BG4SC
	lda	#BG2GFX>>9+BG1GFX>>13
	sta	REG_BG12NBA
	lda	#BG3GFX>>9+BG3GFX>>13
	sta	REG_BG34NBA
	lda	#TM_OBJ|TM_BG4|TM_BG3|TM_BG2|TM_BG1
	sta	REG_TM

	ldx	#00h
;-------------------------------------------------------------------------;
:	lda	INITIAL_LOGO_PAL,x
	sta	RAM_CGDATA0,x
	inx
	cpx	#30h
	bne	:-
;-------------------------------------------------------------------------;
	jsr	SetupStarField

	lda	#DMAP_XFER_MODE_2
	sta	REG_DMAP0
	sta	REG_DMAP1
	sta	REG_DMAP2

	lda	#<REG_BG4HOFS
	sta	REG_BBAD0
	stz	REG_A1T0L
	lda	#>RAM_BG4HOFS
	sta	REG_A1T0H
	stz	REG_A1B0

	lda	#<REG_BG1HOFS
	sta	REG_BBAD1
	stz	REG_A1T1L
	lda	#>RAM_BG1HOFS
	sta	REG_A1T1H
	stz	REG_A1B1

	lda	#<REG_BG1VOFS
	sta	REG_BBAD2
	stz	REG_A1T2L
	lda	#>RAM_BG1VOFS
	sta	REG_A1T2H
	stz	REG_A1B2

	lda	#DMAP_XFER_MODE_3
	sta	REG_DMAP3
	sta	REG_DMAP4
	sta	REG_DMAP5

	lda	#<REG_CGADD
	sta	REG_BBAD3
	sta	REG_BBAD4
	sta	REG_BBAD5

	stz	REG_A1T3L
	lda	#>RAM_CGDATA1
	sta	REG_A1T3H
	stz	REG_A1B3

	stz	REG_A1T4L
	lda	#>RAM_CGDATA2
	sta	REG_A1T4H
	stz	REG_A1B4

	stz	REG_A1T5L
	lda	#>RAM_CGDATA3
	sta	REG_A1T5H
	stz	REG_A1B5

	rep	#10h

	lda	#^RAM_LOGO_MAP
	sta	REG_WMADDH
	ldx	#.loword(RAM_LOGO_MAP)
	stx	REG_WMADDL		; set work ram to RAM_LOGO_MAP

	lda	#^gfx_censor_ring_logoMap
	ldy	#.loword(gfx_censor_ring_logoMap)
	ldx	#0320h			; bytes to transfer
	jsr	DMAtoRAM		; transfer map to ram

	ldx	#(BG1MAP/2)+20h
	stx	REG_VMADDL
	ldx	#0080h			; map index, skip ascii char
	ldy	#0000h			; palette data index
;-------------------------------------------------------------------------;
:	lda	RAM_LOGO_MAP,x
	sta	REG_VMDATAL
	inx
	inx
	lda	LOGO_MAP_PAL,y
	sta	REG_VMDATAH
	iny
	cpy	#LOGO_MAP_PAL_END-LOGO_MAP_PAL
	bne	:-
;-------------------------------------------------------------------------;
	ldx	#(BG1MAP/2)+140h
	stx	REG_VMADDL
	ldx	#0000h
	txy

	rep	#20h

	lda	#3c00h|TOP_BAR		; 3ch = palette
;-------------------------------------------------------------------------;
:	sta	REG_VMDATAL
	iny
	cpy	#20h
	bne	:-
;-------------------------------------------------------------------------;
	sep	#20h
;-------------------------------------------------------------------------;
:	lda	CENTER_TEXT,x
	sec
	sbc	#20h
	sta	REG_VMDATAL
	lda	#3ch
	sta	REG_VMDATAH
	inx
	cpx	#CENTER_TEXT_END-CENTER_TEXT
	bne	:-
;-------------------------------------------------------------------------;
	rep	#20h

	lda	#3c00h|BOT_BAR
;-------------------------------------------------------------------------;
:	sta	REG_VMDATAL
	iny
	cpy	#40h
	bne	:-
;-------------------------------------------------------------------------;
	rep	#30h

	ldx	#0001h			; star tile
	lda	#BG4MAP/2
;-------------------------------------------------------------------------;
:	sta	REG_VMADDL
	stx	REG_VMDATAL
	clc
	adc	#0020h
	cmp	#(BG4MAP/2)+400h
	bne	:-
;-------------------------------------------------------------------------;
	sep	#20h

	DoCopyPalette gfx_censor_ring_bg2Pal, 32, 4
	DoCopyPalette gfx_censor_ring_bg3Pal, 64, 4
	DoCopyPalette gfx_censor_ring_sprPal, 128, 16

	DoDecompressDataVram gfx_censor_8x8_c64Tiles, OAMGFX		; NT0
	DoDecompressDataVram gfx_censor_ring_sprTiles, OAMGFX+2000h	; NT1
	DoDecompressDataVram gfx_censor_ring_logoTiles, BG1GFX
	DoDecompressDataVram gfx_censor_ring_bg2Tiles, BG2GFX
	DoDecompressDataVram gfx_censor_ring_bg2Map, BG2MAP
	DoDecompressDataVram gfx_censor_ring_bg3Tiles, BG3GFX
	DoDecompressDataVram gfx_censor_ring_bg3Map, BG3MAP

	stz	REG_OBSEL

	ldx	#oam_table&65535
	stx	REG_WMADDL
	lda	#^oam_table
	sta	REG_WMADDH

	ldx	#128
	lda	#224
:	sta	REG_WMDATA
	sta	REG_WMDATA
	stz	REG_WMDATA
	stz	REG_WMDATA
	dex
	bpl	:-

	ldx	#(BG3MAP/2)+01h		; remove star tile from bg3 map
	stx	REG_VMADDL
	stz	REG_VMDATAL
	stz	REG_VMDATAH

	sep	#30h

	stz	REG_CGADD
	ldx	#00h
;-------------------------------------------------------------------------;
:	lda	SCROLLTEXT_PAL,x
	sta	REG_CGDATA
	inx
	cpx	#08h
	bne	:-
;-------------------------------------------------------------------------;
	lda	#60h
	sta	REG_CGADD
	stz	REG_CGDATA
	stz	REG_CGDATA
	ldx	#00h
;-------------------------------------------------------------------------;
:	lda	STAR_PAL,x
	sta	REG_CGDATA
	inx
	cpx	#07h
	bne	:-
;-------------------------------------------------------------------------;
	lda	#NMI_ON|NMI_JOYPAD
	sta	REG_NMITIMEN

	lda	#1
	sta	frame_ready

	rts


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
BG3_HSINE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$2a,$2b,$2c,$2d,$2d,$2e,$2e,$2e
	.byte	$2e,$2d,$2c,$2b,$2a,$28,$27,$25
	.byte	$23,$20,$1e,$1c,$1a,$18,$17,$15
	.byte	$14,$14,$14,$14,$15,$16,$17,$1a
	.byte	$1c,$1f,$23,$26,$2a,$2e,$32,$36
	.byte	$3a,$3e,$42,$45,$48,$4a,$4c,$4d
	.byte	$4e,$4e,$4d,$4c,$4a,$48,$45,$41
	.byte	$3d,$39,$34,$2f,$2a,$25,$20,$1b
	.byte	$17,$12,$0e,$0b,$08,$06,$05,$04
	.byte	$04,$04,$05,$07,$0a,$0d,$10,$14
	.byte	$18,$1c,$21,$25,$2a,$2e,$33,$37
	.byte	$3a,$3d,$40,$42,$44,$45,$46,$46
	.byte	$46,$45,$43,$42,$3f,$3d,$3a,$38
	.byte	$35,$32,$2f,$2d,$2a,$28,$26,$24
	.byte	$23,$21,$21,$20,$20,$20,$21,$22
	.byte	$22,$23,$24,$26,$27,$28,$29,$29
	.byte	$2a,$2a,$2a,$2a,$2a,$29,$29,$27
	.byte	$26,$25,$23,$22,$20,$1f,$1d,$1c
	.byte	$1b,$1a,$1a,$1a,$1a,$1b,$1c,$1d
	.byte	$1f,$21,$24,$27,$2a,$2d,$31,$34
	.byte	$38,$3b,$3e,$41,$44,$46,$48,$4a
	.byte	$4a,$4b,$4a,$49,$48,$46,$43,$40
	.byte	$3c,$38,$34,$2f,$2a,$25,$20,$1b
	.byte	$17,$13,$0f,$0b,$08,$06,$04,$03
	.byte	$03,$03,$04,$06,$08,$0b,$0f,$13
	.byte	$17,$1b,$20,$25,$2a,$2f,$33,$38
	.byte	$3c,$40,$43,$46,$48,$49,$4a,$4b
	.byte	$4a,$4a,$48,$46,$44,$41,$3e,$3b
	.byte	$38,$34,$31,$2d,$2a,$27,$24,$21
	.byte	$1f,$1d,$1c,$1b,$1a,$1a,$1a,$1a
	.byte	$1b,$1c,$1d,$1f,$20,$22,$23,$25
	.byte	$26,$27,$29,$29,$2a,$2a,$2a,$2a
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
BG3_VSINE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$1d,$1e,$1f,$1f,$20,$21,$21,$21
	.byte	$22,$22,$21,$21,$21,$20,$1f,$1e
	.byte	$1d,$1c,$1a,$19,$18,$16,$15,$13
	.byte	$12,$11,$0f,$0e,$0e,$0d,$0c,$0c
	.byte	$0c,$0c,$0c,$0d,$0e,$0e,$0f,$11
	.byte	$12,$13,$15,$16,$18,$19,$1a,$1c
	.byte	$1d,$1e,$1f,$20,$21,$21,$21,$22
	.byte	$22,$21,$21,$21,$20,$1f,$1f,$1e
	.byte	$1d,$1c,$1b,$1b,$1a,$19,$19,$19
	.byte	$18,$18,$19,$19,$19,$1a,$1b,$1c
	.byte	$1d,$1e,$20,$21,$22,$24,$25,$27
	.byte	$28,$29,$2b,$2c,$2c,$2d,$2e,$2e
	.byte	$2e,$2e,$2e,$2d,$2c,$2c,$2b,$29
	.byte	$28,$27,$25,$24,$22,$21,$20,$1e
	.byte	$1d,$1c,$1b,$1a,$19,$19,$19,$18
	.byte	$18,$19,$19,$19,$1a,$1b,$1b,$1c
	.byte	$1d,$1e,$1f,$1f,$20,$21,$21,$21
	.byte	$22,$22,$21,$21,$21,$20,$1f,$1e
	.byte	$1d,$1c,$1a,$19,$18,$16,$15,$13
	.byte	$12,$11,$0f,$0e,$0e,$0d,$0c,$0c
	.byte	$0c,$0c,$0c,$0d,$0e,$0e,$0f,$11
	.byte	$12,$13,$15,$16,$18,$19,$1a,$1c
	.byte	$1d,$1e,$1f,$20,$21,$21,$21,$22
	.byte	$22,$21,$21,$21,$20,$1f,$1f,$1e
	.byte	$1d,$1c,$1b,$1b,$1a,$19,$19,$19
	.byte	$18,$18,$19,$19,$19,$1a,$1b,$1c
	.byte	$1d,$1e,$20,$21,$22,$24,$25,$27
	.byte	$28,$29,$2b,$2c,$2c,$2d,$2e,$2e
	.byte	$2e,$2e,$2e,$2d,$2c,$2c,$2b,$29
	.byte	$28,$27,$25,$24,$22,$21,$20,$1e
	.byte	$1d,$1c,$1b,$1a,$19,$19,$19,$18
	.byte	$18,$19,$19,$19,$1a,$1b,$1b,$1c
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
CENTER_TEXT:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	"        THE LIVING LEGEND       "
	.byte	"       CENSOR IS BACK WITH      "
	.byte	"                                "
	.byte	"         ANOTHER RELEASE        "
	.byte	"                                "
	.byte	"     ...FOLLOW THE LEADER...    "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
CENTER_TEXT_END:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
CENTER_TEXT_PAL1:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$08,$00,$0a,$08,$0a,$08,$4c,$10
	.byte	$4e,$18,$90,$20,$90,$28,$d2,$30
	.byte	$d4,$38,$16,$41,$56,$49,$98,$51
	.byte	$da,$61,$1a,$6a,$5c,$72,$9e,$7a
	.byte	$9e,$7a,$5c,$72,$1a,$6a,$da,$61
	.byte	$98,$51,$56,$49,$16,$41,$d4,$38
	.byte	$d2,$30,$90,$28,$90,$20,$4e,$18
	.byte	$4c,$10,$0a,$08,$0a,$08,$08,$00
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
CENTER_TEXT_PAL2:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$c6,$18,$06,$21,$08,$21,$48,$29
	.byte	$48,$29,$8a,$31,$8a,$31,$ca,$39
	.byte	$cc,$39,$0c,$42,$0c,$42,$4e,$4a
	.byte	$4e,$4a,$8e,$52,$8e,$52,$ce,$5a
	.byte	$d0,$5a,$10,$63,$10,$63,$50,$6b
	.byte	$10,$63,$10,$63,$d0,$5a,$ce,$5a
	.byte	$8e,$52,$8e,$52,$4e,$4a,$4e,$4a
	.byte	$0c,$42,$0c,$42,$cc,$39,$ca,$39
	.byte	$8a,$31,$8a,$31,$48,$29,$48,$29
	.byte	$08,$21,$06,$21,$c6,$18,$c6,$18
	.byte	$06,$21,$08,$21,$48,$29,$48,$29
	.byte	$8a,$31,$8a,$31,$ca,$39,$cc,$39
	.byte	$0c,$42,$0c,$42,$4e,$4a,$4e,$4a
	.byte	$8e,$52,$8e,$52,$ce,$5a,$d0,$5a
	.byte	$10,$63,$10,$63,$50,$6b,$10,$63
	.byte	$10,$63,$d0,$5a,$ce,$5a,$8e,$52
	.byte	$8e,$52,$4e,$4a,$4e,$4a,$0c,$42
	.byte	$0c,$42,$cc,$39,$ca,$39,$8a,$31
	.byte	$8a,$31,$48,$29,$48,$29,$08,$21
	.byte	$06,$21,$c6,$18
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
CENTER_TEXT_PAL3:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$84,$10,$c4,$18,$c6,$18,$06,$21
	.byte	$08,$21,$48,$29,$48,$29,$8a,$31
	.byte	$8a,$31,$ca,$39,$cc,$39,$0c,$42
	.byte	$0c,$42,$4e,$4a,$4e,$4a,$8e,$52
	.byte	$8e,$52,$ce,$5a,$d0,$5a,$10,$63
	.byte	$d0,$5a,$ce,$5a,$8e,$52,$8e,$52
	.byte	$4e,$4a,$4e,$4a,$0c,$42,$0c,$42
	.byte	$cc,$39,$ca,$39,$8a,$31,$8a,$31
	.byte	$48,$29,$48,$29,$08,$21,$06,$21
	.byte	$c6,$18,$c4,$18,$84,$10,$84,$10
	.byte	$c4,$18,$c6,$18,$06,$21,$08,$21
	.byte	$48,$29,$48,$29,$8a,$31,$8a,$31
	.byte	$ca,$39,$cc,$39,$0c,$42,$0c,$42
	.byte	$4e,$4a,$4e,$4a,$8e,$52,$8e,$52
	.byte	$ce,$5a,$d0,$5a,$10,$63,$d0,$5a
	.byte	$ce,$5a,$8e,$52,$8e,$52,$4e,$4a
	.byte	$4e,$4a,$0c,$42,$0c,$42,$cc,$39
	.byte	$ca,$39,$8a,$31,$8a,$31,$48,$29
	.byte	$48,$29,$08,$21,$06,$21,$c6,$18
	.byte	$c4,$18,$84,$10
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
CENTER_TEXT_PAL4:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$42,$08,$82,$10,$84,$10,$c4,$18
	.byte	$c6,$18,$06,$21,$08,$21,$48,$29
	.byte	$48,$29,$8a,$31,$8a,$31,$ca,$39
	.byte	$cc,$39,$0c,$42,$0c,$42,$4e,$4a
	.byte	$4e,$4a,$8e,$52,$8e,$52,$ce,$5a
	.byte	$8e,$52,$8e,$52,$4e,$4a,$4e,$4a
	.byte	$0c,$42,$0c,$42,$cc,$39,$ca,$39
	.byte	$8a,$31,$8a,$31,$48,$29,$48,$29
	.byte	$08,$21,$06,$21,$c6,$18,$c4,$18
	.byte	$84,$10,$82,$10,$42,$08,$42,$08
	.byte	$82,$10,$84,$10,$c4,$18,$c6,$18
	.byte	$06,$21,$08,$21,$48,$29,$48,$29
	.byte	$8a,$31,$8a,$31,$ca,$39,$cc,$39
	.byte	$0c,$42,$0c,$42,$4e,$4a,$4e,$4a
	.byte	$8e,$52,$8e,$52,$ce,$5a,$8e,$52
	.byte	$8e,$52,$4e,$4a,$4e,$4a,$0c,$42
	.byte	$0c,$42,$cc,$39,$ca,$39,$8a,$31
	.byte	$8a,$31,$48,$29,$48,$29,$08,$21
	.byte	$06,$21,$c6,$18,$c4,$18,$84,$10
	.byte	$82,$10,$42,$08,$00,$00,$00,$00
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
CONTACT_SPRITE_PAL:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$80,$7a,$c0,$6a,$c0,$52,$40,$3a
	.byte	$c0,$21,$40,$11,$c0,$08,$40,$00
	.byte	$00,$00,$40,$00,$c0,$08,$40,$11
	.byte	$c0,$21,$40,$3a,$c0,$52,$c0,$6a
	.byte	$80,$7a
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
CONTACT_SPRITE_TILE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$00,$01,$02,$03,$04,$05,$06,$07
	.byte	$10,$11,$12,$13,$14,$15,$16,$17
	.byte	$20,$21,$22,$23,$24,$25,$26,$27
	.byte	$30,$31,$32,$33,$34,$35,$36,$37

	.byte	$08,$09,$0a,$0b,$0c,$0d,$0e,$0f
	.byte	$18,$19,$1a,$1b,$1c,$1d,$1e,$1f
	.byte	$28,$29,$2a,$2b,$2c,$2d,$2e,$2f
	.byte	$38,$39,$3a,$3b,$3c,$3d,$3e,$3f
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
CONTACT_SPRITE_XPOS:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$00,$08,$10,$18,$20,$28,$30,$38
	.byte	$00,$08,$10,$18,$20,$28,$30,$38
	.byte	$00,$08,$10,$18,$20,$28,$30,$38
	.byte	$00,$08,$10,$18,$20,$28,$30,$38
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
CONTACT_SPRITE_YPOS:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$08,$08,$08,$08,$08,$08,$08,$08
	.byte	$10,$10,$10,$10,$10,$10,$10,$10
	.byte	$18,$18,$18,$18,$18,$18,$18,$18
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
CREDIT_SPRITE_PAL:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$18,$63,$18,$3b,$1a,$13,$98,$12
	.byte	$16,$12,$94,$11,$52,$11,$10,$11
	.byte	$ce,$10,$0c,$21,$4a,$29,$0c,$21
	.byte	$ce,$10,$10,$11,$52,$11,$94,$11
	.byte	$16,$12,$98,$12,$1a,$13,$18,$3b
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
CREDIT_SPRITE_TILE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	"geggin"
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
CREDIT_SPRITE_TILE_END:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
CREDIT_SPRITE_XPOS:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$cb,$d2,$d9,$e0,$e6,$ec
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
CREDIT_SPRITE_YPOS:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$c1,$c1,$c2,$c2,$c3,$c4,$c6,$c7
	.byte	$c9,$cb,$cd,$cf,$d1,$d4,$d6,$d8
	.byte	$d6,$d4,$d2,$cf,$cd,$cb,$c9,$c8
	.byte	$c6,$c5,$c3,$c2,$c2,$c1,$c1,$c1
	.byte	$c1,$c1,$c2,$c2,$c3,$c4,$c6,$c7
	.byte	$c9,$cb,$cd,$cf,$d1,$d4,$d6,$d8
	.byte	$d6,$d4,$d2,$cf,$cd,$cb,$c9,$c8 
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
INITIAL_LOGO_PAL:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.word	$0000,$5a00,$49c0,$4180,$0000,$4180,$3140,$2900
	.word	$0000,$5a00,$49c0,$4180,$0000,$4180,$3140,$2900
	.word	$0000,$5a00,$49c0,$4180,$0000,$4180,$3140,$2900
	.word	$0000,$5a14,$59d4,$5192
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LARGE_RING_SPRITE_TILE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$41,$42,$43,$44,$45,$46,$47,$48
	.byte	$49,$4a,$4b,$4c,$4d,$4e,$4f,$50
	.byte	$51,$52,$53,$54,$55,$56,$57,$58
	.byte	$59,$5a,$5b,$5c,$5d,$5e,$5f,$60
	.byte	$61,$62,$63,$64,$65,$66,$67,$68
	.byte	$69,$6a,$6b,$6c,$6d,$6e,$6f,$70
	.byte	$71,$72,$73,$74,$75,$76,$70,$77
	.byte	$78
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LARGE_RING_SPRITE_XPOS:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$10,$18,$20,$28,$30,$38,$08,$10
	.byte	$18,$20,$28,$30,$38,$40,$00,$08
	.byte	$10,$38,$40,$48,$00,$08,$40,$48
	.byte	$00,$08,$48,$50,$00,$08,$48,$50
	.byte	$00,$08,$40,$48,$00,$08,$10,$40
	.byte	$48,$08,$10,$18,$30,$38,$40,$48
	.byte	$10,$18,$20,$28,$30,$38,$40,$20
	.byte	$28
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LARGE_RING_SPRITE_YPOS:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$00,$00,$00,$00,$00,$00,$08,$08
	.byte	$08,$08,$08,$08,$08,$08,$10,$10
	.byte	$10,$10,$10,$10,$18,$18,$18,$18
	.byte	$20,$20,$20,$20,$28,$28,$28,$28
	.byte	$30,$30,$30,$30,$38,$38,$38,$38
	.byte	$38,$40,$40,$40,$40,$40,$40,$40
	.byte	$48,$48,$48,$48,$48,$48,$48,$50
	.byte	$50
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_BG1HOFS:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$0f,$0f,$10,$10,$10,$11,$11,$11
	.byte	$12,$12,$12,$12,$13,$13,$13,$13
	.byte	$13,$13,$13,$13,$13,$13,$13,$12
	.byte	$12,$12,$12,$11,$11,$10,$10,$10
	.byte	$0f,$0e,$0e,$0d,$0d,$0c,$0c,$0b
	.byte	$0a,$0a,$09,$08,$08,$07,$06,$06
	.byte	$05,$05,$04,$04,$03,$03,$02,$02
	.byte	$01,$01,$01,$01,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$01,$01,$01
	.byte	$01,$02,$02,$03,$03,$04,$04,$05
	.byte	$05,$06,$06,$07,$08,$08,$09,$0a
	.byte	$0a,$0b,$0c,$0c,$0d,$0d,$0e,$0e
	.byte	$0f,$10,$10,$10,$11,$11,$12,$12
	.byte	$12,$12,$13,$13,$13,$13,$13,$13
	.byte	$13,$13,$13,$13,$13,$12,$12,$12
	.byte	$12,$11,$11,$11,$10,$10,$10,$0f
	.byte	$0f,$0f,$0e,$0e,$0e,$0d,$0d,$0d
	.byte	$0c,$0c,$0c,$0c,$0b,$0b,$0b,$0b
	.byte	$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0c
	.byte	$0c,$0c,$0c,$0d,$0d,$0e,$0e,$0e
	.byte	$0f,$10,$10,$11,$11,$12,$12,$13
	.byte	$14,$14,$15,$16,$16,$17,$18,$18
	.byte	$19,$19,$1a,$1a,$1b,$1b,$1c,$1c
	.byte	$1d,$1d,$1d,$1d,$1e,$1e,$1e,$1e
	.byte	$1e,$1e,$1e,$1e,$1e,$1d,$1d,$1d
	.byte	$1d,$1c,$1c,$1b,$1b,$1a,$1a,$19
	.byte	$19,$18,$18,$17,$16,$16,$15,$14
	.byte	$14,$13,$12,$12,$11,$11,$10,$10
	.byte	$0f,$0e,$0e,$0e,$0d,$0d,$0c,$0c
	.byte	$0c,$0c,$0b,$0b,$0b,$0b,$0b,$0b
	.byte	$0b,$0b,$0b,$0b,$0b,$0c,$0c,$0c
	.byte	$0c,$0d,$0d,$0d,$0e,$0e,$0e,$0f
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_BG1HOFS_OFFSET:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$b8,$ba,$bb,$bd,$be,$c0,$c2,$c3
	.byte	$c5,$c6,$c8,$c9,$ca,$cc,$cd,$ce
	.byte	$cf,$d0,$d2,$d3,$d3,$d4,$d5,$d6
	.byte	$d6,$d7,$d8,$d8,$d8,$d9,$d9,$d9
	.byte	$d9,$d9,$d9,$d9,$d8,$d8,$d8,$d7
	.byte	$d6,$d6,$d5,$d4,$d3,$d3,$d2,$d0
	.byte	$cf,$ce,$cd,$cc,$ca,$c9,$c8,$c6
	.byte	$c5,$c3,$c2,$c0,$be,$bd,$bb,$ba
	.byte	$b8,$b6,$b5,$b3,$b2,$b0,$ae,$ad
	.byte	$ab,$aa,$a8,$a7,$a6,$a4,$a3,$a2
	.byte	$a1,$a0,$9e,$9d,$9d,$9c,$9b,$9a
	.byte	$9a,$99,$98,$98,$98,$97,$97,$97
	.byte	$97,$97,$97,$97,$98,$98,$98,$99
	.byte	$9a,$9a,$9b,$9c,$9d,$9d,$9e,$a0
	.byte	$a1,$a2,$a3,$a4,$a6,$a7,$a8,$aa
	.byte	$ab,$ad,$ae,$b0,$b2,$b3,$b5,$b6
	.byte	$b8,$ba,$bb,$bd,$be,$c0,$c2,$c3
	.byte	$c5,$c6,$c8,$c9,$ca,$cc,$cd,$ce
	.byte	$cf,$d0,$d2,$d3,$d3,$d4,$d5,$d6
	.byte	$d6,$d7,$d8,$d8,$d8,$d9,$d9,$d9
	.byte	$d9,$d9,$d9,$d9,$d8,$d8,$d8,$d7
	.byte	$d6,$d6,$d5,$d4,$d3,$d3,$d2,$d0
	.byte	$cf,$ce,$cd,$cc,$ca,$c9,$c8,$c6
	.byte	$c5,$c3,$c2,$c0,$be,$bd,$bb,$ba
	.byte	$b8,$b6,$b5,$b3,$b2,$b0,$ae,$ad
	.byte	$ab,$aa,$a8,$a7,$a6,$a4,$a3,$a2
	.byte	$a1,$a0,$9e,$9d,$9d,$9c,$9b,$9a
	.byte	$9a,$99,$98,$98,$98,$97,$97,$97
	.byte	$97,$97,$97,$97,$98,$98,$98,$99
	.byte	$9a,$9a,$9b,$9c,$9d,$9d,$9e,$a0
	.byte	$a1,$a2,$a3,$a4,$a6,$a7,$a8,$aa
	.byte	$ab,$ad,$ae,$b0,$b2,$b3,$b5,$b6
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_BG1VOFS:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$ff,$00,$ff,$ff,$00,$ff,$ff
	.byte	$ff,$00,$ff,$ff,$ff,$ff,$00,$ff
	.byte	$ff,$ff,$ff,$ff,$00,$ff,$ff,$ff
	.byte	$ff,$ff,$ff,$00,$ff,$ff,$ff,$ff
	.byte	$ff,$00,$ff,$ff,$ff,$ff,$00,$ff
	.byte	$ff,$ff,$00,$ff,$ff,$00,$ff,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_INIDISP:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	.byte	$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	.byte	$0f,$0e,$0d,$0c,$0b,$0a,$09,$08
	.byte	$07,$06,$05,$04,$03,$02,$01,$00
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_M7A:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$00,$1b,$25,$2e,$34,$3a,$3f,$44
	.byte	$48,$4c,$50,$53,$56,$59,$5c,$5f
	.byte	$61,$63,$66,$68,$6a,$6b,$6d,$6f
	.byte	$70,$72,$73,$74,$76,$77,$78,$79
	.byte	$7a,$7a,$7b,$7c,$7c,$7d,$7d,$7e
	.byte	$7e,$7e,$7f,$7f,$7f,$7f,$7f,$7f
	.byte	$7f,$7e,$7e,$7e,$7d,$7d,$7c,$7c
	.byte	$7b,$7a,$7a,$79,$78,$77,$76,$74
	.byte	$73,$72,$70,$6f,$6d,$6b,$6a,$68
	.byte	$66,$63,$61,$5f,$5c,$59,$56,$53
	.byte	$50,$4c,$48,$44,$3f,$3a,$34,$2e
	.byte	$25,$1b,$2a,$2b,$2c,$2d,$2d,$2e
	.byte	$2e,$2e,$2e,$2d,$2c,$2b,$2a,$28
	.byte	$27,$25,$23,$20,$1e,$1c,$1a,$18
	.byte	$17,$15,$14,$14,$14,$14,$15,$16
	.byte	$17,$1a,$1c,$1f,$23,$26,$2a,$2e
	.byte	$32,$36,$3a,$3e,$42,$45,$48,$4a
	.byte	$4c,$4d,$4e,$4e,$4d,$4c,$4a,$48
	.byte	$45,$41,$3d,$39,$34,$2f,$2a,$25
	.byte	$20,$1b,$17,$12,$0e,$0b,$08,$06
	.byte	$05,$04,$04,$04,$05,$07,$0a,$0d
	.byte	$10,$14,$18,$1c,$21,$25,$2a,$2e
	.byte	$33,$37,$3a,$3d,$40,$42,$44,$45
	.byte	$46,$46,$46,$45,$43,$42,$3f,$3d
	.byte	$3a,$38,$35,$32,$2f,$2d,$2a,$28
	.byte	$26,$24,$23,$21,$21,$20,$20,$20
	.byte	$21,$22,$22,$23,$24,$26,$27,$28
	.byte	$29,$29,$2a,$2a,$2a,$2a,$2a,$29
	.byte	$29,$27,$26,$25,$23,$22,$20,$1f
	.byte	$1d,$1c,$1b,$1a,$1a,$1a,$1a,$1b
	.byte	$1c,$1d,$1f,$21,$24,$27,$2a,$2d
	.byte	$31,$34,$38,$3b,$3e,$41,$44,$46
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LIST_M7B:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$00,$02,$04,$06,$08,$0a,$0c,$0e
	.byte	$10,$12,$14,$16,$17,$19,$1a,$1c
	.byte	$1d,$1e,$1f,$20,$20,$21,$22,$22
	.byte	$22,$22,$22,$22,$22,$21,$21,$20
	.byte	$1f,$1e,$1e,$1d,$1b,$1a,$19,$18
	.byte	$17,$15,$14,$13,$11,$10,$0e,$0d
	.byte	$0c,$0a,$09,$08,$07,$06,$05,$04
	.byte	$03,$02,$01,$01,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$01,$01,$02
	.byte	$03,$04,$05,$06,$07,$08,$09,$0a
	.byte	$0c,$0d,$0e,$10,$11,$13,$14,$15
	.byte	$17,$18,$19,$1a,$1b,$1d,$1e,$1e
	.byte	$1f,$20,$21,$21,$22,$22,$22,$22
	.byte	$22,$22,$22,$21,$20,$20,$1f,$1e
	.byte	$1d,$1c,$1a,$19,$17,$16,$14,$12
	.byte	$10,$0e,$0c,$0a,$08,$06,$04,$02
	.byte	$00,$fd,$fb,$f9,$f7,$f5,$f3,$f1
	.byte	$ef,$ed,$eb,$e9,$e8,$e6,$e5,$e3
	.byte	$e2,$e1,$e0,$df,$df,$de,$dd,$dd
	.byte	$dd,$dd,$dd,$dd,$dd,$de,$de,$df
	.byte	$e0,$e1,$e1,$e2,$e3,$e5,$e6,$e7
	.byte	$e8,$ea,$eb,$ec,$ee,$ef,$f1,$f2
	.byte	$f3,$f5,$f6,$f7,$f8,$f9,$fa,$fb
	.byte	$fc,$fd,$fe,$fe,$ff,$ff,$ff,$ff
	.byte	$00,$ff,$ff,$ff,$ff,$fe,$fe,$fd
	.byte	$fc,$fb,$fa,$f9,$f8,$f7,$f6,$f5
	.byte	$f3,$f2,$f1,$ef,$ee,$ec,$eb,$ea
	.byte	$e8,$e7,$e6,$e5,$e4,$e2,$e1,$e1
	.byte	$e0,$df,$de,$de,$dd,$dd,$dd,$dd
	.byte	$dd,$dd,$dd,$de,$df,$df,$e0,$e1
	.byte	$e2,$e3,$e5,$e6,$e8,$e9,$eb,$ed
	.byte	$ef,$f1,$f3,$f5,$f7,$f9,$fb,$fd
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LOGO_BG1VOFS:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$23,$24,$24,$25,$25,$26,$26,$27
	.byte	$27,$28,$29,$29,$2a,$2a,$2b,$2b
	.byte	$2c,$2c,$2d,$2d,$2e,$2e,$2f,$2f
	.byte	$30,$30,$31,$31,$32,$32,$32,$33
	.byte	$33,$34,$34,$34,$35,$35,$35,$36
	.byte	$36,$36,$37,$37,$37,$38,$38,$38
	.byte	$38,$38,$39,$39,$39,$39,$39,$39
	.byte	$3a,$3a,$3a,$3a,$3a,$3a,$3a,$3a
	.byte	$3a,$3a,$3a,$3a,$3a,$3a,$3a,$3a
	.byte	$3a,$39,$39,$39,$39,$39,$39,$38
	.byte	$38,$38,$38,$38,$37,$37,$37,$36
	.byte	$36,$36,$35,$35,$35,$34,$34,$34
	.byte	$33,$33,$32,$32,$32,$31,$31,$30
	.byte	$30,$2f,$2f,$2e,$2e,$2d,$2d,$2c
	.byte	$2c,$2b,$2b,$2a,$2a,$29,$29,$28
	.byte	$27,$27,$26,$26,$25,$25,$24,$24
	.byte	$23,$22,$22,$21,$21,$20,$20,$1f
	.byte	$1f,$1e,$1d,$1d,$1c,$1c,$1b,$1b
	.byte	$1a,$1a,$19,$19,$18,$18,$17,$17
	.byte	$16,$16,$15,$15,$14,$14,$14,$13
	.byte	$13,$12,$12,$12,$11,$11,$11,$10
	.byte	$10,$10,$0f,$0f,$0f,$0e,$0e,$0e
	.byte	$0e,$0e,$0d,$0d,$0d,$0d,$0d,$0d
	.byte	$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c
	.byte	$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c
	.byte	$0c,$0d,$0d,$0d,$0d,$0d,$0d,$0e
	.byte	$0e,$0e,$0e,$0e,$0f,$0f,$0f,$10
	.byte	$10,$10,$11,$11,$11,$12,$12,$12
	.byte	$13,$13,$14,$14,$14,$15,$15,$16
	.byte	$16,$17,$17,$18,$18,$19,$19,$1a
	.byte	$1a,$1b,$1b,$1c,$1c,$1d,$1d,$1e
	.byte	$1f,$1f,$20,$20,$21,$21,$22,$22
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LOGO_MAP_PAL:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
 .byte	$24,$24,$24,$2c,$2c,$2c,$34,$34,$34,$34,$34,$34,$2c,$2c,$2c,$24
 .byte	$24,$24,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
 .byte	$24,$24,$24,$2c,$2c,$2c,$34,$34,$34,$34,$34,$34,$2c,$2c,$2c,$24
 .byte	$24,$24,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
 .byte	$24,$24,$24,$2c,$2c,$2c,$34,$34,$34,$34,$34,$34,$2c,$2c,$2c,$24
 .byte	$24,$24,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
 .byte	$24,$24,$24,$2c,$2c,$2c,$34,$34,$34,$34,$34,$34,$2c,$2c,$2c,$24
 .byte	$24,$24,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
 .byte	$28,$28,$28,$30,$30,$30,$38,$38,$38,$38,$38,$38,$30,$30,$30,$28
 .byte	$28,$28,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
 .byte	$28,$28,$28,$30,$30,$30,$38,$38,$38,$38,$38,$38,$30,$30,$30,$28
 .byte	$28,$28,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
 .byte	$28,$28,$28,$30,$30,$30,$38,$38,$38,$38,$38,$38,$30,$30,$30,$28
 .byte	$28,$28,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
 .byte	$28,$28,$28,$30,$30,$30,$38,$38,$38,$38,$38,$38,$30,$30,$30,$28
 .byte	$28,$28,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LOGO_MAP_PAL_END:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
LOGO_PAL:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$d6,$5a,$d6,$5a,$d6,$5a,$d6,$5a
	.byte	$d6,$5a,$8e,$5a,$44,$5a,$00,$5a
	.byte	$c0,$49,$80,$41,$40,$31,$00,$29
	.byte	$00,$29,$40,$31,$80,$41,$c0,$49
	.byte	$00,$5a,$44,$5a,$8e,$5a,$d6,$5a
	.byte	$d6,$5a,$d6,$5a,$d6,$5a,$d6,$5a
	.byte	$d6,$5a,$d6,$5a,$d6,$5a,$d6,$5a
	.byte	$d6,$5a,$d0,$52,$cc,$4a,$c6,$42
	.byte	$84,$3a,$02,$32,$c2,$29,$80,$21
	.byte	$80,$21,$c2,$29,$02,$32,$84,$3a
	.byte	$c6,$42,$cc,$4a,$d0,$52,$d6,$5a
	.byte	$d6,$5a,$d6,$5a,$d6,$5a,$d6,$5a
	.byte	$ad,$1d,$12,$8d,$16,$21,$ad,$1e
	.byte	$12,$8d,$17,$21,$c2,$10,$ae,$1b
	.byte	$12,$bd,$28,$f2,$8d,$18,$21,$a9
	.byte	$00,$8d,$19,$21,$e2,$10,$60,$a9
	.byte	$a1,$8d,$21,$21,$ae,$24,$12,$bd
	.byte	$e0,$9d,$8d,$22,$21,$e8,$bd,$e0
	.byte	$9d,$8d,$22,$21,$ee,$24,$12,$ee
	.byte	$24,$12,$ad,$24,$12,$c9,$26,$d0
	.byte	$05,$a9,$00,$8d,$24,$12,$60,$ee
	.byte	$1f,$12,$ad,$1f,$12,$c9,$04,$d0
	.byte	$34,$a9,$00,$8d,$1f,$12,$c2,$10
	.byte	$ae,$1b,$12,$e8,$8e,$1b,$12,$bd
	.byte	$28,$f2,$c9,$00,$d0,$06,$a2,$00
	.byte	$00,$8e,$1b,$12,$ee,$1d,$12,$ad
	.byte	$1d,$12,$c9,$e0,$d0,$0d,$a9,$c0
	.byte	$8d,$1d,$12,$ad,$1e,$12,$49,$04
	.byte	$8d,$1e,$12,$e2,$10,$60,$e2,$30
	.byte	$a9,$b0,$8d,$02,$21,$9c,$03,$21
	.byte	$ae,$15,$12,$a0,$00,$b9,$d0,$9e
	.byte	$8d,$04,$21,$bd,$d6,$9e,$e9,$08
	.byte	$8d,$04,$21,$b9,$ca,$9e,$8d,$04
	.byte	$21,$a9,$04,$18,$6d,$23,$12,$8d
	.byte	$04,$21,$ca,$ca,$ca,$ca,$c8,$c0
	.byte	$06,$d0,$da,$ee,$15,$12,$ad,$15
	.byte	$12,$c9,$38,$d0,$05,$a9,$18,$8d
	.byte	$15,$12,$e2,$30,$60,$a9,$b1,$8d
	.byte	$21,$21,$ad,$2b,$12,$8d,$22,$21
	.byte	$ad,$2c,$12,$8d,$22,$21,$60,$ee
	.byte	$17,$12,$d0,$42,$a9,$fc,$8d,$17
	.byte	$12,$ae,$18,$12,$bd,$a8,$9e,$8d
	.byte	$2b,$12,$e8,$bd,$a8,$9e,$8d,$2c
	.byte	$12,$ee,$18,$12,$ee,$18,$12,$ad
	.byte	$18,$12,$c9,$22,$d0,$09,$a9,$00
	.byte	$8d,$18,$12,$8d,$17,$12,$60,$c9
	.byte	$12,$d0
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
RING_SINE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$00,$01,$02,$03,$04,$05,$06,$07
	.byte	$08,$08,$09,$0a,$0a,$0b,$0b,$0b
	.byte	$0c,$0c,$0c,$0c,$0b,$0b,$0a,$0a
	.byte	$09,$08,$07,$06,$05,$04,$02,$01
	.byte	$00,$fe,$fc,$fb,$f9,$f7,$f5,$f3
	.byte	$f1,$ef,$ed,$eb,$e9,$e8,$e6,$e4
	.byte	$e2,$e0,$df,$dd,$dc,$da,$d9,$d8
	.byte	$d7,$d6,$d5,$d4,$d4,$d3,$d3,$d3
	.byte	$d3,$d3,$d3,$d3,$d4,$d4,$d5,$d6
	.byte	$d7,$d8,$d9,$da,$dc,$dd,$df,$e0
	.byte	$e2,$e4,$e6,$e8,$e9,$eb,$ed,$ef
	.byte	$f1,$f3,$f5,$f7,$f9,$fa,$fc,$fe
	.byte	$ff,$01,$02,$04,$05,$06,$07,$08
	.byte	$09,$0a,$0a,$0b,$0b,$0c,$0c,$0c
	.byte	$0c,$0c,$0b,$0b,$0a,$0a,$09,$08
	.byte	$08,$07,$06,$05,$04,$03,$02,$01
	.byte	$00,$fe,$fd,$fc,$fb,$fa,$f9,$f8
	.byte	$f7,$f7,$f6,$f5,$f5,$f4,$f4,$f4
	.byte	$f3,$f3,$f3,$f3,$f4,$f4,$f5,$f5
	.byte	$f6,$f7,$f8,$f9,$fa,$fb,$fd,$fe
	.byte	$ff,$01,$03,$04,$06,$08,$0a,$0c
	.byte	$0e,$10,$12,$14,$16,$17,$19,$1b
	.byte	$1d,$1f,$20,$22,$23,$25,$26,$27
	.byte	$28,$29,$2a,$2b,$2b,$2c,$2c,$2c
	.byte	$2d,$2c,$2c,$2c,$2b,$2b,$2a,$29
	.byte	$28,$27,$26,$25,$23,$22,$20,$1f
	.byte	$1d,$1b,$19,$17,$16,$14,$12,$10
	.byte	$0e,$0c,$0a,$08,$06,$05,$03,$01
	.byte	$00,$fe,$fd,$fb,$fa,$f9,$f8,$f7
	.byte	$f6,$f5,$f5,$f4,$f4,$f3,$f3,$f3
	.byte	$f3,$f3,$f4,$f4,$f5,$f5,$f6,$f7
	.byte	$f7,$f8,$f9,$fa,$fb,$fc,$fd,$fe
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SCROLLTEXT:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	"         A FORCE OF LIBERATION S"
	.byte	"TRIKES THE 7 GATES OF HELL      "
	.byte	"                 A MESSAGE OF JO"
	.byte	"Y IS TOLD IN EACH AND EVERY CELL"
	.byte	"                       A BLESSIN"
	.byte	"G TO THE SOULS WITH THE STRONGES"
	.byte	"T ADDICTION                     "
	.byte	"  THEY WHO CANNOT HAVE ENOUGH OF"
	.byte	" ADVENTURE, SPORTS AND FICTION  "
	.byte	"                     CRYING CONS"
	.byte	"OLE GAMERS ARE SCREAMING PLEASE!"
	.byte	"!                       AND THE "
	.byte	"LIBERATION..?  IS YET ANOTHER CE"
	.byte	"NSOR RELEASE.........           "
	.byte	"            ETERNAL SALVATION TO"
	.byte	" THE SOULS IN STRAIT-JACKETS:   "
	.byte	"   ANTHROX - PREMIERE - ROMKIDS "
	.byte	"- SCOOPEX - ELITENDO - RIP & AND"
	.byte	"VERON - FAIRLIGHT - QUARTEX - DY"
	.byte	"NAMIX.......... TO MAKE SURE YOU"
	.byte	" ALWAYS PICK UP THE LATEST RELEA"
	.byte	"SES FAST... EITHER CALL...   ..."
	.byte	"WET DREAMS...   OR   ...STREETS "
	.byte	"OF FIRE...  OR JUST CONTACT US B"
	.byte	"Y MAIL...                      C"
	.byte	"ENSOR SAYS: UNTIL NEXT!         "
	.byte	"                                "
	.byte	"        ",0
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SCROLLTEXT_PAL:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.word	$0000,$4210,$4a52,$5294
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SCROLLTEXT_VOFS:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$14,$15,$16,$17,$18,$19,$1a,$1b
	.byte	$1c,$1d,$1d,$1e,$1f,$20,$21,$21
	.byte	$22,$23,$23,$24,$25,$25,$26,$26
	.byte	$26,$27,$27,$27,$28,$28,$28,$28
	.byte	$28,$28,$28,$28,$28,$27,$27,$27
	.byte	$26,$26,$26,$25,$25,$24,$23,$23
	.byte	$22,$21,$21,$20,$1f,$1e,$1d,$1d
	.byte	$1c,$1b,$1a,$19,$18,$17,$16,$15
	.byte	$14,$13,$12,$11,$10,$0f,$0e,$0d
	.byte	$0c,$0b,$0b,$0a,$09,$08,$07,$07
	.byte	$06,$05,$05,$04,$03,$03,$02,$02
	.byte	$02,$01,$01,$01,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$01,$01,$01
	.byte	$02,$02,$02,$03,$03,$04,$05,$05
	.byte	$06,$07,$07,$08,$09,$0a,$0b,$0b
	.byte	$0c,$0d,$0e,$0f,$10,$11,$12,$13
	.byte	$14,$15,$16,$17,$18,$19,$1a,$1b
	.byte	$1c,$1d,$1d,$1e,$1f,$20,$21,$21
	.byte	$22,$23,$23,$24,$25,$25,$26,$26
	.byte	$26,$27,$27,$27,$28,$28,$28,$28
	.byte	$28,$28,$28,$28,$28,$27,$27,$27
	.byte	$26,$26,$26,$25,$25,$24,$23,$23
	.byte	$22,$21,$21,$20,$1f,$1e,$1d,$1d
	.byte	$1c,$1b,$1a,$19,$18,$17,$16,$15
	.byte	$14,$13,$12,$11,$10,$0f,$0e,$0d
	.byte	$0c,$0b,$0b,$0a,$09,$08,$07,$07
	.byte	$06,$05,$05,$04,$03,$03,$02,$02
	.byte	$02,$01,$01,$01,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$01,$01,$01
	.byte	$02,$02,$02,$03,$03,$04,$05,$05
	.byte	$06,$07,$07,$08,$09,$0a,$0b,$0b
	.byte	$0c,$0d,$0e,$0f,$10,$11,$12,$13
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SMALL_RING_SPRITE_TILE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$79,$7a,$7b,$7c,$00
	.byte	$7d,$7e,$7f,$80,$81
	.byte	$82,$83,$84,$85,$86
	.byte	$87,$88,$89,$8a,$00
	.byte	$00,$8b,$8c,$00
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SMALL_RING_SPRITE_XPOS:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$00,$08,$10,$18,$20
	.byte	$00,$08,$10,$18,$20
	.byte	$00,$08,$10,$18,$20
	.byte	$00,$08,$10,$18,$20
	.byte	$00,$08,$10,$18
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SMALL_RING_SPRITE_YPOS:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$00,$00,$00,$00,$00
	.byte	$08,$08,$08,$08,$08
	.byte	$10,$10,$10,$10,$10
	.byte	$18,$18,$18,$18,$18
	.byte	$20,$20,$20,$20
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
STAR_PAL:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.word	$5294,$6b5a,$39ce,$1096
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


