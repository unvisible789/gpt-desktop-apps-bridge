<#
.SYNOPSIS
Human-like File Explorer control for desktop file ops.
Adds versatility: navigate, select, drag, rename with natural pacing.

Complements other skills. Use with vision for precise targeting.
#>

. .\BRIDGE_HELPERS.ps1
. .\BRIDGE_VISION.ps1

function Explorer-Open {
    param([string]$Path = "C:\Users\Owner")
    Log-HumanAction "Explorer-Open" $Path
    Start-Process explorer.exe $Path
    Wait-ForWindow -TitlePattern "File Explorer" -TimeoutSeconds 5
    Wait-Human -MinMs 200 -MaxMs 400
}

function Explorer-Navigate {
    param([string]$FolderName)
    Log-HumanAction "Explorer-Navigate" $FolderName
    # Human-like: use address bar (Ctrl+L), type path
    Send-KeyCombo @("^{l}")
    Wait-Human
    Send-HumanLikeText -Text $FolderName
    Send-HumanLikeText -Text "{ENTER}"
    Wait-Human -MinMs 300 -MaxMs 600
}

function Explorer-SelectAndDrag {
    param([string]$ItemName, [int]$TargetX, [int]$TargetY)
    Log-HumanAction "Explorer-SelectAndDrag" "$ItemName to ($TargetX,$TargetY)"
    # Use vision to find item
    Write-BridgeVision -WithUI | Out-Null
    $point = Get-ClickPointForText -SearchText $ItemName -Fuzzy
    if ($point) {
        Click-HumanLike -X $point.X -Y $point.Y  # select
        Wait-Human
        Drag-HumanLike -StartX $point.X -StartY $point.Y -EndX $TargetX -EndY $TargetY
    } else {
        Write-Output "Item not found via vision; falling back to keys"
        Send-HumanLikeText -Text $ItemName
        Wait-Human
        Send-KeyCombo @("{ENTER}")
    }
}

function Explorer-Rename {
    param([string]$OldName, [string]$NewName)
    Log-HumanAction "Explorer-Rename" "$OldName -> $NewName"
    Write-BridgeVision -WithUI | Out-Null
    $point = Get-ClickPointForText -SearchText $OldName -Fuzzy
    if ($point) {
        Click-HumanLike -X $point.X -Y $point.Y
        Wait-Human
        Send-KeyCombo @("{F2}")
        Wait-Human
        Send-HumanLikeText -Text $NewName
        Send-HumanLikeText -Text "{ENTER}"
    }
}

Write-Output "FileExplorer human control loaded. Human-like nav, drag, rename."