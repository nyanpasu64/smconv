;-------------------------------------------------------------------------;
.include "snes.inc"
.include "snes_decompress.inc"
.include "snes_joypad.inc"
.include "snes_zvars.inc"
.include "graphics.inc"
.include "equates.inc"
.include "global.inc"
.include "snesmod.inc"
.include "soundbank.inc"
;-------------------------------------------------------------------------;
.importzp joy1_down
;-------------------------------------------------------------------------;
.global main, _nmi
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
.zeropage
;/////////////////////////////////////////////////////////////////////////;


;nmis: .res 1             ; for minimalist NMI handler
frame_ready:      .res 1  ; for SNESKit NMI handler
oam_used:         .res 2

; Game variables
player_xlo:       .res 1  ; horizontal position is xhi + xlo/256 px
player_xhi:       .res 1
player_dxlo:      .res 1  ; speed in pixels per 256 s
player_yhi:       .res 1
player_frame_sub: .res 1
player_frame:     .res 1
player_facing:    .res 1


;/////////////////////////////////////////////////////////////////////////;
.bss
;/////////////////////////////////////////////////////////////////////////;


oam_table:        .res (128*4)	; using sneskit naming convention here
oam_hitable:      .res (128*4)	;
; OAMHI contains bit 8 of X and the size bit for each sprite.
; It's a bit wasteful of memory, as the 512-byte OAMHI needs to be
; packed by software into 32 bytes before being sent to the PPU, but
; it makes sprite drawing code much simpler.  The OBC1 used in the
; game Metal Combat: Falcon's Revenge performs the same packing
; function in hardware, possibly as a copy protection method.


;/////////////////////////////////////////////////////////////////////////;
.code
;/////////////////////////////////////////////////////////////////////////;


; Minimalist NMI handler that only acknowledges NMI and signals
; to the main thread that NMI has occurred.
;.proc _nmi
;  sep #$30
;  phb
;  phk  ; set data bank to bank 0 (because banks $40-$7D and $C0-$FF
;  plb  ; can't reach main memory)
;  inc a:nmis
;  bit a:REG_RDNMI
;  plb
;  rti
;.endproc
;
; Standard SNESKit NMI handler
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
_nmi:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
  rep #30h                ; push a,x,y
  pha
  phx
  phy
  sep #20h                ; 8bit akku
;-------------------------------------------------------------------------;
  lda	frame_ready       ; skip frame update if not ready!
  beq	_frame_not_ready  ;-----------------------

  ldy	#0000h			;
  sty	REG_OAMADDL		; reset oam access

  lda	#DMAP_XFER_MODE_2	; copy oam buffers
  sta	REG_DMAP6
  lda	#<REG_OAMDATA
  sta	REG_BBAD6
  ldy	#oam_table&65535
  lda	#^oam_table
  sty	REG_A1T6L
  sta	REG_A1B6
  ldy	#544
  sty	REG_DAS6L
  lda	#%01000000
  sta	REG_MDMAEN
;-------------------------------------------------------------------------;
_frame_not_ready:
;-------------------------------------------------------------------------;
  jsr	joyRead           ; read joypads

  lda	REG_TIMEUP        ; read from REG_TIMEUP (?)

  rep	#30h              ; pop a,x,y
  ply
  plx
  pla
  rti                     ; return

.proc main
.a8
.i16
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
main:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
  ; In the same way that the CPU of the Commodore 64 computer can
  ; interact with a floppy disk only through the CPU in the 1541 disk
  ; drive, the main CPU of the Super NES can interact with the audio
  ; hardware only through the sound CPU.  When the system turns on,
  ; the sound CPU is running the IPL (initial program load), which is
  ; designed to receive data from the main CPU through communication
  ; ports at $2140-$2143.  Load a program and start it running.
  jsr spcBoot             ; boot SPC
  lda #^__SOUNDBANK__     ; setup soundbank
  jsr spcSetBank         

  lda #^SOUND_TABLE|80h    ; setup soundtable
  ldy #.loword(SOUND_TABLE)
  jsr spcSetSoundTable

  lda #59                 ; (*256 bytes = largest sound size)
  jsr spcAllocateSoundRegion

  ldx #150
  jsr spcSetModuleVolume
	
  ldx #MOD_FRAK
  jsr spcLoad
	
  ldx #0
  jsr spcPlay
  jsr spcFlush

  ; Copy background and sprite palettes to PPU.
  ; We perform the copy using DMA (direct memory access), which has
  ; four steps:
  ; 1. Set the destination address in the desired area of memory,
  ;    be it CGRAM (palette), OAM (sprites), or VRAM (tile data and
  ;    background maps).
  ; 2. Tell the DMA controller which area of memory to copy to.
  ; 3. Tell the DMA controller the starting address to copy from.
  ; 4. Tell the DMA controller how big the data is in bytes.
  DoCopyPalette PALETTE, 0, 8	; see $(SNESKIT)/include/snes_decompress.inc
  ; There are 8 sprite palettes, each 15 colors in size, at $81-$8F,
  ; $91-$9F, ..., $F1-$FF.  Each color takes two bytes.
  ; CGRAM is word addressed, which means addresses are in 16-bit
  ; units, so you write the number of the color.
  DoCopyPalette gfx_swinging2Pal, 128, 16
  ; Copy background and sprite tiles to PPU.
  ; PPU memory is also word addressed because the low and high bytes
  ; are actually on separate chips.
  ; In background mode 0, all background tiles are 2 bits per pixel,
  ; which take 16 bytes or 8 words per tile.
  DoDecompressDataVram gfx_bgTiles, $0000

  ; The Super NES supports only square sprites.  This means you
  ; sometimes have to leave blank space around oddly sized sprites.
  ;ldx #$4000
  ;ldy #$0000
  ;jsr ppu_clear_nt  ; clear part of player sprite that isn't used

  ; After leaving the blank space, copy in the sprite data.
  ; Sprites in all background modes use 4-bit-per-pixel tiles,
  ; which take 32 bytes or 16 words per tile.
  DoDecompressDataVram gfx_swinging2Tiles, $8000
  
  ; Load nametable (background map) data
  jsr draw_bg

  ; Program the PPU for the display mode
  sep #$20
  stz REG_BGMODE         ; mode 0 (four 2-bit BGs) with 8x8 tiles
  stz REG_BG12NBA        ; bg CHR at $0000
  lda #$4000 >> 13
  sta REG_OBSEL          ; sprite CHR at $4000, 8x8 and 16x16
  lda #>$6000
  sta REG_BG1SC          ; plane 0 nametable at $6000
  lda #TM_OBJ|TM_BG1     ; enable sprites and plane 0
  sta REG_TM
  lda #NMI_ON|NMI_JOYPAD ; enable vblank NMI and controller autoreading
  sta REG_NMITIMEN       ; and disable hblank and vcount IRQs

  ; Set up game variables, as if it were the start of a new level.
  lda #1
  sta frame_ready
  stz player_facing
  stz player_dxlo
  lda #184
  sta player_yhi
  rep #$30
  stz player_frame_sub
  lda #48 << 8
  sta player_xlo

forever:

  sep #$30
  jsr move_player

  ; Draw the player to a display list in main memory
  rep #$30
  stz oam_used
  jsr draw_player_sprite

  ; Mark remaining sprites as offscreen, then convert sprite size
  ; data from the convenient-to-manipulate format described by
  ; psycopathicteen to the packed format that the PPU actually uses.
  ldx oam_used
  jsr ppu_clear_oam
  jsr ppu_pack_oamhi

  ; PPU OAM can be modified only during vertical blanking.
  ; Wait for vertical blanking and copy prepared data to OAM.
  jsr ppu_vsync
  ;jsr ppu_copy_oam  ; use with minimalist nmi
  sep #$20
  lda #$0F
  sta REG_INIDISP  ; turn on rendering

  ; wait for control reading to finish
  lda #$01
padwait:
  bit REG_HVBJOY
  bne padwait
  stz REG_BG1HOFS
  stz REG_BG1HOFS

  bra forever
.endproc

; except for STZs, the following subroutine is direct copypasta
; from NES code
cur_keys = REG_JOY1L+1
KEY_LEFT = $02
KEY_RIGHT = $01

; constants used by move_player
; PAL frames are about 20% longer than NTSC frames.  So if you make
; dual NTSC and PAL versions, or you auto-adapt to the TV system,
; you'll want PAL velocity values to be 1.2 times the corresponding
; NTSC values, and PAL accelerations should be 1.44 times NTSC.
WALK_SPD = 105  ; speed limit in 1/256 px/frame
WALK_ACCEL = 4  ; movement acceleration in 1/256 px/frame^2
WALK_BRAKE = 8  ; stopping acceleration in 1/256 px/frame^2

.proc move_player

  ; Acceleration to right: Do it only if the player is holding right
  ; on the Control Pad and has a nonnegative velocity.
  lda cur_keys
  and #KEY_RIGHT
  beq notRight
  lda player_dxlo
  bmi notRight
  
  ; Right is pressed.  Add to velocity, but don't allow velocity
  ; to be greater than the maximum.
  clc
  adc #WALK_ACCEL
  cmp #WALK_SPD
  bcc :+
  lda #WALK_SPD
:
  sta player_dxlo
  lda player_facing  ; Set the facing direction to not flipped 
  and #<~$40         ; turn off bit 6, leave all others on
  sta player_facing
  jmp doneRight

  ; Right is not pressed.  Brake if headed right.
notRight:
  lda player_dxlo
  bmi doneRight
  cmp #WALK_BRAKE
  bcs notRightStop
  lda #WALK_BRAKE+1  ; add 1 to compensate for the carry being clear
notRightStop:
  sbc #WALK_BRAKE
  sta player_dxlo
doneRight:

  ; Acceleration to left: Do it only if the player is holding left
  ; on the Control Pad and has a nonpositive velocity.
  lda cur_keys
  and #KEY_LEFT
  beq notLeft
  lda player_dxlo
  beq :+
  bpl notLeft
:

  ; Left is pressed.  Add to velocity.
  lda player_dxlo
  sec
  sbc #WALK_ACCEL
  cmp #256-WALK_SPD
  bcs :+
  lda #256-WALK_SPD
:
  sta player_dxlo
  lda player_facing  ; Set the facing direction to flipped
  ora #$40
  sta player_facing
  jmp doneLeft

  ; Left is not pressed.  Brake if headed left.
notLeft:
  lda player_dxlo
  bpl doneLeft
  cmp #256-WALK_BRAKE
  bcc notLeftStop
  lda #256-WALK_BRAKE
notLeftStop:
  adc #8-1
  sta player_dxlo
doneLeft:

  ; In a real game, you'd respond to A, B, Up, Down, etc. here.
  lda joy1_down
  bit #JOYPAD_A
  beq nkeypress_a

  rep #$10
  sep #$20

  lda #SND_SELNOW
  jsr spcPlaySound

nkeypress_a:
  jsr spcProcess

skip_snd:
  ; Move the player by adding the velocity to the 16-bit X position.
  lda player_dxlo
  bpl player_dxlo_pos
  ; if velocity is negative, subtract 1 from high byte to sign extend
  dec player_xhi
player_dxlo_pos:
  clc
  adc player_xlo
  sta player_xlo
  lda #0          ; add high byte
  adc player_xhi
  sta player_xhi

  ; Test for collision with side walls
  cmp #28
  bcs notHitLeft
  lda #28
  sta player_xhi
  stz player_dxlo
  beq doneWallCollision
notHitLeft:
  cmp #212
  bcc notHitRight
  lda #211
  sta player_xhi
  stz player_dxlo
notHitRight:
doneWallCollision:
  
  ; Animate the player
  ; If stopped, freeze the animation on frame 0 (stand)
  lda player_dxlo
  bne notStop1
  lda #$C0
  sta player_frame_sub
  stz player_frame
  rts
notStop1:

  ; Take absolute value of velocity (negate it if it's negative)
  bpl player_animate_noneg
  eor #$FF
  clc
  adc #1
player_animate_noneg:

  lsr a  ; Multiply abs(velocity) by 5/16
  lsr a
  sta m0
  lsr a
  lsr a
  adc m0

  ; And 16-bit add it to player_frame
  adc player_frame_sub
  sta player_frame_sub
  lda player_frame
  adc #0

  ; Wrap from $800 (after last frame of walk cycle) to $100 (first
  ; frame of walk cycle)
  cmp #8
  bcc have_player_frame
  lda #1
have_player_frame:
  sta player_frame
  rts
.endproc

;;
; Draw the player's sprite to the display list using 16x16 pixel
; sprites.  Hardware 16x16 makes it a sh'load easier to draw a
; character than it was on the NES where even modestly sized
; characters required laying out a grid of sprites.
.proc draw_player_sprite
  ldx oam_used

  ; OAM+0,x: x coordinate, top half
  ; OAM+1,x: y coordinate, top half
  ; OAM+2,x: flipping, priority, and palette, top half
  ; OAM+3,x: tile number, top half
  ; OAM+4-7,x: same for bottom half
  ; OAMHI+1,x: x coordinate high bit and size bit, top half
  ; OAMHI+5,x: same for bottom half
  
  ; Frame 7's center of gravity is offset a little to fit in the
  ; 16-pixel-wide box.  This means its X coordinate needs to be
  ; offset by about a pixel.
  sep #$20
  lda player_frame
  cmp #7  ; C = true for frame 7, false otherwise
  lda #0
  bcc have_xoffset
  bit player_facing
  bvc have_xoffset
  ; What we want to happen:
  ; Not frame 7: Add 0
  ; Frame 7, facing right: Add 1
  ; Frame 7, facing left: Subtract 1
  ; But because carry is set only for frame 7, we can take a shortcut
  ; Not frame 7: Add 0
  ; Frame 7, facing right: Add 0 plus the carry 1
  ; Frame 7, facing left: Add -2 plus the carry 1
  lda #<-2
have_xoffset:
  adc player_xhi
  and #$00FF
  sta OAM+0,x
  sta OAM+4,x
  rep #$20
  lda #$0200  ; large, and not off left side
  sta OAMHI+0,x
  sta OAMHI+4,x
  sep #$20
  lda player_facing
  ora #$30  ; priority
  xba
  lda player_frame  ; tile number
  asl a
  rep #$20
  sta OAM+2,x
  clc
  adc #32
  sta OAM+6,x
  sep #$21
  lda player_yhi
  sbc #24
  sta OAM+1,x
  clc
  adc #16
  sta OAM+5,x
  
  ; The character uses two display list entries (8 bytes).
  ; Mark them used.
  txa
  clc
  adc #8
  sta oam_used
  rts
.endproc

.proc draw_bg
  ; This demo's background tile set includes glyphs at ASCII code
  ; points $20 (space) through $5F (underscore).  Clear the map
  ; to all spaces.
  rep #$30
  ldx #$6000
  ldy #' ' | (1 << 10)
  jsr ppu_clear_nt
  
  ; The screen spans rows 0-27, of which rows 23-27 are the ground.
  ; Draw the top of the ground using a grass tile
  rep #$30
  lda #$6000|NTXY(0, 23)
  sta REG_VMADDL
  lda #$000B
  ldx #32
floorloop1:
  sta REG_VMDATAL
  dex
  bne floorloop1
  
  ; Draw areas buried under the floor as solid color
  lda #$0001
  ldx #4*32
floorloop2:
  sta REG_VMDATAL
  dex
  bne floorloop2

  ; Draw blocks on the sides, in vertical columns
  sep #$20
  lda #VRAM_DOWN|INC_DATAHI
  sta REG_VMAIN
  rep #$30
  
  ; At position (2, 19) (VRAM $6262) and (28, 19) (VRAM $627C),
  ; draw two columns of two blocks each, each block being 4 tiles:
  ; 0C 0D
  ; 0E 0F
  ldx #2

colloop:
  txa
  ora #$6000 | NTXY(0, 19)
  sta REG_VMADDL

  ; Draw $0C $0E $0C $0E or $0D $0F $0D $0F depending on column
  and #$0001
  ora #$040C  ; palette 1
  ldy #4
tileloop:
  sta REG_VMDATAL
  eor #$02
  dey
  bne tileloop

  ; Columns 2, 3, 28, and 29 only  
  inx
  cpx #4  ; Skip columns 4 through 27
  bne not4
  ldx #28
not4:
  cpx #30
  bcc colloop

  sep #$20
  lda #INC_DATAHI
  sta REG_VMAIN
  ; The Super NES has no attribute table. Yay.
  rts
.endproc

SND_SELNOW = 0
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SOUND_TABLE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
  .byte 8                           ; Default pitch (1..8) (hz = PITCH*2000)
  .byte 8                           ; Default panning (0..15)
  .byte 15                          ; Default volume (0..15)
  .word (SELECTION_END-SELECTION)/9 ; Number of BRR chunks in sample (BYTES/9)
  .word .loword(SELECTION)          ; Address of BRR sample
  .byte ^SELECTION                  ; Address bank


;/////////////////////////////////////////////////////////////////////////;
.segment "GRAPHICS"
;/////////////////////////////////////////////////////////////////////////;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
PALETTE:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
   .word $7e2a,$0068,$01e0,$1383 ; NES colours based on how they appear
   .word $4b9f,$0177,$0abe,$3fde ; on my C=1702 monitor -ab
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;/////////////////////////////////////////////////////////////////////////;
.segment "SOUNDS"
;/////////////////////////////////////////////////////////////////////////;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SELECTION:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
.incbin "../sounds/selnow.brr"
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SELECTION_END:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;/////////////////////////////////////////////////////////////////////////;
.segment "HDATA"                        
;/////////////////////////////////////////////////////////////////////////;
.segment "HRAM"
;/////////////////////////////////////////////////////////////////////////;
.segment "HRAM2"
;/////////////////////////////////////////////////////////////////////////;


; TO DO:
; 1. Get sprite palette correct
; 2. Draw one sprite 
; 3. Ensure that high OAM completion still works
; 4. Get OAM DMA working
