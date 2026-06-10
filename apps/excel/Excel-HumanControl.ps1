<#
.SYNOPSIS
Human-like Excel control for data entry, formulas, navigation.
Useful for money plan tracking, audits, etc.
Uses vision for cell targeting (approximate), SendKeys for human feel.
#>

. .\BRIDGE_HELPERS.ps1
. .\BRIDGE_VISION.ps1

function Excel-Open {
    param([string]$FilePath = "")
    Log-HumanAction "Excel-Open" $FilePath
    if ($FilePath) {
        Start-Process excel.exe $FilePath
    } else {
        Start-Process excel.exe
    }
    Wait-ForWindow -TitlePattern "Excel" -TimeoutSeconds 8
    Wait-Human -MinMs 300 -MaxMs 600
}

function Excel-NavigateToCell {
    param([string]$CellRef)  # e.g. "A1" or "B5"
    Log-HumanAction "Excel-NavigateToCell" $CellRef
    Send-KeyCombo @("^{g}")  # Go To
    Wait-Human
    Send-HumanLikeText -Text $CellRef
    Send-HumanLikeText -Text "{ENTER}"
    Wait-Human
}

function Excel-EnterData {
    param([string]$Data, [switch]$WithFormula)
    Log-HumanAction "Excel-EnterData" $Data
    if ($WithFormula -and -not $Data.StartsWith("=")) {
        $Data = "=" + $Data
    }
    Send-HumanLikeText -Text $Data -AddHesitation
    Send-HumanLikeText -Text "{ENTER}"
    Wait-Human -MinMs 100 -MaxMs 250
}

function Excel-SelectRange {
    param([string]$Range)  # e.g. "A1:B10"
    Log-HumanAction "Excel-SelectRange" $Range
    Send-KeyCombo @("^{g}")
    Wait-Human
    Send-HumanLikeText -Text $Range
    Send-HumanLikeText -Text "{ENTER}"
    Wait-Human
}

Write-Output "Excel human control loaded. Nav, data entry, ranges with human timing."