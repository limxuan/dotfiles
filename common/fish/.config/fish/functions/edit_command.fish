function edit_command
    # Define a specific temporary file path
    set temp_file /tmp/fish_vim_commandline.fish

    # Capture the current command line content
    commandline > $temp_file

    # Open the temporary file in Vim for editing
    nvim $temp_file

    # Read the modified command from the file
    set new_command (cat $temp_file)

    # Replace the current command line content with the modified command
    commandline --replace -- $new_command
end
