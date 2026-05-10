# Elevation code from https://superuser.com/a/532109

param(
    [switch]$elevated,
    [string]$installDir = (Join-Path $env:LOCALAPPDATA 'for-asus-bright-ctrl')
)

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  {
    if ($elevated) {
        echo "Need admin rights to uninstall!"
    } else {
        echo ('Starting as admin by "{0}" at "{1}"' -f ($env:USERNAME),($pwd))
        Start-Process -Verb RunAs powershell.exe -ArgumentList ('-ExecutionPolicy Bypass -noprofile -Command Set-Location -LiteralPath \"{0}\"; & \"{1}\" -elevated -installDir \"{2}\"' -f ($pwd),($myinvocation.MyCommand.Definition),$installDir)
    }
    exit
}

echo ('Started as admin "{0}" at "{1}"' -f ($env:USERNAME),($pwd))

Stop-ScheduledTask -TaskName "for-asus-bright-ctrl" -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName "for-asus-bright-ctrl" -Confirm:$false -ErrorAction SilentlyContinue

Unregister-ScheduledTask -TaskName "for-asus-bright-ctrl regedit" -Confirm:$false -ErrorAction SilentlyContinue
Set-ItemProperty -Path 'HKLM:\SOFTWARE\ASUS\ASUS System Control Interface\AsusOptimization\ASUS Keyboard Hotkeys' -Name 'SecurityCheck' -Value 1 -Type DWord -ErrorAction SilentlyContinue

if (Test-Path $installDir) { Remove-Item -Recurse -Force $installDir }
