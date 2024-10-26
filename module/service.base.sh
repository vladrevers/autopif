MODPATH="${0%/*}"
PIF_MODULE_DIR="/data/adb/modules/playintegrityfix"
[ "$1" = "-o" ] && ONCE_MODE=1

get_config() {
    local value=$(grep "^$1=" "$MODPATH/config.prop" 2>/dev/null | cut -d'=' -f2-)
    printf '%s\n' "${value:-$2}"
}

log() {
    local log_file_path="/storage/emulated/0/autopif_log.txt"
    if [ $ONCE_MODE ]; then
        echo "$1"
    elif [ "$(get_config "logging" "on")" = "on" ] && touch "$log_file_path" 2>/dev/null; then
        echo "$(date "+%Y-%m-%d_%H:%M:%S"): $1" >> "$log_file_path"
    fi
}

replace_log() {
    local replace_log_file_path="/storage/emulated/0/autopif_replace_log.txt"
    if ! ([ "$(get_config "replace_logging" "off")" = "on" ] && touch "$replace_log_file_path" 2>/dev/null); then
        return
    fi

    {
        echo "$(date "+%Y-%m-%d_%H:%M:%S") $PIF_FILE_PATH"
        echo "Old:"
        cat "$PIF_FILE_PATH"
        echo -e "New:"
        cat "$remote_pif_file_path"
        echo -e "\n"
    } >> "$replace_log_file_path"
}

set_pif_json_path() {
    local chiteroman_path="/data/adb/pif.json"
    local osm0sis_path="$PIF_MODULE_DIR/custom.pif.json"
    local module_prop_path="$PIF_MODULE_DIR/module.prop"

    if [ -e "$osm0sis_path" ] || grep -q 'author=osm0sis' "$module_prop_path" 2>/dev/null; then
        PIF_FILE_PATH="$osm0sis_path"
    elif grep -q 'author=chiteroman' "$module_prop_path" 2>/dev/null || [ -e "$chiteroman_path" ]; then
        PIF_FILE_PATH="$chiteroman_path"
    else
        PIF_FILE_PATH="$chiteroman_path"
        log "No specific PIF file or author found, using default path"
    fi

    log "Path to PIF file: $PIF_FILE_PATH"
}

check_pif_module_installed() {
    if ! [ -d "$PIF_MODULE_DIR" ]; then
        log "You need to install Play Integrity Fix (or Fork) module!"
        log "Script is terminating due to the missing module"
        exit 1
    fi
    set_pif_json_path
}

check_network_reachable() {
    local max_attempts=8
    local success_pinged_series=0

    for attempt_count in $(seq 1 $max_attempts); do
        if /system/bin/ping -c1 -W3 "connectivitycheck.gstatic.com" > /dev/null 2>&1; then
            success_pinged_series=$((success_pinged_series + 1))
            [ $success_pinged_series -ge 3 ] && log "Network is reachable" && return 0
        else
            success_pinged_series=0
        fi

        [ $attempt_count -ge 6 ] && [ $success_pinged_series -eq 0 ] && break
        sleep 0.5
    done

    log "Network is not reachable"
    return 1
}

# LOAD_PIF_FUNCTION_PLACEHOLDER

update_pif_if_needed() {
    remote_pif_file_path="/data/adb/remote_pif.json"

    load_pif || return 1

    migrate_script_path="$PIF_MODULE_DIR/migrate.sh"
    if [ -f "$migrate_script_path" ]; then
        is_osm0sis=1
        log "Running existing migrate.sh to adapt remote PIF"
        sh "$migrate_script_path" "$remote_pif_file_path" "$remote_pif_file_path" > /dev/null 2>&1
        rm "${remote_pif_file_path}.bak" 2>/dev/null
    fi

    if [ "$(get_config "turn_spoof_signature" "off")" = "on" ]; then
        if grep -q "spoofSignature" "$remote_pif_file_path"; then
            sed -i 's/"spoofSignature":\s*"0"/"spoofSignature": "1"/g; s/"spoofSignature":\s*false/"spoofSignature": true/g' "$remote_pif_file_path"
        elif [ "$is_osm0sis" ]; then
            sed -i ':a;N;$!ba;s/\n}/,\n\n  \/\/ Advanced Settings\n    "spoofSignature": "1"\n}/' "$remote_pif_file_path"
        else
            sed -i ':a;N;$!ba;s/\n}/,\n  "spoofSignature": true\n}/' "$remote_pif_file_path"
        fi
        log "spoofSignature added and enabled in PIF"
    fi

    if diff -q "$remote_pif_file_path" "$PIF_FILE_PATH" > /dev/null 2>&1; then
        log "The current and remote PIF are the same"
    else
        log "Replacing PIF with remote version"
        replace_log
        cat "$remote_pif_file_path" > "$PIF_FILE_PATH"
        stop_dg_and_wallet
    fi

    rm "$remote_pif_file_path"
}

stop_dg_and_wallet() {
    processes="com.google.android.gms.unstable com.google.android.apps.walletnfcrel"
    for process in $processes; do
        pkill -f "$process" > /dev/null 2>&1
        log "Stopped process: $process"
    done
}

# Check for once start mode
if [ $ONCE_MODE ]; then
    check_pif_module_installed

    log "Start a once check"
    check_status="is skipped"
    if check_network_reachable; then
        update_pif_if_needed && check_status="completed"
    fi
    log "Once check ${check_status}"

    return 0
fi

# Wait for system to boot
check_boot_interval=3
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep $check_boot_interval
done

# Wait for storage decryption, with timeout of 180 seconds
i=0
until [ -d "/storage/emulated/0/Android" ] || [ "$i" -ge 180 ]; do
    sleep $check_boot_interval
    i=$((i + check_boot_interval))
done

check_pif_module_installed

sleep 10 # Wait for the network connection after reboot

# Get check interval from config with validation
default_interval=25
time_interval=$(get_config "update_interval_minutes" $default_interval)
if ! [ "$time_interval" -gt 0 ] 2>/dev/null; then
    time_interval=$default_interval
fi

log "Script started. Checking network and PIF every $time_interval minutes"

# Main loop: Check PIF file for updates by time_interval
while true; do
    log "" # Separator in log
    log "Start new check"
    check_status="is skipped"
    if check_network_reachable; then
        update_pif_if_needed && check_status="completed"
    fi
    log "Check ${check_status}. Next check: $(date -d "@$(($(date +%s) + ($time_interval * 60)))" "+%Y-%m-%d_%H:%M:%S")"
    sleep "${time_interval}m"
done
