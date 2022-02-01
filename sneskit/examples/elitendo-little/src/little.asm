;---------------------------------------------------------------------
.include "snes.inc"
.include "snes_decompress.inc"
.include "snes_joypad.inc"
.include "snes_zvars.inc"
;---------------------------------------------------------------------
.importzp joy1_down, joy2_down
;---------------------------------------------------------------------
.export DoLittle
;---------------------------------------------------------------------
; 2e RTS Intro, Coded By Dizzy & The Doctor..........
;---------------------------------------------------------------------
menupoint	= m0 ;b
menu_vram	= m1 ;w
optionlist	= $500
;------------------------------------------
top_w		= 32*12+3	; 32*3
menu_lines 	= 6*2		; (total*2)-2
mlines		= 7		; aantal regels onder 
levels 		= 7		; total		;menu lines
trnadres 	= $700000	; sram
bank 		= $00		; bank waar de intro staat
orgbank		= $00		; originele bank
pro 		= $0000		; highrom games +$8000
game 		= $008000	; reset vector
;------------------------------------------

;---------------------------------------------------------------------
	.bss
;---------------------------------------------------------------------
counter:
	.res 2
scrlpos:
	.res 2
scrlval:
	.res 2
txt_off:
	.res 2
hd_scrl:
	.res 2
scrl8al:
	.res 2

;---------------------------------------------------------------------
	.code
;---------------------------------------------------------------------

DoLittle:
	rep	#$30			; x,y,a fixed -> 16 bit mode
	sep	#$20			; accumulator ->  8 bit mode

	jsr     clear_ram
	lda	#BGMODE_PRIO|BGMODE_1
	sta	REG_BGMODE     	 	; screen mode 1
	stz	REG_BG3SC       	; 3rd layer in $0800
	lda	#$11
	sta	REG_BG34NBA
	lda	#TM_BG3 	        ; enable playfields
	sta	REG_TM			;

	lda	#$80			; automatic increase vram adres whenever
	sta	REG_VMAIN       	; you write in it or read out of it.
	ldx	#$ff00			; Erase Video ram
	ldy	#$0
	sty	REG_VMADDL		; vram=$0
clrall:	sty	REG_VMDATAL		; erase
	dex
	bne	clrall
        
	ldx	#$1000+256
	stx	REG_VMADDL
	ldx	#0
copy2:	lda	font8x8+32,x
	sta	REG_VMDATAL
	inx
	lda	font8x8+32,x
	sta	REG_VMDATAH
	inx
	cpx	#944
	bne	copy2

;***************** zet menu text ****************************************
 
	ldx	#32*3+3			; 32*3	top line start
	stx	REG_VMADDL
	ldy	#3
	ldx	#0
copystr:
	phy
	ldy	#0
copyk:	lda	ktext,x
	sta	REG_VMDATAL
	lda	#%00101100
	sta	REG_VMDATAH
	inx
	iny
	cpy	#32-6		  	; 7 colored lines
	bne	copyk
	phx
	ldx	#32+6
copyclr:
	stz	REG_VMDATAL
	stz	REG_VMDATAH
	dex
	bne	copyclr
	plx
	ply
	dey
	bne	copystr
	 
	ldx	#top_w
	stx	REG_VMADDL
	ldy	#mlines
	ldx	#0
copy3lop:
	phy
	ldy	#0
copy3: 	lda	mtext,x			; others normal
	sta	REG_VMDATAL
	lda	#%00100100
	sta	REG_VMDATAH
	inx
	iny
	cpy	#32-6
	bne	copy3
	phx
	ldx	#6
clrlop1:
	stz	REG_VMDATAL
	stz	REG_VMDATAH
	dex
	bne	clrlop1
	plx
	ply
	dey
	bne	copy3lop
	ldx	#top_w
	jsr	greenline

;*******************************************************

	DoCopyPalette font8x8, 0, 16

	lda	#%11
	sta	REG_W34SEL
	lda	#8
	sta	REG_WH0
	lda	#255-8
	sta	REG_WH1
	lda 	#%100
	sta	REG_TMW

;*****************************************************
; Hdma Init shit..
;*****************************************************

	stz	REG_HDMAEN		; zet hdma uit
	stz	REG_DMAP1  		; per regel dan.
	lda	#<REG_CGADD  		; kopieer naar adres REG_INIDISP + $0d
	sta	REG_BBAD1  		; iedere regel moeten de 2 bytes naar $210d
	
	ldx	#kleuren
	stx	REG_A1T1L
	lda	#bank 
	sta	REG_A1B1		; bank waar tabel instaat
	sta	REG_A1B2

	lda	#DMAP_XFER_MODE_2
	sta	REG_DMAP2
	sta	REG_DMAP0
	lda	#<REG_CGDATA
	sta	REG_BBAD2
	ldx	#kleuren1
	stx	REG_A1T2L

	lda	#<REG_BG3HOFS	   	; kopieer naar adres REG_INIDISP + $11 (hscrl layer 3)
	sta	REG_BBAD0	  	; 
	ldx	#hd_scrl
	stx	REG_A1T0L
	stz	REG_A1B0		; bank waar tabel instaat

;********************* END HDMA ****************

	lda	#127			; 1e 127 lijnen niet scrollen
	sta	hd_scrl
	lda	#16*3
	sta	hd_scrl+3
	lda	#127-(16*3)
	sta	hd_scrl+6

	ldx	#23*32			; laatste teken van scroll op scherm
	stx	scrlval

;****************************************************

	ldx	#top_w
	stx	menu_vram

	ldx	#menu_lines+2
clearob:
	stz	optionlist,x
	dex
	bne	clearob
	
	ldx	#menu_lines
	lda	#1
	sta	optionlist,x

	lda	#NMI_ON|NMI_JOYPAD
	sta	REG_NMITIMEN

	lda	#$0f
	sta	REG_INIDISP		; screen visible

;****************************************************************
; Main loop of programme......
;****************************************************************

vbl:	jsr	vsync
	lda	#%111			; kanaal 0-2 aan van hdma
	sta	REG_HDMAEN	

txtscrl:
	lda	scrlpos
	inc
	inc
	sta	hd_scrl+7
	sta	scrlpos
	inc	scrl8al
	inc	scrl8al
	lda	scrl8al
	cmp	#8			; deelbaar door 8 (don't ask)????
	bne	joy_l
	stz	scrl8al
	ldx	scrlval
	stx	REG_VMADDL		; op welk vram adres schrijven
	inx
	cpx	#23*32+32
	bne	go_on
	ldx	#23*32
go_on:	stx	scrlval
	ldx	txt_off
again:	lda	text,x
	cmp	#255			; Eind van de txt???????
	bne	go_on2
	ldx	#0	
	stx	txt_off
	bra	again
go_on2:	sta	REG_VMDATAL		; pleur char in vram
	lda	#%00101000
	sta	REG_VMDATAH
	inx
	stx	txt_off			; volgend character

;********************************************** menu routs

joy_l:	rep	#20h
	lda	joy1_down
	bit	#(JOYPAD_LEFT|JOYPAD_B)
	sep	#20h
	beq	joy_r
	jsr	left

joy_r:	rep	#20h
	lda	joy1_down
	bit	#(JOYPAD_RIGHT|JOYPAD_A)
	sep	#20h
	beq	joy_d
	jsr	right

joy_d:	rep	#20h
	lda	joy1_down
	bit	#(JOYPAD_DOWN)
	sep	#20h
	beq	joy_u
	jsr	down

joy_u:	rep	#20h
	lda	joy1_down
	bit	#(JOYPAD_UP)
	sep	#20h
	beq	joy_s
	jsr	up

joy_s:	rep	#20h
	lda	joy1_down
	bit	#(JOYPAD_START)
	sep	#20h
	bne	exit

 	jmp	vbl

exit:	rep	#$30
	sep	#$20
	stz	REG_NMITIMEN		; stop nmi...
	stz	REG_MDMAEN
	stz	REG_HDMAEN
	lda	#$80
	sta	REG_INIDISP
	jsr	clear_vram

	ldx	#menu_lines+2
copytrn:
	lda	optionlist,x
	sta	trnadres,x
	dex
	bpl	copytrn

	jsr	clear_ram
	;sep	#$30
	;lda	#orgbank
	;pla
	;plb
	;jml	game
	jmp	DoLittle

;---------------------------------------; menu
down:	lda	menupoint
	cmp	#menu_lines
	beq	no_way	
	inc	menupoint
	inc	menupoint

	jsr	whiteline
	stz	REG_VMDATAH

	rep	#$30
	lda	menu_vram		; count +32 1 line further
	clc
	adc	#32	
	sta	menu_vram
	tax
	sep	#$20

;----------------------------------------------------
greenline:
	stx	REG_VMADDL
	lda	#$3e			; set arrow
	sta	REG_VMDATAL
	lda	#$20
lpp1:   ldx	#28
lpp2:	sta	REG_VMDATAH
	dex
	bne	lpp2
	rts

whiteline:
	ldx	menu_vram		; menu vram pointer
	stx	REG_VMADDL
	lda	#32	
	sta	REG_VMDATAL		; clear old status
	lda	#$20+4			; prio 1/color
	bra	lpp1

;----------------------------------------------------
up:	lda	menupoint
	beq	no_way	
	dec	menupoint
	dec	menupoint

	jsr	whiteline
	lda	#$20+4			; prio 1
	sta	REG_VMDATAH

	rep	#$30
	lda	menu_vram		; count one back
	sec
	sbc	#32	
	sta	menu_vram
 	tax
	sep	#$20

	bra	greenline

no_way:	rts

	 ; right left for yes and no options

right:	sep	#$30
	ldx	menupoint
	lda	optable,x
	cmp	#1
	bmi	right0

	lda	optionlist,x
	cmp    	optable2		; max counter value(level)
	beq	no_count
	inc	a			; else inc +1
	sta	optionlist,x		; countup
	
do_decimal:
	rep	#$30
	lda	menu_vram		; vrampointer to option	
	clc
	adc	#23
	tax
	sep	#$20
	stx	REG_VMADDL
	sep	#$30			; all 8b
	ldx	menupoint
	lda	optionlist,x
	ldx	#0
	jsr	make_decimal
	txa				; high part
	jsr	putdeci
	tya				; low part
	jsr	putdeci

no_count:
	rep	#$30
	sep	#$20
	rts

putdeci:
	clc
	adc	#$30			; '0'chr
	sta	REG_VMDATAL 
	lda	#$20			; prio 1
	sta	REG_VMDATAH
	rts

right0:
	lda	#1
	sta	optionlist,x		; set optionlist to 1 (yes)
	rep	#$30
	ldx	#0
	bra	doyesno
	
left:	sep	#$30			; set all 8b
	ldx	menupoint
	lda     optable,x
	cmp	#1			; counter option ?
	bmi	left0

	lda	optionlist,x
	cmp	#1
	beq	no_count
	dec				; else dec
	sta	optionlist,x		; countdown
	bra     do_decimal

left0:	stz	optionlist,x		; set optionlist to zero (no)
	rep	#$30
	ldx	#3
 	
doyesno:
	phx
	lda	menu_vram		
	clc
	adc	#23			; 22 chrs	
	tax
	sep	#$20
	stx	REG_VMADDL
	plx
    	ldy	#3
doynlop:
	lda	yesno,x		
	sta	REG_VMDATAL
	lda	#$20			; pallet 0 prio 1
	sta	REG_VMDATAH
	inx
	dey
	bne	doynlop
	rts

yesno:	.byte "YESNO "

;---------------------------------------; make accu decimal
make_decimal:				; output: x high / y low digit
	clc
	sec
decimal:
	sbc	#10			; accu-10
	bcc	neg
	inx
	bra	decimal
neg:	clc	
	adc	#10
	tay
 	clc
	rts

;*********** CLEAR RAM & VRAM ROUTS ***********************************

clear_vram:
	lda	#$80			; auto increment
       	sta	REG_VMAIN		
	ldx	#$0000			
  	sta	REG_VMADDL
	ldy	#$7fff
clear:	stx	REG_VMDATAL		; vram data low
	dey
	bpl	clear
	rts

clear_ram:
	ldx	#$1000
clram:	stz	$0000,x
	dex
	bne	clram
	rts

;*************************************************************************

vsync:	lda	REG_RDNMI
	bpl	vsync
	rts

;**************** MENU TEXT + TRAINER DATA *******************************

kleuren:
	.byte 17,0
	.byte 1,$0
	.byte 49,$0
	.byte 1,$0
	.byte 6,$0
	.byte 1,$0
	.byte 96,$0
	.byte 1,0
	.byte 6,0
	.byte 1,$0
	.byte 8+7,$0
	.byte 1,0
	.byte 20,0
	.byte $0,$0

kleuren1:
	.byte 17,0,0
	.byte 1,50,0
	.byte 49,45,0
	.byte 1,40,0
	.byte 6,0,0
	.byte 1,0,60
	.byte 96,0,40
	.byte 1,0,32
	.byte 6,0,0
	.byte 1,224-127,1
	.byte 8+7,224,0
	.byte 1,224-64,0
	.byte 20,0,0
	.byte 0,0,0

optable2:
	.byte levels,levels,$ff,$ff

ktext:	.byte	"     E L I T E N D O      "
	.byte	"         TRAINED          "
	.byte	"        MAGIC BOY         "
mtext:
	.byte	">SLOWROM FIX           NO "
	.byte	" UNLIMITED LIVES       NO "
	.byte	" UNLIMITED ENERGY      NO "
	.byte	" UNLIMITED TIME        NO "
	.byte	" UNLIMITED XXXXX       NO "
	.byte	" UNLIMITED YYYYYY      NO "
	.byte	" START AT LEVEL        01 "
	.byte	$ff

optable:
	.byte	0,0,0,0,0,0,0,0,0,0,0,0,1,0	; normal options

font8x8:
	.incbin "../dist/8x8fnt2a.bp2"		; packed grafix

text:	.byte	"TRAINED BY MCA, INTRO BY RTS"
	.byte	", A RELEASE BY LYNCHMOB, "
	.byte	"GREETZ FLY OUT TO: ANTROX...CORSAIR & DAX...CAPITOL"
	.byte	"...CENSOR...FAIRLIGHT...LEGEND...LYNCHMOB..."
	.byte	"PREMIERE...ROMKIDS...AND YOU...                       " 
	.byte	255

