function zazen --description "Daily system update: paru + daemon-reload + restart updated AUR services"
    # Run paru full system update with vifm as file manager
    paru -Syu --fm vifm
    or return 1

    # Detect which AUR packages were upgraded in the last 2 minutes
    set -l cutoff (date -d '2 minutes ago' '+%s')
    set -l aur_pkgs (paru -Qm | awk '{print $1}')
    set -l upgraded

    # Parse pacman.log for AUR packages upgraded after the cutoff
    while read -l line
        set -l ts (string match -r '^\[([^\]]+)\]' -- $line)[2]
        set -l pkg (string match -r 'upgraded (\S+) ' -- $line)[2]

        set -l log_epoch (date -d "$ts" '+%s' 2>/dev/null)
        or continue

        if test "$log_epoch" -ge "$cutoff"; and contains -- $pkg $aur_pkgs
            if not contains -- $pkg $upgraded
                set -a upgraded $pkg
            end
        end
    end < (grep '\[ALPM\] upgraded' /var/log/pacman.log | psub)

    if test (count $upgraded) -eq 0
        echo "No AUR packages were updated."
        return 0
    end

    echo ""
    set_color -o cyan
    echo "Updated AUR packages: $upgraded"
    set_color normal

    # Daemon reload to pick up any changed unit files
    echo "Running systemctl daemon-reload..."
    sudo systemctl daemon-reload

    # Restart services for each updated AUR package
    # Uses pacman -Ql to find actual .service files owned by the package
    for pkg in $upgraded
        set -l services (pacman -Ql "$pkg" 2>/dev/null \
            | grep '/usr/lib/systemd/system/.*\.service$' \
            | awk '{print $2}' \
            | xargs -I{} basename {})

        if test (count $services) -eq 0
            echo "No service unit found for $pkg, skipping restart."
            continue
        end

        for unit in $services
            echo "Restarting $unit..."
            sudo systemctl restart "$unit"
        end
    end

    echo ""
    set_color -o green
    echo "Zendo is at peace. ✓"
    set_color normal
end


