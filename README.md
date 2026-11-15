# Win11OldMenu

Get the classic right-click menu back in Windows 11.
This works after the November 2026 update (KB5132061).

## About

I just don't like Microsoft forcing changes and breaking backwards compatibility.
I tried to get the old menu back with the old registry edits and apparently they all broke with the latest update.
So I went ahead and vibe-coded this with Opus 5.5., and now I am only sharing this in case people don't have access to it. It fixed the problem for me, most likely will fix it for you too.

Shout out to Microsoft for being so shitty with your updates that your users have to download sketchy scripts from strangers online just to have your system work like they want it to. Fantastic user experience as always!

Feel free to inspect the code, leave comments if anything is suspicious.
I tested this on my own computer, it survives rebooting.

## Install

1. Download this folder.
2. Ideally inspect the **`ClassicMenu.ps1`** file so you know this isn't malicious.
3. Double-click **`Install.cmd`** and click **Yes** on the admin prompt.

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
