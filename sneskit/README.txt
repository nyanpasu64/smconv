********************
SNES DEVELOPMENT KIT
********************

OCTOBER 2015 EDITION + EXAMPLES

 Please add "SNESKIT" to your enviornment with the path to the SNESKIT
folder.
______________________________________________________________________

YOU NEED TO POPULATE THE KIT
______________________________________________________________________

 .------.
 | CC65 |
 `------`

 Binaries of ca65 and ld65 for Windows and Linux are included. They
are from version 2.12.9.  64-bit binaries of version 2.14 for Linux
are also included.

 If you need the source or other binaries download a cc65 package
from http://cc65.github.io/cc65/ and place in $(SNESKIT)/cc65
The binaries should then be at $(SNESKIT)/cc65/bin

 .--------------------------.
 | ADDITIONAL DOCUMENTATION |
 `--------------------------`

 You can add these to your /docs folder:
  * book1.pdf - SNES programming manual!! (25MB/RAR)
     http://romhacking.net/docs/226/
  * Programmanual.pdf - (if 65816primer.txt isn't enough)
     http://www.cs.bu.edu/~jappavoo/Resources/210/wdc_65816_manual.pdf
     http://www.westerndesigncenter.com/wdc/datasheets/Programmanual.pdf
  * w65c816s.pdf - 65816 datasheet
     http://www.westerndesigncenter.com/wdc/documentation/w65c816s.pdf

 .-----------.
 | EMULATORS |
 `-----------`

 Populate your /emu folder with these recommended emulators:
  * BSNES/HIGAN (very ACCURATE)
     http://www.byuu.com
  * Snes9x DEBUG VERSION (very DEBUGGER)
     http://romhacking.net/utils/241/
  * ZSNES (very FAST but not very accurate)
     http://www.zsnes.com
  * SNESGT (very ???)
     http://www.zophar.net/snes/snesgt.html
  * BSNES +DEBUGGER (I haven't tried it yet)
     http://romhacking.net/utils/273/
  * ZSNES +DEBUGGER (another one i haven't tried...)
    [missing link]

 .-------------.
 | OTHER TOOLS |
 `-------------`

  * VSNES - SUPER useful for viewing data (like VRAM) in an emulator
    savestate!
     http://romhacking.net/utils/274/
  * SPCTool - useful for spc development
     http://spcsets.caitsith2.net/spctool/

______________________________________________________________________

GETTING STARTED
______________________________________________________________________

 Move snes_rules_win to snes_rules for Windows.

 Four templates are provided in $(SNESKIT)/template. LOROM, HIROM,
ExHIROM (48mbit), ExHIROM (64mbit; only 63mbit is usable)! Remember
the POWERPAK doesn't like odd sizes so make sure there are enough
segments defined in config.ld.

 The templates contain a HEADER.ASM which should be modified to suit
your purposes--it contains start vectors, mapping mode, game TITLE,
cartridge speed (append _FAST to map mode for HISPEEDS), and NTSC/PAL
can be selected by changing the region.

 A .pnproj file is included for Programmers Notepad 2!

 .---------------------.
 | SYNTAX HIGHLIGHTING |
 `---------------------`

 You can customize Programmers Notepad to have syntax highlighting for
65816. Goto: Tools->Options->Schemes->Advanced, and select Assembler
from the Scheme menu.
 Goto "Keywords" and replace the x86 CPU instructions with this:

adc and asl bcc bcs beq bit bmi bne bpl bra 
clc cli cmp cpa cpx cpy dea dec dex dey eor 
ina inc inx iny jml jmp jsr lda ldx ldy lsr 
nop ora pha phb php phx phy pla plb plp plx 
ply rep rol ror rti rts sbc sec sei sep sta 
stx sty stz tax tay tcd tcs tsc txa txs txy 
tya tyx wai xba xce

 REGISTERS with this:

a x y

 DIRECTIVES with this:

.a16 .a8 .asciiz .bss .byte .code .define 
.else .elseif .endif .endmacro .endrep 
.endrepeat .endscope .export .exportzp 
.global .globalzp .i16 .i8 .if .ifdef .ifndef 
.import .importzp .include .local .macro 
.repeat .res .rodata .scope .segment .word 
.zeropage

 Also change tabsize to 8! which is optimal for assembly 
coding!!

 I may have forgotten some of the instructions/directives
so if you see one that isn't highlighted you can easily
add it to the list! and push Sort to reorganize them! :D

 You can then customize the Styles/More options according
to your taste!! Like I made numbers bold, and directives
bold and red!! (see doc/pn2_65816.png)

______________________________________________________________________

BANK_ZERO
______________________________________________________________________

	
 Add -D BANK_ZERO to the ASFLAGS in the Makefile only if you define
HROM, CROM, CHEAD without a bank:

		HROM:	start = $0000, size = $8000, fill = yes;
		CROM:	start = $8000, size = $7FB0, fill = yes;
		CHEAD:	start = $FFB0, size = $50, fill = yes;

 If you use this method and jml out of bank 80|c0 you will have to use
jml $c00000+label every time to get back to the proper bank. If you
use jml label it will go to bank 0. I do not recommend this method for
that reason. Define the start address with the bank number you are using.


 If you do as such:

		HROM:	start = $C00000, size = $8000, fill = yes;
		CROM:	start = $C08000, size = $7FB0, fill = yes;
		CHEAD:	start = $C0FFB0, size = $50, fill = yes;

 This method can cause range errors with jump tables. I haven't bothered
to figure out how to fix this other than to use jmp (pointer) instead of
jml (pointer_table,x) or jsl (pointer_table,x)
	
 If you get range errors like this:

	Range error (61440 not in [0..255])                   ;

simply add --feature force_range to ASFLAGS. This does not fix the issue
with jump tables mentioned above.

 Some of the examples are using -D BANK_ZERO and others are not. Check
Makefile and config.ld for each example.

______________________________________________________________________

SNESMOD
______________________________________________________________________

To use SNESMOD, the SNESMOD source files must be added
to the startfiles in the makefile. see the SNESMOD example.

STARTFILES	:= snes_init snes_zvars snes_decompress \
		snes_joypad snesmod sm_spc

 Set DRIVER to one of the following to select a sound driver:

DRIVER		:= SNESMOD	#  Original SNESMOD driver w/ bugfixes
				#
DRIVER		:= PITCHMOD	#  Pitch modulation + noise generation
				#
DRIVER		:= CELES	#  Commands like Mxx, Nxx, Wxx are
				# repurposed for special features.
				# Has PWM, a tiny 1 op FM synth,
				# filter sweeps. Sound effects are
				# not supported.
				#
DRIVER		:= SUPERNOFX	#  Super SNESMOD w/o sound effects
				# most standard it commands are not
				# repurposed for other features.
				# Sound effects are not supported.
______________________________________________________________________

SNESGRIT
______________________________________________________________________

 This is a graphics converter for SNES which is a modified version of
the "GBA Raster Image Transmogrifier" by Cearn, which is distributed
under the GPL.

______________________________________________________________________

EXAMPLES
______________________________________________________________________

 Some examples converted to CA65/SNESKIT by Augustus Blackheart.

 I will update with more examples whenever I have time. If anybody
wants to contribute examples, improvements or has suggestions get
in touch! 65816@morganleahrecords.com

______________________________________________________________________

IRC
______________________________________________________________________
Join #snesdev on EFNet!
