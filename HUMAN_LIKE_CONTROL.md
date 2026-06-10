# HUMAN_LIKE_CONTROL.md

Philosophy and primitives for making Grok (and similar agents) control the Windows desktop in a **natural, human-like** way — with timing, micro-variation, error recovery, and self-improvement loops.

This is the core contract for everything in this repo (BRIDGE_HELPERS, BRIDGE_VISION, app modules, task-engine, SkillIntegrator).

## Core Principles (from SELF_UPGRADE_PLAN)
- **Natural timing & movement**: Bezier-style mouse paths, variable speed, micro-jitter, word bursts + punctuation pauses for typing, occasional "hesitation".
- **Error recovery & graceful degradation**: Never force; prefer checks (e.g. unsaved content dialogs), multi-pass vision, retry with offset, human-like confirmation flows.
- **Logging for reflection**: Every significant action goes to HUMAN_ACTION.log. The agent reads recent history for self-reflection and upgrade proposals.
- **Human-like "thinking" pauses**: Between high-level steps; between tasks in agentic loops.
- **Full visibility + control**: UIA / FlaUI vision for element finding + centers, screenshot diffs for change detection, Playwright fallback for complex web.
- **Safety & reversibility**: Dry-run modes, approval hooks for destructive actions, everything revertible via git + local logs.

## Current Primitives (June 2026)
- **BRIDGE_HELPERS.ps1**: Move-MouseHumanLike (with -AddMicroJitter, Duration), Click-HumanLike, Type-HumanLike, Send-KeyCombo, Drag, Scroll, Wait-Human, Close-GracefullyOrAsk, Log-HumanAction, etc. Backed by robust SendInput after the major upgrade.
- **BRIDGE_VISION.ps1**: FlaUI + UIA element location, Get-ClickPointForText, multi-pass find, center calculation.
- **Playwright-Integration.ps1**: Hybrid browser automation for pages where UIA is insufficient.
- App modules (apps/<name>/*-HumanControl.ps1): High-level flows for notepad, chrome, durable, outlook, desktop-general, file-explorer, excel, browser-advanced, crypto-faucets.

## Self-Improvement / Agentic Loop (Phase 2–4)
The system can upgrade itself:
1. SkillIntegrator.ps1 provides Sync-BridgeFromGitHub, Get-AvailableSkills, Integrate-Skill / Install-NewApp (with -DryRun).
2. tasks.json defines both operational tasks and self-upgrade meta-tasks ("sync-skills-from-github", "integrate-new-app", "self-reflect-and-propose-upgrade").
3. agentic-os/task-engine.ps1 loads tasks, wires self-upgrade calls into SkillIntegrator, supports app dispatch, and logs to HUMAN_ACTION.log.
4. On reflection tasks the engine (future) reads the action log + SYNC_LOG.md and can propose or execute new primitives / app modules.

New skills live in this GitHub repo under apps/ or bridge/. The integrator pulls them (raw or via manifest), places them locally under GrokBridgeAssets/, updates local manifests/tasks, and the monitor/agent reloads.

See:
- SELF_UPGRADE_PLAN.md (full phased roadmap + risks)
- SYNC_LOG.md (sync & upgrade history)
- tasks.json (executable task list)
- docs/adding-new-apps.md (how to contribute new control surfaces)
- docs/proven-solutions-for-grok-desktop-control.md (context with PyGPT, Open Interpreter, Power Automate)

## Usage in Agent / Codex / Grok
- Source the bridge helpers + SkillIntegrator + task-engine.
- Call Sync-BridgeFromGitHub -IncludeApps periodically or via a scheduled self-upgrade task.
- Queue tasks from tasks.json or let Start-AgenticLoop drive a small batch.
- All mouse/keyboard/app actions should go through the human-like wrappers and log.

**Remember**: The goal is not robotic speed but believable, recoverable, improvable desktop presence that feels like a careful, slightly variable human operator.

---

*This document is updated as primitives and the self-upgrade meta-layer evolve.*