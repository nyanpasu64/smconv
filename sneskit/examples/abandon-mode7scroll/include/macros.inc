.ifndef __MACROS_INC__
__MACROS_INC__ = 1

.include "snes.inc"
.include "snes_decompress.inc"

IrqPointer	=	$68			;Pointer for Vertical Blank Subroutines
InitPointer	=	$6a			;Actual Non-Irq Routine Running


.macro	ClearDMA			;No Arguments r=ired
	lda	#$ff
	sta	REG_WRIO
	ldx	#$000b
Clear1:	stz	REG_WRMPYA,x
	dex
	bpl	Clear1
	ldx	#$007f
Clear2:	stz	REG_DMAP0,x
	dex
	bpl	Clear2
.endmacro

.macro	InitHDMA src,len,addy,table_len	;\1=Adress of HDMA Lists in Rom (Source)
	rep	#$20			;\2=Length of HDMA Lists (will be copied
	ldx	#$0000			;	to $0200 in Ram
HDMAinit1:
	lda	f:src,x			;\3=Adress of HDMA Register Settings in Rom
	sta	$0200,x			;\4=Length of HDMA Register Table
	inx
	inx
	cpx	#len
	bne	HDMAinit1
	ldx	#$0000
	ldy	#$0000
HDMAinit2:
	lda	addy,x
	sta	REG_DMAP0,y
	inx
	inx
	lda	addy,x
	sta	REG_A1T0L,y
	inx
	inx
	lda	#$00
	sta	REG_A1B0,y
	tya
	clc
	adc	#$10
	tay
	cpx	#table_len
	bne	HDMAinit2
	sep	#$20
.endmacro

.macro CopyToVRAM src,dest,size		;\1=Source Adress of Gfx in Rom
	ldx	#dest			;\2=Destination Adress for Gfx in V-Ram
	stx	REG_VMADDL			;\3=Number of Bytes to be transfered
	ldx	#$0000
:	lda	f:src,x
	sta	REG_VMDATAL
	inx
	inx
	cpx	#size
	bne	:-
.endmacro

.macro	Wait4Blank
:	lda	REG_HVBJOY			;Make sure u r in V-Blank
	and	#$80
	beq	:-
:	lda	REG_HVBJOY
	and	#$80
	bne	:-
.endmacro

.macro Coord one, two, three
	.byte one,two,three
.endmacro

.macro LineH line, point1, point2
	.word line,point1*3,point2*3
.endmacro

.endif

