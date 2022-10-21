# nonrecmk
A simple non recursive Makefile.

## Why
I wanted to try out the concept of non recursive make after reading the (in)famous paper [Recursive Make Considered Harmful](https://accu.org/journals/overload/14/71/miller_2004/). However, I believe the solution presented in that paper is cumbersome and tedious, especially the "makefile fragments", as the paper calls them.

With this project, I wanted the user experience to be intuitive painless. The big goals I had were: make the project files as simple as possible, keep everything in one Makefile, and make adding sub-projects as easy as adding their names to a list. The first goal came at the expense of making the main Makefile much more compilicated, but I can live with that. I managed to squeeze out the other two goals as well, and even added in public and private style project variables.

## Usage
Create a project file named what you want the output file to be and give it the extension `.mk`. For example, a file named `main.mk` will produce a binary called `main`, and `libxyz.a.mk` will produce a library called `libxyz.a`. The Makefile uses the shell command `find` to find all files ending in `.mk`. If that conflicts with other files you already have, you can change the extension `find` looks for by changing the `MKEXT` variable either in the Makefile or on the command line. In this README I will just use `.mk` for simplicity.

### Minimal example
The absolute minimum required in a project file is a list of source files required to build the project.

```Makefile
# File: main.mk

sources := src/a.c src/b.c # or src/*.c
```

This creates an executable called `main` from the source files src/a.c and src/b.c, where the src directory is relative to the `main.mk` file, not the Makefile. More complicated examples are given in the [examples](https://www.github.com/nosbod18/nonrecmk/tree/main/examples) directory.

### Output
The build files are outputed to the directories `build/$(OS)-$(ARCH)-$(MODE)/{bin,lib,obj}`, depending on the output file's extension, where `$(OS)`, `$(ARCH)`, and `$(MODE)` are defined as

```Makefile
OS   ?= $(shell uname -s) # Darwin, Linux, or Windows_NT for Mac, Linux, and Windows respectively
ARCH ?= $(shell uname -m) # x86_64, x86, ...
MODE ?= debug             # Debug mode by default
```

These are all overridable on the command line, so if you want to build a project with release flags instead of debug flags, you could write

```Makefile
ifeq ($(MODE),debug)
    CFLAGS := -Wall -Wextra -g3 -O0
else ifeq ($(MODE),release)
    CFLAGS := -Wall -O3
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

### Variables
In a project file, there are a few predefined variables you can fill out. `sources`, like in the minimal example, is one of them. These variables have the ability to propogate up through a projects dependencies, much like CMake's `PUBLIC` and `PRIVATE` specifiers. Since Make does not have specifiers like that, the convention I have chosen to go with is uppercase names representing public variables, and lowercase names representing private ones. For example, if you had a library with the public API headers in an `include` directory and private API headers in the `src` directory, you could write

```Makefile
# File: libxyz.a.mk

sources  := src/*.c
includes := src
INCLUDES := include
```

Now whenever you reference this project as a dependency for another one, that project will automatically be able to access libxyz.a's include directory without having to specify it manually.

Another example that I find even more useful is if you have a library that uses platform specific libraries, you can specify them in the libraries project file and they will be correctly linked in the binary's project file, even though no linking happens when compiling the library at all. Check out a more in depth example in my [wtk](https://www.github.com/nosbod18/wtk) repo.

The full list of predefined variables in the project file is

```Makefile
sources   := # Project source files, supports wildcards, required
includes  := # Directories to use as include path for the compiler, supports wildcards
INCLUDES  :=
depends   := # Subprojects this project depends on (i.e. the name of their .mk file without the .mk extension)
cflags    := # C compiler flags
CFLAGS    :=
cxxflags  := # CXX compiler flags
CXXFLAGS  :=
ldflags   := # Linker flags (don't worry about linking any library subprojects, that happens automatically)
LDFLAGS   :=
```

There are no public variables for `sources` and `depends` because I don't think it makes sense to have them. If you can think of a situation where those would be necessary please let me know.