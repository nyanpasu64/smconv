.ifndef __PLASMA_INC__
__PLASMA_INC__ = 1
;-------------------------------------------------------------------------;
.global PLASMA_SINE, ColorBlend, CopyPlasmaGfx, DoPlasma, InitPlasma
.global PlasmaHDMAMover, PlasmaMapHDMA, PlasmaMode7, PlasmaOnlyHDMA
;-------------------------------------------------------------------------;
.globalzp HDMAdis1, HDMAdis2, HDMAoffset1, HDMAoffset2, Storage
.globalzp Storage2, blend2131, blendbitsoffset, blendbitsoffset
.globalzp blendbrightoffset, blendflip, blendflip2, matrixaoffset
.globalzp matrixdcos
.globalzp plasma_bar, plasma_opt, plasmahscrpos, plasma_mode
.globalzp plasmavscrpos, spinflag, xcentercoord, ycentercoord
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
PLASMAHDMACOLADDR = 7f0000h

PLASMAOFF = 0	; map only
PLASMAON  = 1
PLASMAMAP = 2
;-------------------------------------------------------------------------;
.endif
