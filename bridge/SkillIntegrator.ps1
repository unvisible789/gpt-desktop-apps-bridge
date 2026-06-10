# SkillIntegrator.ps1
# Allows Grok bridge / agentic system to pull latest skills, helpers, and app modules from this GitHub repo.
# Per SELF_UPGRADE_PLAN.md Phase 2: DownloadFromGitHub + IntegrateSkill + manifest + OneDrive cache + safety.

$ErrorActionPreference = 'Stop'

$RepoOwner = "unvisible789"
$RepoName = "gpt-desktop-apps-bridge"
$Branch = "main"
$BaseRaw = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$Branch"
$LocalBridge = "$env:USERPROFILE\GrokBridgeAssets\bridge"
$LocalApps = "$env:USERPROFILE\GrokBridgeAssets\apps"
$OneDriveCache = "$env:USERPROFILE\OneDrive\GrokBridgeAssets\cache"
$SkillsManifestPath = "$env:USERPROFILE\GrokBridgeAssets\skills-manifest.json"
$TasksPath = "$env:USERPROFILE\GrokBridgeAssets\tasks.json"
$SyncLog = "$env:USERPROFILE\GrokBridgeAssets\SYNC_LOG.md"

function Ensure-Dirs {
    @($LocalBridge, $LocalApps, $OneDriveCache) | ForEach-Object { New-Item -ItemType Directory -Path $_ -Force | Out-Null }
}

function Write-SyncLog {
    param([string]$Message)
    $entry = "$(Get-Date -Format o) | $Message"
    Add-Content -Path $SyncLog -Value $entry -ErrorAction SilentlyContinue
    Write-Host $entry -ForegroundColor Cyan
}

function Get-AvailableSkills {
    # Returns list of known downloadable skills/apps from the repo (can be extended via skills-manifest.json in repo)
    $core = @(
        @{ name = "BRIDGE_HELPERS"; path = "bridge/BRIDGE_HELPERS.ps1"; type = "bridge" },
        @{ name = "BRIDGE_VISION"; path = "bridge/BRIDGE_VISION.ps1"; type = "bridge" },
        @{ name = "SkillIntegrator"; path = "bridge/SkillIntegrator.ps1"; type = "bridge" },
        @{ name = "Playwright-Integration"; path = "bridge/Playwright-Integration.ps1"; type = "bridge" },
        @{ name = "grok_bridge_monitor_v2"; path = "bridge/grok_bridge_monitor_v2.ps1"; type = "bridge" }
    )
    $apps = @(
        @{ name = "notepad"; path = "apps/notepad"; type = "app" },
        @{ name = "chrome"; path = "apps/chrome"; type = "app" },
        @{ name = "durable"; path = "apps/durable"; type = "app" },
        @{ name = "browser-advanced"; path = "apps/browser-advanced"; type = "app" },
        @{ name = "outlook"; path = "apps/outlook"; type = "app" },
        @{ name = "desktop-general"; path = "apps/desktop-general"; type = "app" },
        @{ name = "file-explorer"; path = "apps/file-explorer"; type = "app" },
        @{ name = "excel"; path = "apps/excel"; type = "app" }
    )
    return ($core + $apps)
}

function Download-FromGitHub {
    param(
        [Parameter(Mandatory)] [string]$RepoPath,
        [string]$LocalTarget,
        [switch]$DryRun
    )
    Ensure-Dirs
    $url = "$BaseRaw/$RepoPath"
    if (-not $LocalTarget) {
        $LocalTarget = Join-Path $LocalBridge (Split-Path $RepoPath -Leaf)
        if ($RepoPath -like "apps/*") { $LocalTarget = Join-Path $LocalApps (Split-Path -Leaf $RepoPath) }
    }
    if ($DryRun) {
        Write-Host "[DRYRUN] Would download $url -> $LocalTarget" -ForegroundColor Yellow
        return $LocalTarget
    }
    try {
        if ($RepoPath.EndsWith("/")) {
            Write-Warning "Directory download not fully recursive in raw mode. Use git sparse or manual for full dirs."
        }
        Invoke-WebRequest -Uri $url -OutFile $LocalTarget -UseBasicParsing
        Write-Host "Downloaded: $RepoPath -> $LocalTarget" -ForegroundColor Green
        Write-SyncLog "Downloaded $RepoPath"
        return $LocalTarget
    } catch {
        Write-Warning "Failed to download ${RepoPath}: $_"
        Write-SyncLog "FAILED download $RepoPath : $_"
        return $null
    }
}

function Integrate-Skill {
    param(
        [Parameter(Mandatory)] [string]$SkillName,
        [switch]$DryRun,
        [switch]$Force
    )
    Ensure-Dirs
    $skills = Get-AvailableSkills | Where-Object { $_.name -eq $SkillName -or $_.path -like "*$SkillName*" }
    if (-not $skills) { Write-Warning "Skill not found: $SkillName"; return }

    foreach ($skill in $skills) {
        $localPath = if ($skill.type -eq "app") { Join-Path $LocalApps $skill.name } else { $LocalBridge }
        $targetFile = if ($skill.type -eq "app") {
            # For apps, download the main control file (convention: <App>-HumanControl.ps1 or README)
            $main = "$($skill.path)/$($skill.name -replace '^(.)','$&')-HumanControl.ps1"  # simplistic; real apps vary
            Join-Path $localPath (Split-Path -Leaf $main)
        } else {
            Join-Path $localPath (Split-Path -Leaf $skill.path)
        }

        if ($DryRun) {
            Write-Host "[DRYRUN] Integrate $($skill.name) from $($skill.path)" -ForegroundColor Yellow
            continue
        }

        $downloaded = Download-FromGitHub -RepoPath $skill.path -LocalTarget $targetFile -DryRun:$DryRun
        if ($downloaded) {
            Write-SyncLog "Integrated skill: $($skill.name)"
            # Update local tasks if present
            if (Test-Path $TasksPath) {
                # naive append example; in real use a proper json update
                Add-Content -Path $TasksPath -Value "# auto-added by Integrate-Skill: $($skill.name)" -ErrorAction SilentlyContinue
            }
        }
    }
    Write-Host "[SkillIntegrator] Integrate complete for $SkillName" -ForegroundColor Green
}

function Sync-BridgeFromGitHub {
    param(
        [string]$RepoOwner = "unvisible789",
        [string]$RepoName = "gpt-desktop-apps-bridge",
        [string]$Branch = "main",
        [switch]$IncludeApps,
        [switch]$DryRun
    )

    $baseRaw = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$Branch"
    $localBase = "$env:USERPROFILE\GrokBridgeAssets\bridge"
    New-Item -ItemType Directory -Path $localBase -Force | Out-Null

    $filesToSync = @(
        "bridge/BRIDGE_HELPERS.ps1",
        "bridge/BRIDGE_VISION.ps1",
        "bridge/SkillIntegrator.ps1",
        "bridge/Playwright-Integration.ps1",
        "bridge/grok_bridge_monitor_v2.ps1",
        "bridge/Setup-FlaUI.ps1"
    )

    foreach ($file in $filesToSync) {
        try {
            $url = "$baseRaw/$file"
            $localPath = Join-Path $localBase (Split-Path $file -Leaf)
            if ($DryRun) {
                Write-Host "[DRYRUN] $url -> $localPath" -ForegroundColor Yellow; continue
            }
            Invoke-WebRequest -Uri $url -OutFile $localPath -UseBasicParsing -ErrorAction Stop
            Write-Host "Synced: $file" -ForegroundColor Green
            Write-SyncLog "Synced $file"
        } catch {
            Write-Warning "Failed to sync $file : $_"
            Write-SyncLog "FAILED $file : $_"
        }
    }

    if ($IncludeApps) {
        $appDirs = @("apps/notepad", "apps/chrome", "apps/durable", "apps/desktop-general")
        foreach ($app in $appDirs) {
            # Best-effort: download known main file
            $mainFile = "$app/$(Split-Path $app -Leaf)-HumanControl.ps1"
            try {
                $url = "$baseRaw/$mainFile"
                $localAppDir = Join-Path "$env:USERPROFILE\GrokBridgeAssets\apps" (Split-Path $app -Leaf)
                New-Item -ItemType Directory -Path $localAppDir -Force | Out-Null
                $localPath = Join-Path $localAppDir (Split-Path -Leaf $mainFile)
                if (-not $DryRun) {
                    Invoke-WebRequest -Uri $url -OutFile $localPath -UseBasicParsing
                    Write-SyncLog "Synced app module $app"
                }
            } catch { Write-Warning "App sync note: $app may need full dir (use git or manual)." }
        }
    }

    Write-Host "[SkillIntegrator] Bridge synced from GitHub. Restart monitor to load latest." -ForegroundColor Cyan
    Write-SyncLog "Sync-BridgeFromGitHub completed (IncludeApps=$IncludeApps)"
}

function Install-NewApp {
    param([Parameter(Mandatory)][string]$AppName, [switch]$DryRun)
    Integrate-Skill -SkillName $AppName -DryRun:$DryRun
    Write-Host "New app integration attempted: $AppName. See local apps/ and update tasks.json / monitor." -ForegroundColor Green
}

Write-Host "[SkillIntegrator] Ready. Commands: Sync-BridgeFromGitHub [-IncludeApps] [-DryRun], Get-AvailableSkills, Integrate-Skill <name> [-DryRun], Install-NewApp <name>" -ForegroundColor Green
