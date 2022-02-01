.ifndef __FUNCTIONS_INC
__FUNCTIONS_INC = 1

;====================================================================

.include "snes.inc"
.include "snes_decompress.inc"
.include "snes_zvars.inc"
.include "graphics.inc"
.include "snesmod.inc"
.include "soundbank.inc"
.include "sounds.inc"

; vram addresses
BG2MAP = (0C000H/2)
MAP_START = 0000h
TILES_START = 0800h
TILES_START2 = 2000h
fadeout = 12h

TIMER = m0
REACHEND = m0+1
WRITE = m1
FADE = m2
HOFS = m3
READ = m4
SOURCE = m5
STIME = 3               ; 5 is the lowest this can be set if using sound
FADEOUT = m6
FADEOUTC = m6+1


;TM_ON = %---abcde
;---abcde            a: Sprites disable/enable.
;                    b: Disable/enable BG4.
;                    c: Disable/enable BG3.
;                    d: Disable/enable BG2.
;                    e: Disable/enable BG1.

;====================================================================
.macro clear_vram
;====================================================================
	pha
	phx
	php

	lda	#80h                    ;
	sta	REG_VMAIN               ; Set VRAM port to word access
	ldx	#$1809                  ;
	stx	REG_DMAP0               ; Set DMA mode to fixed source, WORD to $2118/9
	ldx	#$0000                  ;
	stx	REG_VMADD               ; Set VRAM port address to $0000
	stx	$0000                   ; Set $00:0000 to $0000 (assumes scratchpad ram)
	stx	REG_A1T0                ; Set source address to $xx:0000
	lda	#00h                    ;
	sta	REG_A1B0                ; Set source bank to $00
	ldx	#$ffff                  ;
	stx	REG_DAS0                ; Set transfer size to 64k-1 bytes
	lda	#01h                    ;
	sta	REG_MDMAEN              ; Initiate transfer
	stz	REG_VMDATAH             ; Clear the last byte of the VRAM
        
	plp
	plx
	pla
;--------------------------------------------------------------------
.endmacro
;====================================================================
.macro fade_in
;====================================================================
	lda	#0			; fade in screen
:	wai				;
	sta	REG_INIDISP		;
	ina				;
	cmp	#16			;
	bne	:-			;
;--------------------------------------------------------------------
.endmacro
;====================================================================
.macro fade_in_screen gfx_map, gfx_tiles, gfx_pal, mode, tile_reduction
;====================================================================
	lda	#0			; disable layers
	sta	REG_TM			;
;--------------------------------------------------------------------
					; copy graphics
					;
	DoDecompressDataVram gfx_map, MAP_START
.ifblank tile_reduction
	DoDecompressDataVram gfx_tiles, TILES_START
.else
	DoDecompressDataVram gfx_tiles, TILES_START2
.endif
	DoCopyPalette gfx_pal, 0, 256
;--------------------------------------------------------------------
	stz	REG_BG1SC		; set bg0 control 32x32 map = 0
	stz	REG_BG1HOFS		; reset offset
	stz	REG_BG1HOFS		;

	lda	#-1			;
	sta	REG_BG1VOFS		;
	stz	REG_BG1VOFS		;
;--------------------------------------------------------------------
	lda	#mode			;
	sta	REG_BGMODE		;
;--------------------------------------------------------------------
.ifnblank tile_reduction
        lda     #21h
        sta     REG_BG12NBA
.endif
;--------------------------------------------------------------------
	wai				; enable bg1
	lda	#1			;
	sta	REG_TM			;
;--------------------------------------------------------------------
	lda	#0			; fade in screen
:	wai				;
	sta	REG_INIDISP		;
	ina				;
	cmp	#16			;
	bne	:-			;
;--------------------------------------------------------------------
.endmacro
;====================================================================
.macro fade_out
;====================================================================
	lda	#15			; fade out screen
:	wai				;
	dea				;
	sta	REG_INIDISP		;
	bne	:-			;
;--------------------------------------------------------------------
	lda	#80h
	sta	REG_INIDISP
;--------------------------------------------------------------------
.endmacro
;====================================================================
.macro mod_play module, volume
;====================================================================
	ldx	#module
	jsr	spcLoad
	ldx	#0
	jsr	spcPlay
;--------------------------------------------------------------------
	ldx	#volume
	jsr	spcSetModuleVolume
;--------------------------------------------------------------------
	jsr	spcFlush
;--------------------------------------------------------------------
.endmacro
;====================================================================
.macro mod_stop
;====================================================================
	lda	#1
	sta	fadeout, S
	ldx	#0
	ldy	#8
	jsr	spcFadeModuleVolume
	jsr	spcProcess		; PROCESS SPC stuff
;--------------------------------------------------------------------
.endmacro
;====================================================================
.macro PrintText map1, tiles1, pal1, pal2, tiles2
;====================================================================
        lda	#0			; disable layers
        sta	REG_TM			;
;-------------------------------------------------------------------------
					; load graphics
					;
	DoDecompressDataVram map1, MAP_START
	DoDecompressDataVram tiles1, TILES_START2
	DoCopyPalette pal1, 0, 255
	DoCopyPalette pal2, 0, 16
	DoCopyPalette pal2, 16, 16
	DoDecompressDataVram tiles2, 8000h

	stz	REG_CGADD
	stz	REG_CGDATA
	stz	REG_CGDATA
	
	lda	#1+16
	sta	REG_CGADD
	lda	#0EFH
	sta	REG_CGDATA
	lda	#03DH
	sta	REG_CGDATA
	
	stz	REG_BG1SC
	stz	REG_BG1HOFS
	stz	REG_BG1HOFS
	stz	REG_BG2HOFS
	stz	REG_BG2HOFS
	LDA	#-1
	STA	REG_BG1VOFS
	STA	REG_BG1VOFS
	sta	REG_BG2HOFS
	sta	REG_BG2HOFS
	lda	#(0C000h/800h)<<2
	sta	REG_BG2SC	
	lda	#(08000h>>13)<<4
	sta	REG_BG12NBA
;-------------------------------------------------------------------------
	lda	#BGMODE_3		; setup display
	sta	REG_BGMODE		; mode3
	lda	#%11			;
	sta	REG_TM			; bg1
	
	lda	#80h
	sta	REG_VMAIN
	
	ldx	#BG2MAP
	stx	REG_VMADD
	ldx	#1024
:	ldy	#0
	sty	REG_VMDATA
	dex
	bne	:-
;--------------------------------------------------------------------
.endmacro
;====================================================================
.macro PrintTitle gfx_pal, gfx_tiles, gfx_map
;====================================================================
	ldx	m4
	phx
	ldx	m5
	phx

	lda	#0
	sta	song_index
	
	DoDecompressDataVram gfx_sfontTiles, 0000h
	DoCopyPalette gfx_sfontPal, 16, 16
	DoCopyPalette gfx_pal, 0, 16
	DoDecompressDataVram gfx_tiles, 8800h
	DoDecompressDataVram gfx_map, 8000h
	
	lda	#(8000h>>13)<<4
	sta	REG_BG12NBA
	lda	#(8000h>>13)
	sta	REG_BG34NBA
	lda	#1
	sta	REG_BGMODE
	
	lda	#8<<2
	sta	REG_BG1SC
	lda	#(8000h/800h) << 2
	sta	REG_BG2SC
	sta	REG_BG3SC
	
	lda	#80h
	sta	REG_VMAIN
	
	ldx	#8*1024
	stx	WRITE
	stx	REG_VMADD
	ldx	#0
	ldy	#1024
:	stx	REG_VMDATA
	dey
	bne	:-
	
	lda	#-8
	sta	REG_BG1HOFS
	stz	REG_BG1HOFS
	lda	#-9
	sta	REG_BG1VOFS
	sta	REG_BG1VOFS
	lda	#-1
	sta	REG_BG2VOFS
	stz	REG_BG2VOFS
	
	lda	song_index
	asl
	tax
	sep	#10h
	rep	#30h
	lda	stories, x
	sta	SOURCE
	sep	#20h
	
	stz	FADEOUT
	stz	READ+0
	stz	READ+1
	stz	FADE
	lda	#STIME
	sta	TIMER
	stz	REACHEND
	
	lda	#%011
	sta	REG_TM
	wai
;--------------------------------------------------------------------
.endmacro
;====================================================================
.macro ReadButton button, routine, sub, branch, sound
;====================================================================
        rep     #20h
        lda     joy1_down
        bit     #(button)
        sep     #20h
        beq     branch
.ifnblank sound
	spcPlaySoundM sound
.endif
;        fade_out
	jsr	sub
        jmp     routine
branch:
;--------------------------------------------------------------------
.endmacro
;====================================================================
.macro	ReadCharM sound
;====================================================================
.scope
	lda	REACHEND
	beq	:+
	rts
:
	ldy	READ
	lda	(SOURCE), y
	beq	@end_of_text
	iny
	sty	READ

	cmp	#13
	beq	@newline
	cmp	#1
	beq	@delay

	ldy	WRITE
	sty	REG_VMADDL
	iny
	sty	WRITE
	sta	REG_VMDATAL
	lda	#1<<2
	sta	REG_VMDATAH

	cmp	#' '
	beq	@delay
.ifnblank sound
	spcPlaySoundM sound
.endif
@delay:
	rts

@newline:
	rep	#21h
	lda	WRITE
	and	#~31
	adc	#32
	sta	WRITE
	sep	#20h

	jmp	ReadChar

@end_of_text:
	lda	#1
	sta	REACHEND
	jmp	StopText
;--------------------------------------------------------------------
.endscope
.endmacro
;====================================================================
.macro RenderString px, py, text, pal
;====================================================================
	ldx	#BG2MAP + px + py * 32
	stx	REG_VMADD
	ldy	#0
	bra	:++
:	iny
	sta	REG_VMDATAL
	lda	#pal<<2
	sta	REG_VMDATAH
:	lda	text, y
	bne	:--
;--------------------------------------------------------------------
.endmacro
;====================================================================
.macro timeout seconds
;====================================================================
	ldx	#60*seconds		; timeout in seconds
:	wai
	dex
	bne	:-
;--------------------------------------------------------------------
.endmacro
;====================================================================
.macro timeout_buttons seconds, previous, next, menu
;====================================================================
.scope
	ldx     #60*seconds
keep_going:
	rep	#20h
	lda	joy1_down
	bit	#(JOYPAD_L)
	sep	#20h
	beq	:+
	fade_out
	jsr	previous
:
	rep	#20h
	lda	joy1_down
	bit	#(JOYPAD_R)
	sep	#20h
	beq	:+
	fade_out
	jsr	next
:
	rep	#20h
	lda	joy1_down
	bit	#(JOYPAD_B)
	sep	#20h
	beq	:+
	fade_out
	jsr	menu
:
	wai
	dex
	bne     keep_going
.endscope
;--------------------------------------------------------------------
.endmacro
;====================================================================
.macro TitleStuff
;====================================================================
.scope
        lda     FADE
        cmp     #60
        bcc     @fadescr

        dec     TIMER
        bne     @nochar
        lda     #STIME
        sta     TIMER
        jsr     ReadChar
@nochar:
        bra     @skipfade
@fadescr:
        ina
        sta     FADE
        cmp     #64
        bcs     @skipfade
        lsr
        lsr
        sta     REG_INIDISP
@skipfade:
        lda     FADEOUT
        beq     title_loop

        lda     FADEOUTC
        dec
        sta     FADEOUTC

        lsr
        lsr
        beq     @exit_loop

        pha
        lda     song_index
        pla
@exit_loop:

        lda     #80h
        sta     REG_INIDISP
        plx
        stx     m5
        plx
        stx     m4
        rts
.endscope
;--------------------------------------------------------------------
.endmacro
;--------------------------------------------------------------------
.endif
