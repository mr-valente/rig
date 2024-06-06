function ghcs
    set TARGET "shell"
    set -l GH_DEBUG "$GH_DEBUG"
    set -l GH_HOST "$GH_HOST"

    set -l __USAGE "
    Wrapper around \`gh copilot suggest\` to suggest a command based on a natural language description of the desired output effort.
    Supports executing suggested commands if applicable.

    USAGE
      ghcs [flags] <prompt>

    FLAGS
      -d, --debug              Enable debugging
      -h, --help               Display help usage
          --hostname           The GitHub host to use for authentication
      -t, --target target      Target for suggestion; must be shell, gh, git
                               default: \"$TARGET\"

    EXAMPLES

    - Guided experience
      $ ghcs

    - Git use cases
      $ ghcs -t git \"Undo the most recent local commits\"
      $ ghcs -t git \"Clean up local branches\"
      $ ghcs -t git \"Setup LFS for images\"

    - Working with the GitHub CLI in the terminal
      $ ghcs -t gh \"Create pull request\"
      $ ghcs -t gh \"List pull requests waiting for my review\"
      $ ghcs -t gh \"Summarize work I have done in issues and pull requests for promotion\"

    - General use cases
      $ ghcs \"Kill processes holding onto deleted files\"
      $ ghcs \"Test whether there are SSL/TLS issues with github.com\"
      $ ghcs \"Convert SVG to PNG and resize\"
      $ ghcs \"Convert MOV to animated PNG\"
    "

    set -l argv_copy $argv
    for i in (seq (count $argv))
        switch $argv[$i]
            case -d --debug
                set GH_DEBUG "api"
            case -h --help
                echo "$__USAGE"
                return 0
            case --hostname
                set GH_HOST $argv[$i+1]
                set -e argv_copy[$i]
                set -e argv_copy[$i+1]
            case -t --target
                set TARGET $argv[$i+1]
                set -e argv_copy[$i]
                set -e argv_copy[$i+1]
        end
    end

    set -e argv_copy[1..(math (count $argv) - (count $argv_copy))]

    set TMPFILE (mktemp -t gh-copilotXXXXXX)
    function cleanup --on-event fish_exit
        rm -f $TMPFILE
    end

    if GH_DEBUG="$GH_DEBUG" GH_HOST="$GH_HOST" gh copilot suggest -t "$TARGET" $argv_copy --shell-out $TMPFILE
        if test -s $TMPFILE
            set FIXED_CMD (cat $TMPFILE)
            history delete --exact -- $argv_copy[1]
            history delete --exact -- $FIXED_CMD
            history merge
            echo
            eval "$FIXED_CMD"
        end
    else
        return 1
    end
end
