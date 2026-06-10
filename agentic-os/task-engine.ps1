# agentic-os/task-engine.ps1
# Core task scheduler / executor for the Grok desktop bridge agentic system.
# Loads tasks from tasks.json (local or repo), supports self-upgrade actions via SkillIntegrator.
# Part of Phase 4 in SELF_UPGRADE_PLAN.md.

$ErrorActionPreference = 'Continue'

$LocalBase = "$env:USERPROFILE\GrokBridgeAssets"
$TasksFile = Join-Path $LocalBase "tasks.json"
$ActionLog = Join-Path $LocalBase "HUMAN_ACTION.log"
$RepoRawTasks = "https://raw.githubusercontent.com/unvisible789/gpt-desktop-apps-bridge/main/tasks.json"

function Log-Action {
    param([string]$Action, [string]$Details = "")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$ts] $Action | $Details"
    Add-Content -Path $ActionLog -Value $line -ErrorAction SilentlyContinue
    Write-Host $line -ForegroundColor Gray
}

function Load-Tasks {
    if (Test-Path $TasksFile) {
        try { return (Get-Content $TasksFile -Raw | ConvertFrom-Json).tasks }
        catch { Write-Warning "Local tasks.json corrupt, falling back..." }
    }
    # Fallback: pull from GitHub (simple)
    try {
        $raw = Invoke-WebRequest -Uri $RepoRawTasks -UseBasicParsing | Select-Object -ExpandProperty Content
        $json = $raw | ConvertFrom-Json
        return $json.tasks
    } catch {
        Write-Warning "Could not load tasks from repo either."
        return @()
    }
}

function Get-EnabledTasks {
    $all = Load-Tasks
    return $all | Where-Object { $_.enabled -ne $false } | Sort-Object priority
}

function Invoke-Task {
    param(
        [Parameter(Mandatory)][string]$TaskId,
        [hashtable]$Params = @{}
    )
    $tasks = Load-Tasks
    $task = $tasks | Where-Object { $_.id -eq $TaskId }
    if (-not $task) { Write-Warning "Task not found: $TaskId"; return $false }

    Log-Action "START_TASK" "$TaskId ($($task.type))"

    switch ($task.type) {
        "self-upgrade" {
            # Wire to SkillIntegrator
            if (-not (Get-Command -Name Sync-BridgeFromGitHub -ErrorAction SilentlyContinue)) {
                $integrator = Join-Path "$LocalBase\bridge" "SkillIntegrator.ps1"
                if (Test-Path $integrator) { . $integrator }
            }
            if ($TaskId -eq "sync-skills-from-github") {
                $inc = $task.params.IncludeApps; if ($null -eq $inc) { $inc = $false }
                Sync-BridgeFromGitHub -IncludeApps:$inc
            } elseif ($TaskId -eq "integrate-new-app") {
                $app = $Params.AppName; if (-not $app) { $app = Read-Host "App name to integrate (e.g. browser-advanced)" }
                Integrate-Skill -SkillName $app
            } elseif ($TaskId -eq "self-reflect-and-propose-upgrade") {
                Log-Action "REFLECT" "Reading recent logs for improvement ideas..."
                # Placeholder: in full version read last N lines of HUMAN_ACTION.log + SYNC_LOG and suggest
                Write-Host "(Self-reflection stub) Consider: improve mouse precision, add OCR, expand durable controls." -ForegroundColor Yellow
            }
        }
        "app" {
            $appName = $task.app
            $control = Join-Path "$LocalBase\apps\$appName" "$appName-HumanControl.ps1"
            if (Test-Path $control) {
                . $control
                # Convention: each app module exposes e.g. Invoke-AppTask or specific functions
                if (Get-Command -Name "Invoke-$appName-Task" -ErrorAction SilentlyContinue) {
                    & "Invoke-$appName-Task" -TaskId $TaskId @Params
                } else {
                    Log-Action "APP_LOADED" "$appName (no Invoke- wrapper yet - manual use of its functions recommended)"
                }
            } else {
                Write-Warning "App control not found locally for $appName. Run Integrate-Skill or Sync first."
                Log-Action "APP_MISSING" $appName
            }
        }
        "bridge" {
            # Direct bridge primitive test tasks
            if (-not (Get-Command -Name Move-MouseHumanLike -ErrorAction SilentlyContinue)) {
                $helpers = Join-Path "$LocalBase\bridge" "BRIDGE_HELPERS.ps1"
                if (Test-Path $helpers) { . $helpers }
            }
            Log-Action "BRIDGE_PRIMITIVE" $TaskId
            # Example: could call specific test functions here
        }
        "meta" {
            Log-Action "META" $task.description
        }
        default {
            Log-Action "UNKNOWN_TYPE" $TaskId
        }
    }

    Log-Action "END_TASK" $TaskId
    return $true
}

function Add-SelfUpgradeTasks {
    # Helper to ensure core self-upgrade tasks exist in local tasks.json
    Write-Host "(Stub) In full implementation this would merge self-upgrade tasks into local tasks.json" -ForegroundColor DarkGray
}

function Start-AgenticLoop {
    param([int]$MaxIterations = 5)
    Write-Host "Starting simple agentic task loop (max $MaxIterations)..." -ForegroundColor Green
    $enabled = Get-EnabledTasks
    $i = 0
    foreach ($t in $enabled) {
        if ($i++ -ge $MaxIterations) { break }
        Invoke-Task -TaskId $t.id
        Start-Sleep -Milliseconds 800   # human-like pause between tasks
    }
    Log-Action "LOOP_COMPLETE" "Ran $($i) tasks"
}

# Auto-load on dot-source
Write-Host "[task-engine] Loaded. Use: Get-EnabledTasks | Invoke-Task -TaskId <id>   or   Start-AgenticLoop" -ForegroundColor Green
Log-Action "ENGINE_LOADED" "agentic-os/task-engine.ps1"
