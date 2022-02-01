;-------------------------------------------------------------------------;
.include "bg1_scrolltext.inc"
.include "oam.inc"
.include "snes.inc"
;-------------------------------------------------------------------------;


;*****************************************
;*  elitendo intro 3			*
;*  the date aug '93			*
;*  menu options			*
;*  filly part				*
;*  scroller 32*32 animation ;font	* 
;*  all code by radium ½.		*
;*****************************************


LINE1 = 24
LINE2 = LINE1+1
LINE3 = LINE2+1
LINE4 = LINE3+1


;/////////////////////////////////////////////////////////////////////////;
.zeropage
;/////////////////////////////////////////////////////////////////////////;


;-------------------------------------------------------------------------;
ascii_cmp:
	.res 2
scroll_bghofs:
	.res 2
text_index:
	.res 2
text_pointer:
	.res 3
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
	.code
;/////////////////////////////////////////////////////////////////////////;


	.a8
	.i16


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
SetupBG1Scrolltext:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	stx	text_pointer
	sta	text_pointer+2

	ldx	#0000h
	stx	ascii_cmp
	stx	scroll_bghofs
	stx	text_index

	rts


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
BG1Scrolltext:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	lda	scroll_bghofs
	cmp	#32
	bne	ScrollScreen
;-------------------------------------------------------------------------;
	stz	scroll_bghofs
	jsr	rol_chrs
	inc	text_index
	ldy	text_index
;-------------------------------------------------------------------------;
:	lda	[text_pointer],y		; load ascii code
	cmp	#0ffh
	bne	no_reset			; end of scroll line ?
;-------------------------------------------------------------------------;
	ldy	#0000h
	sty	text_index	
	bra	:-
;-------------------------------------------------------------------------;
no_reset:
;-------------------------------------------------------------------------;
	sta	ascii_cmp
	ldx	#0000h				; find chr in table
;-------------------------------------------------------------------------;
CharSearch:
;-------------------------------------------------------------------------;
	lda	SCROLL_TABLE_ASCII,x
	cmp	ascii_cmp
	beq	CharMatch
;-------------------------------------------------------------------------;
	inx
	bra	CharSearch
;-------------------------------------------------------------------------;
CharMatch:
;-------------------------------------------------------------------------;
	lda	#VMAIN_INCH
	sta	REG_VMAIN

	rep	#30h

	txa
	asl
	tax

	lda	SCROLL_TABLE_CHR,x		; get chr number
	ora	#0400h				; set palette 1
	ldx	#(BG1MAP/2)+32*LINE1+1024	; set vram 1 screen 1024
	jsr	VramTransfer

	ldx	#(BG1MAP/2)+32*LINE2+1024	; 896 set vram 1 screen 1024
	jsr	VramTransferADC29

	ldx	#(BG1MAP/2)+32*LINE3+1024	; 896 set vram 1 screen 1024
	jsr	VramTransferADC29

	ldx	#(BG1MAP/2)+32*LINE4+1024	; 896 set vram 1 screen 1024
	jsr	VramTransferADC29

	sep	#20h
;-------------------------------------------------------------------------;
ScrollScreen:
;-------------------------------------------------------------------------;
	lda	scroll_bghofs
	sta	REG_BG1HOFS	
	stz	REG_BG1HOFS
	clc
	adc	#04h
	sta	scroll_bghofs
	rts


	.a16
;-------------------------------------------------------------------------;
VramTransferADC29:
;-------------------------------------------------------------------------;
	adc	#29
;-------------------------------------------------------------------------;
VramTransfer:
;-------------------------------------------------------------------------;
	stx	REG_VMADDL
	sta	REG_VMDATAL
	inc
	sta	REG_VMDATAL
	inc
	sta	REG_VMDATAL
	inc
;-------------------------------------------------------------------------;
:	sta	REG_VMDATAL
	rts
;-------------------------------------------------------------------------;
VRAMTransferXY:					; x source y desti
;-------------------------------------------------------------------------;
	stx	REG_VMADD
	inx
	lda	REG_VMDATAREAD			; read vram
	sty	REG_VMADD
	iny
	bra	:-
;-------------------------------------------------------------------------;
rol_chrs:
;-------------------------------------------------------------------------;
	rep	#30h				; all 16b

	ldx	#(BG1MAP/2)+32*LINE1+4
	ldy	#(BG1MAP/2)+32*LINE1+0
rolline1:
	jsr	VRAMTransferXY
	cpy	#(BG1MAP/2)+32*LINE1+28	
	bne	rolline1

	ldx	#(BG1MAP/2)+32*LINE1+1024	; other screen
	ldy	#(BG1MAP/2)+32*LINE1+28	
copy_chr1:	
	jsr	VRAMTransferXY

	cpy	#(BG1MAP/2)+32*LINE1+32
	bne	copy_chr1

	ldx	#(BG1MAP/2)+32*LINE2+4
	ldy	#(BG1MAP/2)+32*LINE2+0
rolline2:
	jsr	VRAMTransferXY
	cpy	#(BG1MAP/2)+32*LINE2+28
	bne	rolline2

	ldx	#(BG1MAP/2)+32*LINE1+1024+32	; other screen
	ldy	#(BG1MAP/2)+32*LINE1+28+32	
copy_chr2:
	jsr	VRAMTransferXY
	cpy	#(BG1MAP/2)+32*LINE1+32+32
	bne	copy_chr2

	ldx	#(BG1MAP/2)+32*LINE3+4
	ldy	#(BG1MAP/2)+32*LINE3+0
rolline3:
	jsr	VRAMTransferXY
	cpy	#(BG1MAP/2)+32*LINE3+28	
	bne	rolline3

	ldx	#(BG1MAP/2)+32*LINE1+1024+32*2	; other screen
	ldy	#(BG1MAP/2)+32*LINE1+28+32*2	
copy_chr3:	
	jsr	VRAMTransferXY
	cpy	#(BG1MAP/2)+32*LINE1+32+32*2
	bne	copy_chr3

	ldx	#(BG1MAP/2)+32*LINE4+4
	ldy	#(BG1MAP/2)+32*LINE4+0
rolline4:
	jsr	VRAMTransferXY

	cpy	#(BG1MAP/2)+32*LINE4+28	
	bne	rolline4

	ldx	#(BG1MAP/2)+32*LINE1+1024+32*3	; other screen
	ldy	#(BG1MAP/2)+32*LINE1+28+32*3	
copy_chr4:	
	jsr	VRAMTransferXY
 	cpy	#(BG1MAP/2)+32*LINE1+32+32*3
	bne	copy_chr4

	sep	#20h

	rts
;---------------------------------------end scroll rout


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SCROLL_TABLE_ASCII:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte	' '
	.byte	'A','B','C','D','E','F','G','H'
	.byte	'I','J','K','L','M','N','O','P'
	.byte	'Q','R','S','T','U','V','W','X'
	.byte	'Y','Z','.',',','!','?','(',')'
	.byte	$ff ; $ff not found then fill with space
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SCROLL_TABLE_CHR:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.word	164*4
	.word	000*4,001*4,002*4,003*4,004*4,005*4,006*4,007*4
	.word	032*4,033*4,034*4,035*4,036*4,037*4,038*4,039*4
	.word	064*4,065*4,066*4,067*4,068*4,069*4,070*4,071*4
	.word	096*4,097*4,098*4,099*4,100*4,101*4,102*4,103*4
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
