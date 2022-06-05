CC      := gcc
CXX	:= g++
CPP 	:= $(CC) -E
LD 	:= gcc
AS 	:= gcc

BUILD 	:= build

ifneq ($(BUILDING),1)

#if no target name is provided the name of the current folder is used
TARGET		:=
SOURCES 	:= src
LIBDIRS		:=
LIBS		:=
INCLUDES	:= include $(foreach dir,$(LIBDIRS),$(dir)/include)

RELEASE_FLAGS 	:= -DNDEBUG -s -O3 -flto
DEBUG_FLAGS	:= -DDEBUG  -g -O0 -fstrict-aliasing

IPATH 		:= $(addprefix -I$(CURDIR)/, $(INCLUDES))
LPATH		:= $(foreach dir,$(LIBDIRS),-L$(CURDIR)/$(dir)/lib)

WARN		:= -Wall -Wextra -Wstrict-aliasing -pedantic
CPPFLAGS	:= -MMD -MP

COMMON_FLAGS  	:= $(IPATH) $(CPPFLAGS) $(WARN)

ifeq ($(release),on)
BUILD 		:= $(BUILD)/release
COMMON_FLAGS	+= $(RELEASE_FLAGS)
else
BUILD 		:= $(BUILD)/debug
COMMON_FLAGS	+= $(DEBUG_FLAGS)
endif

ifeq ($(TARGET),)
TARGET 		:= $(shell basename $(CURDIR))
endif
CFILES		:= $(notdir $(shell find $(SOURCES) -name "*.c"))
CXXFILES	:= $(notdir $(shell find $(SOURCES) -name "*.cpp"))
ASMFILES	:= $(notdir $(shell find $(SOURCES) -name "*.s"))

export CXXFLAGS := $(COMMON_FLAGS) -std=c++17
export CFLAGS   := $(COMMON_FLAGS) -std=c99
export LDFLAGS  := $(LPATH) $(LIBS)
export ASFLAGS 	:=
export VPATH 	:= $(addprefix $(CURDIR)/, $(shell find $(SOURCES) -type d))
export OFILES 	:= $(CFILES:.c=.o) $(CXXFILES:.cpp=.o) $(ASMFILES:.s=.o)
export OUTPUT	:= $(CURDIR)/$(BUILD)/$(TARGET)

BUILD 		:= $(BUILD)/obj

.PHONY: $(OUTPUT) all clean run remake gen

all: $(OUTPUT)

$(OUTPUT):
	@mkdir -p $(BUILD)
	@$(MAKE) \
	--no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile -j$(nproc) \
	BUILDING=1

clean:
	@echo cleaning ...
	@rm -fr $(OUTPUT) $(BUILD)

run: all
	@$(OUTPUT) test.s -o test.bin

remake: clean all


else

$(OUTPUT): $(OFILES)
	@echo $(notdir $@)
	@$(LD) $^ -o $@ $(LDFLAGS)

%.o: %.c
	@echo $(notdir $<)
	@$(CC) $< -o $@ -c $(CFLAGS)

%.o: %.cpp
	@echo $(notdir $<)
	@$(CXX) $< -o $@ -c $(CXXFLAGS)

%.o: %.s
	@echo $(notdir $<)
	@$(AS) $< -o $@ -c $(ASFLAGS)

-include $(OFILES:.o=.d)

endif
