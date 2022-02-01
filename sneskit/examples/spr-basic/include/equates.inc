.ifndef __EQUATES_INC__
__EQUATES_INC__ = 1

DMA_00       = $02
DMA_01       = $03
DMA_CONST    = $08
DMA_LINEAR   = $00
DMAMODE_CGDATA    = (<REG_CGDATA << 8) | DMA_00
DMAMODE_OAMDATA   = (<REG_OAMDATA << 8) | DMA_00
DMAMODE_PPUDATA   = (<REG_VMDATAL << 8) | DMA_01
INC_DATAHI   = $80
OAM          = oam_table
OAMHI        = oam_hitable
VRAM_DOWN    = $01

.endif
