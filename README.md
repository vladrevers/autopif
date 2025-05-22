# autopif

**English** | [Українська](./README_UK.md) | [Русский](./README_RU.md)

Lightweight fork of [daboynb/playcurl](https://github.com/daboynb/PlayIntegrityNEXT/tree/main/playcurl) that performs a single task: Every 25 minutes, it obtains* the pif.json file and compares your current `custom.pif.json` or `pif.json` file with the obtained version. If your file differs or is missing, it replaces it and stops the DroidGuard and Google Wallet services. If the files are identical or an error occurs (e.g., no internet connection or failed to obtain the file), it does nothing in that iteration (attempt). It is intended to be used with (in my preference) the [osm0sis/PlayIntegrityFork](https://github.com/osm0sis/PlayIntegrityFork) module, or alternatively with [chiteroman/PlayIntegrityFix](https://github.com/chiteroman/PlayIntegrityFix).

<details>
<summary>* About obtaining pif.json</summary>

There are two variants of this module:

**Fetch variant**:  
Downloads the file from [pifsync/pif.json](https://github.com/vladrevers/pifsync/blob/main/pif.json).
- **Plus**: Uses less network data and is lighter.
- **Minus**: New pif.json might be available with a slight delay (approximately 10± minutes).

**Selfgen variant**:  
Generates the file on the device by downloading and extracting information from the latest [XiaomiEUModule.apk](https://sourceforge.net/projects/xiaomi-eu-multilang-miui-roms/files/xiaomi.eu/Xiaomi.eu-app/) from xiaomi.eu.
- **Plus**: The new pif.json is available without delay.
- **Minus**: Uses slightly more network data and requires the aapt binary library, increasing the installed module size by 1.4MB.
- **Optimization**: Caches the last pif.json and apk link, so downloading and extracting information from the apk only occurs when necessary (upon update).
</details>

The 25-minute interval can be changed, please see the [Preferences](#preferences) and [Notes](#notes) sections.

## Installation

1. If the [osm0sis/PlayIntegrityFork](https://github.com/osm0sis/PlayIntegrityFork/releases/latest) or [chiteroman/PlayIntegrityFix](https://github.com/chiteroman/PlayIntegrityFix/releases/latest) module is not installed yet, install it (no need to reboot your device yet, it will just be faster).
2. Install this [autopif](https://github.com/vladrevers/autopif/releases/latest) module.
3. Reboot your device. If you want to see the results immediately, ensure your internet connection is enabled **before** the reboot.

## Preferences

Within the installed autopif module directory (`/data/adb/modules/autopif`), you can find and edit `config.prop` file with the following settings:

- `update_interval_minutes` - interval in minutes for checking updates (default: 25)
- `pif_json_url` - direct link for updating the PIF JSON file (default: https://raw.githubusercontent.com/vladrevers/pifsync/main/pif.json)
- `logging` - enable/disable logging to `/storage/emulated/0/autopif_log.txt` (default: on)
- `replace_logging` - enable/disable logging of PIF file content replacement (before/after) to `/storage/emulated/0/autopif_replace_log.txt` (default: off)
- `turn_spoof_signature` - enable/disable adding the signature spoofing parameter in the PIF file (default: off, except when your ROM signature is test-keys)
- `turn_spoof_vendingSDK` - enable/disable adding the vendingSDK spoofing parameter in the PIF file (default: on for Android 13+ and off for older versions). May cause issues with Play Store, see details in [release notes](https://github.com/vladrevers/autopif/releases/tag/v1.9)

## Manual Execution

You can perform a one-time check in two ways:
1. On Magisk v28+:
   - Open Magisk app → Modules
   - Click "Action" button next to autopif
2. Using terminal command:
```shell
cd /data/adb && ./magisk/busybox ash -o standalone ./modules/autopif/service.sh -o
```

Both methods will run the script once, outputting the results to the console. It's useful for quick updating of the current PIF file and for debugging purposes.

## Notes

After installation, I recommend checking the `autopif_log.txt` file in your Internal Storage after 12-24 hours of habitual device usage. I've noticed that on my device, running Android 14, the script is paused by Magisk or Android itself when the screen is off for an extended period and no background tasks are running (e.g., music playback). The script resumes automatically when the screen is turned on. If you encounter a similar situation, it might make sense to decrease the check interval from 25 minutes to, for example, 20 minutes. However, 25 minutes should generally be sufficient. Conversely, if the script runs exactly on the set interval (e.g., on an older version of Android), you might want to increase the interval from 25 minutes to, for example, 45 minutes. Setting a very short interval, especially less than 5 minutes, is not highly recommended. After monitoring, you can disable logging and delete the log file. For instructions on changing the check interval and disabling logging, see the [Preferences](#preferences) section.

**Announcement (01.01.2025, Fetch Variant Only)**  
Recently, public sources have primarily been using fingerprints from beta versions of Google Pixel firmware. Therefore, you may choose to modify the pif_json_url option in the config.prop file by replacing pif.json in the default link with pif_beta.json: https://raw.githubusercontent.com/vladrevers/pifsync/main/pif_beta.json

It is also recommended to significantly increase the update check interval (update_interval_minutes), for instance, to 6 hours (360 minutes). This setup tends to be more stable (e.g., RCS is less likely to break), provided there are no unexpected changes or "surprises" from Google.