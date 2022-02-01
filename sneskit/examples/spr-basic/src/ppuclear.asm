;-------------------------------------------------------------------------;
.include "snes.inc"
.include "equates.inc"
.include "global.inc"
;-------------------------------------------------------------------------;


.i16
;;
; Clears a nametable and leaves 
; @param X address of nametable in VRAM (16-bit)
; @param Y data (16-bit)
.proc ppu_clear_nt
  sty $0000
  ldy #1024
  
  ; Clear low bytes
  sep #$20
  stz REG_VMAIN    ; +1 on REG_VMDATAL low byte write
  lda #$00         ; point at low byte of Y
  jsr doonedma
  
  lda #INC_DATAHI  ; +1 on REG_VMDATAL high byte write
  sta REG_VMAIN
  lda #$01         ; point at high byte of Y
doonedma:
  stx REG_VMADDL
  sta REG_A1T0L
  ora #<REG_VMDATAL
  sta REG_BBAD0
  lda #DMAP_FIXED
  sta REG_DMAP0
  sty REG_DAS0L
  stz REG_A1T0H
  stz REG_A1B0
  lda #$01
  sta REG_MDMAEN
  rts
.endproc

;;
; Moves remaining OAM entries to (-128, 225) to get them offscreen.
; @param X index of first sprite in OAM
.proc ppu_clear_oam
  rep #$30
lowoamloop:
  lda #$E180
  sta OAM,x
  lda #$0100
  sta OAMHI,x
  inx
  inx
  inx
  inx
  cpx #512
  bcc lowoamloop
  rts
.endproc

;;
; Converts high OAM (sizes and X sign bits) to the packed format
; expected by the S-PPU.
.proc ppu_pack_oamhi
  rep #$10
  ldx #0
  txy
packloop:
  ; pack four sprites' size+xhi bits from OAMHI
  sep #$20
  lda OAMHI+13,y
  asl a
  asl a
  ora OAMHI+9,y
  asl a
  asl a
  ora OAMHI+5,y
  asl a
  asl a
  ora OAMHI+1,y
  sta OAMHI,x
  rep #$21  ; includes clc for following addition

  ; move to the next set of 4 OAM entries
  inx
  tya
  adc #16
  tay
  
  ; done yet?
  cpx #32
  bcc packloop
  rts
.endproc

.proc ppu_copy_oam
  rep #$30
  lda #DMAMODE_OAMDATA
  ldx #OAM
  ldy #544
  ; falls through to ppu_copy
.endproc

;;
; Copies data to the PPU.
; @param X source address
; @param DBR source bank
; @param Y number of bytes to copy
; @param A 15-8: destination PPU register; 7-0: DMA mode
;        useful constants:
; REG_DMAP0_REG_VMDATAL, REG_DMAP0_REG_CGDATA, REG_DMAP0_REG_OAMDATA
.proc ppu_copy
  php
  rep #$30
  sta REG_DMAP0
  stx REG_A1T0L
  sty REG_DAS0L
  sep #$20
  phb
  pla
  sta REG_A1B0
  lda #%00000001
  sta REG_MDMAEN
  plp
  rts
.endproc

.proc ppu_vsync
  php
  sep #$30
loop1:
  bit REG_HVBJOY
  bmi loop1
loop2:
  bit REG_HVBJOY
  bpl loop2
  plp
  rts
.endproc


