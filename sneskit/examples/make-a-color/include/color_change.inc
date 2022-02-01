.ifndef __COLOR_CHANGE_INC
__COLOR_CHANGE_INC = 1

.globalzp cc_cgadd, cc_cgdata

;*************************************************************************
;* increse/decrese color as needed. clobbers a
;*************************************************************************
.global DecreaseBlue, DecreaseGreen, DecreaseRed, DecreaseRGB
.global IncreaseBlue, IncreaseGreen, IncreaseRed, IncreaseRGB

;*************************************************************************
;* a = the color address from which to retrieve color data from
;*************************************************************************
.global GetColor

;*************************************************************************
;* ScreenOffSetColor turns the screen off first before setting the color
;* clc = don't turn screen on before rts
;* sec = turn screen on before rts
;*************************************************************************
.global SetColor, ScreenOffSetColor

.endif
