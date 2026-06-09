# Adding New Apps to the GPT Desktop Bridge

## Steps
1. Create `apps/your-app/`
2. Document common control patterns (focus, type, click, read state)
3. Add reusable helpers to bridge/ if general
4. Test with low-risk commands via queue
5. Update root README

## Best Practices
- Always prefer graceful over force
- Use multi-pass copy for large content
- Log every action to bridge
- Request screen context for GUI-heavy apps

## Example Template
See apps/notepad/ and apps/chrome/

Contribute by PR or direct push to this repo so all GPT instances can use the integrations.