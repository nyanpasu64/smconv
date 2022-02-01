.export spcLoadEffect
.export spcEffect
.export spcSetSoundTable
.export spcAllocateSoundRegion
.export spcPlaySound
.export spcPlaySoundV
.export spcPlaySoundEx
.export spcTest

.export spcChangeWaveTable, spcSetPosition, spcSetWaveTableBank


SPC_BOOT = 0400h


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
.zeropage
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;

digi_src:	.res 3
digi_src2:	.res 3

SoundTable:	.res 3

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
.bss
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;

digi_init:	.res 1
digi_pitch:	.res 1
digi_vp:	.res 1
digi_remain:	.res 2
digi_active:	.res 1
digi_copyrate:	.res 1

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
.code
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;

.i16
.a8

;-------test function-----------;
spcTest:			;#
	lda	z:spc_v		;#
:	cmp	REG_APUIO1	;#
	bne	:-		;#
	xba			;#
	lda	#CMD_TEST	;#
	sta	REG_APUIO0	;#
	xba			;#
	eor	#80h		;#
	sta	z:spc_v		;#
	sta	REG_APUIO1	;#
	rts			;#
;--------------------------------#
; ################################

;**********************************************************************
;* x = id
;*
;* load effect into memory
;**********************************************************************
spcLoadEffect:
;----------------------------------------------------------------------
	ldy	#SB_SRCTABLE	; get address of source
	sty	z:spc2		;
	jsr	get_address	;--------------------------------------
	lda	z:spc_v		; sync with SPC
:	cmp	REG_APUIO1	;
	bne	:-		;--------------------------------------
	lda	#CMD_LOADE	; write message
	sta	REG_APUIO0	;--------------------------------------
	lda	z:spc_v		; dispatch message and wait
	eor	#80h		;
	ora	#01h		;
	sta	z:spc_v		;
	sta	REG_APUIO1	;
:	cmp	REG_APUIO1	;
	bne	:-		;--------------------------------------
	rep	#20h		; x = length (bytes->words)
	lda	[spc_ptr], y	;
	ina			;
	lsr			;
	incptr			;
	tax			;--------------------------------------
	incptr			; skip loop
	sep	#20h		;--------------------------------------
	jsr	do_transfer	; transfer data
				;--------------------------------------
	lda	spc_sfx_next	; return sfx index
	inc	spc_sfx_next	;
	rts			;

;**********************************************************************
;* a = v*16 + p
;* x = id
;* y = pitch (0-15, 8=32khz)
;**********************************************************************
spcEffect:
;----------------------------------------------------------------------
	sta	z:spc1			; spc1.l = "vp"
	sty	z:spc2			; spc1.h = "sh"
	txa				;
	asl				;
	asl				;
	asl				;
	asl				;
	ora	z:spc2			;
	sta	z:spc1+1		;------------------------------
	lda	#CMD_FX			; queue FX message
	jmp	QueueMessage		;
;----------------------------------------------------------------------

;======================================================================
;
; STREAMING
;
;======================================================================

;======================================================================
spcSetSoundTable:
;======================================================================
	sty	SoundTable
	sta	SoundTable+2
	rts

;======================================================================
spcAllocateSoundRegion:
;======================================================================
; a = size of buffer
;----------------------------------------------------------------------
	pha				; flush command queue
	jsr	spcFlush		;
					;
	lda	z:spc_v			; wait for spc
:	cmp	REG_APUIO1		;
	bne	:-			;
;----------------------------------------------------------------------
	pla				; set parameter
	sta	REG_APUIO3		;
;----------------------------------------------------------------------
	lda	#CMD_SSIZE		; set command
	sta	REG_APUIO0		;
	sta	z:spc_pr+0		;
;----------------------------------------------------------------------
	lda	z:spc_v			; send message
	eor	#128			;
	sta	REG_APUIO1		;
	sta	z:spc_v			;
	sta	z:spc_pr+1		;
;----------------------------------------------------------------------
	rts

;----------------------------------------------------------------------
; a = index of sound
;======================================================================
spcPlaySound:
;======================================================================
	ldy	#0ffh
;======================================================================
spcPlaySoundV:
;======================================================================
	xba
	lda	#128
	xba
	ldx	#0ffh
	
;----------------------------------------------------------------------
; a = index
; b = pitch
; y = vol
; x = pan
;======================================================================
spcPlaySoundEx:
;======================================================================
	sep	#10h			; push 8bit vol,pan on stack
	phy				;
	phx				;
;----------------------------------------------------------------------------
	rep	#30h			; um
	pha				; 
;----------------------------------------------------------------------------
	and	#0FFh			; y = sound table index 
	asl				;
	asl				;
	asl				;
	tay				;
;----------------------------------------------------------------------------
	pla				; a = rate
	xba				;
	and	#255			; clear B
	sep	#20h			;
;----------------------------------------------------------------------------
	cmp	#0			; if a < 0 then use default
	bmi	@use_default_pitch	; otherwise use direct	
	sta	digi_pitch		;
	bra	@direct_pitch		;
@use_default_pitch:			;
	lda	[SoundTable], y		;
	sta	digi_pitch		;
@direct_pitch:				;
;----------------------------------------------------------------------------
	tax				; set transfer rate
	lda	digi_rates, x		;
	sta	digi_copyrate		;
;----------------------------------------------------------------------------
	iny				; [point to PAN]
	pla				; if pan <0 then use default
	bmi	@use_default_pan	; otherwise use direct
	sta	z:spc1
	bra	@direct_pan
@use_default_pan:
	lda	[SoundTable], y
	sta	z:spc1
@direct_pan:
;----------------------------------------------------------------------------
	iny				; [point to VOL]
	pla				; if vol < 0 then use default
	bmi	@use_default_vol	; otherwise use direct
	bra	@direct_vol
@use_default_vol:
	lda	[SoundTable], y
@direct_vol:
;----------------------------------------------------------------------------
	asl				; vp = (vol << 4) | pan
	asl				;
	asl				;		
	asl				;
	ora	z:spc1			;
	sta	digi_vp			;
;----------------------------------------------------------------------------
	iny				; [point to LENGTH]
	rep	#20h			; copy length
	lda	[SoundTable], y		;
	sta	digi_remain		;
;----------------------------------------------------------------------------
	iny				; [point to SOURCE]
	iny				;
	lda	[SoundTable], y		; copy SOURCE also make +2 copy
	iny				;
	iny				;
	sta	digi_src		;
	ina				;
	ina				;
	sta	digi_src2		;
	sep	#20h			;
	lda	[SoundTable], y		;
	sta	digi_src+2		;
	sta	digi_src2+2		;
;----------------------------------------------------------------------------
	lda	#1			; set flags
	sta	digi_init		;
	sta	digi_active		; 
;----------------------------------------------------------------------------
	rts
	
;============================================================================
spcProcessStream:
;============================================================================
	rep	#20h			; test if there is data to copy
	lda	digi_remain		;
	bne	:+			;
	sep	#20h			;
	stz	digi_active		;
	rts				;
:	sep	#20h			;
;-----------------------------------------------------------------------
	lda	z:spc_pr+0		; send STREAM signal
	ora	#128			;
	sta	REG_APUIO0		;
;-----------------------------------------------------------------------
:	bit	REG_APUIO0		; wait for SPC
	bpl	:-			;
;-----------------------------------------------------------------------
	stz	REG_APUIO1		; if digi_init then:
	lda	digi_init		;   clear digi_init
	beq	@no_init		;   set newnote flag
	stz	digi_init		;   copy vp
	lda	digi_vp			;   copy pan
	sta	REG_APUIO2		;   copy pitch
	lda	digi_pitch		;
	sta	REG_APUIO3		;
	lda	#1			;
	sta	REG_APUIO1		;
	lda	digi_copyrate		; copy additional data
	clc				;
	adc	#INIT_DATACOPY		;
	bra	@newnote		;
@no_init:				;
;-----------------------------------------------------------------------
	lda	digi_copyrate		; get copy rate
@newnote:
	rep	#20h			; saturate against remaining length
	and	#0FFh			; 
	cmp	digi_remain		;
	bcc	@nsatcopy		;
	lda	digi_remain		;
	stz	digi_remain		;
	bra	@copysat		;
@nsatcopy:				;
;-----------------------------------------------------------------------
	pha				; subtract amount from remaining
	sec				;
	sbc	digi_remain		;
	eor	#0FFFFH			;
	ina				;
	sta	digi_remain		;
	pla				;
@copysat:				;
;-----------------------------------------------------------------------
	sep	#20h			; send copy amount
	sta	REG_APUIO0		;
;-----------------------------------------------------------------------
	sep	#10h			; spc1 = nn*3 (amount of tribytes to copy)
	tax				; x = vbyte
	sta	z:spc1			;
	asl				;
	clc				;
	adc	z:spc1			;
	sta	z:spc1			;
	ldy	#0			;
;-----------------------------------------------------------------------


@next_block:
		
	lda	[digi_src2], y
	sta	z:spc2
	rep	#20h			; read 2 bytes
	lda	[digi_src], y		;
:	cpx	REG_APUIO0		;-sync with spc
	bne	:-			;
	inx				; increment v
	sta	REG_APUIO2		; write 2 bytes
	sep	#20h			;
	lda	z:spc2			; copy third byte
	sta	REG_APUIO1		;
	stx	REG_APUIO0		; send data
	iny				; increment pointer
	iny				;
	iny				;
	dec	z:spc1			; decrement block counter
	bne	@next_block		;
;-----------------------------------------------------------------------
:	cpx	REG_APUIO0		; wait for spc
	bne	:-			;
;-----------------------------------------------------------------------	
	lda	z:spc_pr+0		; restore port data
	sta	REG_APUIO0		;
	lda	z:spc_pr+1		;
	sta	REG_APUIO1		;
	lda	z:spc_pr+2		;
	sta	REG_APUIO2		;
	lda	z:spc_pr+3		;
	sta	REG_APUIO3		;
;-----------------------------------------------------------------------
	tya				; add offset to source
	rep	#31h			;
	and	#255			;
	adc	digi_src		;
	sta	digi_src		;
	ina				;
	ina				;
	sta	digi_src2		;
	sep	#20h			;
;-----------------------------------------------------------------------
	rts
	
.ifdef PAL
	digi_rates:	; PAL SNES runs at 5/6 framerate
		.byte	0, 4, 6, 9,11,13,16,18,22,26
.else
	digi_rates:
		.byte	0, 3, 5, 7, 9,11,13,15,18,21
.endif

spcChangeWaveTable:
spcSetPosition:
spcSetWaveTableBank:
	rts

;;----------------------------------------------------------------------
;spcProcessDigital:
;;----------------------------------------------------------------------
;	lda	z:spc_pr+0		; send STREAM signal
;	ora	#128			;
;	sta	REG_APUIO0		;
;;----------------------------------------------------------------------
;:	cmp	REG_APUIO0		; wait for SPC
;	bne	:-			;
;;----------------------------------------------------------------------
;	lda	REG_APUIO1		; get chunk counter
;	bne	:+			; if 0 then ragequit
;	lda	z:spc_pr+0		; [restore p0]
;	sta	REG_APUIO0		;
;	rts				;
;:					;
;;----------------------------------------------------------------------
;	sep	#30h			;
;	stz	REG_MEMSEL		; switch to SlowROM
;	tax				;
;	ldy	#0			;
;;----------------------------------------------------------------------
;; critical routine following
;;
;; some instructions: bytes,cyc (estimate) microseconds
;; stz io       : 3,4 (8*3+6,		30) 1.397us
;; sep/rep IMM8 : 2,3 (8*2+6,		22) 1.024us
;; sta8 io      : 3,4 (8*3+6,		30) 1.397us
;; iny          : 1,2 (8+6,		14) 0.651us
;; lda8 []+y    : 2,7 (8*2+8*3+8,	40) 2.235us
;; sta16 io     : 3,5 (8*3+6+6,		36) 1.676us
;; nop          : 1,2 (8+6,		14) 0.651us
;;----------------------------------------------------------------------
;	sei				;
;	stz	REG_MEMSEL		; switch to SlowROM
;	stz	REG_APUIO0		; send start signal
;	
;	;--------------------------------------------------------------
;	; ~13us until start
;	;--------------------------------------------------------------
;	
;			;	bne	_sr_wait_for_snes	0#		+2
;			;	nop				1.953125	+2
;			;	cmp	x, #0			3.90625		+2
;			;	beq	_sr_skip		5.859375	+2
;			;	mov	y, stream_write		7.8125		+3
;			;	clrc				10.7421875	+2
;			;SPC:					12.6953125
;	
;	
;	; (TWEAK)
;	nop			; 0#
;	nop			; 0.65186012944079713181543046049262
;	nop			; 1.3037202588815942636308609209846
;	nop			; 1.9555803883223913954462913814766
;	nop			; 2.6074405177631885272617218419686
;	nop			; 3.2593006472039856590771523024606
;	nop			; 3.9111607766447827908925827629526
;	nop			; 4.5630209060855799227080132234446
;	nop			; 5.2148810355263770545234436839366
;	nop			; 5.8667411649671741863388741444286
;	nop			; 6.5186012944079713181543046049206
;	nop			; 7.1704614238487684499697350654126
;	nop			; 7.8223215532895655817851655259046
;	nop			; 8.4741816827303627136005959863966
;				; 9.126041812171159845416026446888
;				
;			;SPC:
;			;	byte1 mov a, dp	; 0#
;			;	write		; 2.9296875
;			;	byte2		; 8.7790626 (PER BYTE)
;			; 17.5581252	b2
;			; 26.3371878	b3
;			; 35.1162504	b4
;			; 43.895313	b5
;			; 52.6743756	b6
;			; 61.4534382	b7
;			; 70.2325008	b8
;			; 79.0115634	b9
;			; 87.790626	b10
;			; 96.5696886	b11
;			; 105.3487512	b12
;			; 114.1278138	b13
;			; 122.9068764	b14
;			; 131.685939	b15
;			; 140.4650016	b16
;			; 149.2440642	b17
;			
;.macro dm_copy_byte target, trail ;84 +14*trail cycles
;	lda	[digital_src], y
;	iny
;	sta	REG_APUIO0
;	.repeat trail-1
;		nop
;	.endrep
;.endmacro
;	
;@cpy_next_chunk:
;	dm_copy_byte REG_APUIO0, 8 ;8.7790626 : 9.12604181217116
;	dm_copy_byte REG_APUIO1, 7 ;17.5581252 : 17.6002234949015
;	dm_copy_byte REG_APUIO2, 8 ;26.3371878 : 26.7262653070727
;	dm_copy_byte REG_APUIO3, 7 ;35.1162504 : 35.2004469898031
;	dm_copy_byte REG_APUIO0, 8 ;43.895313 : 44.3264888019742
;	dm_copy_byte REG_APUIO1, 7 ;52.6743756 : 52.8006704847046
;	dm_copy_byte REG_APUIO2, 8 ;61.4534382 : 61.9267122968758
;	dm_copy_byte REG_APUIO3, 7 ;70.2325008 : 70.4008939796061
;	dm_copy_byte REG_APUIO0, 8 ;79.0115634 : 79.5269357917772
;	dm_copy_byte REG_APUIO1, 7 ;87.790626 : 88.0011174745075
;	dm_copy_byte REG_APUIO2, 8 ;96.5696886 : 97.1271592866786
;	dm_copy_byte REG_APUIO3, 7 ;105.3487512 : 105.601340969409
;	dm_copy_byte REG_APUIO0, 8 ;114.1278138 : 114.72738278158
;	dm_copy_byte REG_APUIO1, 7 ;122.9068764 : 123.20156446431
;	dm_copy_byte REG_APUIO2, 8 ;131.685939 : 132.327606276482
;	dm_copy_byte REG_APUIO3, 7 ;140.4650016 : 140.801787959212
;	dm_copy_byte REG_APUIO0, 7 ;149.2440642 : 149.275969641942
;	dm_copy_byte REG_APUIO1, 8 ;158.0231268 : 158.402011454113
;	
;:	cpx	REG_APUIO0 	; sync point
;	bne	:-		;
;	
;	dex
;	beq	@cpy_complete
;	jmp	@cpy_next_chunk
;@cpy_complete:
;
;	lda	z:spc_pr+0
;	sta	REG_APUIO0
;	lda	z:spc_pr+1
;	sta	REG_APUIO1
;	lda	z:spc_pr+2
;	sta	REG_APUIO2
;	lda	z:spc_pr+3
;	sta	REG_APUIO3
;
;	rep	#10h
;	
;----------------------------------------------------------------------
;	lda	CART_HEADER + 0D5h - 0B0h	; restore rom speed
;	and	#1				;
;	sta	REG_MEMSEL			;
;----------------------------------------------------------------------
;	
;	cli
;	rts

;**********************************************************************
; stop
;
; this is a blocking function
;**********************************************************************
;spcDisableDigital:
;;----------------------------------------------------------------------
;	jsr	spcFlush		; flush existing messages
;;----------------------------------------------------------------------
;	lda	z:spc_v			; wait for spc
;:	cmp	REG_APUIO1		;
;	bne	:-			;
;;----------------------------------------------------------------------
;	lda	#CMD_DDS		; send DDS message
;	sta	REG_APUIO0		;
;	lda	z:spc_v			;
;	eor	#128			;
;	sta	z:spc_v			;
;	sta	REG_APUIO1		;
;;----------------------------------------------------------------------
;:	cmp	REG_APUIO1		; wait for spc
;	bne	:-			;
;;----------------------------------------------------------------------
;	sta	z:spc_pr+1
;	rts

;**********************************************************************
; start streaming
;
; this is a blocking function
;**********************************************************************
;spcEnableDigital:
;----------------------------------------------------------------------
	;jsr	spcFlush		; flush existing messages
;----------------------------------------------------------------------
;	lda	z:spc_v			; wait for spc
;:	cmp	REG_APUIO1		;
;	bne	:-			;
;----------------------------------------------------------------------
;	lda	#CMD_EDS		; send EDS message
;	sta	REG_APUIO0		;	
;	lda	z:spc_v			;
;	eor	#128			;
;	sta	z:spc_v			;
;	sta	REG_APUIO1		;
;----------------------------------------------------------------------	
;:	cmp	REG_APUIO1		; wait for spc
;	bne	:-			;
;----------------------------------------------------------------------
;	sta	z:spc_pr+1
;	stz	digital_len
;	stz	digital_len+1
;	rts				;
