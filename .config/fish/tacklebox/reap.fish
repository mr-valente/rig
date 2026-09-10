# Sourced automatically from config.fish along with the rest of tacklebox.
#
# Reaps orphaned Tailscale SSH session trees.  When a Tailscale SSH client
# disconnects, tailscaled tears down its own helper but leaves the login shell
# alive, reparented to init and blocked forever on a pty whose master fd
# tailscaled never closes.  The shell therefore never receives SIGHUP.  These
# accumulate at a few per day, holding memory, logind sessions and ptys.
#
# `reap` finds those trees and hangs them up by hand.  It is deliberately
# manual -- run it when you want to, it is never scheduled.
#
# Note: reaping frees memory and closes the logind sessions, but it CANNOT
# reclaim the ptys.  Those stay allocated until tailscaled closes the master
# fds it leaked, which only a daemon restart will do.  `reap --ptys` reports
# the discrepancy.

function __reap_error
    printf 'reap: %s\n' "$argv" >&2
end

# The login shell to treat as a session root.  Override by setting
# $reap_shell in config.fish if you ever change shells.
function __reap_shell
    if set -q reap_shell; and test -n "$reap_shell"
        echo $reap_shell
    else
        builtin path basename (status fish-path)
    end
end

# Emit $pid and every ancestor up to init, so we never reap ourselves.
function __reap_ancestry --argument-names pid
    set -l p $pid
    while test -n "$p"; and test "$p" != 1
        echo $p
        set p (ps -o ppid= -p $p 2>/dev/null | string trim)
    end
end

function __reap_descendants --argument-names pid
    for child in (pgrep -P $pid 2>/dev/null)
        echo $child
        __reap_descendants $child
    end
end

# A login shell whose parent is init is, on this machine, always a Tailscale
# SSH session that failed to tear down: live ones are children of tailscaled.
function __reap_orphans
    ps -eo ppid,user,comm,pid --no-headers 2>/dev/null |
        awk -v u=$USER -v s=(__reap_shell) '$1==1 && $2==u && $3==s {print $4}'
end

function __reap_tree_rss --argument-names pid
    ps -o rss= -p $argv 2>/dev/null | awk '{s+=$1} END {printf "%.1f", s/1024}'
end

function __reap_pty_report
    set -l allocated (cat /proc/sys/kernel/pty/nr 2>/dev/null)
    set -l sessions (loginctl list-sessions --no-legend 2>/dev/null | count)
    printf 'ptys allocated: %s   logind sessions: %s\n' $allocated $sessions
    if test (math "$allocated - $sessions") -gt 8
        printf '  %s ptys are held by leaked tailscaled fds; only\n' (math "$allocated - $sessions")
        printf '  `sudo systemctl restart tailscaled` reclaims them.\n'
    end
end

function reap --description 'Reap orphaned Tailscale SSH session trees'
    argparse h/help n/dry-run q/quiet p/ptys -- $argv
    or return 1

    if set -q _flag_help
        printf 'usage: reap [-n|--dry-run] [-q|--quiet] [-p|--ptys]\n\n'
        printf '  -n, --dry-run  show what would be reaped, kill nothing\n'
        printf '  -q, --quiet    only print the summary line\n'
        printf '  -p, --ptys     report pty vs session counts and exit\n'
        return 0
    end

    if set -q _flag_ptys
        __reap_pty_report
        return 0
    end

    set -l protected (__reap_ancestry $fish_pid)
    set -l targets
    set -l trees 0

    for shell in (__reap_orphans)
        set -l tree $shell (__reap_descendants $shell)
        # Never touch a tree containing this very session.
        if contains -- $shell $protected
            continue
        end
        set -l mine no
        for p in $tree
            if contains -- $p $protected
                set mine yes
                break
            end
        end
        test $mine = yes; and continue

        set trees (math $trees + 1)
        set -a targets $tree

        if not set -q _flag_quiet
            set -l tty (ps -o tty= -p $shell 2>/dev/null | string trim)
            set -l kids (ps -o comm= -p $tree 2>/dev/null | tail -n +2 | string join ',')
            printf '  %-8s %-8s %8s MB  %s\n' $shell $tty (__reap_tree_rss $tree) $kids
        end
    end

    if test $trees -eq 0
        set -q _flag_quiet; or echo 'reap: nothing orphaned'
        return 0
    end

    set -l freed (__reap_tree_rss $targets)

    if set -q _flag_dry_run
        printf 'reap: would reap %d trees (%d pids, %s MB)\n' $trees (count $targets) $freed
        return 0
    end

    # SIGHUP is the signal these shells should have received when their client
    # went away; escalate only for processes that ignore it.
    kill -HUP $targets 2>/dev/null

    sleep 2
    set -l alive
    for p in $targets
        kill -0 $p 2>/dev/null; and set -a alive $p
    end
    if test (count $alive) -gt 0
        kill -TERM $alive 2>/dev/null
        sleep 2
        set -l stubborn
        for p in $alive
            kill -0 $p 2>/dev/null; and set -a stubborn $p
        end
        test (count $stubborn) -gt 0; and kill -KILL $stubborn 2>/dev/null
    end

    printf 'reap: %d trees, %d pids, %s MB freed\n' $trees (count $targets) $freed
    set -q _flag_quiet; or __reap_pty_report
end
