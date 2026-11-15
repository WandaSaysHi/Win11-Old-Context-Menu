# Win11OldMenu

Get the classic right-click menu back in Windows 11. This works even after the November 2026 update (KB5132061).

## Install

1. Download this folder.
2. Double-click **`Install.cmd`** and click **Yes** on the admin prompt.

That's it. Your taskbar will flicker once, and the old menu stays after reboots.

## Uninstall

Double-click **`Uninstall.cmd`**.

---

<details>
<summary>How it works</summary>

KB5132061 turns on the Windows feature flag `60813048`. While that flag is on, Explorer ignores the usual registry fix and shows the new menu. `ClassicMenu.ps1` turns the flag off using the built-in Windows API (`RtlSetFeatureConfigurations`), and adds a startup task (`ClassicContextMenu`) that turns it off again after every reboot. It also sets the classic-menu registry keys. Uninstall removes all of this.

Tested on Windows 11 build 26200. This is unofficial; use at your own risk.
</details>

MIT License
