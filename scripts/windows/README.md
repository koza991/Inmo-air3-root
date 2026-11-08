# Windows USB driver (bootloader / fastbootd)

In normal mode the glasses show up for `adb` fine. In **bootloader** and
**fastbootd** mode they enumerate as a Google device with a different USB ID,
and a stock Windows install often has no matching driver, so `fastboot devices`
comes back empty.

## Install Google's USB driver

1. Download the **Google USB Driver** (from Android Studio's SDK Manager →
   *SDK Tools*, or the official
   [usb-driver zip](https://developer.android.com/studio/run/win-usb)).
2. With the glasses in bootloader mode (`adb reboot bootloader`), open
   **Device Manager**. The glasses appear with a warning icon (often named
   *Android* or *Android Bootloader Interface*, under *Other devices*).
3. Right-click → **Update driver** → **Browse my computer** → **Let me pick** →
   **Have Disk** → point to the driver's `android_winusb.inf`.
4. Choose **Android Bootloader Interface** and confirm.

After that, `fastboot devices` should list the glasses.

## Notes

- fastbootd (userspace fastboot, `adb reboot fastboot`) and bootloader
  (`adb reboot bootloader`) can present **different** USB IDs — you may need to
  bind the driver once in each mode.
- Installing an `.inf` with `pnputil /add-driver ... /install` needs an
  elevated (Administrator) shell. If it returns *Access denied*, copy the
  driver folder to a local path and run the elevated command from there, or use
  the Device Manager steps above.
- Nothing in this repo needs your PC's hostname, username, or any device
  serial — don't paste those into issues.
