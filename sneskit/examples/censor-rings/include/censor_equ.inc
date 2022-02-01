.ifndef __CENSOR_EQU_INC__
__CENSOR_EQU_INC__ = 1

;-------------------------------------------------------------------------;
SCROLL_RAM = 7f0000h
;-------------------------------------------------------------------------;
bg1_scroll_mode = m2
end_flag	= m2+1
fi_inidisp	= m3
fo_inidisp	= m3+1
pointer		= m6
sprite_prop	= m7
temp_sprxy	= m7+1
;-------------------------------------------------------------------------;

;-------------------------------------------------------------------------;
bg1_hofs = 0f00h
bg1_vofs = bg1_hofs+1
bg2_hsine = bg1_vofs+1
bg2_vsine = bg2_hsine+1
bg3_hofs = bg2_vsine+1
bg3_vofs = bg3_hofs+1
credit_ypos = bg3_vofs+1
cgdata_l = credit_ypos+1
palette_index = cgdata_l+1
palette_timer1 = palette_index+1
palette_timer2 = palette_timer1+1
scroll_pal = palette_timer2+1
scroll_sine_index = scroll_pal+1
scroll_textpos = scroll_sine_index+1
scroll_tile = scroll_textpos+2
scroll_timer = scroll_tile+2
sprite_tile = scroll_timer+1
vmadd = sprite_tile+1	;len2
;-------------------------------------------------------------------------;

.endif
