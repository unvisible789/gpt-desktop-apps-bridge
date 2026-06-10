# SkillIntegrator.ps1
# Allows Grok bridge to pull latest skills / helpers from this GitHub repo

function Sync-BridgeFromGitHub {
    param(
        [string]$RepoOwner = "unvisible789",
        [string]$RepoName = "gpt-desktop-apps-bridge",
        [string]$Branch = "main"
    )

    $baseRaw = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$Branch"
    $localBase = "$env:USERPROFILE\GrokBridgeAssets\bridge"
    New-Item -ItemType Directory -Path $localBase -Force | Out-Null

    $filesToSync = @(
        "bridge/BRIDGE_HELPERS.ps1",
        "bridge/grok_bridge_monitor_v2.ps1"
    )

    foreach ($file in $filesToSync) {
        try {
            $url = "$baseRaw/$file"
            $localPath = Join-Path $localBase (Split-Path $file -Leaf)
            Invoke-WebRequest -Uri $url -OutFile $localPath -UseBasicParsing -ErrorAction Stop
            Write-Host "Synced: $file" -ForegroundColor Green
        } catch {
            Write-Warning "Failed to sync $file : $_"
        }
    }
    Write-Host "[SkillIntegrator] Bridge synced from GitHub. Restart monitor to load latest." -ForegroundColor Cyan
}

Write-Host "[SkillIntegrator] Ready - use Sync-BridgeFromGitHub to pull latest helpers" -ForegroundColor Green
