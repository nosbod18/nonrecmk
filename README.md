# nonrecmk
A simple non recursive Makefile.

## Why
I wanted to try out the concept of non recursive make after reading the (in)famous paper [Recursive Make Considered Harmful](https://accu.org/journals/overload/14/71/miller_2004/). However, I believe the solution presented in that paper is cumbersome and tedious, especially the "makefile fragments", as the paper calls them.

With this project, I wanted the user experience to be intuitive and painless. The big goals I had were: make the project files as simple as possible, keep all the driver code in one Makefile, and make adding sub-projects simple. The first goal came at the expense of making the main Makefile much more compilicated, but I can live with that. I managed to squeeze out the other two goals as well, with the third one ending up being as easy as adding their names to a list.

## Usage
Create a project file named what you want the output file to be and give it the extension `.mk`. For example, a file named `main.mk` will produce a binary called `main`, and `libxyz.a.mk` will produce a library called `libxyz.a`. The Makefile uses the shell command `find` to find all files ending in `.mk`. If that conflicts with other files you already have, you can change the extension `find` looks for by changing the `MKEXT` variable either in the Makefile or on the command line. In this README I will just use `.mk` for simplicity.

### Minimal example
The absolute minimum required in a project file is a list of source files required to build the project.

```Makefile
# File: main.mk

srcs := src/a.c src/b.c # or src/*.c
```

This creates an executable called `main` from the source files src/a.c and src/b.c, where the src directory is relative to `main.mk`, not the Makefile. A more complicated example is given in the [example](https://www.github.com/nosbod18/nonrecmk/tree/main/example) directory.

### Variables
In a project file, there are a few predefined variables you can fill out. `srcs`, like in the minimal example, is one of them. These variables have the ability to propogate up through a projects dependencies, much like CMake's `PUBLIC` and `PRIVATE` specifiers. Since Make does not have specifiers like that, the convention I have chosen to go with is uppercase names representing public variables, and lowercase names representing private ones. For example, if you had a library with the public API headers in an `include` directory and private API headers in the `src` directory, you could write

```Makefile
# File: libxyz.a.mk

srcs := src/*.c
incs := src
INCS := include
```

Now whenever you reference this project as a dependency for another one, that project will automatically be able to access libxyz.a's include directory, but not its src directory, without having to specify it manually.

Another potentially more practical example is if you have a library that uses platform specific libraries, you can specify them in the library's project file and they will be correctly linked to any binaries that depend on the library, even though no linking happens when compiling the library.

The full list of predefined variables for a project file is

```Makefile
srcs     := # Project source files, supports wildcards, required
incs     := # Directories to use as include path for the compiler, supports wildcards
INCS     :=
deps     := # Subprojects this project depends on (i.e. the name of their .mk file without the .mk extension)
cflags   := # C compiler flags
CFLAGS   :=
cxxflags := # CXX compiler flags
CXXFLAGS :=
ldflags  := # Linker flags (don't worry about linking any library subprojects, that happens automatically)
LDFLAGS  :=
```

There are no public variables for `srcs` and `deps` because I don't think it makes sense to have them. If you can think of a situation where those would be necessary please let me know.

### Output
The build files are outputed to the directories `.build/$(OS)-$(ARCH)-$(MODE)/{bin,lib,obj}`, depending on the output file's extension, where `$(OS)`, `$(ARCH)`, and `$(MODE)` are defined as

```Makefile
OS   := $(if $(OS),Windows,$(subst Darwin,MacOS,$(shell uname -s))) # Windows, MacOS, Linux, ...
ARCH ?= $(shell uname -m) # x86_64, x86, ...
MODE ?= debug             # Debug mode by default
```

These are all overridable on the command line, so if you want to build a project with release flags instead of debug flags, you could write

```Makefile
ifeq ($(MODE),debug)
    cflags := -Wall -Wextra -g3 -O0
else ifeq ($(MODE),release)
    cflags := -Wall -O3
endif
```

in your project file, then type

```bash
$ make MODE=release
```

to compile with `-Wall -O3` instead of `-Wall -Wextra -g3 -O0`.

You can also tell make to build only certain subprojects by listing that projects name as an argument to make. For example, if I have a project called `app` and it depends on the libraries `libx.a`, `liby.a`, and `libz.a`, I can run

```bash
$ make libx.a
```

to only compile `libx.a`. This is useful if you have a large project and only want to check if a certain subproject will compile.
