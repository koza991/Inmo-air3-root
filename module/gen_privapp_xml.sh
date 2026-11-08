#!/system/bin/sh
# Generate the privapp-permissions allowlist from the APKs' own manifests,
# so you grant exactly what each app requests (no hand-maintained list).
# Run as root on the glasses after the three Google packages are installed
# (as user apps is fine) so `dumpsys package` can read their requested perms.
#
# Output: /data/local/tmp/gapps/privapp.xml
set -e
OUT="${1:-/data/local/tmp/gapps/privapp.xml}"
PKGS="com.google.android.gms com.google.android.gsf com.android.vending"

{
  echo '<?xml version="1.0" encoding="utf-8"?>'
  echo '<permissions>'
  for p in $PKGS; do
    echo "    <privapp-permissions package=\"$p\">"
    dumpsys package "$p" \
      | awk '/requested permissions:/{f=1;next} f&&/^[[:space:]]+[a-zA-Z0-9_.]+[[:space:]]*$/{gsub(/[[:space:]]/,"");print;next} f{exit}' \
      | grep '\.' | sort -u \
      | while read perm; do echo "        <permission name=\"$perm\"/>"; done
    echo '    </privapp-permissions>'
  done
  echo '</permissions>'
} > "$OUT"

echo "Wrote $OUT"
