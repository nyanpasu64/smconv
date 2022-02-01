;----------------------------------------------------------------------
.include "snes.inc"
;----------------------------------------------------------------------

;----------------------------------------------------------------------
.export spcBoot
.export spcSetBank
.export spcLoad
.export spcPlay
.export spcStop
.export spcReadStatus
.export spcReadPosition
.export spcGetCues

.export spcSetModuleVolume
.export spcFadeModuleVolume
.export spcReset

.export spcFlush, spcProcess

.export spcReset

.export spc_q
;----------------------------------------------------------------------
.import CART_HEADER, SNESMOD_SPC, SNESMOD_SPC_END
;----------------------------------------------------------------------

;----------------------------------------------------------------------
; soundbank defs
;----------------------------------------------------------------------

.ifdef HIROM
	SB_SAMPCOUNT	=0000h
	SB_MODCOUNT	=0002h
	SB_MODTABLE	=0004h
	SB_SRCTABLE	=0184h
.else
	SB_SAMPCOUNT	=8000h
	SB_MODCOUNT	=8002h
	SB_MODTABLE	=8004h
	SB_SRCTABLE	=8184h
.endif

;----------------------------------------------------------------------
; spc commands
;----------------------------------------------------------------------

CMD_LOAD	=00h
CMD_LOADE	=01h
CMD_POS		=02h
CMD_VOL		=02h
CMD_PLAY	=03h
CMD_STOP	=04h
CMD_MVOL	=05h
CMD_FADE	=06h
CMD_RES		=07h
CMD_FX		=08h
CMD_TEST	=09h
CMD_SSIZE	=0Ah
;CMD_STEREO	=0Ch

CMD_LOADWT	=01h
;----------------------------------------------------------------------
.ifdef PAL
	INIT_DATACOPY = 16
	PROCESS_TIME = 6
.else
	INIT_DATACOPY = 13
	PROCESS_TIME = 5	; process for 5 scanlines
.endif

; increment memory pointer by 2
.macro incptr
	.scope
		iny
		iny
	
		.ifndef HIROM
			bmi	_catch_overflow
			inc	spc_ptr+2
			ldy	#8000h
		.else
			bne	_catch_overflow
			inc	spc_ptr+2
		.endif

		_catch_overflow:
	.endscope
.endmacro

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
.zeropage
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;

spc_ptr:	.res 3
spc_v:		.res 1
spc_bank:	.res 1

spc1:		.res 2
spc2:		.res 2

spc_fread:	.res 1
spc_fwrite:	.res 1

; port record [for interruption]
spc_pr:		.res 4

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
.bss
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;

spc_fifo:	.res 256	; 128-byte command fifo
spc_sfx_next:	.res 1
spc_q:		.res 1

; the only issue with including files in this manner is that
; changes to the included file will not be detected. if
; snesmod_supernofx.asm or snesmod_standard.asm touch this
; file to update the timestamp...

.ifdef ABFM
	.include "snesmod_supernofx.asm"
.endif

.ifdef ABMES
	.include "snesmod_supernofx.asm"
.endif

.ifdef ABNOFX
	.include "snesmod_supernofx.asm"
.endif

.ifdef CELES
	.include "snesmod_supernofx.asm"
.endif

.ifdef FMROM
	.include "snesmod_supernofx.asm"
	.include "snesmod_fmtest.asm"
.endif

.ifdef PITCHMOD
	.include "snesmod_standard.asm"
.endif

.ifdef SNESMOD
	.include "snesmod_standard.asm"
.endif

.ifdef SUPERNOFX
	.include "snesmod_supernofx.asm"
.endif

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
.code
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;

.a8
.i16

;**********************************************************************
;* upload driver
;*
;* disable time consuming interrupts during this function
;**********************************************************************
spcBoot:			
;----------------------------------------------------------------------
:	ldx	REG_APUIO0	; wait for 'ready signal from SPC
	cpx	#0BBAAh		;
	bne	:-		;--------------------------------------
	stx	REG_APUIO1	; start transfer:
	ldx	#SPC_BOOT	; port1 = !0
	stx	REG_APUIO2	; port2,3 = transfer address
	lda	#0CCh		; port0 = 0CCh
	sta	REG_APUIO0	;--------------------------------------
:	cmp	REG_APUIO0	; wait for SPC
	bne	:-		;
;----------------------------------------------------------------------
; ready to transfer
;----------------------------------------------------------------------
	lda	f:SNESMOD_SPC	; read first byte
	xba			;
	lda	#0		;
	ldx	#1		;
	bra	sb_start	;
;----------------------------------------------------------------------
; transfer data
;----------------------------------------------------------------------
sb_send:
;----------------------------------------------------------------------
	xba			; swap DATA into A
	lda	f:SNESMOD_SPC, x; read next byte
	inx			; swap DATA into B
	xba			;--------------------------------------
:	cmp	REG_APUIO0	; wait for SPC
	bne	:-		;--------------------------------------
	ina			; increment counter (port0 data)
;----------------------------------------------------------------------
sb_start:
;----------------------------------------------------------------------
	rep	#20h		; write port0+port1 data
	sta	REG_APUIO0	;
	sep	#20h		;--------------------------------------
	cpx	#SNESMOD_SPC_END-SNESMOD_SPC	; loop until all bytes
	bcc	sb_send				; transferred
;----------------------------------------------------------------------
; all bytes transferred
;----------------------------------------------------------------------
:	cmp	REG_APUIO0	; wait for SPC
	bne	:-		;--------------------------------------
	ina			; add 2 or so...
	ina			;--------------------------------------
				; mask data so invalid 80h message wont get sent
	stz	REG_APUIO1	; port1=0
	ldx	#SPC_BOOT	; port2,3 = entry point
	stx	REG_APUIO2	;
	sta	REG_APUIO0	; write P0 data
				;--------------------------------------
:	cmp	REG_APUIO0	; final sync
	bne	:-		;--------------------------------------
	stz	REG_APUIO0
	
	stz	spc_v		; reset V
	stz	spc_q		; reset Q
	stz	spc_fwrite	; reset command fifo
	stz	spc_fread	;
	stz	spc_sfx_next	;
	
	stz	spc_pr+0
	stz	spc_pr+1
	stz	spc_pr+2
	stz	spc_pr+3
;----------------------------------------------------------------------
; driver installation successful
;----------------------------------------------------------------------
	rts			; return
;----------------------------------------------------------------------

;**********************************************************************
; set soundbank bank number (important...)
;
;**********************************************************************
spcSetBank:
	sta	spc_bank
	rts
	
;**********************************************************************
; upload module to spc
;
; x = module_id
; modifies, a,b,x,y
;
; this function takes a while to execute
;**********************************************************************
spcLoad:
;----------------------------------------------------------------------

	phx			; flush fifo!
	jsr	spcFlush	;
	plx			;
	
	phx
	ldy	#SB_MODTABLE
	sty	spc2
	jsr	get_address
	rep	#20h
	lda	[spc_ptr], y	; X = MODULE SIZE
	tax
	
	incptr
	
	lda	[spc_ptr], y	; read SOURCE LIST SIZE
	
	incptr
	
	sty	spc1		; pointer += listsize*2
	asl			;
	adc	spc1		;
.ifndef HIROM
	bmi	:+		;
	ora	#8000h		;
.else
	bcc	:+
.endif
	inc	spc_ptr+2	;
:	tay			;
	
	sep	#20h		;
	lda	spc_v		; wait for spc
	pha			;
:	cmp	REG_APUIO1	;
	bne	:-		;------------------------------
	lda	#CMD_LOAD	; send LOAD message
	sta	REG_APUIO0	;
	pla			;
	eor	#80h		;
	ora	#01h		;
	sta	spc_v		;
	sta	REG_APUIO1	;------------------------------
:	cmp	REG_APUIO1	; wait for spc
	bne	:-		;------------------------------
	jsr	do_transfer
	
	;------------------------------------------------------
	; transfer sources
	;------------------------------------------------------
	
	plx
	ldy	#SB_MODTABLE
	sty	spc2
	jsr	get_address
	incptr
	
	rep	#20h		; x = number of sources
	lda	[spc_ptr], y	;
	tax			;
	
	incptr
	
transfer_sources:
	
	lda	[spc_ptr], y	; read source index
	sta	spc1		;
	
	incptr
	
	phy			; push memory pointer
	sep	#20h		; and counter
	lda	spc_ptr+2	;
	pha			;
	phx			;
	
	jsr	transfer_source
	
	plx			; pull memory pointer
	pla			; and counter
	sta	spc_ptr+2	;
	ply			;
	
	dex
	bne	transfer_sources
@no_more_sources:

	stz	REG_APUIO0	; end transfers
	lda	spc_v		;
	eor	#80h		;
	sta	spc_v		;
	sta	REG_APUIO1	;-----------------
:	cmp	REG_APUIO1	; wait for spc
	bne	:-		;-----------------
	sta	spc_pr+1
	stz	spc_sfx_next	; reset sfx counter
	
	
	rts
	
;--------------------------------------------------------------
; spc1 = source index
;--------------------------------------------------------------
transfer_source:
;--------------------------------------------------------------
	
	ldx	spc1
	ldy	#SB_SRCTABLE
	sty	spc2
	jsr	get_address
	
	lda	#01h		; port0=01h
	sta	REG_APUIO0	;
	rep	#20h		; x = length (bytes->words)
	lda	[spc_ptr], y	;
	incptr			;
	ina			;
	lsr			;
	tax			;
	lda	[spc_ptr], y	; port2,3 = loop point
	sta	REG_APUIO2
	incptr
	sep	#20h
	
	lda	spc_v		; send message
	eor	#80h		;	
	ora	#01h		;
	sta	spc_v		;
	sta	REG_APUIO1	;-----------------------
:	cmp	REG_APUIO1	; wait for spc
	bne	:-		;-----------------------
	cpx	#0
	beq	end_transfer	; if datalen != 0
	bra	do_transfer	; transfer source data
	
;--------------------------------------------------------------
; spc_ptr+y: source address
; x = length of transfer (WORDS)
;--------------------------------------------------------------
transfer_again:
	eor	#80h		;
	sta	REG_APUIO1	;
	sta	spc_v		;
	incptr			;
:	cmp	REG_APUIO1	;
	bne	:-		;
;--------------------------------------------------------------
do_transfer:
;--------------------------------------------------------------

	rep	#20h		; transfer 1 word
	lda	[spc_ptr], y	;
	sta	REG_APUIO2	;
	sep	#20h		;
	lda	spc_v		;
	dex			;
	bne	transfer_again	;
	
	incptr

end_transfer:
	lda	#0		; final word was transferred
	sta	REG_APUIO1	; write p1=0 to terminate
	sta	spc_v		;
:	cmp	REG_APUIO1	;
	bne	:-		;
	sta	spc_pr+1
	rts

;--------------------------------------------------------------
; spc2 = table offset
; x = index
;
; returns: spc_ptr = 0,0,bank, Y = address
get_address:
;--------------------------------------------------------------

	lda	spc_bank	; spc_ptr = bank:SB_MODTABLE+module_id*3
	sta	spc_ptr+2	;
	rep	#20h		;
	stx	spc1		;
	txa			;
	asl			;
	adc	spc1		;
	adc	spc2		;
	sta	spc_ptr		;
	
	lda	[spc_ptr]	; read address
	pha			;
	sep	#20h		;
	ldy	#2		;
	lda	[spc_ptr],y	; read bank#
	
	clc			; spc_ptr = long address to module
	adc	spc_bank	;
	sta	spc_ptr+2	;
	ply			;
	stz	spc_ptr
	stz	spc_ptr+1
	rts			;

;**********************************************************************
; x = target volume
; y = speed
;**********************************************************************
spcFadeModuleVolume:
;**********************************************************************
	txa				;queue:
	sta	spc1+1			; id xx yy
	tya				;
	sta	spc1			;
	lda	#CMD_FADE
	bra	QueueMessage

;**********************************************************************
; x = starting position
;**********************************************************************
spcPlay:
;----------------------------------------------------------------------
	txa				; queue message: 
	sta	spc1+1			; id -- xx
	lda	#CMD_PLAY		;
	bra	QueueMessage		;

;**********************************************************************
spcReset:
;**********************************************************************
	lda	#CMD_RES
	bra	QueueMessage

;**********************************************************************
; x = volume
;**********************************************************************
spcSetModuleVolume:
;**********************************************************************
	txa				;queue:
	sta	spc1+1			; id -- vv
	lda	#CMD_MVOL		;
	bra	QueueMessage		;

;**********************************************************************
spcStop:
;**********************************************************************
	lda	#CMD_STOP
	bra	QueueMessage

;**********************************************************************
; a = id
; spc1 = params
;**********************************************************************
QueueMessage:
	sei				; disable IRQ in case user 
					; has spcProcess in irq handler
			
	sep	#10h			; queue data in fifo
	ldx	spc_fwrite		;
	sta	spc_fifo, x		;
	inx				;
	lda	spc1			;
	sta	spc_fifo, x		;
	inx				;
	lda	spc1+1			;
	sta	spc_fifo, x		;
	inx				;
	stx	spc_fwrite		;
	rep	#10h			;
	cli				;
	rts				;

;**********************************************************************
; flush fifo (force sync)
;**********************************************************************
spcFlush:
;----------------------------------------------------------------------
	lda	spc_fread		; call spcProcess until
	cmp	spc_fwrite		; fifo becomes empty
	beq	@exit			;
	jsr	spcProcessMessages	;
	bra	spcFlush		;
@exit:	rts				;

;**********************************************************************
; process spc messages for x time
;**********************************************************************
spcProcess:
;----------------------------------------------------------------------
.ifdef PITCHMOD
	lda	digi_active
	beq	:+
	jsr	spcProcessStream
:
.endif

.ifdef SNESMOD
	lda	digi_active
	beq	:+
	jsr	spcProcessStream
:		
.endif

spcProcessMessages:

	sep	#10h			; 8-bit index during this function
	lda	spc_fwrite		; exit if fifo is empty
	cmp	spc_fread		;
	beq	@exit			;------------------------------
	ldy	#PROCESS_TIME		; y = process time
;----------------------------------------------------------------------
@process_again:
;----------------------------------------------------------------------
	lda	spc_v			; test if spc is ready
	cmp	REG_APUIO1		;
	bne	@next			; no: decrement time
					;------------------------------
	ldx	spc_fread		; copy message arguments
	lda	spc_fifo, x		; and update fifo read pos
	sta	REG_APUIO0		;
	sta	spc_pr+0
	inx				;
	lda	spc_fifo, x		;
	sta	REG_APUIO2		;
	sta	spc_pr+2
	inx				;
	lda	spc_fifo, x		;
	sta	REG_APUIO3		;
	sta	spc_pr+3
	inx				;
	stx	spc_fread		;------------------------------
	lda	spc_v			; dispatch message
	eor	#80h			;
	sta	spc_v			;
	sta	REG_APUIO1		;------------------------------
	sta	spc_pr+1
	lda	spc_fread		; exit if fifo has become empty
	cmp	spc_fwrite		;
	beq	@exit			;
;----------------------------------------------------------------------
@next:
;----------------------------------------------------------------------
	lda	REG_SLHV		; latch H/V and test for change
	lda	REG_OPVCT		;------------------------------
	cmp	spc1			; we will loop until the VCOUNT
	beq	@process_again		; changes Y times
	sta	spc1			;
	dey				;
	bne	@process_again		;
;----------------------------------------------------------------------
@exit:
;----------------------------------------------------------------------
	rep	#10h			; restore 16-bit index
	rts				;
	
;**********************************************************************
; read status register
;**********************************************************************
spcReadStatus:
	ldx	#5			; read PORT2 with stability checks
	lda	REG_APUIO2		; 
@loop:					;
	cmp	REG_APUIO2		;
	bne	spcReadStatus		;
	dex				;
	bne	@loop			;
	rts				;
	
;**********************************************************************
; read position register
;**********************************************************************
spcReadPosition:
	ldx	#5			; read PORT3 with stability checks
	lda	REG_APUIO2		;
@loop:					;
	cmp	REG_APUIO2		;
	bne	spcReadPosition		;
	dex				;
	bne	@loop			;
	rts				;

;**********************************************************************
spcGetCues:
;**********************************************************************
	lda	spc_q
	sta	spc1
	jsr	spcReadStatus
	and	#0Fh
	sta	spc_q
	sec
	sbc	spc1
	bcs	:+
	adc	#16
:	rts

