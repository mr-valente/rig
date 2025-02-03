if exists starship 
    and test "$TERM" = xterm-256color
    starship init fish | source
end