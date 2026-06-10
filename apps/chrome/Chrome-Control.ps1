# Chrome-Control.ps1
# Chrome browser control module for Grok desktop bridge
# Uses human-like input + UIA vision for reliable browser automation

. "$PSScriptRoot\..\..\bridge\BRIDGE_HELPERS.ps1" -ErrorAction SilentlyContinue
. "$PSScriptRoot\..\..\bridge\BRIDGE_VISION.ps1" -ErrorAction SilentlyContinue

function Start-Chrome {
    param([string]$Url = "")
    
    if ($Url) {
        Start-Process "chrome.exe" -ArgumentList $Url
    } else {
        Start-Process "chrome.exe"
    }
    Start-Sleep -Seconds 2
    Focus-Chrome
    Log-HumanAction "StartChrome" $Url
}

function Focus-Chrome {
    $chrome = Get-Process chrome -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
    if ($chrome) {
        $null = [Win32]::SetForegroundWindow($chrome.MainWindowHandle)  # Requires Win32 helper or use FlaUI
        Start-Sleep -Milliseconds 300
        Log-HumanAction "FocusChrome"
    } else {
        Write-Warning "Chrome not running or no main window found."
    }
}

function Navigate-To {
    param([Parameter(Mandatory)] [string] $Url)
    
    Focus-Chrome
    # Click address bar (common hotkey or position)
    # Best: Use Ctrl+L to focus address bar
    [System.Windows.Forms.SendKeys]::SendWait("^l")  # Ctrl + L
    Wait-Human -MinMs 150 -MaxMs 300
    
    Type-HumanLike $Url
    Wait-Human -MinMs 100 -MaxMs 200
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    
    Log-HumanAction "NavigateTo" $Url
    Start-Sleep -Seconds 1.5   # Give page time to load
}

function Search-Google {
    param([Parameter(Mandatory)] [string] $Query)
    
    Navigate-To "https://www.google.com"
    Wait-Human -MinMs 400 -MaxMs 800
    
    # Type in Google search box (usually focused on homepage)
    Type-HumanLike $Query
    Wait-Human
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    Log-HumanAction "GoogleSearch" $Query
}

function Click-LinkByText {
    param([Parameter(Mandatory)] [string] $LinkText)
    
    if (Get-Command FindAndClickByText -ErrorAction SilentlyContinue) {
        $success = FindAndClickByText -SearchText $LinkText -TimeoutMs 6000
        if ($success) {
            Log-HumanAction "ClickLink" $LinkText
            return $true
        }
    }
    
    Write-Warning "UIA FindAndClickByText not available or failed for '$LinkText'"
    return $false
}

function TypeInPage {
    param([Parameter(Mandatory)] [string] $Text)
    
    # Assumes focus is already on an input field
    Type-HumanLike $Text
    Log-HumanAction "TypeInPage" $Text
}

function CloseCurrentTab {
    Focus-Chrome
    [System.Windows.Forms.SendKeys]::SendWait("^w")  # Ctrl + W
    Log-HumanAction "CloseTab"
}

Write-Host "[Chrome-Control] Chrome automation module loaded. Functions: Start-Chrome, Navigate-To, Search-Google, Click-LinkByText" -ForegroundColor Green
