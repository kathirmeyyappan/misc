percent_encode() {
    local string="$1"
    local encoded=""
    local i char
    for (( i=0; i<${#string}; i++ )); do
        char="${string:i:1}"
        case "$char" in
            [a-zA-Z0-9.~_/-]) encoded+="$char" ;;
            *) printf -v hex '%%%02X' "'$char"
               encoded+="$hex" ;;
        esac
    done
    echo "$encoded"
}

should_skip() {
    local basename=$(basename "$1")
    local pattern
    for pattern in "${SKIP_PATTERNS[@]}"; do
        [[ "${basename,,}" == "$pattern" ]] && return 0
    done
    return 1
}

cleanup_readme_variants() {
    local dir="$1"
    local readme_file="$dir/README.md"
    for f in "$dir"/README.MD "$dir"/readme.MD "$dir"/Readme.md; do
        if [[ -f "$f" ]] && [[ "$f" != "$readme_file" ]]; then
            rm "$f"
            echo "  Removed $f (using lowercase README.md)"
        fi
    done
}

