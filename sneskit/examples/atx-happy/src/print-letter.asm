;-------------------------------------------------------------------------;
.include "print_letter.inc"
.include "snes.inc"
;-------------------------------------------------------------------------;


;=========================================================================;
;      Code (c) 1993-94 -Pan-/ANTHROX  All code can be used at will!
;=========================================================================;


;/////////////////////////////////////////////////////////////////////////;
        .zeropage
;/////////////////////////////////////////////////////////////////////////;


;-------------------------------------------------------------------------;
text_address:
	.res 3
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
	.bss
;/////////////////////////////////////////////////////////////////////////;


;-------------------------------------------------------------------------;
palette:
	.res 1
stop_flag:
	.res 1
text_index:
	.res 2
timer:
	.res 1
vram_address:
	.res 2
reg_vmaddl:
	.res 2
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
	.code
;/////////////////////////////////////////////////////////////////////////;


	.a8
	.i16


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
; a = text source bank		b = palette
; x = text source address	y = vram address
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
SetupPrintLetter:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	rep     #10h		; X,Y fixed -> 16 bit mode
	sep     #20h		; Accumulator ->  8 bit mode

	sta	text_address+2
	stx	text_address

	xba
	sta	palette

	sty	reg_vmaddl
	sty	vram_address	; Vram address for text

	ldx	#0000h
	stx	text_index	; counter for text printer!
	stz	stop_flag	; flag to stop text writer (1=stop)

	rts


;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
;                        Backwards Text Clear Routine
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
ClearTextScreen:
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	lda	stop_flag	; this routine makes the cursor go backwards
	beq	exit		; to clear the screen
;-------------------------------;------------------------------------------;
	ldx	reg_vmaddl	; get the current cursor position (Vram addr)
	dex			;
	stx	REG_VMADDL	; put it as the current Vram address
	stz	REG_VMDATAL	; put character #0 (cursor) into VRAM
	lda	palette		; make the palette number..
	sta	REG_VMDATAH	;    
	lda	#PL_SPACE	; clear the original tile by making it a space
	sta	REG_VMDATAL	;
	lda	palette		; load the palette number
	sta	REG_VMDATAH	;
	ldx	reg_vmaddl	;
	cpx	vram_address	; did it reach the top of the screen?
	beq	TextWriteOn	;
;-------------------------------;
	dex			; decrease the current cursor position
	stx	reg_vmaddl	; and store it again
exit:	rts
;-------------------------------------------------------------------------;
TextWriteOn:
;-------------------------------------------------------------------------;
	stz	stop_flag	; set the textwriter flag on (0 = write text)
	ldx	vram_address	;	fix the Vram address
	stx	reg_vmaddl
	rts


;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
;                             Text Writer Routine
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
PrintLetter:
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	inc	timer
	lda	timer
	cmp	#05h
	bne	exit
;-------------------------------------------------------------------------;
	stz	timer
	lda	stop_flag	; is it ok to print the text?
	bne	exit
;-------------------------------------------------------------------------;
:	ldx	reg_vmaddl	; get current Vram text address
	stx	REG_VMADDL
	ldy	text_index	; get current text offset
	lda	[text_address],y
	cmp	#PL_CR		; was it a carriage return?
	bne	NoCarriageReturn; no? go to NO Carriage Return
;-------------------------------------------------------------------------;
	stx	REG_VMADDL	; yes!! store the Vram text address in 2116
	lda	#PL_SPACE	; remove that left over cursor!
	sta	REG_VMDATAL
	lda	palette
	sta	REG_VMDATAH

	rep	#30h

	lda	reg_vmaddl
	and	#0ffe0h		; make sure to only get start of line addresses
	clc
	adc	#0020h		; add 32 to get to next line
	sta	reg_vmaddl

	sep	#20h

	ldy	text_index
	iny			; increase text offset to get next char
	sty	text_index
	bra	:-		; go back and get re-do text draw
;-------------------------------------------------------------------------;
NoCarriageReturn:
;-------------------------------------------------------------------------;
	and	#3fh		; no carriage return!!  turn ASCII->C64
	sta	REG_VMDATAL	; screen code
	lda	palette
	sta	REG_VMDATAH	; palette #
	stz	REG_VMDATAL	; make a cursor
	lda	palette
	sta	REG_VMDATAH
	ldx	reg_vmaddl
	inx			; increase Vram address
	stx	reg_vmaddl
	ldy	text_index
	iny			; increase text offset
	sty	text_index
	lda	[text_address],y; is the next byte a stop flag?
	beq	StopText	; yes! 
	cmp	#PL_RESET_TEXT	; is the byte a reset text offset flag?
	beq	ResetText	; yes!
	rts
;-------------------------------------------------------------------------;
StopText:
;-------------------------------------------------------------------------;
	inc	stop_flag	; stop text, enable backwards clear
	ldx	text_index
	inx
	stx	text_index	; since the next byte will be a stop flag
				; we must skip it to get the next character
	rts
;-------------------------------------------------------------------------;
ResetText:
;-------------------------------------------------------------------------;
	inc	stop_flag	; stop text, enable backwards clear
	ldx	#0000h		; return text offset to start of TEXT
	stx	text_index
	rts
