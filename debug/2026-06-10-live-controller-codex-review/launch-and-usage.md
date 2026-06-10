# Launch & Usage Instructions - Live Desktop Controller

## To start the controller (leave this running in the background)

Open a normal PowerShell window and run:

```powershell
powershell -ExecutionPolicy Bypass -NoExit -File "C:\Users\Owner\GrokBridgeAssets\bridge\live-control\live-controller.ps1"
```

- A new PowerShell window will appear (or reuse if minimized).
- It will print startup logs including its own Process ID.
- It listens on http://127.0.0.1:8765 and http://localhost:8765
- Leave the window open (minimized is fine). The AI (Grok or Codex) will send commands to it.

## Recommended usage (for Codex / Grok agents)

**Prefer the safe non-interfering commands** when the human is actively using the computer:

```powershell
# View what the user is in
Invoke-WebRequest -Uri 'http://localhost:8765/command' -Method POST -Body '{"command":"get_active_window","params":{}}' -ContentType 'application/json'

# See what text the user currently has focused
Invoke-WebRequest -Uri 'http://localhost:8765/command' -Method POST -Body '{"command":"get_focused_text","params":{}}' -ContentType 'application/json'

# Contribute text to the user's current focused field (non-interfering where supported)
$body = @{ command = 'set_focused_text'; params = @{ text = 'Your contribution here...' } } | ConvertTo-Json -Compress
Invoke-WebRequest -Uri 'http://localhost:8765/command' -Method POST -Body $body -ContentType 'application/json'
```

**Legacy / precise control commands** (will interfere - use only when necessary):
- type_text (SendKeys)
- move_mouse / click

## Health check
```powershell
Invoke-WebRequest -Uri 'http://localhost:8765/health' -UseBasicParsing
```

## Logs
- `live_log.txt` in the same folder - contains every REQUEST RECEIVED and RESPONSE SENT with timestamps and full bodies.
- Check this file after any AI-driven actions for proof.

## Notes for Codex
- The controller is intentionally minimal and persistent so it can survive chat compaction / agent restarts.
- All actions are driven over plain HTTP JSON so any client (PowerShell, Python, another agent) can drive it.
- The new UIA commands were added specifically to satisfy the concurrent-use requirement.
- Review the full live-controller.ps1 and the reference report in this folder for the complete proof history and design decisions.

Generated as part of the 2026-06-10 debug package.