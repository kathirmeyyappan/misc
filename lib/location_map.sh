generate_location_map() {
    local current_rel_path="$1"
    local tree_lines=()
    
    build_tree() {
        local dir="$1"
        local prefix="$2"
        
        local dirs=()
        while IFS= read -r -d '' d; do
            should_skip "$d" && continue
            dirs+=("$d")
        done < <(find "$dir" -maxdepth 1 -mindepth 1 -type d -print0 | sort -z)
        
        local count=${#dirs[@]}
        local i=0
        for d in "${dirs[@]}"; do
            local name=$(basename "$d")
            local d_rel="${d#$SCRIPT_DIR/}"
            local marker=""
            [[ "$d_rel" == "$current_rel_path" ]] && marker="  📍 YOU ARE HERE"
            
            local connector="├──"
            local next_prefix="${prefix}│   "
            ((i == count - 1)) && { connector="└──"; next_prefix="${prefix}    "; }
            
            tree_lines+=("${prefix}${connector} ${name}${marker}")
            build_tree "$d" "$next_prefix"
            ((i++))
        done
    }
    
    local root_marker=""
    [[ -z "$current_rel_path" ]] && root_marker="  📍 YOU ARE HERE"
    tree_lines+=("misc${root_marker}")
    build_tree "$SCRIPT_DIR" ""
    
    local out="## Map\n\n\`\`\`\n"
    for line in "${tree_lines[@]}"; do
        out+="${line}\n"
    done
    out+="\`\`\`\n\n"
    
    echo "$out"
}
