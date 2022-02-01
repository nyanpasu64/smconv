SM_VERSION = "0.1.6"

# -----------------------------------------------------------------------------
# Platform specific stuff
# -----------------------------------------------------------------------------
BOOST	:=
EXEEXT	:=
MKDIROPT :=

UNAME	:=	$(shell uname -s)

ifneq (,$(findstring MINGW,$(UNAME)))
	EXEEXT		:= .exe
	# is there a dos equivalent of the -p option?
endif

ifneq (,$(findstring Darwin,$(UNAME)))
	EXEEXT		:= -osx
endif

ifneq (,$(findstring Linux,$(UNAME)))
	BOOST		:= -BOOST
	MKDIROPT	:= -p
endif

ifneq (,$(findstring CYGWIN,$(UNAME)))
	EXEEXT		:= .exe
	MKDIROPT	:= -p
endif

# -----------------------------------------------------------------------------
# options for code generation
# -----------------------------------------------------------------------------
CC = gcc
CP = g++
CFLAGS = -Og -g -Wall $(BOOST) -D__BUILD_DATE="\"`date +'%Y%m%d'`\"" -D__BUILD_VERSION="\"$(SM_VERSION)\""
CXXFLAGS :=	$(CFLAGS) -fno-rtti -fno-exceptions
LDFLAGS := -no-pie

SOURCE = brr.cpp convert.cpp inputdata.cpp io.cpp it2spc.cpp itloader.cpp
OBJS := $(addprefix build/, $(SOURCE:.cpp=.o))
EXE=bin/smconv$(EXEEXT)
DEFINES =
LIBS =

SRC_DIR	:=	src

SRCDIRS := $(SRC_DIR)

VPATH	:= $(foreach dir, $(SRCDIRS), $(dir))

# -----------------------------------------------------------------------------
# Build rules
# -----------------------------------------------------------------------------
.PHONY: $(EXE) clean

all: build $(EXE)
# make convert.o dependent on makefile for version number
build/convert.o : Makefile

$(EXE) : $(OBJS)
	@echo make exe $(notdir $<)
	$(CP) $(LDFLAGS) $(OBJS) -o $@

build:
	@[ -d $@ ] || mkdir $(MKDIROPT) $@

build/%.o: %.cpp
	@echo make cpp obj $(notdir $<)
	$(CP) $(CXXFLAGS) -o $@ -c $<

build/%.o: %.c
	@echo make c obj $(notdir $<)
	$(CC) $(CFLAGS) -o $@ -c $<

#---------------------------------------------------------------------------------
clean:
	rm -fr build $(EXE)

