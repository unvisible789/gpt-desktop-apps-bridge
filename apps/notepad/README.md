**Notepad App Integration (Human-Like Refined)**

### Actions
- Open new document
- Type text with human-like delays, word bursts, punctuation pauses, and occasional hesitation
- Chunked long typing with realistic pauses
- Save As with natural timing
- Close gracefully (checks for unsaved content *)

### Scripts
See bridge/BRIDGE_HELPERS.ps1 for Close-GracefullyOrAsk, Send-HumanLikeText, Send-KeyCombo, etc.
See apps/notepad/Notepad-HumanControl.ps1 for high-level flows (Notepad-OpenAndType, Notepad-TypeWithPauses, Notepad-SaveAs, Notepad-CloseGracefully).

### Bridge Usage
Queue: {"type":"OPEN_APP","target":"notepad","instructions":"Open new doc and type a short story with human timing"}

Safety: Always use graceful close. The helpers will refuse force close on unsaved content without approval.