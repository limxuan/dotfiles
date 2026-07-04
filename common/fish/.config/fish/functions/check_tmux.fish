function check_tmux
    if tmux ls &> /dev/null
        tmux attach
    else
        tmux
    end
end
