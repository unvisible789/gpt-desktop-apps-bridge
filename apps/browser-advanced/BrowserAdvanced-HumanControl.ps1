<#
.SYNOPSIS
Advanced human-like browser control (beyond basic Chrome).
For tabs, forms, devtools, multi-page flows with vision for accuracy.
Builds on Chrome module for versatility.

Example: Open multiple tabs, fill forms with human typing, scroll to find elements.
#>

. .\BRIDGE_HELPERS.ps1
. .\BRIDGE_VISION.ps1

function Browser-OpenTabs {
    param([string[]]$Urls)
    Log-HumanAction "Browser-OpenTabs" "Opening $($Urls.Count) tabs"
    foreach ($url in $Urls) {
        Send-KeyCombo @("^{t}")
        Wait-Human
        Send-HumanLikeText -Text $url
        Send-HumanLikeText -Text "{ENTER}"
        Wait-Human -MinMs 400 -MaxMs 800  # page load "thinking" pause
    }
}

function Browser-FillForm {
    param([hashtable]$Fields)  # e.g. @{ "username" = "user"; "password" = "pass" }
    Log-HumanAction "Browser-FillForm" "Filling $($Fields.Count) fields"
    foreach ($field in $Fields.GetEnumerator()) {
        Write-BridgeVision -WithUI | Out-Null
        $point = Get-ClickPointForText -SearchText $field.Key -Fuzzy
        if ($point) {
            Click-HumanLike -X $point.X -Y $point.Y
            Wait-Human
            Send-HumanLikeText -Text $field.Value -AddHesitation
            Wait-Human
        } else {
            # Fallback: tab to field
            Send-KeyCombo @("{TAB}")
            Send-HumanLikeText -Text $field.Value
        }
    }
    Send-HumanLikeText -Text "{ENTER}"
}

function Browser-ScrollAndClick {
    param([string]$TargetText)
    Log-HumanAction "Browser-ScrollAndClick" $TargetText
    for ($i=0; $i -lt 5; $i++) {  # scroll up to 5 times
        Scroll-HumanLike -Clicks 3 -Direction "Down"
        Write-BridgeVision -WithUI | Out-Null
        $point = Get-ClickPointForText -SearchText $TargetText -Fuzzy
        if ($point) {
            Click-HumanLike -X $point.X -Y $point.Y
            return $true
        }
    }
    Write-Output "Target not found after scrolling"
    return $false
}

function Browser-DevTools {
    Log-HumanAction "Browser-DevTools" "Opening DevTools"
    Send-KeyCombo @("{F12}")
    Wait-Human -MinMs 300 -MaxMs 600
    # Example: inspect element
    Send-KeyCombo @("^{Shift}{C}")  # inspect
}

Write-Output "BrowserAdvanced human control loaded. Advanced tabs, forms, scroll+click, devtools."