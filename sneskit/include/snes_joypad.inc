;----------------------------------------------------
; joypad reading codes
;----------------------------------------------------

.ifndef __SNES_JOYPAD__
__SNES_JOYPAD__ = 1

; joypad reading function
.global joyRead

; held = 16bit key status
; down = 16bit key changing 0->1
.globalzp joy1_down, joy1_held, joy1_prev, joy2_down, joy2_held, joy2_prev

.endif
