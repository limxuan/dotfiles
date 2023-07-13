alias g="git"
alias c="clear"
alias v="nvim"
alias ll="exa --icons"
alias llt="exa -g --icons --tree --level=2 -a"
alias sql="sqlite3"
alias vs="fd --hidden --exclude .git | fzf-tmux -p | xargs nvim"
alias lookatme="/Users/limxuan/Library/Python/3.10/bin/lookatme"
set fish_greeting

starship init fish | source

# Setting PATH for Python 3.10
# The original version is saved in /Users/limxuan/.config/fish/config.fish.pysave
set -x PATH "/Library/Frameworks/Python.framework/Versions/3.10/bin" "$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

set -g -x NODE_ENV "development"
