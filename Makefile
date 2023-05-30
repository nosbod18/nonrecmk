############################################################################
#        nonrecmk build system - http://github.com/nosbod18/nonrecmk       #
############################################################################
#  This is free and unencumbered software released into the public domain. #
#                                                                          #
#  Anyone is free to copy, modify, publish, use, compile, sell, or         #
#  distribute this software, either in source code form or as a compiled   #
#  binary, for any purpose, commercial or non-commercial, and by any       #
#  means.                                                                  #
#                                                                          #
#  In jurisdictions that recognize copyright laws, the author or authors   #
#  of this software dedicate any and all copyright interest in the         #
#  software to the public domain. We make this dedication for the benefit  #
#  of the public at large and to the detriment of our heirs and            #
#  successors. We intend this dedication to be an overt act of             #
#  relinquishment in perpetuity of all present and future rights to this   #
#  software under copyright law.                                           #
#                                                                          #
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,         #
#  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF      #
#  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  #
#  IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR       #
#  OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   #
#  ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR   #
#  OTHER DEALINGS IN THE SOFTWARE.                                         #
#                                                                          #
#  For more information, please refer to <http://unlicense.org/>           #
############################################################################

MAKEFLAGS += -rR
SHELL := /bin/bash
.SUFFIXES:
.SECONDEXPANSION:
.RECIPEPREFIX := >

OS        := $(if $(OS),Windows,$(subst Darwin,MacOS,$(shell uname -s)))
ARCH      ?= $(shell uname -m)
MODE      ?= debug
BUILD     ?= .build/$(OS)-$(ARCH)-$(MODE)/
MKEXT     ?= mk
ROOT      ?= .

compilerof = $(if $(filter-out %.c.o %.m.o,$(filter %.o,$1)),CXX,CC)
canonical  = $(patsubst $(CURDIR)/%,%,$(abspath $1))
outdirof   = $(BUILD)$(if $(suffix $1),lib,bin)
flagsof    = $1.$(if $(filter-out %.c.o %.m.o,$1),cxx,c)flags
print      = $(if $V,$(strip $2),$(if $Q,@$2,@$(if $1,printf $1;) $2))

define add.mk
    srcs     := # Project source files, supports wildcards, required
    incs     := # Directories to use as include path for the compiler, supports wildcards
    INCS     :=
    deps     := # Subprojects this project deps on (i.e. the name of their .mk file without the .mk extension)
    cflags   := # C compiler flags
    CFLAGS   :=
    cxxflags := # C++ compiler flags
    CXXFLAGS :=
    ldflags  := # Linker flags (don't worry about linking any library subprojects, that happens automatically)
    LDFLAGS  :=

    include $1
    $$(if $$(strip $$(srcs)),,$$(error $1: No source files were provided))

    t            := $$(call outdirof,$$(basename $1))/$$(notdir $$(basename $1))
    $$t.srcs     := $$(wildcard $$(call canonical,$$(srcs:%=$$(dir $1)%)))
    $$t.objs     := $$($$t.srcs:%=$$(BUILD)obj/%.o)
    $$t.incs     := $$(addprefix -I,$$(wildcard $$(call canonical,$$(incs:%=$$(dir $1)%))))
    $$t.INCS     := $$(addprefix -I,$$(wildcard $$(call canonical,$$(INCS:%=$$(dir $1)%))))
    $$t.deps     := $$(foreach d,$$(deps),$$(call outdirof,$$d)/$$d) $$($$t.objs) $1
    $$t.cflags   := $$(cflags) $$($$t.incs)
    $$t.CFLAGS   := $$(CFLAGS) $$($$t.INCS)
    $$t.cxxflags := $$(cxxflags) $$($$t.incs)
    $$t.CXXFLAGS := $$(CXXFLAGS) $$($$t.INCS)
    $$t.ldflags  := -L$(BUILD)lib $$(patsubst lib%.a,-l%,$$(filter %.a,$$(notdir $$($$t.deps)))) $$(ldflags)
    $$t.LDFLAGS  := $$(LDFLAGS)

    $$(foreach o,$$($$t.objs),\
        $$(eval $$o.cflags   := $$($$t.cflags)   $$($$t.CFLAGS))\
        $$(eval $$o.cxxflags := $$($$t.cxxflags) $$($$t.CXXFLAGS)))

    # Add an alias command so you can specify the name of the project as a make argument
    $$(notdir $$(basename $1)): $$t

    targets += $$t
    files   += $$t $$($$t.objs)
endef

define add.o
    $1.deps := $(1:$(BUILD)obj/%.o=%)
    $1.msg  := "\033[0;32m%-3s $$($1.deps)\033[0m\n" "$$(call compilerof,$1)"
    $1.cmd  := $$($$(call compilerof,$1)) $$($$(call flagsof,$1)) -MMD -MP -c -o $1 $$($1.deps)
endef

define add.a
    $$(foreach d,$$($1.deps),\
        $$(foreach o,$$($1.objs),\
            $$(eval $$o.cflags += $$($$d.CFLAGS))))

    $1.msg := "\033[1;32mAR  $$(notdir $1)\033[0m\n"
    $1.cmd := $(AR) crs $1 $$($1.objs)

    ifneq ($$(strip $$(filter %.a,$$($1.deps))),)
        $1.cmd += && mkdir -p $1.tmp\
                      && pushd $1.tmp > /dev/null\
                      $$(foreach a,$$(filter %.a,$$($1.deps)),\
                          && $(AR) xo $(CURDIR)/$$a)\
                      && popd > /dev/null\
                      && $(AR) crs $1 $1.tmp/*.o\
                      && rm -r $1.tmp
    endif
endef

define add
    $$(foreach d,$$($1.deps),\
        $$(eval $1.ldflags += $$($$d.LDFLAGS))\
        $$(foreach o,$$($1.objs),\
            $$(eval $$o.cflags += $$($$d.CFLAGS))))

    $1.msg := "\033[1;32mLD  $$(notdir $1)\033[0m\n"
    $1.cmd := $$($$(call compilerof,$$($1.deps))) -o $1 $$($1.objs) $$($1.ldflags) $$($1.LDFLAGS)
endef

ifneq ($(MAKECMDGOALS),clean)
    modules := $(patsubst ./%,%,$(shell find $(ROOT) -name '*.$(MKEXT)'))
    targets :=
    files   :=
endif

all: $$(targets)
.PHONY: all

clean:
> $(call print,"\033[1;33mRM  $(BUILD)\033[0m\n",rm -r $(BUILD))
.PHONY: clean

run-%: $(BUILD)bin/$$*
> $(call print,"\033[1;36mRUN $^\033[0m\n",./$^)
.PHONY: run-%

print-%:
> @printf "$* = $($*)\n"
.PHONY: print-%

ifneq ($(MAKECMDGOALS),clean)
    $(foreach m,$(modules),$(eval $(call add.mk,$m)))
    $(foreach f,$(files),$(eval $(call add$(suffix $f),$f)))
endif

$(files): $$($$@.deps)
> $(call print,,mkdir -p $(@D))
> $(call print,$($@.msg),$($@.cmd))

ifneq ($(MAKECMDGOALS),clean)
    -include $(shell find $(BUILD) -name '*.d' 2>/dev/null)
endif
