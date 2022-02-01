.ifndef __GLOBAL_INC__
__GLOBAL_INC__ = 1

.global oam_table, oam_hitable
.global ppu_copy_oam, ppu_pack_oamhi, ppu_clear_oam
.global ppu_copy, ppu_clear_nt, ppu_vsync

.define RGB(r,g,b) ((r)|((g)<<5)|((b)<<10))
.define NTXY(xc,yc) ((xc)|((yc)<<5))

.endif
