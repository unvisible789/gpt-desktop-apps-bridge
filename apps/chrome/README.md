**Chrome / Browser App Integration (Human-Like Refined)**

### Core Human-Like Actions
- Open URL with natural address bar focus and typing
- Search with realistic pacing
- Click elements by visible text (vision + human offset clicks via FindAndClickHuman)
- Scroll with variable human-like pacing
- New tab, close tab, refresh with natural delays
- Full mouse movement (eased paths + jitter)
- Typing with bursts, punctuation pauses, and hesitation

### Scripts
See bridge/BRIDGE_HELPERS.ps1 for the full set of primitives (Move-MouseHumanLike, Click-HumanLike, Send-HumanLikeText, Scroll-HumanLike, FindAndClickHuman, etc.).

### Usage (via queue or direct)
- Queue examples: OPEN_APP chrome with instructions, or direct calls to Chrome-NavigateTo, Chrome-ClickElementByText.
- Always pair with fresh vision (SCREEN_CONTEXT + screenshot) for accurate targeting.

### Notes
- All visible actions are deliberately paced to look and feel human.
- Use vision context from the bridge for 'seeing' before clicking.
- Graceful error handling and waits included.

Example flow: Open Chrome to a page, search, find and click a result using text from vision.