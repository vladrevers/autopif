MODPATH="${0%/*}"

TMP_DIR="$MODPATH/tmp"
mkdir -p "$TMP_DIR"

LAST_LINK_FILE="$TMP_DIR/last_link.txt"
LAST_JSON_FILE="$TMP_DIR/last_output.json"
APK_FILE="$TMP_DIR/latest.apk"

RSS_URL="https://sourceforge.net/projects/xiaomi-eu-multilang-miui-roms/rss?path=/xiaomi.eu/Xiaomi.eu-app"

# Function to fetch the second link from the RSS feed
fetch_rss_link() {
    wget -qO- "$RSS_URL" | awk -v RS='<item>' '/<link>/ {gsub(/.*<link>|<\/link>.*/, ""); link=$0} NR==2 {print link; exit}'
}

# Extract a value from the APK's aapt output
get_value() {
    echo "$aapt_output" | grep -A2 "name=\"$1\"" | grep "value=" | sed 's/.*value="\([^"]*\)".*/\1/' | head -n1
}

# Extract a part of the fingerprint using the provided index
extract_fingerprint_part() {
    fingerprint="$(get_value FINGERPRINT)"
    part_value=$(echo "${fingerprint}" | awk -F'[:/]' -v i="$1" '{print $i}')
    echo "${part_value:-null}"
}

create_json() {
    aapt_output="$($MODPATH/aapt dump xmltree "$APK_FILE" "res/xml/inject_fields.xml")"
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
  "SECURITY_PATCH": "$(get_value SECURITY_PATCH)",
  "spoofProvider": true,
  "spoofProps": true,
  "spoofSignature": false
}
EOF

    # Remove lines containing "null"
    sed -i '/"null"/d' "$LAST_JSON_FILE"
}

# Initialize or read the last saved link
if [ -f "$LAST_LINK_FILE" ]; then
    LOCAL_LAST_LINK=$(cat "$LAST_LINK_FILE")
else
    LOCAL_LAST_LINK=""
fi

# Fetch the latest link from the RSS feed
REMOTE_LAST_LINK=$(fetch_rss_link)

# Check if RSS link fetch was successful
if [ $? -ne 0 ]; then
    echo "Failed to fetch RSS feed. Using the last known link if available."
    REMOTE_LAST_LINK=$LOCAL_LAST_LINK
fi

# If the link is still empty, exit with error
if [ -z "$REMOTE_LAST_LINK" ]; then
    echo "No valid link found. Exiting with error."
    exit 1
fi

# If the link hasn't changed, return the last saved JSON result
if [ "$REMOTE_LAST_LINK" = "$LOCAL_LAST_LINK" ]; then
    if [ -f "$LAST_JSON_FILE" ]; then
        cat "$LAST_JSON_FILE"
        exit 0
    fi
fi

# Download the APK file
wget -qO "$APK_FILE" "$REMOTE_LAST_LINK"

# Check if APK download was successful
if [ $? -ne 0 ]; then
    echo "Failed to download APK. Returning the last available JSON if exists."
    if [ -f "$LAST_JSON_FILE" ]; then
        cat "$LAST_JSON_FILE"
        exit 0
    else
        echo "No JSON file available. Exiting with error."
        exit 1
    fi
fi

# Create the JSON file
create_json

# Clean up
rm -f "$APK_FILE"

# Save the latest link for future checks
echo "$REMOTE_LAST_LINK" > "$LAST_LINK_FILE"

# Output the JSON file content
cat "$LAST_JSON_FILE"
