# flash.ps1 — flash a Magisk-patched STOCK boot to the CURRENT slot only.
# Reads the slot from the device; never assumes a or b. Prompts before flashing.
#
# Usage:
#   .\flash.ps1 -Image .\magisk_patched_boot.img
#   .\flash.ps1 -Image .\stock_boot.img          # (restore: point at your backup)
#
# Requires platform-tools (adb, fastboot) on PATH, or pass -Tools <dir>.

param(
  [Parameter(Mandatory = $true)][string]$Image,
  [string]$Tools = ""
)

$ErrorActionPreference = "Stop"
$fb = if ($Tools) { Join-Path $Tools "fastboot.exe" } else { "fastboot" }

if (-not (Test-Path $Image)) { throw "Image not found: $Image" }

Write-Host "Rebooting to bootloader..."
& (if ($Tools) { Join-Path $Tools "adb.exe" } else { "adb" }) reboot bootloader
Start-Sleep -Seconds 5

$slot = (& $fb getvar current-slot 2>&1 | Select-String 'current-slot:\s*(\w+)').Matches.Groups[1].Value
if (-not $slot) { throw "Could not read current slot. Is the device in bootloader mode and the driver installed?" }

$target = "boot_$slot"
Write-Host ""
Write-Host "About to flash:"
Write-Host "    image : $Image"
Write-Host "    target: $target  (current slot)"
$ans = Read-Host "Type the target partition name to confirm"
if ($ans -ne $target) { Write-Host "Mismatch, aborting. Nothing was flashed."; exit 1 }

& $fb flash $target $Image
& $fb reboot
Write-Host "Done. If it does not boot, flash your stock backup to $target and reboot."
