.ifndef __RENDER_STRING_INC__
__RENDER_STRING_INC__ = 1


;**************************************************************************;
; Print text to screen
;	
; a = palette
; x = address of text to print
; y = vram address (BGMAP_ADDRESS + x +(y*32))
;**************************************************************************;
.global RenderString
.global RenderStringBank0	; same as above but sets pointer bank to 0


;**************************************************************************;
; Print text to screen
;
; assumes you have set the palette using RenderStringSetPalette first
; This could be useful if you're not going to change the palette often
;
; x = address of text to print
; y = vram address (BGMAP_ADDRESS + x +(y*32))
;**************************************************************************;
.global RenderStringGetPalette


;**************************************************************************;
; Set palette to use
;
; a = palette
;**************************************************************************;
.global RenderStringSetPalette


;**************************************************************************;
; Set bank for text to print
;
; a = bank where text to print is located
;**************************************************************************;
.global RenderStringSetBank

.endif
