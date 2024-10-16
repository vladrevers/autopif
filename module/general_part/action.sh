MODPATH="${0%/*}"

. "$MODPATH/service.sh" -o

# warn since Magisk's implementation automatically closes if successful
if [ "$KSU" != "true" -a "$APATCH" != "true" ]; then
    echo -e "\nClosing dialog in 7 seconds ..."
    sleep 7
fi
