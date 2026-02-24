if exists $HOME/.pyenv/bin/pyenv
    set -l PYENV_ROOT $HOME/.pyenv
    fish_add_path $PYENV_ROOT/bin
    # pyenv init - | source
    # pyenv init --path | source
end