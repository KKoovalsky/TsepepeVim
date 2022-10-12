# TsepepeVim plugin for Vim

This is a tiny C++ refactoring plugin which currently supports only function definition generation from a function 
declaration.

This plugin uses [Tsepepe](https://github.com/KKoovalsky/Tsepepe) toolset, which must be compiled along with the
bundled plugin to properly work. This is explained later in the [Installing section](#installing).

Small presentation:

![Tsepepe Function definition generator presentation](./doc/assets/tsepepe_gen_def_presentation.gif)

## Features

- Finds corresponding (paired) C++ file and appends the definition to it.
- Requires compilation database (yeah, not really a feature, but more a requirement).
- Takes into account all the specifiers, attributes, default parameters, namespaces, nested classes, nested types, etc.
Knows what to skip and what to keep.
- Uses libclang. May be slow in large codebases, but everything is lazy evaluated, so the only slowness you might
experience while explicitly invoking the plugin's commands.

## Requirements

System-wide:

* GCC 12.1.0+
* CMake 3.22
* `libclang-14-dev` and `libllvm-14-dev`

## Installing

With `vim-plug`, put that inside inside `.vimrc`:

```
Plug 'KKoovalsky/TsepepeVim', { 'do': './build.py' }
```

When installing other way, remember that the `Tsepepe` toolset must be built within the directory where the 
plugin is dropped:

```
cd to/the/plugins/dir
git submodule update --init --recursive
./build.py
```

## Documentation

See [doc/tsepepe.txt](doc/tsepepe.txt).

## Running tests

```
cd tests
behave compile_command_database_directory_path_getter/
```
