load_pif() {
    pif_json_url=$(get_config "pif_json_url" "https://raw.githubusercontent.com/vladrevers/pifsync/main/pif.json")

    log "Downloading remote PIF file from $pif_json_url"
    if ! wget --no-check-certificate -q -O "$remote_pif_file_path" "$pif_json_url"; then
        log "Failed to download remote PIF file"
        return 1
    fi
}
