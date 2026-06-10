# gpt-desktop-apps-bridge

Hybrid Grok + GPT Codex bridge for **human-like desktop control** and self-improving automation.

## Quick Start (on your laptop)

1. Clone or pull this repo into a folder you control.
2. Create folder: `$env:USERPROFILE\GrokBridgeAssets\bridge`
3. Copy `bridge/BRIDGE_HELPERS.ps1` into that folder (or run the sync function).
4. In PowerShell:
   ```powershell
   . "$env:USERPROFILE\GrokBridgeAssets\bridge\BRIDGE_HELPERS.ps1"
   ```
5. Test:
   ```powershell
   Move-MouseHumanLike -TargetX 800 -TargetY 500 -DurationMs 650 -AddMicroJitter
   Click-HumanLike -X 800 -Y 500
   Type-HumanLike "Hello from Grok bridge"
   ```

## Core Improvements (June 10, 2026)
- `BRIDGE_HELPERS.ps1` completely upgraded with **robust SendInput** mouse/keyboard
- Bezier-style smooth human-like mouse movement + micro jitter
- Variable natural timing and logging
- Fixes previous breakage with mouse/keyboard functions on modern Windows

## Staying Updated
Use the `Sync-BridgeFromGitHub` function from `SkillIntegrator.ps1` to pull the latest helpers directly from this repo.

This bridge is designed to work with local Grok agents, Open Interpreter, or custom Codex setups so Grok can actually control your desktop reliably and naturally.
