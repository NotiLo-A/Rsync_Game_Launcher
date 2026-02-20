ui_info()    { printf "\e[34m[INFO]\e[0m %s\n" "$1"; }
ui_warn()    { printf "\e[33m[WARN]\e[0m %s\n" "$1"; }
ui_error()   { printf "\e[31m[ERROR]\e[0m %s\n" "$1"; }
ui_success() { printf "\e[32m[OK]\e[0m %s\n" "$1"; }

ui_box() {
    local text="$1"
    local padding=2
    local width=$(( ${#text} + padding * 2 ))

    local border
    border=$(printf '═%.0s' $(seq 1 "$width"))

    printf "\n╔%s╗\n" "$border"
    printf "║%*s%s%*s║\n" "$padding" "" "$text" "$padding" ""
    printf "╚%s╝\n\n" "$border"
}

ui_box_multiline() {
    local content="$1"

    local max=0
    while IFS= read -r line; do
        [ ${#line} -gt "$max" ] && max=${#line}
    done <<< "$content"

    local padding=2
    local width=$(( max + padding * 2 ))
    local border
    border=$(printf '═%.0s' $(seq 1 "$width"))

    printf "\n╔%s╗\n" "$border"

    while IFS= read -r line; do
        printf "║%*s%-*s%*s║\n" \
            "$padding" "" \
            "$max" "$line" \
            "$padding" ""
    done <<< "$content"

    printf "╚%s╝\n\n" "$border"
}

ui_exit() {
    read -r -p "Press Enter to exit..."
}

ui_pause() {
    read -r -p "Press Enter to сontinue..."
}


ui_print() {
    printf "%s\n" "$1" ""
}
