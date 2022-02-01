;-------------------------------------------------------------------------;
; snes init code
; by neviksti/mukunda
;-------------------------------------------------------------------------;
.IMPORT __HDATA_LOAD__
.IMPORT __HDATA_RUN__
.IMPORT __HDATA_SIZE__
;-------------------------------------------------------------------------;
.include "snes.inc"
.include "snes_init.inc"
;-------------------------------------------------------------------------;
.import main
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
.code
;/////////////////////////////////////////////////////////////////////////;


	.a8
	.i16


;=========================================================================;
_start:
;=========================================================================;
	sei				; disable interrupts
	clc				; switch to native mode
	xce				; 
					;
	rep	#38h			; mem/A/X/Y = 16bit
					; decimal mode off
	ldx	#1FFFh			; setup stack pointer
	txs				;
	lda	#0000h			; direct page = 0000h
	tcd				;
					;
	sep	#20h			; 8bit A/mem
					;
	lda	#80h			; data bank = 80h
	pha				;
	plb				;

.ifdef BANK_ZERO			;

		; add -D BANK_ZERO to the ASFLAGS in the Makefile only if you
		; define HROM, CROM, CHEAD without a bank (16-bit address)

		lda	$FFD5			; get map mode
		lsr				; 21/31 jump to bank C0
		bcs	:+			; 20/30 jump to bank 80
		jml	$800000+_histart	; (for switchable speed)
	:	jml	$C00000+_histart	;

.else

		jml	_histart

.endif


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
WRAM_FILL_BYTE: .byte   $0
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


.ifdef HIROM

	;/////////////////////////////////////////////////////////////////;
		.segment "XCODE"
	;/////////////////////////////////////////////////////////////////;

.endif


;=========================================================================;
_histart:
;=========================================================================;
	jsr	InitReg

	lda	#0
	ldx	#0000h
	txy
	sec
	jsr	ClearRAMSkipCLC		; clear lower 64k
;-------------------------------------------------------------------------;
_return:
;-------------------------------------------------------------------------;
	nop				; this instruction never happens
	nop				; ClearRAMSkipCLC will return here
	nop				; thanks to PEA _return
	sta	REG_MDMAEN		; transfer again (higher 64k)

	jsr	InitOAM

;-------------------------------------------------------------------------;
; load DATA segment
;---------------------------------------;---------------------------------;
	ldx	#__HDATA_SIZE__		; skip if data segment is empty
	beq	_empty_data_segment	;
;---------------------------------------;
	stx	REG_DAS0L		;
					;
	lda	#^__HDATA_RUN__&1	; copy to __HDATA_RUN__
	sta	REG_WMADDH		;
	ldx	#.LOWORD(__HDATA_RUN__)	;
	stx	REG_WMADDL		;
					;
	lda	#^__HDATA_LOAD__	;
	ldx	#.LOWORD(__HDATA_LOAD__); copy from __HDATA_LOAD__
	ldy	#<REG_WMDATA<<8		; dma increment source, copy to 2180
	jsr	SetMDMA			;
;---------------------------------------;---------------------------------;
_empty_data_segment:
;-------------------------------------------------------------------------;
	jmp	main


;*************************************************************************;
;* A = source bank
;* X = source address
;* Y = DMA Destination, DMA Control
;*************************************************************************;
SetMDMA:
;*************************************************************************;
	sty	REG_DMAP0
	stx	REG_A1T0L
	sta	REG_A1B0

	lda	#01h
	sta	REG_MDMAEN
	rts

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
ClearVRAM:
clear_vram:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;

	lda	#80h		;
	sta	REG_INIDISP	; 80h == force blank
	sta	REG_VMAIN	; 80 == set vram port to word access

	lda	#00h		;
	ldx	#0000h		;
	stx	REG_VMADDL	; VRAM port address to $0000
	stx	0000h		; Set $00:0000 to $0000 (assumes scratchpad ram)
	stx	REG_DAS0L	; Set transfer size to 64k bytes
	ldy	#<REG_VMDATAL<<8|DMAP_FIXED|DMAP_XFER_MODE_1
	jsr	SetMDMA		; dma mode: fixed source, WORD to REG_VMDATAL/9

	stz	REG_VMDATAH	; clear the last byte of the VRAM

	rts

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
InitOAM:
init_oam:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;

	stz	REG_OAMADDL	; sprites initialized to be off the screen, 
	stz	REG_OAMADDH	; palette 0, character 0
	ldx	#0080h
	lda	#0f0h

:	sta	REG_OAMDATA	; X = 240
	sta	REG_OAMDATA	; Y = 240
	stz	REG_OAMDATA	; character = $00
	stz	REG_OAMDATA	; set priority=0, no flips
	dex
	bpl	:-

	ldx	#0020h
	lda	#%01010101
:	sta	REG_OAMDATA	; size bit=0, x MSB = 0
	dex
	bpl	:-

	rts


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
ClearWorkRAM7E:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	lda	#7eh
	ldx	#2000h
	ldy	#0dfffh
	bra	ClearRAM
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
ClearWorkRAM7F:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	lda	#7fh
	ldx	#0000h
	txy
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
ClearRAM:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	clc
;-------------------------------------------------------------------------;
ClearRAMSkipCLC:
;-------------------------------------------------------------------------;
	sty	REG_DAS0L			; transfer size
	stx	REG_WMADDL			; WRAM address
	sta	REG_WMADDH			;
						;
	ldx	#<REG_WMDATA<<8|DMAP_FIXED	; Set DMA mode to fixed source
	stx	REG_DMAP0 			; BYTE to REG_WMDATA
	ldx	#WRAM_FILL_BYTE			; source = WRAM_FILL_BYTE
	stx	REG_A1T0L       		;		 
	stz	REG_A1B0  			;
	lda	#01h				;
	sta	REG_MDMAEN			; start transfer (lower 64k)
	bcc	_skip_set_return		;
;-------------------------------------------------------------------------;
	pea	_return				; ClearWorkRAM clears the stack
;-------------------------------------------------------------------------;
_skip_set_return:
;-------------------------------------------------------------------------;
	rts


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
InitReg:
init_reg:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;

	jsr	MemSelect
	jsr	ClearVRAM

	ldx	#REG_OBSEL	; regs REG_OBSEL-REG_BG34NBA
:	stz	00h,x		; set Sprite,Character,Tile sizes to lowest, 
	inx			; and set addresses to $0000
	cpx	#REG_BG1HOFS	;
	bne	:-		;

:	stz	00h,x		; regs REG_BG1HOFS-REG_BG4VOFS
	stz	00h,x		; Set all BG scroll values to $0000
	inx			;
	cpx	#REG_VMAIN	;
	bne	:-		;

	lda	#80h		; Initialize VRAM transfer mode to word-access
	sta	REG_VMAIN	; increment by 1

	stz	REG_VMADDL	; VRAM address = $0000
	stz	REG_VMADDH	;

	stz	REG_M7SEL	; clear Mode7 setting

	ldx	#REG_M7A	; regs REG_M7A-REG_M7Y

:	stz	00h,x		; clear out the Mode7 matrix values
	stz	00h,x		;
	inx			;
	cpx	#REG_CGADD	;
	bne	:-		;

	ldx	#REG_W12SEL	; regs REG_W12SEL-REG_SETINI
:	stz	00h,x		; turn off windows, main screens, sub screens, color addition,
	inx			; fixed color = $00, no super-impose (external synchronization),
	cpx	#REG_MPYL	; no interlaced mode, normal resolution
	bne	:-		;

	stz	REG_STAT77	; might not be necesary, but selects PPU master/slave mode
	stz	REG_NMITIMEN	; disable timers, NMI,and auto-joyread
	lda	#0ffh
	sta	REG_WRIO	; programmable I/O write port, 
				; initalize to allow reading at in-port

	stz	REG_MDMAEN	; turn off all general DMA channels
	stz	REG_HDMAEN	; turn off all H-MA channels

	lda	REG_RDNMI	; NMI status, reading resets

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
ClearPalette:
clear_palette:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	stz	REG_CGADD
	ldx	#0100h
	
:	stz	REG_CGDATA
	stz	REG_CGDATA
	dex
	bne	:-
;-------------------------------------------------------------------------;
	rts


;=========================================================================;
MemSelect:
mem_select:
;=========================================================================;
	lda	0ffd5h			; if map_mode & 10h
	bit	#10h			; switch to hi-speed mode
	beq	:+			;
	lda	#1			;
	sta	REG_MEMSEL		;
:	rts

