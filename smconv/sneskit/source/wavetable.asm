;--------------------------------------------------------------------
.export WT_C64_SQUARE, WT_NES_01, WT_SMD_01
;--------------------------------------------------------------------
	
;--///////////////////////////////////////////////////////////////--;
	.code
;--///////////////////////////////////////////////////////////////--;

WT_C64_SQUARE:
	.incbin	"../brr/c64-41h-81h.brr"
	.incbin	"../brr/c64-41h-82h.brr"
	.incbin	"../brr/c64-41h-83h.brr"
	.incbin	"../brr/c64-41h-84h.brr"
	.incbin	"../brr/c64-41h-85h.brr"
	.incbin	"../brr/c64-41h-86h.brr"
	.incbin	"../brr/c64-41h-87h.brr"
	.incbin	"../brr/c64-41h-88h.brr"

WT_NES_01:
	.incbin "../brr/nes-001.brr"
	.incbin "../brr/nes-002.brr"
	.incbin "../brr/nes-003.brr"
	.incbin "../brr/nes-004.brr"
	.incbin "../brr/nes-005.brr"
	.incbin "../brr/nes-006.brr"
	.incbin "../brr/nes-007.brr"
	.incbin "../brr/nes-008.brr"

WT_SMD_01:
	.incbin "../brr/smd-001.brr"
	.incbin "../brr/smd-002.brr"
	.incbin "../brr/smd-003.brr"
	.incbin "../brr/smd-004.brr"
	.incbin "../brr/smd-005.brr"
	.incbin "../brr/smd-006.brr"
	.incbin "../brr/smd-007.brr"
	.incbin "../brr/smd-008.brr"


