#!/bin/bash
# MCP Health Check — quick probe of M365 MCP server connectivity
# Usage: ~/.copilot/scripts/mcp-health-check.sh [--quiet]
# Returns exit code 0 if healthy, 1 if auth expired

QUIET="${1:-}"
ENV_URL="https://agent365.svc.cloud.microsoft/mcp/environments/610353a4-2335-ecea-bd8d-cdf812a0e319/servers"

# Probe one server as canary (all share the same OAuth token)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$ENV_URL/mcp_TeamsServer" 2>/dev/null)

if [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "403" ]; then
    [ "$QUIET" != "--quiet" ] && echo "⚠️  M365 MCP tokens expired (HTTP $HTTP_CODE). Run /mcp to re-authenticate."
    exit 1
elif [ "$HTTP_CODE" = "000" ]; then
    [ "$QUIET" != "--quiet" ] && echo "❌ M365 MCP servers unreachable (network error)."
    exit 2
else
    [ "$QUIET" != "--quiet" ] && echo "✅ M365 MCP servers reachable (HTTP $HTTP_CODE)."
    exit 0
fi
