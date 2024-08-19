load_pif() {
    url_file="$MODPATH/pif_json_url.txt"
    default_url="https://raw.githubusercontent.com/vladrevers/pifsync/main/pif.json"
    if [ -f "$url_file" ] && [ -s "$url_file" ]; then
        pif_json_url=$(cat "$url_file")
    else
        pif_json_url="$default_url"
    fi

    log "Downloading remote PIF file from $pif_json_url."
    if wget --no-check-certificate -q -O "$remote_pif_file_path" "$pif_json_url"; then
        return 0
    else
        log "Failed to download remote PIF file."
        return 1
    fi
}
