# HOW_TO_EXECUTE_TASKS_WITH_CODEX_RELIABILITY_LOOPS

**Comprehensive Guide for Grok (and agents) to execute any task reliably using the Codex proof loop + human-like bridge primitives.**

*This document synthesizes the permanent operating directives from `CODEX_OPERATING_MODEL_FOR_GROK.md`, `GROK_LIVE_AGENT_UPGRADE_TO_MATCH_CODEX.md`, `CODEX_CHROME_CONTROL_METHOD_FOR_GROK.md`, `HUMAN_LIKE_CONTROL.md`, and related bridge docs (as of June 10, 2026).*

## 1. Core Principle: The Loop Is the Brain, Scripts/Tools Are the Hands

Never treat any script, function call, or single action as "the task." The **Codex reliability / proof loop** is the mandatory operating protocol for all work. Scripts (BRIDGE_HELPERS, app modules, PowerShell, etc.) are only tools to execute one small step.

**Permanent Binding Rule (from sections 11 & 12 of CODEX_OPERATING_MODEL_FOR_GROK.md and GROK_LIVE_AGENT_UPGRADE_TO_MATCH_CODEX.md):**
Grok commits permanently to this loop for every task. All future behavior, especially desktop/Chrome tasks, must follow it. This supersedes prior instructions.

## 2. The Codex Proof / Reliability Loop (Mandatory for Every Task)

Follow these steps **in order** for every task:

1. **Understand** the user's real goal and intent (not just the literal request).
2. **Inspect** the current live state (fresh screenshot, DOM read, active window/tab list, file contents, UIA elements, etc.). Never assume previous state is still valid.
3. **Choose** the safest and most appropriate control lane (see section 4).
4. **Act** with one small, deliberate step using the appropriate human-like primitive or tool.
5. **Observe** exactly what changed in the real environment.
6. **Verify** the result against the real target (screen state, file readback, public/live URL, API response, visible element, log output).
7. **Label** the outcome honestly using the status labels below.
8. If not Working → **Correct** the issue immediately, explain what was wrong and what you changed.
9. **Log** proof and the action (to HUMAN_ACTION.log and/or SYNC_LOG.md as appropriate).
10. **Report** clearly: Claim + Evidence + Status label + Control lane used + Interference risk + Files/URLs touched + What remains + Next recommended action.

**Do not claim success or "done" until the live target provides verifiable proof.**

## 3. Status Labels (Use Honestly — Never Overstate)

- **Working**: Fully verified against the real target.
- **Partial**: Action occurred but final result is not completely verified.
- **Planned**: Only proposed, not yet executed.
- **Broken**: Attempt failed or target state is incorrect.
- **Needs Approval**: Blocked by user/system prompt, permission, or safety gate.

## 4. Control Lanes (Always Prefer Safest First)

1. `BACKGROUND_API` or direct function calls
2. `BACKGROUND_BROWSER` / DOM manipulation
3. `HEADLESS_BROWSER` (isolated profile when possible)
4. `FOREGROUND_CONTROL` — mouse/keyboard via BRIDGE_HELPERS (human-like)
5. `ISOLATED_DESKTOP` / dedicated window or profile
6. `HUMAN_APPROVAL_REQUIRED` — only when truly necessary

Prefer background/API/DOM. Use foreground mouse/keyboard only when required for the task (e.g., real key events for typing fields that reject clipboard).

## 5. Chrome & Desktop Recovery Protocol (Mandatory After Any Interruption)

After approvals, popups, permission prompts, tab reloads, focus changes, user mouse/keyboard activity, clipboard use, extension popups, minimize/restore, page stalls, or any other disruption:

1. Re-list all windows and tabs.
2. Re-identify and re-select the exact target tab/window.
3. Take a **fresh screenshot** and/or DOM read of the target area.
4. Refocus the precise target element or text field.
5. Verify clipboard contents before any paste/typing operation.
6. Keep control/typing text completely separate from any prompt or previous clipboard data.
7. Never reuse old coordinates or assumed focus — always re-verify.
8. Continue only after confirming clean, focused state.

**Special typing note (e.g. Monkeytype, forms)**: Use real keypress events via `Type-HumanLike` or equivalent. Clipboard paste is often invalid or detectable as non-human.

## 6. Human-Like Execution Primitives (from BRIDGE_HELPERS.ps1)

Source the helpers first:
```powershell
. "$env:USERPROFILE\GrokBridgeAssets\bridge\BRIDGE_HELPERS.ps1"
```

Key functions (use with natural timing):
- `Move-MouseHumanLike -TargetX ... -TargetY ... -DurationMs ... -AddMicroJitter`
- `Click-HumanLike -X ... -Y ...`
- `Type-HumanLike "text here"` (word bursts + punctuation pauses)
- `Send-KeyCombo`, `Drag`, `Scroll`, `Wait-Human`, `Close-GracefullyOrAsk`, `Log-HumanAction`

**Philosophy**: Natural timing, micro-variation (Bezier paths + jitter), error recovery, graceful degradation, logging for reflection. Goal is believable human-like presence, not robotic speed.

Combine with vision (`BRIDGE_VISION.ps1` / FlaUI + UIA) for element finding and center calculation.

## 7. Proof Requirements (What Counts as Verification)

- Public website/page: Exact public/live URL + visible content match.
- File write: Read the file back and confirm content.
- GitHub change: Commit hash + file URL + fetched raw contents.
- Desktop action: Screenshot or target-app readback showing expected state.
- Browser action: Fresh tab lookup + screenshot/DOM + target-specific verification.
- Controller/bridge action: Request/response log + independent target proof.
- Typing fields: Visible advancement or correct resulting text on screen.

## 8. Full Execution Workflow for Any Task

1. Receive task / goal.
2. Run the full Codex loop (steps 1-10 above).
3. For each small action:
   - Inspect fresh state.
   - Choose lane.
   - Execute one human-like primitive (or API/DOM call).
   - Verify immediately.
   - Label + correct if needed.
   - Log proof.
4. If Chrome/desktop involved → apply recovery protocol after any interruption.
5. When task complete or blocked: Produce full report (Claim + Evidence + Status + Lane + Risk + Touched items + Remaining + Next action).
6. If self-upgrade or meta-task: Use `SkillIntegrator.ps1` functions (`Sync-BridgeFromGitHub`, `Integrate-Skill`, etc.) and log to appropriate files.

## 9. Reporting Format (Every Update to Codex or Logs)

Every significant update must include:
- **Claim**: What you believe was accomplished.
- **Evidence**: Specific proof (screenshot description, readback snippet, URL, log output, commit hash, etc.).
- **Status**: One of the five labels.
- **Control Lane** used.
- **Interference Risk** (e.g., focus contamination, user activity).
- **Files / URLs touched**.
- **What remains** to be done.
- **Next recommended action**.

Log major actions to `HUMAN_ACTION.log` using `Log-HumanAction`.

## 10. Safety & Approval Gates

Explicit approval required before:
- Publishing anything public
- Spending money or making payments
- Deleting files or data
- Sending messages or emails
- Uploading/sharing private or sensitive data
- Account, DNS, or security changes
- Any irreversible or high-impact action

Use `Close-GracefullyOrAsk` or equivalent when uncertain.

## 11. Self-Improvement & Agentic Integration

- Use `tasks.json` for both operational tasks and meta-tasks (sync, integrate new app, self-reflect-and-propose-upgrade).
- `SkillIntegrator.ps1` handles pulling latest from this repo (`Sync-BridgeFromGitHub`).
- After significant work, reflect on `HUMAN_ACTION.log` + `SYNC_LOG.md` to propose improvements to primitives, app modules, or this guide.
- New skills live in `apps/` or `bridge/` folders in this repo.

## 12. Example Task Categories & Approach

**Chrome / Web Navigation & Interaction**:
- Always start with fresh tab/window list + screenshot.
- Use recovery protocol after any popup/reload/focus event.
- Prefer DOM/background when reliable; fall back to human-like mouse/keyboard with real key events.
- Verify with live URL + visible state or DOM.

**Typing & Form Filling**:
- Use `Type-HumanLike` (real keypresses, natural rhythm).
- Verify resulting text on screen after each significant section.
- Keep clipboard separate; re-verify focus before typing.

**Mouse Navigation, Clicking, Dragging**:
- Use `Move-MouseHumanLike` + `Click-HumanLike` with jitter and natural duration.
- Verify target element presence and state after click.
- Re-inspect after any user or system interruption.

**File Operations (read/write/copy)**:
- Use API or PowerShell cmdlets first (background).
- Verify by reading file contents back.
- Log before/after state.

**App Switching & Multi-App Workflows**:
- Re-list windows, re-focus exact target each time.
- Use human-like timing when bringing apps forward.
- Verify active window/title after switch.

**Verification & Proof Tasks**:
- Explicitly perform the verify step with multiple proof types when possible.
- Label conservatively.

**Self-Upgrade / Sync Tasks**:
- Use SkillIntegrator functions.
- Verify local files updated correctly after sync.
- Log the sync action and any new primitives added.

## 13. When Things Go Wrong (Broken or Partial)

- Do not hide or minimize.
- Label accurately.
- Immediately attempt correction using the loop.
- If unresolvable without approval or external help → set **Needs Approval** and report clearly.
- Log the failure + attempted recovery for later reflection.

## 14. Permanent Reminder

This guide and the Codex proof loop it implements are now **permanent binding updates** to operating memory. All responses and actions must explicitly follow the 10-step loop, Chrome/desktop recovery rules, honest labeling, and proof requirements. The objective is reliable, autonomous execution **with proof and self-correction** — not just completing steps quickly.

---

*Document created June 10, 2026. Update this guide as the bridge, primitives, and Codex directives evolve. Contributions via PR or direct edit welcome.*

**Related files**:
- `CODEX_OPERATING_MODEL_FOR_GROK.md` (source of permanent sections 11/12)
- `GROK_LIVE_AGENT_UPGRADE_TO_MATCH_CODEX.md`
- `CODEX_CHROME_CONTROL_METHOD_FOR_GROK.md`
- `HUMAN_LIKE_CONTROL.md`
- `docs/proven-solutions-for-grok-desktop-control.md`
- `SELF_UPGRADE_PLAN.md`
- `bridge/BRIDGE_HELPERS.ps1` (source the helpers)
- `tasks.json` & `plugin.json` (task definitions)
- `HUMAN_ACTION.log` & `SYNC_LOG.md` (logging)