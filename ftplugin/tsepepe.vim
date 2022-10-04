vim9script noclear

# Vim C++ plugin (cpp filetype plugin) to provide some C++ refactoring features.
# Last Change:  2022 Oct 3
# Maintainer:   Kacper Kowalski <https://github.com/KKoovalsky>
# License:      This file is placed in the public domain.

if exists("g:tsepepe_loaded")
    finish
endif
g:tsepepe_loaded = 1

# Only do this when not done yet for this buffer
if exists("b:did_ftplugin")
  finish
endif
b:did_ftplugin = 1

if !exists(":TsepepeGenDef")
    command -buffer -nargs=0 TsepepeGenDef :call GenerateFunctionDefinition()
endif

if !exists("*GenerateFunctionDefinition")
    def GenerateFunctionDefinition()
        echo "YOLO!"
    enddef
endif
