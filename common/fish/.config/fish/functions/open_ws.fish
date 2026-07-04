function open_ws
    # Get current folder name
    set session_name (basename (pwd))

    # Check if session already exists
    if tmux has-session -t $session_name 2>/dev/null
        tmux attach-session -t $session_name
    else
        tmux new-session -s $session_name
    end
end
