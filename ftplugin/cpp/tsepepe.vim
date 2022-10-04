vim9script noclear

# Vim C++ plugin (cpp filetype plugin) to provide some C++ refactoring features.
# Last Change:  2022 Oct 3
# Maintainer:   Kacper Kowalski <https://github.com/KKoovalsky>
# License:      This file is placed in the public domain.

# Only do this when not done yet for this buffer
if exists("b:did_ftplugin")
  finish
endif
b:did_ftplugin = 1

if !exists("g:tsepepe_def_gen_executable")
    g:tsepepe_def_gen_executable = "/home/kacper/Workspace/Tsepepe/build/function_definition_generator/tsepepe_definition_generator"
endif

if !exists(":TsepepeGenDef")
    command -buffer -nargs=0 TsepepeGenDef :call GenerateFunctionDefinition()
endif

if !exists("*GenerateFunctionDefinition")
    # This is local for this script, thus no unique prefix or suffix is
    # needed.
    def GenerateFunctionDefinition()
        var dir_with_compile_db = getcwd()
        var current_file_abs_path = expand('%:p')
        var current_active_line = line('.')
        var cmd = g:tsepepe_def_gen_executable .. ' '
            .. dir_with_compile_db .. ' '
            .. current_file_abs_path .. ' '
            .. current_active_line
        var generated_definition = system(cmd)
        echo generated_definition
    enddef
endif
