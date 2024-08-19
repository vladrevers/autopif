load_pif() {
    log "Getting remote PIF file using get_pif_json.sh script."

    new_pif_json=$(. "$MODPATH/get_pif_json.sh")
    if [ $? -eq 0 ]; then
        echo "$new_pif_json" > "$remote_pif_file_path"
        return 0
    else
        log "Failed to get remote PIF file."
        return 1
    fi
}
