new_module_dir="$MODPATH"

if echo "$new_module_dir" | grep -q "modules_update"; then
    old_module_dir=$(echo "$new_module_dir" | sed 's/modules_update/modules/')

    if [ -d "$old_module_dir" ]; then
        if [ -f "$old_module_dir/minutes.txt" ]; then
            cp -af "$old_module_dir/minutes.txt" "$new_module_dir/minutes.txt"
        fi

        if [ -f "$old_module_dir/pif_json_url.txt" ]; then
            cp -af "$old_module_dir/pif_json_url.txt" "$new_module_dir/pif_json_url.txt"
        fi

        if [ ! -f "$old_module_dir/log_file_on" ]; then
            rm -f "$new_module_dir/log_file_on"
        fi

        if [ -f "$old_module_dir/replace_log_file_on" ]; then
            touch "$new_module_dir/replace_log_file_on"
        fi
    fi
fi
