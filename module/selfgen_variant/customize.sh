new_module_dir="$MODPATH"

# Move the appropriate aapt binary to the target location and set permissions
if [ -f "$MODPATH/tmp_aapt_binaries/${ARCH}_aapt" ]; then
    mv "$MODPATH/tmp_aapt_binaries/${ARCH}_aapt" "$MODPATH/aapt"
    chmod +x "$MODPATH/aapt"
    rm -rf "$MODPATH/tmp_aapt_binaries"
else
    abort "Current architecture ($(getprop ro.product.cpu.abi)) is not supported. Installation cannot proceed."
fi

# Migrate configuration files if an older version exists
if echo "$new_module_dir" | grep -q "modules_update"; then
    old_module_dir=$(echo "$new_module_dir" | sed 's/modules_update/modules/')

    if [ -d "$old_module_dir" ]; then
        if [ -f "$old_module_dir/minutes.txt" ]; then
            cp -af "$old_module_dir/minutes.txt" "$new_module_dir/minutes.txt"
        fi

        if [ ! -f "$old_module_dir/log_file_on" ]; then
            rm -f "$new_module_dir/log_file_on"
        fi

        if [ -f "$old_module_dir/replace_log_file_on" ]; then
            touch "$new_module_dir/replace_log_file_on"
        fi
    fi
fi
