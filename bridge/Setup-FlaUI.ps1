# Setup-FlaUI.ps1
# One-time setup script to download FlaUI assemblies for use in PowerShell
# Run this once on your Windows 11 laptop

$ErrorActionPreference = 'Stop'

Write-Host "[Setup] Preparing FlaUI for Grok Bridge..." -ForegroundColor Cyan

$assembliesDir = "$env:USERPROFILE\GrokBridgeAssets\assemblies"
New-Item -ItemType Directory -Path $assembliesDir -Force | Out-Null

$tempDir = Join-Path $env:TEMP "FlaUI-Setup-$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

Push-Location $tempDir

try {
    # Create minimal project to pull FlaUI via NuGet
    @"
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net48</TargetFramework>
    <OutputType>Exe</OutputType>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="FlaUI.Core" Version="3.2.0" />
    <PackageReference Include="FlaUI.UIA3" Version="3.2.0" />
  </ItemGroup>
</Project>
"@ | Out-File -FilePath "FlaUI.csproj" -Encoding utf8

    Write-Host "Restoring FlaUI packages..." -ForegroundColor Yellow
    dotnet restore FlaUI.csproj --verbosity quiet

    # Publish to get all DLLs in one place
    dotnet publish FlaUI.csproj -c Release -o "publish" --no-restore --verbosity quiet

    # Copy relevant FlaUI + dependencies
    Copy-Item "publish\FlaUI*.dll" -Destination $assembliesDir -Force
    Copy-Item "publish\Interop.UIAutomationClient.dll" -Destination $assembliesDir -Force -ErrorAction SilentlyContinue

    Write-Host "[Setup] FlaUI assemblies downloaded to: $assembliesDir" -ForegroundColor Green
} finally {
    Pop-Location
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "
Next steps:" -ForegroundColor Cyan
Write-Host "1. Load with: Add-Type -Path \"$assembliesDir\FlaUI.Core.dll\"; Add-Type -Path \"$assembliesDir\FlaUI.UIA3.dll\"" -ForegroundColor White
Write-Host "2. Then dot-source BRIDGE_VISION.ps1" -ForegroundColor White
