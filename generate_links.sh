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
    local readme_file=""
    
    # Find README.md (case insensitive)
    for f in "$dir"/README.md "$dir"/README.MD "$dir"/readme.md; do
        if [[ -f "$f" ]]; then
            readme_file="$f"
            break
        fi
    done
    
    if [[ -z "$readme_file" ]]; then
        echo "No README.md found in $dir, skipping..."
        return
    fi
    
    echo "Processing: $readme_file"
    
    # Calculate relative path from SCRIPT_DIR
    local rel_path="${dir#$SCRIPT_DIR}"
    rel_path="${rel_path#/}"  # Remove leading slash if present
    
    # Build the menu
    local menu="# Contents\n\n"
    local has_items=false
    
    # List all files and directories, excluding README and gitignored files
    while IFS= read -r -d '' item; do
        local basename=$(basename "$item")
        
        # Skip README files
        if [[ "${basename,,}" == "readme.md" ]]; then
            continue
        fi
        
        # Skip files matched by .gitignore (if git is available)
        if command -v git &> /dev/null && git -C "$SCRIPT_DIR" check-ignore -q "$item" 2>/dev/null; then
            continue
        fi
        
        has_items=true
        
        # Build the full path for the URL (percent-encoded for GitHub Pages)
        local item_rel_path="${item#$SCRIPT_DIR/}"
        local encoded_path=$(percent_encode "$item_rel_path")
        
        if [[ -d "$item" ]]; then
            # It's a directory - link to it with a folder indicator
            menu+="## 📁 [$basename]($BASE_URL/$encoded_path/)\n\n"
        else
            # It's a file
            menu+="## [$basename]($BASE_URL/$encoded_path)\n\n"
        fi
    done < <(find "$dir" -maxdepth 1 -mindepth 1 -print0 | sort -z)
    
    if [[ "$has_items" == false ]]; then
        menu+="_No files in this directory._\n"
    fi
    
    # Read existing README content
    local existing_content=$(cat "$readme_file")
    
    # Check if there's already a Contents section
    if echo "$existing_content" | grep -q "^# Contents"; then
        # Replace existing Contents section (everything from ## Contents to next ## or end)
        # Using awk for multi-line replacement
        local new_content=$(echo "$existing_content" | awk -v menu="$menu" '
            BEGIN { in_contents = 0; printed_menu = 0 }
            /^# Contents/ { 
                in_contents = 1
                printf "%s", menu
                printed_menu = 1
                next
            }
            /^#/ && in_contents { 
                in_contents = 0
                print
                next
            }
            !in_contents { print }
        ')
        echo -e "$new_content" > "$readme_file"
    else
        # Append Contents section to the end
        echo -e "\n$menu" >> "$readme_file"
    fi
    
    echo "  ✓ Updated menu in $readme_file"
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

