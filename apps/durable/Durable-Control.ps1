# Durable-Control.ps1
# Control module for Durable.co AI website builder
# Focused on blog updates, site changes, and content management

$ErrorActionPreference = 'Continue'

$bridgeRoot = "$env:USERPROFILE\GrokBridgeAssets\bridge"
. "$bridgeRoot\BRIDGE_HELPERS.ps1" -ErrorAction SilentlyContinue
. "$bridgeRoot\BRIDGE_VISION.ps1" -ErrorAction SilentlyContinue
. "$PSScriptRoot\..\chrome\Chrome-Control.ps1" -ErrorAction SilentlyContinue

# ==================== LOGIN & NAVIGATION ====================

function Login-To-Durable {
    param(
        [string]$Email = "",
        [string]$Password = ""
    )

    Navigate-To "https://durable.co/login"
    Wait-ForPageLoad 3

    # Try to find and fill email field
    if (Get-Command Fill-InputByLabel -ErrorAction SilentlyContinue) {
        Fill-InputByLabel "Email" $Email
        Wait-Human
        Fill-InputByLabel "Password" $Password
    } else {
        # Fallback
        Type-HumanLike $Email
        [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
        Type-HumanLike $Password
    }

    Wait-Human
    Click-ButtonByText "Log in" -TimeoutMs 5000
    Wait-ForPageLoad 5
    Log-HumanAction "LoginDurable" $Email
}

function Open-MySite {
    param([string]$SiteName = "Roofinghut")

    Focus-Chrome
    # Go to sites dashboard
    Navigate-To "https://durable.co/sites"
    Wait-ForPageLoad 3

    # Click on the site card
    if (Get-Command Click-LinkByText -ErrorAction SilentlyContinue) {
        Click-LinkByText $SiteName
    }
    Wait-ForPageLoad 4
    Log-HumanAction "OpenSite" $SiteName
}

# ==================== BLOG MANAGEMENT ====================

function GoTo-BlogSection {
    Focus-Chrome
    # Durable usually has a Blog or Content section in the left menu
    if (Get-Command Click-LinkByText -ErrorAction SilentlyContinue) {
        Click-LinkByText "Blog" -TimeoutMs 5000
        Start-Sleep -Seconds 2
    }
    Log-HumanAction "GoToBlog"
}

function Create-NewBlogPost {
    param(
        [Parameter(Mandatory)][string]$Title,
        [string]$Content = ""
    )

    GoTo-BlogSection
    Wait-Human

    # Click "New post" or "Create blog post" button
    if (Get-Command Click-ButtonByText -ErrorAction SilentlyContinue) {
        Click-ButtonByText "New post" -TimeoutMs 5000
        Start-Sleep -Seconds 2
    }

    # Fill in title
    if (Get-Command Fill-InputByLabel -ErrorAction SilentlyContinue) {
        Fill-InputByLabel "Title" $Title
    } else {
        Type-HumanLike $Title
    }

    Wait-Human

    # If content is provided, try to paste it into the editor
    if ($Content) {
        # Click into the editor area (often needs a specific click)
        # This part may need tuning based on Durable's current UI
        Type-HumanLike $Content
    }

    Log-HumanAction "CreateBlogPost" $Title
}

function Update-BlogPost {
    param(
        [Parameter(Mandatory)][string]$PostTitle,
        [string]$NewContent = ""
    )

    GoTo-BlogSection
    Wait-Human

    # Click on the existing post
    if (Get-Command Click-LinkByText -ErrorAction SilentlyContinue) {
        Click-LinkByText $PostTitle
        Start-Sleep -Seconds 2
    }

    # Click edit if needed
    Click-ButtonByText "Edit" -TimeoutMs 4000

    if ($NewContent) {
        # Clear existing content and type new (simplified)
        Type-HumanLike $NewContent
    }

    Log-HumanAction "UpdateBlogPost" $PostTitle
}

function Publish-BlogPost {
    Click-ButtonByText "Publish" -TimeoutMs 5000
    Wait-Human
    Log-HumanAction "PublishBlogPost"
}

# ==================== GENERAL SITE CHANGES ====================

function Edit-Page {
    param([string]$PageName = "Home")

    Focus-Chrome
    # Go to Pages section
    if (Get-Command Click-LinkByText -ErrorAction SilentlyContinue) {
        Click-LinkByText "Pages"
        Start-Sleep -Seconds 2
        Click-LinkByText $PageName
    }
    Log-HumanAction "EditPage" $PageName
}

function Make-SiteChange {
    param(
        [string]$Description = ""
    )
    # Placeholder for more advanced site editing
    # Can be expanded with specific element targeting
    Write-Host "[Durable] Site change requested: $Description" -ForegroundColor Yellow
    Log-HumanAction "SiteChangeRequested" $Description
}

Write-Host "[Durable-Control] Durable management module loaded. Focused on blog updates and site changes." -ForegroundColor Green
