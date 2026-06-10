<#
.SYNOPSIS
Human-like Outlook/Email control.
For composing, sending, navigating emails with natural delays.
Useful for outreach in money plan (after approval).

Template generated via SelfBuildTemplate for self-upgrade.
#>

. .\BRIDGE_HELPERS.ps1
. .\BRIDGE_VISION.ps1

function Outlook-Open {
    param([string]$Folder = "Inbox")
    Log-HumanAction "Outlook-Open" $Folder
    Start-Process outlook.exe
    Wait-ForWindow -TitlePattern "Outlook" -TimeoutSeconds 10
    Wait-Human -MinMs 500 -MaxMs 1000
    # Simulate navigating to folder
    Send-HumanLikeText -Text $Folder
    Wait-Human
}

function Outlook-ComposeAndSend {
    param([string]$To, [string]$Subject, [string]$Body)
    Log-HumanAction "Outlook-ComposeAndSend" "To: $To"
    Send-KeyCombo @("^{n}")  # New email
    Wait-Human -MinMs 300 -MaxMs 600
    Send-HumanLikeText -Text $To
    Send-KeyCombo @("{TAB}")
    Send-HumanLikeText -Text $Subject -AddHesitation
    Send-KeyCombo @("{TAB}")
    Send-HumanLikeText -Text $Body -AddHesitation
    Wait-Human
    Send-KeyCombo @("^{ENTER}")  # Send
    Log-HumanAction "EmailSent" "Subject: $Subject"
}

function Outlook-ReadAndReply {
    param([string]$SearchText)
    Log-HumanAction "Outlook-ReadAndReply" $SearchText
    # Use vision to "find" email
    Write-BridgeVision -WithUI | Out-Null
    # Assume click on item
    Send-HumanLikeText -Text $SearchText
    Wait-Human
    Send-KeyCombo @("{ENTER}")
    Wait-Human -MinMs 400 -MaxMs 800
    Send-KeyCombo @("^{r}")  # Reply
    Wait-Human
    Send-HumanLikeText -Text "Thanks for the info. " -AddHesitation
    Send-KeyCombo @("^{ENTER}")
}

Write-Output "Outlook human control loaded. Compose, send, reply with human-like behavior."