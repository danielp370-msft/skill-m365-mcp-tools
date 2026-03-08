#!/bin/bash
# MCP Health Check — probe M365 MCP server connectivity with token validation
# Usage: ~/.copilot/scripts/mcp-health-check.sh [--quiet]
# Returns exit code 0 if healthy, 1 if auth expired, 2 if unreachable

QUIET="${1:-}"
MCP_OAUTH_DIR="$HOME/.copilot/mcp-oauth-config"

# Discover environment URL from config (not hardcoded)
CONFIG_FILE=$(ls "$MCP_OAUTH_DIR"/*.json 2>/dev/null | grep -v '.tokens.json' | head -1)
TOKENS_FILE="${CONFIG_FILE%.json}.tokens.json"

if [ -z "$CONFIG_FILE" ] || [ ! -f "$TOKENS_FILE" ]; then
    [ "$QUIET" != "--quiet" ] && echo "❌ No MCP OAuth config found. Run /mcp to set up."
    exit 1
fi

# Extract server URL and token
SERVER_URL=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['serverUrl'])" 2>/dev/null)
ACCESS_TOKEN=$(python3 -c "import json; print(json.load(open('$TOKENS_FILE'))['accessToken'])" 2>/dev/null)

if [ -z "$SERVER_URL" ] || [ -z "$ACCESS_TOKEN" ]; then
    [ "$QUIET" != "--quiet" ] && echo "❌ Could not read MCP config. Run /mcp to re-authenticate."
    exit 1
fi

# Probe with auth header — expect 405 (Method Not Allowed = auth OK, just wrong HTTP method)
# 401/403 = token expired, 000 = unreachable
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    "$SERVER_URL" 2>/dev/null)

if [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "403" ]; then
    [ "$QUIET" != "--quiet" ] && echo "⚠️  M365 MCP tokens expired (HTTP $HTTP_CODE). Run: ~/.copilot/scripts/mcp-refresh-tokens.sh"
    exit 1
elif [ "$HTTP_CODE" = "000" ]; then
    [ "$QUIET" != "--quiet" ] && echo "❌ M365 MCP servers unreachable (network error)."
    exit 2
else
    [ "$QUIET" != "--quiet" ] && echo "✅ M365 MCP tokens valid (HTTP $HTTP_CODE)."
    exit 0
fi
