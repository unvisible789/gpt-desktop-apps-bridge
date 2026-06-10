# BRIDGE_VISION.ps1
# UIA (FlaUI) based vision / element finding for Grok desktop bridge
# Combines reliable element location with human-like mouse movement from BRIDGE_HELPERS

$assembliesDir = "$env:USERPROFILE\GrokBridgeAssets\assemblies"

function Load-FlaUI {
    param([switch]$Force)
    
    if (-not $Force -and (Get-Command Get-UIElementByName -ErrorAction SilentlyContinue)) {
        Write-Host "[VISION] FlaUI already loaded." -ForegroundColor Green
        return
    }

    $coreDll = Join-Path $assembliesDir "FlaUI.Core.dll"
    $uia3Dll = Join-Path $assembliesDir "FlaUI.UIA3.dll"

    if (-not (Test-Path $coreDll) -or -not (Test-Path $uia3Dll)) {
        Write-Warning "FlaUI assemblies not found. Run Setup-FlaUI.ps1 first."
        return $false
    }

    try {
        Add-Type -Path $coreDll -ErrorAction Stop
        Add-Type -Path $uia3Dll -ErrorAction Stop
        Write-Host "[VISION] FlaUI loaded successfully." -ForegroundColor Green
        return $true
    } catch {
        Write-Error "Failed to load FlaUI: $_"
        return $false
    }
}

function Get-UIElementByName {
    param(
        [Parameter(Mandatory)] [string] $Name,
        [string] $ProcessName = "*",
        [int] $TimeoutMs = 5000
    )

    if (-not (Load-FlaUI)) { return $null }

    $automation = [FlaUI.UIA3.UIA3Automation]::new()
    $desktop = $automation.GetDesktop()

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    while ($stopwatch.ElapsedMilliseconds -lt $TimeoutMs) {
        $elements = $desktop.FindAllDescendants(
            [FlaUI.Core.Conditions.ConditionFactory]::new().ByName($Name)
        )
        if ($elements.Count -gt 0) {
            # Return first match (can be improved with better filtering)
            return $elements[0]
        }
        Start-Sleep -Milliseconds 200
    }
    Write-Warning "Element with name '$Name' not found within timeout."
    return $null
}

function Get-ElementRect {
    param([Parameter(Mandatory)] $Element)

    if ($null -eq $Element) { return $null }
    $bounds = $Element.BoundingRectangle
    return [PSCustomObject]@{
        Left   = $bounds.Left
        Top    = $bounds.Top
        Width  = $bounds.Width
        Height = $bounds.Height
        CenterX = [math]::Round($bounds.Left + $bounds.Width / 2)
        CenterY = [math]::Round($bounds.Top + $bounds.Height / 2)
    }
}

function Click-UIElement {
    param(
        [Parameter(Mandatory)] $Element,
        [string] $Button = "Left"
    )

    $rect = Get-ElementRect -Element $Element
    if ($null -eq $rect) { return }

    # Use existing human-like functions from BRIDGE_HELPERS
    if (Get-Command Click-HumanLike -ErrorAction SilentlyContinue) {
        Click-HumanLike -X $rect.CenterX -Y $rect.CenterY -Button $Button
    } else {
        # Fallback to direct FlaUI click
        $Element.Click()
        Log-HumanAction "ClickUIElement (fallback)" "$($Element.Name) at ($($rect.CenterX), $($rect.CenterY))"
    }
}

function FindAndClickByText {
    param(
        [Parameter(Mandatory)] [string] $SearchText,
        [int] $TimeoutMs = 8000
    )

    Write-Host "[VISION] Searching for element containing '$SearchText'..." -ForegroundColor Yellow
    $element = Get-UIElementByName -Name $SearchText -TimeoutMs $TimeoutMs

    if ($element) {
        Click-UIElement -Element $element
        Log-HumanAction "FindAndClickByText" "Found and clicked '$SearchText'"
        return $true
    } else {
        Write-Warning "Could not find element with text '$SearchText'"
        return $false
    }
}

# Auto-load when dot-sourced (optional)
# Load-FlaUI | Out-Null

Write-Host "[BRIDGE_VISION] UIA vision module loaded. Use FindAndClickByText or Get-UIElementByName." -ForegroundColor Cyan
