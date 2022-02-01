;-------------------------------------------------------------------------;
.include "bg1_scrolltext.inc"
.include "graphics.inc"
.include "oam.inc"
.include "snes.inc"
.include "snes_decompress.inc"
.include "snes_joypad.inc"
;-------------------------------------------------------------------------;
.import clear_vram
;-------------------------------------------------------------------------;
.export DoIntro3
;-------------------------------------------------------------------------;

;*****************************************
;*  elitendo intro 3			*
;*  the date aug '93			*
;*  menu options			*
;*  filly part				*
;*  scroller 32*32 animation ;font	* 
;*  all code by radium ½.		*
;*****************************************


;-------------------------------------------------------------------------;
BG3_YES = 04h	;0ch
BG3_NO = 00h	;08h
BG3_START_LINE = 10*32
COLOR_DELAY = 15
MAX_OPT = 6
OAM_LEFT = $10
OAM_TOP = $0c
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
BG2MAP = 04800h
BG2GFX = 04000h
BG3GFX = 08000h
BG3MAP = 0e000h
OAMGFX = 0c000h
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
.zeropage
;/////////////////////////////////////////////////////////////////////////;


;-------------------------------------------------------------------------;
animate_delay:
	.res 1
fade:
	.res 1

menu_row:
	.res 1
menu_vram:
	.res 2

bghofs:
	.res 2
bgvofs:
	.res 2
bg3move:
	.res 1

tmp_color:
	.res 2

;/////////////////////////////////////////////////////////////////////////;
        .bss
;/////////////////////////////////////////////////////////////////////////;


optionlist:
	.res	MAX_OPT

ram_cgdata:
	.res	32


;/////////////////////////////////////////////////////////////////////////;
	.code
;/////////////////////////////////////////////////////////////////////////;


	.a8
	.i16


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
DoIntro3:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	sei
	stz	REG_NMITIMEN

	jsr	clear_vram
	jsr	SetupPalette
	jsr	ScreenSettings
	jsr	SetMenu

	lda	#^SCROLLTEXT
	ldx	#SCROLLTEXT
	jsr	SetupBG1Scrolltext

	DoDecompressDataVram gfx_bg1Tiles, BG1GFX

	DoDecompressDataVram gfx_bg2Tiles, BG2GFX
	DoDecompressDataVram gfx_bg2Map, BG2MAP

	DoDecompressDataVram gfx_bg3Tiles, BG3GFX

	DoDecompressDataVram gfx_oamTiles, OAMGFX

	DoCopyPalette gfx_bg2Pal, 32, 16
	DoCopyPalette gfx_oamPal, 128, 16

	lda	#200
	sta	bg3move

	ldx	#0000h
	stx	bghofs
	stx	bgvofs
	
	stz	fade
	stz	menu_row		; first menu option

	ldx	#(BG3MAP/2)+BG3_START_LINE+(4*32)+3	; start option line in vram (arrow)
	stx	menu_vram		; $5000 address tiles bg3

	ldx	#MAX_OPT		; set counter on last option
	lda	#1
	sta	optionlist,x
	sta	frame_ready

	lda	#NMI_ON|NMI_JOYPAD
	sta	REG_NMITIMEN
;-------------------------------------------------------------------------;
Loop:
;-------------------------------------------------------------------------;
	jsr	wait_vbl
	jsr	FadeIn
	jsr	MoveBG3
	jsr	MoveBG2
	jsr	BG1Scrolltext
	;jsr	Animate

	lda	joy1_down+1
	ora	joy2_down+1
	lsr
	bcs	Right
	lsr
 	bcs	l_left			; left?
	lsr
	bcs	Down
	lsr
	bcs	Up
	lsr
	bcs	exit			; start?
	bra	Loop
;-------------------------------------------------------------------------;
exit:	stz	REG_TM
;-------------------------------------------------------------------------;
	lda	optionlist
	cmp	#1
	beq	SlowRomFix
;-------------------------------------------------------------------------;
NoSlowRomFix:
SlowRomFix:
	jmp	DoIntro3

l_left:	jsr	Left
	bra	Loop
;-------------------------------------------------------------------------;
Down:
;-------------------------------------------------------------------------;
	lda 	menu_row
	cmp     #MAX_OPT
	beq	no_way	
;-------------------------------------------------------------------------;
	inc	menu_row

	ldx	menu_vram		; menu vram pointer
	stx	REG_VMADD
	lda	#41			; clear old status
	sta	REG_VMDATAL
	stz	REG_VMDATAH

	rep	#30h

	lda	menu_vram		; count +32 1 line further
	adc	#32	
;-------------------------------------------------------------------------;
arrow_store_menu_vram:
;-------------------------------------------------------------------------;
	sta	menu_vram
	tax

	sep	#20h

	stx	REG_VMADD
	lda	#'>'&3fh		; set arrow
	sta	REG_VMDATAL
	lda	#BG3_PRIO|BG3_NO	; prio 1
	sta	REG_VMDATAH
	bra	Loop
;-------------------------------------------------------------------------;	
Up:	lda 	menu_row
	beq	Loop
;-------------------------------------------------------------------------;
	dec	menu_row

	ldx	menu_vram		; menu vram pointer
	stx	REG_VMADD
	stz	REG_VMDATAL		; clear old status
	lda	#BG3_PRIO|PALETTE0	; prio 1
	sta	REG_VMDATAH

	rep	#30h

	lda	menu_vram		; count +32 1 line further
	sbc	#32	
	bra	arrow_store_menu_vram
;-------------------------------------------------------------------------;
no_way:	jmp	Loop

	;right left for yes and no options
;-------------------------------------------------------------------------;
Right:
;-------------------------------------------------------------------------;
	sep	#30h

	ldx	menu_row
	lda	OPTION_TABLE,x
	cmp	#1
	bmi	Right0
;-------------------------------------------------------------------------;
	lda	optionlist,x
	cmp	OPTION_TABLE,x		; max counter value
	beq	no_countup
	inc				; else inc +1
	sta	optionlist,x		; countup
	
	jsr	IncreaseMenuVram23
	stx	REG_VMADD

	sep	#30h			; all 8b

	ldx	menu_row
	lda	optionlist,x
	jsr	MakeDecimal
	txa				; high part
	clc
	adc	#'0'&3fh
	sta	REG_VMDATAL
	lda	#BG3_PRIO|BG3_NO	; prio 1
	sta	REG_VMDATAH
	tya				; low part
	clc
	adc	#48
	sta	REG_VMDATAL
	lda	#BG3_PRIO|BG3_NO
	sta	REG_VMDATAH
;-------------------------------------------------------------------------;
no_countup:
;-------------------------------------------------------------------------;
	rep	#10h
	jmp	Loop
;-------------------------------------------------------------------------;
Right0:	lda	#1
	sta	optionlist,x		; set optionlist to 1 (yes)

	jsr	IncreaseMenuVram23

	stx	REG_VMADD
	lda	#'Y'&3fh
	sta	REG_VMDATAL
	lda	#BG3_PRIO|BG3_YES	; palette 0 prio 1
	sta	REG_VMDATAH

	lda	#'E'&3fh
	sta	REG_VMDATAL
	lda	#BG3_PRIO|BG3_YES	; palette 0 prio 1
	sta	REG_VMDATAH

	lda	#'S'&3fh
	sta	REG_VMDATAL
	lda	#BG3_PRIO|BG3_YES	; palette 0 prio 1
	sta	REG_VMDATAH
	jmp	Loop
;-------------------------------------------------------------------------;
Left:
;-------------------------------------------------------------------------;
	sep	#30h			; set all 8b

	ldx	menu_row
	lda	OPTION_TABLE,x
	cmp	#1			; counter option ?
	bmi	Left0
;-------------------------------------------------------------------------;
	lda	optionlist,x
	cmp	#1
	beq	no_countdown
;-------------------------------------------------------------------------;
	dec				; else dec
	sta	optionlist,x		; countdown

	jsr	IncreaseMenuVram23
	stx	REG_VMADD

	sep	#30h			; all 8b

	ldx	menu_row
	lda	optionlist,x
	jsr	MakeDecimal
	txa				; high part
	clc
	adc	#'0'&3fh
	sta	REG_VMDATAL
	lda	#BG3_PRIO|BG3_YES	; prio 1
	sta	REG_VMDATAH
	tya				; low part
	clc
 	adc	#48
	sta	REG_VMDATAL
	lda	#20h
	sta	REG_VMDATAH
;-------------------------------------------------------------------------;
no_countdown:
;-------------------------------------------------------------------------;

	rep	#10h
	rts
;-------------------------------------------------------------------------;
Left0:
;-------------------------------------------------------------------------;
	stz	optionlist,x		; set optionlist to zero (no)

	jsr	IncreaseMenuVram23

	stx	REG_VMADD
	lda	#'N'&3fh
	sta	REG_VMDATAL
	lda	#BG3_PRIO|BG3_NO	; palette 0 prio 1
	sta	REG_VMDATAH
	lda	#'O'&3fh
	sta	REG_VMDATAL
	lda	#BG3_PRIO|BG3_NO	; palette 0 prio 1
	sta	REG_VMDATAH
	stz	REG_VMDATAL
	sta	REG_VMDATAH
	rts
;-------------------------------------------------------------------------;
IncreaseMenuVram23:
;-------------------------------------------------------------------------;
	rep	#30h

	lda	menu_vram		
	clc
	adc	#23			; 22 chrs	
	tax

	sep	#20h

	rts


;=========================================================================;
FadeIn:
;=========================================================================;
	lda	fade
	cmp	#10h
	bcs	no_fade
;-------------------------------------------------------------------------;
	sta	REG_INIDISP
	inc	fade
;-------------------------------------------------------------------------;
no_fade:rts


;=========================================================================;
MoveBG3:
;=========================================================================;
	lda	bg3move
	beq	no_move
;-------------------------------------------------------------------------;
	sta	REG_BG3VOFS
	stz	REG_BG3VOFS
	sec
	sbc	#04h
	sta	bg3move
;-------------------------------------------------------------------------;
no_move:
;-------------------------------------------------------------------------;
	rts


;=========================================================================;
SetMenu:
;=========================================================================;
	lda	#VMAIN_INCH
	sta	REG_VMAIN

	ldx	#(BG3MAP/2)+BG3_START_LINE
	stx	REG_VMADD

	ldx	#MAX_OPT		; first clear optiontable
clropt:	stz	optionlist,x
	dex
	bne	clropt
;-------------------------------------------------------------------------;
:	lda	MENU_TEXT,x
	and	#3fh
	sta	REG_VMDATAL
	lda	#BG3_PRIO|BG3_NO
	sta	REG_VMDATAH
	inx
	cpx	#MENU_TEXT_END-MENU_TEXT
	bne	:-
;-------------------------------------------------------------------------;
	rts


;=========================================================================;
Animate:
;=========================================================================;
	inc	animate_delay
	lda	animate_delay
	cmp	#COLOR_DELAY			; create what delay
	bne	no_animate
;-------------------------------------------------------------------------;
	stz	animate_delay

	ldx	ram_cgdata+0eh			; save color 7
	phx
	
	ldx	#12
	ldy	#14
;-------------------------------------------------------------------------;
setit:	lda	ram_cgdata,x
	sta	ram_cgdata,y
	lda	ram_cgdata+1,x
	sta	ram_cgdata+1,y
	dey
	dey
	dex
	dex
	bne	setit	
;-------------------------------------------------------------------------;
	plx
	stx	ram_cgdata+02h			; set color 1

	lda	#16				; palette 1
	sta	REG_CGADD

	lda	#DMAP_XFER_MODE_2
	sta	REG_DMAP4

	lda	#<REG_CGDATA
	sta	REG_BBAD4

	ldx	#ram_cgdata
	stx	REG_A1T4L
	stz	REG_A1B4

	ldx	#32
	stx	REG_DAS4L

	lda	#%00010000
	sta	REG_MDMAEN

	stz	REG_CGADD
	stz	REG_CGDATA
	stz	REG_CGDATA
;-------------------------------------------------------------------------;
no_animate:
stop:
;-------------------------------------------------------------------------;
	rts


;=========================================================================;
MoveBG2:
;=========================================================================;
	inc	bgvofs
	lda	bgvofs
	sta	REG_BG2VOFS
	stz	REG_BG2VOFS
	sta	REG_BG2HOFS
	stz	REG_BG2HOFS

	;ldx	bghofs			; move h back and forth
	;lda	BGHOFS_CURVE,x
	;cmp	#0ffh
	;bne	no_x
;-------------------------------------------------------------------------;
	;ldx	#0000h
;-------------------------------------------------------------------------;
;no_x:	lda	BGHOFS_CURVE,x
	;sta	REG_BG2HOFS
	;stz	REG_BG2HOFS
	;inx
	;stx	bghofs
	rts


;=========================================================================;
SetupPalette:
;=========================================================================;
	;-------------------------------set the colors
	lda	#0			; palette 0
	sta	REG_CGADD
	ldx	#0000h
;-------------------------------------------------------------------------;
set_menu_col:				; setcolor for menu
;-------------------------------------------------------------------------;
	lda	PALETTE,x
	sta	REG_CGDATA
	inx
	cpx	#32
	bne	set_menu_col
;-------------------------------------------------------------------------;
	lda	#16			; palette 1
	sta	REG_CGADD
	ldx	#0000h
;-------------------------------------------------------------------------;
set_scr_col:
;-------------------------------------------------------------------------;
	lda	PALETTE+32,x		; setcolor in cgram and adress $00
	sta	REG_CGDATA		; for scroller
	sta	ram_cgdata,x
	inx
	lda	PALETTE+32,x
	sta	REG_CGDATA
	sta	ram_cgdata,x
	inx
	cpx	#32
	bne	set_scr_col
;-------------------------------------------------------------------------;
 	rts


;=========================================================================;
ScreenSettings:
;=========================================================================;
	lda	#BGMODE_1|BGMODE_PRIO	; mode 1 bg & bg 3 highest prio 
	sta	REG_BGMODE		; REG_BGMODE

	lda	#BG1MAP>>9|SC_64x32	; size 1 two screens
	sta	REG_BG1SC		; tile table
	lda	#BG2GFX>>9
	sta	REG_BG12NBA		; font $0000, filly $4000
	lda	#BG2MAP>>9		; filly tile
	sta	REG_BG2SC	
	lda	#BG3MAP>>9|SC_32x64	; $5000 tiles menufont
	sta	REG_BG3SC
	lda	#BG3GFX>>13		; $4000  menufont data
	sta	REG_BG34NBA	

	lda	#TM_OBJ|TM_BG3|TM_BG2|TM_BG1	; show bg1+2+3
	sta	REG_TM

	lda	#OBSEL_8_64|OBSEL_BASE(OAMGFX)
	sta	REG_OBSEL 

	lda	#VMAIN_INCH
	sta	REG_VMAINC

	;-------------------------------

	ldx	#BG1MAP/2			; make tiles bg1 sfont screen
	stx	REG_VMADD

	ldx	#656				; black tile
	ldy	#0000h
;-------------------------------------------------------------------------;
make_fnt_tile:
;-------------------------------------------------------------------------;
	stx	REG_VMDATAL
	iny
	cpy	#2048				; tile for two screens	
	bne     make_fnt_tile
;-------------------------------------------------------------------------;
       	ldx	#BG3MAP/2			; make tiles bg3 menu screen
	stx	REG_VMADD
	lda	#41
	ldx	#0000h
;-------------------------------------------------------------------------;
make_menu_tile:
;-------------------------------------------------------------------------;
	sta	REG_VMDATAL
	stz	REG_VMDATAH
	inx
	cpx	#32*32*2			; 1 screen
	bne     make_menu_tile
;-------------------------------------------------------------------------;
	ldx	#0200h
	lda	#0e0h
:	sta	oam_table,x
	dex
	sta	oam_table,x
	dex
	stz	oam_table,x
	dex
	stz	oam_table,x
	dex
	bpl	:-

	ldx	#0020h
	lda	#%01010101
:	sta	oam_hitable,x		; initialize all sprites to be off the screen
	dex
	bpl	:-

	ldx	#(OAM_DATA_END-OAM_DATA)-1
:	lda	OAM_DATA,x
	sta	oam_table,x
	dex
	bpl	:-

	lda	#%10101010
	sta	oam_hitable

	rts


;=========================================================================;
wait_vbl:
;=========================================================================;
	lda	REG_RDNMI
	bit	#80h
	beq	wait_vbl
	lda	REG_RDNMI
	rts
	

	.a8
	.i8				; all 8b
;---------------------------------------; make accu decimal
MakeDecimal:				; output: x high / y low digit
;-------------------------------------------------------------------------;
	clc
	adc	#1
	ldx	#0
;-------------------------------------------------------------------------;
decimal:sbc	#10			; accu-10
	bcc	neg
;-------------------------------------------------------------------------;
	inx
	bra	decimal
;-------------------------------------------------------------------------;
neg:	adc	#10
	
	tay
 	clc

	rts


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
BGHOFS_CURVE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
 .byte	000,002,004,006,008,010,012,014,016,018,020,022,024,026,028,030
 .byte	032,034,036,038,040,042,044,046,048,050,052,054,056,058,060,062
 .byte	064,066,068,070,072,074,076,078,080,082,084,086,088,090,092,094
 .byte	096,098,100,098,096,094,092,090,088,086,084,082,080,078,076,074
 .byte	072,070,068,066,064,062,060,058,056,054,052,050,048,046,044,042
 .byte	040,038,036,034,032,030,028,026,024,022,020,018,016,014,012,010
 .byte	08,06,04,02,$ff
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
MENU_TEXT:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
;text start set by BG3_START_LINE
	.byte	"             PRESENTS           " 
	.byte	"                                "
	.byte	"           TERMINATOR 6         "
	.byte	"                                "
	.byte	"   >SLOW ROM FIX          NO    " ; first level option
	.byte	"    UNLIMITED LIVES       NO    "
	.byte	"    UNLIMITED ENERGY      NO    "
	.byte	"    UNLIMITED WEAPONS     NO    "	
	.byte	"    UNLIMITED TIME        NO    "
	.byte	"    LEVEL CHEAT           NO    "
	.byte	"    STARTING LEVEL        01    "
	.byte	"                                "
	.byte	"     PRESS START TO GO ON !     "
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
MENU_TEXT_END:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	
;op.table $00 -Y/N option greater than $00 -counter max select  
;optionlist 0-no 1-yes 
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
OPTION_TABLE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$00,$00,$00,$00,$00,$00,$20	; option
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SCROLLTEXT:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	" RELEASED BY MAGICAL TRAINED BY MCA "
	.byte	"                                    "
 	.byte	"GREETZ FLY OUT TO.. VISION..DAX AND CORSAIR.."
	.byte     "LEGEND..ANTHROX..FAIRLIGHT..VISA..PREMIERE.."
	.byte     "CENSOR..WARDUKE AND RTS .... INTROCODE BY RADIUM"
	.byte 	"..GRAPHICART BY LOWLIFE AND RADIUM",$ff
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
PALETTE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.word	$0000,$5294,$6318,$739c,$0000,$739c,$77bd,$7bde
	.word	$0000,$7ed0,$7f74,$7ff8,$0000,$26be,$1f3f,$279d

	.word	$0000,$0000,$0008,$108C,$3110,$4190,$5214,$6298
	.word	$6318,$0000,$0000,$0000,$0000,$0000,$0000,$0000
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
OAM_DATA:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	OAM_LEFT+(64*0),OAM_TOP,$00,%00110000
	.byte	OAM_LEFT+(64*1),OAM_TOP,$08,%00110000
	.byte	OAM_LEFT+(64*2),OAM_TOP,$80,%00110000
	.byte	OAM_LEFT+(64*3),OAM_TOP,$88,%00110000
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
OAM_DATA_END:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
