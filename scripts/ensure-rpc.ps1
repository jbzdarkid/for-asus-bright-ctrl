# Idempotent: ensures HKLM\...\SecurityCheck = 0 and that the ASUSOptimization
# service has picked up that value. AsusOptimization caches it at startup, so
# changing the registry alone is not enough -- we must restart the service.
# A no-op when the value is already 0, which is the steady-state case.
#
# Requires admin (writes HKLM and restarts a service).

$keyPath = 'HKLM:\SOFTWARE\ASUS\ASUS System Control Interface\AsusOptimization\ASUS Keyboard Hotkeys'
$valName = 'SecurityCheck'
$svcName = 'ASUSOptimization'

$current = $null
try {
    $current = (Get-ItemProperty -Path $keyPath -Name $valName -ErrorAction Stop).$valName
} catch [System.Management.Automation.ItemNotFoundException] {
    # Key or value missing; treat as needs-setting.
}

if ($current -eq 0) {
    echo "$valName is already 0; nothing to do."
    exit
}

echo "Setting $keyPath\$valName = 0 (was: $current)"
New-Item -Path $keyPath -Force
New-ItemProperty -Path $keyPath -Name $valName -Value 0 -PropertyType DWord -Force

# Stopped restarting the service because it just resets the regkey back.
# $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
# if ($null -eq $svc) {
#     Write-Warning "service '$svcName' not found; cannot restart. Reboot to apply."
#     exit
# }
# echo "Restarting service '$svcName'..."
# Restart-Service -Name $svcName -Force
