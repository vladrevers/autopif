## [1.9.0] - 2025-05-20
- Added `turn_spoof_vendingSDK` option to activate the `spoofVendingSdk` parameter in the PIF file
- **Note**: This option is enabled by default for Android 13+ (only during first installation or when updating from version 1.8.1 and older). It helps bypass Play Integrity changes where, since May 2025, devices with unlocked bootloaders on Android 13+ cannot pass MEETS_DEVICE_INTEGRITY. Be aware that this feature may cause issues with the Play Store (navigation degradation or crashes during app installation/updates).
- Fixed config migration to correctly process the last line of config.prop files without trailing newline

## [1.8.1] - 2024-10-27
- **selfgen variant**: fixed issue with ignoring failures when calling `get_pif_json.sh` and enhanced error checks within the script
- Removed unnecessary code

## [1.8.0] - 2024-10-26
- Added `turn_spoof_signature` option to activate the `spoofSignature` parameter in the PIF file
- Migrated configuration to a unified `config.prop` file instead of separate configuration files. See [Preferences](https://github.com/vladrevers/autopif#preferences) for more details.
- Code refactoring and general optimization

## [1.7.1] - 2024-10-16
- Added a one-time manual check option via the Magisk interface
