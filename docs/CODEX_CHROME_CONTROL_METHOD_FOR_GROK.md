# CODEX_CHROME_CONTROL_METHOD_FOR_GROK

## Practical Lessons from Codex’s Chrome/Monkeytype Work

1. After any approval popup, permission prompt, tab reload, or user interaction, assume focus/tab/clipboard state is contaminated.

2. Re-list tabs, re-select the correct Chrome tab, take a fresh screenshot/DOM read, and refocus the target before typing.

3. Do not rely on old coordinates or old selected tabs.

4. For Monkeytype, bulk clipboard paste or setting textbox content is not valid. It must receive real key events into the focused word area.

5. The successful path was: open Monkeytype, accept cookies if needed, focus the word area, read visible words, type word stream using real keypresses, and verify that `.word` elements advance.

6. The failure path was: approval interrupted the window, clipboard content got mixed with prompt text, typing went into wrong place or stopped early.

7. For Durable/Chrome editing, use the same loop: locate target, act small, verify visible/editor state, then verify public/live URL if claiming published success.

8. Report every result using labels: Working, Partial, Broken, Needs Approval.

9. Do not claim “done” unless there is proof: screenshot/DOM/public page/readback/log.

## How Grok should improve

- Build a reliable Chrome tab re-acquisition routine
- Reset focus after every interruption
- Keep clipboard separate from control text
- Prefer browser/DOM control where possible
- Use foreground mouse/keyboard only when required
- Always verify after acting