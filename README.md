# INMO Air3 Root (Magisk, no data wipe)

Root the **INMO Air3 (model IMA301)** AR glasses with Magisk using a temporary
boot, so your original `boot` image is backed up **before** anything is flashed.
No `userdata` wipe, no custom recovery, and a one-command path back to stock.

> **Status of these glasses.** On the unit this was written for, the bootloader
> was already **unlocked** (`fastboot getvar unlocked` → `yes`) and
> `fastboot oem device-info` reported the device as unlocked. Qualcomm Secure
> Boot was **off** (`secure: no`). Your unit may differ — check first (see
> [Step 1](#step-1--check-your-device)). If your bootloader is locked and cannot
> be unlocked, this method does not apply.

> ⚠️ **Read before you start.** Modifying `boot` is inherently risky. INMO does
> not publish full firmware, so a reliable per-partition backup (made in
> [Step 4](#step-4--back-up-the-stock-partitions)) is your only way back if a
> flash goes wrong. Do not skip it. You do this at your own risk; it may void
> your warranty.

---

## Why a temporary boot?

On a `user` build, `fastboot fetch` and `dd` over ADB can't read the boot
partitions (no root yet), and INMO ships no firmware image to extract a stock
`boot.img` from. The workaround:

1. Patch a **Google GKI** boot image (matching the glasses' kernel) with Magisk.
2. `fastboot boot` it **once** — nothing is written to the device.
3. From that temporary rooted session, `dd` the real stock partitions out to
   your PC. **Now you have a verified backup.**
4. Patch the *stock* `boot` with Magisk and flash only that.

Everything up to the flash in [Step 6](#step-6--flash-magisk-patched-stock-boot)
is read-only or in-memory.

---

## What you need

- The glasses with **Developer mode + USB debugging** on (see
  [Step 0](#step-0--enable-developer-mode-usb-debugging-and-adb-on-the-glasses)).
- A Windows or Linux PC with **[Android platform-tools][pt]** (`adb`, `fastboot`).
- Google's **USB driver** (Windows) so the PC sees the glasses in
  bootloader/fastbootd mode. See [Windows USB driver](#windows-usb-driver).
- The glasses' USB-C cable.
- Downloads you fetch yourself from official sources (see
  [Downloads](#downloads)) — **no binaries are shipped in this repo.**

[pt]: https://developer.android.com/tools/releases/platform-tools

---

## Downloads (get these yourself)

| File | Where | Notes |
|---|---|---|
| Google GKI boot image | [Android GKI release builds][gki] | Pick the build whose kernel matches your glasses (see Step 2). |
| Magisk APK | [Magisk releases][magisk] | Official `topjohnwu/Magisk` only. |

Verify everything you download. Google GKI images and the Magisk APK are signed
by their publishers; don't use mirrors.

[gki]: https://source.android.com/docs/core/architecture/kernel/gki-release-builds
[magisk]: https://github.com/topjohnwu/Magisk/releases

---

## Steps

### Step 0 — Enable Developer mode, USB debugging, and ADB on the glasses

You must turn on Developer mode and authorise ADB on the glasses **first** —
every later step talks to them over `adb`/`fastboot`.

INMO's own glasses have a slightly non-standard way in. INMO only documents the
exact gesture for the **Air2** (Settings → About → *My Glasses*, then
long-press the right temple touchpad twice, ~1.5 s each, and enter the code
`20210108`). The Air3 runs Android 14, so try the standard Android route first
and fall back to the Air2 gesture if your build hides the build-number entry:

1. On the glasses open **Settings → About / About this device** (INMO may label
   it *My Glasses*).
2. **Tap the build number / version number 7 times** until it says
   *You are now a developer*.
   - If there is no tappable build number, use the INMO entry instead:
     long-press the **right touchpad twice (~1.5 s each)** on the About screen
     and enter **`20210108`**.
3. Go back to **Settings → System → Developer options** and turn on
   **USB debugging** (and *ADB debugging* if shown separately).
4. Connect the glasses to the PC by USB-C. Set the USB mode to **File transfer
   (MTP)**, not charge-only.
5. On the glasses, when the **"Allow USB debugging?"** dialog appears, check
   *Always allow from this computer* and tap **Allow**. (If it never appears,
   run `adb devices` once — that triggers it.)

> INMO notes that enabling ADB may void the short no-questions return window and
> that altering the OS can cause instability — this is your own risk.

Verify from the PC:

```sh
adb devices          # the glasses should be listed as 'device', not 'unauthorized'
```

If it shows `unauthorized`, accept the dialog on the glasses. If empty, re-check
the cable/USB-mode and that USB debugging is on.

### Step 1 — Check your device

With ADB working (Step 0), confirm the bootloader state:

```sh
adb devices
adb reboot bootloader
fastboot getvar unlocked          # expect: unlocked: yes
fastboot oem device-info          # expect: Device unlocked: true
fastboot getvar secure            # note the value
```

If `unlocked` is not `yes`, stop — you must unlock the bootloader first (that
**does** wipe data), and no public unlock method is documented for this device.

Reboot back to the system when done: `fastboot reboot`.

### Step 2 — Match the kernel and get a GKI boot image

```sh
adb shell uname -r
```

Read the `android<N>-<x.y>.<sublevel>` kernel string, then download the matching
Google GKI boot image from the [GKI release builds][gki] page (use the
`boot-<ver>.img` from the certified GKI artifacts, arm64).

### Step 3 — Patch the GKI image with Magisk (temporary boot)

Use the Magisk app's *Patch a file* on the GKI `boot.img`, **or** the included
[`scripts/device/patch_boot.sh`](scripts/device/patch_boot.sh), which runs
Magisk's own `boot_patch.sh` on-device under `/data/local/tmp`. Keep the
patched image's OS patch level equal to the source — do not raise it.

### Step 4 — Back up the stock partitions

`fastboot boot` the **patched GKI** image (temporary; nothing is flashed), then
from the rooted session copy the stock partitions to your PC and verify hashes.
[`scripts/device/dump_partitions.sh`](scripts/device/dump_partitions.sh) dumps
`boot`, `vendor_boot`, `vbmeta`, `vbmeta_system`, `dtbo`, `recovery` for **both
slots** and writes a `sha256` list. Pull them and compare.

**Keep this backup somewhere safe (two copies).** It is device-specific and is
your only way back.

### Step 5 — Patch the *stock* boot

Run Magisk's patch on the stock `boot` image for your **current slot** (check
with `fastboot getvar current-slot`). The included scripts default to the
current slot — never assume a slot, read it.

### Step 6 — Flash Magisk-patched stock boot

```sh
adb reboot bootloader
fastboot flash boot_<slot> magisk_patched_boot.img   # only the current slot
fastboot reboot
```

Open Magisk, finish setup, and grant root (set **Superuser access: Apps and
ADB** if you'll use `adb shell su`).

### Restore to stock

```sh
adb reboot bootloader
fastboot flash boot_<slot> stock_boot_<slot>.img     # from your Step 4 backup
fastboot reboot
```

Remove any Magisk modules first if the system won't boot.

---

## Windows USB driver

In bootloader/fastbootd mode the glasses enumerate as a Google device. If
`fastboot devices` is empty, install Google's USB driver and bind
**Android Bootloader Interface** to the device in Device Manager. See
[`scripts/windows/README.md`](scripts/windows/README.md).

---

## Optional: Google apps as privileged system apps

Installing GSF / Play Services / Play Store as normal user apps fails on this
build — Play Services needs privileged permissions (e.g. `MANAGE_USERS`) only
granted to system `priv-app`. The [`module/`](module) folder has a generator
that builds a Magisk module placing them under `/system/priv-app` with a
`privapp-permissions` allowlist. You supply the APKs; none are shipped here.
See [`module/README.md`](module/README.md).

---

## License

MIT — see [LICENSE](LICENSE). Provided as-is, with no warranty. "INMO" and
"Air3" are trademarks of their respective owners; this project is unaffiliated.
