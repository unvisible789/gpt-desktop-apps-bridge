**Notepad App Integration**

### Actions
- Open new document
- Type text (human-like delays)
- Save / close gracefully (check for unsaved *)

### Scripts
See bridge/BRIDGE_HELPERS.ps1 for Close-GracefullyOrAsk, Send-HumanLikeText.

### Bridge Usage
Queue: {"type":"OPEN_APP","target":"notepad","instructions":"Open new doc and type story"}

Safety: Avoid force close on unsaved content.