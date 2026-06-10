# Review of Debug Package and Targeted Improvements (2026-06-10)

**Reviewed by:** Grok
**Package:** debug/2026-06-10-live-controller-codex-review/
**Focus files:** live-controller.ps1, DEBUG_SUMMARY.md, live-controller-reference-report-2026-06-10.md (in debug)

## Analysis of Current State

The live desktop controller is a minimal persistent HttpListener (localhost:8765) that has successfully proven raw input commands (cursor, screenshot, move, click, type_text via SendKeys) with strict PID match and logging per the proof standard. Recent additions include safe UIA-based commands for concurrent use (get_active_window, get_focused_text, set_focused_text) to address the requirement that the AI can view and type without interfering with the human user.

The debug package and summary accurately document the work, proofs (including fresh ones), issues (focus in cluttered desktops, Add-Type limitations, no window targeting yet, controller persistence in tool env), and recommendations.

The report has been extended with section 12 and 13, but the main PASS/FAIL table and proven command list in the document are outdated (still list type_text as NOT ADDED YET and only up to click in some copies).

### 1. Robustness and error handling
- Positive: Per-request try-catch, per-command try-catch for actions, outer fatal catch with infinite sleep for keep-alive, good logging of REQUEST/RESPONSE.
- Issues: $ErrorActionPreference = 'Stop' at top can terminate the listener on uncaught errors in setup or helpers. No finally to guarantee response.Close() in all paths (some paths rely on the catch). The long if-elseif chain in the loop means an error in one branch can be hard to isolate, though catches help. One bad command (e.g. malformed or unsupported) is handled but the listener stays up.
- Gap: No top-level protection if listener setup fails or in the while condition.

### 2. Window and element targeting
- Positive: The safe commands (get_active_window, get_focused_text, set_focused_text) use GetForegroundWindow and AutomationElement.FocusedElement for non-interfering view of the *current user context*. list_windows was missing.
- Issues: Heavily dependent on global focus for actions. To act on a specific window (e.g. a background Notepad while user is in browser), the AI or human must first focus it (using interfering move/click). No enumeration of windows or targeted find by title/process without focus. The UIA is only for focused; no desktop-wide search in the controller (vision module not loaded in the minimal controller).
- This limits "view windows" (plural) and makes reliable targeting for set_focused_text dependent on the human's current focus or prior interfering actions.

### 3. Reliability of type_text and set_focused_text
- type_text (SendKeys): Proven multiple times with full compliance (PID, logs, length, cursor, stay alive). However, it always targets the currently focused window, which can be unreliable if focus changes (e.g. during user activity) and inherently interferes.
- set_focused_text (UIA): Good design with IsReadOnly check and clear fallback error. Works for standard edit controls without focus steal. In tests, correctly errored on read-only TermControl when the controller window had focus (expected). No verification read-back after set (though per proof standard, no visual claim required yet).
- Common: Both can have race conditions if human and AI edit simultaneously. No retry logic or focus assurance for SendKeys.

### 4. Code structure and maintainability
- Positive: Comments explain the dual model and user requirement. Per-command error handling with consistent JSON shape. Minimal dependencies (native .NET for UIA and Win32).
- Issues: Long single file (~550+ lines) with deeply nested if-elseif in the loop. Lots of duplicated code for building result, JSON, buffer, write, and Log RESPONSE (violates DRY). Add-Type for MouseClicker was inside handler (recompiled every click). No helper functions for common response sending. Hard-coded paths and ports. The MouseClicker Add-Type and Win32 classes are inline and repeated in spirit.
- The structure works for minimal controller but will become hard to maintain as more commands (per build order) are added.

### 5. Gaps in the strict proof standard
- The proof standard (one capability at a time, exact launched process, PID match, logs with REQUEST/RESPONSE, HTTP only, process stays alive) is followed for type_text and initial safe commands (fresh logs exist).
- Gap: The reference report's section 4 PASS/FAIL table and section 5 proven list are outdated in the document (type_text listed as NOT ADDED YET, only raw commands listed). The new safe commands and list_windows are only in the added sections 12/13.
- No dedicated proof events table entry for the safe commands or list_windows in the main body (though fresh-proof-log covers some).
- The report in the debug package has the extensions, but consistency with the main docs/ version is needed.
- The controller comment says "minimal" but the philosophy requires not overclaiming (e.g. set_focused_text only when supported).

Overall, the system is functional and follows the repo's philosophy (human-like, logged, incremental, safe where possible). The main weaknesses are the focus dependency for targeting (interference risk) and code duplication/robustness edges.

## Targeted Improvements Made

Prioritized stability (robustness, one bad command doesn't kill listener) and reduced interference (better view without focus, list for windows).

Changes to live-controller.ps1 (local source, then synced to debug package):

1. **Robustness and error handling**:
   - Changed top $ErrorActionPreference from 'Stop' to 'Continue' (prevents one uncaught error in a helper or setup from killing the entire listener loop).
   - Restructured the per-request handling with explicit try { logic } catch { log } finally { ensure $response.Close() } (guarantees cleanup even on errors, prevents resource leaks or stuck states).
   - Extracted Send-JsonResponse and Send-ErrorResponse helper functions (reduces duplication, ensures consistent logging and JSON shape for all responses, including errors).
   - Wrapped ConvertFrom-Json and command dispatch in the existing try, with early validation for $cmd.command.
   - Pre-compiled the MouseClicker Add-Type once at script start (instead of every click) for reliability and to avoid repeated compilation errors in restricted hosts.

2. **Window and element targeting**:
   - Added `list_windows` command (using Win32 EnumWindows + IsWindowVisible + GetWindowText + GetWindowThreadProcessId). Returns array of "Title (PID:xxx)" for visible top-level windows. Pure view, zero interference (no mouse move, no focus change). Directly addresses "view windows" requirement and reduces reliance on global focus.
   - Fixed get_active_window variable name conflict ($fgPid instead of $pid to avoid any collision with automatic read-only $PID variable; the command now succeeds and returns title + process_id).
   - The existing safe UIA commands (get_focused_text, set_focused_text) remain the primary for non-interfering interaction with the *user's current focused context* (aligns with concurrent use philosophy without overcomplicating).

3. **Reliability of type_text and set_focused_text**:
   - No change to the proven logic (kept simple per philosophy and proof standard).
   - The helpers and finally improve the surrounding reliability (consistent error responses, guaranteed close).
   - set_focused_text already had good IsReadOnly check and clear error; list_windows gives visibility into other windows so the AI can advise the user or wait for focus if needed.
   - type_text remains the interfering fallback when UIA SetValue is not supported.

4. **Code structure and maintainability**:
   - Helpers reduce ~100+ lines of duplicated send code across handlers.
   - Precompile and finally improve long-term stability.
   - list_windows is a small, self-contained addition following the existing Win32/Add-Type pattern used elsewhere (click, get_active_window).
   - Kept the controller minimal: no new dependencies, no FlaUI (since assemblies not always present), no complex targeting logic (e.g. no HWND passing or background activation yet -- that would increase interference risk and complexity).

5. **Proof standard gaps**:
   - Updated the reference report (see pushed version) to fix the outdated PASS/FAIL table (now marks type_text as PASS, adds the safe commands and list_windows with notes on non-interfering nature).
   - Added the latest test (PID 9244) as a proof event example.
   - Updated bottom line and notes to reflect current capabilities and the list_windows addition.
   - The fresh proof log from the test run (with consistent PID, full REQUEST/RESPONSE for health + type_text + safe commands + list_windows) is referenced.

All changes follow the existing proof standards (incremental, logged, PID match, HTTP only, process stays alive, one capability focus) and the repo philosophy (human-like where possible, minimal controller, clear errors for unsupported, no overclaiming visual verification).

## Test Results (Post-Improvements)

Using the updated local live-controller.ps1, launched fresh instance (PID 9244), with Notepad activated for type_text test:

- /health: success, pid 9244
- get_cursor: success, real coords, pid 9244
- move_mouse: verification PASS, pid 9244
- click: verification PASS, clicked true, pid 9244
- type_text ("LIVE TYPE TEST"): verification PASS, typed_text_length 14, cursor before/after, pid 9244
- get_active_window: success (title "Windows PowerShell", process_id, pid 9244) -- bug fixed
- get_focused_text: success (UIA read from focused control, pid 9244)
- set_focused_text: graceful error (as expected on TermControl; clear message recommending raw type_text), pid 9244
- list_windows: success, returned 7+ visible windows with titles and PIDs (including Notepad and browsers), pid 9244 -- new non-interfering view
- Final /health: success, same pid 9244, controller still running

All responses had consistent PID. The live_log (captured in output and excerpts) showed the required REQUEST RECEIVED and RESPONSE SENT for the calls (with bodies and full JSON). The controller stayed alive through the full sequence. No interference beyond the explicit move/click for the type_text setup (as per test design).

The list_windows output example from run: ["Windows PowerShell (PID:9728)", "Codex (PID:12776)", "*The Silent Bridge - Notepad (PID:6908)", ...]

## What Still Needs Work (per analysis and test)

- Full window targeting for actions (e.g. set text in a specific background window by title without focus steal) -- would require more UIA search or activation (increases complexity and potential interference; left for later per "do not overcomplicate").
- Loading richer vision (FlaUI) in the controller for name-based find without focus (assemblies/setup needed; the safe commands use native UIA as lightweight fallback).
- Verification/read-back after set_focused_text or type_text (per proof standard, not claimed yet; could be future incremental addition).
- Making the controller a true background service (currently user must leave PS window open).
- Updating the main docs/ report (the debug package has the extended version; the source docs/ was older).
- Edge cases in UIA (some controls don't support ValuePattern; the error handling is good).

The improvements increase stability (finally, Continue, helpers, precompile) and viewing capability (list_windows) while keeping the controller minimal and aligned with the proof standard and concurrent-use philosophy.

The updated live-controller.ps1 (local) and this review have been pushed to the debug package for Codex.