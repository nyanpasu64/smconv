;-------------------------------------------------------------------------;
.include "graphics.inc"
.include "snes.inc"
.include "snes_decompress.inc"
.include "snes_zvars.inc"
;-------------------------------------------------------------------------;
.importzp frame_ready
;-------------------------------------------------------------------------;
.import oam_table
;-------------------------------------------------------------------------;
.export DoCensor
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
OAMGFX = 00000h
BG1GFX = 02000h
BG1MAP = 0c100h
BG2GFX = 0c000h
BG2MAP = 0b000h
;-------------------------------------------------------------------------;
SCROLL_PAL	= 1
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
.bss
;/////////////////////////////////////////////////////////////////////////;


bg1_hofs:
	.res 1
bg1_vofs:
	.res 1
bg2_hsine:
	.res 1
bg2_vsine:
	.res 1
cgdata_l:
	.res 1
palette_index:
	.res 1
palette_timer1:
	.res 1
palette_timer2:
	.res 1
scroll_pal:
	.res 1
scroll_textpos:
	.res 2
sprite_ypos:
	.res 1


;-------------------------------------------------------------------------;
        .a8
        .i16
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
.code
;/////////////////////////////////////////////////////////////////////////;


;=========================================================================;
GetTopTile:
;=========================================================================;
	lda	SCROLLTEXT,x
	bne	:+
;-------------------------------------------------------------------------;
	ldx	#0000h
	stx	scroll_textpos
	bra	GetTopTile
;-------------------------------------------------------------------------;
:	cmp	#20h
	bcc	_nope
	cmp	#30h
	bcc	sub20
	cmp	#40h
	bcc	sub10
	cmp	#50h
	bcc	_exit
	cmp	#60h
	bcc	add10
	bra	_nope
;=========================================================================;
GetBottomTile:
;=========================================================================;
	lda	SCROLLTEXT,x
	cmp	#20h
	bcc	_nope
	cmp	#30h
	bcc	sub10
	cmp	#40h
	bcc	_exit
	cmp	#50h
	bcc	add10
	cmp	#60h
	bcc	add20
;-------------------------------------------------------------------------;
_nope:	lda	#20h		; load ASCII space
;-------------------------------------------------------------------------;
_exit:	sta	REG_VMDATAL
	;lda	#SCROLL_PAL<<2	; SCROLL_PAL should equal palette #
	stz	REG_VMDATAH	; ...but if it's pal 0 just use stz

	rts
;-------------------------------------------------------------------------;
add20:
;-------------------------------------------------------------------------;
	clc
	adc	#10h
;-------------------------------------------------------------------------;
add10:
;-------------------------------------------------------------------------;
	clc
	adc	#10h
	bra	_exit
;-------------------------------------------------------------------------;
sub20:
;-------------------------------------------------------------------------;
	sec
	sbc	#10h
;-------------------------------------------------------------------------;
sub10:
;-------------------------------------------------------------------------;
	sec
	sbc	#10h
	bra	_exit



;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
DoCensor:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	rep	#10h
	sep	#20h

	DoDecompressDataVram gfx_8x16_fontTiles, OAMGFX
	DoDecompressDataVram gfx_censorTiles, BG2GFX
	DoDecompressDataVram gfx_censorMap, BG2MAP
	DoCopyPalette gfx_censorPal, 16, 16

	jsr	Setup

	sep	#30h

	jsr	ResetBG1HOFS
	jsr	ResetBG1VOFS

	lda	#NMI_ON|NMI_JOYPAD
	sta	REG_NMITIMEN

	lda	#01h
	sta	frame_ready

	lda	#0fh
	sta	REG_INIDISP
;-------------------------------------------------------------------------;
MainLoop:
;-------------------------------------------------------------------------;
	jsr	ReadNMI
	jsr	ScrollText
	jsr	MoveLogo
	jsr	LogoPalette
	jsr	CreditSprites
	jsr	ScrollPalette
	jsr	MoveScrollV
	bra	MainLoop
;-------------------------------------------------------------------------;


;=========================================================================;
ScrollPalette:
;=========================================================================;
	lda	#01h
	sta	REG_CGADD
	lda	cgdata_l
	sta	REG_CGDATA
	lda	#03h
	sta	REG_CGDATA
	lda	scroll_pal
	bne	:++
;-------------------------------------------------------------------------;
	inc	cgdata_l
	lda	cgdata_l
	cmp	#0ffh
	bne	:+
;-------------------------------------------------------------------------;
	lda	#01h
	sta	scroll_pal
;-------------------------------------------------------------------------;
:	rts
;-------------------------------------------------------------------------;
:	dec	cgdata_l
	lda	cgdata_l
	cmp	#0e0h
	bne	:+
;-------------------------------------------------------------------------;
	stz	scroll_pal
;-------------------------------------------------------------------------;
:	rts	


;=========================================================================;
CreditSprites:
;=========================================================================;
	lda	sprite_ypos
	xba
	ldy	#00h
	tyx
:	lda	SPRITE_X,y
	sta	oam_table,x
	inx

	phx

	xba
	tax
	lda	SPRITE_Y,x
	xba
	txa
	sec
	sbc	#04h
	xba

	plx

	sta	oam_table,x
	inx

	lda	SPRITE_TILE,y
	sta	oam_table,x
	inx

	lda	#%100000
	sta	oam_table,x
	inx

	iny	
	cpy	#SPRITE_TILE_END-SPRITE_TILE
	bne	:-
;-------------------------------------------------------------------------;
	inc	sprite_ypos
	lda	sprite_ypos
	cmp	#38h
	bne	:+
;-------------------------------------------------------------------------;
	lda	#18h
	sta	sprite_ypos
;-------------------------------------------------------------------------;
:	rts

;=========================================================================;
LogoPalette:
;=========================================================================;
	dec	palette_timer1
	beq	:+
	rts
;-------------------------------------------------------------------------;
:	dec	palette_timer2
	beq	:+
;-------------------------------------------------------------------------;
	rts
;-------------------------------------------------------------------------;
:	lda	#02h
	sta	palette_timer1
	lda	#01h
	sta	palette_timer2
	lda	#11h
	sta	REG_CGADD
	ldx	palette_index
	ldy	#07h
;-------------------------------------------------------------------------;
:	lda	PALETTE,x
	sta	REG_CGDATA
	inx
	lda	PALETTE,x
	sta	REG_CGDATA
	inx
	dey
	bne	:-
;-------------------------------------------------------------------------;
	inc	palette_index
	inc	palette_index
	lda	palette_index
	cmp	#0eh
	beq	:+
	cmp	#36h
	bne	:++
;-------------------------------------------------------------------------;
:	lda	#04h
	sta	palette_timer2
	rts
;-------------------------------------------------------------------------;
:	cmp	#50h
	bne	:+
;-------------------------------------------------------------------------;
	stz	palette_index
;-------------------------------------------------------------------------;
:	rts

;=========================================================================;
MoveLogo:
;=========================================================================;
	ldx	bg2_hsine
	lda	SINE,x
	sta	REG_BG2HOFS
	stz	REG_BG2HOFS
	inc	bg2_hsine
	lda	bg2_hsine
	cmp	#60h
	bne	:+
;-------------------------------------------------------------------------;
	stz	bg2_hsine
:	ldx	bg2_vsine
	lda	SINE+60h,x
	sta	REG_BG2VOFS
	stz	REG_BG2VOFS
	inc	bg2_vsine
	lda	bg2_vsine
	cmp	#80h
	bne	:+
;-------------------------------------------------------------------------;
	stz	bg2_vsine
:	rts
;=========================================================================;
ResetBG1VOFS:
;=========================================================================;
	stz	bg1_vofs
	rts	

;=========================================================================;
MoveScrollV:
;=========================================================================;
	ldx	bg1_vofs
	lda	SCREEN_SINE,x
	sta	REG_BG1VOFS
	stz	REG_BG1VOFS
	inc	bg1_vofs
	rts

;=========================================================================;
ResetBG1HOFS:
;=========================================================================;
	stz	scroll_textpos
	stz	REG_W12SEL
	stz	bg1_hofs
	stz	REG_BG1HOFS
	stz	REG_BG1HOFS
	rts

;=========================================================================;
ScrollText:
;=========================================================================;
	inc	bg1_hofs
	inc	bg1_hofs
	lda	bg1_hofs
	cmp	#08h
	bne	set_bg1_hofs
;-------------------------------------------------------------------------;
	stz	bg1_hofs

	rep	#30h

	inc	scroll_textpos

	sep	#20h

	ldx	scroll_textpos
	ldy	#0000
;-------------------------------------------------------------------------;
:	tya
	clc
	adc	#0a0h
	sta	REG_VMADDL
	lda	#(BG1MAP>>8)+01h
	sta	REG_VMADDH

	jsr	GetTopTile

	tya
	clc
	adc	#0c0h
	sta	REG_VMADDL
	lda	#(BG1MAP>>8)+01h
	sta	REG_VMADDH

	jsr	GetBottomTile
	inx
	iny
	cpy	#0020h
	bne	:-
;-------------------------------------------------------------------------;
	lda	#0a0h
	sta	REG_VMADDL
	lda	#0c6h
	sta	REG_VMADDH

	jsr	GetTopTile

	lda	#0c0h
	sta	REG_VMADDL
	lda	#0c6h
	sta	REG_VMADDH

	jsr	GetBottomTile
;-------------------------------------------------------------------------;
set_bg1_hofs:
;-------------------------------------------------------------------------;
	lda	bg1_hofs
	sta	REG_BG1HOFS
	stz	REG_BG1HOFS
	sep	#10h
	rts

;=========================================================================;
ReadNMI:
;=========================================================================;
	lda	REG_RDNMI
	and	#80h
	cmp	#80h
	bne	ReadNMI
;-------------------------------------------------------------------------;
	lda	REG_RDNMI
	rts	

;=========================================================================;
Setup:
;=========================================================================;
	lda	#BGMODE_1
	sta	REG_BGMODE
	lda	#(BG1MAP>>8)
	sta	REG_BG1SC
	lda	#(BG2MAP>>9)
	sta	REG_BG2SC
	lda	#(BG2GFX>>9)
	sta	REG_BG12NBA
	lda	#0ffh
	sta	REG_BG1HOFS
	stz	REG_BG1HOFS
	sta	REG_BG1VOFS
	stz	REG_BG1VOFS
	sta	REG_BG2HOFS
	stz	REG_BG2HOFS
	sta	REG_BG2VOFS
	stz	REG_BG2VOFS
	stz	bg2_vsine
	stz	bg2_hsine
	lda	#18h
	sta	sprite_ypos
	lda	#0e0h
	sta	cgdata_l
	stz	scroll_pal
	lda	#02h
	sta	REG_CGSWSEL
	lda	#63h
	sta	REG_CGADSUB
	lda	#0e0h
	sta	REG_COLDATA
	lda	#TM_OBJ|TM_BG1
	sta	REG_TM
	lda	#TM_BG2
	sta	REG_TS
	stz	palette_timer1
	lda	#0eh
	sta	palette_index
	lda	#04h
	sta	palette_timer2

	lda	#OBSEL_8_32|OBSEL_BASE(OAMGFX)|OBSEL_NN_8K
	sta	REG_OBSEL
	lda	#81h
	sta	REG_CGADD
	lda	#94h
	sta	REG_CGDATA
	lda	#52h
	sta	REG_CGDATA

	rts	


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
PALETTE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$06,$08,$0a,$08
	.byte	$4e,$18,$92,$18,$d6,$18,$5a,$21
	.byte	$1e,$2a,$5a,$21,$d6,$18,$92,$18
	.byte	$4e,$18,$0a,$08,$06,$08,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$40,$18,$40,$28
	.byte	$82,$38,$84,$48,$86,$58,$0a,$69
	.byte	$50,$79,$0a,$69,$86,$58,$84,$48
	.byte	$82,$38,$40,$28,$40,$18,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$0a
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SCREEN_SINE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$40,$40,$40,$40,$40,$40,$41,$41
	.byte	$42,$43,$43,$44,$45,$46,$46,$47
	.byte	$48,$49,$4a,$4b,$4c,$4e,$4f,$50
	.byte	$51,$52,$53,$54,$55,$56,$57,$57
	.byte	$58,$59,$59,$5a,$5a,$5b,$5b,$5b
	.byte	$5b,$5b,$5b,$5b,$5b,$5b,$5a,$59
	.byte	$59,$58,$57,$56,$55,$53,$52,$51
	.byte	$4f,$4d,$4c,$4a,$48,$46,$44,$42
	.byte	$40,$3d,$3b,$39,$36,$34,$31,$2f
	.byte	$2d,$2a,$28,$25,$23,$21,$1e,$1c
	.byte	$1a,$18,$16,$14,$12,$10,$0e,$0d
	.byte	$0b,$0a,$09,$08,$07,$06,$05,$05
	.byte	$04,$04,$04,$04,$04,$05,$05,$06
	.byte	$07,$08,$09,$0a,$0c,$0d,$0f,$11
	.byte	$13,$15,$17,$1a,$1c,$1f,$22,$24
	.byte	$27,$2a,$2d,$30,$33,$36,$39,$3c
	.byte	$3f,$43,$46,$49,$4c,$4f,$52,$55
	.byte	$58,$5b,$5d,$60,$63,$65,$67,$6a
	.byte	$6c,$6e,$70,$71,$73,$74,$76,$77
	.byte	$78,$79,$7a,$7a,$7a,$7b,$7b,$7b
	.byte	$7a,$7a,$7a,$79,$78,$77,$76,$75
	.byte	$73,$72,$70,$6f,$6d,$6b,$69,$67
	.byte	$65,$63,$60,$5e,$5c,$5a,$57,$55
	.byte	$52,$50,$4d,$4b,$49,$46,$44,$42
	.byte	$40,$3d,$3b,$39,$37,$35,$33,$32
	.byte	$30,$2f,$2d,$2c,$2b,$29,$28,$28
	.byte	$27,$26,$25,$25,$25,$24,$24,$24
	.byte	$24,$24,$25,$25,$25,$26,$26,$27
	.byte	$28,$28,$29,$2a,$2b,$2c,$2d,$2e
	.byte	$2f,$30,$31,$32,$33,$34,$35,$36
	.byte	$37,$38,$39,$3a,$3b,$3b,$3c,$3d
	.byte	$3d,$3e,$3e,$3f,$3f,$3f,$3f,$40
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SCROLLTEXT:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	"                "
	.byte	"                "
	.byte	"   ......YES, YE"
	.byte	"S!!! THE CRAZY S"
	.byte	"WEDES WHO ONCE R"
	.byte	"OAMED OVER THE W"
	.byte	"ONDERLAND OF THE"
	.byte	" LEGENDARY C64, "
	.byte	"NOW MAKES A COME"
	.byte	"BACK INTO THE WO"
	.byte	"RLD OF CYBER BY "
	.byte	"JOINING THE SCEN"
	.byte	"E OF THE GLORIOU"
	.byte	"S CONSOLES....  "
	.byte	"                "
	.byte	"     WELL, FAST "
	.byte	"CREDITS FOR THIS"
	.byte	" INTRO BEFORE TH"
	.byte	"E REAL TEXT MASS"
	.byte	"ACRE STARTS:  EV"
	.byte	"ERYTHING (CODE &"
	.byte	" GRAPHICS (EXCEP"
	.byte	"T THE SROLLFONT)"
	.byte	") WAS MADE BY ME"
	.byte	", # G E G G I N "
	.byte	"#.....          "
	.byte	"            NEWS"
	.byte	"FLASH! NEWSFLASH"
	.byte	"! LOOK OUT FOR O"
	.byte	"UR -SEGA MEGADRI"
	.byte	"VE- INTRO WHICH "
	.byte	"IS ABOUT TO BE R"
	.byte	"ELEASED SOMEDAY "
	.byte	"THIS WEEK....   "
	.byte	"                "
	.byte	"      WE ARE SO "
	.byte	"FRESH IN THIS BU"
	.byte	"SINESS THAT WE H"
	.byte	"AVEN'T GOT AN OW"
	.byte	"N CONSOLE BOARD "
	.byte	"YET, SO IF YOU W"
	.byte	"ANNA GET IN TOUC"
	.byte	"H WITH ME YOU CA"
	.byte	"N ALWAYS CATCH M"
	.byte	"E ON ONE OF THE "
	.byte	"BOARDS I'M ON..."
	.byte	" THE ONES I CALL"
	.byte	" MOST OFTEN IS: "
	.byte	"    HIGH SOCIETY"
	.byte	"'S #TOMORROW LAN"
	.byte	"D# (510-786-3188"
	.byte	")              Q"
	.byte	"UARTEX'S #STREET"
	.byte	"S OF FIRE# (+46/"
	.byte	"855010498)      "
	.byte	"        REBEL'S "
	.byte	"#INNER CIRCLE# ("
	.byte	"+46/31314142)..."
	.byte	".....           "
	.byte	"         ANYWAY,"
	.byte	" HOW DO YOU LIKE"
	.byte	" MY INTRO?? I HO"
	.byte	"PE YOU'LL SEE IT"
	.byte	" INFRONT OF LOAD"
	.byte	"ZA GAMES IN THE "
	.byte	"FUTURE...       "
	.byte	"              A "
	.byte	"FEW #PARTY ON DU"
	.byte	"DE!# MUST GO TO."
	.byte	"..:    SAURON/MI"
	.byte	"RACLE (SO, JOHAN"
	.byte	"... I DIDN'T GOT"
	.byte	" MY INTRO RELEAS"
	.byte	"ED UNTIL ABOUT 1"
	.byte	" WEEK AFTER YOU."
	.byte	". DAMN! I GOTTA "
	.byte	"WORK FASTER NEXT"
	.byte	" TIME!!),   CONQ"
	.byte	"UEROR (HOWDY, PE"
	.byte	"TER.. HOW'S YOUR"
	.byte	" MILITARY SERVIC"
	.byte	"E GOIN'?),   TED"
	.byte	" (ISN'T IT WONDE"
	.byte	"RFUL TO BE CODIN"
	.byte	"G LIKE AN ELK FO"
	.byte	"R HOURS, AND EVE"
	.byte	"RYTHING THAT HAP"
	.byte	"PENS WHEN YOU RU"
	.byte	"N THE PROGRAM IS"
	.byte	" THAT THE SCREEN"
	.byte	" GOES TOTALLY BL"
	.byte	"ACK!!??, HAHA!),"
	.byte	"   SPIKE (YES DA"
	.byte	"NIEL, SOMEDAY WE"
	.byte	" WILL GO OUT AND"
	.byte	" HAVE A COUPLE O"
	.byte	"F BEERS!!(?)),  "
	.byte	" SWEN RAW (KEEP "
	.byte	"ON WORKING WITH "
	.byte	"#YOU KNOW WHAT#)"
	.byte	",   MATRIX + THE"
	.byte	" OTHER Z45 DUDES"
	.byte	" AND BEZERK + TH"
	.byte	"E REST OF #RIZIN"
	.byte	"G# (I HEARD THAT"
	.byte	" YOU ARE PLANNIN"
	.byte	"G ON GOING CONSO"
	.byte	"LE...?),   WICO "
	.byte	"(GET READY FOR A"
	.byte	" NEW LEECH ATTAC"
	.byte	"K, MIKAEL!!)...."
	.byte	"....  AND OFCOUR"
	.byte	"SE TO THE REST O"
	.byte	"F MY MORBID PART"
	.byte	"NERS IN CENSOR!!"
	.byte	" (HEY, PSYCHO..."
	.byte	" HOW'S YOUR SEGA"
	.byte	" INTRO GOING?? C"
	.byte	"AN'T WAIT TO SEE"
	.byte	" IT!!).....     "
	.byte	"            WELL"
	.byte	", SINCE THERE'S "
	.byte	"NO GAME COMING A"
	.byte	"FTER THIS INTRO,"
	.byte	" AND I HAVE TOTA"
	.byte	"LLY NOTHING TO D"
	.byte	"O, I MIGHT ASWEL"
	.byte	"L TELL YOU SOMET"
	.byte	"HING ABOUT CENSO"
	.byte	"R AND MYSELF... "
	.byte	"         WELL, C"
	.byte	"ENSOR WAS FORMED"
	.byte	" ON THE C64, WHE"
	.byte	"N A GANG OF OLD "
	.byte	"TRIAD MEMBERS LE"
	.byte	"FT TRIAD BECAUSE"
	.byte	" OF A DUDE CALLE"
	.byte	"D #JERRY# (THE T"
	.byte	"RIAD #LEADER#).."
	.byte	".     THEY FORME"
	.byte	"D CENSOR, AND ST"
	.byte	"ARTED TO CLIMB T"
	.byte	"HE CHARTS IN CRA"
	.byte	"CKING, ASWELL AS"
	.byte	" IN DEMOCODING.."
	.byte	"...   AT THIS TI"
	.byte	"ME I WAS NOT A M"
	.byte	"EMBER OF CENSOR,"
	.byte	" BUT WHEN I MET "
	.byte	"THEM AT A PARTY "
	.byte	"AND WE ALL GOT H"
	.byte	"EAVILY BOOZED, T"
	.byte	"HEY ASKED ME IF "
	.byte	"I WANTED TO JOIN"
	.byte	"....   THE ONLY "
	.byte	"REASON (AT THAT "
	.byte	"TIME) THAT THEY "
	.byte	"WANTED ME TO GET"
	.byte	" INTO THE GROUP,"
	.byte	" WAS THAT THEY C"
	.byte	"ONSIDERED ME TO "
	.byte	"BE A #PARTY-AMIN"
	.byte	"AL#, AN IT HAD N"
	.byte	"OTHING TO DO WIT"
	.byte	"H MY COMPUTER SK"
	.byte	"ILLS IN ANY WAY!"
	.byte	"!             WE"
	.byte	"LL, THAT PARTY E"
	.byte	"NDED UP WITH THA"
	.byte	"T CENSOR GOT THR"
	.byte	"OWN OUT FOR SEVE"
	.byte	"RAL REASONS, ALL"
	.byte	" INCLUDING BOOZE"
	.byte	"!, SO I DIDN'T J"
	.byte	"OIN AT THAT TIME"
	.byte	", CAUSE I LIVED "
	.byte	"ABOUT 500 KM FRO"
	.byte	"M THE PARTYPLACE"
	.byte	", AND I WANTED T"
	.byte	"O STAY...       "
	.byte	"      NEXT TIME "
	.byte	"I MET THEM WAS A"
	.byte	"T A PARTY IN DEN"
	.byte	"MARK, AND THIS T"
	.byte	"IME IT WAS ALSO "
	.byte	"UNDER DRUNKEN CO"
	.byte	"NDITIONS.....  T"
	.byte	"HIS TIME I JOINE"
	.byte	"D, AND SINCE THE"
	.byte	"N I HAVE BEEN IN"
	.byte	" THE GROUP...  T"
	.byte	"HAT HAPPENED IN "
	.byte	"THE BEGINNING OF"
	.byte	" 1990....     ON"
	.byte	"E THING ABOUT CE"
	.byte	"NSOR IS THAT ALL"
	.byte	" THE MEMBERS LIV"
	.byte	"E IN SWEDEN, AND"
	.byte	" EVERYONE KNOWS "
	.byte	"EACHOTHER QUITE "
	.byte	"WELL....   WE HA"
	.byte	"VE OFTEN INTERNA"
	.byte	"L PARTYS AND OFT"
	.byte	"EN DO THINGS TOG"
	.byte	"ETHER THAT DOES "
	.byte	"NOT INCLUDE COMP"
	.byte	"UTERS..... (NOTE"
	.byte	": THAT DOES NOT "
	.byte	"MEAN ANY KIND OF"
	.byte	" FAG ACTIVITIES,"
	.byte	" IF THAT'S WHAT "
	.byte	"YOU THOUGH!!)   "
	.byte	"   THE AMIGA DUD"
	.byte	"ES (ATLEAST THE "
	.byte	"SCANDINAVIAN ONE"
	.byte	"S) THAT HAVE HEA"
	.byte	"RD THE NAME #CEN"
	.byte	"SOR# BEFORE, HAV"
	.byte	"E PROBABLY HEARD"
	.byte	" OF US BEAUSE WE"
	.byte	" HAVE GOT BANNED"
	.byte	" FROM SOME COPYP"
	.byte	"ARTYS (ALSO AMIG"
	.byte	"A PARTYS) BECAUS"
	.byte	"E THEY ARE AFRAI"
	.byte	"D THAT WE WILL M"
	.byte	"AKE TOO MUCH TRO"
	.byte	"UBLE..... (I WIL"
	.byte	"L NOT COMMENT TH"
	.byte	"AT FURTHER...)  "
	.byte	"                "
	.byte	"  PHEW.... WHAT "
	.byte	"TO WRITE NOW??  "
	.byte	"       HMM, A LI"
	.byte	"TTLE #GREET# LIS"
	.byte	"T OF PEOPLE/THIN"
	.byte	"GS THAT MAKES LI"
	.byte	"FE WORTH LIVING."
	.byte	"......:        G"
	.byte	"EORGE A. ROMERO "
	.byte	"- CAMEL & MARLBO"
	.byte	"RO - BEER (SPEIA"
	.byte	"LLY #FOSTERS# AN"
	.byte	"D #TUBORG#) - CI"
	.byte	"NDY CRAWFORD - D"
	.byte	"ARIO ARGENTO - C"
	.byte	"OCA COLA - SATAN"
	.byte	" - MINISTRY (THE"
	.byte	" GROUP, NOT THE "
	.byte	"SYSOP) - PENTHOU"
	.byte	"SE - FERRARI'S -"
	.byte	" CLIVE BARKER - "
	.byte	"JUICY CUNTS - LA"
	.byte	"URA PALMERS FUCK"
	.byte	"IN' KILLER!! - W"
	.byte	"ILLIAM GIBSON - "
	.byte	"THE GORGEOUS LOO"
	.byte	"KIN' #KELLY BUND"
	.byte	"Y# IN #MARRIED W"
	.byte	"ITH CHILDREN# - "
	.byte	"AT & T - FAITH N"
	.byte	"O MORE - TRACY L"
	.byte	"ORDS - COFFEE - "
	.byte	"RED HOT CHILLI P"
	.byte	"EPPERS - PIZZA -"
	.byte	" COMPUTERS (?) -"
	.byte	" ALIENS (HA, FIN"
	.byte	"ALLY YOU MANAGED"
	.byte	" TO KILL THAT FU"
	.byte	"CKIN #RIPLEY#.. "
	.byte	"GREAT WORK!!!) -"
	.byte	" BIG TITS (NOT T"
	.byte	"O FORGET) - DENM"
	.byte	"ARK PARTYS! (CAN"
	.byte	"'T THERE BE ANOT"
	.byte	"HER ONE SOON!!) "
	.byte	"- STEPHEN KING -"
	.byte	" PEARL JAM - AID"
	.byte	"S (MAKES FUCKING"
	.byte	" MORE EXCITING!!"
	.byte	") - EDGAR ALLAN "
	.byte	"POE - ..... + LO"
	.byte	"ADZA , LOADZA MO"
	.byte	"RE STUFF.....   "
	.byte	"         BY THE "
	.byte	"WAY, AS YOU AMER"
	.byte	"ICANOS MIGHT KNO"
	.byte	"W OR NOT, EUROPE"
	.byte	" IS QUITE SLOW I"
	.byte	"N GETTING THOSE "
	.byte	"NEW MOVIES FROM "
	.byte	"THE US, AND SINC"
	.byte	"E I STOPPED VIDE"
	.byte	"O SWAPPING A LON"
	.byte	"G TIME AGO, I WO"
	.byte	"NDERED IF ONE OF"
	.byte	" YOU OVER THERE "
	.byte	"WOULD LIKE TO DO"
	.byte	" ME A FAVOR..?? "
	.byte	"I AM AFTER TWO M"
	.byte	"OVIES, AND I WAN"
	.byte	"T THEM IN SUPERB"
	.byte	" QUALITY (I WOUL"
	.byte	"D PREFER DIRECTL"
	.byte	"Y COPIED FROM LA"
	.byte	"SER DISC), I WOU"
	.byte	"LD ALSO LIKE TO "
	.byte	"HAVE THEM IN #PA"
	.byte	"L# IF THAT CAN B"
	.byte	"E ARRANGED, OTHE"
	.byte	"RWISE I CAN MANA"
	.byte	"GE WITH A #NTSC#"
	.byte	" COPY... WELL TH"
	.byte	"E MOVIES ARE:   "
	.byte	"   HELLRAISER II"
	.byte	"I (HELL ON EARTH"
	.byte	")      &      EV"
	.byte	"IL DEAD III (ARM"
	.byte	"Y OF DARKNESS)  "
	.byte	"    .......IF YO"
	.byte	"U WANNA HELP ME "
	.byte	"OUT, CONTACT ME "
	.byte	"ON ONE OF THE BO"
	.byte	"ARDS MENTIONED E"
	.byte	"ARLIER......    "
	.byte	"      LALALAA! D"
	.byte	"IDIDUMDIDUM!! .."
	.byte	"..  WELL, IT SEE"
	.byte	"MS LIKE MY INSPI"
	.byte	"RATION IS TOTALL"
	.byte	"Y GONE, SO I BET"
	.byte	"TER STOP IT RIGH"
	.byte	"T AWAY....      "
	.byte	"   GEGGIN IS GON"
	.byte	"E...LIVING THE N"
	.byte	"IGHT OF THE DEAD"
	.byte	"...!!!!!!       "
	.byte	"                "
	.byte	"            ",0



;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SINE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$e6,$e4,$e2,$e1,$df,$de,$dd,$dc
	.byte	$da,$d9,$d8,$d7,$d6,$d5,$d4,$d3
	.byte	$d3,$d2,$d2,$d1,$d1,$d1,$d1,$d1
	.byte	$d1,$d1,$d1,$d1,$d2,$d2,$d3,$d3
	.byte	$d4,$d5,$d6,$d7,$d8,$d9,$da,$db
	.byte	$dd,$de,$df,$e1,$e2,$e4,$e5,$e6
	.byte	$e8,$e9,$eb,$ec,$ed,$ef,$f0,$f1
	.byte	$f3,$f4,$f5,$f6,$f7,$f8,$f9,$f9
	.byte	$fa,$fb,$fb,$fc,$fc,$fc,$fc,$fc
	.byte	$fc,$fc,$fc,$fc,$fb,$fb,$fa,$fa
	.byte	$f9,$f8,$f7,$f6,$f5,$f4,$f3,$f2
	.byte	$f0,$ef,$ee,$ec,$eb,$ea,$e8,$e7
	.byte	$d0,$d1,$d2,$d3,$d4,$d5,$d6,$d7
	.byte	$d8,$d9,$da,$db,$dc,$dd,$de,$df
	.byte	$e0,$e1,$e1,$e2,$e3,$e4,$e5,$e6
	.byte	$e6,$e7,$e8,$e9,$ea,$ea,$eb,$ec
	.byte	$ec,$ed,$ee,$ee,$ef,$f0,$f0,$f1
	.byte	$f1,$f2,$f2,$f3,$f3,$f4,$f4,$f4
	.byte	$f5,$f5,$f5,$f6,$f6,$f6,$f7,$f7
	.byte	$f7,$f7,$f7,$f7,$f7,$f7,$f7,$f7
	.byte	$f7,$f7,$f7,$f7,$f7,$f7,$f7,$f7
	.byte	$f7,$f6,$f6,$f6,$f6,$f5,$f5,$f5
	.byte	$f4,$f4,$f3,$f3,$f2,$f2,$f1,$f1
	.byte	$f0,$f0,$ef,$ef,$ee,$ed,$ed,$ec
	.byte	$eb,$ea,$ea,$e9,$e8,$e7,$e7,$e6
	.byte	$e5,$e4,$e3,$e3,$e2,$e1,$e0,$df
	.byte	$de,$dd,$dc,$db,$da,$d9,$d8,$d8
	.byte	$d7,$d6,$d5,$d4,$d3,$d2,$d1,$d0
	.byte	$c2,$0a
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SPRITE_X:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$cb,$d2,$d9,$e0,$e6,$ec
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SPRITE_Y:
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
SPRITE_TILE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	$6e,$6f,$6e,$6e,$7e,$7f
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SPRITE_TILE_END:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


