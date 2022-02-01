.ifndef __SPRITE_CROLL32_INC__
__SPRITE_CROLL32_INC__ = 1
;-------------------------------------------------------------------------;

;*************************************************************************;
; uses memptr so call after using snes_decompress macros or edit
; spr-scroll-32.asm to use a different zp var
;
; a = scrolltext bank
; b = scrolltext ypos
; x = scrolltext address
; y = address where font gfx are located (assumes bank 7eh)
;*************************************************************************;
.global SpriteScroll32Setup

.global SINE_OF_DOOM, SpriteScroll32, SpriteScroll32Attributes
.global TransferOAMGfxToVram
;-------------------------------------------------------------------------;
.endif
