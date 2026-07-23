# Aliases
alias ls="eza -l -g --icons"
alias lst="eza -g --icons --tree --level=2 -a"
alias t="tmux"
alias tks="tmux kill-server"
alias trs=tmux_reset

# Tool init
eval "$(zoxide init bash)"
eval "$(starship init bash)"

# PATH
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"

# Ctrl+G: edit current command line in nvim (no auto-execute)
__edit_command_line() {
    echo "$READLINE_LINE" > /tmp/bash_cmd_edit
    nvim /tmp/bash_cmd_edit
    READLINE_LINE=$(cat /tmp/bash_cmd_edit)
    READLINE_POINT=${#READLINE_LINE}
}
bind -x '"\C-g": __edit_command_line'

# Ctrl+S: attach or create tmux session
__check_tmux() {
    if tmux ls &>/dev/null; then
        tmux attach
    else
        tmux
    fi
}
bind -x '"\C-s": __check_tmux'

# Tmux session by folder name
open_ws() {
    local session_name
    session_name=$(basename "$(pwd)")
    if tmux has-session -t "$session_name" 2>/dev/null; then
        tmux attach-session -t "$session_name"
    else
        tmux new-session -s "$session_name"
    fi
}

# Reset tmux session with nvim + shell windows
tmux_reset() {
    if ! tmux has-session 2>/dev/null; then
        echo "No tmux session running."
        return 1
    fi

    local folder_name current_session temp_session
    folder_name=$(basename "$(pwd)")
    current_session=$(tmux display-message -p '#{session_name}')
    temp_session="__old_session_tmp"

    if [[ "$current_session" == "$folder_name" ]]; then
        tmux rename-session -t "$current_session" "$temp_session"
        current_session="$temp_session"
    fi

    tmux has-session -t "$folder_name" 2>/dev/null && tmux kill-session -t "$folder_name"

    tmux new-session -d -s "$folder_name" "nvim ."
    tmux new-window -t "$folder_name"
    tmux rename-window -t "$folder_name:0" "nvim"
    tmux rename-window -t "$folder_name:1" "shell"
    tmux switch-client -t "$folder_name"
    sleep 0.2
    tmux select-window -t "$folder_name:0"
    tmux kill-session -t "$current_session"

    echo "Tmux reset complete: now in session '$folder_name', focused on the first window."
}
