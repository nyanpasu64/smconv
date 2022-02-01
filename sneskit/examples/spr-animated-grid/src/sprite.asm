;-------------------------------------------------------------------------;
.include "snes.inc"
.include "snes_decompress.inc"
.include "graphics.inc"
;-------------------------------------------------------------------------;
.import oam_table, oam_hitable, sprite_init, wait_vb, waiting
;-------------------------------------------------------------------------;
.importzp frame_ready, joy1_down
;-------------------------------------------------------------------------;
.global DoSprite
;-------------------------------------------------------------------------;


;sprite screen collision test
;by Benjamin Santiago
;(based on bazz example)


;-------------------------------------------------------------------------;
BG2MAP = 8000h
BG2GFX = 8800h
SPRGFX = 0000h
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
.bss
;/////////////////////////////////////////////////////////////////////////;


temp_xpos:	.res 1
temp_ypos:	.res 1
tile_index:	.res 2
tile_index2:	.res 2
tile_prop:	.res 1
tile_row:	.res 1


;/////////////////////////////////////////////////////////////////////////;
.code
;/////////////////////////////////////////////////////////////////////////;


.a8
.i16


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
DoSprite:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	stz	tile_index

	lda	#BGMODE_1
	sta	REG_BGMODE

	DoCopyPalette gfx_wildarms2Pal, 0, 16
	DoCopyPalette gfx_facePal, 128, 16
	DoDecompressDataVram gfx_faceTiles, SPRGFX
	DoDecompressDataVram gfx_wildarms2Map, BG2MAP
	DoDecompressDataVram gfx_wildarms2Tiles, BG2GFX

	lda	#(BG2MAP>>9)		; 8000h>>9 = 40h
	sta	REG_BG2SC
	;lda	#(BG2GFX>>9)		; 8800h>>9 = 40h
	sta	REG_BG12NBA

		;%vhoopppN
	lda	#%00110000		; enable sprite priority
	sta	tile_prop

	jsr	sprite_init		; put RAM "copy" of sprites offscreen
	jsr	position_sprites

	lda	#OBSEL_32_64|OBSEL_BASE(SPRGFX)|OBSEL_NN_8K
	sta	REG_OBSEL		; set sprite size to 32x32 at "small"

	lda	#TM_OBJ|TM_BG2		; Enable sprites
	sta	REG_TM

	lda	#0fh
	sta	REG_INIDISP		; Turn on screen, full Brightness

	lda	#NMI_ON
	sta	REG_NMITIMEN

	cli

	lda	#1
	sta	frame_ready
;--------------------------------------------------------------------------
SpriteLoop:
;--------------------------------------------------------------------------
	jsr	waiting

	ldx	tile_index
	jsr	GetTile
	stx	tile_index
;-------------------------------------------------------------------------;
done_with_arithmetic:
;-------------------------------------------------------------------------;
	jsr	wait_vb
	jsr	position_sprites

	bra	SpriteLoop

;=========================================================================;
position_sprites:
;=========================================================================;
	phx
	phy

	stz	tile_row
	stz	temp_xpos
	stz	temp_ypos

	lda	#20h
	xba

	ldy	#0000h
;-------------------------------------------------------------------------;
sprite_props:
;-------------------------------------------------------------------------;
	ldx	tile_index2
	jsr	GetTile
	stx	tile_index2
;-------------------------------------------------------------------------;
	lda	temp_ypos		; y coordinate
	sta	oam_table+01h,y

	lda	SPRITE_TABLE,x		; tile number
	sta	oam_table+02h,y

	lda	tile_prop		; tile properties
	sta	oam_table+03h,y

	lda	temp_xpos
	sta	oam_table,y		; x coordinate

	iny
	iny
	iny
	iny

	clc
	adc	#20h			; add x coordinate after each sprite
	sta	temp_xpos
	bne	sprite_props 		; end of row check  
;-------------------------------------------------------------------------;
	xba
	cmp	#0e0h			; all rows done check
	beq	end_position_sprites	; all rows are completed
;-------------------------------------------------------------------------;
	adc	#20h			; there is more work to do
	xba

	lda	temp_ypos
	adc	#20h			; add to y for next row
	sta	temp_ypos

	lda	tile_index
	sta	tile_index2

	inc	tile_row
	lda	tile_row
;-------------------------------------------------------------------------;
manage_tile_index:
;-------------------------------------------------------------------------;
	ldx	tile_index2
	jsr	GetTile
	stx	tile_index2
	dea
	beq	sprite_props
	bra	manage_tile_index
;-------------------------------------------------------------------------;
end_position_sprites:
;-------------------------------------------------------------------------;
	ldx	#0000h
;-------------------------------------------------------------------------;
:	stz	oam_hitable,x
	inx
	cpx	#14
	bne	:-
;-------------------------------------------------------------------------;
	ply
	plx
	rts


;=========================================================================;
GetTile:
;=========================================================================;
	cpx	#SPRITE_TABLE_END-SPRITE_TABLE-1
	bne	:+
;-------------------------------------------------------------------------;
	ldx	#0000h
	bra	:++
;-------------------------------------------------------------------------;
:	inx
;-------------------------------------------------------------------------;
:	rts


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SPRITE_TABLE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.byte $00,$04,$08,$0c,$40,$44,$48,$4c,$48,$44,$40,$0c,$08,$04
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SPRITE_TABLE_END:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;

