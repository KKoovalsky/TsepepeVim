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
    command -buffer -nargs=0 -range TsepepeGenDef :call GenerateFunctionDefinitionssInProperCppFile(<line1>, <line2>)
endif

if !exists(":TsepepeImplIface")
    command -buffer -nargs=1 TsepepeImplIface :call ImplementInterface(<f-args>)
endif

if !exists(":TsepepeGoToCorrespondingFile")
    command -buffer -nargs=0 TsepepeGoToCorrespondingFile :call GoToCorrespondingFile()
endif

if !has("python3")
    throw "ERROR: no python3 support! Enable +python3 feature to allow this plugin to work."
endif

if !exists("g:tsepepe_plugin_dir")
    # This plugin dir is computed from the currently sourced file (<sfile>),
    # its full path (:p), but this file is located under 
    #    <plugin dir>/ftplugin/cpp/tsepepe.vim
    # thus we need to take the third parent dir (:h x 3)
    g:tsepepe_plugin_dir = expand('<sfile>:p:h:h:h')
endif

if !exists("g:tsepepe_python3_utils_loaded")

    # Let's load the python3 helpers for this plugin globally, once for all.

    py3 << trim EOF
    import os
    import sys
    import vim

    plugin_path = vim.eval("g:tsepepe_plugin_dir")
    module_path = os.path.join(plugin_path, 'python3')
    sys.path.append(module_path)
    from pytsepepevim import comp_db_dir_getter
    EOF

    g:tsepepe_python3_utils_loaded = true
endif

if !exists("g:tsepepe_programs_dir")
    # Assume Tsepepe is build inside the plugin dir.
    g:tsepepe_programs_dir = g:tsepepe_plugin_dir .. '/output/bin'
endif

if !exists("*s:GenerateFunctionDefinitionssInProperCppFile")
    def GenerateFunctionDefinitionssInProperCppFile(
            line_begin: number, line_end: number)
        var definition_file = FindDefinitionFile()
        var definitions = GenerateFunctionDefinitions(line_begin, line_end)
        AppendToWindow(definition_file, definitions)
    enddef
endif

if !exists("*s:ImplementInterface")
    # Extends the class under cursor by implementing the interface with the 
    # specified name.
    def ImplementInterface(interface_name: string)
        var new_file_content = GetFileContentAfterImplementingInterface(
            interface_name)
        ReplaceActiveBufferContent(new_file_content)
    enddef
endif

if !exists("*s:GoToCorrespondingFile")
    # Activates window with the corresponding source file. For a header file 
    # it will ba a source file, and for a source file it will be a header
    # file. The corresponding file is a paired C++ file, which has the same
    # stem.
    def GoToCorrespondingFile()
        var corresponding_file = ''
        var paired_cpp_files = FindPairedCppFile()
        if paired_cpp_files->len() == 1
            corresponding_file = paired_cpp_files[0]
        else
            corresponding_file = QueryUserForProjectFile(
                'Found multiple paired files. Which one to switch to?', 
                paired_cpp_files)
        endif
        ActivateFile(corresponding_file)
    enddef
endif

if !exists("*GenerateFunctionDefinitions")
    # Generates function definition from a declaration found at line, where
    # the cursor is currently located.
    def GenerateFunctionDefinitions(
            line_begin: number, line_end: number): string
        var dir_with_compile_db = FindCompilationDatabaseDirectory()
        var current_file_abs_path = expand('%:p')
        var current_buffer_content = join(getline(1, '$'), "\n")
        var generator = g:tsepepe_programs_dir
            .. '/tsepepe_function_definition_generator'
        return RunShellCommandAndGetStdout("GenerateFunctionDefinitions", 
            [generator,
             dir_with_compile_db,
             current_file_abs_path,
             current_buffer_content,
             line_begin,
             line_end
            ]
         )
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
                definition_file = QueryUserForProjectFile(
                    'Where to put the definition?', paired_cpp_files)
            endif
        endif
        return definition_file
    enddef
endif

if !exists("*s:QueryUserForProjectFile")
    def QueryUserForProjectFile(prompt: string, choices: list<string>): string
        var choices_adapted: list<string>
        var ordinal_num = 1
        var root_dir = getcwd()
        var root_dir_match = '^' .. root_dir
        var root_dir_str_len = strlen(root_dir)
        for choice in choices
            var choice_to_print = ''
            if choice =~ root_dir_match
                choice_to_print = slice(choice, root_dir_str_len)
                if choice_to_print[0] == '/'
                    choice_to_print = slice(choice_to_print, 1)
                endif
            else
                choice_to_print = choice
            endif
            choices_adapted->add("&" .. ordinal_num .. ". " .. choice_to_print)
            ++ordinal_num
        endfor
        var actual_choice = confirm(prompt, choices_adapted->join("\n"))
        return choices->get(actual_choice - 1)
    enddef
endif

if !exists("*s:AppendToWindow")
    def AppendToWindow(file: string, text: string)
        ActivateFile(file)

        # Put the cursor at the end of file.
        execute('normal! G$')
    
        # Put the text under the cursor.
        execute("normal! a\n\n" .. text .. "\<ESC>")
    enddef
endif

if !exists("*FindCompilationDatabaseDirectory")
    def FindCompilationDatabaseDirectory(): string
        var project_root = getcwd()
        var current_file_abs_path = expand('%:p')
        var py3code = 'comp_db_dir_getter.get_compile_db_dir('
            .. '"' .. project_root .. '",'
            .. '"' .. current_file_abs_path .. '")'
        return py3eval(py3code)
    enddef
endif

if !exists("*GetFileContentAfterImplementingInterface")
    def GetFileContentAfterImplementingInterface(interface_name: string): string
        var dir_with_compile_db = FindCompilationDatabaseDirectory()
        var project_root = getcwd()
        var current_file_abs_path = expand('%:p')
        var current_buffer_content = join(getline(1, '$'), "\n")
        var active_line = line('.')

        var implementor_maker = g:tsepepe_programs_dir 
            .. '/tsepepe_implementor_maker'
        var cmd = implementor_maker .. ' '
            .. dir_with_compile_db .. ' '
            .. project_root .. ' '
            .. current_file_abs_path .. ' '
            .. shellescape(current_buffer_content) .. ' '
            .. interface_name .. ' '
            .. active_line

        var result = system(cmd)
        if v:shell_error != 0
            throw result
        endif

        return result
    enddef
endif


if !exists("*ReplaceActiveBufferContent")
    def ReplaceActiveBufferContent(new_buffer_content: string)
        # Save the cursor for later.
        var save_cursor = getcurpos()

        # Delete all the lines from the active buffer (make the buffer empty).
        deletebufline('%', 1, '$')

        # Set the buffer content with the new lines.
        setline(1, split(new_buffer_content, '\n'))

        # Restore the cursor
        setpos('.', save_cursor)
    enddef
endif

if !exists("*s:ActivateFile")
    # Open the definition file in another window, or go to already
    # existing window with that file open.
    def ActivateFile(file: string)
        execute('tab drop ' .. file)
    enddef
endif

if !exists("*s:RunShellCommandAndGetStdout")
    def RunShellCommandAndGetStdout(id_: string, cmd: list<any>): string
        var stdout: list<string>
        var stderr: list<string>

        def on_stdout(ch: channel, msg: string)
            add(stdout, msg)
        enddef
        def on_stderr(ch: channel, msg: string)
            add(stderr, msg)
        enddef

        var job = job_start(cmd, {out_cb: on_stdout, err_cb: on_stderr})
        var status = "run"
        while status == "run"
            status = job_status(job)
            sleep 1m
        endwhile

        if status == "fail"
            throw "Command: " .. id_ .. " failed to run!"
        endif

        var result_code = job_info(job)['exitval']
        if result_code != 0
            throw "Command: " .. id_ .. 
                  " failed with return code: " .. result_code .. 
                  " and stderr:\n" .. join(stderr, "\n")
        endif
 
        if !empty(stderr)
            echom "Command: " .. id_ " didn't fail, but stderr is not empty:\n" .. join(stderr, "\n")
        endif
        return join(stdout, "\n")
    enddef
endif

