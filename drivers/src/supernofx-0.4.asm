;========================================================
; "SM-SPC"
;
; snesmod spc driver
;
; (c) 2009 Mukunda Johnson
; (c) 2013 Additional code added by KungFuFurby for pitch modulation and noise generation
; (c) 2014-2017 Additional code added by Augustus Blackheart and KungFuFurby
;========================================================
;#define DEBUGINC inc debug \ mov SPC_PORT0, debug

.define LBYTE(z) (z & 0FFh)
.define HBYTE(z) (z >> 8)

.define SPROC TCALL 0
.define SPROC2 SPROC

;********************************************************
; PROTOCOL
;
; mm = mimic data
; id = message id
; vv = validation data (not previous value)
; v1 = nonzero validation data (not previous value)
;
; SPC PORTS:
; PORT0 = RESERVED
; PORT1 = COMMUNICATION
; PORT2 = STATUS:
;   MSB fep-cccc LSB
;   f = module volume fade[out/in] in progress
;   e = end of module reached (restarted from beginning)
;   p = module is playing (0 means not playing or preparing...)
;   cccc = cue, incremented on SF1 pattern effect
; PORT3 = MODULE POSITION
; 
; NAME	ID	DESC
;--------------------------------------------------------
; LOAD	00	Upload Module
; 
; >> id vv -- --	send message
; << -- mm -- --	message confirmed
;
; >> -- v1 DD DD	transfer module
; << -- mm -- --	DDDD = data, loop until all words xferred
;
; >> -- 00 DD DD	final word
; << -- mm -- --	okay proceed to transfer sources...
;
; for each entry in SOURCE_LIST:
;
; >> 01 vv LL LL	send loop point
; << -- mm -- --	loop point saved
; >> -- v1 DD DD	transfer source data
; << -- mm -- --	DDDD = data, loop unti all words xferred
;
; >> -- 00 DD DD	transfer last word
; << -- mm -- --	
;
; [loop until all needed sources are transferred]
;
; >> 00 vv -- --	terminate transfer
; << -- mm -- --
;
; notes:
;   this function resets the memory system
;   all sound effects will become invalid
; 
;   after final sample transferred the system may
;   be halted for some time to setup the echo delay.
;--------------------------------------------------------
; VOL	02	Set Master Volume
;
; >> id vv VV --
; << -- mm -- --
;
; VV = master volume level (0..127)
;--------------------------------------------------------
; PLAY	03	Play Module
;
; >> id vv -- pp
; << -- mm -- --
;
; pp = start position
;--------------------------------------------------------
; STOP	04	Stop Playback
;
; >> id vv -- --
; << -- mm -- --
;--------------------------------------------------------
; MVOL	05	Set Module Volume
;
; >> id vv -- VV
; << -- mm -- --
;
; VV = 0..255 new module volume scale
;--------------------------------------------------------
; FADE	06	Fade Module Volume
;
; >> id vv tt VV
; << -- mm -- --
;
; VV = 0..255 target volume level
; tt = fade speed (added every m tick)
;--------------------------------------------------------
; RES	07	Reset
;
; >> id vv -- --
; 
; <driver unloaded>
;--------------------------------------------------------
; TEST	09	Test function
;
; >> id vv -- --
; << -- mm -- --
;********************************************************


;*****************************************************************************************
; dsp registers		; Nocash SNES Specs
;*****************************************************************************************
DSPV_VOL	=00h	; Left volume for Voice 0..7 (R/W)
DSPV_VOLR	=01h	; Right volume for Voice 0..7 (R/W)
DSPV_PL		=02h	; Pitch scaler for Voice 0..7, lower 8bit (R/W)
DSPV_PH		=03h	; Pitch scaler for Voice 0..7, upper 6bit (R/W)
DSPV_SRCN	=04h	; Source number for Voice 0..7 (R/W)
DSPV_ADSR1	=05h	; ADSR settings for Voice 0..7, lower 8bit (R/W)
DSPV_ADSR2	=06h	; ADSR settings for Voice 0..7, upper 8bit (R/W
DSPV_GAIN	=07h	; Gain settings for Voice 0..7 (R/W)
DSPV_ENVX	=08h	; Current envelope value for Voice 0..7 (R)
DSPV_OUTX	=09h	; Current sample value for Voice 0..7 (R) 

;		=0Ah	; Unused (8 bytes of general-purpose RAM) (R/W)
;		=1Ah	; These registers seem to have no function at all.
;		=2Ah	; Data written to them seems to have no effect on
;		=3Ah	; sound output, the written values seem to be left
;		=4Ah	; intact (ie. they aren't overwritten by voice or
;		=5Ah	; or echo status information).
;		=6Ah	;
;		=7Ah	;

;		=0Bh	; Unused (8 bytes of general-purpose RAM) (R/W)
;		=1Bh	;
;		=2Bh	;
;		=3Bh	;
;		=4Bh	;
;		=5Bh	;
;		=6Bh	;
;		=7Bh	;

			; volume: (negative = phase inverted)
DSP_MVOL	=0Ch	; Left channel master volume (R/W)  :: (-127..+127) -128 causes
DSP_MVOLR	=1Ch	; Right channel master volume (R/W) :: multiply overflows
DSP_EVOL	=2Ch	; Left channel echo volume  :: (-128..+127) -128 can be safely
DSP_EVOLR	=3Ch	; Right channel echo volume :: used
DSP_KON		=4Ch	; Flags for Voice 0..7 (0=No change, 1=Key On) (W)
DSP_KOF		=5Ch	; Flags for Voice 0..7 (0=No change, 1=Key Off) (R/W)
DSP_FLG		=6Ch	; Reset, Mute, Echo-Write flags and Noise Clock (R/W)
			; 0-4 Noise frequency (0=Stop, 1=16Hz, 2=21Hz, ..., 1Eh=16kHz, 1Fh=32kHz)
			; 5   Echo Buffer Writes (0=Enable, 1=Disable) (doesn't disable echo-reads)
			; 6   Mute Amplifier     (0=Normal, 1=Mute) (doesn't stop internal processing)
			; 7   Soft Reset         (0=Normal, 1=KeyOff all voices, and set Envelopes=0)
DSP_ENDX	=7Ch	; Voice End Flags for Voice 0..7 (R) (W=Ack)

DSP_EFB		=0Dh	; Echo feedback volume (R/W)
;		=1Dh	; Unused (1 byte of general-purpose RAM) (R/W)
DSP_PMON	=2Dh	; Pitch Modulation Enable Flags for Voice 1..7 (R/W) (see notes below)
DSP_NON		=3Dh	; Noise Enable Flags for Voice 0..7 (R/W)
DSP_EON		=4Dh	; Echo Enable Flags for Voice 0..7 (R/W)
DSP_DIR		=5Dh	; Sample table address (R/W)
			; 0-7   Sample Table Address (in 256-byte steps) (indexed via DSPV_SRCN)
			; The table can contain up to 256 four-byte entries (max 1Kbyte). Each
			; entry is: 
			; Byte 0-1  BRR Start Address (used when voice is Keyed-ON)
			; Byte 2-3  BRR Restart/Loop Address (used when end of BRR data reached)
			; Changing DIR or VxSRCN has no immediate effect (until/unless voices
			; are newly Looped or Keyed-ON).

DSP_ESA		=6Dh	; Echo ring buffer address (R/W)
DSP_EDL		=7Dh	; Echo delay (ring buffer size) (R/W)

;		=0Eh	; Unused (8 bytes of general-purpose RAM) (R/W)
;		=1Eh	;
;		=2Eh	;
;		=3Eh	;
;		=4Eh	;
;		=5Eh	;
;		=6Eh	;
;		=7Eh	;

DSP_C0		=0Fh	; Echo FIR filter coefficient 0..7 (R/W)
DSP_C1		=1Fh	; Value -128 should not be used for any of the FIRx
DSP_C2		=2Fh	; registers (to avoid multiply overflows). To avoid
DSP_C3		=3Fh	; additional overflows: The sum of POSITIVE values
DSP_C4		=4Fh	; in the first seven registers (FIR0..FIR6) should
DSP_C5		=5Fh	; not exceed +7Fh, and the sum of NEGATIVE values
DSP_C6		=6Fh	; should not exceed -7Fh. The sum of all eight
DSP_C7		=7Fh	; registers (FIR0..FIR7) should be usually around +80h

;-----------------------;

; 2Dh - PMON - Pitch Modulation Enable Flags for Voice 1..7 (R/W)
; Pitch modulation allows to generate "Frequency Sweep" effects by mis-using the
; amplitude from channel (x-1) as pitch factor for channel (x).
;  0    Not used
;  1-7  Flags for Voice 1..7 (0=Normal, 1=Modulate by Voice 0..6)
; For example, output a very loud 1Hz sine-wave on channel 4 (with Direct
; Gain=40h, and with Left/Right volume=0; unless you actually want to output it
; to the speaker). Then additionally output a 2kHz sine wave on channel 5 with
; PMON.Bit5 set. The "2kHz" sound should then repeatedly sweep within 1kHz..3kHz
; range (or, for a more decent sweep in 1.8kHz..2.2kHz range, drop the Gain
; level of channel 4)

; x5h/x6h - ADSR 1/2
;  0-3   4bit Attack rate   ;Rate=N*2+1, Step=+32 (or Step=+1024 when Rate=31)
;  4-6   3bit Decay rate    ;Rate=N*2+16, Step=-(((Level-1) SAR 8)+1)
;  7     ADSR/Gain Select   ;0=Use VxGAIN, 1=Use VxADSR (Attack/Decay/Sustain)
;  8-12  5bit Sustain rate  ;Rate=N, Step=-(((Level-1) SAR 8)+1)
;  13-15 3bit Sustain level ;Boundary=(N+1)*100h
;  N/A   0bit Release rate  ;Rate=31, Step=-8 (or Step=-800h when BRR-end)

; Echo Overflows
; Setting FIRx, EFB, or EVOLx to -128 does probably cause multiply overflows?

FLG_NOISE	=0E0h
FLG_RESET	=80h
FLG_MUTE	=40h
FLG_ECEN	=20h

#define SETDSP(xx,yy) mov SPC_DSPA, #xx\ mov SPC_DSPD, #yy

;*****************************************************************************************
; module defs
;*****************************************************************************************

MOD_IV		=00H	; INITIAL VOLUME
MOD_IT		=01H	; INITIAL TEMPO
MOD_IS		=02H	; INITIAL SPEED
MOD_CV		=03H	; INITIAL CHANNEL VOLUME
MOD_CP		=0BH	; INITIAL CHANNEL PANNING
MOD_EVOL	=13H	; ECHO VOLUME (LEFT)
MOD_EVOLR	=14H	; ECHO VOLUME (RIGHT)
MOD_EDL		=15H	; ECHO DELAY
MOD_EFB		=16H	; ECHO FEEDBACK
MOD_EFIR	=17H	; ECHO FIR COEFS
MOD_EON		=1FH	; ECHO ENABLE BITS
MOD_SEQU	=20H	; SEQUENCE
MOD_PTABLE_L	=0E8H	; PATTERN TABLE
MOD_PTABLE_H	=128H	; 
MOD_ITABLE_L	=168H	; INSTRUMENT TABLE
MOD_ITABLE_H	=1A8H	; 
MOD_STABLE_L	=1E8H	; SAMPLE TABLE
MOD_STABLE_H	=228H	;

INS_FADEOUT	=00H
INS_SAMPLE	=01H
INS_GVOL	=02H
INS_SETPAN	=03H
INS_ENVLEN	=04H
INS_ENVSUS	=05H
INS_ENVLOOPST	=06H
INS_ENVLOOPEND	=07H
INS_ENVDATA	=08H

SAMP_DVOL	=00H
SAMP_GVOL	=01H
SAMP_PITCHBASE	=02H
SAMP_DINDEX	=04H
SAMP_SETPAN	=05H


;*****************************************************************************
; 0000 - 00EF   zero-page memory
;*****************************************************************************


xfer_address:	.block 2
m0:		.block 2
m1:		.block 2
m2:		.block 2
m3:		.block 2
m4:		.block 2
m5:		.block 2
m6:		.block 2
;next_sample:	.block 1
comms_v:	.block 1 ; communication variable

;stream_size:	.block 1
;stream_region:	.block 1

STREAM_REGION = 0FFh

;mod_active:	.block 1
mod_position:	.block 1
mod_tick:	.block 1
mod_row:	.block 1
mod_bpm:	.block 1
mod_speed:	.block 1
mod_speed_bk:	.block 1
mod_gvol:	.block 1

module_vol:	.block 1 ; module volume
module_fadeT:	.block 1 ; module volume fade target
module_fadeR:	.block 1 ; module volume fade rate
module_fadeC:	.block 1 ; timer counter

evol_l:		.block 1
evol_r:		.block 1

patt_addr:	.block 2
patt_rows:	.block 1
;pattjump_enable: .block 1
pattjump_index:	.block 1 ; 0 = no pattern jump
patt_update:	.block 1 ; PATTERN UPDATE FLAGS

ch_start:
ch_pitch_l:	.block 8
ch_pitch_h:	.block 8
ch_volume:	.block 8 ; 0..64
ch_cvolume:	.block 8 ; 0..128 (IT = 0..64)
ch_panning:	.block 8 ; 0..64
ch_cmem:	.block 8
ch_note:	.block 8
ch_instr:	.block 8
ch_vcmd:	.block 8
ch_command:	.block 8
ch_param:	.block 8
ch_sample:	.block 8
ch_flags:	.block 8
ch_env_y_l:	.block 8
ch_env_y_h:	.block 8
ch_env_node:	.block 8
ch_env_tick:	.block 8
ch_env_vib:	.block 8
ch_vib_wav:	.block 8 ; for negative sine values and triangle
ch_fadeout:	.block 8
;ch_ad:		.block 4
;ch_sr:		.block 4
ch_end:

MAX_ADSR_CHANNELS:	=4

; channel processing variables:
t_hasdata:	.block 1
;t_sampoff:	.block 1 ; sample offset not yet implemented
t_volume:	.block 1
t_panning:	.block 1
t_pitch:
t_pitch_l:	.block 1
t_pitch_h:	.block 1
t_flags:	.block 1
t_env:		.block 1 ; 0..255

p_instr:	.block 2

STATUS:		.block 1
STATUS_P	=32
STATUS_E	=64
STATUS_F	=128

;debug:		.block 1

CF_NOTE		=1
CF_INSTR	=2
CF_VCMD		=4
CF_CMD		=8
CF_KEYON	=16
CF_FADE		=32
CF_SURROUND	=64

TF_START	=80H
TF_DELAY	=2

;---------------------------
; extras
;---------------------------
STANDARD        = 7
BANDPASS        = 15
HIGHPASS        = 23
LOWPASS         = 31
CUSTOM1		= 39
CUSTOM2		= 47

current_evol:		.block 1
current_evol_time:	.block 1
current_filter_time:	.block 1
current_noise_time:	.block 1
current_wt_time:	.block 1
evol_fb:		.block 1
evol_max:		.block 1
evol_min:		.block 1
evol_time:		.block 1
filter_cmp:		.block 1
filter_time:		.block 1
;filter_delay1:		.block 1
;filter_delay2:		.block 1
;filter_delay3:		.block 1
filter_values:		.block 8
;min_bp_filter:		.block 1
noise_sweep_endmax:	.block 1
noise_sweep_endmin:	.block 1
noise_sweep_start:	.block 1
noise_time:		.block 1
noise_value:		.block 1
parameter_mode:		.block 1
wt_cur:			.block 1
;wt_max:		.block 1
;wt_min:		.block 1
wt_sample_high:		.block 1
wt_sample_low:		.block 1
wt_time:		.block 1
special:		.block 1

SF_MODACTIVE		=1	; mod_active
SF_EVOLINC		=2	; filter sweep evol (inc/dec)
SF_WTDIR		=4	; (inc/dec)
SF_NOISESWEEP		=8	; noise frequency cylce (off/on)
SF_NOISEINC		=16	; noise frequency (dec/inc)
SF_SWINGTEMPO		=32	; swing tempo (off/on)
SF_SWINGODD		=64	; swing tempo (odd/even)
SF_PATTERNJUMP		=128	; pattern jump (off/on)

special_mode:		.block 1

SM_FILTERSWEEP		=1	; filter sweep (off/on)
SM_3AFRESET		=2	; reset all before S3[A-F]
SM_WAVETABLE		=4	; (enable/disable)
SM_MVOLEVOLDIR		=8	; (inc evol dec mvol/dec evol inc mvol)
SM_NOISEREPEAT		=16	; (once/repeat)
SM_NOISEMODE		=32	; (normal/ping pong)
SM_PANBRELLO		=64	; (off/on)
SM_TREMOLO		=128	; (off/on)

swing_tempo_mod:	.block 1

DEFAULT_EVOL_MAX:	=64
DEFAULT_EVOL_MIN:	=32
DEFAULT_FILTER_DELAY1:	=10
DEFAULT_FILTER_DELAY2:	=12
DEFAULT_FILTER_DELAY3:	=14
DEFAULT_FILTER_TIME:	=80h	; {3-255}
DEFAULT_MAX_NOISE:	=1Fh
DEFAULT_MODVOL:		=8Fh
DEFAULT_MVOL:		=50h	; xmsnes 32h
DEFAULT_NOISE_TIME:	=80h
DEFAULT_RAMP_POS:	=40h
DEFAULT_RAMP_NEG:	=0bfh
DEFAULT_SQ_POS:		=40h
DEFAULT_SQ_NEG:		=00h
DEFAULT_SWING:		=1
DEFAULT_TEMPO:		=4eh	; original in snesmod was 50h
DEFAULT_VOL_SAT:	=64
DEFAULT_WT_MAX:		=8
DEFAULT_WT_MIN:		=0

Z_SURROUND	=1
Z_MUTE		=2
Z_UNMUTE	=3
Z_DIRECTGAIN	=5
Z_CHFS_W_RES	=6
Z_CHFS		=7
Z_EFIR		=8
Z_MVOL		=9
Z_EVOL		=10
Z_EFB		=11
Z_EDL		=12
Z_ETIMENOISE	=13
Z_MINMAX	=14
Z_FILTERTIME	=15

;-----------------------------------------------------------------------------


;*****************************************************************************
; 00F0 - 00FF	Registers
;*****************************************************************************


SPC_TEST	=0F0h ; Testing functions (W)                                  0Ah
SPC_CONTROL	=0F1h ; Timer, I/O and ROM Control (W)                         80h
		      ; bits 0-2 timer enables (1=on), bits 4-5 are I/O port clear bits (11=clear all)
SPC_DSP		=0F2h ; DSP Register Index (R/W)
SPC_DSPA	=0F2h ; 
SPC_DSPD	=0F3h ; DSP Register Data (R/W)
SPC_PORT0	=0F4h ; CPU Input and Output Register 0 (R and W)      R=00h,W=00h
SPC_PORT1	=0F5h ; CPU Input and Output Register 1 (R and W)      R=00h,W=00h
SPC_PORT2	=0F6h ; CPU Input and Output Register 2 (R and W)      R=00h,W=00h
SPC_PORT3	=0F7h ; CPU Input and Output Register 3 (R and W)      R=00h,W=00h
SPC_AUXPORT4	=0F8h ; External I/O Port P4 (S-SMP Pins 34-27) (R/W) (unused) FFh
SPC_AUXPORT5	=0F9h ; External I/O Port P5 (S-SMP Pins 25-18) (R/W) (unused) FFh
SPC_TIMER0	=0FAh ; Timer 0 Divider (for 8000Hz clock source) (W)
SPC_TIMER1	=0FBh ; Timer 1 Divider (for 8000Hz clock source) (W)
SPC_TIMER2	=0FCh ; Timer 2 Divider (for 64000Hz clock source) (W)
SPC_COUNTER0	=0FDh ; Timer 0 Output (R)
SPC_COUNTER1	=0FEh ; Timer 1 Output (R)
SPC_COUNTER2	=0FFh ; Timer 2 Output (R)

DEBUG_P0 = SPC_PORT0
DEBUG_P2 = SPC_PORT2
;-----------------------------------------------------------------------------


;*****************************************************************************
; 0100 - 01FF	Page 1, mainly used for stack space
;*****************************************************************************
;-----------------------------------------------------------------------------


;*****************************************************************************
; 0200 - 02FF	Sample Directory
;*****************************************************************************
SampleDirectory		=0200h	; 256 bytes	(64-sample directory)
;-----------------------------------------------------------------------------


;*****************************************************************************
; 0300 - 037F   Pattern Memory
;-----------------------------------------------------------------------------
PatternMemory		=0300h	; 16*8 bytes
;-----------------------------------------------------------------------------


;*****************************************************************************
.org 380h	; program
;*****************************************************************************


;-------------------------------------------------------;---------------------
main:							;
;-------------------------------------------------------;---------------------
	call	ClearMemory				;
							;
	mov	SPC_PORT1, #0				; reset some ports
	mov	SPC_PORT2, #0				;
	mov	SPC_PORT3, #0				;
	mov	SPC_CONTROL, #0				; reset control
	mov	SPC_TIMER1, #255			; reset fade timer
							;----------------
	mov	SPC_DSPA, #DSP_DIR			; set source dir
	mov	SPC_DSPD, #HBYTE(SampleDirectory)	;
							;
	call	ResetMemory				;

;**************************************************************************************
;* setup streaming system
;**************************************************************************************
	;mov	stream_size, #0			;
	;mov	a, #0FFh			; calc streaming region address H
	;setc					;
	;sbc	a, stream_size			;
	;mov	stream_region, a		;
;--------------------------------------------------------------------------------------
	mov	a, #LBYTE(__BRK_ROUTINE__)	; set BRK/TCALL0 vector
	mov	!0FFDEH, a			;
	mov	a, #HBYTE(__BRK_ROUTINE__)	;
	mov	!0FFDFH, a			;
;--------------------------------------------------------------------------------------
	call	ResetMasterVolume
	mov	SPC_CONTROL, #%110
;----------------------------------------------------------------------
	bra	patch1			; patch for it->spc conversion ; 043eh, 043fh
					;
	call	Module_Stop		;
	mov	a, #0			;
	call	Module_Start		;
patch1:					;
;----------------------------------------------------------------------

;--------------------------------------------------------
main_loop:
;--------------------------------------------------------

	SPROC2
	call	ProcessComms
	SPROC
	call	ProcessFade
	SPROC
	call	Module_Update
	SPROC
	call	UpdatePorts

	bbc2	special_mode, skip_wavetable	; test SM_WAVETABLE

	inc	current_wt_time
	cmp	current_wt_time, wt_time
	bne	skip_wavetable

	mov	current_wt_time, #0
	mov	y, wt_cur

	SPROC
	call	WaveTable

skip_wavetable:
	bbc0	special_mode, skip_filter_sweep	; test SM_FILTERSWEEP

	inc	current_filter_time
	cmp	filter_time, current_filter_time
	bne	skip_filter_sweep

	mov	current_filter_time, #0
	SPROC
	call	FilterSweep

skip_filter_sweep:
	bbc3	special, skip_noise_freq		; test SF_NOISESWEEP

	inc	current_noise_time
	cmp	noise_time, current_noise_time
	bne	main_loop

	mov	current_noise_time, #0
	SPROC
	call	NoiseFreqSweep

skip_noise_freq:
	bra	main_loop

;--------------------------------------------------------
FilterSweep:
;--------------------------------------------------------
	call	EVOLSweep		; m0 = current channel target value
	mov	m2, #0			; m1 = current value
	mov	m3, #0			; m2 = total pos filter values
	mov	x, #7			; m3 = total neg filter values
					; m4 = tmp for converting neg to pos
_filter_sweep:				;
	push	x			;
_overflow_check:			;
	mov	a, !CBITS+x		;
	mov	SPC_DSPA, a		;
	mov	a, SPC_DSPD		;
	mov	m1, a			;
	bmi	_check_neg		;
					;
	adc	m2, m1			; adding positive values together
	bra	_dex			;
					;
_check_neg:				;
	eor	a, #0FFh		;
	inc	a			;
	mov	m4, a			;
	adc	m3, m4			; adding negative values together
					;
_dex:	dec	x			;
	bpl	_overflow_check		;
;---------------------------------------;
	pop	x			;
	bra	_channel_mode		;
;---------------------------------------;
_cm_dx:	dec	x			;
;---------------------------------------;
_channel_mode:				;
;---------------------------------------;
	mov	a, filter_values+x	; get target filter value for current channel
	cmp	a, #80h			; if value is +128, move to next channel
	beq	_cm_dx			; skipping the overflow check
					;
	mov	m0, a			; m0 = current channel target value
;---------------------------------------;
_select_channel:			;
;---------------------------------------;
	mov	a, !CBITS+x		;
	mov	SPC_DSPA, a		;
	mov	a, SPC_DSPD		;  a = current filter value
	mov	m1, a			; m1 = current filter value
	bmi	_from_neg		;
	beq	_from_z			;
					;
_from_pos:				;
	mov	a, m0			;
	bmi	_filter_dec		;
					;
_pos_to_pos:				;
	cmp	m0, m1			;
	bcc	_filter_dec		;
	cmp	m2, #7Fh		; do the total positive values exceed 126?
	bcc	_filter_inc		; if not decrease is ok (inc is negative dec)
	bra	_skip_channel		; total of positive values are too high
					;
_from_neg:				;
	mov	a, m0			;
	bpl	_filter_inc		; target is a positive value
					;
_neg_to_neg:				;
	cmp	m0, m1			;
	bcs	_filter_inc		;
	cmp	m3, #7Fh		; do the total negative values exceed 126?
	bcc	_filter_dec		; if not increase is ok (dec is negative inc)
	bra	_skip_channel		; total of positive values are too high
					;
_from_z:				;
	mov	a, m0			;
	cmp	m0, m1			; target, current value
	bpl	_filter_inc		;
					;
_filter_dec:				;
	dec	m1			; decrease current filter value
	bra	_store_new_value	;
					;
_filter_inc:				;
	inc	m1			; increase current filter value
					;
_store_new_value:			;
	mov	SPC_DSPD, m1		; store current filter value
	cmp	m0, m1			; does current filter value equal target value?
	bne	_skip_channel		; if not, keep filter sweep enable for current channel
_reset_fv:				;
	mov	a, #80h			; disable filter sweep
	mov	filter_values+x, a	; for current channel
;---------------------------------------;
_skip_channel:				;
;---------------------------------------;
	dec	x			;
	bpl	_filter_sweep		;
	ret				;

;--------------------------------------------------------
EVOLSweep:
;--------------------------------------------------------
	cmp	evol_time, #0
	beq	_end_evol
	inc	current_evol_time
	cmp	current_evol_time, evol_time
	bne	_end_evol
	mov	current_evol_time, #0
_det_dir:
	bbs1	special, _dec_evol		; test SF_EVOLINC
	cmp	current_evol, evol_max
	beq	_end_evol
	inc	current_evol
	bra	_set_evol
_dec_evol:
	cmp	current_evol, evol_min
	beq	_end_evol
	dec	current_evol
_set_evol:
	mov	a, current_evol
	bbc1	special, _skip_neg		; test SF_EVOLINC
	eor	a, #255
	inc	a
_skip_neg:
	call	Command_EchoVolume2
_end_evol:
	ret

;--------------------------------------------------------
NoiseFreqSweep:
;--------------------------------------------------------
	bbs4	special, _do_inc		; test SF_NOISEINC
_do_dec:
	dec	noise_value
	cmp	noise_value, #20h
	bcc	_check_min
	mov	noise_value, noise_sweep_start
_check_min:
	cmp	noise_value, noise_sweep_endmin
	bne	_do_noise
	bra	_check_pingpong

_do_inc:
	inc	noise_value
	cmp	noise_value, #20h
	bcc	_check_max
	mov	noise_value, noise_sweep_start
_check_max:
	cmp	noise_value, noise_sweep_endmax
	bne	_do_noise

_check_pingpong:
	bbc5	special_mode, _check_repeat		; test SM_NOISEMODE
	eor	special, #SF_NOISEINC
	bra	_do_noise
_check_repeat:
	bbc4	special_mode, _turn_nfc_off		; test SM_NOISEREPEAT
	mov	noise_value, noise_sweep_start
	bra	_do_noise

_turn_nfc_off:
	and	special, #~SF_NOISESWEEP

_do_noise:
	call	SCommand_NoiseFreq1b

check_back_later:
	ret

;--------------------------------------------------------
WaveTable:
;--------------------------------------------------------
	bbc2	special, _wt_inc	; test SF_WTDIR
					;
_wt_dec:				;
	call	_wt_swap_sample		;
	dec	y			;
	cmp	y, #DEFAULT_WT_MIN	; if minimum is reached switch direction
	beq	_wt_swap_dir		;
	bra	_wt_exit		;
					;
_wt_inc:				;
	call	_wt_swap_sample		;
	inc	y			;
	cmp	y, #DEFAULT_WT_MAX	; if maximum is reached switch direction
	beq	_wt_swap_dir		;
					;
_wt_exit:				;
	mov	wt_cur, y		;
_wt_exit2:				;
	ret				;
					;
_wt_swap_dir:				;
	eor	special, #SF_WTDIR	;
	bra	_wt_exit2		;
					;
_wt_swap_sample:			;
	mov	a, !WaveTable_L+y	;
	mov	!SampleDirectory, a	; sample start
	mov	!SampleDirectory+2, a	; loop start
	mov	a, #HBYTE(WTLoop1)	; it's all in 1axxh
	mov	!SampleDirectory+1, a	; sample start
	mov	!SampleDirectory+3, a	; loop start
	ret				;

;--------------------------------------------------------
UpdatePorts:
;--------------------------------------------------------
	mov	SPC_PORT2, STATUS
	mov	SPC_PORT3, mod_position
	ret

;--------------------------------------------------------
ResetMemory:
;--------------------------------------------------------
	mov	xfer_address, #LBYTE(MODULE)	; reset transfer address
	mov	xfer_address+1, #HBYTE(MODULE)	;
	;mov	next_sample, #0		; reset sample target
	ret

;--------------------------------------------------------
ClearMemory:
;--------------------------------------------------------
        mov     x, #0
;--------------------------------------------------------
ClearMemoryX:
;--------------------------------------------------------
        mov     a, #0
_clrmem:
        mov     (X)+, a
        cmp     x, #0F0h
        bne     _clrmem

	ret

;--------------------------------------------------------
ResetSound:
;--------------------------------------------------------
	SETDSP( DSP_KOF, 0FFh );
	SETDSP( DSP_FLG, FLG_ECEN );
	SETDSP( DSP_PMON, 0 );
	SETDSP( DSP_EVOL, 0 );
	SETDSP( DSP_EVOLR, 0 );
	SETDSP( DSP_NON, 00h );
	SETDSP( DSP_KOF, 000h ); this is weird

	mov	x, #16h
	call	ClearMemoryX
	mov	evol_max, #DEFAULT_EVOL_MAX
	mov	evol_min, #DEFAULT_EVOL_MIN
	mov	filter_time, #DEFAULT_FILTER_TIME
	mov	module_vol, #DEFAULT_MODVOL
	mov	module_fadeT, #255
	mov	noise_sweep_endmax, #DEFAULT_MAX_NOISE
	;mov	wt_max, #DEFAULT_WT_MAX
	;mov	wt_min, #DEFAULT_WT_MIN
	ret

;--------------------------------------------------------
ProcessComms:
;--------------------------------------------------------
	cmp	comms_v, SPC_PORT1	; test for command
	bne	_new_message		;
	ret				; <no message>
					;
_new_message:				;
	mov	comms_v, SPC_PORT1	; copy V
	mov	a, SPC_PORT0		; jump to message
	nop				; verify data
	cmp	a, SPC_PORT0		;
	bne	_new_message		;
	and	a, #127			; mask 7 bits
	asl	a			;
	mov	x, a			;
	jmp	[CommandTable+x]	;'
;--------------------------------------------------------
CommandTable:
;--------------------------------------------------------
	.word	CMD_LOAD		; 00h - load module
	.word	CMD_LOADE		; 01h - CMD_LOADE load sound DISABLED
	.word	CMD_NULL		; 02h - CMD_VOL set volume DISABLED
;--------------------------------------------------------
	.word	CMD_PLAY		; 03h - play
	.word	CMD_STOP		; 04h - stop
	.word	CMD_MVOL		; 05h - set module volume
	.word	CMD_FADE		; 06h - fade module volume
;--------------------------------------------------------
	;.word	CMD_NULL		; 07h - CMD_RES reset DISABLED
	;.word	CMD_NULL		; 08h - CMD_FX sound effect DISABLED
;--------------------------------------------------------
CommandRet:
;--------------------------------------------------------
	mov	SPC_PORT1, comms_v	; 07h,08h
	ret				; 08h
;--------------------------------------------------------
	.word	CMD_POS			; 09h - CMD_TEST DISABLED
	;.word	CMD_NULL		; 0ah - CMD_SSIZE set stream size DISABLED

;********************************************************
CMD_POS:
;********************************************************
	mov	a, SPC_PORT3
	call	Command_SetPosition2
	bra	CommandRet

;********************************************************
CMD_FADE:
;********************************************************
	or	STATUS, #STATUS_F
	mov	SPC_PORT2, STATUS
	mov	module_fadeT, SPC_PORT3
	mov	module_fadeR, SPC_PORT2
	bra	CommandRet

;********************************************************
CMD_STOP:
;********************************************************
	call	Module_Stop
CMD_NULL:	;*
	bra	CommandRet

;********************************************************
CMD_MVOL:
;********************************************************
	mov	module_vol, SPC_PORT3
	mov	module_fadeT, SPC_PORT3
	bra	CommandRet

;********************************************************
CMD_LOAD:
;********************************************************
	call	Module_Stop
	call	ResetMemory		; reset memory system
	call	StartTransfer

	mov	m1, #0
_wait_for_sourcen:			;
	cmp	comms_v, SPC_PORT1	;
	beq	_wait_for_sourcen	;
	mov	comms_v, SPC_PORT1	;
	cmp	SPC_PORT0, #0		; if p0 != 0:
	beq	_end_of_sources		; load source
					;
	mov	y, m1			;
	clrc				;
	adc	m1, #4			;
	call	RegisterSource		;
	call	StartTransfer		;
					;
	bra	_wait_for_sourcen	; load next source

_end_of_sources:			; if p0 == 0:
	mov	a, !SampleDirectory	; store backup of this info
	mov	wt_sample_low, a	; in case wavetable cycle is used
	mov	a, !SampleDirectory+1	;
	mov	wt_sample_high, a	;
	bra	CommandRet		;

;-------------------------------------------------------------------
RegisterSource:
;-------------------------------------------------------------------
	mov	a, xfer_address
	mov	!SampleDirectory+y, a	; sample start
	clrc
	adc	a, SPC_PORT2
	mov	!SampleDirectory+2+y, a	; loop start

	mov	a, xfer_address+1
	mov	!SampleDirectory+1+y, a	; sample start

	adc	a, SPC_PORT3
	mov	!SampleDirectory+3+y, a	; loop start

	ret

;********************************************************
CMD_LOADE:
;********************************************************
	mov	xfer_address, #LBYTE(WTLoop1)
	mov	xfer_address+1, #HBYTE(WTLoop1)
	call	StartTransfer
	bra	CommandRet

;===================================================================
StartTransfer:
;===================================================================
	mov	x, comms_v		; start transfer
	mov	y, #0			;
	mov	SPC_PORT1, x		;

;-------------------------------------------------------------------
DoTransfer:
;-------------------------------------------------------------------
	cmp	x, SPC_PORT1		; wait for data
	beq	DoTransfer		;
	mov	x, SPC_PORT1		;
					;---------------------------
	mov	a, SPC_PORT2		; copy data
	mov	[xfer_address]+y, a	;
	mov	a, SPC_PORT3		;
	mov	SPC_PORT1, x		;<- reply to snes
	inc	y			;
	mov	[xfer_address]+y, a	;
	inc	y			;
	beq	_inc_address		; catch index overflow
_cont1:	cmp	x, #0			; loop until x=0
	bne	DoTransfer		;

	mov	m0, y
	clrc
	adc	xfer_address, m0
	adc	xfer_address+1, #0
	mov	comms_v, x
	ret

_inc_address:
	inc	xfer_address+1
	bra	_cont1

;********************************************************
CMD_PLAY:
;********************************************************
	call	Module_Stop
	mov	a, SPC_PORT3
	and	STATUS, #~STATUS_P
	mov	SPC_PORT2, STATUS
	mov	SPC_PORT1, comms_v
	jmp	Module_Start

;********************************************************
;CMD_RES:	; 13 bytes
;********************************************************
	;mov	SPC_DSPA, #DSP_FLG
	;mov	SPC_DSPD, #11100000b
	;clrp
	;mov	SPC_CONTROL, #10000000b ;
	;jmp	0FFC0h

;********************************************************
; Setup echo...
;********************************************************
SetupEcho:				; STREAM_REGION = 0FFh
	mov	a, !MODULE+MOD_EDL	; ESA = stream_region - EDL*8
	beq	_skip_enable_echo	; skip all of this if echo isn't enabled
	xcn	a			; max = stream_region -1
	lsr	a			;
	mov	m0, a			;
	mov	a, #STREAM_REGION	;
	setc				;
	sbc	a, m0			;
	cmp	a, #STREAM_REGION	;
	bne	_edl_not_ss		;
	dec	a			;
_edl_not_ss:				;
	mov	SPC_DSPA, #DSP_ESA	;
	mov	SPC_DSPD, a		;

	mov	m0+1, a			; clear memory region used by echo
	mov	m0, #0			;
	mov	a, #0			;
	mov	y, #0			;
_clearmem:				;
	mov	[m0]+y, a		;
	inc	y			;
	bne	_clearmem		;
	inc	m0+1			;
	cmp	m0+1, #STREAM_REGION	;
	bne	_clearmem		;

	call	ResetEFIR		;
	call	ResetEchoFeedback	;

	mov	SPC_DSPA, #DSP_EON	; copy EON
	mov	a, !MODULE+MOD_EON	;
	mov	SPC_DSPD, a		;

	mov	SPC_DSPA, #DSP_EDL	; read old EDL, set new EDL
	mov	y, SPC_DSPD		;
	mov	a, !MODULE+MOD_EDL	;
	mov	SPC_DSPD, a		;

	;-----------------------------------------
	; delay EDL*16ms before enabling echo
	; 16384 clks * EDL
	; EDL<<14 clks
	;
	; run loop EDL<<10 times
	;-----------------------------------------
	mov	a, y			;
	asl	a			;
	asl	a			;
	inc	a			;
	mov	m0+1, a			;
	mov	m0, #0			;
_delay_16clks:				;
	cmp	a, [0]+y		;
	decw	m0			;
	bne	_delay_16clks		;

	call	ResetEchoVolume
	mov	SPC_DSPA, #DSP_FLG	; clear ECEN
	mov	SPC_DSPD, #0
	ret

_skip_enable_echo:
	mov	evol_l, #0
	mov	evol_r, #0
	ret

;********************************************************
; zerofill channel data
;********************************************************
Module_ResetChannels:
	mov	x, #ch_start
	mov	a, #0
_zerofill_ch:
	mov	(x)+, a
	cmp	x, #ch_end
	bne	_zerofill_ch
	ret

Module_Stop:
	call	ResetSound
	mov	SPC_CONTROL, #%110
	and	special, #~SF_MODACTIVE
	ret

;********************************************************
; play module...
;
; a = initial position
;********************************************************
Module_Start:
	mov	mod_position, a
	call	ResetSound
	call	Module_ResetChannels
	or	special, #SF_MODACTIVE
	mov	a, !MODULE+MOD_IS
	mov	mod_speed, a
	mov	a, !MODULE+MOD_IT
	call	Module_ChangeTempo
	mov	a, !MODULE+MOD_IV
	mov	mod_gvol, a

	mov	x, #7				;
_copy_cvolume:					; copy volume levels
	mov	a, !MODULE+MOD_CV+x		;
	mov	ch_cvolume+x, a			;
	dec	x				;
	bpl	_copy_cvolume			;

	mov	x, #7
_copy_cpan:
	mov	a, !MODULE+MOD_CP+x
	cmp	a, #65
	bcs	_cpan_surround
	mov	ch_panning+x, a
	bra	_cpan_normal

_cpan_surround:
	mov	a, #32
	mov	ch_panning+x, a
	mov	a, #CF_SURROUND
	mov	ch_flags+x, a
_cpan_normal:
	dec	x
	bpl	_copy_cpan

	call	SetupEcho

	mov	a, mod_position
	call	Module_ChangePosition

	; start timer
	mov	SPC_CONTROL, #%111

	or	STATUS, #STATUS_P
	mov	SPC_PORT2, STATUS

	;SETDSP( DSP_KOF, 0 );	// ?????? already done in reset sound
	ret

;********************************************************
; set sequence position
;
; a=position
;********************************************************
Module_ChangePosition:
	mov	y, a
_skip_pattern:
	mov	a, !MODULE+MOD_SEQU+y
	cmp	a, #254			; skip +++
	bne	_not_plusplusplus	;
	inc	y			;
	bra	_skip_pattern		;

_not_plusplusplus:
	cmp	a, #255			; restart on ---
	bne	_not_end		;
	mov	y, #0			;
	bra	_skip_pattern		;

_not_end:
	mov	mod_position, y
	mov	y, a
	mov	a, !MODULE+MOD_PTABLE_L+y
	mov	patt_addr, a
	mov	a, !MODULE+MOD_PTABLE_H+y
	mov	patt_addr+1, a
	mov	y, #0
	mov	a, [patt_addr]+y
	mov	patt_rows, a

	incw	patt_addr

	and	special, #~SF_PATTERNJUMP
	mov	mod_tick, #0
	mov	mod_row, #0
	ret

;********************************************************
; a = new BPM value
;********************************************************
Module_ChangeTempo:
	push	x
	mov	mod_bpm, a
	mov	SPC_CONTROL, #%110
	mov	x, a
	mov	y, #DEFAULT_TEMPO
	mov	a, #00h
	div	ya, x
	mov	SPC_TIMER0, a
	pop	x
	ret

;********************************************************
; process module fading
;********************************************************
ProcessFade:
	mov	a, SPC_COUNTER1
	beq	_skipfade
	or	STATUS, #STATUS_F
	mov	a, module_vol
	cmp	a, module_fadeT
	beq	_nofade
	bcc	_fadein
;--------------------------------------------
_fadeout:
;--------------------------------------------
	sbc	a, module_fadeR
	bcs	_fade_satL
	mov	module_vol, module_fadeT
	ret

_fade_satL:
	cmp	a, module_fadeT
	bcs	_fadeset
	mov	module_vol, module_fadeT
	ret
;--------------------------------------------
_fadein:
;--------------------------------------------
	adc	a, module_fadeR
	bcc	_fade_satH
	mov	module_vol, module_fadeT
	ret

_fade_satH:
	cmp	a, module_fadeT
	bcc	_fadeset
	mov	module_vol, module_fadeT
	ret

_fadeset:
	mov	module_vol, a
	ret

_nofade:
	and	STATUS, #~STATUS_F
_skipfade:
	ret

;********************************************************
; Update module playback
;********************************************************
Module_Update:
	bbc0	special, _no_tick	; test SF_MODACTCIVE
	mov	a, SPC_COUNTER0		; check for a tick
	beq	_no_tick		;

	call	Module_OnTick		;
_no_tick:				;
	ret				;

;********************************************************
; module tick!!!
;********************************************************
Module_OnTick:
	cmp	mod_tick, #0
	bne	_skip_read_pattern
	call	Module_ReadPattern

_skip_read_pattern:
	call	Module_UpdateChannels

	inc	mod_tick		; increment tick until >= SPEED
	cmp	mod_tick, mod_speed	;
	bcc	_exit_tick		;
	mov	mod_tick, #0		;
					;
	bbc7	special, _no_pattjump	; test SF_PATTERNJUMP
	mov	a, pattjump_index	;
	jmp	Module_ChangePosition	;
					;
_no_pattjump:				;
	inc	mod_row			; increment row until > PATTERN_ROWS
	beq	_adv_pos		;
	cmp	mod_row, patt_rows	;
	beq	_exit_tick		;
	bcc	_exit_tick		;
					;
_adv_pos:				;
	mov	a, mod_position		; advance position
	inc	a			;
	jmp	Module_ChangePosition	;

_exit_tick:
	ret

;********************************************************
; read pattern data
;********************************************************
Module_ReadPattern:
	mov	y, #1			; skip hints
	mov	a, [patt_addr]+y	; copy update flags
	inc	y			;
	mov	patt_update, a		;
	mov	m1, a			;
	mov	x, #0			;
	lsr	m1			; test first bit
	bcc	_no_channel_data	;
					;
_read_pattern_data:			;
	SPROC				;
	mov	a, [patt_addr]+y	; read maskvar
	inc	y			;
	mov	m0, a			;
	bbc4	m0, _skip_read_note	; test/read new note
	mov	a, [patt_addr]+y	;
	inc	y			;
	mov	ch_note+x, a		;
					;
_skip_read_note:			;
	bbc5	m0, _skip_read_instr	; test/read new instrument
	mov	a, [patt_addr]+y	;
	inc	y			;
	mov	ch_instr+x, a		;
					;
_skip_read_instr:			;
	bbc6	m0, _skip_read_vcmd	; test/read new vcmd
	mov	a, [patt_addr]+y	;
	inc	y			;
	mov	ch_vcmd+x, a		;
					;
_skip_read_vcmd:			;
	bbc7	m0, _skip_read_cmd	; test/read new cmd+param
	mov	a, [patt_addr]+y	;
	inc	y			;
	mov	ch_command+x, a		;
	mov	a, [patt_addr]+y	;
	inc	y			;
	mov	ch_param+x, a		;
					;
_skip_read_cmd:				;
	and	m0, #0Fh		; set flags (lower nibble)
	mov	a, ch_flags+x		;
	and	a, #0F0h		;
	or	a, m0			;
	mov	ch_flags+x, a		;
					;
_no_channel_data:			;
_rp_nextchannel:			;
	inc	x			; increment index
	lsr	m1			; shift out next bit
	bcs	_read_pattern_data	; process if set
	bne	_no_channel_data	; loop if bits remain (upto 8 iterations)
	;-------------------------------;
	mov	m0, y			; add offset to pattern address
	clrc				;
	adc	patt_addr, m0		;
	adc	patt_addr+1, #0		;

	bbs5	special, _swing_tempo
	ret

_swing_tempo:
	mov	a, mod_speed_bk
	bbs6	special, _swing_even
_swing_odd:
	setc
	adc	a, swing_tempo_mod
_swing_even:
	eor	special, #SF_SWINGODD
	cmp	a, #0
	beq	_no_change
	mov	mod_speed, a
_no_change:
	ret

BITS:	.byte   1,  2,  4,  8, 16, 32, 64,128
CBITS:	.byte  15, 31, 47, 63, 79, 95,111,127

;********************************************************
; update module channels...
;********************************************************
Module_UpdateChannels:
	mov	x, #0
	mov	a, patt_update

_muc_loop:
	lsr	a
	push	a
	mov	a, #0
	rol	a
	mov	t_hasdata, a

	call	Module_UpdateChannel

	pop	a
	inc	x
	cmp	x, #8
	bne	_muc_loop

	ret

;********************************************************
; update module channel
;********************************************************
Module_UpdateChannel:
	SPROC

	;--------------------------------------
	; get data pointers
	;--------------------------------------
	mov	y, ch_instr+x
	dec	y
	mov	a, !MODULE+MOD_ITABLE_L+y
	mov	p_instr, a
	mov	a, !MODULE+MOD_ITABLE_H+y
	mov	p_instr+1, a

	mov	t_flags, #0
	cmp	t_hasdata, #0
	beq	_muc_nopatterndata

	call	Channel_ProcessData
	bra	_muc_pa

_muc_nopatterndata:
	call	Channel_CopyTemps

_muc_pa:
	call	Channel_ProcessAudio
	ret

;********************************************************	
Channel_ProcessData:
;********************************************************
	cmp	mod_tick, #0		; skip tick0 processing on other ticks
	bne	_cpd_non0		;
					;
	mov	a, ch_flags+x		;
	mov	m6, a			;
	bbc0	m6, _cpd_no_note	; test for note
					;
	mov	a, ch_note+x		;
	cmp	a, #254			; test notecut/noteoff
	beq	_cpd_notecut		;
	bcs	_cpd_noteoff		;
					;
_cpd_note:				; don't start note on glissando
	bbc3	m6, _cpdn_test_for_glis	;
	mov	a, ch_command+x		;
	cmp	a, #7			;
	beq	_cpd_note_next		;
					;
_cpdn_test_for_glis:			;
	call	Channel_StartNewNote	;
	bra	_cpd_note_next		;
					;
_cpd_notecut:				;notecut:
	mov	a, #0			; cut volume
	mov	ch_volume+x, a		;
	and	m6, #~CF_NOTE		; clear note flag
	bra	_cpd_note_next		;
					;
_cpd_noteoff:				;noteoff:
	and	m6, #~(CF_NOTE|CF_KEYON); clear note and keyon flags
					;
_cpd_note_next:				;
	bbc1	m6, _cpdn_no_instr	; apply instrument SETPAN
	mov	y, #INS_SETPAN		;
	mov	a, [p_instr]+y		;
	bmi	_cpdi_nsetpan		;
	mov	ch_panning+x, a		;
					;
_cpdi_nsetpan:				;
	mov	y, ch_sample+x		; apply sample SETPAN
;	beq	_cpdi_nosample		;
	mov	a, !MODULE+MOD_STABLE_L+y	;
	mov	m0, a			;
	mov	a, !MODULE+MOD_STABLE_H+y	;
	mov	m0+1, a			;
	mov	y, #SAMP_DVOL		; copy default volume
	mov	a, [m0]+y		;
	mov	ch_volume+x, a		;
	mov	y, #SAMP_SETPAN		;
	mov	a, [m0]+y		;
	bmi	_cpdi_nsetpan_s		;
	mov	ch_panning+x, a		;
_cpdi_nsetpan_s:			;
_cpdi_nosample:				;
_cpdn_no_instr:				;
	and	m6, #~CF_NOTE		;
					;
_cpd_no_note:				;
	mov	a, m6			; save flag mods
	mov	ch_flags+x, a		;
					;
	and	a, #(CF_NOTE|CF_INSTR)	; test for note or instrument
	beq	_no_note_or_instr	;
					;
	call	Channel_ResetVolume	; and reset volume things
					;
_no_note_or_instr:			;
_cpd_non0:				; nonzero ticks: just update audio
	SPROC				;
					;
	mov	a, ch_flags+x		; test and process volume command
	and	a, #CF_VCMD		;
	beq	_skip_vcmd		;

	call	Channel_ProcessVolumeCommand

_skip_vcmd:				;
	SPROC				;
	call	Channel_CopyTemps	; copy t values
					;
	mov	a, ch_flags+x		; test and process command
	and	a, #CF_CMD		;
	beq	_skip_cmd		;
					;
	call	Channel_ProcessCommand	;

_skip_cmd:
	ret

;********************************************************
Channel_CopyTemps:
;********************************************************
	mov	a, ch_pitch_l+x		; prepare for effects processing.....
	mov	y, ch_pitch_h+x		;
	movw	t_pitch, ya		;
	mov	a, ch_volume+x		;
	mov	y, ch_panning+x		;
	movw	t_volume, ya		;
	;mov	t_sampoff, #0		;

	ret

;********************************************************
Channel_StartNewNote:
;********************************************************
	mov	a, ch_note+x		; pitch = note * 64
	mov	y, #64			;
	mul	ya			;
	mov	ch_pitch_l+x, a		;
	mov	ch_pitch_h+x, y		;

	mov	a, ch_instr+x		; test for instrument and copy sample!
	beq	_csnn_no_instr		;
	mov	y, #INS_SAMPLE		;
	mov	a, [p_instr]+y		;
	mov	ch_sample+x, a		;

_csnn_no_instr:
	or	t_flags, #TF_START	; set start flag
	ret

;********************************************************
Channel_ResetVolume:
;********************************************************
	mov	a, #255			; reset fadeout
	mov	ch_fadeout+x, a		;----------------
	mov	a, #0			; reset envelope
	mov	ch_env_node+x, a	;
	mov	ch_env_tick+x, a	;----------------
	mov	ch_cmem+x, a		; reset CMem
					;----------------
	mov	a, ch_flags+x		; set KEYON
	or	a, #CF_KEYON		; clear FADE
	and	a, #~CF_FADE		;
	mov	ch_flags+x, a		;----------------
	ret

;********************************************************
Channel_ProcessAudio:
;********************************************************
	SPROC					;
	mov	y, ch_sample+x			; m5 = sample address
;	beq	_cpa_nsample			;
	mov	a, !MODULE+MOD_STABLE_L+y	;
	mov	m5, a				;
	mov	a, !MODULE+MOD_STABLE_H+y	;
	mov	m5+1, a				;
						;
_cpa_nsample:					;
	call	Channel_ProcessEnvelope		;
						;
	mov	a, ch_flags+x			; process FADE
	and	a, #CF_FADE			;
	beq	_skip_fade			;
	mov	a, ch_fadeout+x			;
	setc					;
	mov	y, #INS_FADEOUT			;
	sbc	a, [p_instr]+y			;
	bcs	_subfade_noverflow		;	
	mov	a, #0				;
_subfade_noverflow:				;
	mov	ch_fadeout+x, a			;
_skip_fade:					;
	mov	a, !BITS+x
	and	a, #0
	bne	_sfx_override

	mov	a, t_flags			; exit if 'note delay' is set
	and	a, #TF_DELAY			;
	beq	_cpa_ndelay			;
_sfx_override:
	ret					;
_cpa_ndelay:					;

	;----------------------------------------
	; COMPUTE VOLUME:
	; V*CV*SV*GV*VEV*FADE
	; m0 = result (0..255)
	;----------------------------------------

	mov	y, #INS_GVOL
	mov	a, [p_instr]+y
	push	a
	mov	y, #SAMP_GVOL
	mov	a, [m5]+y
	push	a

	mov	a, t_volume			; y = 8-BIT VOLUME
	asl	a				;
	asl	a				;		
	bcc	_cpa_clamp_vol			;	
	mov	a, #255				;
_cpa_clamp_vol:					;
	mov	y, a				;

	mov	a, ch_cvolume+x			; *= CV
	asl	a				;
	asl	a
	bcs	_calcvol_skip_cv		;
	mul	ya				;
_calcvol_skip_cv:				;

	pop	a				; *= SV
	asl	a				;
	asl	a
	bcs	_calcvol_skip_sv		;
	mul	ya				;
_calcvol_skip_sv:				;

	pop	a				;
	asl	a				;
	bcs	_calcvol_skip_iv		;
	mul	ya				;
_calcvol_skip_iv:

	mov	a, mod_gvol			; *= GV
	asl	a				;
	bcs	_calcvol_skip_gvol		;
	mul	ya				;
_calcvol_skip_gvol:				;

	mov	a, t_env			; *= VEV
	mul	ya				;

	mov	a, ch_fadeout+x			; *= FADE
	mul	ya				;

	mov	a, module_vol
	mul	ya

	mov	a, y				; store 7bit result
	lsr	a				; 
	mov	m2, a

	cmp	t_flags, #80h
	bcs	_dont_hack_gain
	cmp	a, #0
	bne	_gain_not_zero			; map value 0 to fast linear decrease
	mov	a, #%10011100			; (8ms)
_gain_not_zero:					;
	cmp	a, #126				; map value 126 to fast linear increase
	bne	_gain_not_max			; (8ms)
	mov	a, #%11011100			;
_gain_not_max:					;
	mov	m2, a				;
_dont_hack_gain:
	mov	a, ch_flags+x			; [KFF] added in pitchmod
	and	a, #128				;
	beq	panning				;
	mov	m1, #0				;
	mov	m1+1, #0			;
	bra	_cpa_nsurround			;

panning:
	;---------------------------------------
	; compute PANNING
	;---------------------------------------
	mov	a, t_panning			; a = panning 0..127	
	asl	a				;	
	bpl	_clamppan			;
	dec	a				;
_clamppan:					;	
	mov	m1+1, a				; store panning (volume) levels
	eor	a, #127				;
	mov	m1, a				;

	mov	a, ch_flags+x			; apply surround (R = -R)
	and	a, #CF_SURROUND			;
	beq	_cpa_nsurround			;
	eor	m1+1, #255			;
	inc	m1+1				;
_cpa_nsurround:					;

	;---------------------------------------
	; compute PITCH
	;---------------------------------------
	cmp	x, #1

	mov	y, #SAMP_PITCHBASE		; m3 = t_pitch PITCHBASE
	mov	a, [m5]+y			;
	clrc					;
	adc	a, t_pitch_l			;
	mov	m3, a				;
	inc	y				;
	mov	a, [m5]+y			;
	adc	a, t_pitch_h			;
	mov	m3+1, a				;
	bpl	_positive_oct			;

	; Negative octave handling by KungFuFurby 12/16/15 - 12/17/15
	; Negative octave detected!
	; This code ensures that the SPC700 can handle lower pitches than
	; what SNESMod normally supports.

	eor	a, #0FFh			; Prevent glitched
	mov	y, a				; division read.
	mov	a, !LUT_DIV3+y			; m0 = octave
	eor	a, #0FFh			;
	mov	m0, a				;
	bra	_oct_cont

_positive_oct:
	mov	y, a				; m0 = octave
	mov	a, !LUT_DIV3+y			;
	mov	m0, a				;
_oct_cont:
	asl	a				; m3 -= (oct*3) << 8
	clrc					; Safety clear for negative
	adc	a, m0				; octaves
	mov	m0+1, a				;
	mov	a, m3+1				;
	setc					;
	sbc	a, m0+1				;

	asl	m3				; m3 = m3*2 + LUT_FTAB base
	rol	a				;
	adc	m3, #LBYTE(LUT_FTAB)		;
	adc	a, #HBYTE(LUT_FTAB)		; 
	mov	m3+1, a				;

	mov	y, #0				; read ftab[f]
	mov	a, [m3]+y			;
	mov	m4, a				;
	inc	y				;
	mov	a, [m3]+y			;
	push	a				;

	mov	a, #8				; y = 8-oct
	setc					;
	sbc	a, m0				;
	mov	y, a				;

	pop	a				; a,m4 = ftab value
	beq	_no_pitch_shift			; skip shift if 0
						;
_cont_pitch_shift:
	lsr	a				; shift by (8-oct)
	ror	m4				;
	dbnz	y, _cont_pitch_shift		; (thanks KungFuFurby)

	; WARNING: More than eight pitch shifts are possible,
	; so the code has been compressed to a mere three lines
	; Only problem will be with glitched values out of range.

_no_pitch_shift:
	mov	m4+1, a

	;----------------------------------------
	; m1 = VOL/VOLR
	; m2 = GAIN
	; m4 = PITCH
	;----------------------------------------
	mov	a, x				; DSPA = voices[x]
	xcn	a				;
	mov	SPC_DSPA, a			;
						;------------------------------
	mov	a, t_flags			; test for KEYON
	and	a, #TF_START			;
	beq	_cpa_nstart			;------------------------------
						;keyon:
	mov	y, #SAMP_DINDEX			; set SRCN
	mov	a, [m5]+y			;
	or	SPC_DSPA, #DSPV_SRCN		;
	mov	SPC_DSPD, a			;------------------------------
	;----------------------------------------
	; **TODO: SAMPLE OFFSET
	;----------------------------------------
	mov	SPC_DSPA, #DSP_KON		; set KON bit
	mov	a, !BITS+x			;
	mov	SPC_DSPD, a			;------------------------------
	mov	a, x				; restore DSPA = voices[x]
	xcn	a				;
	mov	SPC_DSPA, a			;
;------------------------------------------------
_cpa_nstart:
;------------------------------------------------
	mov	SPC_DSPD, m1			; set VOLUME
	inc	SPC_DSPA			;
	mov	SPC_DSPD, m1+1			;
	inc	SPC_DSPA			;------------------------------
	mov	SPC_DSPD, m4			; set PITCH
	inc	SPC_DSPA			;
	mov	SPC_DSPD, m4+1			;
	inc	SPC_DSPA			;
	inc	SPC_DSPA			;------------------------------
						;
	;cmp	x, #MAX_ADSR_CHANNELS		; only channels 0-3 may use ADSR
	;bcs	_ch_direct_gain			;
	;mov	a, ch_ad+x			; test to see if ADSR has been
	;cmp	a, #ADSR			; set for channel
	;bcs	_ch_adsr			;
						;
_ch_direct_gain:				;
	mov	SPC_DSPD, #00h			; disable ADSR
	or	SPC_DSPA, #07h			; set GAIN [default]
	mov	SPC_DSPD, m2			;------------------------------
						;
	;----------------------------------------
	; **TODO: RESTORE SAMPLE OFFSET
	;----------------------------------------
						;
_end_ch_process_audio:				;
	SPROC					;
_env_quit:					;
	ret					;
						;
_ch_adsr:					;
	;mov	SPC_DSPD, a			; store attack and decay rate
	;inc	SPC_DSPA			;
	;mov	a, ch_sr+x			;
	;mov	SPC_DSPD, a			; store sustain rate and level
	;bra	_end_ch_process_audio		;

;********************************************************
Channel_ProcessEnvelope:
;********************************************************
	mov	a, t_flags			; exit if 'note delay' is set
	and	a, #TF_DELAY			;
	bne	_env_quit			;

	mov	y, #INS_ENVLEN			; test for envelope
	mov	a, [p_instr]+y			;
	mov	m0, a				;
	bne	_envelope_valid			;if no envelope:
	mov	t_env, #255			; set to max

	mov	a, ch_flags+x			; start fade on KEYOFF
	and	a, #CF_KEYON			;
	beq	_env_quit			;
	bra	_env_setfade			;
						;
_envelope_valid:
	mov	a, ch_env_node+x		; read envelope node data

	clrc					; m1/m2
	adc	a, #INS_ENVDATA			;
	mov	y, a				;
	mov	a, [p_instr]+y			;
	mov	m1, a				;
	inc	y				;
	mov	a, [p_instr]+y			;
	mov	m1+1, a				;
	inc	y				;
	mov	a, [p_instr]+y			;
	mov	m2, a				;
	inc	y				;
	mov	a, [p_instr]+y			;
	mov	m2+1, a				;

	SPROC
	mov	a, ch_env_tick+x		; test zero/nonzero tick
	bne	_env_nonzero_tick		;
						;ZEROTICK:
	mov	a, m1				; copy Y level
	mov	ch_env_y_h+x, a			;
	mov	a, #0				;
	mov	ch_env_y_l+x, a			;
	bra	_env_zerotick			;

_env_nonzero_tick:				;NONZERO:
	mov	a, ch_env_y_l+x
	clrc
	adc	a, m2
	mov	ch_env_y_l+x, a
	mov	a, ch_env_y_h+x
	adc	a, m2+1

	bpl	_catch_negative			; clamp result 0.0->64.0
	mov	a, #0				;
	mov	ch_env_y_h+x, a			;
	mov	ch_env_y_l+x, a			;
	bra	_env_zerotick			;
						;
_catch_negative:				;
	cmp	a, #64				;
	bcc	_catch_plus			;
	mov	a, #64				;
	mov	ch_env_y_h+x, a			;
	mov	a, #0				;
	mov	ch_env_y_l+x, a			;
	bra	_env_zerotick			;
						;
_catch_plus:					;
	mov	ch_env_y_h+x, a			;

_env_zerotick:
	mov	a, ch_env_y_l+x			; t_env = env << 2
	mov	m1, a				;
	mov	a, ch_env_y_h+x			;
	asl	m1				;
	rol	a				;
	asl	m1				;
	rol	a				;

	bcc	_env_shift_clamp		; clamp to 255
	mov	a, #255				;
_env_shift_clamp:				;
	mov	t_env, a			;

	mov	a, ch_flags+x			; don't advance if "keyon" and node=sustain
	and	a, #CF_KEYON			;
	beq	_env_nsustain			;
	mov	y, #INS_ENVSUS			;
	mov	a, [p_instr]+y			;
	cmp	a, ch_env_node+x		;
	bne	_env_nsustain			;
	ret					;

_env_setfade:					;
	mov	a, ch_flags+x			;
	or	a, #CF_FADE			;
	mov	ch_flags+x, a			;
	ret
						;
_env_nsustain:					;
	inc	ch_env_tick+x			; increment tick
	mov	a, ch_env_tick+x		;
	cmp	a, m1+1				; exit if < duration
	bcc	_env_exit			;

	mov	a, #0				; reset tick
	mov	ch_env_tick+x, a		;

	mov	y, #INS_ENVLOOPEND		; turn on FADE if keyoff and loop
	mov	a, [p_instr]+y			;
	cmp	a, #255				;
	beq	_env_no_loop			;
	mov	a, ch_flags+x			;	
	and	a, #CF_KEYON			;	
	bne	_env_no_fade			;	
	mov	a, ch_flags+x			;
	or	a, #CF_FADE			;
	mov	ch_flags+x, a			;

_env_no_fade:					;
	mov	a, ch_env_node+x		; test for loop point
;	mov	y, #INS_ENVLOOPEND		;
	cmp	a, [p_instr]+y			;
	bne	_env_loop_test			;
	mov	y, #INS_ENVLOOPST		;
	mov	a, [p_instr]+y			;
	mov	ch_env_node+x, a		;
_env_exit:
	ret

_env_loop_test:
_env_no_loop:
	mov	a, ch_env_node+x		;
	setc					; suspicious...
	sbc	m0, #4				;
	cmp	a, m0				; test for envelope end
	beq	_env_setfade			;
	clrc					; increment node
	adc	a, #4				;
	mov	ch_env_node+x, a		;
	ret

;********************************************************
Channel_ProcessVolumeCommand:
;********************************************************
	mov	a, ch_volume+x
	mov	y, ch_vcmd+x
	mov	m0, y
	call	do_vcmd
	mov	ch_volume+x, a
	ret

do_vcmd:
	cmp	y, #65
	bcc	vcmd_setvol
	cmp	y, #75
	bcc	vcmd_finevolup
	cmp	y, #85
	bcc	vcmd_finevoldown
	cmp	y, #95
	bcc	vcmd_volup
	cmp	y, #105
	bcc	vcmd_voldown
	cmp	y, #193
	bcs	vcmd_invalid
	cmp	y, #128
	bcs	vcmd_pan
vcmd_invalid:
	ret

;--------------------------------------------------------
; 00-64 set volume
;--------------------------------------------------------
vcmd_setvol:
	cmp	mod_tick, #0		; a = volume
	bne	exit_vcmd		;
	mov	a, y			;
exit_vcmd:				;
	ret				;

;--------------------------------------------------------
; 65-74 fine vol up
;--------------------------------------------------------
vcmd_finevolup:
	sbc	m0, #65			; m0 = rate (-1)
	cmp	mod_tick, #0
	bne	exit_vcmd

_vcmd_add_sat64:
	adc	a, m0			; a += rate (+1)
	cmp	a, #DEFAULT_VOL_SAT+1	; saturate to DEFAULT_VOL_SAT
	bcc	exit_vcmd		;
	mov	a, #DEFAULT_VOL_SAT	;
	ret				;

;--------------------------------------------------------
; 75-84 fine vol down
;--------------------------------------------------------
vcmd_finevoldown:
	sbc	m0, #75-1		; m0 = rate [carry is cleared]
	cmp	mod_tick, #0
	bne	exit_vcmd

_vcmd_sub_sat0:	
	sbc	a, m0			; a -= rate
	bcs	exit_vcmd		; saturate lower bound to 0
	mov	a, #0			;
	ret				;

;--------------------------------------------------------
; 85-94 vol up
;--------------------------------------------------------
vcmd_volup:
	sbc	m0, #85			; m0 = rate (-1)
	cmp	mod_tick, #0
	beq	exit_vcmd
	bra	_vcmd_add_sat64

;--------------------------------------------------------
; 95-104 vol down
;--------------------------------------------------------
vcmd_voldown:
	sbc	m0, #95-1
	cmp	mod_tick, #0
	beq	exit_vcmd
	bra	_vcmd_sub_sat0

;--------------------------------------------------------
; 128-192 set pan
;--------------------------------------------------------
vcmd_pan:
	cmp	mod_tick, #0		; set panning
	bne	exit_vcmd		;
	push	a			;
	mov	a, y			;
	sbc	a, #128			;
	call	Command_SetPanningb	; Bugfix by KungFuFurby 12/20/15
	;mov	ch_panning+x, a		;@@??
	pop	a			;
	ret				;

command_memory_map:	
	.byte 00h, 00h, 00h, 10h, 20h, 20h, 30h, 70h, 00h
	;       A    B    C    D    E    F    G    H    I
	.byte 40h, 10h, 10h, 00h, 10h, 50h, 10h, 80h, 70h
	;       J    K    L    M    N    O    P    Q    R
	.byte 60h, 00h, 70h, 00h, 10h, 00h, 70h, 00h
	;       S    T    U    V    W    X    Y    Z

;********************************************************
Channel_ProcessCommandMemory:
;********************************************************
	mov	y, ch_command+x
	mov	a, !command_memory_map-1+y
	beq	_cpc_quit		; 0 = no memory!
	mov	m0, x
	clrc
	adc	a, m0
	mov	y, a
	cmp	y, #70h			; <7 : single param
	bcc	_cpcm_single		;
;--------------------------------------------------------
_cpcm_double:				; >=7: double param
;--------------------------------------------------------
	mov	a, !PatternMemory-10h+y
	mov	m0, a
	mov	a, ch_param+x
	cmp	a, #10h
	bcc	_cpcmd_h_clr
	push	a
	and	m0, #0Fh
	or	a, m0
	mov	m0, a
	pop	a
_cpcmd_h_clr:
	and	a, #0Fh
	beq	_cpcmd_l_clr
	and	m0, #0F0h
	or	a, m0
	mov	m0, a
_cpcmd_l_clr:
	mov	a, m0
	mov	ch_param+x, a
	mov	!PatternMemory-10h+y, a
	ret

;--------------------------------------------------------
_cpcm_single:
;--------------------------------------------------------
	mov	a, ch_param+x
	beq	_cpcms_clear
	mov	!PatternMemory-10h+y, a
	ret
_cpcms_clear:
	mov	a, !PatternMemory-10h+y
	mov	ch_param+x, a	
_cpc_quit:
	ret

;********************************************************
Channel_ProcessCommand:
;********************************************************
	mov	a, ch_command+x		; exit if cmd = 0 
	beq	_cpc_quit		;

	cmp	mod_tick, #0		; process MEMORY on t0
	bne	_cpc_nott0		;
	call	Channel_ProcessCommandMemory

_cpc_nott0:
	mov	y, ch_command+x		; setup jump address
	mov	a, !CMD_JUMPTABLE_L-1+y	;
	mov	!cpc_jump+1, a		;
	mov	a, !CMD_JUMPTABLE_H-1+y	;
	mov	!cpc_jump+2, a		;
	mov	a, ch_param+x		; preload data
	mov	y, mod_tick		;

	;-------------------------------
	; a = param
	; y = tick
	; Z = tick=0
	;-------------------------------
	
cpc_jump:
	jmp	$0011
	
; note: tasm has some kind of bug that removes the 16th character
; in macro args (...?)
;-----------------------------------------------------------------------
CMD_JUMPTABLE_L:
;-----------------------------------------------------------------------
	.byte	LBYTE(Command_SetSpeed)			; Axx
	.byte	LBYTE(Command_SetPositXion)		; Bxx
	.byte	LBYTE(Command_PatternBXreak)		; Cxx
	.byte	LBYTE(Command_VolumeSlXide)		; Dxy
	.byte	LBYTE(Command_PitchSliXdeDown)		; Exy
	.byte	LBYTE(Command_PitchSliXdeUp)		; Fxy
	.byte	LBYTE(Command_GlissandXo)		; Gxx
	.byte	LBYTE(Command_Vibrato)			; Hxy
	.byte	LBYTE(SCommand_Null)			; Ixx Tremor
	.byte	LBYTE(Command_Arpeggio)			; Jxy
	.byte	LBYTE(Command_VolumeSlXideVibrato)	; Kxy
	.byte	LBYTE(SCommand_Null)			; Lxx VolumeSlideGliss
	.byte	LBYTE(Command_SetChannXelVolume)	; Mxx
	.byte	LBYTE(Command_ChannelVoolumeSlide)	; Nxx
	.byte	LBYTE(SCommand_Null)			; Oxx SampleOffset
	.byte	LBYTE(Command_PanningSXlide)		; Pxy
	.byte	LBYTE(Command_RetriggeXrNote)		; Qxy
	.byte	LBYTE(Command_Tremolo)			; Rxt
	.byte	LBYTE(Command_Extended)			; Sxy
	.byte	LBYTE(Command_Tempo)			; Txy
	.byte	LBYTE(SCommand_Null)			; Uxx Fine Vibrato
	.byte	LBYTE(Command_SetGlobaXlVolume)		; Vxx
	.byte	LBYTE(Command_GlobalVoXlumeSlide)	; Wxy
	.byte	LBYTE(Command_SetPanniXng)		; Xxx
	.byte	LBYTE(Command_PanbrellXo)		; Yxx
	.byte	LBYTE(Command_SetParamXeter)		; Zxx
;-----------------------------------------------------------------------
CMD_JUMPTABLE_H:
;-----------------------------------------------------------------------
	.byte	HBYTE(Command_SetSpeed)			; Axx
	.byte	HBYTE(Command_SetPositXion)		; Bxx
	.byte	HBYTE(Command_PatternBXreak)		; Cxx
	.byte	HBYTE(Command_VolumeSlXide)		; Dxy
	.byte	HBYTE(Command_PitchSliXdeDown)		; Exy
	.byte	HBYTE(Command_PitchSliXdeUp)		; Fxy
	.byte	HBYTE(Command_GlissandXo)		; Gxx
	.byte	HBYTE(Command_Vibrato)			; Hxy
	.byte	HBYTE(SCommand_Null)			; Ixx Tremor
	.byte	HBYTE(Command_Arpeggio)			; Jxy
	.byte	HBYTE(Command_VolumeSlXideVibrato)	; Kxx
	.byte	HBYTE(SCommand_Null)			; Lxx VolumeSlideGliss
	.byte	HBYTE(Command_SetChannXelVolume)	; Mxx
	.byte	HBYTE(Command_ChannelVoolumeSlide)	; Nxx
	.byte	HBYTE(SCommand_Null)			; Oxx VolumeSlideGliss
	.byte	HBYTE(Command_PanningSXlide)		; Pxy
	.byte	HBYTE(Command_RetriggeXrNote)		; Qxy
	.byte	HBYTE(Command_Tremolo)			; Rxy
	.byte	HBYTE(Command_Extended)			; Sxy
	.byte	HBYTE(Command_Tempo)			; Txy
	.byte	HBYTE(SCommand_Null)			; Uxx FineVibrato
	.byte	HBYTE(Command_SetGlobaXlVolume)		; Vxx
	.byte	HBYTE(Command_GlobalVoXlumeSlide)	; Wxy
	.byte	HBYTE(Command_SetPanniXng)		; Xxx
	.byte	HBYTE(Command_PanbrellXo)		; Yxx
	.byte	HBYTE(Command_SetParamXeter)		; Zxx

;=======================================================================
Command_SetSpeed:
;=======================================================================
	bne	cmd_exit1			;on tick0:
	cmp	a, #0				; if param != 0
	beq	cmd_exit1			; mod_speed = param
	mov	mod_speed, a			;
cmd_exit1:					;
	ret					;
						;
;=======================================================================
Command_SetPosition:
;=======================================================================
	bne	cmd_exit1			;on tick0:
Command_SetPosition2:				;
	mov	pattjump_index, a		; set jump index
	or	special, #SF_PATTERNJUMP	;
	bra	_enable_pattjump		;
						;
;=======================================================================
Command_PatternBreak:
;=======================================================================
	; nonzero params are not supported	;
	bne	cmd_exit1			;on tick0:
	mov	pattjump_index, mod_position	; index = position+1
	inc	pattjump_index			;
_enable_pattjump:				;
	or	special, SF_PATTERNJUMP		; enable pattern jump(break)
	ret					;
						;
;=======================================================================
Command_VolumeSlideVibrato:
;=======================================================================
	call	Command_Vibrato

	mov	a, ch_param+x
	mov	y, mod_tick
;=======================================================================
Command_VolumeSlide:				; Dxy
;=======================================================================
	mov	m0, t_volume			; slide volume
	mov	m0+1, #DEFAULT_VOL_SAT		;
	call	DoVolumeSlide			;
	mov	t_volume, a			;
	mov	ch_volume+x, a			;
	ret					;

;=======================================================================
Command_PitchSlideDown:
;=======================================================================
	call	PitchSlide_Load			; m0 = slide amount
	movw	ya, t_pitch			; pitch -= m0
	subw	ya, m0				;
	bmi	_exx_zero			; saturate lower to 0
_ps:	movw	t_pitch, ya			;
	mov	ch_pitch_l+x, a			;
	mov	ch_pitch_h+x, y			;
	ret					;
;---------------------------------------------------------------------
_exx_zero:
;---------------------------------------------------------------------
	mov	a, #0				; zero pitch
	mov	y, #0				;
	movw	t_pitch, ya			;
	mov	ch_pitch_l+x, a			;
	mov	ch_pitch_h+x, a			;
	ret					;
;=======================================================================
Command_PitchSlideUp:
;=======================================================================
	call	PitchSlide_Load			; m0 = slide amount
	movw	ya, t_pitch			;
	addw	ya, m0				;
	cmp	y, #01Ah			;
	bcs	_fxx_max			; clamp upper bound to 1A00H
	bra	_ps
;-----------------------------------------------------------------------
_fxx_max:
;-----------------------------------------------------------------------
	mov	y, #01Ah			; max pitch
	mov	a, #0				;
	movw	t_pitch, ya			;
	mov	ch_pitch_l+x, a			;
	mov	ch_pitch_h+x, y			;
	ret					;
;=======================================================================
Command_Glissando:
;=======================================================================
	beq	cmd_exit1			; on tickn:

	call	Amult4_M0			; m0 = xx*4 (slide amount)

	mov	a, ch_note+x			; m1 = slide target
	mov	m1, #0				;
	lsr	a				;
	ror	m1				;
	lsr	a				;
	ror	m1				;
	mov	m1+1, a				;

	movw	ya, t_pitch			; test slide direction
	cmpw	ya, m1				;
	bcc	_gxx_slideup
;-----------------------------------------------
_gxx_slidedown:
;-----------------------------------------------
	subw	ya, m0				; subtract xx*4 from pitch
	bmi	_gxx_set			; saturate lower to target pitch
	cmpw	ya, m1				;
	bcc	_gxx_set			;
_gxx_set2:					;
	movw	t_pitch, ya			;
	mov	ch_pitch_l+x, a			;
	mov	ch_pitch_h+x, y			;
	ret					;
;-----------------------------------------------
_gxx_slideup:
;-----------------------------------------------
	addw	ya, m0				; add xx*4 to pitch
	cmpw	ya, m1				; saturate upper to target pitch
	bcs	_gxx_set			;
	bra	_gxx_set2			;
;-----------------------------------------------
_gxx_set:					; pitch = target
;-----------------------------------------------
	movw	ya, m1				;
	bra	_gxx_set2			;

;=======================================================================
Command_Panbrello:
;=======================================================================
	or	special_mode, #SM_PANBRELLO
	bra	Command_Vibrato

;=======================================================================
Command_Tremolo:
;=======================================================================
	or	special_mode, #SM_TREMOLO
;=======================================================================
Command_Vibrato:
;=======================================================================
	mov	a, #70h
	mov	m0, x
	clrc
	adc	a, m0
	mov	y, a
	mov	a, !PatternMemory-10h+y

	mov	m0, a
	and	m0, #0Fh

	lsr	a				; cmem += x*4
	lsr	a				;
	and	a, #111100b			;
	clrc					;
	adc	a, ch_cmem+x			;
	mov	ch_cmem+x, a			;

	mov	y, a				; a = sine[cmem]

	mov	a, ch_vib_wav+x
	mov	m1, a				; m1 = waveform value
	mov	a, ch_env_vib+x			; a = vibrato waveform type

	cmp	a, #1
	beq	_hxx_ramp_down
	cmp	a, #2
	beq	_hxx_sq
	cmp	a, #4
	beq	_hxx_tri
	cmp	a, #5
	beq	_hxx_ramp_up
	cmp	a, #6
	beq	_hxx_sq2
;-----------------------------------------------
_hxx_sine:					; S30
;-----------------------------------------------;
	cmp	y, #80h				;
	bcs	_hxx_sine_neg			;
	mov	a, !IT_FineSineData+y		; copy positive values
	bra	_hxx_bpl			;
						;
_hxx_sine_neg:					;
	mov	a, y				; IT_FineSineData is only 128
	clrc					; bytes long, once the end is
	sbc	a, #127				; reached reset to the start
	mov	y, a				;
	mov	a, !IT_FineSineData+y		; copy positive values
	eor	a, #0FFh			; ...and make them negative
	inc	a				;
	bra	_hxx_bpl			;
;----------------------------------------------- 
_hxx_ramp_down:					; S31
;-----------------------------------------------
	cmp	y, #0
	bne	_hxx_chk_ramp
_hxx_res_ramp:
	mov	m1, #DEFAULT_RAMP_POS
_hxx_chk_ramp:
	cmp	m1, #DEFAULT_RAMP_NEG
	beq	_hxx_res_ramp
_hxx_dec_ramp:
	bra	_dec_m1_hxx_bpl
;-----------------------------------------------
_hxx_sq:					; S32
;-----------------------------------------------
	cmp	y, #80h
	bcs	_hxx_neg_sq
	bra	_hxx_pos_sq
;-----------------------------------------------
;_hxx_rand:					; S33 - unimplemented
;-----------------------------------------------
_hxx_tri:					; S34
;-----------------------------------------------
	cmp	y, #0C0h
	bcs	_inc_m1_hxx_bpl
	cmp	y, #040h
	bcs	_dec_m1_hxx_bpl
;-----------------------------------------------
_hxx_sq2:					; S36
;-----------------------------------------------
	cmp	y, #0C0h
	bcs	_hxx_pos_sq
	cmp	y, #80h
	bcs	_hxx_neg_sq
	cmp	y, #40h
	bcs	_hxx_pos_sq
;-----------------------------------------------
_hxx_neg_sq:
;-----------------------------------------------
	mov	a, #DEFAULT_SQ_NEG
	bra	_hxx_bpl
;-----------------------------------------------
_hxx_pos_sq:
;-----------------------------------------------
	mov	a, #DEFAULT_SQ_POS
	bra	_hxx_bpl
;-----------------------------------------------
_hxx_ramp_up:					; S35
;-----------------------------------------------
	cmp	y, #0
	bne	_hex_chk_ramp2
_hex_res_ramp2:
	mov	m1, #DEFAULT_RAMP_NEG
_hex_chk_ramp2:
	cmp	m1, #DEFAULT_RAMP_POS
	beq	_hex_res_ramp2
;-----------------------------------------------
_inc_m1_hxx_bpl:
;-----------------------------------------------
	inc	m1
	bra	_hxx_bpl_movm1a
;-----------------------------------------------
_dec_m1_hxx_bpl:
;-----------------------------------------------
	dec	m1
;-----------------------------------------------
_hxx_bpl_movm1a:
;-----------------------------------------------
	mov	a, m1
;-----------------------------------------------
_hxx_bpl:
;-----------------------------------------------
	mov	ch_vib_wav+x, a
	bpl	_hxx_plus
;-----------------------------------------------
_hxx_neg:
;-----------------------------------------------
	eor	a, #255
	inc	a

	call	_hxx_mulya
	mov	m0, a
	bbs7	special_mode, _hxx_subw_volume	; SM_TREMOLO
	bbs6	special_mode, _hxx_subw_panning	; SM_PANBRELLO
;-----------------------------------------------
_hxx_subw:
;-----------------------------------------------
	movw	ya, t_pitch
	subw	ya, m0
	bmi	_hxx_zero
	bra	_store_pitch
;-----------------------------------------------
_hxx_subw_volume:
;-----------------------------------------------
	mov	a, t_volume
	mov	y, #0
	subw	ya, m0
	bmi	_hxx_zvolume
	bra	_store_volume
;-----------------------------------------------
_hxx_subw_panning:
;-----------------------------------------------
	mov	a, t_panning
	mov	y, #0
	subw	ya, m0
	bmi	_hxx_zpanning
	bra	_store_panning
;-----------------------------------------------
_hxx_plus:
;-----------------------------------------------
	call	_hxx_mulya
	mov	y, m0+1
	bbs7	special_mode, _store_volume	; SM_TREMOLO
	bbs6	special_mode, _store_panning	; SM_PANBRELLO
_hxx_addw:
	addw	ya, t_pitch			; warning: might break something on highest note
;-----------------------------------------------
_store_pitch:
;-----------------------------------------------
	movw	t_pitch, ya
	ret
;-----------------------------------------------
_store_volume:
;-----------------------------------------------
	clrc
	adc	a, t_volume
	mov	t_volume, a
	bra	_disable_tremolo
;-----------------------------------------------
_store_panning:
;-----------------------------------------------
	clrc
	adc	a, t_panning
	mov	t_panning, a
	bra	_disable_panbrello
;-----------------------------------------------
_hxx_zero:
;-----------------------------------------------
	mov	t_pitch, #0
	mov	t_pitch+1, #0
	ret
;-----------------------------------------------
_hxx_zvolume:
;-----------------------------------------------
	mov	t_volume, #0
_disable_tremolo:
	and	special, #~SM_TREMOLO
	ret
;-----------------------------------------------
_hxx_zpanning:
;-----------------------------------------------
	mov	t_panning, #0
_disable_panbrello:
	and	special, #~SM_PANBRELLO
	ret
;-----------------------------------------------
_hxx_mulya:
;-----------------------------------------------
	mov	y, m0
	mul	ya
	mov	m0+1, y
	mov	y, #4
_hxx_div:
	lsr	m0+1
	ror	a
	dbnz	y, _hxx_div
	ret

;=======================================================================
;Command_Tremor:					; unimplemented
;=======================================================================
;	ret

;=======================================================================
Command_Arpeggio:
;=======================================================================
	bne	_jxx_other
	mov	a, #0
	mov	ch_cmem+x, a
	ret

_jxx_other:
	mov	a, ch_cmem+x
	inc	a
	cmp	a, #3
	bcc	_jxx_less3
	mov	a, #0
_jxx_less3:
	mov	ch_cmem+x, a
	cmp	a, #1
	beq	_jxx_x
	bcs	_jxx_y
	ret

_jxx_x:	mov	a, ch_param+x

_jxx_add:
	and	a, #0F0h
	asl	a
	mov	m0+1, #0
	rol	m0+1
	asl	a
	rol	m0+1
	mov	m0, a
	movw	ya, t_pitch
	addw	ya, m0
	movw	t_pitch, ya
	ret

_jxx_y:	mov	a, ch_param+x
	xcn	a
	bra	_jxx_add

;=======================================================================
Command_SetChannelVolume:
;=======================================================================
	bne	cmd_exit2			; on tick0:
	cmp	a, #80h				;
	bne	_set_cv				;
	mov	a, !MODULE+MOD_CV+x		;
_set_cv:
	mov	ch_cvolume+x, a
cmd_exit2:
	ret

;=======================================================================
Command_ChannelVolumeSlide:
;=======================================================================
	mov	a, ch_cvolume+x			; slide channel volume
	mov	m0, a				; 
	mov	m0+1, #64			;
	mov	a, ch_param+x			;
	call	DoVolumeSlide			;
	mov	ch_cvolume+x, a			;
	ret					;

;=======================================================================
;Command_SampleOffset:
;=======================================================================
	;bne	cmd_exit2			; on tick0:
	;mov	t_sampoff, a			;   set sampoff data
	;ret					;

;=======================================================================
Command_PanningSlide:
;=======================================================================
	xcn	a
	mov	m0, t_panning			; slide panning
	mov	m0+1, #64			;
	call	DoVolumeSlide			;
	mov	t_panning, a			;
	mov	ch_panning+x, a			;
	ret					;

;=======================================================================
Command_RetriggerNote:
;=======================================================================
	and	a, #0Fh				; m0 = y == 0 ? 1 : x
	bne	_crn_x1				;
	inc	a				;
_crn_x1:					;	
	mov	m0, a				;
	mov	a, ch_cmem+x			;if cmem is 0:
	bne	_crn_cmem_n0			;  cmem = m0
	mov	a, m0				;
_crn_count_ret:					;
	mov	ch_cmem+x, a			;
	ret					;
						;	
_crn_cmem_n0:					;else:
	dec	a				; dec cmem until 0
	bne	_crn_count_ret			;
						;RETRIGGER NOTE:
	mov	a, m0				; cmem = m0
	mov	ch_cmem+x, a			;
	;----------------------------------------
	; affect volume
	;----------------------------------------
	mov	a, ch_param+x
	xcn	a
	and	a, #0Fh
	mov	m1, a
	asl	a
	push	x
	mov	x, a
	mov	a, t_volume
	clrc
	jmp	[rnvtable+x]

rnvtable:
	.word	rnv_0
	.word	rnv_1
	.word	rnv_2
	.word	rnv_3
	.word	rnv_4
	.word	rnv_5
	.word	rnv_6
	.word	rnv_7
	.word	rnv_8
	.word	rnv_9
	.word	rnv_A
	.word	rnv_B
	.word	rnv_C
	.word	rnv_D
	.word	rnv_E
	.word	rnv_F

rnv_1:	dec	a
	bra	_rnv_sat0
rnv_2:	sbc	a, #2-1
	bra	_rnv_sat0
rnv_3:	sbc	a, #4-1
	bra	_rnv_sat0
rnv_4:	sbc	a, #8-1
	bra	_rnv_sat0
rnv_5:	sbc	a, #16-1
	bra	_rnv_sat0
rnv_6:	mov	y, #170
	mul	ya
	mov	a, y
	bra	_rnv_set
rnv_7:	lsr	a
rnv_8:
rnv_0:	bra	_rnv_set
rnv_9:	inc	a
	bra	_rnv_sat64
rnv_A:	adc	a, #2
	bra	_rnv_sat64
rnv_B:	adc	a, #4
	bra	_rnv_sat64
rnv_C:	adc	a, #8
	bra	_rnv_sat64
rnv_D:	adc	a, #16
	bra	_rnv_sat64
rnv_E:	mov	y, #3
	mul	ya
	lsr	a
	bra	_rnv_sat64

rnv_F:	asl	a
	bra	_rnv_sat64

_rnv_sat0:
	bpl	_rnv_set
	mov	a, #0
	bra	_rnv_set

_rnv_sat64:
	cmp	a, #65
	bcc	_rnv_set
	mov	a, #64
_rnv_set:
	pop	x
	mov	t_volume, a
	mov	ch_volume+x, a
	or	t_flags, #TF_START

	ret

;=======================================================================
Command_Extended:
;=======================================================================
	xcn	a				; setup jump to:
	and	a, #0Fh				; CmdExTab[x]
	mov	y, a				;
	mov	a, !CmdExTab_L+y		;
	mov	!cmdex_jmp+1, a			;
	mov	a, !CmdExTab_H+y		;
	mov	!cmdex_jmp+2, a			;

	mov	a, ch_param+x			; a = y
	and	a, #0Fh				; y = tick
	mov	y, mod_tick			; z = tick0

cmdex_jmp:
	jmp	0a0bh

;=======================================================================
SCommand_Null:
;=======================================================================
	ret

CmdExTab_L:
	.byte	LBYTE(SCommand_EPN)		; S0x 0-4 Echo; 5-8 Pitch, 9-c Noise
	.byte	LBYTE(SCommand_NoiseFrXeq1)	; S1x
	.byte	LBYTE(SCommand_NoiseFrXeq2)	; S2x
	.byte	LBYTE(SCommand_VibWav_XFilter)	; S3x 0-6 Vib. waveform / Filter
	.byte	LBYTE(SCommand_TremWavX_Noise)	; S4x 0-3 Trem. waveform / Noise
	.byte	LBYTE(SCommand_PanWav_XNoise)	; S5x 0-3 Panb. waveform / Noise
 	.byte	LBYTE(SCommand_Null)
	.byte	LBYTE(SCommand_ResetFiXlterOpt)	; S7[E|F]
	.byte	LBYTE(SCommand_Panning)		; S8x
	.byte	LBYTE(SCommand_SoundCoXntrol)	; S9x
	.byte	LBYTE(SCommand_Null)
	.byte	LBYTE(SCommand_Null)
	.byte	LBYTE(SCommand_NoteCut)		; SCx
	.byte	LBYTE(SCommand_NoteDelXay)	; SDx
	.byte	LBYTE(SCommand_Null)
	.byte	LBYTE(SCommand_Cue)		; SFx
CmdExTab_H:
	.byte	HBYTE(SCommand_EPN)
	.byte	HBYTE(SCommand_NoiseFrXeq1)
	.byte	HBYTE(SCommand_NoiseFrXeq2)
	.byte	HBYTE(SCommand_VibWav_XFilter)
	.byte	HBYTE(SCommand_TremWavX_Noise)
	.byte	HBYTE(SCommand_PanWav_XNoise)
	.byte	HBYTE(SCommand_Null)
	.byte	HBYTE(SCommand_ResetFiXlterOpt)
	.byte	HBYTE(SCommand_Panning)
	.byte	HBYTE(SCommand_SoundCoXntrol)
	.byte	HBYTE(SCommand_Null)
	.byte	HBYTE(SCommand_Null)
	.byte	HBYTE(SCommand_NoteCut)
	.byte	HBYTE(SCommand_NoteDelXay)
	.byte	HBYTE(SCommand_Null)
	.byte	HBYTE(SCommand_Cue)

;-----------------------------------------------------------------------
_jmp_resetdelayechofb:
;-----------------------------------------------------------------------
	jmp	Reset_Delay_Echo_Feedback
;=======================================================================
SCommand_EPN:	; Echo / Pitchmod / Noise ; This part added by KFF for noise & pitch modulation
;=======================================================================
	cmp	a, #0dh
	bcs	_jmp_resetdelayechofb
	cmp	a, #9			; do we need to do something with noise?
	bcc	_pitch_mod
	mov	SPC_DSPA, #DSP_NON
	clrc
	sbc	a, #7
	bra	skip_dsp_eon		; preserve DSP_NON in SPC_DSPA
;-----------------------------------------------------------------------
_pitch_mod:
;-----------------------------------------------------------------------
	cmp	a, #5			; do we need to do something with pitchmod?
	bcc	SCommand_Echo
	mov	SPC_DSPA, #DSP_PMON
	clrc
	sbc	a, #3
	bra	skip_dsp_eon		; preserve DSP_PMON in SPC_DSPA
;=======================================================================
SCommand_Echo:
;=======================================================================
	mov	SPC_DSPA, #DSP_EON
skip_dsp_eon:
	cmp	a, #1
	beq	_sce_enable_one
	bcc	cmd_exit3
	cmp	a, #3
	bcc	_sce_disable_one
	beq	_sce_enable_all
	cmp	a, #4
	beq	_sce_disable_all

cmd_exit3:
	ret
;-----------------------------------------------------------------------
_sce_enable_one:
;-----------------------------------------------------------------------
	mov	a, !BITS+x
	or	a, SPC_DSPD
	mov	SPC_DSPD, a
	ret
;-----------------------------------------------------------------------
_sce_disable_one:
;-----------------------------------------------------------------------
	mov	a, !BITS+x
	eor	a, #255
	and	a, SPC_DSPD
	mov	SPC_DSPD, a
	ret
;-----------------------------------------------------------------------
_sce_enable_all:
;-----------------------------------------------------------------------
	mov	SPC_DSPD, #0FFh
	ret
;-----------------------------------------------------------------------
_sce_disable_all:
;-----------------------------------------------------------------------
	mov	SPC_DSPD, #0
	ret

;-----------------------------------------------------------------------
_jmp_resetall:
;-----------------------------------------------------------------------
	jmp	ResetAll
;-----------------------------------------------------------------------
_set_echowriteflag:
;-----------------------------------------------------------------------
	mov	SPC_DSPA, #DSP_FLG
	cmp	a, #08h
	beq	_enable_echo_write
;-----------------------------------------------------------------------
_disable_echo_write:
;-----------------------------------------------------------------------
	or	SPC_DSPD, #FLG_ECEN
	ret
;-----------------------------------------------------------------------
_enable_echo_write:
;-----------------------------------------------------------------------
	and	SPC_DSPD, #~FLG_ECEN
	ret
;-----------------------------------------------------------------------

;=======================================================================
SetWaveform:
;=======================================================================
	mov	ch_env_vib+x, a
	mov	a, #0
	mov	ch_vib_wav+x, a
	ret
;=======================================================================
SCommand_VibWav_Filter:				; S3x
;=======================================================================
	cmp	a, #07h
	bcc	SetWaveform
	cmp	a, #09h
	bcc	_set_echowriteflag
	beq	_jmp_resetall

	cmp	a, #0Ah
	beq	Command_SetFilterDefault
	cmp	a, #0Bh
	beq	Command_SetFilterBand
	cmp	a, #0Ch
	beq	Command_SetFilterHigh
	cmp	a, #0Dh
	beq	Command_SetFilterLow
	cmp	a, #0Eh
	beq	Command_SetFilterCust1
	cmp	a, #0Fh
	beq	Command_SetFilterCust2
;------------------------------------------------------------------------
Command_SetFilterDefault:			; 0Ah
;------------------------------------------------------------------------
	mov	y, #7
	bra	_set_special_filter
;------------------------------------------------------------------------
Command_SetFilterBand:
;------------------------------------------------------------------------
	mov	y, #15
	bra	_set_special_filter
;------------------------------------------------------------------------
Command_SetFilterHigh:
;------------------------------------------------------------------------
	mov	y, #23
	bra	_set_special_filter
;------------------------------------------------------------------------
Command_SetFilterLow:
;------------------------------------------------------------------------
	mov	y, #31
	bra	_set_special_filter
;------------------------------------------------------------------------
Command_SetFilterCust1:
;------------------------------------------------------------------------
	mov	y, #39
	bra	_set_special_filter
;------------------------------------------------------------------------
Command_SetFilterCust2:
;------------------------------------------------------------------------
	mov	y, #47

_set_special_filter:

	bbc1	special_mode, _skip_reset		; test SM_3AFRESET

	call	ResetFbFirVol
_skip_reset:
	setc
	mov	SPC_DSPA, #DSP_C7
	push	x
	mov	x, #7
_copy_special_coef:
	mov	a, !Filter+y
	mov	filter_values+x, a
	bbs0	special_mode, _cscdy			; test SM_FILTERSWEEP
	mov	SPC_DSPD, a
	sbc	SPC_DSPA, #10h
_cscdy:	dec	y
	dec	x
	bpl	_copy_special_coef
	pop	x
	ret

;=======================================================================
SCommand_PanWav_Noise:				; S5x
;=======================================================================
	cmp	a, #4
	bcc	SCommand_VibWav_Filter
	or	special, #SF_NOISESWEEP
	clrc
	adc	a, #10h
	bra	_noise_mov
;=======================================================================
SCommand_NoiseFreq2:				; S2x
;=======================================================================
	clrc
	adc	a, #10h
;=======================================================================
SCommand_NoiseFreq1:				; S1x
;=======================================================================
	and	special, #~SF_NOISESWEEP
_noise_mov:
	mov	noise_value, a
	mov	noise_sweep_start, a
;-----------------------------------------------------------------------
SCommand_NoiseFreq1b:
;-----------------------------------------------------------------------
	mov	SPC_DSPA, #DSP_FLG
	and	SPC_DSPD, #FLG_NOISE
	or	SPC_DSPD, noise_value
	ret

;=======================================================================
SCommand_ResetFilterOpt:			; S7x
;=======================================================================
	cmp	a, #0eh
	beq	_cfs_reset_on
	cmp	a, #0fh
	beq	_cfs_reset_off
	ret

_cfs_reset_on:
	or	special_mode, #SM_3AFRESET
	ret

_cfs_reset_off:
	and	special_mode, #~SM_3AFRESET
	ret

;=======================================================================
SCommand_Panning:				; S8x
;=======================================================================
	bne	cmd_exit4			; on tick0:
	mov	m0, a				; panning = (y << 2) + (y >> 2)
	asl	a				;
	asl	a				;
	lsr	m0				;
	lsr	m0				;
	adc	a, m0				;
	mov	t_panning, a			;
	call	Command_SetPanningb		;
	ret					;

;-----------------------------------------------------------------------
_command_setzmodechfs_r:			; S96
;-----------------------------------------------------------------------
	call	ResetFbFirVol
;-----------------------------------------------------------------------
_command_setzmodechfs:				; S97
;-----------------------------------------------------------------------
	mov	parameter_mode, #Z_CHFS
	push	x
	mov	x, #7
	mov	a, #80h
_set80:	mov	filter_values+x, a
	dec	x
	bpl	_set80

	pop 	x
	or	special_mode, #SM_FILTERSWEEP
	ret
;-----------------------------------------------------------------------

;=======================================================================
SCommand_SoundControl:				; S9x
;=======================================================================
	bne	cmd_exit4
	cmp	a, #Z_SURROUND
	beq	_command_surround
	cmp	a, #Z_MUTE
	beq	_command_mutechannel
	cmp	a, #Z_UNMUTE
	beq	_command_unmutechannel
	cmp	a, #Z_CHFS_W_RES
	beq	_command_setzmodechfs_r
	cmp	a, #Z_CHFS
	beq	_command_setzmodechfs
	cmp	a, #Z_EFIR
	bcs	_command_setz
	ret

;------------------------------------------------------------------------
_command_surround:
;------------------------------------------------------------------------
	mov	a, ch_flags+x
	or	a, #CF_SURROUND
	mov	ch_flags+x, a
	mov	a, #32
	mov	ch_panning+x, a
	mov	t_panning, a
	ret
;------------------------------------------------------------------------
_command_mutechannel:
;------------------------------------------------------------------------
	mov	a, ch_flags+x
	or	a, #80h
	mov	ch_flags+x, a
	ret
;------------------------------------------------------------------------
_command_unmutechannel:	
;------------------------------------------------------------------------
	mov	a, ch_flags+x
	and     a, #7Fh				; mask 7 bits
	mov	ch_flags+x,a
	ret
;------------------------------------------------------------------------
_command_setz:
;------------------------------------------------------------------------
	mov	parameter_mode, a
	ret

;=======================================================================
SCommand_NoteCut:				; SCx
;=======================================================================
	cmp	a, mod_tick			; on tick Y:
	bne	cmd_exit4			;
	mov	a, #0				; zero volume
	mov	t_volume, a			;
	mov	ch_volume+x, a			;
cmd_exit4:					;
	ret					;

;=======================================================================
SCommand_NoteDelay:				; SDx
;=======================================================================
	cmp	a, mod_tick
	beq	scdelay_equ
	bcs	scdelay_lower
	ret
;-----------------------------------------------------------------------
scdelay_lower:
;-----------------------------------------------------------------------
	or	t_flags, #TF_DELAY
	ret
;-----------------------------------------------------------------------
scdelay_equ:
;-----------------------------------------------------------------------
	or	t_flags, #TF_START
	ret

;=======================================================================
SCommand_Cue:					; SFx
;=======================================================================
	bne	cmd_exit4			;on tick0:
	inc	STATUS				; increment CUE value
	and	STATUS, #11101111b		; in status and send to
	mov	SPC_PORT2, STATUS		; snes
	ret					;

;=======================================================================
Command_Tempo:					; Txy
;=======================================================================
	cmp	a, #20h
	bcc	_temposlide
	cmp	a, #80
	bcs	_change_tempo
	mov	a, #80
	bra	_change_tempo

_temposlide:
	cmp	a, #10h
	bcc	_txx_down
	and	a, #0Fh
	clrc
	adc	a, mod_bpm
	bra	_change_tempo

_txx_down:
	mov	m0, a
	mov	a, mod_bpm
	setc
	sbc	a, m0
	cmp	a, #80
	bcs	_change_tempo
	mov	a, #80

_change_tempo:
	call	Module_ChangeTempo
	mov	SPC_CONTROL, #%111
	ret

;=======================================================================
;Command_FineVibrato:				; unimplemented
;=======================================================================
;	ret

;=======================================================================
Command_SetGlobalVolume:
;=======================================================================
	bne	cmd_exit4			; set global volume on tick0
	cmp	a, #80h				;
	bcc	_vxx_nsat			; saturate to 80h
	mov	a, #80h				;
_vxx_nsat:					;
	mov	mod_gvol, a			;
	ret					;

;=======================================================================
Command_GlobalVolumeSlide:
;=======================================================================
	mov	m0, mod_gvol			; slide global volume
	mov	m0+1, #128			; max 128
	call	DoVolumeSlide			;
	mov	mod_gvol, a			;
	ret					;

;=======================================================================
Command_SetPanning:
;=======================================================================
	bne	cmd_exit4			; set panning on tick0	
	lsr	a				;
	lsr	a				;
	mov	t_panning, a			;
;=======================================================================
Command_SetPanningb:
;=======================================================================
	mov	ch_panning+x, a			;
	mov	a, ch_flags+x			;
	and	a, #~CF_SURROUND		;
	mov	ch_flags+x, a			;
	ret					;

;=======================================================================
ZCommand_EchoVolume:				; S9A Zxx
;=======================================================================
	cmp	a, #80h
	beq	ResetEchoVolume
	mov	current_evol, a
;-----------------------------------------------------------------------
Command_EchoVolume2:
;-----------------------------------------------------------------------
	mov	evol_l, a
	mov	y, !MODULE+MOD_EVOL
	cmp	y, !MODULE+MOD_EVOLR		; check for stereo
	beq	_setr
	eor	a, #0ffh
	inc	a
_setr:	mov	evol_r, a
	bra	UpdateEchoVolume
;=======================================================================
ResetEchoVolume:
;=======================================================================
	mov	a, !MODULE+MOD_EVOL
	mov	evol_l, a
	mov	current_evol, a
	mov	a, !MODULE+MOD_EVOLR
	mov	evol_r, a
;-----------------------------------------------------------------------
UpdateEchoVolume:
;-----------------------------------------------------------------------
	mov	SPC_DSPA, #DSP_EVOL
	mov	SPC_DSPD, evol_l
	mov	SPC_DSPA, #DSP_EVOLR
	mov	SPC_DSPD, evol_r
	ret
;=======================================================================
ZCommand_EchoFeedback:			; S9B Zxx
;=======================================================================
	cmp	a, #80h
	beq	ResetEchoFeedback

;=======================================================================
Command_EchoFeedback2:
;=======================================================================
	mov	SPC_DSPA, #DSP_EFB
	mov	SPC_DSPD, a
	ret

;=======================================================================
ResetEchoFeedback:
;=======================================================================
	mov	SPC_DSPA, #DSP_EFB		; restore default EFB
	mov	a, !MODULE+MOD_EFB		;
	mov	SPC_DSPD, a	
	mov	evol_fb, a
	ret

;======================================================================= 
Reset_Delay_Echo_Feedback:			; S0x
;=======================================================================
	cmp	a, #0fh
	beq	ResetEchoFeedback
	cmp	a, #0eh
	beq	ResetEchoVolume
	cmp	a, #0dh
	beq	ResetEchoDelay
	ret


;-----------------------------------------------------------------------
ZCommand_ChFilterSweep:				; S97 Zxx
;-----------------------------------------------------------------------
	cmp	a, #80h
	beq	_disable_ch_filter_sweep
	mov	filter_values+x, a
	or	special_mode, #SM_FILTERSWEEP
	ret

_disable_ch_filter_sweep:
	and	special_mode, #~SM_FILTERSWEEP
	ret

;=======================================================================
Command_SetParameter:
;=======================================================================
	;cmp	parameter_mode, #Z_DIRECTGAIN	; S95
	;beq	Command_DirectGain
	cmp	parameter_mode,	#Z_CHFS		; S9[6|7]
	beq	ZCommand_ChFilterSweep
	cmp	parameter_mode, #Z_EFIR		; S98
	beq	ZCommand_SetEFIR
	cmp	parameter_mode, #Z_MVOL		; S99
	beq	ZCommand_MasterVolume
	cmp	parameter_mode, #Z_EVOL		; S9A
	beq	ZCommand_EchoVolume
	cmp	parameter_mode, #Z_EFB		; S9B
	beq	ZCommand_EchoFeedback
	cmp	parameter_mode, #Z_ETIMENOISE   ; S9D
	beq	ZCommand_EVOLSweepNoise
	jmp	Command_SetParameter2

;=======================================================================
;Command_DirectGain:
;=======================================================================
	;ret

;=======================================================================
ZCommand_SetEFIR:				; S98 Zxx
;=======================================================================
	and	special_mode, #~SM_FILTERSWEEP	; disable channel filter sweep
	cmp	a, #80h				;
	beq	ResetEFIR			;
	mov	y, a				;
	mov	a, !CBITS+x			;
	mov	SPC_DSPA, a			;
	mov	SPC_DSPD, y			;
	ret					;
;-----------------------------------------------------------------------
ResetEFIR_FS:
;-----------------------------------------------------------------------
	call	ResetFilterOpts
;=======================================================================
ResetEFIR:
;=======================================================================
	setc					; copy FIR coefficients
	mov	SPC_DSPA, #DSP_C7		;
	push	x				;
	mov	x, #7				;
_copy_coef:					;
	mov	a, !MODULE+MOD_EFIR+x		;
	mov	filter_values+x, a		;
	mov	SPC_DSPD, a			;
	sbc	SPC_DSPA, #10h			;
	dec	x				;
	bpl	_copy_coef			;

	pop	x
	ret

;-----------------------------------------------------------------------
ResetEchoDelay:
;-----------------------------------------------------------------------
	mov	SPC_DSPA, #DSP_EDL		; defined in the header
	mov	a, !MODULE+MOD_EDL
	mov	SPC_DSPD, a
	ret
;-----------------------------------------------------------------------

;=======================================================================
ResetMasterVolume:
;=======================================================================
	mov	a, #DEFAULT_MVOL
;=======================================================================
ZCommand_MasterVolume:				; S99 Zxx
;=======================================================================
	cmp	a, #80h
	beq	ResetMasterVolume
;=======================================================================
Command_MasterVolume2:
;=======================================================================
	mov	SPC_DSPA, #DSP_MVOL
	mov	SPC_DSPD, a
	mov	SPC_DSPA, #DSP_MVOLR
	mov	SPC_DSPD, a
	ret

;-----------------------------------------------------------------------
_set_swingmod:
;-----------------------------------------------------------------------
	setc
	sbc	a, #0F0h
	mov	swing_tempo_mod, a
	jmp	EnableSwingTempo
;=======================================================================
ZCommand_EVOLSweepNoise:					; S9D Zxx
;=======================================================================
	cmp	a, #20h
	bcc	_set_noise_start
	cmp	a, #40h
	bcc	_set_noise_endmin
	cmp	a, #60h
	bcc	_set_noise_endmax
	beq	_disable_noise_sweep
	cmp	a, #0DAh
	bcc	_set_noise_time
	beq	_set_noiseinc
	cmp	a, #0DBh
	beq	_set_noisedec
	cmp	a, #0DCh
	beq	_enable_noiserepeat
	cmp	a, #0DDh
	beq	_disable_noiserepeat
	cmp	a, #0DEh
	beq	_enable_noisepingpong
	cmp	a, #0DFh
	beq	_disable_noisepingpong
	cmp	a, #0F0h
	beq	DisableSwingTempo
	cmp	a, #0F1h
	bcs	_set_swingmod

_set_evol_time:
	setc
	sbc	a, #0E0h
	mov	evol_time, a
	ret

;-----------------------------------------------------------------------
_set_noise_start:
;-----------------------------------------------------------------------
        or      special, #SF_NOISESWEEP
        jmp     _noise_mov
;-----------------------------------------------------------------------
_set_noise_endmin:
;-----------------------------------------------------------------------
	setc
	sbc	a, #20h
	mov	noise_sweep_endmin, a
	ret
;-----------------------------------------------------------------------
_set_noise_endmax:
;-----------------------------------------------------------------------
	setc
	sbc	a, #40h
	mov	noise_sweep_endmax, a
	ret
;-----------------------------------------------------------------------
_disable_noise_sweep:
;-----------------------------------------------------------------------
	and	special, #~SF_NOISESWEEP
	ret
;-----------------------------------------------------------------------
_set_noise_time:
;-----------------------------------------------------------------------
	setc
	sbc	a, #60h
	cmp	a, #38h
	bcc	_skip_rola
	rol	a
_skip_rola:
	mov	 noise_time, a
	ret
;-----------------------------------------------------------------------
_set_noiseinc:
;-----------------------------------------------------------------------
	or	special, #SF_NOISEINC
	bra	_s4xit
;-----------------------------------------------------------------------
_set_noisedec:
;-----------------------------------------------------------------------
	and	special, #~SF_NOISEINC
_s4xit:	and	special_mode, #~SM_NOISEMODE
	ret
;-----------------------------------------------------------------------
_enable_noiserepeat:
;-----------------------------------------------------------------------
	or	special_mode, #SM_NOISEREPEAT
	ret
;-----------------------------------------------------------------------
_disable_noiserepeat:
;-----------------------------------------------------------------------
	and	special_mode, #~SM_NOISEREPEAT
	ret
;-----------------------------------------------------------------------
_enable_noisepingpong:
;-----------------------------------------------------------------------
	or	special_mode, #SM_NOISEMODE
	ret
;-----------------------------------------------------------------------
_disable_noisepingpong:
;-----------------------------------------------------------------------
	and	special_mode, #~SM_NOISEMODE
	ret

;=======================================================================
EnableSwingTempo:
;=======================================================================
	or	special, #SF_SWINGTEMPO
	and	special, #~SF_SWINGODD          ; always start at 0
	mov	mod_speed_bk, mod_speed         ; back up speed
	ret
;=======================================================================
DisableSwingTempo:
;=======================================================================
	and	special, #~SF_SWINGTEMPO
	mov	mod_speed_bk, mod_speed_bk	; restore speed
	ret

;=======================================================================
SCommand_TremWav_Noise:				; S4x
;=======================================================================
	mov	y, a
	mov	a, !S4xTab_L+y
	mov	!s4xjmp+1, a
	;mov	a, !S4xTab_H+y
	mov	a, #HBYTE(EVOL_MaxMin)
	mov	!s4xjmp+2, a
s4xjmp:	jmp	0a0bh

S4xTab_L:
	.byte	LBYTE(JmpSetWaveform)		; S40
	.byte	LBYTE(JmpSetWaveform)		; S41
	.byte	LBYTE(JmpSetWaveform)		; S42
	.byte	LBYTE(JmpSetWaveform)		; S43
	.byte	LBYTE(EVOL_MaxMin)		; S44
	.byte	LBYTE(EVOL_MinMax)		; S45
	.byte	LBYTE(EnableSwingTempo)		; S46
	.byte	LBYTE(DisableSwingTempxo)	; S47
	.byte	LBYTE(_enable_wavetablxe)	; S48
	.byte	LBYTE(_disable_wavetabxle)	; S49
	.byte	LBYTE(_set_noisedec)		; S4A
	.byte	LBYTE(_set_noiseinc)		; S4B
	.byte	LBYTE(_enable_noiserepxeat)	; S4C
	.byte	LBYTE(_disable_noiserexpeat)	; S4D
	.byte	LBYTE(_enable_noisepinxgpong)	; S4E
	.byte	LBYTE(_disable_noisepixngpong)	; S4F

;S4xTab_H:
	;.byte	HBYTE(JmpSetWaveform)		; S40
	;.byte	HBYTE(JmpSetWaveform)		; S41
	;.byte	HBYTE(JmpSetWaveform)		; S42
	;.byte	HBYTE(JmpSetWaveform)		; S43
	;.byte	HBYTE(EVOL_MaxMin)		; S44
	;.byte	HBYTE(EVOL_MinMax)		; S45
	;.byte	HBYTE(EnableSwingTempo)		; S46
	;.byte	HBYTE(DisableSwingTempxo)	; S47
	;.byte	HBYTE(_enable_wavetablxe)	; S48
	;.byte	HBYTE(_disable_wavetabxle)	; S49
	;.byte	HBYTE(_set_noisedec)		; S4A
	;.byte	HBYTE(_set_noiseinc)		; S4B
	;.byte	HBYTE(_enable_noiserepxeat)	; S4C
	;.byte	HBYTE(_disable_noiserexpeat)	; S4D
	;.byte	HBYTE(_enable_noisepinxgpong)	; S4E
	;.byte	HBYTE(_disable_noisepixngpong)	; S4F

JmpSetWaveform:
	jmp	SetWaveform

;------------------------------------------------------------------------
EVOL_MaxMin:
;------------------------------------------------------------------------
	or	special, #SF_EVOLINC
	mov	current_evol, evol_min
	ret
;------------------------------------------------------------------------
EVOL_MinMax:
;------------------------------------------------------------------------
	and	special, #~SF_EVOLINC
	mov	current_evol, evol_max
	ret
;-----------------------------------------------------------------------
_disable_wavetable:
;-----------------------------------------------------------------------
	and	special_mode, #~SM_WAVETABLE
	mov	a, wt_sample_low		; restore original
	mov	!SampleDirectory, a		; sample start
	mov	!SampleDirectory+2, a		; loop start
	mov	a, wt_sample_high
	mov	!SampleDirectory+1, a		; sample start
	mov	!SampleDirectory+3, a		; loop start
	ret
;-----------------------------------------------------------------------
_enable_wavetable:
;-----------------------------------------------------------------------
	mov	wt_cur, #0
	or	special_mode, #SM_WAVETABLE
	ret

;=======================================================================
Command_SetParameter2:
;=======================================================================
	cmp	parameter_mode, #Z_EDL          ; S9C
	beq	ZCommand_EchoDelaySpecial
	cmp	parameter_mode, #Z_MINMAX	; S9E
	beq	ZCommand_SetEVOLMinMax
	cmp	parameter_mode, #Z_FILTERTIME	; S9F
	beq	ZCommand_SetFilterTime
	ret

;=======================================================================
ZCommand_SetEVOLMinMax:				; S9E Zxx
;=======================================================================
	cmp	a, #80h
	bcs	_set_evol_max
	mov	evol_min, a
	ret

_set_evol_max:
	setc
	sbc	a, #80h
	mov	evol_max, a
	ret

;=======================================================================
ZCommand_EchoDelaySpecial:			; S9C Zxx
;=======================================================================
	cmp	a, !MODULE+MOD_EDL
	beq	SetEchoDelay
	bcs	_command_special		; if > what's defined in header reset
SetEchoDelay:
	mov	SPC_DSPA, #DSP_EDL		; otherwise change to new value
	mov	SPC_DSPD, a			;
	ret
;-----------------------------------------------------------------------
_command_special:
;-----------------------------------------------------------------------
	cmp	a, #10h
	beq	ResetAll
	cmp	a, #50h
	bcc	_set_wt_time
	;cmp	a, #58h
	;bcc	_set_wt_min
	;cmp	a, #60h
	;bcc	_set_wt_max

	ret

;_set_wt_max:
	;setc
	;sbc	a, #58h
	;mov	wt_max, a
	;ret

;_set_wt_min:
	;setc
	;sbc	a, #50h
	;mov	wt_min, a
	;ret

_set_wt_time:
	setc
	sbc	a, #10h
	call	Amult4_M0
	mov	wt_time, a
	mov	current_wt_time, #0
	ret

;=======================================================================
ResetAll:					; restore all to header defaults
;=======================================================================
	call	ResetEchoDelay
	call	ResetMasterVolume
ResetFbFirVol:
	call	ResetEchoFeedback
	call	ResetEFIR
	call	ResetEchoVolume
cmd_exit5:
	ret

;=======================================================================
ZCommand_SetFilterTime:				; S9F Zxx
;=======================================================================
	cmp	a, #0
	beq	cmd_exit5

_set_filter_time:
	mov	filter_time, a
	ret

;=======================================================================
ResetFilterOpts:
;=======================================================================
	and	special_mode, #~SM_FILTERSWEEP
	ret

;-----------------------------------------------------------------------
; a = param
; y = tick
; m0 = value
; m0+1 = upper bound
;
; return: a = result
;-----------------------------------------------------------------------
DoVolumeSlide:
;-----------------------------------------------------------------------
	mov	m1, a			; test param for slide behavior
					;-------------------------------
	and	a, #0Fh			; Dx0 : slide up
	beq	_dvs_up			;-------------------------------
	mov	a, m1			; D0y : slide down
	and	a, #0F0h		;
	beq	_dvs_down		;-------------------------------
	mov	a, m1			; DxF : slide up fine
	and	a, #0Fh			;
	cmp	a, #0Fh			;
	beq	_dvs_fineup		;-------------------------------
	mov	a, m1			; DFy : slide down fine
	cmp	a, #0F0h		;
	bcs	_dvs_finedown		;
_dvs_quit:				;-------------------------------
	mov	a, m0			; (invalid)
_dvs_exit:				;
	ret				;
;-----------------------------------------------------------------------
_dvs_finedown:				; DFy
;-----------------------------------------------------------------------
	cmp	y, #0			;on tick0:
	bne	_dvs_quit		;
	mov	a, m0			; a = volume - y
	and	m1, #0Fh		;
	sbc	a, m1			;
	bcs	_dvs_exit		; saturate lower bound to 0
	mov	a, #0			;
	ret				;
;-----------------------------------------------------------------------
_dvs_fineup:				; DxF
;-----------------------------------------------------------------------
	cmp	y, #0			;on tick0:
	bne	_dvs_quit		;
	mov	a, m1			; a = x + volume
	xcn	a			;
	and	a, #0Fh			;
	clrc				;
	adc	a, m0			;
	cmp	a, m0+1			; saturate upper to [m0.h]
	bcc	_dvs_exit		;
	mov	a, m0+1			;
	ret				;
;-----------------------------------------------------------------------
_dvs_down:				; D0y
;-----------------------------------------------------------------------
	cmp	m1,#0Fh			;on tick0 OR y == 15
	beq	_dvsd_15		;
	cmp	y, #0			;
	beq	_dvs_quit		;
_dvsd_15:				;
	mov	a, m0			; a = volume - param
	setc				;
	sbc	a, m1			;
	bcs	_dvs_exit		; saturate lower to 0
	mov	a, #0			;
	ret				;
;-----------------------------------------------------------------------
_dvs_up:				;
;-----------------------------------------------------------------------
	cmp	m1, #0F0h		;on tick0 OR x == 15
	beq	_dvsu_15		;
	cmp	y, #0			;
	beq	_dvs_quit		;
_dvsu_15:				;
	mov	a, m1			; a = x + volume
	xcn	a			;
	and	a, #0Fh			;
	clrc				;
	adc	a, m0			;
	cmp	a, m0+1			; saturate upper to [m0.h]
	bcc	_dvs_exit		;
	mov	a, m0+1			;
	ret				;
;-----------------------------------------------------------------------

;=======================================================================
; a = param
; y = tick
; return m0:word = slide amount
;=======================================================================
PitchSlide_Load:
;=======================================================================
	cmp	a, #0F0h			; Fx: fine slide
	bcs	_psl_fine			;
	cmp	a, #0E0h			; Ex: extra fine slide
	bcs	_psl_exfine			;
;-----------------------------------------------------------------------
_psl_normal:
;-----------------------------------------------------------------------
	cmp	y, #0				; no slide on tick0
	beq	_psl_zero			;
;=======================================================================
Amult4_M0:
;=======================================================================
	mov	m0+1, #0			; m0 = a*4
	asl	a				;	
	rol	m0+1				;
	asl	a				;
	rol	m0+1				;
	mov	m0, a				;
	ret					;
;-----------------------------------------------------------------------
_psl_fine:
;-----------------------------------------------------------------------
	cmp	y, #0				; no slide on not tick0
	bne	_psl_zero			;
	mov	m0+1, #0			; m0 = y*4
	and	a, #0Fh				;	
	asl	a				;
	asl	a				;
	mov	m0, a				;
	ret					;
;-----------------------------------------------------------------------
_psl_exfine:
;-----------------------------------------------------------------------
	cmp	y, #0				; no slide on not tick0
	bne	_psl_zero			;
	mov	m0+1, #0			; m0 = y
	and	a, #0Fh				;	
	mov	m0, a				;
	ret					;
;-----------------------------------------------------------------------
_psl_zero:
;-----------------------------------------------------------------------
	mov	m0, #0
	mov	m0+1, #0
	ret

;***********************************************************************

LUT_DIV3:
	.byte 0, 0, 0, 1, 1, 1, 2, 2, 2
	.byte 3, 3, 3, 4, 4, 4, 5, 5, 5
	.byte 6, 6, 6, 7, 7, 7, 8, 8, 8
	.byte 9, 9, 9,10,10

__BRK_ROUTINE__:
	asl	SPC_PORT0
	;bcs	_brk_pass
	;ret
;_brk_pass:
	;jmp	somewhere
	ret
	
LUT_FTAB:
        .word 02174h, 0217Bh, 02183h, 0218Bh, 02193h, 0219Ah, 021A2h, 021AAh, 021B2h, 021BAh, 021C1h, 021C9h, 021D1h, 021D9h, 021E1h, 021E8h
        .word 021F0h, 021F8h, 02200h, 02208h, 02210h, 02218h, 0221Fh, 02227h, 0222Fh, 02237h, 0223Fh, 02247h, 0224Fh, 02257h, 0225Fh, 02267h
        .word 0226Fh, 02277h, 0227Fh, 02287h, 0228Fh, 02297h, 0229Fh, 022A7h, 022AFh, 022B7h, 022BFh, 022C7h, 022CFh, 022D7h, 022DFh, 022E7h
        .word 022EFh, 022F7h, 022FFh, 02307h, 0230Fh, 02317h, 0231Fh, 02328h, 02330h, 02338h, 02340h, 02348h, 02350h, 02358h, 02361h, 02369h
        .word 02371h, 02379h, 02381h, 0238Ah, 02392h, 0239Ah, 023A2h, 023AAh, 023B3h, 023BBh, 023C3h, 023CBh, 023D4h, 023DCh, 023E4h, 023EDh
        .word 023F5h, 023FDh, 02406h, 0240Eh, 02416h, 0241Fh, 02427h, 0242Fh, 02438h, 02440h, 02448h, 02451h, 02459h, 02462h, 0246Ah, 02472h
        .word 0247Bh, 02483h, 0248Ch, 02494h, 0249Dh, 024A5h, 024AEh, 024B6h, 024BEh, 024C7h, 024CFh, 024D8h, 024E0h, 024E9h, 024F2h, 024FAh
        .word 02503h, 0250Bh, 02514h, 0251Ch, 02525h, 0252Dh, 02536h, 0253Fh, 02547h, 02550h, 02559h, 02561h, 0256Ah, 02572h, 0257Bh, 02584h
        .word 0258Ch, 02595h, 0259Eh, 025A7h, 025AFh, 025B8h, 025C1h, 025C9h, 025D2h, 025DBh, 025E4h, 025ECh, 025F5h, 025FEh, 02607h, 0260Fh
        .word 02618h, 02621h, 0262Ah, 02633h, 0263Ch, 02644h, 0264Dh, 02656h, 0265Fh, 02668h, 02671h, 0267Ah, 02682h, 0268Bh, 02694h, 0269Dh
        .word 026A6h, 026AFh, 026B8h, 026C1h, 026CAh, 026D3h, 026DCh, 026E5h, 026EEh, 026F7h, 02700h, 02709h, 02712h, 0271Bh, 02724h, 0272Dh
        .word 02736h, 0273Fh, 02748h, 02751h, 0275Ah, 02763h, 0276Dh, 02776h, 0277Fh, 02788h, 02791h, 0279Ah, 027A3h, 027ACh, 027B6h, 027BFh
        .word 027C8h, 027D1h, 027DAh, 027E4h, 027EDh, 027F6h, 027FFh, 02809h, 02812h, 0281Bh, 02824h, 0282Eh, 02837h, 02840h, 0284Ah, 02853h
        .word 0285Ch, 02865h, 0286Fh, 02878h, 02882h, 0288Bh, 02894h, 0289Eh, 028A7h, 028B0h, 028BAh, 028C3h, 028CDh, 028D6h, 028E0h, 028E9h
        .word 028F2h, 028FCh, 02905h, 0290Fh, 02918h, 02922h, 0292Bh, 02935h, 0293Eh, 02948h, 02951h, 0295Bh, 02965h, 0296Eh, 02978h, 02981h
        .word 0298Bh, 02995h, 0299Eh, 029A8h, 029B1h, 029BBh, 029C5h, 029CEh, 029D8h, 029E2h, 029EBh, 029F5h, 029FFh, 02A08h, 02A12h, 02A1Ch
        .word 02A26h, 02A2Fh, 02A39h, 02A43h, 02A4Dh, 02A56h, 02A60h, 02A6Ah, 02A74h, 02A7Eh, 02A87h, 02A91h, 02A9Bh, 02AA5h, 02AAFh, 02AB9h
        .word 02AC3h, 02ACCh, 02AD6h, 02AE0h, 02AEAh, 02AF4h, 02AFEh, 02B08h, 02B12h, 02B1Ch, 02B26h, 02B30h, 02B3Ah, 02B44h, 02B4Eh, 02B58h
        .word 02B62h, 02B6Ch, 02B76h, 02B80h, 02B8Ah, 02B94h, 02B9Eh, 02BA8h, 02BB2h, 02BBCh, 02BC6h, 02BD1h, 02BDBh, 02BE5h, 02BEFh, 02BF9h
        .word 02C03h, 02C0Dh, 02C18h, 02C22h, 02C2Ch, 02C36h, 02C40h, 02C4Bh, 02C55h, 02C5Fh, 02C69h, 02C74h, 02C7Eh, 02C88h, 02C93h, 02C9Dh
        .word 02CA7h, 02CB2h, 02CBCh, 02CC6h, 02CD1h, 02CDBh, 02CE5h, 02CF0h, 02CFAh, 02D04h, 02D0Fh, 02D19h, 02D24h, 02D2Eh, 02D39h, 02D43h
        .word 02D4Dh, 02D58h, 02D62h, 02D6Dh, 02D77h, 02D82h, 02D8Ch, 02D97h, 02DA1h, 02DACh, 02DB7h, 02DC1h, 02DCCh, 02DD6h, 02DE1h, 02DECh
        .word 02DF6h, 02E01h, 02E0Bh, 02E16h, 02E21h, 02E2Bh, 02E36h, 02E41h, 02E4Bh, 02E56h, 02E61h, 02E6Ch, 02E76h, 02E81h, 02E8Ch, 02E97h
        .word 02EA1h, 02EACh, 02EB7h, 02EC2h, 02ECCh, 02ED7h, 02EE2h, 02EEDh, 02EF8h, 02F03h, 02F0Eh, 02F18h, 02F23h, 02F2Eh, 02F39h, 02F44h
        .word 02F4Fh, 02F5Ah, 02F65h, 02F70h, 02F7Bh, 02F86h, 02F91h, 02F9Ch, 02FA7h, 02FB2h, 02FBDh, 02FC8h, 02FD3h, 02FDEh, 02FE9h, 02FF4h
        .word 02FFFh, 0300Ah, 03015h, 03020h, 0302Ch, 03037h, 03042h, 0304Dh, 03058h, 03063h, 0306Eh, 0307Ah, 03085h, 03090h, 0309Bh, 030A7h
        .word 030B2h, 030BDh, 030C8h, 030D4h, 030DFh, 030EAh, 030F5h, 03101h, 0310Ch, 03117h, 03123h, 0312Eh, 0313Ah, 03145h, 03150h, 0315Ch
        .word 03167h, 03173h, 0317Eh, 03189h, 03195h, 031A0h, 031ACh, 031B7h, 031C3h, 031CEh, 031DAh, 031E5h, 031F1h, 031FCh, 03208h, 03213h
        .word 0321Fh, 0322Bh, 03236h, 03242h, 0324Dh, 03259h, 03265h, 03270h, 0327Ch, 03288h, 03293h, 0329Fh, 032ABh, 032B7h, 032C2h, 032CEh
        .word 032DAh, 032E5h, 032F1h, 032FDh, 03309h, 03315h, 03320h, 0332Ch, 03338h, 03344h, 03350h, 0335Ch, 03367h, 03373h, 0337Fh, 0338Bh
        .word 03397h, 033A3h, 033AFh, 033BBh, 033C7h, 033D3h, 033DFh, 033EBh, 033F7h, 03403h, 0340Fh, 0341Bh, 03427h, 03433h, 0343Fh, 0344Bh
        .word 03457h, 03463h, 0346Fh, 0347Bh, 03488h, 03494h, 034A0h, 034ACh, 034B8h, 034C4h, 034D1h, 034DDh, 034E9h, 034F5h, 03502h, 0350Eh
        .word 0351Ah, 03526h, 03533h, 0353Fh, 0354Bh, 03558h, 03564h, 03570h, 0357Dh, 03589h, 03595h, 035A2h, 035AEh, 035BAh, 035C7h, 035D3h
        .word 035E0h, 035ECh, 035F9h, 03605h, 03612h, 0361Eh, 0362Bh, 03637h, 03644h, 03650h, 0365Dh, 03669h, 03676h, 03683h, 0368Fh, 0369Ch
        .word 036A8h, 036B5h, 036C2h, 036CEh, 036DBh, 036E8h, 036F4h, 03701h, 0370Eh, 0371Bh, 03727h, 03734h, 03741h, 0374Eh, 0375Ah, 03767h
        .word 03774h, 03781h, 0378Eh, 0379Ah, 037A7h, 037B4h, 037C1h, 037CEh, 037DBh, 037E8h, 037F5h, 03802h, 0380Eh, 0381Bh, 03828h, 03835h
        .word 03842h, 0384Fh, 0385Ch, 03869h, 03876h, 03884h, 03891h, 0389Eh, 038ABh, 038B8h, 038C5h, 038D2h, 038DFh, 038ECh, 038FAh, 03907h
        .word 03914h, 03921h, 0392Eh, 0393Bh, 03949h, 03956h, 03963h, 03970h, 0397Eh, 0398Bh, 03998h, 039A6h, 039B3h, 039C0h, 039CEh, 039DBh
        .word 039E8h, 039F6h, 03A03h, 03A11h, 03A1Eh, 03A2Bh, 03A39h, 03A46h, 03A54h, 03A61h, 03A6Fh, 03A7Ch, 03A8Ah, 03A97h, 03AA5h, 03AB2h
        .word 03AC0h, 03ACEh, 03ADBh, 03AE9h, 03AF6h, 03B04h, 03B12h, 03B1Fh, 03B2Dh, 03B3Bh, 03B48h, 03B56h, 03B64h, 03B72h, 03B7Fh, 03B8Dh
        .word 03B9Bh, 03BA9h, 03BB6h, 03BC4h, 03BD2h, 03BE0h, 03BEEh, 03BFCh, 03C09h, 03C17h, 03C25h, 03C33h, 03C41h, 03C4Fh, 03C5Dh, 03C6Bh
        .word 03C79h, 03C87h, 03C95h, 03CA3h, 03CB1h, 03CBFh, 03CCDh, 03CDBh, 03CE9h, 03CF7h, 03D05h, 03D13h, 03D21h, 03D2Fh, 03D3Eh, 03D4Ch
        .word 03D5Ah, 03D68h, 03D76h, 03D85h, 03D93h, 03DA1h, 03DAFh, 03DBDh, 03DCCh, 03DDAh, 03DE8h, 03DF7h, 03E05h, 03E13h, 03E22h, 03E30h
        .word 03E3Eh, 03E4Dh, 03E5Bh, 03E6Ah, 03E78h, 03E86h, 03E95h, 03EA3h, 03EB2h, 03EC0h, 03ECFh, 03EDDh, 03EECh, 03EFAh, 03F09h, 03F18h
        .word 03F26h, 03F35h, 03F43h, 03F52h, 03F61h, 03F6Fh, 03F7Eh, 03F8Dh, 03F9Bh, 03FAAh, 03FB9h, 03FC7h, 03FD6h, 03FE5h, 03FF4h, 04002h
        .word 04011h, 04020h, 0402Fh, 0403Eh, 0404Dh, 0405Bh, 0406Ah, 04079h, 04088h, 04097h, 040A6h, 040B5h, 040C4h, 040D3h, 040E2h, 040F1h
        .word 04100h, 0410Fh, 0411Eh, 0412Dh, 0413Ch, 0414Bh, 0415Ah, 04169h, 04178h, 04188h, 04197h, 041A6h, 041B5h, 041C4h, 041D3h, 041E3h
        .word 041F2h, 04201h, 04210h, 04220h, 0422Fh, 0423Eh, 0424Eh, 0425Dh, 0426Ch, 0427Ch, 0428Bh, 0429Ah, 042AAh, 042B9h, 042C9h, 042D8h

IT_FineSineData:
	.byte   0,  2,  3,  5,  6,  8,  9, 11, 12, 14, 16, 17, 19, 20, 22, 23
	.byte  24, 26, 27, 29, 30, 32, 33, 34, 36, 37, 38, 39, 41, 42, 43, 44
	.byte  45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 56, 57, 58, 59
	.byte  59, 60, 60, 61, 61, 62, 62, 62, 63, 63, 63, 64, 64, 64, 64, 64
	.byte  64, 64, 64, 64, 64, 64, 63, 63, 63, 62, 62, 62, 61, 61, 60, 60
	.byte  59, 59, 58, 57, 56, 56, 55, 54, 53, 52, 51, 50, 49, 48, 47, 46
	.byte  45, 44, 43, 42, 41, 39, 38, 37, 36, 34, 33, 32, 30, 29, 27, 26
	.byte  24, 23, 22, 20, 19, 17, 16, 14, 12, 11,  9,  8,  6,  5,  3,  2

Filter:	.byte	$7f,$00,$00,$00,$00,$00,$00,$00 ; default
	.byte	$34,$33,$00,$d9,$e5,$01,$fc,$eb ; bandpass
	.byte	$58,$bf,$db,$f0,$fe,$07,$0c,$0c ; highpass
	.byte	$0a,$17,$23,$29,$12,$fe,$f3,$f9 ; lowpass
	.byte	$f8,$08,$11,$1c,$1c,$11,$08,$f8 ; ren & stimpy
	.byte	$0d,$22,$22,$24,$11,$f0,$03,$ff ; star ocean/tales of phantasia

;-----------------------------------------------------------------------------
; C64 waveform: $41	          When S48 is used the first sample is
;  pulse width: $81-$88           replaced by the following samples
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; C64 waveform: $41	[16744 Hz]
;  pulse width: $81-$88
;-----------------------------------------------------------------------------
WTLoop1:
	.byte	$b0,$08,$81,$11,$11,$11,$11,$11,$11
	.byte	$67,$1f,$5e,$5f,$4f,$31,$23,$e7,$a7

WTLoop2:
	.byte	$c0,$0b,$ba,$d1,$11,$11,$11,$11,$11
	.byte	$a3,$33,$33,$33,$33,$33,$42,$42,$5b

WTLoop3:
	.byte	$c0,$0b,$bb,$bb,$c1,$11,$11,$11,$11
	.byte	$a3,$55,$54,$54,$54,$54,$54,$53,$6b

WTLoop4:
	.byte	$c0,$0b,$cb,$cb,$cb,$f2,$12,$12,$12
	.byte	$b3,$33,$33,$33,$33,$33,$33,$32,$4d

WTLoop5:
	.byte	$b0,$08,$99,$99,$99,$9a,$46,$56,$56
	.byte	$b3,$55,$55,$55,$55,$55,$55,$54,$6d

WTLoop6:
	.byte	$b0,$08,$98,$99,$99,$99,$98,$06,$45
	.byte	$b7,$01,$f1,$01,$00,$00,$10,$1f,$28

WTLoop7:
	.byte	$b0,$08,$a9,$99,$99,$9a,$9a,$a9,$27
	.byte	$b3,$56,$56,$56,$55,$55,$55,$55,$6d

WTLoop8:
	.byte	$b0,$09,$aa,$aa,$aa,$aa,$aa,$ab,$ab
	.byte	$b3,$57,$67,$67,$66,$66,$66,$66,$6d
;--------------------------------------------------------

;--------------------------------------------------------
WaveTable_L:
	.byte	LBYTE(WTLoop1), LBYTE(WTLoop2)
	.byte	LBYTE(WTLoop3), LBYTE(WTLoop4)
	.byte	LBYTE(WTLoop5), LBYTE(WTLoop6)
	.byte	LBYTE(WTLoop7), LBYTE(WTLoop8)
;--------------------------------------------------------

;--------------------------------------------------------
MODULE .END
;--------------------------------------------------------


;--------------------------------------------------------
;FFC0 - FFFF    Memory (read / write)
;FFC0 - FFFF    Memory (write only)*
;FFC0 - FFFF    64 byte IPL ROM (read only)*
;--------------------------------------------------------
