**GPT Desktop Apps Bridge**

Hybrid coordination repo for adding and controlling desktop applications with GPT (via Codex/phone computer-use) + local Grok execution.

## Goal
Central place to define "apps" (desktop tools, browsers, editors, etc.) that GPT can reliably use through the bridge system.

- Grok (local): Executes PowerShell, file ops, precise SendKeys/mouse on desktop.
- Codex/GPT (phone): Provides vision, high-level commands, user intent via the file bridge.

This allows "all apps available to GPT" by creating per-app folders with scripts, docs, and control patterns.

## Current Structure
- `/bridge/` - Core monitor, helpers, and coordination scripts.
- `/apps/` - One folder per application/tool with integration code and docs.
- `/docs/` - Guides on adding new apps and using the system.

## How to Add a New App
1. Create folder `apps/<app-name>/`
2. Add `README.md` with:
   - What the app is
   - Common actions (open, type, click, close, etc.)
   - PowerShell snippets or helper functions
   - Safety notes (e.g., unsaved content)
   - Example bridge commands
3. Add scripts (e.g., `control.ps1` or helpers)
4. Update root README with the new app
5. Test via the bridge (add to COMMAND_QUEUE or manual coordination)

## Bridge Workflow
- Commands go through `COMMAND_QUEUE.jsonl` (JSON with id, type, target, instructions, approved)
- Results written to `COMMAND_RESULTS.jsonl`
- Monitor (v2) polls and executes safely
- Codex provides screen context for complex GUI work

See `/docs/adding-new-apps.md` for details and examples.

## Existing Apps
- Notepad (basic open/type/close)
- Chrome / Browser control
- (Add more as we integrate)

All chat memory, scripts, and app definitions live here for full GPT/Codex access.

## Related
This supports the grok-codex-bridge coordination system for phone-controlled desktop automation.