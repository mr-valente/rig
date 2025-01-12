function reload
    clear
    fish_greeting
    source $PROFILE
    # If a directory is passed, cd to it
    if test -d $argv[1]
        cd $argv[1]
    end
end

function exists
    type -q $argv[1]
end

# Pretty print PATH with each entry on a new line
function path
    for p in $PATH
        echo $p
    end
end