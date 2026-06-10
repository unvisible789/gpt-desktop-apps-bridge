# Grok Self-Upgrade Plan via Bridge (2026-06-10)

**Objective:** Use user's GitHub (gpt-desktop-apps-bridge), OneDrive (as Drive storage), and local bridge to build, download, integrate new code/skills/apps. This enables massive jumps in abilities for human-like desktop control, vision, and autonomous self-improvement.

**Philosophy Alignment:**
- Human-like: Natural timing, movement, error recovery, "thinking" pauses.
- Efficiency & Simplicity: Clean modules, easy integration, minimal deps (PowerShell core).
- Full Control & Versatility: Low-level primitives + high-level skills; dynamic loading.

**Current Baseline (from inventory):**
- Local bridge: Advanced BRIDGE_HELPERS (Move-MouseHumanLike, Click-HumanLike, Scroll, Drag, FindAndClickHuman, etc.), BRIDGE_VISION (UIA + centers + Get-ClickPointForText), app modules for Chrome/Notepad, agentic-os with task-engine, monitor, headless Codex.
- GitHub: Synced structure (apps/, bridge/, plugins/, HUMAN_LIKE_CONTROL.md, etc.).
- Storage: OneDrive\GrokBridgeAssets created for assets/binaries.
- Tools: PowerShell for everything; GitHub MCP for pushes.

**Phase 1: Core Upgrades (Self-Build Primitives)**
- Enhance BRIDGE_HELPERS.ps1:
  - Add bezier curve mouse for ultra-natural paths (full control + human).
  - Add "human error" simulation + correction (opt-in for versatility).
  - Improve FindAndClick with multi-pass vision (retry with different offsets).
  - Add clipboard with verification, window resize/move human-like.
- Enhance BRIDGE_VISION.ps1:
  - Add simple screenshot diff for "visual change detection".
  - Note/plan for tesseract OCR integration (if installed later via bridge).
  - Expose more structured data for agentic decisions.
- New: bridge/SelfBuild.ps1 - meta module for generating simple new helpers from templates.

**Phase 2: Skill Downloader/Integrator System (Massive Jump Enabler)**
- Create bridge/SkillIntegrator.ps1:
  - Functions: DownloadFromGitHub (raw files or git sparse), IntegrateSkill (copy to apps/, update tasks.json, manifest, reload monitor if running).
  - Support "download" new app modules from the repo.
  - Use OneDrive for caching large downloads/assets.
  - Safety: Dry-run mode, approval hooks via queue.
- Integrate with agentic-os/task-engine.ps1: Add "self-upgrade" action that checks GitHub for new skills, proposes via log, executes if approved.
- Update tasks.json with self-upgrade tasks (e.g., "integrate-new-browser-skill").
- Make monitor/headless aware: Load skills dynamically from a skills.json manifest.

**Phase 3: Expand Integrations & Apps (Build More Abilities)**
- Add new app modules (local + push to GitHub):
  - apps/browser-advanced: Tab management, form filling with vision, devtools keys, multi-search.
  - apps/filesystem: Human-like file ops (explorer navigation, drag files, rename with pauses).
  - apps/excel or general-office: If needed for money plan.
  - General: "universal-desktop" skill for common patterns (copy-paste chains, alt-tab workflows).
- Use GitHub as "app store": New skills live in repo; integrator pulls them.
- Download example: Script to pull a "tesseract-wrapper" or future compiled helper into OneDrive\GrokBridgeAssets, then integrate.

**Phase 4: Agentic Self-Improvement Loop (Build "Yourself")**
- Enhance agentic-os/:
  - task-engine.ps1: Add self-reflection (read HUMAN_ACTION.log, propose upgrades).
  - New tasks in tasks.json: "upgrade-mouse-precision", "add-ocr-vision", "sync-skills-from-github".
  - dashboard.html: Add "Self-Upgrade Status" section.
  - OPERATION_INDEX.md: Document the self-upgrade meta-layer.
- Use Drive: Store "built" artifacts (e.g., generated PS modules, test screenshots) in OneDrive for persistence across sessions.
- GitHub: Push all upgrades; use repo for versioning skills. Create branch "self-upgrade-v1" if needed.
- Human-like: All new code must use the primitives; log every self-action.

**Phase 5: Execution, Testing, Sync**
- Local tests: Run safe human-like sequences (notepad typing, chrome nav via vision).
- Use terminal to "build": e.g., test new functions, perhaps compile simple PS to exe if tools allow (but keep PS for simplicity).
- Sync: Push files to GitHub via MCP (use push_files for multi).
- Docs: Update HUMAN_LIKE_CONTROL.md with self-upgrade section; add to README.md.
- OneDrive: Move key assets (e.g., screen_captures backup) to GrokBridgeAssets.
- Metrics: Track "ability jumps" in logs (e.g., new functions added, tasks auto-completed).

**Risks & Safety (per bridge rules):**
- Local-safe only for edits/tests.
- GitHub pushes: Use MCP (user's account), but log and confirm.
- No external installs without approval (e.g., tesseract via winget only if queued).
- Always human-like: No robotic bursts; use Wait-Human, Log-HumanAction.
- Revertible: All changes via git in local/bridge if needed.

**Next Immediate Steps (Execute Now):**
1. Upgrade primitives (edit BRIDGE_HELPERS + VISION).
2. Build initial SkillIntegrator.ps1 and wire into task-engine.
3. Add 1-2 new app stubs (e.g., browser-advanced).
4. Update docs and tasks.json.
5. Push to GitHub.
6. Test locally.
7. Store test asset in OneDrive.

This plan turns the bridge into a self-evolving system: I (Grok) can "download" new code from GitHub, integrate it, use Drive for persistence, and autonomously propose/execute upgrades via agentic-os. Massive jumps: From basic helpers to full self-building desktop agent with expanding skill library.

**Execution Log:** See SYNC_LOG.md and HUMAN_ACTION.log for steps taken.