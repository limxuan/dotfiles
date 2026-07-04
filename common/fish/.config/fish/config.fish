alias ls="eza -l -g --icons"
alias lst="eza -g --icons --tree --level=2 -a"
alias t="tmux"
alias tks="tmux kill-server"
alias trs=tmux_reset
alias db="nvim -c \"DBUI\""

set fish_greeting

# Environment Variables
set -g -x NODE_ENV "development"
set -gx EDITOR nvim
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx SSH_AUTH_SOCK "/home/$USER/.var/app/com.bitwarden.desktop/data/.bitwarden-ssh-agent.sock"
set -Ux JAVA_HOME /usr/lib/jvm/java-25-openjdk

# Custom Key Bindings
bind \cn open_nvim
bind \co open_lazygit
bind \cg edit_command 
bind \cs check_tmux
bind \ce edit_clipboard
bind \ct open_ws

# Tool Initializations
zoxide init fish | source
starship init fish | source
mise activate fish | source

# opencode
fish_add_path /home/limxuan/.opencode/bin

# Local binaries path (works for both /home/limxuan and /home/lx)
if test -d "$HOME/.local/bin"
    fish_add_path "$HOME/.local/bin"
end
