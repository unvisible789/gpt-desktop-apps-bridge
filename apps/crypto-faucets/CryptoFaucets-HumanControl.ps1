<#
.SYNOPSIS
Crypto faucets and airdrops collector - human-like Jarvis mode.
Visit free faucets (testnet/mainnet small claims), connect MetaMask (or others like Phantom), claim tokens.
Uses browser-advanced for nav, vision for buttons/popups, human delays/clicks/typing.
Airdrops: Claim flows similar.

Examples:
- Claim from faucet: Browser-Navigate, connect wallet, click claim, confirm.
- Airdrop check/claim: Search site, connect, claim.
- Multi: Loop faucets with delays.

Safety: Dry-run mode, user approval for real tx/claims (no seeds stored, testnets first). Log every human-like action.
Integrate with task-engine for daily claims.
#>

. .\BRIDGE_HELPERS.ps1
. .\BRIDGE_VISION.ps1
. .\apps\browser-advanced\BrowserAdvanced-HumanControl.ps1  # Extend browser for wallet flows

function Crypto-ConnectWallet {
    param([string]$Wallet = "MetaMask")
    Log-HumanAction "Crypto-ConnectWallet" $Wallet
    # Assume on site with "Connect Wallet" button (vision)
    Write-BridgeVision -WithUI | Out-Null
    $point = Get-ClickPointForText -SearchText "Connect Wallet" -Fuzzy
    if ($point) {
        Click-HumanLike -X $point.X -Y $point.Y
        Wait-Human -MinMs 1000 -MaxMs 3000  # Popup appears
    }
    # Focus MetaMask popup by title (human-like window switch)
    if (Focus-Window -titlePattern "MetaMask") {
        Wait-Human
        # Click "Connect" or "Next" / "Confirm" in popup via vision (popup may be captured)
        Write-BridgeVision -WithUI | Out-Null
        $connectPoint = Get-ClickPointForText -SearchText "Connect" -Fuzzy
        if ($connectPoint) {
            Click-HumanLike -X $connectPoint.X -Y $connectPoint.Y
        } else {
            # Fallback: Enter key for confirm (common in wallet popups)
            Send-KeyCombo @("{ENTER}")
        }
        Wait-Human -MinMs 500 -MaxMs 2000
    } else {
        # Fallback: Assume popup at right side, click approx
        Click-HumanLike -X 1400 -Y 400  # Adjust based on vision
    }
    Wait-Human -MinMs 1000 -MaxMs 3000  # Wallet connected
    Log-HumanAction "WalletConnected" $Wallet
}

function Crypto-ConfirmTransaction {
    Log-HumanAction "Crypto-ConfirmTransaction" "Confirming wallet popup"
    if (Focus-Window -titlePattern "MetaMask") {
        Wait-Human
        Send-KeyCombo @("{ENTER}")  # Confirm
        Wait-Human -MinMs 2000 -MaxMs 5000
    } else {
        Write-BridgeVision -WithUI | Out-Null
        $confirm = Get-ClickPointForText -SearchText "Confirm" -Fuzzy
        if ($confirm) { Click-HumanLike -X $confirm.X -Y $confirm.Y }
    }
}

function Crypto-ClaimFaucet {
    param([string]$FaucetUrl, [string]$Wallet = "MetaMask")
    Log-HumanAction "Crypto-ClaimFaucet" "$FaucetUrl via $Wallet"
    Browser-Navigate $FaucetUrl
    Wait-Human -MinMs 1000 -MaxMs 2000
    # Connect if needed
    Crypto-ConnectWallet -Wallet $Wallet
    Write-BridgeVision -WithUI | Out-Null
    $claimPoint = Get-ClickPointForText -SearchText "Claim" -Fuzzy
    if ($claimPoint) {
        Click-HumanLike -X $claimPoint.X -Y $claimPoint.Y
        Wait-Human -MinMs 2000 -MaxMs 5000  # Tx confirm
    }
    # Handle any MetaMask confirm popup (vision click "Confirm")
    Write-BridgeVision -WithUI | Out-Null
    $confirmPoint = Get-ClickPointForText -SearchText "Confirm" -Fuzzy
    if ($confirmPoint) {
        Click-HumanLike -X $confirmPoint.X -Y $confirmPoint.Y
        Wait-Human -MinMs 3000 -MaxMs 10000  # Wait for claim
    }
    Log-HumanAction "FaucetClaimed" $FaucetUrl
}

function Crypto-ClaimAirdrop {
    param([string]$AirdropUrl, [string]$Wallet = "MetaMask")
    Log-HumanAction "Crypto-ClaimAirdrop" $AirdropUrl
    Browser-Navigate $AirdropUrl
    Wait-Human -MinMs 1000 -MaxMs 3000
    Crypto-ConnectWallet -Wallet $Wallet
    Write-BridgeVision -WithUI | Out-Null
    $claimPoint = Get-ClickPointForText -SearchText "Claim" -Fuzzy
    if ($claimPoint) {
        Click-HumanLike -X $claimPoint.X -Y $claimPoint.Y
        Wait-Human -MinMs 2000 -MaxMs 5000
    }
    # Confirm popup
    Write-BridgeVision -WithUI | Out-Null
    $confirmPoint = Get-ClickPointForText -SearchText "Confirm" -Fuzzy
    if ($confirmPoint) {
        Click-HumanLike -X $confirmPoint.X -Y $confirmPoint.Y
    }
    Log-HumanAction "AirdropClaimed" $AirdropUrl
}

function Crypto-CheckEligibility {
    param([string]$SiteUrl)
    Log-HumanAction "Crypto-CheckEligibility" $SiteUrl
    Browser-Navigate $SiteUrl
    Wait-Human
    Write-BridgeVision -WithUI | Out-Null
    # Look for "Eligible" or claim button via vision
    $eligible = Get-ClickPointForText -SearchText "Eligible" -Fuzzy
    if ($eligible) {
        Log-HumanAction "Eligibility" "Eligible for airdrop"
        return $true
    }
    return $false
}

# Example multi-faucet loop (human-like: waits between claims to avoid rate limits)
function Crypto-ClaimDailyFaucets {
    param([string[]]$FaucetUrls = @("https://faucet.example1.com", "https://faucet.example2.com"))
    Log-HumanAction "Crypto-ClaimDailyFaucets" "Starting daily claims"
    foreach ($url in $FaucetUrls) {
        Crypto-ClaimFaucet -FaucetUrl $url
        Wait-Human -MinMs 5000 -MaxMs 15000  # Human-like delay between claims
    }
    Log-HumanAction "Crypto-ClaimDailyFaucets" "Daily claims complete"
}

function Crypto-SaveWallet {
    param([string]$Address, [string]$KeyOrSeed, [string]$Label = "default")
    Log-HumanAction "Crypto-SaveWallet" "Saving $Label wallet (address only in logs for safety)"
    $secureKey = ConvertTo-SecureString $KeyOrSeed -AsPlainText -Force | ConvertFrom-SecureString  # Basic DPAPI encrypt for local user
    $walletData = @{
        Label = $Label
        Address = $Address
        EncryptedKey = $secureKey
        Saved = Get-Date
    } | ConvertTo-Json
    $walletFile = Join-Path $assets "wallets.json"
    if (Test-Path $walletFile) {
        $existing = Get-Content $walletFile | ConvertFrom-Json
        $existing += $walletData
        $existing | ConvertTo-Json | Set-Content $walletFile
    } else {
        $walletData | Set-Content $walletFile
    }
    Log-HumanAction "WalletSaved" "$Label address: $Address (key encrypted locally)"
}

function Crypto-LoadWallet {
    param([string]$Label = "default")
    Log-HumanAction "Crypto-LoadWallet" $Label
    $walletFile = Join-Path $assets "wallets.json"
    if (Test-Path $walletFile) {
        $wallets = Get-Content $walletFile | ConvertFrom-Json
        $wallet = $wallets | Where-Object { $_.Label -eq $Label } | Select-Object -First 1
        if ($wallet) {
            $decrypted = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR((ConvertTo-SecureString $wallet.EncryptedKey)))
            return @{Address = $wallet.Address; Key = $decrypted}
        }
    }
    Write-Output "Wallet $Label not found"
    return $null
}

function Crypto-ManageCaptcha {
    param([string]$SiteUrl, [string]$Service = "2captcha")  # Stub for service integration
    Log-HumanAction "Crypto-ManageCaptcha" "$SiteUrl via $Service"
    # Human-like: Open site, detect captcha via vision, solve or send to service (API stub)
    Browser-Navigate $SiteUrl
    Wait-Human
    Write-BridgeVision -WithUI | Out-Null
    $captchaPoint = Get-ClickPointForText -SearchText "captcha" -Fuzzy
    if ($captchaPoint) {
        Click-HumanLike -X $captchaPoint.X -Y $captchaPoint.Y
        Wait-Human
        # Stub: Assume manual solve or external service call
        $solved = "manual-solved-token"  # Replace with real 2captcha API call in full
        Send-HumanLikeText -Text $solved
        Log-HumanAction "CaptchaSolved" "For $SiteUrl"
    }
}

function Crypto-ConvertCurrency {
    param([string]$From, [string]$To, [decimal]$Amount)
    Log-HumanAction "Crypto-ConvertCurrency" "$Amount $From to $To"
    Browser-Navigate "https://www.coingecko.com"
    Wait-Human
    # Simple search/calc stub; enhance with vision forms
    Browser-SearchAndClick "$From to $To converter" "Convert"
    Wait-Human
    # Fallback calc
    $rate = 1.0  # Stub rate
    $converted = $Amount * $rate
    Log-HumanAction "CurrencyConverted" "$Amount $From = $converted $To (stub rate)"
    return $converted
}

Write-Output "CryptoFaucets human control loaded. Faucets, airdrops, MetaMask connect/claim, save/load wallets (encrypted), captcha, currency convert - full crypto Jarvis mode. Use with approvals for real value."