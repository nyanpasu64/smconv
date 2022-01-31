;=============================================================================
; "SM-SPC"
;
; snesmod spc driver
;
; (c) 2009 Mukunda Johnson
; (c) 2013 Additional code added by KungFuFurby for pitch modulation and noise generation
; (c) 2014-2016 Additional code added by Augustus Blackheart and KungFuFurby
; (c) 2016 FM code by psychopathicteen
;=============================================================================
;#define DEBUGINC inc debug \ mov SPC_PORT0, debug

.define ABNOFX
.define LBYTE(z) (z & 0FFh)
.define HBYTE(z) (z >> 8)

.define SPROC TCALL 0
.define SPROC2 SPROC

;*****************************************************************************
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
; LOADE	01	Upload Sound Effect
;
; >> id vv LL LL	send message
; << -- mm -- --	source registered, ready for data
;
; >> -- v1 DD DD	transfer source data
; << -- mm -- --	loop until all words xferred
;
; >> -- 00 DD DD	send last word
; << -- mm -- --	okay, ready for playback
;
; sound effects are always one-shot
;  LLLL is not used (or maybe it is...........)
;--------------------------------------------------------
; VOL	02	
;
; >> id vv VV --
; << -- mm -- --
;
; 
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


;*****************************************************************************
; dsp registers		; Nocash SNES Specs
;*****************************************************************************
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

ADSR		=080h
FLG_NOISE	=0E0h
FLG_RESET	=080h
FLG_MUTE	=040h
FLG_ECEN	=020h

LIN_DEC = %10000000
EXP_DEC = %10100000
LIN_INC = %11000000
EXP_INC = %11100000

GAIN_RATE = 1Ch ; 1eh = 4ms;

#define SETDSP(xx,yy) mov SPC_DSPA, #xx\ mov SPC_DSPD, #yy

;*****************************************************************************
; module defs
;*****************************************************************************

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
; 0000 - 00EF	zero-page memory
;*****************************************************************************


m0:		.block 2
m1:		.block 2
m2:		.block 2
m3:		.block 2
m4:		.block 2
m5:		.block 2
m6:		.block 1

mod_bpm:	.block 1
mod_position:	.block 1
mod_row:	.block 1
mod_speed:	.block 1
mod_speed_bk:	.block 1
mod_tick:	.block 1

module_vol:	.block 1 ; module volume
module_fadeT:	.block 1 ; module volume fade target
module_fadeR:	.block 1 ; module volume fade rate
module_fadeC:	.block 1 ; timer counter

patt_addr:	.block 2
patt_rows:	.block 1

pattjump_index:	.block 1 ; 0 = no pattern jump
patt_update:	.block 1 ; PATTERN UPDATE FLAGS

ch_start:
ch_pitch_l:	.block 8
ch_pitch_h:	.block 8
ch_volume:	.block 8 ; 0..64

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
MAX_ADSR_CHANNELS:	=3
ch_ad:		.block MAX_ADSR_CHANNELS
ch_sr:		.block MAX_ADSR_CHANNELS
ch_end:

drop:		.block 2
; channel processing variables:
t_hasdata:	.block 1
;t_sampoff:	.block 1
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

CF_NOTE		=1
CF_INSTR	=2
CF_VCMD		=4
CF_CMD		=8
CF_KEYON	=16
CF_FADE		=32
CF_SURROUND	=64
CF_MUTE		=128

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
filter_time:		.block 1
filter_values:		.block 8
fm_blocks:		.block 1
fm_car_freq:		.block 1
fm_car_phase:		.block 1
fm_count:		.block 1
fm_mod_amp:		.block 1
fm_mod_freq:		.block 1
fm_mod_phase:		.block 1
fm_wave:		.block 1
;-------------------------------;
mod_mode:		.block 1;
;-------------------------------;
MO_CHFLTSWP		=1	; 0: channel filter sweep (off/on)
MO_CHFLTZMODE		=2	; 1: channel filter sweep zmode (off/on)
MO_DROP			=4	; 2: drop pitch (off/on)
MO_EVOLINC		=8	; 3: filter sweep evol (dec/inc)
MO_FM_MODAMP		=16	; 4: adjust fm vol (off/on)
MO_GXXVOL		=32	; 5: gxx volume slide (off/on)
;-------------------------------;
mod_special:		.block 1;
;-------------------------------;
MS_ACTIVE		=1	; 0: (inactive/active)
MS_FM_ACTIVE		=2	; 1: fm (off/on)
MS_GXXVIB		=4	; 2: gxx vibrato (off/on)
MS_FM_VIBRATO		=8	; 3: s3[8-f] = fm+vibrato (off/on)
MS_PATTERNJUMP		=16	; 4: (off/on)
MS_SWINGODD		=32	; 5: swing tempo (even/odd)
MS_SWINGTEMPO		=64	; 6: swing tempo (off/on)
MS_TREMOLO		=128	; 7: (off/on)
;-------------------------------;
noise_sweep_endmax:	.block 1
noise_sweep_endmin:	.block 1
noise_sweep_start:	.block 1
noise_time:		.block 1
noise_value:		.block 1
;-------------------------------;
special:		.block 1;
;-------------------------------;
;			=1	; 0: 
SF_FMWAVEFORM		=2	; 1: (vibrato waveform/fm waveform)
SF_NOISEINC		=4	; 2: noise frequency (dec/inc)
SF_NOISEMODE		=8	; 3: (normal/ping pong)
SF_NOISEREPEAT		=16	; 4: (once/repeat)
SF_NOISESWEEP		=32	; 5: noise frequency sweep (off/on)
SF_WAVETABLE		=64	; 6: (disable/enable)
SF_WTDIR		=128	; 7: (inc/dec)
;-------------------------------;
swing_tempo_mod:	.block 1
wt_cur:			.block 1
wt_max:			.block 1
wt_min:			.block 1
wt_time:		.block 1

DEFAULT_EVOL_MAX:	=64
DEFAULT_EVOL_MIN:	=32
DEFAULT_FILTER_DELAY1:	=10
DEFAULT_FILTER_DELAY2:	=12
DEFAULT_FILTER_DELAY3:	=14
DEFAULT_FILTER_TIME:	=080h
DEFAULT_MIN_BPFILTER:	=033h
DEFAULT_MAX_NOISE:	=01fh
DEFAULT_MODVOL:		=08fh
DEFAULT_MVOL:		=07fh
DEFAULT_NOISE_TIME:	=080h
DEFAULT_RAMP_POS:	=040h
DEFAULT_RAMP_NEG:	=0bfh
DEFAULT_SQ_POS:		=038h
DEFAULT_SQ_NEG:		=0c7h
DEFAULT_SWING:		=1
DEFAULT_TEMPO:		=4eh	; original snesmod value = 50h
DEFAULT_VOL_SAT:	=64
DEFAULT_WT_MAX:		=7
DEFAULT_WT_MIN:		=0
DEFAULT_WT_TIME:	=16

;-------------------------------;
MAX_ZP_CLEAR:		 	; do not clear comms_v or xfer_address!!
;-------------------------------;
comms_v:	.block 1	; communication variable
xfer_address:	.block 2	;
;-------------------------------;
STREAM_REGION = 0FFh

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
; 0100 - 01FF   Page 1, stack space
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
	mov	comms_v, #0				;
	mov	SPC_PORT1, #0				; reset some ports
	mov	SPC_PORT2, #0				;
	mov	SPC_PORT3, #0				;
	mov	SPC_CONTROL, #0				; reset	control
	mov	SPC_TIMER1, #255			; reset fade timer
							;---------------------
	mov	SPC_DSPA, #DSP_DIR			; set source dir
	mov	SPC_DSPD, #HBYTE(SampleDirectory)	;
;-------------------------------------------------------;---------------------
	mov	xfer_address, #LBYTE(MODULE)		; reset transfer
	mov	xfer_address+1, #HBYTE(MODULE)		; address
;-------------------------------------------------------;---------------------
	mov	a, #LBYTE(__BRK_ROUTINE__)		; set BRK/TCALL0 vector
	mov	!0FFDEH, a				;
	mov	a, #HBYTE(__BRK_ROUTINE__)		;
	mov	!0FFDFH, a				;
;-------------------------------------------------------;---------------------
	mov	SPC_CONTROL, #%110
	bra	main_loop		; patch for it->spc conversion
;---------------------------------------;
	call	Module_Stop		;
	mov	a, #0			;
	call	Module_Start		;
;-----------------------------------------------------------------------------
main_loop:
;-----------------------------------------------------------------------------
	SPROC2
	call	ProcessComms
	bbc0	mod_special, main_loop			; test MS_ACTIVE
;-------------------------------------------------------
	SPROC
	call	ProcessFade
	SPROC
	call	Module_Update
;-------------------------------------------------------
update_ports:
;-------------------------------------------------------
	mov	SPC_PORT2, STATUS
	mov	SPC_PORT3, mod_position
;-------------------------------------------------------
	bbc6	special, skip_wt			; test SF_WAVETABLE
;-------------------------------------------------------
	inc	current_wt_time
	cmp	current_wt_time, wt_time
	bne	skip_wt
;-------------------------------------------------------
	mov	current_wt_time, #0
	mov	y, wt_cur
	SPROC
;-------------------------------------------------------
	bbc2	mod_mode, skip_drop			; test MO_DROP
	inc	drop
	inc	drop
	cmp	drop, #0
	bne	skip_drop
	inc	drop+1
;-------------------------------------------------------
skip_drop:
;-------------------------------------------------------
	call	WaveTable
;-------------------------------------------------------
skip_wt:
;-------------------------------------------------------
	bbc0	mod_mode, skip_filter_sweep		; test MO_CHFLTSWP
;-------------------------------------------------------
	inc	current_filter_time
	cmp	filter_time, current_filter_time
	bne	skip_filter_sweep
;-------------------------------------------------------
	mov	current_filter_time, #0
	SPROC
	call	ChannelFilterSweep
;-------------------------------------------------------
skip_filter_sweep:
;-------------------------------------------------------
	bbc5	special, skip_noise_freq		; test SF_NOISESWEEP
;-------------------------------------------------------
	inc	current_noise_time
	cmp	noise_time, current_noise_time
	bne	skip_noise_freq
;-------------------------------------------------------
	mov	current_noise_time, #0
	SPROC
	call	NoiseFreqSweep
;-------------------------------------------------------
skip_noise_freq:
;-------------------------------------------------------
	;eor	mod_mode, #MO_FM_MODAMP
	;bbc4	mod_mode, main_loop			; test MO_FM_MODAMP
;-------------------------------------------------------
	inc	fm_count
	mov	y, fm_count
	call	Sine
	mov	fm_mod_amp, a
	bra	main_loop

;=============================================================================
ChannelFilterSweep:
;=============================================================================
	call	EVOLSweep		; m0 = current channel target value
	mov	m2, #0			; m1 = current value
	mov	m3, #0			; m2 = total pos filter values
	mov	x, #7			; m3 = total neg filter values
;---------------------------------------; m4 = tmp for converting neg to pos
_filter_sweep:
;---------------------------------------;
	push	x			;
;---------------------------------------;
_overflow_check:
;---------------------------------------;
	mov	a, !CBITS+x		;
	mov	SPC_DSPA, a		;
	mov	a, SPC_DSPD		;
	mov	m1, a			;
	bmi	_check_neg		;
;---------------------------------------;
	clrc				;
	adc	m2, m1			; add positive values together
	bra	_dex			;
;---------------------------------------;
_check_neg:
;---------------------------------------;
	eor	a, #0FFh		;
	inc	a			;
	mov	m4, a			;
	clrc				;
	adc	m3, m4			; add negative values together
					;
_dex:	dec	x			;
	bpl	_overflow_check		;
;---------------------------------------;
	pop	x			;
	bra	_channel_mode		;
;---------------------------------------;
_cm_dx:	dec	x			;
;---------------------------------------;
_channel_mode:
;---------------------------------------;
	mov	a, filter_values+x	; get target filter value for current channel
	cmp	a, #80h			; if value is +128, move to next channel
	beq	_cm_dx			; skipping the overflow check
					;
	mov	m0, a			; m0 = current channel target value
;---------------------------------------;
_select_channel:
;---------------------------------------;
	mov	a, !CBITS+x		;
	mov	SPC_DSPA, a		;
	mov	a, SPC_DSPD		;  a = current filter value
	mov	m1, a			; m1 = current filter value
	bmi	_from_neg		;
	beq	_from_zero		;
;---------------------------------------;
_from_pos:
;---------------------------------------;
	mov	a, m0			;
	bmi	_filter_dec		;
;---------------------------------------;
_pos_to_pos:
;---------------------------------------;
	cmp	m0, m1			;
	bcc	_filter_dec		;
	cmp	m2, #7Fh		; do the total positive values exceed 126?
	bcc	_filter_inc		; if not decrease is ok (inc is negative dec)
	bra	_skip_channel		; total of positive values are too high
;---------------------------------------;
_from_neg:
;---------------------------------------;
	mov	a, m0			;
	bpl	_filter_inc		; target is a positive value
;---------------------------------------;
_neg_to_neg:
;---------------------------------------;
	cmp	m0, m1			;
	bcs	_filter_inc		;
	cmp	m3, #7Fh		; do the total negative values exceed 126?
	bcc	_filter_dec		; if not increase is ok (dec is negative inc)
	bra	_skip_channel		; total of positive values are too high
;---------------------------------------;
_from_zero:
;---------------------------------------;
	mov	a, m0			;
	cmp	m0, m1			; target, current value
	bpl	_filter_inc		;
;---------------------------------------;
_filter_dec:
;---------------------------------------;
	dec	m1			; decrease current filter value
	bra	_store_new_value	;
;---------------------------------------;
_filter_inc:
;---------------------------------------;
	inc	m1			; increase current filter value
;---------------------------------------;
_store_new_value:
;---------------------------------------;
	mov	SPC_DSPD, m1		; store current filter value
	cmp	m0, m1			; does current filter value equal target value?
	bne	_skip_channel		; if not, keep current channel filter active
;---------------------------------------;
_reset_fv:
;---------------------------------------;
	mov	a, #80h			; disable filter sweep
	mov	filter_values+x, a	; for current channel
;---------------------------------------;
_skip_channel:
;---------------------------------------;
	dec	x			;
	bpl	_filter_sweep		;
	ret				;
					;
;=============================================================================
EVOLSweep:
;=============================================================================
	cmp	evol_time, #0
	beq	_end_evol
	inc	current_evol_time
	cmp	current_evol_time, evol_time
	bne	_end_evol
	mov	current_evol_time, #0

_det_dir:
	bbc3	mod_mode, _dec_evol		; test MO_EVOLINC
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
	bmi	_set
	eor	a, #255
	inc	a
_set:	call	Command_EchoVolume2

_end_evol:
	ret

;=============================================================================
NoiseFreqSweep:
;=============================================================================
	bbs2	special, _do_inc		; test SF_NOISEINC

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
	bbc3	special, _check_repeat		; test SF_NOISEMODE
	eor	special, #SF_NOISEINC
	bra	_do_noise

_check_repeat:
	bbc4	special, _turn_nfc_off		; test SF_NOISEREPEAT
	mov	noise_value, noise_sweep_start
	bra	_do_noise

_turn_nfc_off:
	and	special, #~SF_NOISESWEEP

_do_noise:
	call	SCommand_NoiseFreq1b

check_back_later:
	ret

;=============================================================================
WaveTable:
;=============================================================================
	mov	a, !WAVETABLE_L+y	; wave address low
	mov	!SampleDirectory+4, a	; sample start
	mov	!SampleDirectory+6, a	; loop start
	mov	a, #HBYTE(WT_SAMPLE1)	; wave address high
	cmp	y, #7			;
	bcc	_skip_inc		;
;---------------------------------------;
	inc	a			;
;---------------------------------------;
_skip_inc:
;---------------------------------------;
	mov	!SampleDirectory+5, a	; sample start
	mov	!SampleDirectory+7, a	; loop start
	bbc7	special, _wt_increase	; test SF_WTDIR
;---------------------------------------;
	dec	y			;
	cmp	y, wt_min		; if minimum is reached switch direction
	beq	_wt_swap_dir		;
	bra	_wt_exit		;
;---------------------------------------;
_wt_increase:				;
;---------------------------------------;
	inc	y			;
	cmp	y, wt_max		; if maximum is reached switch direction
	bcs	_wt_swap_dir		;
;---------------------------------------;
_wt_exit:				;
;---------------------------------------;
	mov	wt_cur, y		;
	ret				;
;---------------------------------------;
_wt_swap_dir:				;
;---------------------------------------;
	eor	special, #SF_WTDIR	;
	bra	check_back_later	;

;=============================================================================
ClearMemory:
;=============================================================================
        mov     x, #0
;=============================================================================
ClearMemoryX:
;=============================================================================
        mov     a, #0
_clrmem:
        mov     (X)+, a
        cmp     x, #MAX_ZP_CLEAR
        bne     _clrmem

	ret

;=============================================================================
ResetSound:				; 76 bytes
;=============================================================================
	SETDSP( DSP_KOF, 0FFh );
	SETDSP( DSP_FLG, FLG_ECEN );
	SETDSP( DSP_PMON, 0 );
	SETDSP( DSP_EVOL, 0 );
	SETDSP( DSP_EVOLR, 0 );
	SETDSP( DSP_NON, 00h );
	SETDSP( DSP_KOF, 000h ); this is weird

	call	ClearMemory
	call	ResetMasterVolume
	mov	evol_max, #DEFAULT_EVOL_MAX
	mov	evol_min, #DEFAULT_EVOL_MIN
	mov	filter_time, #DEFAULT_FILTER_TIME
	mov	fm_blocks, #01h
	mov	module_vol, #DEFAULT_MODVOL
	mov	module_fadeT, #255
	mov	noise_sweep_endmax, #DEFAULT_MAX_NOISE
	mov	wt_max, #DEFAULT_WT_MAX

	ret

;=============================================================================
ProcessComms:				; 23 bytes
;=============================================================================
	cmp	comms_v, SPC_PORT1	; test for command
	bne	_new_message		;
	ret				; <no message>
;---------------------------------------;
_new_message:
;---------------------------------------;
	mov	comms_v, SPC_PORT1	; copy V
	mov	a, SPC_PORT0		; jump to message
	nop				; verify data
	cmp	a, SPC_PORT0		;
	bne	_new_message		;
	and	a, #127			; mask 7 bits
	asl	a			;
	mov	x, a			;
	jmp	[CommandTable+x]	;'
;-------------------------------------------------------------------
CommandTable:
;-------------------------------------------------------------------
	.word	CMD_LOAD		; 00h - load module
	.word	CMD_LOADWT		; 01h - change wavetable
	.word	CMD_POS			; 02h - CMD_VOL set volume DISABLED
	.word	CMD_PLAY		; 03h - play
	.word	CMD_STOP		; 04h - stop
	.word	CMD_MVOL		; 05h - set module volume
	.word	CMD_FADE		; 06h - fade module volume
	.word	CMD_RES			; 07h - reset spc
	;.word	CMD_NULL		; 08h - CMD_FX sound effect DISABLED
;-------------------------------------------------------------------
;-------------------------------------------------------------------
CommandRet:
;-------------------------------------------------------------------
	mov	SPC_PORT1, comms_v
	ret

;*******************************************************************
CMD_POS:
;*******************************************************************
	mov	a, SPC_PORT3
	call	DoSetPosition
	bra	CommandRet

;*******************************************************************
CMD_FADE:
;*******************************************************************
	or	STATUS, #STATUS_F
	mov	SPC_PORT2, STATUS
	mov	module_fadeT, SPC_PORT3
	mov	module_fadeR, SPC_PORT2
	bra	CommandRet

;*******************************************************************
CMD_STOP:
;*******************************************************************
	call	Module_Stop
CMD_NULL:	;*
	bra	CommandRet

;*******************************************************************
CMD_MVOL:
;*******************************************************************
	mov	module_vol, SPC_PORT3
	mov	module_fadeT, SPC_PORT3
	bra	CommandRet

;*******************************************************************
CMD_LOAD:
;*******************************************************************
	call	Module_Stop
	mov	xfer_address, #LBYTE(MODULE)	; reset transfer address
	mov	xfer_address+1, #HBYTE(MODULE)	;
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

;-------------------------------------------------------------------
RegisterSource:
;-------------------------------------------------------------------
	mov	a, xfer_address		;
	mov	!SampleDirectory+y, a	; sample start
	clrc				;
	adc	a, SPC_PORT2		;
	mov	!SampleDirectory+2+y, a	; loop start
					;
	mov	a, xfer_address+1	;
	mov	!SampleDirectory+1+y, a	; sample start
					;
	adc	a, SPC_PORT3		;
	mov	!SampleDirectory+3+y, a	; loop start

	call	StartTransfer		;
					;
	bra	_wait_for_sourcen	; load next source

_end_of_sources:			; if p0 == 0:
	bra	CommandRet		;

;*******************************************************************
CMD_LOADWT:
;*******************************************************************
	mov	xfer_address, #LBYTE(WT_SAMPLE1)
	mov	xfer_address+1, #HBYTE(WT_SAMPLE1)
	call	StartTransfer
	bra	CommandRet
;===================================================================
StartTransfer:
;===================================================================
	mov	x, comms_v		; start transfer
	mov	y, #0			;
	mov	SPC_PORT1, x		;
;---------------------------------------;---------------------------
DoTransfer:
;---------------------------------------;---------------------------
	cmp	x, SPC_PORT1		; wait for data
	beq	DoTransfer		;
;---------------------------------------;
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
;---------------------------------------;---------------------------
_cont1:	cmp	x, #0			; loop until x=0
	bne	DoTransfer		;
;---------------------------------------;---------------------------
	mov	m0, y
	clrc
	adc	xfer_address, m0
	adc	xfer_address+1, #0
	mov	comms_v, x
	ret
;-------------------------------------------------------------------
_inc_address:
;-------------------------------------------------------------------
	inc	xfer_address+1
	bra	_cont1

;*****************************************************************************
SetupEcho:
;*****************************************************************************
	mov	a, !MODULE+MOD_EDL	; ESA = stream_region - EDL*8
	beq	_skip_enable_echo	; skip all of this if echo isn't enabled
;---------------------------------------;---------------------------
	xcn	a			; max = stream_region -1
	lsr	a			;
	mov	m0, a			;
	mov	a, #STREAM_REGION	;
	setc				;
	sbc	a, m0			;
	cmp	a, #STREAM_REGION	;
	bne	_edl_not_ss		;
;---------------------------------------;---------------------------
	dec	a			;
;---------------------------------------;---------------------------
_edl_not_ss:
;---------------------------------------;---------------------------
	mov	SPC_DSPA, #DSP_ESA	;
	mov	SPC_DSPD, a		;
					;
	mov	m0+1, a			; clear memory region used by echo
	mov	m0, #0			;
	mov	a, #0			;
	mov	y, #0			;
;---------------------------------------;---------------------------
_clearmem:
;---------------------------------------;---------------------------
	mov	[m0]+y, a		;
	inc	y			;
	bne	_clearmem		;
;---------------------------------------;---------------------------
	inc	m0+1			;
	cmp	m0+1, #STREAM_REGION	;
	bne	_clearmem		;
;---------------------------------------;---------------------------
	mov	SPC_DSPA, #DSP_EON	; copy EON
	mov	a, !MODULE+MOD_EON	;
	mov	SPC_DSPD, a		;
					;
	mov	SPC_DSPA, #DSP_EDL	; read old EDL, set new EDL
	mov	y, SPC_DSPD		;
	mov	a, !MODULE+MOD_EDL	;
	mov	SPC_DSPD, a		;
	;-------------------------------;---------
	; delay EDL*16ms before enabling echo
	; 16384 clks * EDL
	; EDL<<14 clks
	;
	; run loop EDL<<10 times
	;-------------------------------;---------
	mov	a, y			;
	asl	a			;
	asl	a			;
	inc	a			;
	mov	m0+1, a			;
	mov	m0, #0			;
;---------------------------------------;---------------------------
_delay_16clks:
;---------------------------------------;---------------------------
	cmp	a, [0]+y		;
	decw	m0			;
;---------------------------------------;---------------------------
	bne	_delay_16clks
;---------------------------------------;---------------------------
	call	ResetAll		; Reset EVOL, EFIR, EFB
	mov	SPC_DSPA, #DSP_FLG	; clear ECEN
	mov	SPC_DSPD, #0
;-------------------------------------------------------------------
_skip_enable_echo:
;-------------------------------------------------------------------
	ret

;*****************************************************************************
Module_Stop:
;*****************************************************************************
	call	ResetSound
	mov	SPC_CONTROL, #%110
	and	mod_special, #~MS_ACTIVE
	ret

;*******************************************************************
CMD_PLAY:
;*******************************************************************
	call	Module_Stop
	mov	a, SPC_PORT3
	and	STATUS, #~STATUS_P
	mov	SPC_PORT2, STATUS
	mov	SPC_PORT1, comms_v
;*****************************************************************************
; play module...
;
; a = initial position
;*****************************************************************************
Module_Start:
;*****************************************************************************
	mov	mod_position, a
	call	ResetSound
;-----------------------------------------------------------------------------
;_zerofill_channel_data:
;-----------------------------------------------------------------------------
	;mov	x, #ch_start			; zerofill channel data
	;mov	a, #0				; already clearing zeropage
;-----------------------------------------------------------------------------
;_zerofill_ch:					; in reset sound...
;-----------------------------------------------------------------------------
	;mov	(x)+, a
	;cmp	x, #ch_end
	;bne	_zerofill_ch
;-----------------------------------------------------------------------------
	or	mod_special, #MS_ACTIVE
	mov	a, !MODULE+MOD_IS
	mov	mod_speed, a
	mov	a, !MODULE+MOD_IT
	call	Module_ChangeTempo
;-----------------------------------------------------------------------------
	;mov	a, !MODULE+MOD_IV
	;mov	mod_gvol, a

	;mov	x, #7
;-----------------------------------------------------------------------------
;_copy_cvolume:					; copy volume levels
;-----------------------------------------------------------------------------
	;mov	a, !MODULE+MOD_CV+x		;
	;mov	ch_cvolume+x, a			;
	;dec	x				;
	;bpl	_copy_cvolume			;
;-----------------------------------------------------------------------------
	mov	x, #7
;-----------------------------------------------------------------------------
_copy_cpan:
;-----------------------------------------------------------------------------
	mov	a, !MODULE+MOD_CP+x
	cmp	a, #65
	bcs	_cpan_surround
	mov	ch_panning+x, a
	bra	_cpan_normal
;-----------------------------------------------------------------------------
_cpan_surround:
;-----------------------------------------------------------------------------
	mov	a, #32
	mov	ch_panning+x, a
	mov	a, #CF_SURROUND
	mov	ch_flags+x, a
;-----------------------------------------------------------------------------
_cpan_normal:
;-----------------------------------------------------------------------------
	dec	x
	bpl	_copy_cpan
;-----------------------------------------------------------------------------
	call	SetupEcho

	mov	a, mod_position
	call	Module_ChangePosition

	; start timer
	mov	SPC_CONTROL, #%111

	or	STATUS, #STATUS_P
	mov	SPC_PORT2, STATUS

	ret


;*****************************************************************************
; a = new BPM value
;*****************************************************************************
Module_ChangeTempo:
;*****************************************************************************
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

;*****************************************************************************
; process module fading
;*****************************************************************************
ProcessFade:
;*****************************************************************************
	mov	a, SPC_COUNTER1
	beq	_skipfade
	or	STATUS, #STATUS_F
	mov	a, module_vol
	cmp	a, module_fadeT
	beq	_nofade
	bcc	_fadein
;-----------------------------------------------------------------------------
_fadeout:
;-----------------------------------------------------------------------------
	sbc	a, module_fadeR
	bcs	_fade_satL
	mov	module_vol, module_fadeT
	ret
;-----------------------------------------------------------------------------
_fade_satL:
;-----------------------------------------------------------------------------
	cmp	a, module_fadeT
	bcs	_fadeset
	mov	module_vol, module_fadeT
	ret
;-----------------------------------------------------------------------------
_fadein:
;-----------------------------------------------------------------------------
	adc	a, module_fadeR
	bcc	_fade_satH
	mov	module_vol, module_fadeT
	ret
;-----------------------------------------------------------------------------
_fade_satH:
;-----------------------------------------------------------------------------
	cmp	a, module_fadeT
	bcc	_fadeset
	mov	module_vol, module_fadeT
	ret
;-----------------------------------------------------------------------------
_fadeset:
;-----------------------------------------------------------------------------
	mov	module_vol, a
	ret
;-----------------------------------------------------------------------------
_nofade:
;-----------------------------------------------------------------------------
	and	STATUS, #~STATUS_F
;-----------------------------------------------------------------------------
_skipfade:
_no_tick:
;-----------------------------------------------------------------------------
	ret

;*****************************************************************************
; Update module playback
;*****************************************************************************
Module_Update:
;*****************************************************************************
	mov	a, SPC_COUNTER0		; check for a tick
	beq	_no_tick		;
;---------------------------------------;
					;
	;-------------------------------;
	; module tick!!!
	;-------------------------------;
					;
	cmp	mod_tick, #0		;
	bne	_skip_read_pattern	;
;---------------------------------------;
	mov	y, #1			; skip hints
	mov	a, [patt_addr]+y	; copy update flags
	inc	y			;
	mov	patt_update, a		;
	mov	m1, a			;
	mov	x, #0			;
	lsr	m1			; test first bit
	bcc	_no_channel_data	;
;---------------------------------------;
_read_pattern_data:
;---------------------------------------;
	SPROC				;
	mov	a, [patt_addr]+y	; read maskvar
	inc	y			;
	mov	m0, a			;
	bbc4	m0, _skip_read_note	; test/read new note
	mov	a, [patt_addr]+y	;
	inc	y			;
	mov	ch_note+x, a		;
;---------------------------------------;
_skip_read_note:
;---------------------------------------;
	bbc5	m0, _skip_read_instr	; test/read new instrument
	mov	a, [patt_addr]+y	;
	inc	y			;
	mov	ch_instr+x, a		;
;---------------------------------------;
_skip_read_instr:
;---------------------------------------;
	bbc6	m0, _skip_read_vcmd	; test/read new vcmd
	mov	a, [patt_addr]+y	;
	inc	y			;
	mov	ch_vcmd+x, a		;
;---------------------------------------;
_skip_read_vcmd:
;---------------------------------------;
	bbc7	m0, _skip_read_cmd	; test/read new cmd+param
	mov	a, [patt_addr]+y	;
	inc	y			;
	mov	ch_command+x, a		;
	mov	a, [patt_addr]+y	;
	inc	y			;
	mov	ch_param+x, a		;
;---------------------------------------;
_skip_read_cmd:
;---------------------------------------;
	and	m0, #0Fh		; set flags (lower nibble)
	mov	a, ch_flags+x		;
	and	a, #0F0h		;
	or	a, m0			;
	mov	ch_flags+x, a		;
;---------------------------------------;
_no_channel_data:
_rp_nextchannel:
;---------------------------------------;
	inc	x			; increment index
	lsr	m1			; shift out next bit
	bcs	_read_pattern_data	; process if set
	bne	_no_channel_data	; loop if bits remain (upto 8 iterations)
;---------------------------------------;
	mov	m0, y			; add offset to pattern address
	clrc				;
	adc	patt_addr, m0		;
	adc	patt_addr+1, #0		;
					;
	bbc6	mod_special, _no_change	; test MS_SWINGTEMPO
;---------------------------------------;
_swing_tempo:
;---------------------------------------;
	mov	a, mod_speed_bk	
	bbs5	mod_special, _swing_even; test MS_SWINGODD
;---------------------------------------;
_swing_odd:
;---------------------------------------;
	setc				;
	adc	a, swing_tempo_mod	;
;---------------------------------------;
_swing_even:
;---------------------------------------;
	eor	mod_special, #MS_SWINGODD
;---------------------------------------;
	mov	mod_speed, a
;---------------------------------------;
_no_change:
_skip_read_pattern:
;---------------------------------------;-------------------------------------
	mov	x, #0			; update module channels
	mov	a, patt_update		;
;---------------------------------------;
_muc_loop:
;---------------------------------------;
	lsr	a

	push	a

	mov	a, #0
	rol	a
	mov	t_hasdata, a

;-----------------------------------------------------------------------------
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
;-----------------------------------------------------------------------------
_muc_nopatterndata:
;-----------------------------------------------------------------------------
	call	Channel_CopyTemps
;-----------------------------------------------------------------------------
_muc_pa:
;-----------------------------------------------------------------------------
	call	Channel_ProcessAudio
;-----------------------------------------------------------------------------
	pop	a

	inc	x
	cmp	x, #8
	bne	_muc_loop
;-----------------------------------------------------------------------------
	inc	mod_tick			; increment tick until >= SPEED
	cmp	mod_tick, mod_speed		;
	bcc	_exit_tick			;
;-----------------------------------------------;
	mov	mod_tick, #0			;
	bbc4	mod_special, _no_pattjump	; test MS_PATTERNJUMP
	mov	a, pattjump_index		;
	bra	Module_ChangePosition		;
;-----------------------------------------------;
_no_pattjump:
;---------------------------------------;
	inc	mod_row			; increment row until > PATTERN_ROWS
	beq	_adv_pos		;
	cmp	mod_row, patt_rows	;
	beq	_exit_tick		;
	bcc	_exit_tick		;
;---------------------------------------;
_adv_pos:
;---------------------------------------;
	mov	a, mod_position		; advance position
	inc	a			;
	bra	Module_ChangePosition	;
;---------------------------------------;
_exit_tick:
;---------------------------------------;
	ret				;
;---------------------------------------;


;*****************************************************************************
; set sequence position
;
; a=position
;*****************************************************************************
Module_ChangePosition:
;*****************************************************************************
	mov	y, a
;-----------------------------------------------------------------------------
_skip_pattern:
;-----------------------------------------------------------------------------
	mov	a, !MODULE+MOD_SEQU+y	;
	cmp	a, #254			; skip +++
	bne	_not_plusplusplus	;
	inc	y			;
	bra	_skip_pattern		;
;-----------------------------------------------------------------------------
_not_plusplusplus:
;-----------------------------------------------------------------------------
	cmp	a, #255			; restart on ---
	bne	_not_end		;
	mov	y, #0			;
	bra	_skip_pattern		;
;-----------------------------------------------------------------------------
_not_end:
;-----------------------------------------------------------------------------
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

	and	mod_special, #~MS_PATTERNJUMP
	mov	mod_tick, #0
	mov	mod_row, #0
	ret


;*****************************************************************************
Channel_ProcessData:
;*****************************************************************************
	cmp	mod_tick, #0		; skip tick0 processing on other ticks
	bne	_cpd_non0		;
					;
	mov	a, ch_flags+x		;
	mov	m6, a			;
	bbc0	m6, _cpd_no_note	; test for note
;---------------------------------------;
	mov	a, ch_note+x		;
	cmp	a, #254			; test notecut/noteoff
	beq	_cpd_notecut		;
	bcs	_cpd_noteoff		;
;---------------------------------------;
_cpd_note:				; don't start note on glissando
;---------------------------------------;
	bbc3	m6, _cpdn_test_for_glis	;
	mov	a, ch_command+x		;
	cmp	a, #7			;
	beq	_cpd_note_next		;
;---------------------------------------;
_cpdn_test_for_glis:
;---------------------------------------;
	call	Channel_StartNewNote	;
	bra	_cpd_note_next		;
;---------------------------------------;
_cpd_notecut:				;notecut:
;---------------------------------------;
	mov	a, #0			; cut volume
	mov	ch_volume+x, a		;
	and	m6, #~CF_NOTE		; clear note flag
	bra	_cpd_note_next		;
;---------------------------------------;
_cpd_noteoff:				;noteoff:
;---------------------------------------;
	and	m6, #~(CF_NOTE|CF_KEYON); clear note and keyon flags
;---------------------------------------;
_cpd_note_next:	
;---------------------------------------;
	bbc1	m6, _cpdn_no_instr	; apply instrument SETPAN
;---------------------------------------;
	mov	y, #INS_SETPAN		;
	mov	a, [p_instr]+y		;
	bmi	_cpdi_nsetpan		;
;---------------------------------------;
	mov	ch_panning+x, a		;
;---------------------------------------;
_cpdi_nsetpan:
;---------------------------------------;
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
;---------------------------------------;
	mov	ch_panning+x, a		;
;---------------------------------------;
_cpdi_nsetpan_s:
_cpdi_nosample:	
_cpdn_no_instr:	
;---------------------------------------;
	and	m6, #~CF_NOTE		;
;---------------------------------------;
_cpd_no_note:
;---------------------------------------;
	mov	a, m6			; save flag mods
	mov	ch_flags+x, a		;
					;
	and	a, #(CF_NOTE|CF_INSTR)	; test for note or instrument
	beq	_no_note_or_instr	;
;---------------------------------------;
	call	Channel_ResetVolume	; and reset volume things
;---------------------------------------;
_no_note_or_instr:			;
_cpd_non0:				; nonzero ticks: just update audio
;---------------------------------------;
	SPROC				;
					;
	mov	a, ch_flags+x		; test and process volume command
	and	a, #CF_VCMD		;
	beq	_skip_vcmd		;
;---------------------------------------;
	call	Channel_ProcessVolumeCommand
;---------------------------------------;
_skip_vcmd:
;---------------------------------------;
	SPROC				;
	call	Channel_CopyTemps	; copy t values
					;
	mov	a, ch_flags+x		; test and process command
	and	a, #CF_CMD		;
	beq	_skip_cmd		;
;---------------------------------------;
	call	Channel_ProcessCommand	;
;---------------------------------------;
_skip_cmd:
;---------------------------------------;
	ret				;
					;
;*****************************************************************************
Channel_CopyTemps:
;*****************************************************************************
	mov	a, ch_pitch_l+x		; prepare for effects processing.....
	mov	y, ch_pitch_h+x		;
	subw	ya, drop		;
	movw	t_pitch, ya		;
	mov	a, ch_volume+x		;
	mov	y, ch_panning+x		;
	movw	t_volume, ya		;
	;mov	t_sampoff, #0		;

	ret

;*****************************************************************************
Channel_StartNewNote:
;*****************************************************************************
	mov	a, ch_note+x		; pitch = note * 64
	mov	y, #64			;
	mul	ya			;
	mov	ch_pitch_l+x, a		;
	mov	ch_pitch_h+x, y		;
					;
	mov	a, ch_instr+x		; test for instrument and copy sample!
	beq	_csnn_no_instr		;
;---------------------------------------;
	mov	y, #INS_SAMPLE		;
	mov	a, [p_instr]+y		;
	mov	ch_sample+x, a		;
;---------------------------------------;
_csnn_no_instr:
;---------------------------------------;
	or	t_flags, #TF_START	; set start flag
	ret

;*****************************************************************************
Channel_ResetVolume:
;*****************************************************************************
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

;*****************************************************************************
Channel_ProcessAudio:
;*****************************************************************************
	SPROC					;
	mov	y, ch_sample+x			; m5 = sample address
;	beq	_cpa_nsample			;
	mov	a, !MODULE+MOD_STABLE_L+y	;
	mov	m5, a				;
	mov	a, !MODULE+MOD_STABLE_H+y	;
	mov	m5+1, a				;
;-----------------------------------------------;
_cpa_nsample:					
;-----------------------------------------------;
	call	Channel_ProcessEnvelope		;
						;
	mov	a, ch_flags+x			; process FADE
	and	a, #CF_FADE			;
	beq	_skip_fade			;
;-----------------------------------------------;
	mov	a, ch_fadeout+x			
	setc					
	mov	y, #INS_FADEOUT			
	sbc	a, [p_instr]+y			
	bcs	_subfade_noverflow			
;-----------------------------------------------
	mov	a, #0				
;-----------------------------------------------
_subfade_noverflow:				
;-----------------------------------------------
	mov	ch_fadeout+x, a			
;-----------------------------------------------
_skip_fade:					
;-----------------------------------------------
	;mov	a, !BITS+x			
	;and	a, #0				
	;bne	_sfx_override			
;-----------------------------------------------;
	mov	a, t_flags			; exit if 'note delay' is set
	and	a, #TF_DELAY			;
	beq	_cpa_ndelay			;
;-----------------------------------------------;
_sfx_override:					
;-----------------------------------------------
	ret					
;-----------------------------------------------
_cpa_ndelay:					
;-----------------------------------------------;
						;
	;---------------------------------------;
	; COMPUTE VOLUME:
	; V*SV*VEV*FADE
	; m0 = result (0..255)
	;---------------------------------------;
						;
	mov	y, #INS_GVOL			;
	mov	a, [p_instr]+y			;
						;
	push	a				;
						;
	mov	y, #SAMP_GVOL			;
	mov	a, [m5]+y			;
						;
	push	a				;
						;
	mov	a, t_volume			; y = 8-BIT VOLUME
	asl	a				;
	asl	a				;		
	bcc	_cpa_clamp_vol			;	
	mov	a, #255				;
;-----------------------------------------------;
_cpa_clamp_vol:					;
;-----------------------------------------------;
	mov	y, a				;
						;
	pop	a				; *= SV
						;
	asl	a				;
	asl	a				;
	bcs	_calcvol_skip_sv		;
;-----------------------------------------------;
	mul	ya				;
;-----------------------------------------------;
_calcvol_skip_sv:				;
;-----------------------------------------------;
	pop	a				;
						;
	asl	a				;
	bcs	_calcvol_skip_iv		;
	mul	ya				;
;-----------------------------------------------;
_calcvol_skip_iv:				;
;-----------------------------------------------;
	mov	a, t_env			; *= VEV
	mul	ya				;
						;
	mov	a, ch_fadeout+x			; *= FADE
	mul	ya				;
						;
	mov	a, module_vol			;
	mul	ya				;
						;
	mov	a, y				; store 7bit result
	lsr	a				; 
	mov	m2, a				;
						;
	cmp	t_flags, #80h			;
	bcs	_dont_hack_gain			;
	cmp	a, #0				;
	bne	_gain_not_zero			; map value 0 to fast linear decrease
;-----------------------------------------------;
	mov	a, #(LIN_DEC|GAIN_RATE)		;
;-----------------------------------------------;
_gain_not_zero:					;
;-----------------------------------------------;
	cmp	a, #126				; map value 126 to fast linear increase
	bne	_gain_not_max			; ...127 not reached...
;-----------------------------------------------;
	mov	a, #(LIN_INC|GAIN_RATE)		;
;-----------------------------------------------;
_gain_not_max:					;
;-----------------------------------------------;
	mov	m2, a				;
;-----------------------------------------------;
_dont_hack_gain:				;
;-----------------------------------------------;
	mov	a, ch_flags+x			; [KFF] added in pitchmod
	and	a, #CF_MUTE			;
	beq	panning				;
	mov	m1, #0				;
	mov	m1+1, #0			;
	bra	_cpa_nsurround			;
;-----------------------------------------------;
panning:					
;-----------------------------------------------;
						;
	;---------------------------------------;
	; compute PANNING
	;---------------------------------------;
						;
	mov	a, t_panning			; a = panning 0..127	
	asl	a				;	
	bpl	_clamppan			;
;-----------------------------------------------;
	dec	a				;
;-----------------------------------------------;
_clamppan:
;-----------------------------------------------;	
	mov	m1+1, a				; store panning (volume) levels
	eor	a, #127				;
	mov	m1, a				;

	mov	a, ch_flags+x			; apply surround (R = -R)
	and	a, #CF_SURROUND			;
	beq	_cpa_nsurround			;
	eor	m1+1, #255			;
	inc	m1+1				;
;-----------------------------------------------;
_cpa_nsurround:					;
;-----------------------------------------------;
						;
	;---------------------------------------;
	; compute PITCH
	;---------------------------------------;
						;
	cmp	x, #1				;
						;
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
;-----------------------------------------------;

	;-----------------------------------------------------------------;
	; Negative octave handling by KungFuFurby 12/16/15 - 12/17/15     ;
	; Negative octave detected!                                       ;
	; This code ensures that the SPC700 can handle lower pitches than ;
	; what SNESMod normally supports.                                 ;
	;-----------------------------------------------------------------;
						;
	eor	a, #0FFh			; Prevent glitched
	mov	y, a				; division read.
	mov	a, !LUT_DIV3+y			; m0 = octave
	eor	a, #0FFh			;
	mov	m0, a				;
	bra	_oct_cont			;
;-----------------------------------------------;
_positive_oct:
;-----------------------------------------------;
	mov	y, a				; m0 = octave
	mov	a, !LUT_DIV3+y			;
	mov	m0, a				;
;-----------------------------------------------;
_oct_cont:
;-----------------------------------------------;
	asl	a				; m3 -= (oct*3) << 8
	clrc					; Safety clear for negative
	adc	a, m0				; octaves
	mov	m0+1, a				;
	mov	a, m3+1				;
	setc					;
	sbc	a, m0+1				;
						;
	asl	m3				; m3 = m3*2 + LUT_FTAB base
	rol	a				;
	adc	m3, #LBYTE(LUT_FTAB)		;
	adc	a, #HBYTE(LUT_FTAB)		; 
	mov	m3+1, a				;
						;
	mov	y, #0				; read ftab[f]
	mov	a, [m3]+y			;
	mov	m4, a				;
	inc	y				;
	mov	a, [m3]+y			;
						;
	push	a				;
						;
	mov	a, #8				; y = 8-oct
	setc					;
	sbc	a, m0				;
	mov	y, a				;
						;
	pop	a				; a,m4 = ftab value
	beq	_no_pitch_shift			; skip shift if 0
;-----------------------------------------------;
_cont_pitch_shift:
;-----------------------------------------------;
	lsr	a				; shift by (8-oct)
	ror	m4				;
	dbnz	y, _cont_pitch_shift		; (thanks KungFuFurby)

	;-----------------------------------------------------------------;
	; WARNING: More than eight pitch shifts are possible, so the code ;
	; has been compressed to a mere three lines. The only problem     ;
	; will be with glitched values out of range.                      ;
	;-----------------------------------------------------------------;
						
;-----------------------------------------------;
_no_pitch_shift:
;-----------------------------------------------;
	mov	m4+1, a				;
						;
	;---------------------------------------;
	; m1 = VOL/VOLR
	; m2 = GAIN
	; m4 = PITCH
	;---------------------------------------;
						;
	mov	a, x				; DSPA = voices[x]
	xcn	a				;
	mov	SPC_DSPA, a			;
						;-----------------------------
	mov	a, t_flags			; test for KEYON
	and	a, #TF_START			;
	beq	_cpa_nstart			;-----------------------------
;-----------------------------------------------;keyon:
	mov	y, #SAMP_DINDEX			; set SRCN
	mov	a, [m5]+y			;
	or	SPC_DSPA, #DSPV_SRCN		;
	mov	SPC_DSPD, a			;-----------------------------
	;---------------------------------------;
	; **TODO: SAMPLE OFFSET
	;---------------------------------------;
	mov	SPC_DSPA, #DSP_KON		; set KON bit
	mov	a, !BITS+x			;
	mov	SPC_DSPD, a			;-----------------------------
	mov	a, x				; restore DSPA = voices[x]
	xcn	a				;
	mov	SPC_DSPA, a			;
;-----------------------------------------------;
_cpa_nstart:
;-----------------------------------------------;
	mov	SPC_DSPD, m1			; set VOLUME
	inc	SPC_DSPA			;
	mov	SPC_DSPD, m1+1			;
	inc	SPC_DSPA			;-----------------------------
	mov	SPC_DSPD, m4			; set PITCH
	inc	SPC_DSPA			;
	mov	SPC_DSPD, m4+1			;
	inc	SPC_DSPA			;
	inc	SPC_DSPA			;-----------------------------
						;
	cmp	x, #MAX_ADSR_CHANNELS		;
	bcs	_ch_direct_gain			;
	mov	a, ch_ad+x			; test to see if ADSR has been
	cmp	a, #ADSR			; set for channel
	bcs	_ch_adsr			;
;-----------------------------------------------;
_ch_direct_gain:				;
;-----------------------------------------------;
	mov	SPC_DSPD, #00h			; disable ADSR
	or	SPC_DSPA, #07h			; set GAIN [default]
	mov	SPC_DSPD, m2			;-----------------------------
						;
	;---------------------------------------;
	; **TODO: RESTORE SAMPLE OFFSET
	;---------------------------------------;
						;
;-----------------------------------------------;
_end_ch_process_audio:
;-----------------------------------------------;
	SPROC					;
;-----------------------------------------------;
_env_quit:
;-----------------------------------------------;
	ret					;
;-----------------------------------------------;
_ch_adsr:
;-----------------------------------------------;
	mov	SPC_DSPD, a			; store attack and decay rate
	inc	SPC_DSPA			;
	mov	a, ch_sr+x			;
	mov	SPC_DSPD, a			; store sustain rate and level
	bra	_end_ch_process_audio		;
;-----------------------------------------------;

;*****************************************************************************
Channel_ProcessEnvelope:
;*****************************************************************************
	mov	a, t_flags			; exit if 'note delay' is set
	and	a, #TF_DELAY			;
	bne	_env_quit			;
;-----------------------------------------------;
	mov	y, #INS_ENVLEN			; test for envelope
	mov	a, [p_instr]+y			;
	mov	m0, a				;
	bne	_envelope_valid			;if no envelope:
;-----------------------------------------------;
	mov	t_env, #255			; set to max
						;
	mov	a, ch_flags+x			; start fade on KEYOFF
	and	a, #CF_KEYON			;
	beq	_env_quit			;
	bra	_env_setfade			;
;-----------------------------------------------;
_envelope_valid:
;-----------------------------------------------;
	mov	a, ch_env_node+x		; read envelope node data
						;
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
						;
	SPROC					;
	mov	a, ch_env_tick+x		; test zero/nonzero tick
	bne	_env_nonzero_tick		;
;-----------------------------------------------;ZEROTICK:
	mov	a, m1				; copy Y level
	mov	ch_env_y_h+x, a			;
	mov	a, #0				;
	mov	ch_env_y_l+x, a			;
	bra	_env_zerotick			;
;-----------------------------------------------;
_env_nonzero_tick:				;NONZERO:
;-----------------------------------------------;
	mov	a, ch_env_y_l+x			;
	clrc					;
	adc	a, m2				;
	mov	ch_env_y_l+x, a			;
	mov	a, ch_env_y_h+x			;
	adc	a, m2+1				;
	bpl	_catch_negative			; clamp result 0.0->64.0
;-----------------------------------------------;
	mov	a, #0				;
	mov	ch_env_y_h+x, a			;
	mov	ch_env_y_l+x, a			;
	bra	_env_zerotick			;
;-----------------------------------------------;
_catch_negative:				
;-----------------------------------------------
	cmp	a, #64				
	bcc	_catch_plus			
;-----------------------------------------------
	mov	a, #64				
	mov	ch_env_y_h+x, a			
	mov	a, #0				
	mov	ch_env_y_l+x, a			
	bra	_env_zerotick			
;-----------------------------------------------
_catch_plus:
;-----------------------------------------------
	mov	ch_env_y_h+x, a			
;-----------------------------------------------
_env_zerotick:
;-----------------------------------------------;
	mov	a, ch_env_y_l+x			; t_env = env << 2
	mov	m1, a				;
	mov	a, ch_env_y_h+x			;
	asl	m1				;
	rol	a				;
	asl	m1				;
	rol	a				;
						;
	bcc	_env_shift_clamp		; clamp to 255
;-----------------------------------------------;
	mov	a, #255				;
;-----------------------------------------------;
_env_shift_clamp:
;-----------------------------------------------;
	mov	t_env, a			;
						;
	mov	a, ch_flags+x			; don't advance if "keyon" and node=sustain
	and	a, #CF_KEYON			;
	beq	_env_nsustain			;
;-----------------------------------------------;
	mov	y, #INS_ENVSUS			;
	mov	a, [p_instr]+y			;
	cmp	a, ch_env_node+x		;
	bne	_env_nsustain			;
;-----------------------------------------------;
	ret					;
;-----------------------------------------------;
_env_setfade:
;-----------------------------------------------;
	mov	a, ch_flags+x			;
	or	a, #CF_FADE			;
	mov	ch_flags+x, a			;
	ret					;
;-----------------------------------------------;
_env_nsustain:
;-----------------------------------------------;
	inc	ch_env_tick+x			; increment tick
	mov	a, ch_env_tick+x		;
	cmp	a, m1+1				; exit if < duration
	bcc	_env_exit			;
;-----------------------------------------------;
	mov	a, #0				; reset tick
	mov	ch_env_tick+x, a		;
						;
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
;-----------------------------------------------;
_env_no_fade:
;-----------------------------------------------;
	mov	a, ch_env_node+x		; test for loop point
;	mov	y, #INS_ENVLOOPEND		;
	cmp	a, [p_instr]+y			;
	bne	_env_loop_test			;
;-----------------------------------------------;
	mov	y, #INS_ENVLOOPST		;
	mov	a, [p_instr]+y			;
	mov	ch_env_node+x, a		;
;-----------------------------------------------;
_env_exit:
;-----------------------------------------------;
	ret					;
;-----------------------------------------------;
_env_loop_test:					;
_env_no_loop:					;
;-----------------------------------------------;
	mov	a, ch_env_node+x		;
	setc					; suspicious...
	sbc	m0, #4				;
	cmp	a, m0				; test for envelope end
	beq	_env_setfade			;
	clrc					; increment node
	adc	a, #4				;
	mov	ch_env_node+x, a		;
	ret					;
;-----------------------------------------------;

;*****************************************************************************
Channel_ProcessVolumeCommand:
;*****************************************************************************
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

;-----------------------------------------------------------------------------
; 00-64 set volume
;-----------------------------------------------------------------------------
vcmd_setvol:
	cmp	mod_tick, #0		; a = volume
	bne	exit_vcmd		;
	mov	a, y			;
exit_vcmd:				;
	ret				;

;-----------------------------------------------------------------------------
; 65-74 fine vol up
;-----------------------------------------------------------------------------
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

;-----------------------------------------------------------------------------
; 75-84 fine vol down
;-----------------------------------------------------------------------------
vcmd_finevoldown:
	sbc	m0, #75-1		; m0 = rate [carry is cleared]
	cmp	mod_tick, #0
	bne	exit_vcmd

_vcmd_sub_sat0:	
	sbc	a, m0			; a -= rate
	bcs	exit_vcmd		; saturate lower bound to 0
	mov	a, #0			;
	ret				;

;-----------------------------------------------------------------------------
; 85-94 vol up
;-----------------------------------------------------------------------------
vcmd_volup:
	sbc	m0, #85			; m0 = rate (-1)
	cmp	mod_tick, #0
	beq	exit_vcmd
	bra	_vcmd_add_sat64

;-----------------------------------------------------------------------------
; 95-104 vol down
;-----------------------------------------------------------------------------
vcmd_voldown:
	sbc	m0, #95-1
	cmp	mod_tick, #0
	beq	exit_vcmd
	bra	_vcmd_sub_sat0

;-----------------------------------------------------------------------------
; 128-192 set pan
;-----------------------------------------------------------------------------
vcmd_pan:
	cmp	mod_tick, #0		; set panning
	bne	exit_vcmd		;
					;
	push	a			;
					;
	mov	a, y			;
	sbc	a, #128			;
	call	Command_SetPanningb	; Bugfix by KungFuFurby 12/20/15
	mov	ch_panning+x, a		;

	pop	a

	ret


;-----------------------------------------------------------------------------
COMMAND_MEMORY_MAP:
;-----------------------------------------------------------------------------
	.byte 00h, 00h, 00h, 10h, 20h, 20h, 30h, 70h, 00h
	;       A    B    C    D    E    F    G    H    I
	.byte 40h, 10h, 00h, 00h, 00h, 00h, 10h, 80h, 70h
	;       J    K    L    M    N    O    P    Q    R
	.byte 60h, 00h, 00h, 00h, 10h, 00h, 00h, 00h
	;       S    T    U    V    W    X    Y    Z
;-----------------------------------------------------------------------------


;********************************************************
Channel_ProcessCommandMemory:
;********************************************************
	mov	y, ch_command+x
	mov	a, !COMMAND_MEMORY_MAP-1+y
	beq	_cpc_quit		; 0 = no memory!
	mov	m0, x
	clrc
	adc	a, m0
	mov	y, a
	cmp	y, #70h			; <7 : single param
	bcc	_cpcm_single		;
;-----------------------------------------------------------------------------
_cpcm_double:				; >=7: double param
;-----------------------------------------------------------------------------
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
;-----------------------------------------------------------------------------
_cpcm_single:
;-----------------------------------------------------------------------------
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
	jmp	0011h
	
; note: tasm has some kind of bug that removes the 16th character
; in macro args (...?)
;-----------------------------------------------------------------------------
CMD_JUMPTABLE_L:
;-----------------------------------------------------------------------------
	.byte	LBYTE(Command_SetSpeed)			; Axx
	.byte	LBYTE(Command_SetPositXion)		; Bxx
	.byte	LBYTE(Command_SetSR)			; Cxx disable pattern break cmd
	.byte	LBYTE(Command_VolumeSlXide)		; Dxy
	.byte	LBYTE(Command_PitchSliXdeDown)		; Exy
	.byte	LBYTE(Command_PitchSliXdeUp)		; Fxy
	.byte	LBYTE(Command_GlissandXo)		; Gxx
	.byte	LBYTE(Command_Vibrato)			; Hxy
	.byte	LBYTE(Command_EchoFeedXback)		; Ixx was Tremor
	.byte	LBYTE(Command_Arpeggio)			; Jxy
	.byte	LBYTE(Command_VolumeSlXideVibrato)	; Kxy
	.byte	LBYTE(Command_VolumeSlXideGlissando)	; Lxx
	.byte	LBYTE(Command_SetAD)			; Mxx was Command_SetChannXelVolume
	.byte	LBYTE(Command_NoiseSetXtings)		; Nxx
	.byte	LBYTE(Command_EVOLMinMXax)		; Oxx was Command_SampleOfXfset
	.byte	LBYTE(Command_PanningSXlide)		; Pxy
	.byte	LBYTE(Command_RetriggeXrNote)		; Qxy
	.byte	LBYTE(Command_Tremolo)			; Rxy
	.byte	LBYTE(Command_Extended)			; Sxy
	.byte	LBYTE(Command_Tempo)			; Txy
	.byte	LBYTE(Command_SetFilteXrSpeed)		; Uxx was Command_FineVibrXato
	.byte	LBYTE(Command_MasterVoXlume)		; Vxx was Command_SetGlobaXlVolume
	.byte	LBYTE(SCommand_Null)			; Wxx was Command_GlobalVoXlumeSlide
	.byte	LBYTE(Command_SetPanniXng)		; Xxx Command_SetPanniXng
	.byte	LBYTE(Command_EchoVoluXme)		; Yxx was Command_PanbrellXo
	.byte	LBYTE(Command_SetParamXeter)		; Zxx
;-----------------------------------------------------------------------------
CMD_JUMPTABLE_H:
;-----------------------------------------------------------------------------
	.byte	HBYTE(Command_SetSpeed)			; Axx
	.byte	HBYTE(Command_SetPositXion)		; Bxx
	.byte	HBYTE(Command_SetSR)			; Cxx
	.byte	HBYTE(Command_VolumeSlXide)		; Dxy
	.byte	HBYTE(Command_PitchSliXdeDown)		; Exy
	.byte	HBYTE(Command_PitchSliXdeUp)		; Fxy
	.byte	HBYTE(Command_GlissandXo)		; Gxx
	.byte	HBYTE(Command_Vibrato)			; Hxy
	.byte	HBYTE(Command_EchoFeedXback)		; Ixx
	.byte	HBYTE(Command_Arpeggio)			; Jxy
	.byte	HBYTE(Command_VolumeSlXideVibrato)	; Kxy
	.byte	HBYTE(Command_VolumeSlXideGlissando)	; Lxx
	.byte	HBYTE(Command_SetAD)			; Mxx Command_SetChannXelVolume
	.byte	HBYTE(Command_NoiseSetXtings)		; Nxx
	.byte	HBYTE(Command_EVOLMinMXax)		; Oxx
	.byte	HBYTE(Command_PanningSXlide)		; Pxy
	.byte	HBYTE(Command_RetriggeXrNote)		; Qxy
	.byte	HBYTE(Command_Tremolo)			; Rxy
	.byte	HBYTE(Command_Extended)			; Sxy
	.byte	HBYTE(Command_Tempo)			; Txy
	.byte	HBYTE(Command_SetFilteXrSpeed)		; Uxx
	.byte	HBYTE(Command_MasterVoXlume)		; Vxx was Command_SetGlobaXlVolume
	.byte	HBYTE(SCommand_Null)			; Wxx was Command_GlobalVoXlumeSlide
	.byte	HBYTE(Command_SetPanniXng)		; Xxx
	.byte	HBYTE(Command_EchoVoluXme)		; Yxx
	.byte	HBYTE(Command_SetParamXeter)		; Zxx

;=======================================================================
Command_SetSpeed:				; axx	9 bytes
;=======================================================================
	bne	cmd_exit1			;on tick0:
	cmp	a, #0				; if param != 0
	beq	cmd_exit1			; mod_speed = param
	mov	mod_speed, a			;
cmd_exit1:					;
	ret	
;=======================================================================
Command_SetPosition:				; bxx
;=======================================================================
	bne	cmd_exit1			;on tick0:
;=======================================================================
DoSetPosition:
;=======================================================================
	mov	pattjump_index, a		; set jump index
	or	mod_special, #MS_PATTERNJUMP	;
	ret					;
;=======================================================================
;Command_PatternBreak:				; cxx
;=======================================================================
	;ret
;=======================================================================
Command_SetSR:					; cxx
;=======================================================================
	cmp	x, #MAX_ADSR_CHANNELS
	bcs	cmd_exit1
	mov	ch_sr+x, a
	ret
;=======================================================================
Command_VolumeSlideVibrato:			; kxy
;=======================================================================
	call	Command_Vibrato	
;=======================================================================
Setup_VolumeSlide:
;=======================================================================
	mov	a, ch_param+x
	mov	y, mod_tick
;=======================================================================
Command_VolumeSlide:				; dxy
;=======================================================================
	mov	m0, t_volume			; slide volume
	mov	m0+1, #DEFAULT_VOL_SAT		;
						;
	call	DoVolumeSlide			;
						;
	mov	t_volume, a			;
	mov	ch_volume+x, a			;
	ret					;
;=======================================================================
Command_PitchSlideDown:
;=======================================================================
	call	PitchSlide_Load			; m0 = slide amount
						;
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
;-----------------------------------------------------------------------------
_fxx_max:
;-----------------------------------------------------------------------------
	mov	y, #01Ah			; max pitch
	mov	a, #0				;
	movw	t_pitch, ya			;
	mov	ch_pitch_l+x, a			;
	mov	ch_pitch_h+x, y			;
	ret					;
;=======================================================================
Command_VolumeSlideGlissando:			; lxx
;=======================================================================
	or	mod_mode, #MO_GXXVOL		;
;=======================================================================
Command_Glissando:				; gxx
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
;-----------------------------------------------;
	bbc2	mod_special, _skip_vibrato	; test MS_GXXVIB
	call	Command_Vibrato			;
;-----------------------------------------------
_skip_vibrato:
;-----------------------------------------------
	bbc5    mod_mode, _skip_gxx_vol		; test MO_GXXVOL
	call	Setup_VolumeSlide		;
	and	mod_mode, #~MO_GXXVOL		;
;-----------------------------------------------;
_skip_gxx_vol:
;-----------------------------------------------;
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
;Command_Panbrello:				; yxy
;=======================================================================
	;or	mod_special, #MS_PANBRELLO
	;bra	_skip_pan_trem_disable
;=======================================================================
Command_Tremolo:				; rxy
;=======================================================================
	or	mod_special, #MS_TREMOLO
	bra	_skip_pan_trem_disable
fmexit:	ret
;=======================================================================
Command_Vibrato:				; hxy
;=======================================================================
	and	mod_special, #~MS_TREMOLO	;
;-----------------------------------------------
_skip_pan_trem_disable:
;-----------------------------------------------
	mov	a, #70h				;
	mov	m0, x				; m0=channel
	clrc					;
	adc	a, m0				; 70h+channel
	mov	y, a				;
	mov	a, !PatternMemory-10h+y		;
						;
	mov	m0, a				; m0=speed|depth
	mov	m2+1, a				; 
	and	m0, #0Fh			; m0=depth
						;
	mov	a, ch_env_vib+x			;
	cmp	a, #08h				;
	bcc	_skip_fm			;
;-----------------------------------------------
	mov	fm_mod_freq, m0			; carrier frequency
	mov	fm_car_freq, m2+1		;
	and	fm_car_freq, #0F0h		; modulation frequency
	bbc1	mod_special, _skip_fm		; test MS_FM_ACTIVE
;-----------------------------------------------------------------------------
_fm_synth:					; fm synth by psychopathicteen
;-----------------------------------------------------------------------------
	mov	m0+1, #02h			;
	mov	y, fm_blocks			; setup index
	cmp	y, #FM_WAVEFORM_END-FM_WAVEFORM	;
	bcc	_no_index_reset
;-----------------------------------------------------------------------
	mov	y, #01h				; reset index
;-----------------------------------------------------------------------
_no_index_reset:
;-----------------------------------------------------------------------
	or	special, #SF_FMWAVEFORM		;
;-----------------------------------------------------------------------
_make_brr:
;-----------------------------------------------------------------------------
	mov	m1+1, #08h			; number of samples per block
;-----------------------------------------------------------------------------
_make_block:
;-----------------------------------------------------------------------------
	mov	m2, y				; wavetable index
	call	_add_mod_freq			;
	adc	fm_car_phase, fm_car_freq	; add carrier frequency to carrier
	mov	a, y				; phase
	clrc					;
	adc	a, fm_car_phase			; take the carrier phase and add
	mov	y, a				; the current modulation height
	call	_get_waveform			;
	mov	fm_wave, a			; store current carrier wave
	call	_add_mod_freq			;
	adc	fm_mod_phase, fm_mod_freq	; add mod freq to mod phase
	mov	a, y				;
	clrc					;
	adc	a, fm_car_phase			; take the carrier phase and add
	mov	y, a				; the current modulation height
	mov	a, fm_wave			;
	xcn	a				; grab previous sample, swap nibbles
	call	_get_waveform			;
	or	a, fm_wave+x			; two samples in one byte
	mov	y, m2				; get index
	mov	!FM_WAVEFORM+y, a		;
	inc	y				;
	dec	m1+1				; decrease sample count
	bne	_make_block			;
;-----------------------------------------------;
	inc	y				; skip header
	dec	m0+1				; decrease block count
	bne	_make_brr			;
;-----------------------------------------------;
	mov	fm_blocks, y			; store brr index
	and	special, #~SF_FMWAVEFORM	;
	bbc3	mod_special, fmexit		; test MS_FM_VIBRATO
;-----------------------------------------------------------------------------
_skip_fm:					;
;-----------------------------------------------------------------------------
	mov	a, m2+1				;
	lsr	a				; cmem += x*4
	lsr	a				;
	and	a, #111100b			;
	clrc					;
	adc	a, ch_cmem+x			;
	mov	ch_cmem+x, a			;
						;
	mov	y, a				; a = sine[cmem]
						;
	mov	a, ch_vib_wav+x			;
	mov	m1, a				; m1 = waveform value
;-----------------------------------------------;
_get_waveform:					;
;-----------------------------------------------;
	mov	a, ch_env_vib+x			; a = vibrato waveform type
;-----------------------------------------------
_hxx_cmp:
;-----------------------------------------------
	cmp	a, #8
	bcs	_hxx_sub8
	cmp	a, #1
	beq	_hxx_ramp_down
	cmp	a, #2
	beq	_hxx_sq
	cmp	a, #3
	beq	_hxx_tri_sq
	cmp	a, #4
	beq	_hxx_tri
	cmp	a, #5
	beq	_hxx_ramp_up
	cmp	a, #6
	beq	_hxx_sq2
	cmp	a, #7
	beq	_hxx_sq3
;-----------------------------------------------
_hxx_sine:					; s30
;-----------------------------------------------
	call	Sine
	bra	_hxx_bpl
;-----------------------------------------------
_hxx_ramp_down:					; s31
;-----------------------------------------------
	cmp	y, #0
	bne	_hxx_chk_ramp
;-----------------------------------------------
_hxx_res_ramp:
;-----------------------------------------------
	mov	m1, #DEFAULT_RAMP_POS
;-----------------------------------------------
_hxx_chk_ramp:
;-----------------------------------------------
	cmp	m1, #DEFAULT_RAMP_NEG
	beq	_hxx_res_ramp
;-----------------------------------------------
_hxx_dec_ramp:
;-----------------------------------------------
	bra	_dec_m1_hxx_bpl
;-----------------------------------------------
_hxx_sq:					; s32
;-----------------------------------------------
	cmp	y, #080h
	bcs	_hxx_neg_sq
	bra	_hxx_pos_sq
;-----------------------------------------------
_hxx_tri_sq:					; s33
;-----------------------------------------------
	cmp	y, #080h
	bcs	_hxx_pos_sq
;-----------------------------------------------
_hxx_tri:					; s34
;-----------------------------------------------
	cmp	y, #0C0h
	bcs	_inc_m1_hxx_bpl
	cmp	y, #040h
	bcs	_dec_m1_hxx_bpl
	bra	_inc_m1_hxx_bpl
;-----------------------------------------------
_hxx_sq2:					; s36
;-----------------------------------------------
	cmp	y, #0C0h
	bcs	_hxx_pos_sq
	cmp	y, #080h
	bcs	_dec_m1_hxx_bpl
;-----------------------------------------------
_hxx_neg_sq:
;-----------------------------------------------
	mov	a, #DEFAULT_SQ_NEG
	bra	_hxx_bpl
;-----------------------------------------------
_hxx_sq3:
;-----------------------------------------------
	cmp	y, #094h
	bcs	_hxx_neg_sq
	cmp	y, #028h
	bcs	_dec_m1_hxx_bpl
;-----------------------------------------------
_hxx_pos_sq:
;-----------------------------------------------
	mov	a, #DEFAULT_SQ_POS
	bra	_hxx_bpl
;-----------------------------------------------
_hxx_sub8:
;-----------------------------------------------
	mov	m1, fm_wave
        setc
        sbc     a, #08h
        bra     _hxx_cmp
;-----------------------------------------------
_hxx_ramp_up:					; s35
;-----------------------------------------------
	cmp	y, #0
	bne	_hex_chk_ramp2
;-----------------------------------------------
_hex_res_ramp2:
;-----------------------------------------------
	mov	m1, #DEFAULT_RAMP_NEG
;-----------------------------------------------
_hex_chk_ramp2:
;-----------------------------------------------
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
	bbs1	special, _hexit			; test SF_FMWAVEFORM
	mov	ch_vib_wav+x, a
	bpl	_hxx_plus
;-----------------------------------------------
_hxx_neg:
;-----------------------------------------------
	eor	a, #255
	inc	a

	call	_hxx_mulya
	mov	m0, a
	bbs7	mod_special, _hxx_subw_volume	; MS_TREMOLO
	;bbs6   mod_special, _hxx_subw_panning ; MS_PANBRELLO
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
;_hxx_subw_panning:
;-----------------------------------------------
	;mov	a, t_panning
	;mov	y, #0
	;subw	ya, m0
	;bmi	_hxx_zpanning
	;bra	_store_panning
;-----------------------------------------------
_hxx_plus:
;-----------------------------------------------
	call	_hxx_mulya
	mov	y, m0+1
	bbs7	mod_special, _store_volume	; MS_TREMOLO
	;bbs6	mod_special, _store_panning	; MS_PANBRELLO
_hxx_addw:
	addw	ya, t_pitch			; warning: might break something on highest note
;-----------------------------------------------
_store_pitch:
;-----------------------------------------------
	movw	t_pitch, ya
_hexit:	ret
;-----------------------------------------------
_store_volume:
;-----------------------------------------------
	clrc
	adc	a, t_volume
	mov	t_volume, a
	;bra	_disable_tremolo
	ret
;-----------------------------------------------
;_store_panning:
;-----------------------------------------------
	;clrc
	;adc	a, t_panning
	;mov	t_panning, a
	;bra	_disable_panbrello
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
	;and	mod_special, #~MS_TREMOLO
	ret
;-----------------------------------------------
;_hxx_zpanning
;-----------------------------------------------
	;mov	t_panning, #0
;_disable_panbrello:
	;and	mod_special, #~MS_PANBRELLO
	;ret
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
;-----------------------------------------------------------------------------
_add_mod_freq:
;-----------------------------------------------------------------------------
	clrc					;
	adc	fm_mod_phase, fm_mod_freq	; add modulator frequency to phase
	mov	y, fm_mod_phase			; use modulator phase
	call	Sine				;
	mov	y, fm_mod_amp			;
	mul	ya				; multiply the sine
	clrc					;
	ret					;
;-----------------------------------------------------------------------------
Sine:
;-----------------------------------------------------------------------------
	cmp	y, #80h				;
	bcs	_sine_neg			;
	mov	a, !IT_FINE_SINE_DATA+y		; copy positive values
	ret					;
;-----------------------------------------------------------------------------
_sine_neg:
;-----------------------------------------------------------------------------
	mov	a, y				; IT_FINE_SINE_DATA is only 128
	clrc					; bytes long, once the end is
	sbc	a, #127				; reached reset to the start
	mov	y, a				;
	mov	a, !IT_FINE_SINE_DATA+y		; copy positive values
	eor	a, #0FFh			; ...and make them negative
	inc	a				;
	ret

;=======================================================================
;Command_Tremor:					; unimplemented
;=======================================================================
;	ret

;-----------------------------------------------------------------------
ResetEchoFeedback:
;-----------------------------------------------------------------------
	mov	a, !MODULE+MOD_EFB
	mov	evol_fb, a
;=======================================================================
Command_EchoFeedback:				; ixx
;=======================================================================
	cmp	a, #80h
	beq	ResetEchoFeedback
	mov	SPC_DSPA, #DSP_EFB
	mov	SPC_DSPD, a
	ret
;=============================================================================
Command_Arpeggio:				; jxy
;=============================================================================
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

_jxx_y:
	mov	a, ch_param+x
	xcn	a
	bra	_jxx_add
;=======================================================================
;Command_SetChannelVolume:			; mxx
;=======================================================================
	;bne	cmd_exit2			; on tick0:
	;cmp	a, #80h				;
	;bne	SetChannelVolume		;
	;mov	a, !MODULE+MOD_CV+x		;
	;cmp	a, #65				;  cvolume = param > 64 ? 64 : param
	;bcc	cscv_under65			;
	;mov	a, #64				;
;cscv_under65:					;
;SetChannelVolume:
	;mov	ch_cvolume+x, a			;
;cmd_exit2:
	;ret					;

;=======================================================================
Command_SetAD:					; mxx
;=======================================================================
	bne	cmd_exit2			; on tick0
	cmp	a, #40h
	bcc	_set_wt_time
	cmp	a, #48h
	bcc	_set_wt_min
	cmp	a, #50h
	bcc	_set_wt_max
	cmp	a, #70h
	bcc	_evol_speed
	cmp	a, #7fh
	bcc	_swing_tempo_on_off
;-----------------------------------------------;
	cmp	x, #MAX_ADSR_CHANNELS
	bcs	cmd_exit2
	mov	ch_ad+x, a
	ret
;-----------------------------------------------;
_evol_speed:
;-----------------------------------------------;
	setc
	sbc	a, #50h
	mov	evol_time, a
	ret
;-----------------------------------------------;
_swing_tempo_on_off:
;-----------------------------------------------;
	setc
	sbc	a, #70h
	cmp	a, #0
	beq	_set_swing_tempo_off
;-----------------------------------------------;
_set_swing_tempo_on:
;-----------------------------------------------;
	mov	swing_tempo_mod, a		;
	or	mod_special, #MS_SWINGTEMPO	;
	and	mod_special, #~MS_SWINGODD	; always start at 0
	mov	mod_speed_bk, mod_speed		; back up speed
	ret					;
;-----------------------------------------------;
_set_swing_tempo_off:
;-----------------------------------------------;
	and	mod_special, #~MS_SWINGTEMPO	;
	mov	mod_speed, mod_speed_bk		; restore speed
	ret					;
;-----------------------------------------------;
_set_wt_time:	; 00-3f
;-----------------------------------------------;
	call	Amult4_M0
	mov	wt_time, a
	mov	current_wt_time, #0
	ret
;-----------------------------------------------;
_set_wt_max:	; 48-4f
;-----------------------------------------------;
	setc
	sbc	a, #48h
	mov	wt_max, a
	ret
;-----------------------------------------------;
_set_wt_min:	; 40-47
;-----------------------------------------------;
	setc	
	sbc	a, #40h
	mov	wt_min, a
	ret
;=======================================================================
;Command_ChannelVolumeSlide:			; nxx 15 bytes
;=======================================================================
	;mov	a, ch_cvolume+x			; slide channel volume
	;mov	m0, a				; 
	;mov	m0+1, #64			;
	;mov	a, ch_param+x			;
	;call	DoVolumeSlide			;
	;mov	ch_cvolume+x, a			;
	;ret					;
;=======================================================================
Command_NoiseSettings:				; nxx
;=======================================================================
	cmp	a, #20h				; 00h-1Fh min noise freq
	bcc	_set_min_noise_value		;
	cmp	a, #40h				; 20h-3Fh max noise freq
	bcc	_set_max_noise_value		;
	cmp	a, #80h
	bcs	cmd_exit2

	setc					; 40-7fh speed
	sbc	a, #40h
	cmp	a, #0
	beq	_disable_noise_sweep
	call	Amult4_M0
	mov	noise_time, a
	ret

_disable_noise_sweep:
	and	special, #~SF_NOISESWEEP
	ret

_set_min_noise_value:
	mov	noise_sweep_endmin, a
	ret
_set_max_noise_value:
	setc
	sbc	a, #20h
	mov	noise_sweep_endmax, a
cmd_exit2:
	ret

;=======================================================================
;Command_SampleOffset:				; oxx
;=======================================================================
	;bne	cmd_exit2			; on tick0:
	;mov	t_sampoff, a			;   set sampoff data
	;ret					;

;=======================================================================
Command_EVOLMinMax:				; oxx
;=======================================================================
	cmp	a, #80h
	beq	cmd_exit2
	bcs	_set_evol_max
	cmp	a, evol_max
	bcs	cmd_exit2
	mov	evol_min, a
	ret
;-----------------------------------------------;
_set_evol_max:
;-----------------------------------------------;
	setc
	sbc	a, #80h
	cmp	a, evol_min
	bcc	cmd_exit2
	mov	evol_max, a
	ret

;=======================================================================
Command_PanningSlide:				; pxy
;=======================================================================
	xcn	a
	mov	m0, t_panning			; slide panning
	mov	m0+1, #64			;
	call	DoVolumeSlide			;
	mov	t_panning, a			;
	mov	ch_panning+x, a			;
	ret					;
;=============================================================================
Command_RetriggerNote:				; qxy
;=============================================================================
	and	a, #0Fh				; m0 = y == 0 ? 1 : x
	bne	_crn_x1				;
	inc	a				;
_crn_x1:					;	
	mov	m0, a				;

	mov	a, ch_cmem+x			;if cmem is 0:
	bne	_crn_cmem_n0			;  cmem = m0
	mov	a, m0				;
_crn_count_ret:
	mov	ch_cmem+x, a			;
	ret					;	
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
	jmp	[RNVTABLE+x]
;-----------------------------------------------------------------------------
RNVTABLE:
;-----------------------------------------------------------------------------
	.word	rnv_0, rnv_1, rnv_2, rnv_3, rnv_4, rnv_5, rnv_6, rnv_7
	.word	rnv_8, rnv_9, rnv_A, rnv_B, rnv_C, rnv_D, rnv_E, rnv_F
;-----------------------------------------------------------------------------
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
;-----------------------------------------------------------------------------
_psl_normal:
;-----------------------------------------------------------------------------
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
;-----------------------------------------------------------------------------
_psl_zero:
;-----------------------------------------------------------------------------
	mov	m0, #0
	mov	m0+1, #0
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



;-----------------------------------------------------------------------------
CmdExTab_L:
;-----------------------------------------------------------------------------
	.byte	LBYTE(SCommand_EPN)		; S0x 0-4 Echo; 5-8 Pitch, 9-c Noise
	.byte	LBYTE(SCommand_NoiseFrXeq1)	; S1x
	.byte	LBYTE(SCommand_NoiseFrXeq2)	; S2x
	.byte	LBYTE(SCommand_VibratoXWav)	; S3x 0-3 Vib. waveform
	.byte	LBYTE(SCommand_TremoloXWav)	; S4x set special, was tremolo waveform
	.byte	LBYTE(SCommand_NoiseFrXeq3)	; S5x noise freq sweep, was panbrello
 	.byte	LBYTE(SCommand_Null)		; S6x pattern delay
	.byte	LBYTE(SCommand_Drop)		; S7x NNA S77 vol env off S78 vol env on
	.byte	LBYTE(SCommand_Panning)		; S8x
	.byte	LBYTE(SCommand_SoundCoXntrol)	; S9x
	.byte	LBYTE(SCommand_Null)		; SAx
	.byte	LBYTE(SCommand_Null)		; SBx set loopback point
	.byte	LBYTE(SCommand_NoteCut)		; SCx
	.byte	LBYTE(SCommand_NoteDelXay)	; SDx
	.byte	LBYTE(SCommand_EchoDelXay)	; SEx
	.byte	LBYTE(SCommand_Cue)		; SFx
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
CmdExTab_H:
;-----------------------------------------------------------------------------
	.byte	HBYTE(SCommand_EPN)
	.byte	HBYTE(SCommand_NoiseFrXeq1)
	.byte	HBYTE(SCommand_NoiseFrXeq2)
	.byte	HBYTE(SCommand_VibratoXWav)
	.byte	HBYTE(SCommand_TremoloXWav)
	.byte	HBYTE(SCommand_NoiseFrXeq3)
	.byte	HBYTE(SCommand_Null)
	.byte	HBYTE(SCommand_Drop)
	.byte	HBYTE(SCommand_Panning)
	.byte	HBYTE(SCommand_SoundCoXntrol)
	.byte	HBYTE(SCommand_Null)
	.byte	HBYTE(SCommand_Null)
	.byte	HBYTE(SCommand_NoteCut)
	.byte	HBYTE(SCommand_NoteDelXay)
	.byte	HBYTE(SCommand_EchoDelXay)
	.byte	HBYTE(SCommand_Cue)
;-----------------------------------------------------------------------------


;=======================================================================
SCommand_EchoDelay:				; sex
;=======================================================================
	cmp	a, !MODULE+MOD_EDL
	beq	SetEchoDelay
	bcs	_reset_echo_delay		; anything else reset
SetEchoDelay:
	mov	SPC_DSPA, #DSP_EDL		; otherwise fuck around with it
	mov	SPC_DSPD, a			;
;=======================================================================
SCommand_Null:
;=======================================================================
	ret
;-----------------------------------------------------------------------------
_reset_echo_delay:
;-----------------------------------------------------------------------------
	mov	SPC_DSPA, #DSP_EDL		; defined in the header
	mov	a, !MODULE+MOD_EDL		;
	mov	SPC_DSPD, a			;
	ret					;
;-----------------------------------------------------------------------------
_echo_write:
;-----------------------------------------------------------------------------
	mov	SPC_DSPA, #DSP_FLG		;
	cmp	a, #0Eh				;
	beq	_enable_echo_write		;
	or	SPC_DSPD, #FLG_ECEN		; disable echo write
	ret					;
_enable_echo_write:				;
	and	SPC_DSPD, #~FLG_ECEN		;
	ret					;
;-----------------------------------------------------------------------------
;=======================================================================
ResetAll:					; s0f
;=======================================================================
	call	ResetEchoVolume
	call	ResetEFIR_FS
	call	ResetEchoFeedback
	ret
;=======================================================================
SCommand_EPN:	; Echo / Pitchmod / Noise ; This part added by KFF for noise & pitch modulation
;=======================================================================
	cmp	a, #0Fh
	beq	ResetAll
	cmp	a, #0Dh
	bcs	_echo_write
	cmp	a, #09h
	bcc	_pitch_mod

	mov	SPC_DSPA, #DSP_NON
	clrc
	sbc	a, #7
	bra	skip_dsp_eon		; preserve DSP_NON in SPC_DSPA
;-----------------------------------------------------------------------------
_pitch_mod:
;-----------------------------------------------------------------------------
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
;-----------------------------------------------------------------------------
_sce_enable_one:
;-----------------------------------------------------------------------------
	mov	a, !BITS+x
	or	a, SPC_DSPD
	mov	SPC_DSPD, a
	ret
;-----------------------------------------------------------------------------
_sce_disable_one:
;-----------------------------------------------------------------------------
	mov	a, !BITS+x
	eor	a, #255
	and	a, SPC_DSPD
	mov	SPC_DSPD, a
	ret
;-----------------------------------------------------------------------------
_sce_enable_all:
;-----------------------------------------------------------------------------
	mov	SPC_DSPD, #0FFh
	ret
;-----------------------------------------------------------------------------
_sce_disable_all:
;-----------------------------------------------------------------------------
	mov	SPC_DSPD, #0
	ret

;=======================================================================
SCommand_VibratoWav:				; s3x
;=======================================================================
	mov	ch_env_vib+x, a			; set waveform type
	mov	a, #0
	mov	ch_vib_wav+x, a			; reset waveform position
	ret
	
;=======================================================================
SCommand_TremoloWav:				; s4x
;=======================================================================
	mov	y, a
	mov	a, !S4xTab_L+y
	mov	!s4xjmp+1, a
	;mov	a, !S4xTab_H+y		; all s4x commands are at 10xx
	;mov	!s4xjmp+2, a		; so no need for a high table
s4xjmp:	jmp	1000h

;-----------------------------------------------------------------------------
S4xTab_L:
;-----------------------------------------------------------------------------
	.byte	LBYTE(SCommand_VibratoXWav)
	.byte	LBYTE(SCommand_VibratoXWav)
	.byte	LBYTE(SCommand_VibratoXWav)
	.byte	LBYTE(SCommand_VibratoXWav)
	.byte	LBYTE(EVOL_MaxMin)
	.byte	LBYTE(EVOL_MinMax)		; default
	.byte	LBYTE(_set_gxx_vibrato)
	.byte	LBYTE(_set_gxx_standarXd)	; default
	.byte	LBYTE(_enable_wavetablXe)
	.byte	LBYTE(_disable_wavetabXle)	; default
	.byte	LBYTE(_set_noise_sweepX_inc)
	.byte	LBYTE(_set_noise_sweepX_dec)	; default
	.byte	LBYTE(_set_noise_repeaXt_on)
	.byte	LBYTE(_set_noise_repeaXt_off)	; default
	.byte	LBYTE(_set_noise_pingpXong_on)
	.byte	LBYTE(_set_noise_pingpXong_off)	; default
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
_set_noise_pingpong_off:			; s4f
;-----------------------------------------------------------------------------
	and	special, #~SF_NOISEMODE
	ret
;-----------------------------------------------------------------------------
_set_noise_pingpong_on:				; s4e
;-----------------------------------------------------------------------------
	or	special, #SF_NOISEMODE
S4Exit:	ret
;-----------------------------------------------------------------------------
_set_noise_repeat_off:				; s4d
;-----------------------------------------------------------------------------
	and	special, #~SF_NOISEREPEAT
	ret
;-----------------------------------------------------------------------------
_set_noise_repeat_on:				; s4c
;-----------------------------------------------------------------------------
	or	special, #SF_NOISEREPEAT
	ret
;-----------------------------------------------------------------------------
_set_noise_sweep_dec:				; s4b
;-----------------------------------------------------------------------------
	and	special, #~SF_NOISEINC
_s4xit:	and	special, #~SF_NOISEMODE
	ret
;-----------------------------------------------------------------------------
_set_noise_sweep_inc:				; s4a
;-----------------------------------------------------------------------------
	or	special, #SF_NOISEINC
	bra	_s4xit
;-----------------------------------------------------------------------------
_disable_wavetable:				; s49
;-----------------------------------------------------------------------------
	and	special, #~(SF_WAVETABLE|SF_WTDIR)
	ret
;-----------------------------------------------------------------------------
_enable_wavetable:				; s48
;-----------------------------------------------------------------------------
	mov	wt_cur, wt_min
	or	special, #SF_WAVETABLE
	ret
;-----------------------------------------------------------------------------
_set_gxx_standard:				; s47
;-----------------------------------------------------------------------------
	and	mod_special, #~MS_GXXVIB
	ret
;-----------------------------------------------------------------------------
_set_gxx_vibrato:				; s46
;-----------------------------------------------------------------------------
	or	mod_special, #MS_GXXVIB
	ret
;-----------------------------------------------------------------------------
EVOL_MinMax:					; s45
;-----------------------------------------------------------------------------
	or	mod_mode, #MO_EVOLINC
	mov	current_evol, evol_min
	ret
;-----------------------------------------------------------------------------
EVOL_MaxMin:					; s44
;-----------------------------------------------------------------------------
	and	mod_mode, #~MO_EVOLINC
	mov	current_evol, evol_max
	ret
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
FILTER:	.byte   $7f,$00,$00,$00,$00,$00,$00,$00
	.byte   $34,$33,$00,$d9,$e5,$01,$fc,$eb ; bandpass
	.byte   $58,$bf,$db,$f0,$fe,$07,$0c,$0c ; highpass
	.byte   $0a,$17,$23,$29,$12,$fe,$f3,$f9 ; lowpass
	.byte	$f8,$08,$11,$1c,$1c,$11,$08,$f8 ; ren and stimpy
	.byte	$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f	; star ocean/top
;-----------------------------------------------------------------------------

;=======================================================================
;						; s7x
;=======================================================================
;available commands: S7D, S7E, S7F

;=======================================================================
SCommand_NoiseFreq3:				; s5x
;=======================================================================
	or	special, #SF_NOISESWEEP
	clrc
	adc	a, #10h
	bra	_noise_mov
;=======================================================================
SCommand_NoiseFreq2:				; s2x
;=======================================================================
	clrc
	adc	a, #10h
;=======================================================================
SCommand_NoiseFreq1:				; s1x
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
SCommand_Panning:				; s8x
;=======================================================================
	bne	cmd_exit4			; on tick0:
	mov	m0, a				; panning = (y << 2) + (y >> 2)
	asl	a				;
	asl	a				;
	lsr	m0				;
	lsr	m0				;
	adc	a, m0				;
	mov	t_panning, a			;
	mov	ch_panning+x, a			;
	ret					;

;-----------------------------------------------------------------------------
Command_ToggleEvolIncDec:			; s90
;-----------------------------------------------------------------------------
	eor	mod_mode, #MO_EVOLINC
	ret
;-----------------------------------------------------------------------------
Command_Surround:
;-----------------------------------------------------------------------------
	mov	a, ch_flags+x
	or	a, #CF_SURROUND
	mov	ch_flags+x, a
	mov	a, #32
	mov	ch_panning+x, a
	mov	t_panning, a
	ret
;-----------------------------------------------------------------------------
Command_MuteChannel:				; s92
;-----------------------------------------------------------------------------
	mov	a, ch_flags+x
	or	a, #CF_MUTE
	bra	_setcf
;-----------------------------------------------------------------------------
Command_UnmuteChannel:				; s93
;-----------------------------------------------------------------------------
	mov	a, ch_flags+x
	and     a, #~CF_MUTE			; mask 7 bits
_setcf:	mov	ch_flags+x,a
cmd_exit4:
	ret
;-----------------------------------------------------------------------------
Command_EnableFMVibrato:			; s94
;-----------------------------------------------------------------------------
	or	mod_special, #(MS_FM_VIBRATO|MS_FM_ACTIVE)
	mov	a, #LBYTE(FM_WAVEFORM)
	mov	!SampleDirectory, a
	mov	!SampleDirectory+2, a
	mov	a, #HBYTE(FM_WAVEFORM)
	mov	!SampleDirectory+1, a
	mov	!SampleDirectory+3, a
	ret
;-----------------------------------------------------------------------------
Command_DisableFMVibrato:			; s95
;-----------------------------------------------------------------------------
	and	mod_special, #~(MS_FM_VIBRATO|MS_FM_ACTIVE)
	ret
;-----------------------------------------------------------------------------
Command_SetZModeChFS_MaxMin:			; s96
;-----------------------------------------------------------------------------
	call	EVOL_MaxMin
	bra	_resa
;-----------------------------------------------------------------------------
Command_SetZModeChFS_MinMax:			; s97
;-----------------------------------------------------------------------------
	call	EVOL_MinMax
_resa:	call	ResetAll
;-----------------------------------------------------------------------------
Command_SetZModeChFS:				; s98
;-----------------------------------------------------------------------------
	push	x

	mov	x, #7
	mov	a, #80h
_set80:	mov	filter_values+x, a
	dec	x
	bpl	_set80

	pop	x

	or	mod_mode, #MO_CHFLTSWP

	ret
;-----------------------------------------------------------------------------
Command_SetZModeEFIR:				; s99
;-----------------------------------------------------------------------------
	and	mod_mode, #~(MO_CHFLTZMODE|MO_CHFLTSWP)
S9Exit:	ret
;=======================================================================
SCommand_SoundControl:				; s9x
;=======================================================================
	bne	cmd_exit4
	mov	y, a
	mov	a, !S9xTab_L+y
	mov	!s9xjmp+1, a
	;mov	a, !S9xTab_H+y			; all s9x commands are at 11xx
	;mov	!s9xjmp+2, a			; so no need for a high table
s9xjmp:	jmp	1100h

;-----------------------------------------------------------------------------
S9xTab_L:
;-----------------------------------------------------------------------------
	.byte	LBYTE(Command_ToggleEvXolIncDec)	; s90
	.byte	LBYTE(Command_Surround)			; s91
	.byte	LBYTE(Command_MuteChanXnel)		; s92
	.byte	LBYTE(Command_UnmuteChXannel)		; s93
	.byte	LBYTE(Command_EnableFMXVibrato)		; s94
	.byte	LBYTE(Command_DisableFXMVibrato)	; s95
	.byte	LBYTE(Command_SetZModeXChFS_MaxMin)	; s96
	.byte	LBYTE(Command_SetZModeXChFS_MinMax)	; s97
	.byte	LBYTE(Command_SetZModeXChFS)		; s98
	.byte	LBYTE(Command_SetZModeXEFIR)		; s99
	.byte	LBYTE(Command_SetFilteXr7F)		; s9a
	.byte	LBYTE(Command_SetFilteXrBand)		; s9b
	.byte	LBYTE(Command_SetFilteXrHigh)		; s9c
	.byte	LBYTE(Command_SetFilteXrLow)		; s9d
	.byte	LBYTE(Command_SetFilteXrSp1)		; s9e
	.byte	LBYTE(Command_SetFilteXrSp2)		; s9f
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
Command_SetFilter7F:					; s9a
;-----------------------------------------------------------------------------
	mov	y, #7
	bra	_set_special_filter
;-----------------------------------------------------------------------------
Command_SetFilterBand:					; s9b
;-----------------------------------------------------------------------------
	mov	y, #15
	bra	_set_special_filter
;-----------------------------------------------------------------------------
Command_SetFilterHigh:					; s9c
;-----------------------------------------------------------------------------
	mov	y, #23
	bra	_set_special_filter
;-----------------------------------------------------------------------------
Command_SetFilterLow:					; s9d
;-----------------------------------------------------------------------------
	mov	y, #31
	bra	_set_special_filter
;-----------------------------------------------------------------------------
Command_SetFilterSp1:					; s9e
;-----------------------------------------------------------------------------
	mov	y, #39
	bra	_set_special_filter
;-----------------------------------------------------------------------------
Command_SetFilterSp2:					; s9f
;-----------------------------------------------------------------------------
	mov	y, #47
_set_special_filter:
	setc
	mov	SPC_DSPA, #DSP_C7

	push	x

	mov	x, #7
_copy_special_coef:
	mov	a, !FILTER+y			;
	bbc0	mod_mode, _csc			; test MO_CHFLTSWP
	mov	filter_values+x, a		; set values for filter sweep
	bra	_cscdy
_csc:	mov	SPC_DSPD, a			; set value immediately
	sbc	SPC_DSPA, #10h			;
_cscdy:	dec	y				;
	dec	x				;
	bpl	_copy_special_coef		;

	pop	x

	ret

;=============================================================================
SCommand_NoteCut:				; scx	11 bytes
;=============================================================================
	cmp	a, mod_tick			; on tick Y:
	bne	cmd_exit5			;
	mov	a, #0				; zero volume
	mov	t_volume, a			;
	mov	ch_volume+x, a			;
	ret	
;=============================================================================
SCommand_NoteDelay:				; sdx	15 bytes
;=============================================================================
	cmp	a, mod_tick
	beq	scdelay_equ
	bcs	scdelay_lower
	ret
scdelay_lower:
	or	t_flags, #TF_DELAY
	ret
scdelay_equ:
	or	t_flags, #TF_START
	ret
;=============================================================================
SCommand_Cue:					; sfx
;=============================================================================
	bne	cmd_exit5			;on tick0:
	inc	STATUS				; increment CUE value
	and	STATUS, #11101111b		; in status and send to
	mov	SPC_PORT2, STATUS		; snes
	ret					;
;=============================================================================
Command_Tempo:					; txy
;=============================================================================
	cmp	a, #20h
	bcc	_temposlide
	cmp	a, #80
	bcs	_change_tempo
	mov	a, #80
	bra	_change_tempo
;-----------------------------------------------------------------------------
_temposlide:
	cmp	a, #10h
	bcc	_txx_down
	and	a, #0Fh
	clrc
	adc	a, mod_bpm
	bra	_change_tempo
;-----------------------------------------------------------------------------
_txx_down:
	mov	m0, a
	mov	a, mod_bpm
	setc
	sbc	a, m0
	cmp	a, #80
	bcs	_change_tempo
	mov	a, #80
;-----------------------------------------------------------------------------
_change_tempo:
	call	Module_ChangeTempo
	mov	SPC_CONTROL, #%111
	ret
;=============================================================================
;Command_FineVibrato:				; unimplemented
;=============================================================================
;	ret
;-----------------------------------------------------------------------------

;=======================================================================
Command_SetFilterSpeed:				; uxx
;=======================================================================
	mov	filter_time, a
	ret
;=============================================================================
;Command_SetGlobalVolume:			; vxx
;=============================================================================
	;bne	cmd_exit5			; set global volume on tick0
	;cmp	a, #80h				;
	;bcc	_vxx_nsat			; saturate to 80h
	;mov	a, #80h				;
;_vxx_nsat:					;
	;mov	mod_gvol, a			;
	;ret					;
;=============================================================================
ResetMasterVolume:
;=============================================================================
	mov	a, #DEFAULT_MVOL
;=============================================================================
Command_MasterVolume:				; vxx
;=============================================================================
	cmp	a, #80h
	beq	ResetMasterVolume
;=============================================================================
Command_MasterVolume2:
;=============================================================================
	mov	SPC_DSPA, #DSP_MVOL
	mov	SPC_DSPD, a
	mov	SPC_DSPA, #DSP_MVOLR
	mov	SPC_DSPD, a
cmd_exit5:
	ret

;=============================================================================
;Command_GlobalVolumeSlide:			; wxy 12 bytes
;=============================================================================
	;mov	m0, mod_gvol			; slide global volume
	;mov	m0+1, #128			; max 128
	;call	DoVolumeSlide			;
	;mov	mod_gvol, a			;
	;ret					;

;=============================================================================
Command_SetPanning:				; xxx
;=============================================================================
	bne	cmd_exit5			; set panning on tick0	
	lsr	a				;
	lsr	a				;
	mov	t_panning, a			;
Command_SetPanningb:				;
	mov	ch_panning+x, a			;
	mov	a, ch_flags+x			;
	and	a, #~CF_SURROUND		;
	mov	ch_flags+x, a			;
	ret					;

;=============================================================================
ResetEchoVolume:
;=============================================================================
	mov	a, !MODULE+MOD_EVOL
;=============================================================================
Command_EchoVolume:				; yxx
;=============================================================================
	cmp	a, #80h
	beq	ResetEchoVolume
	mov	current_evol, a
;=============================================================================
Command_EchoVolume2:
;=============================================================================
	mov	SPC_DSPA, #DSP_EVOL
	mov	SPC_DSPD, a
	mov	y, !MODULE+MOD_EVOL
	cmp	y, !MODULE+MOD_EVOLR		; check for stereo
	beq	_update_echo_volume
;-----------------------------------------------------------------------------
	eor	a, #0FFh
	inc	a
;-----------------------------------------------------------------------------
_update_echo_volume:
;-----------------------------------------------------------------------------
	mov	SPC_DSPA, #DSP_EVOLR
	mov	SPC_DSPD, a
	ret

;-----------------------------------------------------------------------------
_z_ch_filter:				; s98 z80
;-----------------------------------------------------------------------------
	cmp	a, #80h
	beq	_disable_ch_filter_sweep
	mov	filter_values+x, a
	or	mod_mode, #MO_CHFLTSWP
	ret
;-----------------------------------------------------------------------------
_disable_ch_filter_sweep:
;-----------------------------------------------------------------------------
	and	mod_mode, #~MO_CHFLTSWP
	ret
;=============================================================================
Command_SetParameter:
;=============================================================================
	bbs1	mod_mode, _z_ch_filter	; test MO_CHFLTZMODE
;-----------------------------------------------------------------------------
ZCommand_SetEFIR:			; s99 z80
;-----------------------------------------------------------------------------
	cmp	a, #80h			;
	beq	ResetEFIR_FS		;
	mov	y, a			;
	mov	a, !CBITS+x		;
	mov	SPC_DSPA, a		;
	mov	SPC_DSPD, y		;
	ret				;
;-----------------------------------------------------------------------------
ResetEFIR_FS:
;-----------------------------------------------------------------------------
	mov	current_evol_time, #0
;=============================================================================
ResetEFIR:
;=============================================================================
	and	special, #~(MO_EVOLINC|MO_CHFLTZMODE|MO_CHFLTSWP)
	call	Command_SetFilter7F
	ret
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
; a = param
; y = tick
; m0 = value
; m0+1 = upper bound
;
; return: a = result
;=============================================================================
DoVolumeSlide:
;=============================================================================
	mov	m1, a			; test param for slide behavior
					;-------------------------------------
	and	a, #0Fh			; Dx0 : slide up
	beq	_dvs_up			;-------------------------------------
	mov	a, m1			; D0y : slide down
	and	a, #0F0h		;
	beq	_dvs_down		;-------------------------------------
_dvs_quit:				;-------------------------------------
	mov	a, m0			; (invalid)
_dvs_exit:				;
	ret				;
;-----------------------------------------------------------------------------
_dvs_down:				; D0y
;-----------------------------------------------------------------------------
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
;-----------------------------------------------------------------------------
_dvs_up:				;
;-----------------------------------------------------------------------------
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
;-----------------------------------------------------------------------------

;*****************************************************************************


;-----------------------------------------------------------------------------
LUT_FTAB:
;-----------------------------------------------------------------------------
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
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
;BITS:	.byte   1,  2,  4,  8, 16, 32, 64,128
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
;CBITS:	.byte	15, 31, 47, 63, 79, 95,111,127
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
LUT_DIV3:
;-----------------------------------------------------------------------------
	.byte 0, 0, 0, 1, 1, 1, 2, 2, 2
	.byte 3, 3, 3, 4, 4, 4, 5, 5, 5
	.byte 6, 6, 6, 7, 7, 7, 8, 8, 8
	.byte 9, 9, 9,10,10
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
WAVETABLE_L:
;-----------------------------------------------------------------------------
	.byte	LBYTE(WT_SAMPLE1), LBYTE(WT_SAMPLE2)
	.byte	LBYTE(WT_SAMPLE3), LBYTE(WT_SAMPLE4)
	.byte	LBYTE(WT_SAMPLE5), LBYTE(WT_SAMPLE6)
	.byte	LBYTE(WT_SAMPLE7), LBYTE(WT_SAMPLE8)
;-----------------------------------------------------------------------------

	;.byte	0,0,0,0,0,0

;-----------------------------------------------------------------------------
; C64 waveform: $41	[33488 Hz]			; should start at xx04h
;  pulse width: $81-$88
;-----------------------------------------------------------------------------
WT_SAMPLE1:
;-----------------------------------------------------------------------------
	.byte	$a0,$00,$0f,$dd,$de,$ee,$f1,$46,$66
	.byte	$7c,$82,$41,$3f,$10,$10,$00,$2f,$66
	.byte	$98,$00,$f0,$db,$14,$31,$0f,$ff,$00
	.byte	$7f,$1f,$1f,$0f,$f0,$00,$f0,$f4,$50
;-----------------------------------------------------------------------------
WT_SAMPLE2:
;-----------------------------------------------------------------------------
	.byte	$a0,$00,$0f,$dd,$de,$ee,$f1,$45,$65
	.byte	$6c,$40,$63,$40,$1f,$3f,$13,$f0,$21
	.byte	$88,$24,$f0,$e1,$a8,$e7,$75,$fd,$ee
	.byte	$7f,$0f,$10,$1e,$0f,$00,$f0,$f4,$60
;-----------------------------------------------------------------------------
WT_SAMPLE3:
;-----------------------------------------------------------------------------
	.byte	$a0,$00,$0f,$dc,$dd,$ee,$e1,$35,$55
	.byte	$74,$ae,$02,$32,$22,$21,$22,$21,$21
	.byte	$8c,$01,$14,$f0,$e1,$98,$b5,$74,$1e
	.byte	$7b,$cb,$f1,$f1,$fe,$f0,$e0,$f3,$6f
;-----------------------------------------------------------------------------
WT_SAMPLE4:
;-----------------------------------------------------------------------------
	.byte	$a0,$00,$0f,$dc,$cd,$ee,$e1,$34,$44
	.byte	$64,$cd,$03,$55,$42,$43,$24,$42,$43
	.byte	$8c,$00,$01,$13,$0f,$f0,$b8,$87,$74
	.byte	$7f,$1d,$cc,$f0,$01,$0e,$00,$e6,$61
;-----------------------------------------------------------------------------
WT_SAMPLE5:
;-----------------------------------------------------------------------------
	.byte	$90,$00,$0d,$98,$8a,$bb,$c1,$57,$77
	.byte	$5c,$8c,$77,$41,$1f,$30,$c7,$42,$00
	.byte	$88,$1f,$11,$f1,$22,$00,$e1,$c9,$87
	.byte	$87,$04,$52,$fe,$de,$ff,$ff,$f1,$55
;-----------------------------------------------------------------------------
WT_SAMPLE6:
;-----------------------------------------------------------------------------
	.byte	$90,$00,$0d,$88,$89,$bb,$c1,$57,$77
	.byte	$64,$9d,$12,$44,$32,$32,$22,$12,$44
	.byte	$88,$00,$10,$00,$10,$22,$f0,$0f,$da
	.byte	$9f,$a3,$52,$00,$ef,$00,$00,$01,$20
;-----------------------------------------------------------------------------
WT_SAMPLE7:
;-----------------------------------------------------------------------------
	.byte	$a0,$00,$0e,$cb,$cc,$dd,$e1,$23,$33
	.byte	$54,$8b,$14,$77,$63,$64,$33,$44,$34
	.byte	$68,$30,$11,$11,$11,$11,$76,$0e,$e0
	.byte	$9b,$ee,$95,$52,$0f,$d0,$f0,$01,$3f
;-----------------------------------------------------------------------------
WT_SAMPLE8:
;-----------------------------------------------------------------------------
	.byte	$a0,$00,$0e,$cb,$bc,$dd,$e1,$23,$33
	.byte	$64,$8e,$02,$33,$31,$32,$12,$12,$6f
	.byte	$68,$32,$21,$10,$11,$11,$11,$66,$ff
	.byte	$9b,$00,$ee,$85,$62,$0e,$ef,$01,$21
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
;WAVETABLE_L:
;-----------------------------------------------------------------------------
	;.byte	LBYTE(WT_SAMPLE1), LBYTE(WT_SAMPLE2)
	;.byte	LBYTE(WT_SAMPLE3), LBYTE(WT_SAMPLE4)
	;.byte	LBYTE(WT_SAMPLE5), LBYTE(WT_SAMPLE6)
	;.byte	LBYTE(WT_SAMPLE7), LBYTE(WT_SAMPLE8)
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
BITS:	.byte	1,  2,  4,  8, 16, 32, 64,128
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
CBITS:	.byte  DSP_C0,DSP_C1,DSP_C2,DSP_C3,DSP_C4,DSP_C5,DSP_C6,DSP_C7
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
FM_WAVEFORM:
;-----------------------------------------------------------------------------
	;.byte	$b0,$00,$00,$00,$00,$00,$00,$00,$00
	;.byte	$74,$00,$00,$00,$00,$00,$00,$00,$00
	;.byte	$b0,$00,$00,$00,$00,$00,$00,$00,$00
	;.byte	$b7,$00,$00,$00,$00,$00,$00,$00,$00

	.byte	$b0,$02,$34,$56,$4c,$17,$56,$55,$42
	.byte	$74,$df,$16,$31,$1e,$0f,$00,$01,$f0
	.byte	$b0,$ff,$f0,$05,$39,$b4,$2f,$30,$10
	.byte	$b7,$be,$cc,$df,$f3,$02,$f0,$02,$32


;-----------------------------------------------------------------------------
FM_WAVEFORM_END:
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
IT_FINE_SINE_DATA:
;-----------------------------------------------------------------------------
	.byte   0,  2,  3,  5,  6,  8,  9, 11, 12, 14, 16, 17, 19, 20, 22, 23
	.byte  24, 26, 27, 29, 30, 32, 33, 34, 36, 37, 38, 39, 41, 42, 43, 44
	.byte  45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 56, 57, 58, 59
	.byte  59, 60, 60, 61, 61, 62, 62, 62, 63, 63, 63, 64, 64, 64, 64, 64
	.byte  64, 64, 64, 64, 64, 64, 63, 63, 63, 62, 62, 62, 61, 61, 60, 60
	.byte  59, 59, 58, 57, 56, 56, 55, 54, 53, 52, 51, 50, 49, 48, 47, 46
	.byte  45, 44, 43, 42, 41, 39, 38, 37, 36, 34, 33, 32, 30, 29, 27, 26
	.byte  24, 23, 22, 20, 19, 17, 16, 14, 12, 11,  9,  8,  6,  5,  3,  2
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
;LUT_DIV3:
;-----------------------------------------------------------------------------
	;.byte 0, 0, 0, 1, 1, 1, 2, 2, 2
	;.byte 3, 3, 3, 4, 4, 4, 5, 5, 5
	;.byte 6, 6, 6, 7, 7, 7, 8, 8, 8
	;.byte 9, 9, 9,10,10
;-----------------------------------------------------------------------------


;*******************************************************************
CMD_RES:	; 13 bytes
;*******************************************************************
	mov	SPC_DSPA, #DSP_FLG
	mov	SPC_DSPD, #11100000b
	clrp
	mov	SPC_CONTROL, #10000000b ;
	jmp	0FFC0h

;-----------------------------------------------------------------------
SCommand_Drop:						; s7x
;-----------------------------------------------------------------------
	cmp	a, #0eh
	beq	_enable_drop
	and	mod_mode, #~MO_DROP
	mov	drop, #0
	mov	drop+1, #0
	ret

_enable_drop:
	or	mod_mode, #MO_DROP
	ret


;*****************************************************************************
__BRK_ROUTINE__:
	asl	SPC_PORT0
	;bcs	_brk_pass
	;ret
_brk_pass:
	;jmp	somewhere
	ret
;*****************************************************************************


;-----------------------------------------------------------------------------
MODULE .END
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
;FFC0 - FFFF    Memory (read / write)
;FFC0 - FFFF    Memory (write only)*
;FFC0 - FFFF    64 byte IPL ROM (read only)*
;-----------------------------------------------------------------------------

