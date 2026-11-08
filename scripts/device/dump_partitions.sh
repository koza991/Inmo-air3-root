#!/system/bin/sh
# Dump stock partitions from a rooted (temporary-boot) session to /data/local/tmp/bk.
# Run as root on the glasses, e.g. from Magisk's overlay.d or:  su -c 'sh dump_partitions.sh'
# Nothing is written to any partition; this only reads them.
set -e
O=/data/local/tmp/bk
rm -rf "$O"; mkdir -p "$O"
id > "$O/log.txt"

# Both slots, so a backup exists whichever slot you later flash.
PARTS="boot_a boot_b vendor_boot_a vendor_boot_b vbmeta_a vbmeta_b \
vbmeta_system_a vbmeta_system_b dtbo_a dtbo_b recovery_a recovery_b"

for p in $PARTS; do
  src="/dev/block/by-name/$p"
  [ -e "$src" ] || { echo "skip $p (not present)" >> "$O/log.txt"; continue; }
  dd if="$src" of="$O/$p.img" bs=4194304 >> "$O/log.txt" 2>&1
  sha256sum "$src" >> "$O/sums.txt" 2>&1
done

chmod -R 0644 "$O"/* 2>/dev/null || true
echo "done" >> "$O/log.txt"
touch "$O/DONE"
echo "Backup written to $O. Pull with: adb pull /data/local/tmp/bk ./backup"
