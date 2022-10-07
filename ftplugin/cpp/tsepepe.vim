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

if !exists(":TsepepeGenDef")
    command -buffer -nargs=0 TsepepeGenDef :call GenerateFunctionDefinitionInProperCppFile()
endif

if !exists("g:tsepepe_programs_dir")
    # This plugin dir is computed from the currently sourced file (<sfile>),
    # its full path (:p), but this file is located under 
    #    <plugin dir>/ftplugin/cpp/tsepepe.vim
    # thus we need to take the third parent dir (:h x 3)
    var this_plugin_dir = expand('<sfile>:p:h:h:h')
    # Assume Tsepepe is build inside the plugin dir.
    g:tsepepe_programs_dir = this_plugin_dir .. '/output/bin'
endif

if !exists("*s:GenerateFunctionDefinitionInProperCppFile")
    def GenerateFunctionDefinitionInProperCppFile()
        var definition_file = FindDefinitionFile()
        var definition = GenerateFunctionDefinition()
        AppendToWindow(definition_file, definition)
    enddef
endif

if !exists("*GenerateFunctionDefinition")
    # Generates function definition from a declaration found at line, where
    # the cursor is currently located.
    def GenerateFunctionDefinition(): string
        var dir_with_compile_db = getcwd()
        var current_file_abs_path = expand('%:p')
        var current_active_line = line('.')
        var generator = g:tsepepe_programs_dir
            .. '/tsepepe_function_definition_generator'
        var cmd = generator .. ' '
            .. dir_with_compile_db .. ' '
            .. current_file_abs_path .. ' '
            .. current_active_line
        var result = system(cmd)
        if v:shell_error != 0
            throw result
        endif
        return result
    enddef
endif

if !exists("*FindPairedCppFile")
    def FindPairedCppFile(): list<string>
        var project_root = getcwd()
        var current_file_abs_path = expand('%:p')
        var finder = g:tsepepe_programs_dir .. '/tsepepe_paired_cpp_file_finder'
        var cmd = finder .. ' ' .. project_root .. ' ' .. current_file_abs_path
        var result = systemlist(cmd)
        if v:shell_error != 0
            throw result[0]
        endif
        return result
    enddef
endif

if !exists("*FindDefinitionFile")
    def FindDefinitionFile(): string
        var current_file_abs_path = expand('%:p')
        var extension = expand('%:e')
        var source_file_extensions = ['cpp', 'cxx', 'cc']
        var definition_file = ''
        # If the current file is a source file ...
        if source_file_extensions->index(extension) >= 0
            definition_file = current_file_abs_path
        # If is header file ...
        else
            var paired_cpp_files = FindPairedCppFile()
            if paired_cpp_files->len() == 1
                definition_file = paired_cpp_files[0]
            else
                definition_file = QueryUser(
                    'Where to put the definition?', paired_cpp_files)
            endif
        endif
        return definition_file
    enddef
endif

if !exists("*QueryUser")
    def QueryUser(prompt: string, choices: list<string>): string
        var choices_adapted: list<string>
        var ordinal_num = 1
        for choice in choices
            choices_adapted->add("&" .. ordinal_num .. ". " .. choice .. "\n")
            ++ordinal_num
        endfor
        var actual_choice = confirm(prompt, choices_adapted->join(''))
        return choices->get(actual_choice - 1)
    enddef
endif

if !exists("*s:AppendToWindow")
    def AppendToWindow(file: string, text: string)
        # Open the definition file in another window, or go to already
        # existing window with that file open.
        execute('tab drop ' .. file)
        
        # Put the cursor at the end of file.
        execute('normal! G')
    
        # Put the text under the cursor.
        execute("normal! a\n\n" .. text .. "\n{\n}\<ESC>")
    enddef
endif
