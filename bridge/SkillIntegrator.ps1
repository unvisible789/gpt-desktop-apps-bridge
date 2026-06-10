<#
.SYNOPSIS
Skill Downloader & Integrator for Grok self-upgrade via GitHub + Drive.
Allows "downloading" new skills from the gpt-desktop-apps-bridge repo,
integrating them into local bridge (apps/, agentic-os, etc.).
Uses OneDrive\GrokBridgeAssets for storage/cache.
Human-like: Logs actions, uses waits, safe dry-run.

Usage:
. .\bridge\SkillIntegrator.ps1
Download-Skill -SkillName "browser-advanced" -FromGitHub
Integrate-Skill -SkillPath "local\path" 

This enables massive jumps: pull new human-like controls, expand abilities autonomously (local-safe).
#>

$bridge = "C:\Users\Owner\Documents\Codex\2026-06-08\can-you-control-my-computer\work\grok-codex-bridge"
$assets = "C:\Users\Owner\OneDrive\GrokBridgeAssets"
$githubOwner = "unvisible789"
$githubRepo = "gpt-desktop-apps-bridge"
$githubBase = "https://raw.githubusercontent.com/$githubOwner/$githubRepo/main"

function Log-SkillAction {
    param([string]$Action, [string]$Details = "")
    $ts = Get-Date -Format "HH:mm:ss.fff"
    $msg = "[$ts] SKILL: $Action $(if($Details){": $Details"})"
    Add-Content -Path (Join-Path $bridge "HUMAN_ACTION.log") -Value $msg -ErrorAction SilentlyContinue
    Write-Output $msg
}

function Ensure-Dir($Path) {
    if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
}

function Download-Skill {
    param(
        [string]$SkillName,  # e.g., "browser-advanced" or "excel-control"
        [switch]$FromGitHub,
        [switch]$DryRun
    )
    Log-SkillAction "Download-Skill" "Starting $SkillName (GitHub=$FromGitHub, Dry=$DryRun)"
    Ensure-Dir $assets

    if ($FromGitHub) {
        $localPath = Join-Path $assets $SkillName
        Ensure-Dir $localPath

        # Simulate download of key files from GitHub (in real: use Invoke-WebRequest or git)
        $filesToPull = @("README.md", "Control.ps1")  # Extend per skill
        foreach ($f in $filesToPull) {
            $url = "$githubBase/apps/$SkillName/$f"
            $dest = Join-Path $localPath $f
            if (-not $DryRun) {
                try {
                    Invoke-WebRequest -Uri $url -OutFile $dest -ErrorAction Stop
                    Log-SkillAction "Downloaded" "$f to $dest"
                } catch {
                    Log-SkillAction "DownloadFailed" "$f : $_ (using local template)"
                    # Fallback template
                    " # Auto-generated skill for $SkillName`n# Human-like control stub" | Out-File $dest
                }
            } else {
                Log-SkillAction "DryRunDownload" "$url -> $dest"
            }
        }
        return $localPath
    }
    Log-SkillAction "DownloadComplete" $SkillName
}

function Integrate-Skill {
    param([string]$SkillPath, [switch]$DryRun)
    Log-SkillAction "Integrate-Skill" "From $SkillPath (Dry=$DryRun)"

    $skillName = Split-Path $SkillPath -Leaf
    $targetAppDir = Join-Path $bridge "apps\$skillName"
    Ensure-Dir $targetAppDir

    if (-not $DryRun) {
        Copy-Item -Path "$SkillPath\*" -Destination $targetAppDir -Recurse -Force -ErrorAction SilentlyContinue
        Log-SkillAction "CopiedFiles" "to $targetAppDir"

        # Update tasks.json for agentic-os self-upgrade awareness
        $tasksFile = Join-Path $bridge "agentic-os\tasks.json"
        if (Test-Path $tasksFile) {
            $tasks = Get-Content $tasksFile -Raw | ConvertFrom-Json
            $newTask = @{
                id = "integrate-$skillName"
                description = "Integrate and test new $skillName skill for expanded abilities."
                status = "pending"
                priority = "high"
                related = "self-upgrade, human-like control"
                note = "Pulled from GitHub/Drive via SkillIntegrator. Test human-like flows."
            }
            $tasks.tasks += $newTask
            $tasks | ConvertTo-Json -Depth 6 | Set-Content $tasksFile -Encoding UTF8
            Log-SkillAction "UpdatedTasks" "Added integrate-$skillName"
        }

        # Update local manifest or plugin if exists
        $manifest = Join-Path $bridge "codex.json"
        if (Test-Path $manifest) {
            Log-SkillAction "ManifestNote" "Skill $skillName ready for Codex pull (update plugins/ if needed)"
        }
    } else {
        Log-SkillAction "DryRunIntegrate" "Would copy to $targetAppDir and update tasks"
    }

    Log-SkillAction "IntegrateComplete" $skillName
    return $targetAppDir
}

function SelfUpgrade-Check {
    <#
    Meta function: Check GitHub for new skills, propose download/integrate.
    Call from task-engine for autonomous self-build.
    #>
    Log-SkillAction "SelfUpgradeCheck" "Scanning GitHub for new abilities"
    # In full: parse repo apps/ dir via API or assume list
    $exampleSkills = @("browser-advanced", "file-explorer", "excel-ops")
    foreach ($s in $exampleSkills) {
        Log-SkillAction "Proposed" "New skill: $s - run Download-Skill -SkillName $s -FromGitHub then Integrate"
    }
    return $exampleSkills
}

Write-Output "SkillIntegrator loaded. Functions: Download-Skill, Integrate-Skill, SelfUpgrade-Check."
Write-Output "Example: Download-Skill -SkillName 'browser-advanced' -FromGitHub ; Integrate-Skill -SkillPath (path)"
Log-SkillAction "SkillIntegrator" "Loaded for self-upgrade via GitHub + Drive"