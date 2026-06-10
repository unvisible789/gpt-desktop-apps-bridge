<#
.SYNOPSIS
General desktop human-like control for expanded abilities (file ops, alt-tab, clipboard, etc.).
Complements Chrome/Notepad. Uses bridge primitives for human-like execution.

This is a "self-built" skill example: can be downloaded/integrated via SkillIntegrator from GitHub.
#>

. .\BRIDGE_HELPERS.ps1
. .\BRIDGE_VISION.ps1

function Desktop-AltTab {
    param([int]$Times = 1)
    Log-HumanAction "Desktop-AltTab" "Switching $Times times"
    for ($i=0; $i -lt $Times; $i++) {
        Send-KeyCombo @("{ALT}", "{TAB}")
        Wait-Human -MinMs 150 -MaxMs 400  # human decision pause
    }
}

function Desktop-ClipboardCopy {
    param([string]$TextToCopy)
    Log-HumanAction "Desktop-ClipboardCopy" "Copying text"
    # Simulate select all + copy human-like
    Send-KeyCombo @("^{a}")
    Wait-Human
    Send-KeyCombo @("^{c}")
    # For actual, could set clipboard but keep SendKeys for human sim
    [System.Windows.Forms.Clipboard]::SetText($TextToCopy) | Out-Null
    Log-HumanAction "ClipboardSet" "Text copied to clipboard"
}

function Desktop-FileOp {
    param([string]$Action = "copy", [string]$Source, [string]$Dest)
    Log-HumanAction "Desktop-FileOp" "$Action $Source to $Dest"
    # Human-like: open explorer, navigate (via keys or vision), drag
    Start-Process explorer.exe
    Wait-ForWindow -TitlePattern "File Explorer" -TimeoutSeconds 5
    Wait-Human
    # Simplified: use PS for actual, but wrap with human delays for sim
    if ($Action -eq "copy") {
        Copy-Item $Source $Dest -Force
    } elseif ($Action -eq "move") {
        Move-Item $Source $Dest -Force
    }
    Wait-Human -MinMs 300 -MaxMs 600
    Log-HumanAction "FileOpComplete" "$Action done"
}

function Desktop-ContextMenu {
    param([int]$X, [int]$Y)
    Log-HumanAction "Desktop-ContextMenu" "Right-click at ($X,$Y)"
    Click-HumanLike -X $X -Y $Y -RightClick
    Wait-Human
}

Write-Output "Desktop-General human control loaded. Adds versatility for file, window, clipboard ops."