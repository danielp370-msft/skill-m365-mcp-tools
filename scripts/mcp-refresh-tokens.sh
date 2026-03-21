#!/bin/bash
# MCP Token Silent Refresh — refreshes M365 MCP OAuth tokens without browser interaction
# Usage: ~/.copilot/scripts/mcp-refresh-tokens.sh [--quiet]
# Returns exit code 0 if refreshed, 1 if refresh failed (need manual /mcp)

QUIET="${1:-}"
MCP_OAUTH_DIR="$HOME/.copilot/mcp-oauth-config"

# Pick the first config/token pair to get credentials
CONFIG_FILE=$(ls "$MCP_OAUTH_DIR"/*.json 2>/dev/null | grep -v '.tokens.json' | head -1)
TOKENS_FILE="${CONFIG_FILE%.json}.tokens.json"

if [ -z "$CONFIG_FILE" ] || [ ! -f "$TOKENS_FILE" ]; then
    [ "$QUIET" != "--quiet" ] && echo "❌ No MCP OAuth config found."
    exit 1
fi

# Extract credentials and resource URL
CLIENT_ID=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['clientId'])")
RESOURCE_URL=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['resourceUrl'])")
REFRESH_TOKEN=$(python3 -c "import json; print(json.load(open('$TOKENS_FILE'))['refreshToken'])")

if [ -z "$REFRESH_TOKEN" ]; then
    [ "$QUIET" != "--quiet" ] && echo "❌ No refresh token available. Run /mcp to authenticate."
    exit 1
fi

# Use the .default meta-scope instead of the granular scopes stored in the token.
# Entra rejects refresh_token requests that send all 32 granular scopes
# (e.g. McpServers.Teams.All, McpServers.Mail.All, ...) with "invalid_scope".
# The .default scope tells Entra to return all previously-consented scopes.
# Also use /organizations/ (not /common/) to match the Entra auth server config.
SCOPE="${RESOURCE_URL}/.default offline_access"

# Attempt silent refresh
RESPONSE=$(curl -s -X POST "https://login.microsoftonline.com/organizations/oauth2/v2.0/token" \
    -d "client_id=$CLIENT_ID" \
    -d "grant_type=refresh_token" \
    -d "refresh_token=$REFRESH_TOKEN" \
    -d "scope=$SCOPE" \
    --max-time 10)

# Check if we got a new access token
HAS_TOKEN=$(echo "$RESPONSE" | python3 -c "import json,sys; d=json.load(sys.stdin); print('yes' if 'access_token' in d else 'no')" 2>/dev/null)

if [ "$HAS_TOKEN" != "yes" ]; then
    ERROR=$(echo "$RESPONSE" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('error','unknown'))" 2>/dev/null)
    [ "$QUIET" != "--quiet" ] && echo "❌ Token refresh failed ($ERROR). Run /mcp to re-authenticate."
    exit 1
fi

# Write refreshed tokens to ALL token files
python3 << PYEOF
import json, time, glob, os

resp = json.loads('''$RESPONSE''')
new_tokens = {
    "accessToken": resp["access_token"],
    "refreshToken": resp.get("refresh_token", ""),
    "expiresAt": int(time.time()) + resp.get("expires_in", 3600),
    "scope": resp.get("scope", "")
}

token_files = glob.glob(os.path.expanduser("~/.copilot/mcp-oauth-config/*.tokens.json"))
for tf in token_files:
    with open(tf, 'w') as f:
        json.dump(new_tokens, f, indent=2)
PYEOF

[ "$QUIET" != "--quiet" ] && echo "✅ MCP tokens refreshed successfully."
exit 0
