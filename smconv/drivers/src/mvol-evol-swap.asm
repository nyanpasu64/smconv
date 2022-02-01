evol_l:			.block 1
evol_r:			.block 1

current_evol_time:	.block 1
evol_fb:		.block 1
filter_time:		.block 1
mvol_evol_end:		.block 1
mvol_evol_start:	.block 1
mvol_evol_swap:		.block 1

DEFAULT_MVOL = 7eh

; ?80 - MVOL slides to 7eh (default), EVOL decreses
; ?81-FF - MVOL slides to 01-7e, EVOL increases 

; from ab-mes
; this was a fun command but it took up way too many bytes
; for how little i used it

;--------------------------------------------------------
DecreaseMasterIncreaseEcho:
;--------------------------------------------------------
	inc	current_evol_time
	cmp	filter_time, current_evol_time
	bne	_end_evol

        mov     current_evol_time, #0
	cmp	mvol_evol_swap, #3
	bcs	IncreaseMasterDecreaseEcho

	mov	a, mvol_evol_end
	cmp	a, mvol_evol_start
	beq	_end_evol_inc
	dec	mvol_evol_start
	cmp	evol_fb, #0
	beq	_skip_fb_dec
	dec	evol_fb
	mov	a, evol_fb
	call	Command_EchoFeedback2

_skip_fb_dec:
	mov	a, mvol_evol_start
	call	Command_MasterVolume2

	mov	a, evol_l
	inc	a
	mov	evol_l, a
	cmp	evol_l, #7eh
	bcs	_ext_exit
	call	Command_EchoVolumeNS2

_ext_exit:
	ret

_end_evol_inc:
	mov	mvol_evol_swap, #1
	mov	current_evol_time, #0
	ret
;--------------------------------------------------------
IncreaseMasterDecreaseEcho:
;--------------------------------------------------------
	cmp	mvol_evol_swap, #4
	beq	skip_setup

	mov	evol_l, #7eh
	inc	mvol_evol_swap
skip_setup:
	cmp	mvol_evol_start, #DEFAULT_MVOL
	beq	_end_evol_dec

	inc	mvol_evol_start
	mov	a, mvol_evol_start
	call	Command_MasterVolume2

_skip_mvol_inc:
	mov	a, evol_l
	cmp	evol_l, evol_min
	beq	_ext_exit

	dec	a
	call	Command_EchoVolumeNS2
	ret

_end_evol_dec:
	mov	mvol_evol_swap, #0
	mov	current_evol_time, #0
	call	ResetEchoFeedback
	ret



;=======================================================================
Command_EchoFeedback:				; ?xx
;=======================================================================
	cmp	a, #80h
	beq	ResetEchoFeedback
;=======================================================================
Command_EchoFeedback2:
;=======================================================================
	mov	SPC_DSPA, #DSP_EFB
_set_dsp_efb:
	mov	SPC_DSPD, a
	ret
;-----------------------------------------------------------------------
ResetEchoFeedback:
;-----------------------------------------------------------------------
	mov	SPC_DSPA, #DSP_EFB	; restore default EFB
	mov	a, !MODULE+MOD_EFB	;
	mov	evol_fb, a
	bra	_set_dsp_efb


;-----------------------------------------------------------------------
check_mvol_evol_status:
;-----------------------------------------------------------------------
	mov	mvol_evol_swap, #3
	ret
;-----------------------------------------------------------------------
ResetMasterVolume2:
;-----------------------------------------------------------------------
	cmp	mvol_evol_swap, #1
	beq	check_mvol_evol_status
	bcs	cmd_exit4
;=======================================================================
ResetMasterVolume:
;=======================================================================
	mov	a, #DEFAULT_MVOL
;=======================================================================
Command_MasterVolume:				; ?xx
;=======================================================================
	cmp	a, #80h
	beq	ResetMasterVolume2
	cmp	a, #81h
	bcs	EnableMasterEchoVolumeSlide
	mov	mvol_evol_start, a
;=======================================================================
Command_MasterVolume2:
;=======================================================================
	mov	SPC_DSPA, #DSP_MVOL
	mov	SPC_DSPD, a
	mov	SPC_DSPA, #DSP_MVOLR
	mov	SPC_DSPD, a
cmd_exit4:
	ret
;-----------------------------------------------------------------------
EnableMasterEchoVolumeSlide:
;-----------------------------------------------------------------------
	cmp	mvol_evol_swap, #0
	bne	cmd_exit4
	setc
	sbc	a, #80h
	dec	a
	mov	mvol_evol_end, a
	mov	mvol_evol_swap, #2
	ret

check_stereo_echo:
	mov	y, !MODULE+MOD_EVOL
	cmp	y, !MODULE+MOD_EVOLR
	beq	_setr

	eor	a, #0ffh
	inc	a
_setr:	ret

;=======================================================================
Command_EchoVolumeNS:				;
;=======================================================================
	setc
	sbc	a, #80h
;-----------------------------------------------------------------------
Command_EchoVolumeNS2:		; set echo volume no scaling!
;-----------------------------------------------------------------------
	mov	SPC_DSPA, #DSP_EVOL
	mov	SPC_DSPD, a
	mov	current_evol, a
	mov	evol_l, a
	call	check_stereo_echo
	mov	SPC_DSPA, #DSP_EVOLR
	mov	SPC_DSPD, a
	mov	evol_r, a
	ret
;=======================================================================
Command_EchoVolume:				; ?xx
;=======================================================================
	cmp	a, #80h
	beq	ResetEchoVolume
	bcs	Command_EchoVolumeNS
;-----------------------------------------------------------------------
Command_EchoVolume2:
;-----------------------------------------------------------------------
	mov	current_evol, a
	mov	evol_l, a
	call	check_stereo_echo

	mov	evol_r, a
	bra	UpdateEchoVolume
;=======================================================================
ResetEchoVolume:
;=======================================================================
	mov	a, !MODULE+MOD_EVOL
	mov	evol_l, a
	mov	current_evol, a
	mov	a, !MODULE+MOD_EVOLR
	mov	evol_r, a
;=======================================================================
UpdateEchoVolume:			; set echo volume with master scale applied
;=======================================================================
	mov	SPC_DSPA, #DSP_MVOL	; set EVOL scaled by main volume
	mov	a, SPC_DSPD		;
	asl	a			;
	mov	m0, a			;
	mov	SPC_DSPA, #DSP_EVOL	;
	mov	y, evol_l		;
	mul	ya			;
	mov	a, y			;
	mov	y, evol_l		;
	bpl	_plus			;
	setc				;
	sbc	a, m0			;
_plus:	mov	SPC_DSPD, a		;
	mov	a, m0			; set EVOLR scaled by main volume
	mov	SPC_DSPA, #DSP_EVOLR	;
	mov	y, evol_r		;
	mul	ya			;
	mov	a, y			;
	mov	y, evol_r		;
	bpl	_plusr			;
	setc				;
	sbc	a, m0			;
_plusr:	mov	SPC_DSPD, a		;

	ret

