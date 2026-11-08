# Google apps as privileged system apps (optional)

On this build, installing **Google Services Framework**, **Play Services**, and
**Play Store** as ordinary user apps lets them install but Play Services
crash-loops: it requests privileged permissions (such as `MANAGE_USERS` and
`READ_DEVICE_CONFIG`) that Android only grants to apps in a **privileged system
path** (`/system/priv-app`) backed by a `privapp-permissions` allowlist.

This folder builds a Magisk module that places the three packages under
`/system/priv-app` with an allowlist derived from each APK's own manifest.

## You provide the APKs

Download these yourself from official sources and drop them in a working dir
(default `/data/local/tmp/gapps`) with these names:

| Name | Package | Pick |
|---|---|---|
| `gsf.apk` | `com.google.android.gsf` | Google Services Framework |
| `gms.apk` | `com.google.android.gms` | Play Services, **arm64**, min-API matching the OS |
| `vending.apk` | `com.android.vending` | Play Store |

No APKs are included in this repo.

## Build

```sh
# 1) (first install them as user apps so their manifests can be read)
adb install gsf.apk ; adb install gms.apk ; adb install vending.apk

# 2) generate the allowlist from the installed packages
adb push gen_privapp_xml.sh /data/local/tmp/gapps/
adb shell su -c 'sh /data/local/tmp/gapps/gen_privapp_xml.sh'

# 3) build the module
adb push make_module.sh /data/local/tmp/gapps/
adb shell 'SRC=/data/local/tmp/gapps su -c "sh /data/local/tmp/gapps/make_module.sh"'

# 4) remove the user-installed copies, then reboot
adb shell pm uninstall com.android.vending
adb shell pm uninstall com.google.android.gms
adb shell pm uninstall com.google.android.gsf
adb reboot
```

## Notes

- `system.prop` sets `ro.control_privapp_permissions=log` so a missing allowlist
  entry is logged rather than fatal (a fatal one can boot-loop the device).
  Once you've confirmed it's stable you can switch to `enforce`.
- The glasses are **not** Play-certified. You may hit "device not certified" at
  sign-in; register the device's GSF/Android ID at
  `google.com/android/uncertified` if needed. This repo does **not** collect or
  publish that ID — it's yours.
- To remove: delete the module in Magisk and reboot.
