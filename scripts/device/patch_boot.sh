#!/system/bin/sh
# Patch a boot image with Magisk's own boot_patch.sh, on-device, no app UI.
# Usage: su -c 'sh patch_boot.sh /path/to/Magisk.apk /path/to/boot.img'
# Output: new-boot.img next to this script's working dir.
set -e
APK="$1"; BOOT="$2"
[ -f "$APK" ] && [ -f "$BOOT" ] || { echo "usage: patch_boot.sh <Magisk.apk> <boot.img>"; exit 1; }

W=/data/local/tmp/mg
rm -rf "$W"; mkdir -p "$W/x"; cd "$W"
unzip -o -q "$APK" 'assets/*' 'lib/arm64-v8a/*' -d x
cp x/assets/boot_patch.sh x/assets/util_functions.sh .
for f in x/lib/arm64-v8a/lib*.so; do
  b=$(basename "$f" .so); b=${b#lib}; cp "$f" "./$b"
done
chmod 755 ./* 2>/dev/null || true
cp "$BOOT" boot.img

# Keep verity/encryption as stock; do NOT raise the OS patch level.
export KEEPVERITY=true KEEPFORCEENCRYPT=true PATCHVBMETAFLAG=false \
       RECOVERYMODE=false BOOTMODE=false
sh ./boot_patch.sh boot.img
ls -l new-boot.img
echo "Patched image: $W/new-boot.img  (pull it, then fastboot flash boot_<slot>)"
