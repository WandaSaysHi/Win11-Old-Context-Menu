# Win11OldMenu - brings back the classic Windows 11 right-click menu.
# Windows feature 60813048 (enabled by KB5132061) forces the new menu. This turns it off,
# keeps it off after every reboot with a startup task, and sets the classic-menu registry keys.
# Actions: Install | Uninstall | Status  (Startup is used by the scheduled task)
param([ValidateSet('Install','Uninstall','Status','Startup')][string]$Action = 'Status')

$FeatureId  = 60813048
$Priority   = 8   # "User" priority, outranks the update's "Service" priority (4)
$Clsids     = '{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}', '{51668040-5e31-4023-bbe3-149163bd80f1}'
$TaskName   = 'ClassicContextMenu'
$InstallDir = Join-Path $env:ProgramFiles 'ClassicMenu'
$InstallPs1 = Join-Path $InstallDir 'ClassicMenu.ps1'

Add-Type -TypeDefinition @'
using System; using System.Runtime.InteropServices;
public static class FeatureStore {
  [StructLayout(LayoutKind.Sequential)] struct CFG { public uint Id, Packed, Payload; }
  [StructLayout(LayoutKind.Sequential)] struct UPDATE {
    public uint Id; public int Priority, State, StateOptions;
    public byte Variant, R1, R2, R3; public int PayloadKind; public uint Payload; public int Operation; }
  [DllImport("ntdll.dll")] static extern int RtlQueryFeatureConfiguration(uint id, int type, ref ulong stamp, out CFG cfg);
  [DllImport("ntdll.dll")] static extern int RtlSetFeatureConfigurations(IntPtr stamp, int type, UPDATE[] u, int count);
  // Runtime store (type 1). State: 0 default, 1 disabled, 2 enabled. Operation: 1 set, 4 reset.
  public static bool IsDisabled(uint id) { ulong s = 0; CFG c;
    return RtlQueryFeatureConfiguration(id, 1, ref s, out c) == 0 && ((c.Packed >> 4) & 3) == 1; }
  public static int Set(uint id, int priority, int state, int op) {
    var u = new UPDATE { Id = id, Priority = priority, State = state, Operation = op };
    return RtlSetFeatureConfigurations(IntPtr.Zero, 1, new[] { u }, 1); }
}
'@

function Restart-Explorer {
  # Windows restarts the shell by itself, as the normal user.
  Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 4
}

function Show-Status {
  $on   = [FeatureStore]::IsDisabled($FeatureId)
  $task = Test-Path $InstallPs1   # the SYSTEM task itself is hidden from non-admins; its installed script isn't
  $keys = @($Clsids | Where-Object { Test-Path "HKCU:\Software\Classes\CLSID\$_\InprocServer32" }).Count
  Write-Host "Classic menu active:  $on"
  Write-Host "Kept after reboot:    $task"
  Write-Host "Registry keys:        $keys of 2"
}

switch ($Action) {
  'Status'  { Show-Status; return }
  'Startup' {
    $wasOn = -not [FeatureStore]::IsDisabled($FeatureId)
    [void][FeatureStore]::Set($FeatureId, $Priority, 1, 1)
    if ($wasOn -and (Get-Process explorer -ErrorAction SilentlyContinue)) { Restart-Explorer }
    return
  }
}

# Install / Uninstall need admin - relaunch elevated if needed.
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) {
  Start-Process powershell -Verb RunAs -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$PSCommandPath`"",'-Action',$Action)
  return
}

if ($Action -eq 'Install') {
  $err = [FeatureStore]::Set($FeatureId, $Priority, 1, 1)
  New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
  if ($PSCommandPath -ne $InstallPs1) { Copy-Item -LiteralPath $PSCommandPath -Destination $InstallPs1 -Force }
  Register-ScheduledTask -TaskName $TaskName -Force `
    -Action    (New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$InstallPs1`" -Action Startup") `
    -Trigger   (New-ScheduledTaskTrigger -AtStartup) `
    -Principal (New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest) `
    -Settings  (New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 2)) `
    -Description 'Keeps the classic right-click menu (Win11OldMenu).' | Out-Null
  foreach ($c in $Clsids) { reg add "HKCU\Software\Classes\CLSID\$c\InprocServer32" /ve /f | Out-Null }
  $msg = 'Classic menu installed.'
} else {
  $err = [FeatureStore]::Set($FeatureId, $Priority, 0, 4)
  Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
  if (Test-Path $InstallDir) { Remove-Item -LiteralPath $InstallDir -Recurse -Force }
  foreach ($c in $Clsids) { reg delete "HKCU\Software\Classes\CLSID\$c" /f 2>$null | Out-Null }
  $msg = 'Classic menu removed. Windows default menu restored.'
}

Restart-Explorer
Write-Host ""
if ($err -eq 0) { Write-Host $msg -ForegroundColor Green } else { Write-Host ("Something went wrong (code 0x{0:X8})." -f $err) -ForegroundColor Red; Show-Status }
Write-Host ""
Read-Host "Press Enter to close"
