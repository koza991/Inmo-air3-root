#!/system/bin/sh
# Build a Magisk module that installs Google apps as privileged system apps.
# Run as root on the glasses after Magisk is working.
#
# You provide the APKs in $SRC (download them yourself, official sources only):
#   gsf.apk      -> com.google.android.gsf      (Google Services Framework)
#   gms.apk      -> com.google.android.gms      (Play Services, arm64, API-matched)
#   vending.apk  -> com.android.vending         (Play Store)
#   privapp.xml  -> privapp-permissions allowlist (see gen_privapp_xml.sh)
#
# Usage: SRC=/data/local/tmp/gapps su -c 'sh make_module.sh'
set -e
SRC="${SRC:-/data/local/tmp/gapps}"
M=/data/adb/modules/air3_gapps
rm -rf "$M"
mkdir -p "$M/system/priv-app" "$M/system/etc/permissions" "$M/system/etc/sysconfig"

cat > "$M/module.prop" <<EOF
id=air3_gapps
name=Air3 Google Apps (priv-app)
version=1.0
versionCode=1
author=community
description=GSF + Play Services + Play Store as privileged system apps
EOF

# Let the system log (not reject) any privileged perm not in the allowlist,
# so a missing entry can't boot-loop the device. Tighten to 'enforce' later.
echo "ro.control_privapp_permissions=log" > "$M/system.prop"

inst() {  # inst <AppDirName> <apkfile>
  d="$M/system/priv-app/$1"; mkdir -p "$d"
  cp "$SRC/$2" "$d/$1.apk"
  # Extract bundled native libs so the system can find them.
  tmp="$SRC/x_$1"; rm -rf "$tmp"; mkdir -p "$tmp"; (cd "$tmp" && unzip -o -q "$d/$1.apk" 'lib/arm64-v8a/*' 2>/dev/null || true)
  if [ -d "$tmp/lib/arm64-v8a" ]; then mkdir -p "$d/lib/arm64"; cp "$tmp"/lib/arm64-v8a/* "$d/lib/arm64/"; fi
}

inst GoogleServicesFramework gsf.apk
inst PrebuiltGmsCore          gms.apk
inst Phonesky                 vending.apk

cp "$SRC/privapp.xml" "$M/system/etc/permissions/privapp-permissions-air3-gapps.xml"

cat > "$M/system/etc/sysconfig/air3-google.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<config>
    <allow-in-power-save package="com.google.android.gms" />
    <allow-in-data-usage-save package="com.google.android.gms" />
    <allow-unthrottled-location package="com.google.android.gms" />
    <allow-ignore-location-settings package="com.google.android.gms" />
    <allow-in-power-save package="com.android.vending" />
</config>
EOF

chown -R 0:0 "$M"
find "$M" -type d -exec chmod 755 {} \;
find "$M" -type f -exec chmod 644 {} \;
chcon -R u:object_r:system_file:s0 "$M/system" 2>/dev/null || true

echo "Module built at $M. Reboot to activate."
echo "Uninstall the user-installed copies first:  pm uninstall com.android.vending; pm uninstall com.google.android.gms; pm uninstall com.google.android.gsf"
