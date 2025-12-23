#!/bin/bash

###############################################################################
# Configuration
###############################################################################

BASE_URL="https://kathirm.com/misc"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SKIP_PATTERNS=(
    "readme.md"
    ".git"
    ".gitignore"
    ".github"
    "generate_misc.sh"
    "lib"
)

###############################################################################
# Load Modules
###############################################################################

source "${SCRIPT_DIR}/lib/utils.sh"
source "${SCRIPT_DIR}/lib/location_map.sh"
source "${SCRIPT_DIR}/lib/menu_links.sh"

###############################################################################
# Menu Assembly
###############################################################################

generate_menu() {
    local dir="$1"
    local readme_file="$dir/README.md"
    
    cleanup_readme_variants "$dir"
    echo "Processing: $readme_file"
    
    local rel_path="${dir#$SCRIPT_DIR}"
    rel_path="${rel_path#/}"
    
    local menu=""
    menu+="$(generate_directory_listing "$dir" "$rel_path")"
    menu+="$(generate_location_map "$rel_path")"
    
    echo -e "$menu" > "$readme_file"
    echo "  ✓ Wrote menu to $readme_file"
}

###############################################################################
# Directory Traversal
###############################################################################

process_directory() {
    local dir="$1"
    generate_menu "$dir"
    
    for subdir in "$dir"/*/; do
        [[ -d "$subdir" ]] && ! should_skip "$subdir" && process_directory "${subdir%/}"
    done
}

###############################################################################
# Main
###############################################################################

main() {
    echo "=== Generating README menus ==="
    echo "Base URL: $BASE_URL"
    echo "Working directory: $SCRIPT_DIR"
    echo ""

    process_directory "$SCRIPT_DIR"

    echo ""
    echo "=== Done! ==="
}

main "$@"
