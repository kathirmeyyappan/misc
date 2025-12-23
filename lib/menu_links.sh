generate_directory_listing() {
    local dir="$1"
    local rel_path="$2"
    local output=""
    
    local breadcrumb="misc"
    [[ -n "$rel_path" ]] && breadcrumb="misc/$rel_path"
    output+="# \`$breadcrumb\`\n\n"
    output+="## Contents:\n\n"
    
    if [[ -z "$rel_path" ]]; then
        output+="### [..](https://kathirm.com)\n\n"
    elif [[ "$(dirname "$rel_path")" == "." ]]; then
        output+="### [..]($BASE_URL/)\n\n"
    else
        local encoded_parent=$(percent_encode "$(dirname "$rel_path")")
        output+="### [..]($BASE_URL/$encoded_parent/)\n\n"
    fi
    
    local has_items=false

    while IFS= read -r -d '' item; do
        should_skip "$item" && continue
        if [[ -d "$item" ]]; then
            has_items=true
            local basename=$(basename "$item")
            local encoded_path=$(percent_encode "${item#$SCRIPT_DIR/}")
            output+="### 📁 [$basename]($BASE_URL/$encoded_path/)\n\n"
        fi
    done < <(find "$dir" -maxdepth 1 -mindepth 1 -print0 | sort -z)

    while IFS= read -r -d '' item; do
        should_skip "$item" && continue
        if [[ -f "$item" ]]; then
            has_items=true
            local basename=$(basename "$item")
            local encoded_path=$(percent_encode "${item#$SCRIPT_DIR/}")
            output+="### [$basename]($BASE_URL/$encoded_path)\n\n"
        fi
    done < <(find "$dir" -maxdepth 1 -mindepth 1 -print0 | sort -z)
    
    [[ "$has_items" == false ]] && output+="_No files in this directory._\n"
    
    echo "$output"
}

