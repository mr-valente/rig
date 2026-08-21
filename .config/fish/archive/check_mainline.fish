function check_mainline --description "Check if Arch mainline kernel is 7.0+"
    # Fetch the version
    set -l current_mainline (curl -s "https://archlinux.org/packages/search/json/?name=linux" | jq -r ".results[0].pkgver")
    
    # Check if version is 7.0 or higher
    # Regex explanation:
    # ^           = Start of string
    # ([7-9]|     = Major versions 7, 8, 9
    # [1-9][0-9]) = Major versions 10+
    # \.          = Literal dot before minor version
    if string match -qr "^([7-9]|[1-9][0-9])\." -- $current_mainline
        set_color -o green
        echo ""
        echo "🚨 ALERT: Linux mainline has updated to $current_mainline!"
        echo ""
        set_color normal
    end
end