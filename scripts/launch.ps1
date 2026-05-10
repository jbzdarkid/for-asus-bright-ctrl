# Self-relaunch hidden so the user does not see a PowerShell window flash.
if (-not $env:FOR_ASUS_BRIGHT_CTRL_HIDDEN) {
    $env:FOR_ASUS_BRIGHT_CTRL_HIDDEN = '1'
    Start-Process powershell.exe -WindowStyle Hidden -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$PSCommandPath`""
    exit
}

Get-ChildItem $PSScriptRoot | Unblock-File

# Placeholder to be replaced with the real version during CI build.
$InstalledVersion = '0.0.0-dev'
$repo             = 'jbzdarkid/for-asus-bright-ctrl'
$updateLog        = Join-Path $PSScriptRoot 'update-log.txt'

function Write-UpdateLog([string]$msg) {
    $line = '[{0}] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $msg
    try { Add-Content -LiteralPath $updateLog -Value $line -ErrorAction Stop } catch { }
}

function Invoke-UpdateCheck {
    if ($InstalledVersion.EndsWith('-dev')) {
        Write-UpdateLog "skipping update check on dev"
        return
    }

    try {
        # Github APIs require these headers
        $headers = @{
            'User-Agent' = 'for-asus-bright-ctrl-updater'
            'Accept'     = 'application/vnd.github+json'
        }
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest" -Headers $headers -TimeoutSec 15
        $latest  = $release.tag_name

        if ($latest -eq $InstalledVersion) {
            Write-UpdateLog "up to date ($InstalledVersion)"
            return
        }

        Write-UpdateLog "update available: $InstalledVersion -> $latest"

        $asset = $release.assets | Where-Object name -eq 'for-asus-bright-ctrl.zip' | Select-Object -First 1

        # Download the zipfile to a nearby folder so we can move instead of copying across drives.
        $stage   = Join-Path $PSScriptRoot '.update'
        $zipPath = "$stage.zip"
        Write-UpdateLog "downloading latest assets from $($asset.browser_download_url)"
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath -Headers $headers -TimeoutSec 120 -UseBasicParsing

        $actual = "sha256:" + (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLower()
        if ($actual -ne $asset.digest) {
            Write-UpdateLog "hash mismatch (expected $($asset.digest), got $actual); skipping update"
            return
        }

        New-Item -ItemType Directory -Force -Path $stage | Out-Null
        Expand-Archive -LiteralPath $zipPath -DestinationPath $stage -Force

        # Stop before updating so that we can overwrite the exe.
        Stop-Process -Name 'for-asus-bright-ctrl' -Force -ErrorAction SilentlyContinue

        # Do not recurse because it's not a consistent order.
        # Instead, move each file directly from the unzip folder to the production folder.
        Get-ChildItem -LiteralPath $stage -Force | ForEach-Object {
            Move-Item -LiteralPath $_.FullName -Destination $PSScriptRoot -Force
        }

        Write-UpdateLog "successfully updated to $latest"
    }
    catch {
        Write-UpdateLog ("update check failed: {0}" -f $_.Exception.Message)
    }
}

Invoke-UpdateCheck

Start-Process -FilePath (Join-Path $PSScriptRoot 'for-asus-bright-ctrl.exe') -WorkingDirectory $PSScriptRoot
