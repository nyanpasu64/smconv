;--------------------------------------------------------------------------
.include "snes.inc"
.include "snes_decompress.inc"
.include "snes_joypad.inc"
.include "graphics.inc"
;--------------------------------------------------------------------------
.import clear_vram, init_reg
.export DoIntro
;--------------------------------------------------------------------------

MAX_OPT	=	6
CPR_PAL	=	PALETTE3
OPT_PAL =	PALETTE2
TXT_PAL	=	PALETTE1

RAM_CGDATA =	01a00h
OPTION_STOR =	01c00h
BOUNCE_STOR =	01e00h

BG1GFX	=	06000h
BG1MAP	=	03c00h
BG2GFX	=	0e000h
BG2MAP	=	07c00h
BG2MAP2	=	0a000h	; BGMODE 2 BG2MAP
BG3MAP	=	0e800h
LOGOGFX	=	00000h
LOGOMAP =	0d800h
BENDMAP	=	04020h
SCRMAP  =	042e0h
SINELOC	=	08200h
SPRGFX	=	0c000h

YN_POS	=	03c18h
;--------------------------------------------------------------------------
	.bss
;--------------------------------------------------------------------------

addr_stor:	.res 2
anim_ofs:	.res 2
ball_dir:	.res 1
ball_rand:	.res 2
ball_timer:	.res 2
ball_x:		.res 2
ball_y:		.res 2
bend_flag:	.res 1
char_timer:	.res 2
chr_c_ofs:	.res 2
cnv_out1:	.res 2
cnv_out2:	.res 2
cnv_stor1:	.res 2
cnv_stor2:	.res 2
cnv_stor3:	.res 2
cnv_stor4:	.res 2
col_ofs:	.res 2
joy_count:	.res 2
joypad:		.res 2
line1_ofs:	.res 2
line2_ofs:	.res 2
line3_ofs:	.res 2
line4_ofs:	.res 2
line5_ofs:	.res 2
line6_ofs:	.res 2
line7_ofs:	.res 2
line8_ofs:	.res 2
num_conv:	.res 2
opt_count:	.res 2
opt_flag:	.res 2
opt_timer:	.res 2
opt_vpos:	.res 2
options:	.res 2
ring_ofs:	.res 2
scr_dir:	.res 1
scr_ofs:	.res 2
scr_spos:	.res 2
scr_y_fix:	.res 2
sine_ofs:	.res 2
wave_stor:	.res 2
xreg_stor:	.res 2

;--------------------------------------------------------------------------
	.code
;--------------------------------------------------------------------------

;==========================================================================
;      Code (c) 1993-94 -Pan-/ANTHROX   All code can be used at will!
;==========================================================================                     
DoIntro:
	sei

	rep	#10h		; X,Y fixed -> 16 bit mode
	sep	#20h		; Accumulator ->  8 bit mode

        DoDecompressDataVram gfx_logoTiles, LOGOGFX
        DoDecompressDataVram gfx_charTiles, BG1GFX
        DoDecompressDataVram gfx_ballTiles, SPRGFX
	DoDecompressDataVram gfx_logoMap, LOGOMAP

	DoCopyPalette gfx_greenPal,  0, 10	; 0<<2 : palette number
	DoCopyPalette gfx_charPal,  16, 10	; 1<<2 . for REG_VMDATAH 
	DoCopyPalette gfx_goldPal,  32, 10	; 2<<2
	DoCopyPalette gfx_bluePal,  48, 10	; 3<<2
	DoCopyPalette gfx_logoPal,  64, 26	; 4<<2 : grit file should contain -ga64
	DoCopyPalette gfx_ballPal, 128, 11

;==========================================================================
;                      Make Tiles
;==========================================================================

	lda	#80h
	sta	REG_VMAIN

	ldx	#BG1MAP
	stx	REG_VMADDL
	ldx	#0000h
	txy
copyoptiontext:
	lda	OPT_TEXT,x
	sec
	sbc	#20h
	sta	REG_VMDATAL
	lda	#TXT_PAL
	sta	REG_VMDATAH
	inx
	cpx	#0400h
	bne	copyoptiontext

	ldx	#BENDMAP
	stx	REG_VMADDL
	tyx
setbounce:
	lda	#0ffh
	sta	REG_VMDATAL
	lda	#20h
	sta	REG_VMDATAH
	inx
	cpx	#0020h
	bne	setbounce

	ldx	#BG2MAP2/2+320h
	stx	REG_VMADDL
	tyx
CopyMyRight:
	lda	COPYRIGHT,x
	eor	#54h
	sec
	sbc	#20h
	sta	REG_VMDATAL
	lda	#CPR_PAL
	sta	REG_VMDATAH
	inx
	cpx	#0020h
	bne	CopyMyRight

	ldx	#BG2MAP
	stx	REG_VMADDL
	tyx
copymiddlebkack:
	stz	REG_VMDATAL
	lda	#PALETTE6
	sta	REG_VMDATAH
	inx
	cpx	#0400h
	bne	copymiddlebkack

;==========================================================================
;                              Sprite Setup Routine
;==========================================================================

Sprite_Setup:
	lda	#OBSEL_8_16|OBSEL_BASE(SPRGFX)|OBSEL_NN_16K
	sta	REG_OBSEL
	stz	REG_OAMADDL
	stz	REG_OAMADDH
	tyx
sprtclear:
	stz	REG_OAMDATA	; Horizontal position
	lda	#0e0h
	sta	REG_OAMDATA	; Vertical position
	stz	REG_OAMDATA	; sprite object = 0
	lda	#%00110000
	sta	REG_OAMDATA	; palette = 0, priority = %11, h;v flip = 0
	inx
	cpx	#0080h		; (128 sprites)
	bne	sprtclear

sprtdataclear:
	stz	REG_OAMDATA	; clear H-position 
	stz	REG_OAMDATA	; and make size large
	iny
	cpy	#0020h		; 32 extra bytes for sprite data
				; info
	bne	sprtdataclear

	ldx	#0100h
	stx	REG_OAMADDL
	lda	#%00000010
	sta	REG_OAMDATA

	stz	REG_OAMADDL
	stz	REG_OAMADDH
	stz	REG_OAMDATA
	lda	#0c0h
	sta	REG_OAMDATA
	lda	#02h
	sta	REG_OAMDATA
	lda	#%00110000
	sta	REG_OAMDATA

	jsr	OptionSetup
	jsr	HDMA

	ldx	#00ffh
	stx	scr_y_fix	; fix for left most scroll y pos

	ldx	#0084h
	stx	opt_vpos	; Options vertical scroll position

	ldx	#0007h
	stx	ball_rand	;  timer for ball randomization

	ldx	#0001h
	stx	ball_timer	; timer for selection bar fade
	stx	char_timer	; timer for char anim

	;ldx	#0000h
	dex
	stx	scr_ofs		; scroll text offset
	stx	scr_spos	; scroll screen position
	stx	opt_flag	; Option flag (is the option currently moving?)
	stz	scr_dir		; scroll direction: 0 = down; 1 = up
	stx	opt_timer	; second opt scroll timer
	lda	#1
	sta	ball_dir	; X ball direction 0 = left; 1 = right
	stx	ball_y		; ball Y sine offset
	stx	ball_x		; X ball position
	stx	ring_ofs	; offset for ring

	stx	xreg_stor	; storage for X register counter
	
	stz	bend_flag	; bend in progress flag; 1 = bending
	stx	addr_stor	; storage for address
	stx	opt_count	; current option counter 

	lda	Number
	dec a	
	sta	options		; high # of options
	stz	options+1

	stx	cnv_stor1	; storage for conversion of hex-> decimal
	stx	cnv_stor2	;
	stx	cnv_stor3	; same as the above
	stx	cnv_stor4	; same as above
	stx	num_conv	; put number here to be converted
	stx	cnv_out1	; output of conversion
	stx	cnv_out2	; output of conversion
	stx	joy_count	; counter timer for Joypad presses
	stx	col_ofs		; offset for color
	stx	anim_ofs	; offset for char anim
	stx	chr_c_ofs	; offset for char color
	stx	sine_ofs	; offset for background sine
	stx	wave_stor	; storage for calculation of HDMAwave offset

	stx	line1_ofs	; first line offset

	ldx	#0004h
	stx	line2_ofs
	ldx	#0008h
	stx	line3_ofs
	ldx	#000ch
	stx	line4_ofs

	inx
	inx
	inx
	inx
	stx	line5_ofs
	
	inx
	inx
	inx
	inx
	stx	line6_ofs
	
	inx
	inx
	inx
	inx
	stx	line7_ofs
	
	inx
	inx
	inx
	inx
	stx	line8_ofs

;===========================================================================
;                         Start of Core Program
;===========================================================================

Waitloop:
	lda	#NMI_JOYPAD
	sta	REG_NMITIMEN
	jsr	WaitVb		; wait for vertical blank
	lda	joy1_down+1
	cmp	#10h
	bne	nevermind

	stz	REG_HDMAEN
	jsr	init_reg
	jsr	clear_vram
	jmp	DoIntro

nevermind:

	jsr	OptionSelect

	lda	#BGMODE_3
	sta	REG_BGMODE

	lda	#04h
	sta	REG_BG1HOFS
	stz	REG_BG1HOFS	

	lda	#TM_OBJ|TM_BG1	; both planes enabled for
	sta	REG_TM		; sprite visibility

	lda	#(LOGOMAP>>9)
	sta	REG_BG1SC

	stz	REG_BG12NBA	; gfx at 0000h
	stz	REG_BG1VOFS
	stz	REG_BG1VOFS


	;===================================================
	;  ^^^ Logo stuff ^^^                              ;
	;===================================================

	jsr	Scroll
	jsr	BallBounce
	jsr	OptionMove
	jsr	Bend
	jsr	CharAnim
	jsr	Background
	jsr	Joypad
	jsr	SelectColor

	lda	#0fh
	sta	REG_INIDISP

	lda     #NMI_IRQY|NMI_JOYPAD
        sta     REG_NMITIMEN

        lda     #57h
        sta     REG_VTIMEL	; wait for bottom of logo 
        stz     REG_VTIMEH

Waitvert:
        lda     REG_TIMEUP

Waitvert2:
        lda     REG_TIMEUP
        and     #80h
        beq     Waitvert2

	stz	REG_TM
	
	stz	REG_BG1HOFS
	stz	REG_BG1HOFS

	lda	opt_vpos
	sta	REG_BG1VOFS
	stz	REG_BG1VOFS

	lda	#BGMODE_2
	sta	REG_BGMODE

	lda	#BG1MAP>>8
	sta	REG_BG1SC

	lda	#BG2GFX>>9+BG1GFX>>13
	sta	REG_BG12NBA		; gfx at 3000h
	
	lda	#BG2MAP>>8
	sta	REG_BG2SC

	lda	#BG3MAP>>9
	sta	REG_BG3SC

Waithoriz:
	lda	REG_HVBJOY
	asl a
	bpl	Waithoriz

	ldx	sine_ofs
	lda	BACK_SINE,x
	sta	REG_BG2VOFS
	stz	REG_BG2VOFS

	lda	#TM_OBJ|TM_BG2|TM_BG1
	sta	REG_TM
	;===================================================
	;^^^^^  middle option text screen stuff
	;===================================================

	jsr	HDMAWave

	lda     #NMI_IRQY|NMI_JOYPAD
        sta     REG_NMITIMEN

        lda     #0a7h
        sta     REG_VTIMEL	; wait for bottom of options 
        stz     REG_VTIMEH

        lda     REG_TIMEUP

Waitvert3:
        lda     REG_TIMEUP
        and     #80h
        beq     Waitvert3

Waithoriz2:
	lda	REG_HVBJOY
	asl a
	bpl	Waithoriz2

	stz	REG_BG2VOFS
	stz	REG_BG2VOFS
	lda	#TM_OBJ
	sta	REG_TM

	lda	scr_y_fix
	sta	REG_BG1VOFS
	stz	REG_BG1VOFS

	lda	scr_spos
	sta	REG_BG1HOFS
	stz	REG_BG1HOFS

	lda	#BGMODE_2
	sta	REG_BGMODE

	lda	#SINELOC>>9
	sta	REG_BG1SC
	sta	REG_BG3SC	; the data for sine bounce vram location

	lda	#BG2MAP2>>9	; mode 2 background 2 map
	sta	REG_BG2SC

	lda	#BG1GFX>>9+BG1GFX>>13
	sta	REG_BG12NBA

Waithoriz3:
	lda	REG_HVBJOY
	asl a
	bpl	Waithoriz3

	lda	#TM_OBJ|TM_BG2|TM_BG1
	sta	REG_TM
	
	;=======================================================
	;^^^^^^^^^   scroll stuff!                             
	;=======================================================
	jsr	Joypad

	jmp	Waitloop	; constant loop


;==========================================================================
;                         Option Selection
;==========================================================================
OptionSelect:

	lda	joy_count
	eor	#01h
	sta	joy_count
	beq	OkOptSel
	rts

OkOptSel:

optmoveok:
	lda	opt_timer
	beq	OkOptSel2
	dec	opt_timer
	rts
OkOptSel2:
	lda	#01h
	sta	opt_timer
	lda	joy1_down+1
	cmp	#JOYPADH_B
	beq	OptB
	cmp	#JOYPADH_LEFT
	beq	OptB
	cmp	#JOYPADH_RIGHT
	beq	OptA
	lda	joy1_down
	cmp	#JOYPAD_A
	beq	OptA
	rts

OptB:	bra	Decopt

Incopt:
OptA:
	ldx	opt_count	; get current option line
	lda	Type,x
	beq	Textopt
	bra	Numberopt

Textopt:
	lda	#01h
	sta	OPTION_STOR,x
	jmp	displayyn	

Numberopt:
	lda	OPTION_STOR,x
	cmp	Max,x
	bne	Incnumber
	rts

Incnumber:
	inc	OPTION_STOR,x
	lda	OPTION_STOR,x
PrintDec:
	sta	num_conv
	jsr	Hex2Dec

	rep	#30h

	lda	opt_count
	asl a
	asl a
	asl a
	asl a
	asl a
	clc
	adc	#YN_POS
	sta	REG_VMADDL

	sep	#20h

	lda	cnv_out1
	clc
	adc	#10h
	sta	REG_VMDATAL
	lda	#OPT_PAL
	sta	REG_VMDATAH
	lda	cnv_out1+1
	clc
	adc	#10h
	sta	REG_VMDATAL
	lda	#OPT_PAL
	sta	REG_VMDATAH
	lda	cnv_out2
	clc
	adc	#10h
	sta	REG_VMDATAL
	lda	#OPT_PAL
	sta	REG_VMDATAH
	rts

Decopt:
	ldx	opt_count	; get current option line
	lda	Type,x
	beq	Textopt1
	bra	Numberopt1

Textopt1:
	stz	OPTION_STOR,x
	bra	displayyn	

Numberopt1:
	lda	OPTION_STOR,x
	cmp	Min,x
	bne	Decnumber
	rts

Decnumber:
	dec	OPTION_STOR,x
	lda	OPTION_STOR,x
	sta	num_conv
	jsr	Hex2Dec

	rep	#30h

	lda	opt_count
	asl a
	asl a
	asl a
	asl a
	asl a
	clc
	adc	#YN_POS
	sta	REG_VMADDL

	sep	#20h

	lda	cnv_out1
	clc
	adc	#10h
	sta	REG_VMDATAL
	lda	#OPT_PAL
	sta	REG_VMDATAH
	lda	cnv_out1+1
	clc
	adc	#10h
	sta	REG_VMDATAL
	lda	#OPT_PAL
	sta	REG_VMDATAH
	lda	cnv_out2
	clc
	adc	#10h
	sta	REG_VMDATAL
	lda	#OPT_PAL
	sta	REG_VMDATAH
	rts

displayyn:
	rep	#30h
	lda	opt_count
	asl a
	asl a
	asl a
	asl a
	asl a
	clc
	adc	#YN_POS
	sta	REG_VMADDL
	sep	#20h
	lda	OPTION_STOR,x
	beq	TxtNo
	ldx	#0000h
copyyes:
	lda	YES,x
	sec
	sbc	#20h
	sta	REG_VMDATAL
	lda	#OPT_PAL
	sta	REG_VMDATAH
	inx
	cpx	#YES_END-YES
	bne	copyyes
	rts
TxtNo:
	ldx	#0000h
copyno:
	lda	NO,x
	sec
	sbc	#20h
	sta	REG_VMDATAL
	lda	#OPT_PAL
	sta	REG_VMDATAH
	inx
	cpx	#NO_END-NO
	bne	copyno
	rts


;=========================================================================
;                           Selection Background mover
;=========================================================================

Background:
	ldx	#BG3MAP/2+20h
	stx	REG_VMADDL

	rep	#30h

	lda	sine_ofs
	tax
	inx

	sep	#20h

	ldy	#0000h
copybacksine:
	lda	BACK_SINE,x
	sta	REG_VMDATAL
	lda	#0c0h
	sta	REG_VMDATAH
	inx
	iny
	cpy	#20h
	bne	copybacksine
	lda	sine_ofs
	inc a
	and	#3fh
	sta	sine_ofs
	rts


;==========================================================================
;                            ball bouncer
;==========================================================================

BallBounce:
	stz	REG_OAMADDL
	stz	REG_OAMADDH

	ldx	ball_y
	lda	ball_x
	sta	REG_OAMDATA
	lda	BALL_SINE,x
	inc a
	inc a
	sta	REG_OAMDATA
	inc	ball_y
	inc	ball_y

	dec	ball_rand
	lda	ball_rand
	bne	norandom
	
	ldx	scr_ofs
	lda	SCROLLTEXT,x
	and	#1fh
	clc
	adc	#51h
	sta	ball_rand
	inc	ball_y
	inc	ball_y

norandom:
	lda	ball_dir
	beq	ballleft
	inc	ball_x
	lda	ball_x
	cmp	#0e8h
	beq	changedir
	rts	

changedir:
	lda	ball_dir
	eor	#01h
	sta	ball_dir
	rts

ballleft:
	dec	ball_x
	lda	ball_x
	cmp	#08h
	beq	changedir
	rts

;=========================================================================
;                              HDMA Color Wave
;=========================================================================

HDMAWave:
	ldx	#0000h
	txy
clearDMAcolor:
	stz	RAM_CGDATA+28,x
	stz	RAM_CGDATA+29,x
	inx
	inx
	inx
	iny
	cpy	#2fh
	bne	clearDMAcolor

	ldx	line1_ofs
	ldy	#14a5h
	jsr	drawline

	lda	line1_ofs
	inc a
	and	#7fh
	sta	line1_ofs

	ldx	line2_ofs
	ldy	#2529h
	jsr	drawline

	lda	line2_ofs
	inc a
	and	#7fh
	sta	line2_ofs

	ldx	line3_ofs
	ldy	#35adh
	jsr	drawline

	lda	line3_ofs
	inc a
	and	#7fh
	sta	line3_ofs

	ldx	line4_ofs
	ldy	#4631h
	jsr	drawline

	lda	line4_ofs
	inc a
	and	#7fh
	sta	line4_ofs

	ldx	line5_ofs
	ldy	#5294h
	jsr	drawline

	lda	line5_ofs
	inc a
	and	#7fh
	sta	line5_ofs

	ldx	line6_ofs
	ldy	#6318h
	jsr	drawline

	lda	line6_ofs
	inc a
	and	#7fh
	sta	line6_ofs

	ldx	line7_ofs
	ldy	#739ch
	jsr	drawline

	lda	line7_ofs
	inc a
	and	#7fh
	sta	line7_ofs

	ldx	line8_ofs
	ldy	#7fffh
	jsr	drawline

	lda	line8_ofs
	inc a
	and	#7fh
	sta	line8_ofs

	rts

drawline:
	rep	#30h

	lda	HDMA_SINE,x
	and	#00ffh
	sta	wave_stor	; storage
	asl a
	clc
	adc	wave_stor
	tax
	tya
	sta	RAM_CGDATA+28,x

	sep	#20h
	rts


;=========================================================================
;                        Character Animation
;=========================================================================

CharAnim:
	dec	char_timer
	lda	char_timer
	beq	Charanimation
	rts
Charanimation:
	lda	#07h
	sta	char_timer

	rep	#30h

	lda	anim_ofs
	tax
	ldy	#0008h
	lda	#BG2GFX/2
	sta	REG_VMADDL

	lda	ANIM_OFFSET,x
	and	#00ffh
	asl a
	asl a
	asl a
	tax

	sep	#20h

copyCharanimGRAPHICS:
	lda	ANIM_GRAPHICS,x
	sta	REG_VMDATAL
	stz	REG_VMDATAH
	inx
	dey
	bne	copyCharanimGRAPHICS
	ldx	anim_ofs
	inx
	stx	anim_ofs
CheckAnimoff:
	ldx	anim_ofs
	lda	ANIM_OFFSET,x
	cmp	#0feh
	beq	Changeanimcol
	cmp	#0ffh
	beq	Fixcharoops
	rts
Fixcharoops:
	rep	#30h

	stz	anim_ofs

	sep	#20h
	rts

Changeanimcol:
	rep	#30h

	inc	anim_ofs
	sep	#20h
	lda	chr_c_ofs
	inc a
	and	#07h
	sta	chr_c_ofs

	rep	#30h

	lda	chr_c_ofs
	asl a
	tax
	lda	ANIM_COLORS,x
	sta	RAM_CGDATA+1

	sep	#20h

	bra	CheckAnimoff


;==========================================================================
;                       Scroll Bend
;==========================================================================

Bend:	lda	bend_flag
	beq	okbendtest
	bra	bendring

okbendtest:

	lda	ball_y
	cmp	#7ah
	beq	Hitscroll
	cmp	#7bh
	beq	Hitscroll
	cmp	#7ch
	beq	Hitscroll
	rts

Hitscroll:
	rep	#30h

	lda	ball_x
	and	#00ffh
	lsr a
	lsr a
	lsr a
	clc
	adc	#BENDMAP-05h
	sta	addr_stor

	sep	#20h

	inc	bend_flag
	rts

bendring:
	ldx	addr_stor
	stx	REG_VMADDL
	ldx	#0000h
copybounce:
	lda	BOUNCE_STOR,x
	eor	#0ffh
	sta	REG_VMDATAL
	lda	#20h
	sta	REG_VMDATAH
	inx
	cpx	#09h
	bne	copybounce
	
	ldx	#BENDMAP-05h
	stx	REG_VMADDL

	stz	REG_VMDATAL
	stz	REG_VMDATAH
	stz	REG_VMDATAL
	stz	REG_VMDATAH
	stz	REG_VMDATAL
	stz	REG_VMDATAH
	stz	REG_VMDATAL
	stz	REG_VMDATAH
	stz	REG_VMDATAL
	stz	REG_VMDATAH

	ldx	ring_ofs	; current offset for ring

	lda	RING,x
	sta	xreg_stor
	
	ldx	xreg_stor
	ldy	#0000h

	lda	BOUNCE1,x
	
	sta	BOUNCE_STOR
	lda	BOUNCE2,x
	
	sta	BOUNCE_STOR+1
	lda	BOUNCE3,x
	
	sta	BOUNCE_STOR+2
	lda	BOUNCE4,x
	
	sta	BOUNCE_STOR+3
	lda	BOUNCE5,x
	
	sta	BOUNCE_STOR+4
	lda	BOUNCE6,x
	
	sta	BOUNCE_STOR+5
	lda	BOUNCE7,x
	
	sta	BOUNCE_STOR+6
	lda	BOUNCE8,x
	
	sta	BOUNCE_STOR+7
	lda	BOUNCE9,x
	
	sta	BOUNCE_STOR+8

	ldx	addr_stor
	cpx	#BENDMAP
	bcs	noborder
	
	ldx	ring_ofs	; current offset for ring

	lda	RING,x
	sta	xreg_stor
	
	ldx	xreg_stor
	lda	BOUNCE4,x
	eor	#0ffh
	sta	scr_y_fix



noborder:

	inc	ring_ofs
	lda	ring_ofs
	cmp	#38h
	beq	resetring
	rts
resetring:
	stz	ring_ofs
	stz	bend_flag
	rts


;==========================================================================
;                    Options Mover
;==========================================================================

OptionMove:
	lda	opt_flag
	beq	optmoveok2		;0 = ok to select, >= in movement
	dec	opt_flag
	lda	scr_dir
	beq	movesdown
	inc	opt_vpos
	rts
movesdown:
	dec	opt_vpos
	rts


optmoveok2:

	lda	joy1_down+1		; read joypad data
	cmp	#04h
	beq	optup
	cmp	#08h
	beq	optdown
	rts

optup:
	lda	opt_count	; read current option
	cmp	options		; compare with # of options
	beq	sorrynogo

	lda	#01h
	sta	scr_dir		; direction is up
	lda	#08h
	sta	opt_flag	; set the # of lines to scroll through
	inc	opt_count	; increase # of current option
sorrynogo:
	rts
optdown:

	lda	opt_count
	beq	sorrynogo

	stz	scr_dir
	lda	#08h
	sta	opt_flag
	lda	#02h
	sta	opt_timer
	dec	opt_count
	rts
	

;==========================================================================
;                  Joypad Routine
;==========================================================================
Joypad:
	lda	REG_HVBJOY
	and     #01h
	bne     Joypad
	
	ldx	REG_JOY1L
	stx	joy1_down
	rts

;==========================================================================
;             Scroll Routine
;==========================================================================

Scroll:
	lda	scr_spos
	inc a
	and	#07h
	sta	scr_spos
	beq	scrollit
	rts
scrollit:
	ldx	#SCRMAP
	stx	REG_VMADDL

	ldx	scr_ofs
	ldy	#0000h
copyscroll:
	lda	SCROLLTEXT,x
	beq	wrapscroll
	sec
	sbc	#20h
	sta	REG_VMDATAL
	;lda	#08h
	stz	REG_VMDATAH
	inx
	iny
	cpy	#0020h
	bne	copyscroll
	lda	SCROLLTEXT,x
	sec
	sbc	#20h
	ldx	#SCRMAP+400h
	stx	REG_VMADDL
	sta	REG_VMDATAL
	stz	REG_VMDATAH
	ldx	scr_ofs
	inx
	stx	scr_ofs
	rts
	
wrapscroll:
	ldx	#0000h
	stx	scr_ofs
	bra	copyscroll


;=========================================================================
;                            Selection Bar Glow Routine
;=========================================================================


SelectColor:
	dec	ball_timer
	beq	Selectglow
	rts
Selectglow:
	lda	#02h
	sta	ball_timer
	rep	#30h
	lda	col_ofs
	asl a
	tax
	lda	HDMACOLIST,x
	sta	RAM_CGDATA+13
	sep	#20h
	lda	col_ofs
	inc a
	and	#1fh
	sta	col_ofs
	rts


;=========================================================================
;                         Hex to Decimal Conversion
;=========================================================================

Hex2Dec:

	rep	#30h

	lda	num_conv
	and	#000fh
	asl a
	asl a
	tax

	sep	#20h

	inx
	inx
	inx
	lda	LOW,x
	sta	cnv_stor2
	dex
	lda	LOW,x
	sta	cnv_stor1+1
	dex
	lda	LOW,x
	sta	cnv_stor1

	rep	#30h

	lda	num_conv
	and	#00f0h
	lsr a
	lsr a
	lsr a
	lsr a
	asl a
	asl a
	tax

	sep	#20h

	inx
	inx
	inx
	lda	HIGH,x
	sta	cnv_stor4
	dex	
	lda	HIGH,x
	sta	cnv_stor3+1
	dex
	lda	HIGH,x
	sta	cnv_stor3

oneadd:
	lda	cnv_stor4
	clc
	adc	cnv_stor2
	cmp	#0ah
	bcs	onehigh

	stz	cnv_out1
	sta	cnv_out2
	bra	tenadd

onehigh:
	sec
	sbc	#0ah
	sta	cnv_out2
	lda	#01h
	sta	cnv_out1
tenadd:
	lda	cnv_stor3+1
	clc
	adc	cnv_stor1+1
	clc
	adc	cnv_out1
	cmp	#0ah
	bcs	tenhigh

	stz	cnv_out1
	sta	cnv_out1+1
	bra	hundadd

tenhigh:
	sec	
	sbc	#0ah
	sta	cnv_out1+1
	lda	#01h
	sta	cnv_out1
hundadd:
	lda	cnv_stor3
	clc
	adc	cnv_stor1
	clc
	adc	cnv_out1
	sta	cnv_out1
	rts

;==========================================================================
;                            Option Setup Routine
;==========================================================================

OptionSetup:

	
	ldx	#0000h
clearopts:
	stz	OPTION_STOR,x
	inx
	cpx	#0100h
	bne	clearopts

	ldx	#0000h
SetOptRam:
	lda	Type,x
	bne	Numberthing
SetRamOpt:
	inx
	cpx	Number
	bne	SetOptRam
	bra	thisthat

Numberthing:
	lda	Begin,x
	sta	OPTION_STOR,x
	bra	SetRamOpt

thisthat:
	ldx	#0000h
	stx	opt_count
printopt:
	ldx	opt_count
	lda	Type,x
	bne	numbtype
	jsr	displayyn
contOptram:
	ldx	opt_count
	inx
	stx	opt_count
	ldx	opt_count
	cpx	Number
	bne	printopt
	rts
numbtype:
	ldx	opt_count
	lda	OPTION_STOR,x
	jsr	PrintDec
	bra	contOptram



;==========================================================================
;                        Vertical Blank Wait Routine
;==========================================================================
WaitVb:	
	lda	REG_RDNMI
	bpl     WaitVb	; is the number higher than #$7f? (#$80-$ff)
			; bpl tests bit #7 ($80) if this bit is set it means
			; the byte is negative (BMI, Branch on Minus)
			; BPL (Branch on Plus) if bit #7 is set in REG_RDNMI
			; it means that it is at the start of V-Blank
			; if not it will keep testing REG_RDNMI until bit #7
			; is on (which would make it a negative (BMI)
	rts

;==========================================================================
;                     Start of HDMA routine
;==========================================================================

HDMA:
	stz	REG_DMAP0
	lda	#<REG_CGADD
	sta	REG_BBAD0
	ldx	#LIST_CGADD
	stx	REG_A1T0L
	phk
	pla
	sta	REG_A1B0

	lda     #DMAP_XFER_MODE_2
	sta     REG_DMAP1           ; 2= 2 bytes per register (not a word!)
	lda     #<REG_CGDATA
	sta     REG_BBAD1           ; 21xx   this is 2122
	ldx     #RAM_CGDATA
	stx     REG_A1T1L
	stz     REG_A1B1           ; bank address of data in ram

	ldx	#0000h
BackupHCol:
	lda	LIST_CGDATA,x
	sta	RAM_CGDATA,x
	inx
	cpx	#0200h
	bne	BackupHCol

	jsr	WaitVb

	lda	#%00000011
	sta	REG_HDMAEN		; STA!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	rts


LIST_CGADD:
	.byte	$1,$61
	.byte	$55,$00
	.byte	$01,$00
	.byte	$24,$00
	.byte	$08,$00
	.byte	$01,$00
	.byte	$23,$00
	.byte	$01,$00
	.byte	$01,$00

	.byte	$01,$00
	.byte	$01,$00
	.byte	$01,$00
	.byte	$01,$00	;1
	.byte	$01,$00
	.byte	$01,$00
	.byte	$01,$00
	.byte	$01,$00

	.byte	$01,$00
	.byte	$01,$00
	.byte	$01,$00
	.byte	$01,$00
	.byte	$01,$00	;2
	.byte	$01,$00
	.byte	$01,$00
	.byte	$01,$00

	.byte	$01,$00
	.byte	$01,$00
	.byte	$01,$00
	.byte	$01,$00
	.byte	$01,$00	;3
	.byte	$01,$00
	.byte	$01,$00
	.byte	$01,$00


	.byte	$01,$00
	.byte	$01,$00
	.byte	$01,$00
	.byte	$01,$00
	.byte	$01,$00	;4
	.byte	$01,$00
	.byte	$01,$00
	.byte	$01,$00


	.byte	$01,$00
	.byte	$01,$00
	.byte	$01,$00
	.byte	$01,$00
	.byte	$01,$00	;5
	.byte	$01,$00
	.byte	$01,$00
	.byte	$01,$00


	.byte	$01,$00
	.byte	$01,$00
	.byte	$01,$00
	.byte	$01,$00
	.byte	$01,$00	;6
	.byte	$01,$00
	.byte	$01,$00
	.byte	$01,$00


	.byte	$00,$00

;============================================================================
;                                    RESET
;============================================================================

;RESETMACHINE:

	;jsr	Snes_Init
	;rep	#$30
	;sep	#$20

	;ldx	#$0000
;copyallopts:
	;lda	OPTION_STOR,x
	;sta	>$708000,x
	;inx
	;cpx	#$0100
	;bne	copyallopts

	;sep	#$30
	;lda	#$00
	;pha
	;plb
	;.byte	$5c,$00,$f4,$00		; jump to game


;============================================================================
;                            Start of Graf-x Data
;============================================================================

BACK_SINE:
 .byte  32,35,38,41,44,47,50,52,55,57,59,60,62,63,63,64,64,64,63,63
 .byte  62,60,59,57,55,52,50,47,44,41,38,35,32,29,26,23,20,17,14,12
 .byte  9,7,5,4,2,1,1,0,0,0,1,1,2,4,5,7,9,12,14,17,20,23,26,29

 .byte  32,35,38,41,44,47,50,52,55,57,59,60,62,63,63,64,64,64,63,63
 .byte  62,60,59,57,55,52,50,47,44,41,38,35,32,29,26,23,20,17,14,12
 .byte  9,7,5,4,2,1,1,0,0,0,1,1,2,4,5,7,9,12,14,17,20,23,26,29,32

HDMA_SINE:
 .byte  0,0,0,0,0,0,1,1,1,1,1,2,2,2,3,3,4,4,5,5,6,6,7,7,8,9,9,10,11
 .byte  11,12,13,14,15,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29
 .byte  30,31,32,33,34,36,37,38,39,40,41,42,44,45,46

 .byte	46,45,44,42,41,40,39,38,37,36,34,33,32,31,30,29,28,27,26,25,24,23,22
 .byte	21,20,19,18,17,16,15,15,14,13,12,11,11,10,9,9,8,7,7,6,6,5,5,4,4,3,3
 .byte	2,2,2,1,1,1,1,1,0,0,0,0,0,0


ANIM_COLORS:
	.word	$01e0,$2312,$01DF,$4010,$7E68,$291C,$3666,$7D3D

ANIM_OFFSET:
 .byte	0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,14,14,14,14,14,14,14
 .byte	14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14
 .byte	14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14
 .byte	14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14
 .byte	14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14
 .byte	14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14
 .byte	$fe,$ff

ANIM_GRAPHICS:

;============================================================================
;= Cyber Font-Editor V1.4  Rel. by Frantic (c) 1991-1992 Sanity Productions =
;============================================================================
	; diamond
	.byte	$00,$00,$00,$00,$08,$00,$00,$00	;' '
	.byte	$00,$00,$00,$18,$18,$00,$00,$00	;'!'
	.byte	$00,$00,$18,$3c,$3c,$18,$00,$00	;'"'
	.byte	$00,$18,$3c,$7e,$7e,$3c,$18,$00	;'#'
	.byte	$18,$3c,$7e,$ff,$ff,$7e,$3c,$18	;'$'
	.byte	$3c,$7e,$ff,$ff,$ff,$ff,$7e,$3c	;'%'
	.byte	$7e,$ff,$ff,$ff,$ff,$ff,$ff,$7e	;'&'
	.byte	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff	;'''
	.byte	$7e,$ff,$ff,$ff,$ff,$ff,$ff,$7e	;'('
	.byte	$3c,$7e,$ff,$ff,$ff,$ff,$7e,$3c	;')'
	.byte	$18,$3c,$7e,$ff,$ff,$7e,$3c,$18	;'*'
	.byte	$00,$18,$3c,$7e,$7e,$3c,$18,$00	;'+'
	.byte	$00,$00,$18,$3c,$3c,$18,$00,$00	;','
	.byte	$00,$00,$00,$18,$18,$00,$00,$00	;'-'
	.byte	$00,$00,$00,$00,$00,$00,$00,$00	;'.'


COPYRIGHT:
                ;********************************
 .byte	$74,$74,$74,$74,$74,$74,$1D,$3A,$20,$26,$3B,$74,$17,$3B,$30,$31
 .byte	$74,$16,$2D,$74,$79,$04,$35,$3A,$79,$74,$74,$74,$74,$74,$74,$74

BALL_SINE:
	
 .byte  0,0,0,0,0,0,0,1,1,1,1,2,2,2,3,3,3,4,4,5,5,6,6,7,8,8,9,10,10
 .byte  11,12,13,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,30
 .byte  31,32,33,35,36,37,39,40,41,43,44,46,47,49,50,52,53,55,56,58
 .byte  59,61,63,64,66,68,69,71,73,75,76,78,80,82,84,86,87,89,91,93
 .byte  95,97,99,101,103,105,107,109,111,113,115,117,119,121,123,125
 .byte  127,129,131,133,135,137,140,142,144,146,148,150,152,154,157
 .byte  159,161,163,165,167,170,172

 .byte  172,170,167,165,163,161,159,157,154,152,150,148,146,144,142,140,137
 .byte  135,133,131,129,127,125,123,121,119,117,115,113,111,109,107,105,103
 .byte  101,99,97,95,93,91,89,87,86,84,82,80,78,76,75,73,71,69,68,66,64,63
 .byte  61,59,58,56,55,53,52,50,49,47,46,44,43,41,40,39,37,36,35,33,32,31
 .byte 30,28,27,26,25,24,23,22,21,20,19,18,17,16,15,14,13,13,12,11,10,10
 .byte 9,8,8,7,6,6,5,5,4,4,3,3,3,2,2,2,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0



;BOUNCE1:	.byte	0,0,0,0,0,0,0,1,1,1,1
;BOUNCE2:	.byte	0,0,0,0,0,1,1,2,2,2,2
;BOUNCE3:	.byte	0,0,0,1,1,2,2,3,3,3,3
;BOUNCE4:	.byte	0,0,1,2,2,3,3,4,4,4,4
;BOUNCE5:	.byte	0,1,2,3,3,4,4,5,5,5,5
;BOUNCE6:	.byte	0,0,1,2,2,3,3,4,4,4,4
;BOUNCE7:	.byte	0,0,0,1,1,2,2,3,3,3,3
;BOUNCE8:	.byte	0,0,0,0,0,1,1,2,2,2,2
;BOUNCE9:	.byte	0,0,0,0,0,0,0,1,1,1,1

BOUNCE1:	.byte	0,0,0,0,0,0,0,1,1,1,1
BOUNCE2:	.byte	0,0,0,0,0,1,1,2,2,2,2
BOUNCE3:	.byte	0,0,0,1,1,2,2,3,3,4,5
BOUNCE4:	.byte	0,0,1,2,3,3,4,4,5,6,7
BOUNCE5:	.byte	0,1,2,3,3,4,5,6,7,8,8
BOUNCE6:	.byte	0,0,1,2,3,3,4,4,5,6,7
BOUNCE7:	.byte	0,0,0,1,1,2,2,3,3,4,5
BOUNCE8:	.byte	0,0,0,0,0,1,1,2,2,2,2
BOUNCE9:	.byte	0,0,0,0,0,0,0,1,1,1,1


RING:	.byte	0,1,2,3,4,5,6,7,8,9,$a
	.byte	9,8,7,6,5,4,3,2,1,0,1
	.byte	2,3,4,5,6,7,8,7,6,5,4
	.byte	3,2,1,0,1,2,3,4,5,4,3
	.byte	2,1,0,1,0,1,2,3,2,1,0
	.byte	1,0
	

YES:	.byte	"YES"
YES_END:

NO:	.byte	"NO "
NO_END:

LOW:	.byte	0,0,0,0
	.byte	0,0,0,1
	.byte	0,0,0,2
	.byte	0,0,0,3
	.byte	0,0,0,4
	.byte	0,0,0,5
	.byte	0,0,0,6
	.byte	0,0,0,7
	.byte	0,0,0,8
	.byte	0,0,0,9
	.byte	0,0,1,0
	.byte	0,0,1,1
	.byte	0,0,1,2
	.byte	0,0,1,3
	.byte	0,0,1,4
	.byte	0,0,1,5

HIGH:	.byte	0,0,0,0
	.byte	0,0,1,6
	.byte	0,0,3,2
	.byte	0,0,4,8
	.byte	0,0,6,4
	.byte	0,0,8,0
	.byte	0,0,9,6
	.byte	0,1,1,2
	.byte	0,1,2,8
	.byte	0,1,4,4
	.byte	0,1,6,0
	.byte	0,1,7,6
	.byte	0,1,9,2
	.byte	0,2,0,8
	.byte	0,2,2,4
	.byte	0,2,4,0


LIST_CGDATA:
	.byte	$1,$e0,$01
	.byte	$55,$00,$00
	.byte	$01,$ff,$ff
	.byte	$24,$00,$00
	.byte	$08,$80,$30
	.byte	$01,$00,$00
	.byte	$23,$00,$00
	.byte	$01,$ff,$ff
	.byte	$01,$00,$00

	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00

	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00
	

	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00

	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00

	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00

	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00
	.byte	$01,$00,$00


	.byte	$00,$00,$00


HDMACOLIST:

	.word	$0000,$0400,$0820,$0C20,$1040,$1460,$1860,$1C80
	.word	$1C80,$20A0,$24C0,$28C0,$2CE0,$3100,$3500,$3920 
	.word	$3920,$3500,$3100,$2CE0,$28C0,$24C0,$20A0,$1C80
	.word	$1C80,$1860,$1460,$1040,$0C20,$0820,$0400,$0000 


OPT_TEXT:
		;********************************
	
	.byte	"    Slow Rom Fix:       Yes     "
	.byte	"    Unlimited Lives:    Yes     "
	.byte	"    Unlimited Health:   Yes     "
	.byte	"    Invincibility:      Yes     "
	.byte	"    Unlimited Credits:  Yes     "
	.byte	"    Start at Level:             "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"        Bobby's World +5        "
	.byte	"     Trained by -Pan- & TWK     "
	.byte	"         Sound by Groo          "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "
	.byte	"                                "	
	

SCROLLTEXT:
	.byte	"                                "
	.byte	" -Pan- presents another kickin' trainer "
	.byte	"on October 10, 1994        "
	.byte	"    A few small hellos to: "
	.byte	"Censor, Nightfall, Premiere, Accumulators, "
	.byte	"Cyber Force,  Mystic..      "
	.byte	"To order copiers call 718-630-9869!        "
	.byte	" Wild Card DX arrives THIS WEEK! YA!!      "
	.byte	"           "
	.byte	" -Pan-                  "
	.byte	"                                ",0

Type:	; 0 = yes/no ; 1 = number
	.byte	0,0,0,0,0,1,1,1,0

Begin:
        .byte   2,4,4,1,0,1,1,1,3

	.code

Number:
	.word	MAX_OPT		; number of options

Options:

Min:	
	.byte	1,0,1,1,0,1,1,1,1

Max:
	.byte	9,5,5,5,5,5,$a,8,5

Slow:
	php
	sep	#$30
	.byte	$af,$00,$80,$70
	and	#$01
	eor	#$01
	sta	REG_MEMSEL
	plp
	rtl




Cheat:
	.byte	$ad,$18,$42
	.byte	$85,$7a
	pha
	php
	sep	#$30
	.byte	$af,$01,$80,$70
	beq	Livesoff
	lda	#$09
	sta	$1da1
	sta	$1da3
Livesoff:
	.byte	$af,$02,$80,$70
	beq	Damage
	lda	#$0a
	sta	$1d09
	sta	$1d0b

Damage:
	;.byte	$af,$03,$80,$70
	;beq	noammo
	;lda	#$99
	;sta	$1096
noammo:
	.byte	$af,$03,$80,$70
	beq	nohyper
	lda	#$01
	sta	$1db1
	sta	$1db3

nohyper:
	.byte	$af,$04,$80,$70
	beq	nothingy
	lda	#$01
	.byte	$8f,$e0,$65,$7e
nothingy:
	;.byte	$af,$05,$80,$70
	;beq	nojumpy
	;rep	#$30
	;.byte	$a5,$7a
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
	.byte	$af,$03,$80,$70
	beq	timeoff
	plp
	.byte	$5c,$ab,$89,$01
	rtl
timeoff:
	plp
	.byte	$a9,$e5,$04
	.byte	$85,$e9
	.byte	$5c,$9f,$89,$01
	;rtl
LEVEL:
	php
	rep	#$30
	.byte	$af,$05,$80,$70
	dec a
	.byte    $8f,$ff,$ff,$70
	and	#$00ff
	asl a
	clc
	adc	>$70ffff
	and	#$00ff
	sta	>$7e137b
	plp
	rtl

leveljunk:
	.byte	0,3,6,9,$c

IRQ:
	pha
	php
	sep	#$20
	.byte	$af,$01,$80,$70
	beq	IRQtime
	lda	#$03
	sta	>$7e1395
IRQtime:
	.byte	$af,$02,$80,$70
	beq	IRQmoney
	lda	#$03
	sta	>$7e139b
	sta	>$7e139d
IRQmoney:
	.byte	$af,$03,$80,$70
	beq	IRQcreds
	lda	#$78
	sta	>$7e1b05
IRQcreds:
	.byte	$af,$04,$80,$70
	beq	IRQend
	lda	#$03
	sta	>$7e1397

IRQend:
	plp
	pla
	.byte	$5c,$f7,$f4,$00

