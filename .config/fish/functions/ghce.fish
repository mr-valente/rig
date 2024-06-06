function ghce
    set -l GH_DEBUG "$GH_DEBUG"
    set -l GH_HOST "$GH_HOST"

    set -l __USAGE "
    Wrapper around \`gh copilot explain\` to explain a given input command in natural language.

    USAGE
      ghce [flags] <command>

    FLAGS
      -d, --debug      Enable debugging
      -h, --help       Display help usage
          --hostname   The GitHub host to use for authentication

    EXAMPLES

    # View disk usage, sorted by size
    $ ghce 'du -sh | sort -h'

    # View git repository history as text graphical representation
    $ ghce 'git log --oneline --graph --decorate --all'

    # Remove binary objects larger than 50 megabytes from git history
    $ ghce 'bfg --strip-blobs-bigger-than 50M'
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
        end
    end

    set -e argv_copy[1..(math (count $argv) - (count $argv_copy))]

    GH_DEBUG="$GH_DEBUG" GH_HOST="$GH_HOST" gh copilot explain $argv_copy
end