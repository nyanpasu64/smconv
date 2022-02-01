#-------------------------------------------------------------------------
# SNES MODE 25H (ExHiROM 64mbit size, 63mbit usable) Memory Specification
#-------------------------------------------------------------------------

*************************************************************************
MEMORY {
#*************************************************************************

#-------------------------------------------------------------------------
# HROM used for extended program code (32k)
#   ( do NOT access HROM normally! )
# CROM used for common program code (32k) (shared across banks)
# really at bank C0 but use 0 to avoid asm errors
#-------------------------------------------------------------------------
	HROM:	start = $C00000, size = $8000, fill = yes;
	CROM:	start = $C08000, size = $7FB0, fill = yes;	# CROM and CHEAD must be
	CHEAD:	start = $C0FFB0, size = $50, fill = yes;		# mirrored at 408000
#-------------------------------------------------------------------------
# insert rom sections for program data
#-------------------------------------------------------------------------
	ROM1:	start = $C10000, size = $10000, fill = yes;
	ROM2:	start = $C20000, size = $70000, fill = yes;
	ROM3:	start = $C90000, size = $80000, fill = yes;
	ROM4:	start = $D10000, size = $80000, fill = yes;
	ROM5:	start = $D90000, size = $80000, fill = yes;
	ROM6:	start = $E10000, size = $80000, fill = yes;
	ROM7:	start = $E90000, size = $80000, fill = yes;
	ROM8:	start = $F10000, size = $f0000, fill = yes;

	ROM9:	start = $400000, size = $08000, fill = yes;
	ROMA:	start = $408000, size = $08000, fill = yes;
	ROMB:	start = $410000, size = $70000, fill = yes;
	ROMC:	start = $480000, size = $80000, fill = yes;
	ROMD:	start = $500000, size = $80000, fill = yes;
	ROME:	start = $580000, size = $80000, fill = yes;
	ROMF:	start = $600000, size = $80000, fill = yes;
	ROMG:	start = $680000, size = $80000, fill = yes;
	ROMH:	start = $700000, size = $80000, fill = yes;
	ROMI:	start = $780000, size = $60000, fill = yes;

	ROMJ:	start = $3e0000, size = $08000, fill = yes;
	ROMK:	start = $3e8000, size = $08000, fill = yes;
	ROML:	start = $3f0000, size = $08000, fill = yes;
	ROMM:	start = $3f8000, size = $08000, fill = yes;
#-------------------------------------------------------------------------
# 128K memory
#-------------------------------------------------------------------------
	ZPAGE:	start = $0000, size = 256;	# 8k loram
	LORAM:	start = $0100, size = 7936;	#
	HIRAM1:	start = $7E2000, size = 57344;	# 56k hiram1
	HIRAM2:	start = $7F0000, size = 65536;	# 64k hiram2
}

#*************************************************************************
SEGMENTS {
#*************************************************************************

# if you aren't using some segments you can comment them
# out to prevent linker warnings (no way to turn them off???)
#-------------------------------------------------------------------------
# standard segments
#-------------------------------------------------------------------------
	CODE:		load = CROM, type = ro;		# 32k code
	XCODE:		load = HROM, type = ro;		# 32k xcode
	HEADER:		load = CHEAD, type = ro;	# cartridge header
	ZEROPAGE:	load = ZPAGE, type = zp;	# zero page
	BSS:		load = LORAM, type = bss;	# 8k (minus zpage) bss
	RODATA:		load = ROM1, type = ro;		# some rodata...
	
#-------------------------------------------------------------------------
# Remember to use FAR addressing or similar compensation when
# accessing data that is not mapped to bank 00H/80H
#-------------------------------------------------------------------------
	HRAM:		load = HIRAM1, type = bss;	# 56K+64K HRAM
	HRAM2:		load = HIRAM2, type = bss;	# 
	
#-------------------------------------------------------------------------
# select load and run segments for HDATA
# default: load in ROM1, run in 32k HIRAM2
#-------------------------------------------------------------------------
	HDATA:		load = ROM1, run = HIRAM2, type = rw, define = yes;
	
#-------------------------------------------------------------------------
# custom segments (insert as needed)
#-------------------------------------------------------------------------
	DATA1:		load = ROM1, type = ro;
	DATA2:		load = ROM2, type = ro;
	GRAPHICS:	load = ROM3, type = ro;
	GRAPHICS2:	load = ROM4, type = ro;
	GRAPHICS3:	load = ROM5, type = ro;
	GRAPHICS4:	load = ROM6, type = ro;
	GRAPHICS5:	load = ROM7, type = ro;
	SOUNDBANK:	load = ROM8, type = ro;

	DATA3:		load = ROM9, type = ro;
	MIRROR:		load = ROMA, type = ro;
	GRAPHICS6:	load = ROMB, type = ro;
	GRAPHICS7:	load = ROMC, type = ro;
	GRAPHICS8:	load = ROMD, type = ro;
	GRAPHICS9:	load = ROME, type = ro;
	GRAPHICSA:	load = ROME, type = ro;
	GRAPHICSB:	load = ROMF, type = ro;
	GRAPHICSC:	load = ROMG, type = ro;
	GRAPHICSD:	load = ROMH, type = ro;
	GRAPHICSE:	load = ROMI, type = ro;

	UNMAPPED1:	load = ROMJ, type = ro;
	DATA4:		load = ROMK, type = ro;
	UNMAPPED2:	load = ROML, type = ro;
	DATA5:		load = ROMM, type = ro;
}
