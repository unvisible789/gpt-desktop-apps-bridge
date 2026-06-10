# Playwright-Integration.ps1
# Allows the PowerShell bridge to call Playwright (Python) scripts for advanced browser automation
# Especially useful for MetaMask, dApps, complex sites, and stealth operations

$ErrorActionPreference = 'Stop'

$playwrightDir = "$env:USERPROFILE\GrokBridgeAssets\bridge\playwright"

function Invoke-PlaywrightScript {
    param(
        [Parameter(Mandatory)][string]$ScriptName,
        [hashtable]$Arguments = @{},
        [switch]$ShowOutput
    )

    $scriptPath = Join-Path $playwrightDir "$ScriptName.py"

    if (-not (Test-Path $scriptPath)) {
        Write-Error "Playwright script not found: $scriptPath"
        return
    }

    # Build argument string
    $argList = @()
    foreach ($key in $Arguments.Keys) {
        $argList += "--$key=$($Arguments[$key])"
    }

    Write-Host "[Playwright] Running $ScriptName..." -ForegroundColor Cyan

    if ($ShowOutput) {
        python $scriptPath @argList
    } else {
        $output = python $scriptPath @argList 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Playwright script exited with code $LASTEXITCODE"
        }
        return $output
    }
}

function Test-PlaywrightSetup {
    Write-Host "Checking Playwright Python setup..." -ForegroundColor Yellow
    
    try {
        $pythonCheck = python --version 2>&1
        Write-Host "Python found: $pythonCheck" -ForegroundColor Green
    } catch {
        Write-Error "Python not found in PATH. Please install Python 3.10+ and add to PATH."
        return $false
    }

    try {
        python -c "import playwright; print('Playwright Python package found')" 2>&1
    } catch {
        Write-Warning "Playwright not installed. Run: pip install playwright && playwright install chromium"
        return $false
    }

    Write-Host "[Playwright] Setup looks good!" -ForegroundColor Green
    return $true
}

Write-Host "[Playwright-Integration] Loaded. Use Invoke-PlaywrightScript to run advanced automation." -ForegroundColor Cyan
