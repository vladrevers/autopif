MODPATH="${0%/*}"
PIF_FILE_PATH=""

log() {
    log_file_path="/storage/emulated/0/autopif_log.txt"
    if [ -f "$MODPATH/log_file_on" ] && touch "$log_file_path" 2>/dev/null; then
        echo "$(date "+%Y-%m-%d_%H:%M:%S"): $1" >> "$log_file_path"
    fi

    if [ -f "$MODPATH/log_console_on" ]; then
        echo "$1"
    fi
}

set_pif_file_path() {
    chiteroman_pif_file_path="/data/adb/pif.json"
    osm0sis_pif_file_path="/data/adb/modules/playintegrityfix/custom.pif.json"
    module_prop_path="/data/adb/modules/playintegrityfix/module.prop"

    if grep -q 'author=osm0sis' "$module_prop_path" 2>/dev/null; then
        PIF_FILE_PATH="$osm0sis_pif_file_path"
    elif grep -q 'author=chiteroman' "$module_prop_path" 2>/dev/null; then
        PIF_FILE_PATH="$chiteroman_pif_file_path"
    elif [ -e "$osm0sis_pif_file_path" ]; then
        PIF_FILE_PATH="$osm0sis_pif_file_path"
    elif [ -e "$chiteroman_pif_file_path" ]; then
        PIF_FILE_PATH="$chiteroman_pif_file_path"
    else
        PIF_FILE_PATH="$chiteroman_pif_file_path"
        log "No specific PIF file or author found, using default path."
    fi

    log "Path to PIF file: $PIF_FILE_PATH"
}

check_network_reachable() {
    max_attempts=8
    success_pinged_series=0

    for attempt_count in $(seq 1 $max_attempts); do
        if /system/bin/ping -c1 -W3 "connectivitycheck.gstatic.com" > /dev/null 2>&1; then
            success_pinged_series=$((success_pinged_series + 1))
            if [ $success_pinged_series -ge 3 ]; then
                log "Network is reachable."
                return 0
            fi
        else
            success_pinged_series=0
        fi

        if [ $attempt_count -ge 6 ] && [ $success_pinged_series -eq 0 ]; then
            break # Early exit after 6 attempts with 0 successes
        fi

        sleep 0.5
    done

    log "Network is not reachable."
    return 1
}

update_pif_if_needed() {
    remote_pif_file_path="/data/adb/remote_pif.json"
    log "Downloading remote PIF file."

    if ! wget --no-check-certificate -q -O "$remote_pif_file_path" "https://raw.githubusercontent.com/daboynb/autojson/main/pif.json"; then
        log "Failed to download remote PIF file."
        return 1
    fi

    if grep -q '"FINGERPRINT": "null"' "$remote_pif_file_path" 2>/dev/null; then
        log "Remote PIF file is bad, skip replace local PIF."
        return 0
    fi

    example_pif_file_path="/data/adb/modules/playintegrityfix/example.pif.json"
    if [ -e "$example_pif_file_path" ]; then
        rm "$example_pif_file_path"
        log "Delete example.pif.json"
    fi

    if diff "$remote_pif_file_path" "$PIF_FILE_PATH" > /dev/null 2>&1; then
        log "The current and remote PIF are the same."
    else
        log "Replacing PIF with remote version."
        cat "$remote_pif_file_path" > "$PIF_FILE_PATH"
        handle_gms
    fi

    rm "$remote_pif_file_path"
}

handle_gms() {
    processes="com.google.android.gms com.google.android.gms.unstable com.google.android.apps.walletnfcrel"

    for process in $processes; do
        pkill -f "$process" > /dev/null 2>&1
        log "Stopped process: $process"
    done

    gms_cache_path="/data/data/com.google.android.gms/cache"
    walletnfcrel_cache_path="/data/data/com.google.android.apps.walletnfcrel/cache"

    if [ -d "$gms_cache_path" ] && [ "$(ls -A "$gms_cache_path")" ]; then
        rm -r "$gms_cache_path"/* 2>/dev/null
        log "Cleared cache: $gms_cache_path"
    fi

    if [ -d "$walletnfcrel_cache_path" ] && [ "$(ls -A "$walletnfcrel_cache_path")" ]; then
        rm -r "$walletnfcrel_cache_path"/* 2>/dev/null
        log "Cleared cache: $walletnfcrel_cache_path"
    fi
}

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

if ! [ -d "/data/adb/modules/playintegrityfix" ]; then
    log "You need to install Play Integrity Fix (or Fork) module!"
    log "Script is terminating due to the missing module"
    exit 1
fi

sleep 10 # Wait for the network connection after reboot

# Get check interval from file with validation
time_interval=$(cat "$MODPATH/minutes.txt" 2>/dev/null)
if ! [ "$time_interval" -gt 0 ] 2>/dev/null; then
    time_interval=25
fi

log "Script started. Checking network and PIF every $time_interval minutes."

set_pif_file_path

# Main loop: Check PIF file for updates by time_interval
while true; do
    log "" # Separator in log
    log "Start new check."
    check_status="skipped"
    if check_network_reachable; then
        update_pif_if_needed && check_status="completed"
    fi
    log "Check ${check_status}. Next check: $(date -d "@$(($(date +%s) + ($time_interval * 60)))" "+%Y-%m-%d_%H:%M:%S")"
    sleep "${time_interval}m"
done
