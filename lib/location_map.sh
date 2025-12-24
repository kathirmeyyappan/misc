generate_location_map() {
    local current_rel_path="$1"
    local tree_lines=()
    
    build_tree() {
        local dir="$1"
        local prefix="$2"
        
        local items=()
        while IFS= read -r -d '' item; do
            should_skip "$item" && continue
            items+=("$item")
        done < <(find "$dir" -maxdepth 1 -mindepth 1 -printf '%y %p\0' | sort -z | cut -z -d' ' -f2-)
        
        local count=${#items[@]}
        local i=0
        for item in "${items[@]}"; do
            local name=$(basename "$item")
            local connector="├──"
            local next_prefix="${prefix}│   "
            ((i == count - 1)) && { connector="└──"; next_prefix="${prefix}    "; }
            
            if [[ -d "$item" ]]; then
                local d_rel="${item#$SCRIPT_DIR/}"
                local marker=""
                [[ "$d_rel" == "$current_rel_path" ]] && marker="  📍 YOU ARE HERE"
                tree_lines+=("${prefix}${connector} 📁 ${name}${marker}")
                build_tree "$item" "$next_prefix"
            else
                tree_lines+=("${prefix}${connector} ${name}")
            fi
            ((i++))
        done
    }
    
    local root_marker=""
    [[ -z "$current_rel_path" ]] && root_marker="  📍 YOU ARE HERE"
    tree_lines+=("📁 misc${root_marker}")
    build_tree "$SCRIPT_DIR" ""
    
    local out="## Map:\n\n\`\`\`\n"
    for line in "${tree_lines[@]}"; do
        out+="${line}\n"
    done
    out+="\`\`\`\n\n"
    
    echo "$out"
}
