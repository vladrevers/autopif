MODPATH="${0%/*}"

TMP_DIR="$MODPATH/tmp"
mkdir -p "$TMP_DIR"

LAST_LINK_FILE="$TMP_DIR/last_link.txt"
LAST_JSON_FILE="$TMP_DIR/last_output.json"
APK_FILE="$TMP_DIR/latest.apk"

RSS_URL="https://sourceforge.net/projects/xiaomi-eu-multilang-miui-roms/rss?path=/xiaomi.eu/Xiaomi.eu-app"

# Function to fetch the second link from the RSS feed
fetch_rss_link() {
    wget --no-check-certificate -qO- "$RSS_URL" | awk -v RS='<item>' '/<link>/ {gsub(/.*<link>|<\/link>.*/, ""); link=$0} NR==2 {print link; exit}'
}

# Extract a value from the APK's aapt output
get_value() {
    echo "$aapt_output" | grep -A2 "^[ ]*A: name=\"$1\"" | grep "value=" | sed 's/.*value="\([^"]*\)".*/\1/' | head -n1
}

# Extract a part of the fingerprint using the provided index
extract_fingerprint_part() {
    fingerprint="$(get_value FINGERPRINT)"
    part_value=$(echo "${fingerprint}" | awk -F'[:/]' -v i="$1" '{print $i}')
    echo "${part_value:-null}"
}

valid_aapt_output() {
    if [ -z "$(get_value FINGERPRINT)" ]; then
        echo "Failed to get FINGERPRINT value"
        rm -rf "$TMP_DIR"/*
        exit 1
    fi
}

create_json_file() {
    aapt_output="$($MODPATH/aapt dump xmltree "$APK_FILE" "res/xml/inject_fields.xml")"
    valid_aapt_output
    cat <<EOF >"$LAST_JSON_FILE"
{
  "BRAND": "$(get_value BRAND)",
  "DEVICE": "$(get_value DEVICE)",
  "FINGERPRINT": "$(get_value FINGERPRINT)",
  "ID": "$(extract_fingerprint_part 5)",
  "MANUFACTURER": "$(get_value MANUFACTURER)",
  "MODEL": "$(get_value MODEL)",
  "PRODUCT": "$(get_value PRODUCT)",
  "DEVICE_INITIAL_SDK_INT": "25",
  "SECURITY_PATCH": "$(get_value SECURITY_PATCH)"
}
EOF

    sed -i '/"null"/d' "$LAST_JSON_FILE"
}


# Fetch the latest link from the RSS feed
REMOTE_LAST_LINK=$(fetch_rss_link)
if [ $? -ne 0 ] || [ -z "$REMOTE_LAST_LINK" ]; then
    echo "Failed to fetch RSS feed or no valid link found"
    exit 1
fi

# If the link hasn't changed, return the last saved JSON result
if [ "$REMOTE_LAST_LINK" = "$(cat "$LAST_LINK_FILE" 2>/dev/null)" ]; then
    if [ -s "$LAST_JSON_FILE" ]; then
        cat "$LAST_JSON_FILE"
        exit 0
    fi
fi

# Download the APK file
wget --no-check-certificate -qO "$APK_FILE" "$REMOTE_LAST_LINK"
if [ $? -ne 0 ] || [ ! -s "$APK_FILE" ]; then
    echo "Failed to download APK or APK is empty"
    exit 1
fi

create_json_file

# Clean up
rm -f "$APK_FILE"

# Save the latest link for future checks
echo "$REMOTE_LAST_LINK" > "$LAST_LINK_FILE"

# Output the JSON file content
cat "$LAST_JSON_FILE"
