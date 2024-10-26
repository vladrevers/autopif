load_pif() {
    log "Getting remote PIF file using get_pif_json.sh script."

    local new_pif_json=$(. "$MODPATH/get_pif_json.sh")
    if [ $? -ne 0 ]; then
        log "Failed to get remote PIF file."
        return 1
    fi

    echo "$new_pif_json" > "$remote_pif_file_path"
}
