# Elevation code from https://superuser.com/a/532109

param(
    [switch]$elevated,
    [string]$installDir = (Join-Path $env:LOCALAPPDATA 'for-asus-bright-ctrl'),
    [string]$targetUser = $env:USERNAME
)

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  {
    if ($elevated) {
        echo "Need admin rights to install!"
    } else {
        # Forward the *original* user's identity and install dir; admin's
        # $env:LOCALAPPDATA / $env:USERNAME would otherwise resolve differently.
        echo ('Starting as admin by "{0}" at "{1}"' -f ($env:USERNAME),($pwd))
        Start-Process -Verb RunAs powershell.exe -ArgumentList ('-ExecutionPolicy Bypass -noprofile -Command Set-Location -LiteralPath \"{0}\"; & \"{1}\" -elevated -installDir \"{2}\" -targetUser \"{3}\"' -f ($pwd),($myinvocation.MyCommand.Definition),$installDir,$targetUser)
    }
    exit
}

echo ('Started as admin "{0}" at "{1}" (installing to "{2}")' -f ($env:USERNAME),($pwd),$installDir)

# Stop any previously-installed instance so we can overwrite the exe.
Stop-ScheduledTask -TaskName "for-asus-bright-ctrl" -ErrorAction SilentlyContinue
Stop-Process -Name "for-asus-bright-ctrl" -Force -ErrorAction SilentlyContinue

New-Item -ItemType Directory -Force -Path $installDir | Out-Null
Copy-Item -Path "$pwd\*" -Include 'for-asus-bright-ctrl.exe','ensure-rpc.ps1','uninstall.ps1','uninstall.reg' -Destination $installDir -Force

$action = New-ScheduledTaskAction -Execute "$installDir\for-asus-bright-ctrl.exe" -WorkingDirectory "$installDir"
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $targetUser
# Delay so the at-logon ensure-rpc.ps1 task has time to (re)apply the
# registry value and restart ASUSOptimization before the exe connects.
$trigger.Delay = 'PT1M'
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -ExecutionTimeLimit 0
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "for-asus-bright-ctrl" -Description "This task runs a third-party program to control ASUS Flicker-Free Dimming with hot keys" -Settings $settings -Force
Start-ScheduledTask -TaskName "for-asus-bright-ctrl"

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -NoProfile -File `"$installDir\ensure-rpc.ps1`"" -WorkingDirectory "$installDir"
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $targetUser
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "for-asus-bright-ctrl regedit" -Description "This task edits the registry to allow the third-party program to control ASUS Flicker-Free Dimming with hot keys" -Settings $settings -Force -RunLevel Highest
Start-ScheduledTask -TaskName "for-asus-bright-ctrl regedit"
