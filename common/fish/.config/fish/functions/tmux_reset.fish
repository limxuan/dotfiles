function tmux_reset
    if not tmux has-session 2>/dev/null
        echo "No tmux session running."
        return 1
    end

    set -l folder_name (basename (pwd))
    set -l current_session (tmux display-message -p '#{session_name}')
    set -l temp_session "__old_session_tmp"

    # Rename current session to temp to free the desired name
    if test "$current_session" = "$folder_name"
        tmux rename-session -t "$current_session" "$temp_session"
        set current_session "$temp_session"
    end

    # Kill session if folder-named session already exists
    tmux has-session -t "$folder_name" 2>/dev/null
    and tmux kill-session -t "$folder_name"

    # Create new session and windows
    tmux new-session -d -s "$folder_name" "nvim ."
    
    # Ensure a second window is created (in case there are fewer than 2 windows)
    tmux new-window -t "$folder_name"

    # Rename windows to match expectations
    tmux rename-window -t "$folder_name:0" "nvim"
    tmux rename-window -t "$folder_name:1" "shell"

    # Switch to the new session
    tmux switch-client -t "$folder_name"
    sleep 0.2  # Give time to switch

    # Select the first window (0)
    tmux select-window -t "$folder_name:0"

    # Kill the old renamed session
    tmux kill-session -t "$current_session"

    echo "Tmux reset complete: now in session '$folder_name', focused on the first window."
end
