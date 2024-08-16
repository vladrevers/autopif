# autopif

**English** | [Українська](./README_UK.md) | [Русский](./README_RU.md)

Lightweight fork of [daboynb/playcurl](https://github.com/daboynb/PlayIntegrityNEXT/tree/main/playcurl) that performs a single task: Every 25 minutes, it downloads the [pifsync/pif.json](https://github.com/vladrevers/pifsync/blob/main/pif.json) file and compares your current `custom.pif.json` or `pif.json` file with the downloaded version. If your file differs or is missing, it replaces it, stops the GMS/Wallet services, and clears their cache. If the files are identical or an error occurs (e.g., no internet connection or failed to download the file), it does nothing in that iteration (attempt). It is intended to be used with (in my preference) the [osm0sis/PlayIntegrityFork](https://github.com/osm0sis/PlayIntegrityFork) module, or alternatively with [chiteroman/PlayIntegrityFix](https://github.com/chiteroman/PlayIntegrityFix).

The 25-minute interval can be changed, please see the [Preferences](#preferences) and [Notes](#notes) sections.

## Installation

1. If the [osm0sis/PlayIntegrityFork](https://github.com/osm0sis/PlayIntegrityFork/releases/latest) or [chiteroman/PlayIntegrityFix](https://github.com/chiteroman/PlayIntegrityFix/releases/latest) module is not installed yet, install it (no need to reboot your device yet, it will just be faster).

2. Install this [autopif](https://github.com/vladrevers/autopif/releases/latest) module.

3. Reboot your device. If you want to see the results immediately, ensure your internet connection is enabled **before** the reboot.

## Preferences

Within the installed autopif module directory (`/data/adb/modules/autopif`) or inside the module's ZIP file before installation, you can find or create the following files for customization:

- `minutes.txt` (contains only an integer value, specifying the interval in minutes for checking updates, default is 25)
- `pif_json_url.txt` (allows overriding the direct link for updating the PIF JSON file. Absent by default, and the default URL is used)
- `log_file_on` (if this file exists, a log will be written to `/storage/emulated/0/autopif_log.txt`. Present by default, remove this file if you don't need logging)
- `replace_log_file_on` (if this file exists, logs of PIF file content replacement (before/after) will be written to `/storage/emulated/0/autopif_replace_log.txt`. Not present by default, create this file if you need logging of content replacements)

## Manual Execution

You can perform a one-time check manually using the following command in a terminal:

```shell
cd /data/adb && ./magisk/busybox ash ./modules/autopif/service.sh -o
```

This command will run the script once, outputting the results to the console. It's useful for quick updating of the current PIF file and for debugging purposes.

## Notes

After installation, I recommend checking the `autopif_log.txt` file in your Internal Storage after 12-24 hours of habitual device usage. I've noticed that on my device, running Android 14, the script is paused by Magisk or Android itself when the screen is off for an extended period and no background tasks are running (e.g., music playback). The script resumes automatically when the screen is turned on. If you encounter a similar situation, it might make sense to decrease the check interval from 25 minutes to, for example, 20 minutes. However, 25 minutes should generally be sufficient. Conversely, if the script runs exactly on the set interval (e.g., on an older version of Android), you might want to increase the interval from 25 minutes to, for example, 45 minutes. Setting a very short interval, especially less than 10 minutes, is not highly recommended because the [pifsync/pif.json](https://github.com/vladrevers/pifsync/blob/main/pif.json) file on the server is updated once per hour. After monitoring, you can disable logging and delete the log file. For instructions on changing the check interval and disabling logging, see the [Preferences](#preferences) section.