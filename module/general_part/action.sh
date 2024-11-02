MODPATH="${0%/*}"

. "$MODPATH/service.sh" -o

if [ "$APATCH" != "true" ]; then
    echo -e "\nClosing window in 7 seconds..."
    sleep 7
fi
