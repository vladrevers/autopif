load_pif() {
    log "Getting remote PIF file using get_pif_json.sh script"

    new_pif_json=$(. "$MODPATH/get_pif_json.sh" 2>&1) || {
        log "Failed to get PIF json: $new_pif_json"
        return 1
    }

    echo "$new_pif_json" > "$remote_pif_file_path"
}
