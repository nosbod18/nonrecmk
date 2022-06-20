# nonrecmk

A simple non recursive Makefile.

## Usage
Create a `project.mk` file in your project tree that has the following contents.

```Makefile
TARGET  := mytarget
SOURCES := src/a.c src/b.c # or src/*.c
```

This creates an executable called mytarget from the source files src/a.c and src/b.c.
All paths inside a `project.mk` file are relative to that file. The build files are
outputed to the directory `build/$(OS)-$(ARCH)-$(MODE)`, where `$(OS)`, `$(ARCH)`, and `$(MODE)`
are defined as

```Makefile
OS   ?= $(shell uname -s) # Darwin, Linux, or Windows_NT for Mac, Linux, and Windows respectively
ARCH ?= $(shell uname -m) # x86_64, x86, ...
MODE ?= debug             # Debug mode by default
```

These are all overridable on the command line, so if you want to build a project with release
flags instead of debug flags, you could write

```Makefile
ifeq ($(MODE),debug)
    CFLAGS := -Wall -Wextra -g3 -O0
else ifeq ($(MODE),release)
    CFLAGS := -Wall -O3
endif
```

in your `project.mk`, then type

```bash
$ make MODE=release
```

to compile with `-Wall -O3` instead of `-Wall -Wextra -g3 -O0`.

The full list of supported variables in the `project.mk` files is

```Makefile
TARGET   := # Name of project, required
SOURCES  := # Project source files, supports wildcards, required
INCLUDE  := # Directories to use as include path for compiler (-I...), supports wildcards
DEPENDS  := # Subprojects this project depends on (automatically links any libraries)
CFLAGS   := # C compiler flags
CXXFLAGS := # C++ compiler flags
LDFLAGS  := # Linker flags
```

## TODO
Add complete example