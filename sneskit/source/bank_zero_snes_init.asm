;-------------------------------------------------------------------------;
; snes init code
; by neviksti/mukunda
;-------------------------------------------------------------------------;
.IMPORT __HDATA_LOAD__
.IMPORT __HDATA_RUN__
.IMPORT __HDATA_SIZE__
;-------------------------------------------------------------------------;
.include "snes.inc"
;-------------------------------------------------------------------------;
.import main
;-------------------------------------------------------------------------;
.global _start, clear_vram, init_oam, init_reg, clear_palette
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
	rep	#38h			; mem/A/X/Y = 16bit
					; decimal mode off
	ldx	#1FFFh			; setup stack pointer
	txs				;
	lda	#0000h			; direct page = 0000h
	tcd				;
	sep	#20h			; 8bit A/mem
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


.ifdef HIROM

;/////////////////////////////////////////////////////////////////////////;
	.segment "XCODE"
;/////////////////////////////////////////////////////////////////////////;

.endif


;=========================================================================;
_histart:
;=========================================================================;

	jsr	mem_select
	jsr	init_reg
	jsr	init_oam

;-------------------------------------------------------------------------;
; erase WRAM
;-------------------------------------------------------------------------;

	stz	REG_WMADDL	; WRAM address = 0
	stz	REG_WMADDM	;
	stz	REG_WMADDH	;

	ldx	#8008h		; Set DMA mode to fixed source, BYTE to REG_WMDATA
	stx	REG_DMAP0 	; source = WRAM_FILL_BYTE
	ldx	#WRAM_FILL_BYTE	; transfer size = full 64k
	stx	REG_A1T0L       ; 
	lda	#^WRAM_FILL_BYTE;
	sta	REG_A1B0  	;
	ldx	#0000h		;
	stx	REG_DAS0L	;
	lda	#01h		;
	sta	REG_MDMAEN	; start transfer (lower 64k)
	nop
	nop
	sta	REG_MDMAEN	; transfer again (higher 64k)
	
;-------------------------------------------------------------------------;
; load DATA segment
;---------------------------------------;---------------------------------;
					;
	lda	#^__HDATA_RUN__&1	; copy to __HDATA_RUN__
	sta	REG_WMADDH		;
	ldx	#.LOWORD(__HDATA_RUN__)	;
	stx	REG_WMADDL		;
					;
	ldx	#8000h			; dma increment source, copy to 2180
	stx	REG_DMAP0		;
	ldx	#.LOWORD(__HDATA_LOAD__); copy from __HDATA_LOAD__
	stx	REG_A1T0L		;
	lda	#^__HDATA_LOAD__	;
	sta	REG_A1B0		;
	ldx	#__HDATA_SIZE__		; skip if data segment is empty
	beq	_empty_data_segment	;
;---------------------------------------;---------------------------------;
	stx	REG_DAS0L		;
	lda	#01h			;
	sta	REG_MDMAEN		;
;---------------------------------------;---------------------------------;
_empty_data_segment:
;-------------------------------------------------------------------------;
	jmp	main


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
WRAM_FILL_BYTE:	.byte	$0
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
clear_vram:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;

	lda	#80h		;
	sta	REG_INIDISP	; 80h == force blank
	sta	REG_VMAIN	; 80 == set vram port to word access
	ldx	#1809h		; clear vram with dma
	stx	REG_DMAP0	; dma mode: fixed source, WORD to REG_VMDATAL/9
	ldx	#0000h		;
	stx	REG_VMADDL	; VRAM port address to $0000
	stx	0000h		; Set $00:0000 to $0000 (assumes scratchpad ram)
	stx	REG_A1T0L	; Set source address to $xx:0000
	stz	REG_A1B0	; Set source bank to $00
	stx	REG_DAS0L	; Set transfer size to 64k bytes
	lda	#01h
	sta	REG_MDMAEN	; Initiate transfer

	stz	REG_VMDATAH	; clear the last byte of the VRAM

	rts

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
init_oam:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;

	stz	REG_OAMADDL	; sprites initialized to be off the screen, 
	stz	REG_OAMADDH	; palette 0, character 0
	ldx	#0080h
	lda	#0F0h

:	sta	REG_OAMDATA	; X = 240
	sta	REG_OAMDATA	; Y = 240
	stz	REG_OAMDATA	; character = $00
	stz	REG_OAMDATA	; set priority=0, no flips
	dex
	bne	:-

	ldx	#0020h
	lda	#%01010101
:	sta	REG_OAMDATA	; size bit=0, x MSB = 0
	dex
	bne	:-

	rts

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
init_reg:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;

	jsr	mem_select
	jsr	clear_vram

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
mem_select:
;=========================================================================;
	lda	$FFD5			; if map_mode & 10h
	bit	#10h			; switch to hi-speed mode
	beq	:+			;
	lda	#1			;
	sta	REG_MEMSEL		;
:	rts

