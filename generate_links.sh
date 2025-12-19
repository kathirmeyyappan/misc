#!/bin/bash

# Base URL for all assets
BASE_URL="https://kathirm.com/misc"

# Get the absolute path of the misc directory (script's location)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Percent-encode special characters for GitHub Pages URLs
percent_encode() {
    local string="$1"
    local encoded=""
    local i char
    for (( i=0; i<${#string}; i++ )); do
        char="${string:i:1}"
        case "$char" in
            [a-zA-Z0-9.~_/-]) encoded+="$char" ;;  # Safe chars (including / for paths)
            *) printf -v hex '%%%02X' "'$char"
               encoded+="$hex" ;;
        esac
    done
    echo "$encoded"
}

# Generate menu for a directory
generate_menu() {
    local dir="$1"
    local readme_file="$dir/README.md"
    
    # Remove any case variants (GitHub Pages needs lowercase .md)
    for f in "$dir"/README.MD "$dir"/readme.MD "$dir"/Readme.md; do
        if [[ -f "$f" ]] && [[ "$f" != "$readme_file" ]]; then
            rm "$f"
            echo "  Removed $f (using lowercase README.md)"
        fi
    done
    
    echo "Processing: $readme_file"
    
    # Calculate relative path from SCRIPT_DIR
    local rel_path="${dir#$SCRIPT_DIR}"
    rel_path="${rel_path#/}"  # Remove leading slash if present
    
    # Build the menu with breadcrumb title
    local breadcrumb
    if [[ -z "$rel_path" ]]; then
        breadcrumb="misc"
    else
        breadcrumb="misc/$rel_path"
    fi
    local menu="# \`$breadcrumb\` contents\n\n"
    
    # Add parent directory link
    if [[ -z "$rel_path" ]]; then
        # Top level - link to main site
        menu+="### [..](https://kathirm.com)\n\n"
    else
        # Nested directory - link to parent
        local parent_path=$(dirname "$rel_path")
        if [[ "$parent_path" == "." ]]; then
            menu+="### [..]($BASE_URL/)\n\n"
        else
            local encoded_parent=$(percent_encode "$parent_path")
            menu+="### [..]($BASE_URL/$encoded_parent/)\n\n"
        fi
    fi
    
    local has_items=false
    
    # Helper function to check if item should be skipped
    should_skip() {
        local item="$1"
        local basename=$(basename "$item")
        
        # Skip README files, .git, .gitignore, and the script itself
        if [[ "${basename,,}" == "readme.md" ]] || \
           [[ "$basename" == ".git" ]] || \
           [[ "$basename" == ".gitignore" ]] || \
           [[ "$basename" == ".github" ]] || \
           [[ "$basename" == "generate_links.sh" ]]; then
            return 0
        fi
        
        return 1
    }
    
    # First pass: directories
    while IFS= read -r -d '' item; do
        if should_skip "$item"; then continue; fi
        if [[ -d "$item" ]]; then
            has_items=true
            local basename=$(basename "$item")
            local item_rel_path="${item#$SCRIPT_DIR/}"
            local encoded_path=$(percent_encode "$item_rel_path")
            menu+="### 📁 [$basename]($BASE_URL/$encoded_path/)\n\n"
        fi
    done < <(find "$dir" -maxdepth 1 -mindepth 1 -print0 | sort -z)
    
    # Second pass: files
    while IFS= read -r -d '' item; do
        if should_skip "$item"; then continue; fi
        if [[ -f "$item" ]]; then
            has_items=true
            local basename=$(basename "$item")
            local item_rel_path="${item#$SCRIPT_DIR/}"
            local encoded_path=$(percent_encode "$item_rel_path")
            menu+="### [$basename]($BASE_URL/$encoded_path)\n\n"
        fi
    done < <(find "$dir" -maxdepth 1 -mindepth 1 -print0 | sort -z)
    
    if [[ "$has_items" == false ]]; then
        menu+="_No files in this directory._\n"
    fi
    
    # Overwrite the README with the new menu
    echo -e "$menu" > "$readme_file"
    
    echo "  ✓ Wrote menu to $readme_file"
}

# Recursively process directories
process_directory() {
    local dir="$1"
    
    # Generate menu for current directory
    generate_menu "$dir"
    
    # Process subdirectories
    for subdir in "$dir"/*/; do
        if [[ -d "$subdir" ]]; then
            process_directory "${subdir%/}"
        fi
    done
}

# Main execution
echo "=== Generating README menus ==="
echo "Base URL: $BASE_URL"
echo "Working directory: $SCRIPT_DIR"
echo ""

process_directory "$SCRIPT_DIR"

echo ""
echo "=== Done! ==="

