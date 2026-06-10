# Chrome-Control.ps1
# Comprehensive Chrome / Browser control module for Grok desktop bridge
# Human-like + UIA powered automation (Codex-style capabilities)

$ErrorActionPreference = 'Continue'

# Load dependencies
$bridgeRoot = "$env:USERPROFILE\GrokBridgeAssets\bridge"
. "$bridgeRoot\BRIDGE_HELPERS.ps1" -ErrorAction SilentlyContinue
. "$bridgeRoot\BRIDGE_VISION.ps1" -ErrorAction SilentlyContinue

# ==================== BASIC CONTROL ====================

function Start-Chrome {
    param([string]$Url = "")
    if ($Url) { Start-Process chrome.exe $Url } else { Start-Process chrome.exe }
    Start-Sleep -Seconds 2.5
    Focus-Chrome
    Log-HumanAction "StartChrome" $Url
}

function Focus-Chrome {
    $proc = Get-Process chrome -ErrorAction SilentlyContinue | Where-Object MainWindowHandle -ne 0 | Select-Object -First 1
    if ($proc) {
        (New-Object -ComObject WScript.Shell).AppActivate($proc.MainWindowTitle) | Out-Null
        Start-Sleep -Milliseconds 350
        Log-HumanAction "FocusChrome"
    }
}

# ==================== NAVIGATION ====================

function Navigate-To {
    param([Parameter(Mandatory)][string]$Url)
    Focus-Chrome
    [System.Windows.Forms.SendKeys]::SendWait("^l")
    Wait-Human -MinMs 120 -MaxMs 280
    Type-HumanLike $Url
    Wait-Human -MinMs 80 -MaxMs 180
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    Log-HumanAction "NavigateTo" $Url
    Start-Sleep -Seconds 1.8
}

function Search-Google {
    param([Parameter(Mandatory)][string]$Query)
    Navigate-To "https://www.google.com"
    Wait-Human -MinMs 450 -MaxMs 850
    Type-HumanLike $Query
    Wait-Human
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    Log-HumanAction "GoogleSearch" $Query
}

function Refresh-Page {
    Focus-Chrome
    [System.Windows.Forms.SendKeys]::SendWait("{F5}")
    Log-HumanAction "RefreshPage"
}

# ==================== TABS ====================

function New-Tab {
    param([string]$Url = "")
    Focus-Chrome
    [System.Windows.Forms.SendKeys]::SendWait("^t")
    Wait-Human -MinMs 200 -MaxMs 400
    if ($Url) { Navigate-To $Url }
    Log-HumanAction "NewTab" $Url
}

function Close-CurrentTab {
    Focus-Chrome
    [System.Windows.Forms.SendKeys]::SendWait("^w")
    Log-HumanAction "CloseTab"
}

function Switch-To-Tab {
    param([int]$TabNumber = 1)
    Focus-Chrome
    if ($TabNumber -le 8) {
        [System.Windows.Forms.SendKeys]::SendWait("^$TabNumber")
    }
    Log-HumanAction "SwitchTab" $TabNumber
}

function Close-AllTabs {
    Focus-Chrome
    [System.Windows.Forms.SendKeys]::SendWait("^w")
    Log-HumanAction "CloseAllTabs"
}

# ==================== SCROLLING (Human-like) ====================

function Scroll-Down {
    param([int]$Times = 3)
    Focus-Chrome
    for ($i = 0; $i -lt $Times; $i++) {
        [System.Windows.Forms.SendKeys]::SendWait("{PGDN}")
        Wait-Human -MinMs 180 -MaxMs 420
    }
    Log-HumanAction "ScrollDown" $Times
}

function Scroll-Up {
    param([int]$Times = 3)
    Focus-Chrome
    for ($i = 0; $i -lt $Times; $i++) {
        [System.Windows.Forms.SendKeys]::SendWait("{PGUP}")
        Wait-Human -MinMs 180 -MaxMs 420
    }
    Log-HumanAction "ScrollUp" $Times
}

# ==================== ELEMENT INTERACTION (UIA Powered) ====================

function Click-LinkByText {
    param([Parameter(Mandatory)][string]$LinkText, [int]$TimeoutMs = 7000)
    if (Get-Command FindAndClickByText -ErrorAction SilentlyContinue) {
        $success = FindAndClickByText -SearchText $LinkText -TimeoutMs $TimeoutMs
        if ($success) { Log-HumanAction "ClickLink" $LinkText; return $true }
    }
    Write-Warning "Could not click link: $LinkText"
    return $false
}

function Click-ButtonByText {
    param([Parameter(Mandatory)][string]$ButtonText, [int]$TimeoutMs = 6000)
    if (Get-Command FindAndClickByText -ErrorAction SilentlyContinue) {
        return FindAndClickByText -SearchText $ButtonText -TimeoutMs $TimeoutMs
    }
    return $false
}

function Type-In-Field {
    param([Parameter(Mandatory)][string]$Text)
    Type-HumanLike $Text
    Log-HumanAction "TypeInField" $Text
}

# ==================== FORM FILLING ====================

function Fill-InputByLabel {
    param(
        [Parameter(Mandatory)][string]$LabelText,
        [Parameter(Mandatory)][string]$Value
    )
    if (Get-Command FindAndClickByText -ErrorAction SilentlyContinue) {
        FindAndClickByText -SearchText $LabelText -TimeoutMs 5000 | Out-Null
        Wait-Human -MinMs 200 -MaxMs 400
    }
    Type-HumanLike $Value
    Log-HumanAction "FillInput" "$LabelText = $Value"
}

# ==================== UTILITIES ====================

function Wait-ForPageLoad {
    param([int]$Seconds = 3)
    Start-Sleep -Seconds $Seconds
    Log-HumanAction "WaitPageLoad" $Seconds
}

function Take-Screenshot {
    param([string]$FileName = "chrome-screenshot.png")
    $path = "$env:USERPROFILE\GrokBridgeAssets\screenshots\$FileName"
    New-Item -ItemType Directory -Path (Split-Path $path) -Force | Out-Null
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $bitmap = New-Object System.Drawing.Bitmap $screen.Width, $screen.Height
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.CopyFromScreen($screen.Location, [System.Drawing.Point]::Empty, $screen.Size)
    $bitmap.Save($path)
    $graphics.Dispose()
    $bitmap.Dispose()
    Log-HumanAction "Screenshot" $path
    return $path
}

Write-Host "[Chrome-Control] Comprehensive Chrome module loaded. Ready for advanced browser automation." -ForegroundColor Green
