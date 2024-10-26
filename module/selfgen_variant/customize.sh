new_module_dir="$MODPATH"
prev_module_dir=$(echo "$new_module_dir" | sed 's/modules_update/modules/')

# Check if the appropriate aapt binary exists, move it to the target location, set permissions, and clean up
[ -f "$MODPATH/tmp_aapt_binaries/${ARCH}_aapt" ] || abort "Current architecture ($(getprop ro.product.cpu.abi)) is not supported. Installation cannot proceed."
mv "$MODPATH/tmp_aapt_binaries/${ARCH}_aapt" "$MODPATH/aapt"
chmod +x "$MODPATH/aapt"
rm -rf "$MODPATH/tmp_aapt_binaries"

# Update config with value
update_config() {
    local key=$1
    local value=$2
    sed -i "s|^$key=.*|$key=$value|" "$new_module_dir/config.prop"
}

if echo "$new_module_dir" | grep -q "modules_update" && [ -d "$prev_module_dir" ]; then
    ui_print "Migration of the previous configuration:"
    if [ -f "$prev_module_dir/config.prop" ]; then
        # Migrate from config.prop
        while IFS='=' read -r key value; do
            [ -n "$key" ] && [ "${key#\#}" = "$key" ] && update_config "$key" "$value"
        done < "$prev_module_dir/config.prop"
    elif [ "$(grep '^versionCode=' "$prev_module_dir/module.prop" | cut -d'=' -f2)" -lt 1080 ]; then
        # Migrate from old file-based config
        [ -f "$prev_module_dir/minutes.txt" ] && update_config "update_interval_minutes" "$(cat "$prev_module_dir/minutes.txt")"
        [ ! -f "$prev_module_dir/log_file_on" ] && update_config "logging" "off"
        [ -f "$prev_module_dir/replace_log_file_on" ] && update_config "replace_logging" "on"
    fi
    ui_print "$(cat "$new_module_dir/config.prop")"
fi

if [ ! -f "$prev_module_dir/config.prop" ]; then
    if grep -q "testkey" "/system/etc/security/otacerts.zip" 2>/dev/null; then
        update_config "turn_spoof_signature" "on"
        ui_print "The default turn_spoof_signature is set to 'on' as your ROM likely uses a test signature."
    fi
fi