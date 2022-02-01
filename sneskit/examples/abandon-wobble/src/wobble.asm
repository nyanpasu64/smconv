;-------------------------------------------------------------------------;
.include "snes.inc"
.include "snes_decompress.inc"
.include "snes_joypad.inc"
.include "snes_zvars.inc"
.include "graphics.inc"
;-------------------------------------------------------------------------;
.import FadeInMosaic
;-------------------------------------------------------------------------;
.global DoWobble
;-------------------------------------------------------------------------;
;	Author:	Kay Struve
;	E-Mail:	pothead@uni-paderborn.de
;	Telephone:	++49-(0)5251-65459
;	Date:		Beginning of 1994
;	Machine:	Super Nintendo (65816)
;	Assembled with:	SASM V1.81,V2.00
;-------------------------------------------------------------------------;
BG1GFX = 02000h
BG1MAP = 00000h
BG2GFX = 08000h
BG2MAP = 01000h
BG3GFX = 0e000h
BG3MAP = 00800h
;-------------------------------------------------------------------------;


;-------------------------------------------------------------------------;
RAM_BG12VOFS = 1000h
;-------------------------------------------------------------------------;


;/////////////////////////////////////////////////////////////////////////;
.zeropage
;/////////////////////////////////////////////////////////////////////////;
Act_Main:
	.res 2
Comm_Bit:
	.res 1
Drw_PoiPoi:
	.res 2
Dummy_Sin:
	.res 2
L_X1Pos:
	.res 2
L_Y1Pos:
	.res 2
L_X2Pos:
	.res 2
L_Incr1:
	.res 2
L_Incr2:
	.res 2
L_DeltaX:
	.res 2
OBuf_RotX:
	.res 2
OBuf_RotY:
	.res 2
OBuf_RotZ:
	.res 2
Script_Poi:
	.res 2
Script_Next:
	.res 2


;/////////////////////////////////////////////////////////////////////////;
.code
;/////////////////////////////////////////////////////////////////////////;


.a8
.i16


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
DoWobble:
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;
	rep	#10h
	sep	#20h

	lda	#DMAP_XFER_MODE_2
	sta	REG_DMAP5
	sta	REG_DMAP6

	lda	#<REG_BG2VOFS
	sta	REG_BBAD5
	lda	#<REG_BG1VOFS
	sta	REG_BBAD6
	ldx	#RAM_BG12VOFS
	stx	REG_A1T5
	stx	REG_A1T6
	lda	#^RAM_BG12VOFS
	sta	REG_A1B5
	sta	REG_A1B6

	lda	#BGMODE_PRIO|BGMODE_1
	sta	REG_BGMODE

	lda	#(BG2GFX>>9)+(BG1GFX>>13)
	sta	REG_BG12NBA
	lda	#(BG3GFX>>13)
	sta	REG_BG34NBA

	lda	#TM_BG3|TM_BG2
	sta	REG_TM
	lda	#TM_BG1
	sta	REG_TS

	stz	REG_BG1SC
	lda	#(BG2MAP>>9)
	sta	REG_BG2SC
	lda	#(BG3MAP>>9)
	sta	REG_BG3SC

	lda	#02h			; Fixed Color Addition with
	sta	REG_CGSWSEL		; BG1,3 as Main Screens
	lda	#%110			; BG2 as Sub Screen (added to BG1)
	sta	REG_CGADSUB
	lda	#0e1h
	sta	REG_COLDATA

	DoDecompressDataVram gfx_w_sc1Tiles, BG1GFX
	DoDecompressDataVram gfx_w_sc1Map, BG1MAP
	DoDecompressDataVram gfx_w_sc2Tiles, BG2GFX
	DoDecompressDataVram gfx_w_sc2Map, BG2MAP
	DoDecompressDataVram gfx_w_sc3Tiles, BG3GFX
	DoDecompressDataVram gfx_w_sc3Map, BG3MAP; -ma8192 in grit file for bg3 priority

	DoCopyPalette gfx_w_sc1Pal, 16, 16 ; -ma1024 in grit file for pal offset
	DoCopyPalette gfx_w_sc2Pal, 32, 16 ; -ma2048 in grit file for pal offset
	DoCopyPalette gfx_w_sc3Pal,  0, 4

	ldx	#0000h
	stx	m1			; as long as 0 is loaded...
	stx	Script_Next		; Ready to start Script
	stx	Script_Poi		; Script Pointer to first entry

	lda	#01h
;-------------------------------------------------------------------------;
:	sta	RAM_BG12VOFS,x
	inx
	stz	RAM_BG12VOFS,x
	inx
	stz	RAM_BG12VOFS,x
	inx
	cpx	#224*3
	bne	:-
;-------------------------------------------------------------------------;
	stz	RAM_BG12VOFS,x
	stz	RAM_BG12VOFS+1,x
	stz	RAM_BG12VOFS+2,x

	lda	#60h
	sta	REG_HDMAEN
	lda	#0fh
	sta	Comm_Bit		; Init for Color Fade Out
	lda	#0e8h			; Vertical Timer IRQ at Line $0e8
	sta	REG_VTIMEL
	stz	REG_VTIMEH

	ldx	Act_Main
	inx
	inx
	stx	Act_Main
	ldx	#01c0h
	stx	OBuf_RotZ

	lda	#NMI_ON|NMI_JOYPAD
	sta	REG_NMITIMEN

	cli

Forever:
	lda	REG_RDNMI
	bpl	Forever

	jsr	FadeInMosaic
	jsr	VBR__02
	jsr	Main__02

	lda	m1+1
	beq	Forever

	inc	m1+1
	lda	m1+1
	cmp	#48
	bne	Forever

	stz	REG_TM
	stz	REG_TS
	stz	REG_HDMAEN

	lda	#8fh
	sta	REG_INIDISP

	lda	#88
:	dec a
	wai
	bne	:-

	jmp	DoWobble


;=========================================================================;
VBR__02:
;=========================================================================;
	inc	OBuf_RotX
	inc	OBuf_RotX+1
	inc	OBuf_RotX+1
	inc	OBuf_RotY
	inc	OBuf_RotY
	inc	OBuf_RotY

	lda	OBuf_RotX+1

	rep	#20h

	pha
	dec	OBuf_RotZ
	lda	OBuf_RotZ	
	cmp	#0ffffh
	bne	@cont
	stz	OBuf_RotZ
@cont:	pla
	and	#00ffh
	asl	a
	asl	a
	asl	a
	tax

	sep	#20h

	lda	OBuf_RotZ
	sta	REG_M7A
	lda	OBuf_RotZ+1
	sta	REG_M7A

	lda	SINUS+1,x
	sta	REG_M7B
	lda	REG_MPYM
	sta	REG_BG3HOFS
	lda	REG_MPYH
	sta	REG_BG3HOFS

	rep	#21h

	txa
	adc	#512
	and	#07ffh
	tax

	sep	#20h

	lda	OBuf_RotZ
	sta	REG_M7A
	lda	OBuf_RotZ+1
	sta	REG_M7A

	lda	SINUS+1,x
	sta	REG_M7B
	lda	REG_MPYM
	sta	REG_BG3VOFS
	lda	REG_MPYH
	sta	REG_BG3VOFS
	
	rep	#20h

	lda	OBuf_RotX+1
	and	#00ffh
	clc
	adc	#SINUS2
	sta	L_X1Pos
	lda	OBuf_RotY
	and	#00ffh
	clc
	adc	#SINUS2
	sta	L_Y1Pos

	lda	OBuf_RotX
	and	#00ffh
	tay
	lda	OBuf_RotZ
	bpl	@Pos1
	eor	#0ffffh
	inc	a
@Pos1:	clc
	ror	a
	clc
	ror	a

	sep	#20h

	sta	Dummy_Sin
	ldx	#224*3
@LOOP:	lda	SINUS2,x
	clc
	adc	(L_X1Pos),y
	ror	a
	clc
	adc	(L_Y1Pos),y
	ror	a
	sec
	sbc	Dummy_Sin
	phx
	pha

	rep	#21h

	txa
	sbc	#224*3-1
	eor	#0ffffh
	inc	a
	tax

	sep	#20h

	pla
	sta	RAM_BG12VOFS+1,x
	plx
	iny
	inc	Dummy_Sin
	dex
	dex
	dex
	bne	@LOOP
	rts


;=========================================================================;
Main__02:
;=========================================================================;
	wai
pad:	lda	REG_HVBJOY
	and	#01h
	bne	pad
	lda	Comm_Bit			; Color Fade Out
	sta	REG_INIDISP

	rep	#20h

	lda	OBuf_RotZ
	beq	@cont3

	sep	#20h

	bpl	@noBut

@cont3:	sep	#20h

	lda	Comm_Bit
	cmp	#0fh
	beq	@cont
	pha
	and	#70h
	bne	@to70
	pla
	ora	#70h
	bra	@toStop
@to70:	sec
	sbc	#10h
	bne	@cont2
	pla
	sec
	sbc	#11h
	bne	@toStop

	rep	#10h

	ldx	Act_Main			; next part
	inx
	inx
	stx	Act_Main
	bra	@toStop
@cont2:	pla
	sec
	sbc	#10h
@toStop:
	sta	Comm_Bit

	rep	#20h

	dec	OBuf_RotZ
	dec	OBuf_RotZ

	sep	#20h

	bra	@noBut

@cont:	lda	joy1_down+1
	and	#10h
	beq	@noBut

	lda	#0eh
	sta	Comm_Bit
	inc	m1+1

@noBut:	rts


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SINUS:		;     Sinus Table with 1024 Entries Words
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
	.word	$0000,$00D5,$0188,$025F,$0335,$03E8,$04BE,$0571
	.word	$0647,$071D,$07CF,$08A5,$097B,$0A2D,$0B03,$0BB5
	.word	$0C8B,$0D60,$0E12,$0EE7,$0FBC,$106D,$1142,$11F3
	.word	$12C7,$139B,$144B,$151F,$15F2,$16A2,$1775,$1825
	.word	$18F7,$19C9,$1A79,$1B4A,$1C1B,$1CCA,$1D9B,$1E48
	.word	$1F19,$1FE8,$2095,$2165,$2233,$22DF,$23AE,$2459
	.word	$2527,$25F3,$269E,$276A,$2836,$28E0,$29AB,$2A53
	.word	$2B1E,$2BE7,$2C8F,$2D58,$2E20,$2EC6,$2F8E,$3034
	.word	$30FA,$31C0,$3264,$3329,$33EE,$3491,$3554,$35F6
	.word	$36B8,$377A,$381B,$38DB,$399B,$3A3B,$3AF9,$3B97
	.word	$3C55,$3D11,$3DAF,$3E6A,$3F25,$3FC0,$407A,$4114
	.word	$41CC,$4284,$431C,$43D3,$4488,$451E,$45D3,$4668
	.word	$471B,$47CD,$4860,$4911,$49C1,$4A52,$4B01,$4B91
	.word	$4C3E,$4CEA,$4D78,$4E22,$4ECC,$4F58,$5000,$508C
	.word	$5131,$51D7,$5260,$5303,$53A7,$542E,$54CE,$5554
	.word	$55F3,$5692,$5715,$57B2,$584D,$58CF,$5968,$59E8
	.word	$5A81,$5B17,$5B94,$5C2A,$5CBE,$5D39,$5DCC,$5E44
	.word	$5ED5,$5F65,$5FDB,$6069,$60F5,$6169,$61F5,$6267
	.word	$62EF,$6378,$63E7,$646C,$64F2,$655E,$65E1,$664D
	.word	$66CD,$674C,$67B6,$6832,$68AF,$6915,$698E,$69F4
	.word	$6A6B,$6AE1,$6B44,$6BB8,$6C2B,$6C8B,$6CFB,$6D58
	.word	$6DC8,$6E35,$6E8F,$6EFB,$6F65,$6FBD,$7025,$707A
	.word	$70E0,$7145,$7197,$71FA,$725A,$72AA,$730A,$7357
	.word	$73B3,$740F,$7459,$74B2,$750A,$7551,$75A6,$75ED
	.word	$763F,$7691,$76D3,$7722,$7771,$77B0,$77FB,$7839
	.word	$7882,$78C9,$7905,$7949,$798D,$79C5,$7A06,$7A3B
	.word	$7A7B,$7AB7,$7AEA,$7B25,$7B5F,$7B8E,$7BC5,$7BF2
	.word	$7C28,$7C5A,$7C84,$7CB6,$7CE5,$7D0B,$7D39,$7D5D
	.word	$7D87,$7DB1,$7DD2,$7DF9,$7E1E,$7E3B,$7E5F,$7E7A
	.word	$7E9A,$7EBA,$7ED2,$7EEE,$7F0A,$7F1E,$7F36,$7F4A
	.word	$7F5F,$7F74,$7F84,$7F95,$7FA6,$7FB3,$7FC0,$7FCB
	.word	$7FD6,$7FDF,$7FE7,$7FEE,$7FF3,$7FF8,$7FFB,$7FFC
	.word	$7FFE,$7FFC,$7FFB,$7FF8,$7FF2,$7FEE,$7FE7,$7FDF
	.word	$7FD6,$7FCB,$7FC0,$7FB3,$7FA3,$7F95,$7F84,$7F74
	.word	$7F5F,$7F4A,$7F36,$7F1E,$7F05,$7EEE,$7ED2,$7EBA
	.word	$7E9A,$7E7A,$7E5F,$7E3B,$7E18,$7DF9,$7DD2,$7DB1
	.word	$7D87,$7D5D,$7D39,$7D0B,$7CDD,$7CB6,$7C84,$7C5A
	.word	$7C28,$7BF2,$7BC5,$7B8E,$7B55,$7B25,$7AEA,$7AB7
	.word	$7A7B,$7A3B,$7A06,$79C5,$7982,$7949,$7905,$78C9
	.word	$7882,$7839,$77FB,$77B0,$7763,$7722,$76D3,$7691
	.word	$763F,$75ED,$75A6,$7551,$74FB,$74B2,$7459,$740F
	.word	$73B3,$7357,$730A,$72AA,$724A,$71FA,$7197,$7145
	.word	$70E0,$707A,$7025,$6FBD,$6F53,$6EFB,$6E8F,$6E35
	.word	$6DC8,$6D58,$6CFB,$6C8B,$6C18,$6BB8,$6B44,$6AE1
	.word	$6A6B,$69F4,$698E,$6915,$689A,$6832,$67B6,$674C
	.word	$66CD,$664D,$65E1,$655E,$64DC,$646C,$63E7,$6378
	.word	$62EF,$6267,$61F5,$6169,$60DE,$6069,$5FDB,$5F65
	.word	$5ED5,$5E44,$5DCC,$5D39,$5CA5,$5C2A,$5B94,$5B17
	.word	$5A81,$59E8,$5968,$58CF,$5833,$57B2,$5715,$5692
	.word	$55F3,$5554,$54CE,$542E,$538B,$5303,$5260,$51D7
	.word	$5131,$508C,$5000,$4F58,$4EB0,$4E22,$4D78,$4CEA
	.word	$4C3E,$4B91,$4B01,$4A52,$49A4,$4911,$4860,$47CD
	.word	$471B,$4668,$45D3,$451E,$446A,$43D3,$431C,$4284
	.word	$41CC,$4114,$407A,$3FC0,$3F06,$3E6A,$3DAF,$3D11
	.word	$3C55,$3B97,$3AF9,$3A3B,$397B,$38DB,$381B,$377A
	.word	$36B8,$35F6,$3554,$3491,$33CD,$3329,$3264,$31C0
	.word	$30FA,$3034,$2F8E,$2EC6,$2DFF,$2D58,$2C8F,$2BE7
	.word	$2B1E,$2A53,$29AB,$28E0,$2814,$276A,$269E,$25F3
	.word	$2527,$2459,$23AE,$22DF,$2211,$2165,$2095,$1FE8
	.word	$1F19,$1E48,$1D9B,$1CCA,$1BF9,$1B4A,$1A79,$19C9
	.word	$18F7,$1825,$1775,$16A2,$15CF,$151F,$144B,$139B
	.word	$12C7,$11F3,$1142,$106D,$0F98,$0EE7,$0E12,$0D60
	.word	$0C8B,$0BB5,$0B03,$0A2D,$0958,$08A5,$07CF,$071D
	.word	$0647,$0571,$04BE,$03E8,$0311,$025F,$0188,$00D5
	.word	$0000,$FF2A,$FE77,$FDA0,$FCCA,$FC17,$FB41,$FA8E
	.word	$F9B8,$F8E2,$F830,$F75A,$F684,$F5D2,$F4FC,$F44A
	.word	$F374,$F29F,$F1ED,$F118,$F043,$EF92,$EEBD,$EE0C
	.word	$ED38,$EC64,$EBB4,$EAE0,$EA0D,$E95D,$E88A,$E7DA
	.word	$E708,$E636,$E586,$E4B5,$E3E4,$E335,$E264,$E1B7
	.word	$E0E6,$E017,$DF6A,$DE9A,$DDCC,$DD20,$DC51,$DBA6
	.word	$DAD8,$DA0C,$D961,$D895,$D7C9,$D71F,$D654,$D5AC
	.word	$D4E1,$D418,$D370,$D2A7,$D1DF,$D139,$D071,$CFCB
	.word	$CF05,$CE3F,$CD9B,$CCD6,$CC11,$CB6E,$CAAB,$CA09
	.word	$C947,$C885,$C7E4,$C724,$C664,$C5C4,$C506,$C468
	.word	$C3AA,$C2EE,$C250,$C195,$C0DA,$C03F,$BF85,$BEEB
	.word	$BE33,$BD7B,$BCE3,$BC2C,$BB77,$BAE1,$BA2C,$B997
	.word	$B8E4,$B832,$B79F,$B6EE,$B63E,$B5AD,$B4FE,$B46E
	.word	$B3C1,$B315,$B287,$B1DD,$B133,$B0A7,$AFFF,$AF73
	.word	$AECE,$AE28,$AD9F,$ACFC,$AC58,$ABD1,$AB31,$AAAB
	.word	$AA0C,$A96D,$A8EA,$A84D,$A7B2,$A730,$A697,$A617
	.word	$A57E,$A4E8,$A46B,$A3D5,$A341,$A2C6,$A233,$A1BB
	.word	$A12A,$A09A,$A024,$9F96,$9F0A,$9E96,$9E0A,$9D98
	.word	$9D10,$9C87,$9C18,$9B93,$9B0D,$9AA1,$9A1E,$99B2
	.word	$9932,$98B3,$9849,$97CD,$9750,$96EA,$9671,$960B
	.word	$9594,$951E,$94BB,$9447,$93D4,$9374,$9304,$92A7
	.word	$9237,$91CA,$9170,$9104,$909A,$9042,$8FDA,$8F85
	.word	$8F1F,$8EBA,$8E68,$8E05,$8DA5,$8D55,$8CF5,$8CA8
	.word	$8C4C,$8BF0,$8BA6,$8B4D,$8AF5,$8AAE,$8A59,$8A12
	.word	$89C0,$896E,$892C,$88DD,$888E,$884F,$8804,$87C6
	.word	$877D,$8736,$86FA,$86B6,$8672,$863A,$85F9,$85C4
	.word	$8584,$8548,$8515,$84DA,$84A0,$8471,$843A,$840D
	.word	$83D7,$83A5,$837B,$8349,$831A,$82F4,$82C6,$82A2
	.word	$8278,$824E,$822D,$8206,$81E1,$81C4,$81A0,$8185
	.word	$8165,$8145,$812D,$8111,$80F5,$80E1,$80C9,$80B5
	.word	$80A0,$808B,$807B,$806A,$8059,$804C,$803F,$8034
	.word	$8029,$8020,$8018,$8011,$800C,$8007,$8004,$8003
	.word	$8001,$8003,$8004,$8007,$800D,$8011,$8018,$8020
	.word	$8029,$8034,$803F,$804C,$805C,$806A,$807B,$808B
	.word	$80A0,$80B5,$80C9,$80E1,$80FA,$8111,$812D,$8145
	.word	$8165,$8185,$81A0,$81C4,$81E7,$8206,$822D,$824E
	.word	$8278,$82A2,$82C6,$82F4,$8322,$8349,$837B,$83A5
	.word	$83D7,$840D,$843A,$8471,$84AA,$84DA,$8515,$8548
	.word	$8584,$85C4,$85F9,$863A,$867D,$86B6,$86FA,$8736
	.word	$877D,$87C6,$8804,$884F,$889C,$88DD,$892C,$896E
	.word	$89C0,$8A12,$8A59,$8AAE,$8B04,$8B4D,$8BA6,$8BF0
	.word	$8C4C,$8CA8,$8CF5,$8D55,$8DB5,$8E05,$8E68,$8EBA
	.word	$8F1F,$8F85,$8FDA,$9042,$90AC,$9104,$9170,$91CA
	.word	$9237,$92A7,$9304,$9374,$93E7,$9447,$94BB,$951E
	.word	$9594,$960B,$9671,$96EA,$9765,$97CD,$9849,$98B3
	.word	$9932,$99B2,$9A1E,$9AA1,$9B23,$9B93,$9C18,$9C87
	.word	$9D10,$9D98,$9E0A,$9E96,$9F21,$9F96,$A024,$A09A
	.word	$A12A,$A1BB,$A233,$A2C6,$A35A,$A3D5,$A46B,$A4E8
	.word	$A57E,$A617,$A697,$A730,$A7CC,$A84D,$A8EA,$A96D
	.word	$AA0C,$AAAB,$AB31,$ABD1,$AC74,$ACFC,$AD9F,$AE28
	.word	$AECE,$AF73,$AFFF,$B0A7,$B14F,$B1DD,$B287,$B315
	.word	$B3C1,$B46E,$B4FE,$B5AD,$B65B,$B6EE,$B79F,$B832
	.word	$B8E4,$B997,$BA2C,$BAE1,$BB95,$BC2C,$BCE3,$BD7B
	.word	$BE33,$BEEB,$BF85,$C03F,$C0F9,$C195,$C250,$C2EE
	.word	$C3AA,$C468,$C506,$C5C4,$C684,$C724,$C7E4,$C885
	.word	$C947,$CA09,$CAAB,$CB6E,$CC32,$CCD6,$CD9B,$CE3F
	.word	$CF05,$CFCB,$D071,$D139,$D200,$D2A7,$D370,$D418
	.word	$D4E1,$D5AC,$D654,$D71F,$D7EB,$D895,$D961,$DA0C
	.word	$DAD8,$DBA6,$DC51,$DD20,$DDEE,$DE9A,$DF6A,$E017
	.word	$E0E6,$E1B7,$E264,$E335,$E406,$E4B5,$E586,$E636
	.word	$E708,$E7DA,$E88A,$E95D,$EA30,$EAE0,$EBB4,$EC64
	.word	$ED38,$EE0C,$EEBD,$EF92,$F067,$F118,$F1ED,$F29F
	.word	$F374,$F44A,$F4FC,$F5D2,$F6A7,$F75A,$F830,$F8E2
	.word	$F9B8,$FA8E,$FB41,$FC17,$FCEE,$FDA0,$FE77,$FF2A
	.word	$0000,$00D5,$0188,$025F,$0335,$03E8,$04BE,$0571
	.word	$0647,$071D,$07CF,$08A5,$097B,$0A2D,$0B03,$0BB5
	.word	$0C8B,$0D60,$0E12,$0EE7,$0FBC,$106D,$1142,$11F3
	.word	$12C7,$139B,$144B,$151F,$15F2,$16A2,$1775,$1825
	.word	$18F7,$19C9,$1A79,$1B4A,$1C1B,$1CCA,$1D9B,$1E48
	.word	$1F19,$1FE8,$2095,$2165,$2233,$22DF,$23AE,$2459
	.word	$2527,$25F3,$269E,$276A,$2836,$28E0,$29AB,$2A53
	.word	$2B1E,$2BE7,$2C8F,$2D58,$2E20,$2EC6,$2F8E,$3034
	.word	$30FA,$31C0,$3264,$3329,$33EE,$3491,$3554,$35F6
	.word	$36B8,$377A,$381B,$38DB,$399B,$3A3B,$3AF9,$3B97
	.word	$3C55,$3D11,$3DAF,$3E6A,$3F25,$3FC0,$407A,$4114
	.word	$41CC,$4284,$431C,$43D3,$4488,$451E,$45D3,$4668
	.word	$471B,$47CD,$4860,$4911,$49C1,$4A52,$4B01,$4B91
	.word	$4C3E,$4CEA,$4D78,$4E22,$4ECC,$4F58,$5000,$508C
	.word	$5131,$51D7,$5260,$5303,$53A7,$542E,$54CE,$5554
	.word	$55F3,$5692,$5715,$57B2,$584D,$58CF,$5968,$59E8
	.word	$5A81,$5B17,$5B94,$5C2A,$5CBE,$5D39,$5DCC,$5E44
	.word	$5ED5,$5F65,$5FDB,$6069,$60F5,$6169,$61F5,$6267
	.word	$62EF,$6378,$63E7,$646C,$64F2,$655E,$65E1,$664D
	.word	$66CD,$674C,$67B6,$6832,$68AF,$6915,$698E,$69F4
	.word	$6A6B,$6AE1,$6B44,$6BB8,$6C2B,$6C8B,$6CFB,$6D58
	.word	$6DC8,$6E35,$6E8F,$6EFB,$6F65,$6FBD,$7025,$707A
	.word	$70E0,$7145,$7197,$71FA,$725A,$72AA,$730A,$7357
	.word	$73B3,$740F,$7459,$74B2,$750A,$7551,$75A6,$75ED
	.word	$763F,$7691,$76D3,$7722,$7771,$77B0,$77FB,$7839
	.word	$7882,$78C9,$7905,$7949,$798D,$79C5,$7A06,$7A3B
	.word	$7A7B,$7AB7,$7AEA,$7B25,$7B5F,$7B8E,$7BC5,$7BF2
	.word	$7C28,$7C5A,$7C84,$7CB6,$7CE5,$7D0B,$7D39,$7D5D
	.word	$7D87,$7DB1,$7DD2,$7DF9,$7E1E,$7E3B,$7E5F,$7E7A
	.word	$7E9A,$7EBA,$7ED2,$7EEE,$7F0A,$7F1E,$7F36,$7F4A
	.word	$7F5F,$7F74,$7F84,$7F95,$7FA6,$7FB3,$7FC0,$7FCB
	.word	$7FD6,$7FDF,$7FE7,$7FEE,$7FF3,$7FF8,$7FFB,$7FFC
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
SINUS2:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
 .byte	$3B,$3C,$3E,$3F,$41,$42,$44,$45,$47,$48,$49,$4B,$4C,$4E,$4F,$50
 .byte	$52,$53,$54,$56,$57,$58,$59,$5B,$5C,$5D,$5E,$5F,$60,$62,$63,$64
 .byte	$65,$66,$67,$68,$69,$6A,$6A,$6B,$6C,$6D,$6E,$6E,$6F,$70,$70,$71
 .byte	$72,$72,$73,$73,$73,$74,$74,$75,$75,$75,$75,$76,$76,$76,$76,$76
 .byte	$76,$76,$76,$76,$76,$76,$75,$75,$75,$75,$74,$74,$73,$73,$73,$72
 .byte	$72,$71,$70,$70,$6F,$6E,$6E,$6D,$6C,$6B,$6A,$69,$69,$68,$67,$66
 .byte	$65,$64,$63,$62,$60,$5F,$5E,$5D,$5C,$5B,$59,$58,$57,$55,$54,$53
 .byte	$52,$50,$4F,$4D,$4C,$4B,$49,$48,$47,$45,$44,$42,$41,$3F,$3E,$3C
 .byte	$3B,$3A,$38,$37,$35,$34,$32,$31,$2F,$2E,$2D,$2B,$2A,$28,$27,$26
 .byte	$24,$23,$22,$20,$1F,$1E,$1D,$1B,$1A,$19,$18,$17,$16,$14,$13,$12
 .byte	$11,$10,$0F,$0E,$0D,$0C,$0C,$0B,$0A,$09,$08,$08,$07,$06,$06,$05
 .byte	$04,$04,$03,$03,$03,$02,$02,$01,$01,$01,$01,$00,$00,$00,$00,$00
 .byte	$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$02,$02,$03,$03,$03,$04
 .byte	$04,$05,$06,$06,$07,$08,$08,$09,$0A,$0B,$0C,$0D,$0D,$0E,$0F,$10
 .byte	$11,$12,$13,$14,$16,$17,$18,$19,$1A,$1B,$1D,$1E,$1F,$21,$22,$23
 .byte	$24,$26,$27,$29,$2A,$2B,$2D,$2E,$2F,$31,$32,$34,$35,$37,$38,$3A
 .byte	$3B,$3C,$3E,$3F,$41,$42,$44,$45,$47,$48,$49,$4B,$4C,$4E,$4F,$50
 .byte	$52,$53,$54,$56,$57,$58,$59,$5B,$5C,$5D,$5E,$5F,$60,$62,$63,$64
 .byte	$65,$66,$67,$68,$69,$6A,$6A,$6B,$6C,$6D,$6E,$6E,$6F,$70,$70,$71
 .byte	$72,$72,$73,$73,$73,$74,$74,$75,$75,$75,$75,$76,$76,$76,$76,$76
 .byte	$76,$76,$76,$76,$76,$76,$75,$75,$75,$75,$74,$74,$73,$73,$73,$72
 .byte	$72,$71,$70,$70,$6F,$6E,$6E,$6D,$6C,$6B,$6A,$69,$69,$68,$67,$66
 .byte	$65,$64,$63,$62,$60,$5F,$5E,$5D,$5C,$5B,$59,$58,$57,$55,$54,$53
 .byte	$52,$50,$4F,$4D,$4C,$4B,$49,$48,$47,$45,$44,$42,$41,$3F,$3E,$3C
 .byte	$3B,$3A,$38,$37,$35,$34,$32,$31,$2F,$2E,$2D,$2B,$2A,$28,$27,$26
 .byte	$24,$23,$22,$20,$1F,$1E,$1D,$1B,$1A,$19,$18,$17,$16,$14,$13,$12
 .byte	$11,$10,$0F,$0E,$0D,$0C,$0C,$0B,$0A,$09,$08,$08,$07,$06,$06,$05
 .byte	$04,$04,$03,$03,$03,$02,$02,$01,$01,$01,$01,$00,$00,$00,$00,$00
 .byte	$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$02,$02,$03,$03,$03,$04
 .byte	$04,$05,$06,$06,$07,$08,$08,$09,$0A,$0B,$0C,$0D,$0D,$0E,$0F,$10
 .byte	$11,$12,$13,$14,$16,$17,$18,$19,$1A,$1B,$1D,$1E,$1F,$21,$22,$23
 .byte	$24,$26,$27,$29,$2A,$2B,$2D,$2E,$2F,$31,$32,$34,$35,$37,$38,$3A
 .byte	$3B,$3C,$3E,$3F,$41,$42,$44,$45,$47,$48,$49,$4B,$4C,$4E,$4F,$50
 .byte	$52,$53,$54,$56,$57,$58,$59,$5B,$5C,$5D,$5E,$5F,$60,$62,$63,$64
 .byte	$65,$66,$67,$68,$69,$6A,$6A,$6B,$6C,$6D,$6E,$6E,$6F,$70,$70,$71
 .byte	$72,$72,$73,$73,$73,$74,$74,$75,$75,$75,$75,$76,$76,$76,$76,$76
 .byte	$76,$76,$76,$76,$76,$76,$75,$75,$75,$75,$74,$74,$73,$73,$73,$72
 .byte	$72,$71,$70,$70,$6F,$6E,$6E,$6D,$6C,$6B,$6A,$69,$69,$68,$67,$66
 .byte	$65,$64,$63,$62,$60,$5F,$5E,$5D,$5C,$5B,$59,$58,$57,$55,$54,$53
 .byte	$52,$50,$4F,$4D,$4C,$4B,$49,$48,$47,$45,$44,$42,$41,$3F,$3E,$3C
 .byte	$3B,$3A,$38,$37,$35,$34,$32,$31,$2F,$2E,$2D,$2B,$2A,$28,$27,$26
 .byte	$24,$23,$22,$20,$1F,$1E,$1D,$1B,$1A,$19,$18,$17,$16,$14,$13,$12
 .byte	$11,$10,$0F,$0E,$0D,$0C,$0C,$0B,$0A,$09,$08,$08,$07,$06,$06,$05
 .byte	$04,$04,$03,$03,$03,$02,$02,$01,$01,$01,$01,$00,$00,$00,$00,$00
 .byte	$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$02,$02,$03,$03,$03,$04
 .byte	$04,$05,$06,$06,$07,$08,$08,$09,$0A,$0B,$0C,$0D,$0D,$0E,$0F,$10
 .byte	$11,$12,$13,$14,$16,$17,$18,$19,$1A,$1B,$1D,$1E,$1F,$21,$22,$23
 .byte	$24,$26,$27,$29,$2A,$2B,$2D,$2E,$2F,$31,$32,$34,$35,$37,$38,$3A
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=;
