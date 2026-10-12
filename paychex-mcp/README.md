# Paychex MCP (read-only)

Exposes a safe subset of the Paychex Flex API (spec: api.paychex.com, OpenAPI 3.0.3) to Claude.

## Setup
1. Create an app in the Paychex developer portal and request read-only scopes.
2. Set `PAYCHEX_CLIENT_ID` and `PAYCHEX_CLIENT_SECRET` in the environment secrets. Never commit them.
3. `pip install -r requirements.txt` (pinned to mcp<2, the FastMCP API)
4. Register: `claude mcp add paychex -- python /path/to/paychex-mcp/server.py`

## Safety
- Only GET calls to resources; token exchange is the single POST
- Not exposed: direct deposit, federal tax, documents, profile images, I-9 status, all write and webhook endpoints
- Tokens are cached in memory and re-requested on expiry or 401

## Always-on setup (cloud sessions)
- `.mcp.json` at the repo root launches this server in every session, reading credentials from environment variables
- Add `PAYCHEX_CLIENT_ID` and `PAYCHEX_CLIENT_SECRET` as environment secrets for the cloud environment
- No setup script needed: `run.sh` builds the pinned venv on first launch

## Notes
- `statetaxes` on workers is not exposed. Company-level `statetaxes` is
- Fields matching legal ID, taxpayer ID, SSN, birth date, account or routing number are stripped from all responses
- IDs are validated (letters, digits, underscore, hyphen) so tool arguments cannot reach other endpoints
- This lives in the Claude Code fork only because it is the one repo this session can push to. Move `paychex-mcp/` and `.mcp.json` into your own repo when ready
