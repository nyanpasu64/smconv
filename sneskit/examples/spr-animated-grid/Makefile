#*********************************************************************************
# SNES MAKEFILE TEMPLATE (reworded devkitpro template :P)
#
# 4/28/2009
#*********************************************************************************

#---------------------------------------------------------------------------------
.SUFFIXES:
#---------------------------------------------------------------------------------

ifeq ($(strip $(SNESKIT)),)
$(error SNESKIT path not found, please add it to your environment)
endif

include	$(SNESKIT)/snes_rules

#---------------------------------------------------------------------------------
# TARGET is the name of the output binary
# BUILD is the directory where object files & intermediate files will be placed
# SOURCES is a list of directories containing source code
# INCLUDES is a list of directories containing extra header files
# GRAPHICS is a list of directories containing image files for conversion
# AUDIO is a list of directories containing audio files
#---------------------------------------------------------------------------------
TARGET		:=	$(notdir $(CURDIR))
BUILD		:=	build
SOURCES		:=	src
INCLUDES	:=	include
GRAPHICS	:=	graphics
AUDIO		:=	audio
DRIVER		:=	SNESMOD

#---------------------------------------------------------------------------------
# options for code generation
#---------------------------------------------------------------------------------

STARTFILES	:= snes_init snes_zvars snes_decompress snes_joypad #snesmod sm_spc
ASFLAGS		:= --cpu 65816 -s -D $(DRIVER) --feature force_range
SMCONVFL	:= --verbose --driver $(DRIVER) --soundbank --output soundbank

#---------------------------------------------------------------------------------
ifneq ($(BUILD),$(notdir $(CURDIR)))
#---------------------------------------------------------------------------------

export INCLUDE	:=	$(foreach dir,$(INCLUDES),-I $(CURDIR)/$(dir)) \
			-I $(CURDIR)/$(BUILD) \
			-I $(SNESKIT)/include

export OUTPUT	:=	$(CURDIR)/$(TARGET)

export LDFLAGS	:=	-C $(CURDIR)/config.ld

export VPATH	:=	$(foreach dir,$(SOURCES),$(CURDIR)/$(dir)) \
			$(foreach dir,$(GRAPHICS),$(CURDIR)/$(dir)) \
			$(foreach dir,$(AUDIO),$(CURDIR)/$(dir)) \
			$(SNESKIT)/source 

SFILES		:=	$(STARTFILES:=.asm) $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.asm)))
PNGFILES	:=	$(foreach dir,$(GRAPHICS),$(notdir $(wildcard $(dir)/*.png)))

export AUDIOFILES :=	$(foreach dir,$(AUDIO),$(notdir $(wildcard $(dir)/*.*)))

ifneq ($(AUDIOFILES),)
SFILES		:=	soundbank.asm $(SFILES)
#export SBXML	:=	$(CURDIR)/audio.xml
endif

export OFILES	:=	$(PNGFILES:.png=.o) $(SFILES:.asm=.o)
 
.PHONY: $(BUILD) clean
 
#---------------------------------------------------------------------------------
$(BUILD):
	@[ -d $@ ] || mkdir -p $@
	@make --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile
 
all	: $(BUILD)
#---------------------------------------------------------------------------------
clean:
	@echo clean ...
	@rm -fr $(BUILD) $(TARGET).sfc $(TARGET).map soundbank.nfo

#---------------------------------------------------------------------------------
else

#---------------------------------------------------------------------------------
# main targets
#---------------------------------------------------------------------------------
$(OUTPUT).sfc	: $(TILESETS) $(OFILES)

#---------------------------------------------------------------------------------
# rule for converting PNG graphics
#---------------------------------------------------------------------------------
%.asm : %.png %.grit
	@$(SNESGRIT) $<
	
#---------------------------------------------------------------------------------
# rule for converting audio files
#---------------------------------------------------------------------------------
soundbank.asm : $(AUDIOFILES)
	@echo
	@echo Compiling Soundbank ...
	@echo
	@$(SMCONV) $(SMCONVFL) $^ &>../soundbank.nfo

#---------------------------------------------------------------------------------------
endif
#---------------------------------------------------------------------------------------
