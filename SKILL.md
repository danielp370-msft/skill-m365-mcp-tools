---
name: agent365-mcp-setup
description: Set up Microsoft Agent 365 MCP servers (Teams, Outlook Mail, Calendar, SharePoint/OneDrive, Word, Copilot Search, Dataverse, User Profile) in Copilot CLI. Use this skill when asked to connect to Agent 365 MCP servers or add Microsoft 365 tools.
license: MIT
---

# Agent 365 MCP Server Setup

## Overview

Microsoft Agent 365 provides enterprise-grade MCP (Model Context Protocol) servers that give agents governed access to Microsoft 365 services. This skill walks through connecting any of the available servers to Copilot CLI.

## Prerequisites

1. **Frontier Preview Program** — The user must be enrolled at https://adoption.microsoft.com/copilot/frontier-program/
2. **Microsoft Entra authentication** — The user must be able to sign in with their Microsoft work account
3. **Power Platform environment** — A Power Platform environment with Dataverse is required (the environment ID is used in the MCP URL)

## Available MCP Servers

| Server ID | Config Name | Display Name | What It Does |
|-----------|-------------|-------------|--------------|
| `mcp_TeamsServer` | `TeamsServer` | Microsoft Teams | Chats, channels, messages, members |
| `mcp_MailTools` | `OutlookMail` | Outlook Mail | Send, read, search, reply to emails |
| `mcp_CalendarTools` | `OutlookCalendar` | Outlook Calendar | Events, scheduling, availability |
| `mcp_ODSPRemoteServer` | `SharePointOneDrive` | SharePoint & OneDrive | Files, folders, sites, sharing |
| `mcp_WordServer` | `Word` | Microsoft Word | Create/read documents, comments |
| `mcp_M365Copilot` | `CopilotSearch` | Copilot Search | Search across all M365 content |
| `mcp_MeServer` | `UserProfile` | User Profile | User profiles, org hierarchy |
| `mcp_DataverseServer` | `Dataverse` | Dataverse | Tables, records, queries |

**This list may be out of date.** See [Step 0](#step-0-discover-available-servers) for how to get the current list.

## URL Format

All servers use the same base URL pattern:

```
https://agent365.svc.cloud.microsoft/mcp/environments/{ENVIRONMENT_ID}/servers/{SERVER_ID}
```

**IMPORTANT:** The URL `https://agent365.svc.cloud.microsoft/agents/servers/{SERVER_ID}` (without environment ID) will fail with `"Tenant id is invalid"`. You MUST include the Power Platform environment ID.

## Step-by-Step Setup

### Step 0: Discover Available Servers

**IMPORTANT:** Do NOT install all servers at once. First, discover what's available, then let the user choose.

**Option 1 — MCPManagement server (recommended, live data):** Connect the MCPManagement server first to query available servers. Add this to `~/.copilot/mcp-config.json`:

```json
"MCPManagement": {
  "type": "http",
  "url": "https://agent365.svc.cloud.microsoft/mcp/environments/{ENV_ID}/servers/MCPManagement",
  "tools": ["*"]
}
```

Then use the `GetMCPServers` tool (no parameters needed) to list all available servers.

**Option 2 — Fetch the docs page:** Use `web_fetch` on `https://learn.microsoft.com/en-us/microsoft-agent-365/tooling-servers-overview` and parse the "Tools catalog" section for current server IDs.

**Option 3 — Hardcoded fallback:** Use the table in the [Available MCP Servers](#available-mcp-servers) section above.

Use `ask_user` to present the available servers and let the user pick one or more. They can always add more later by re-running the skill.

### Step 1: Get the Power Platform Environment ID

The environment ID is a GUID that identifies a Power Platform environment in the user's tenant.

**Option A: Use Playwright (recommended)**
1. Navigate to `https://admin.powerplatform.microsoft.com/environments`
2. Wait for auth redirect to complete and page to load
3. Take a snapshot — the environment list will show as a grid
4. Each environment row has a link like `/environments/environment/{GUID}/hub`
5. Extract the GUID from the URL — that's the environment ID

**Option B: Ask the user**
- Direct them to https://admin.powerplatform.microsoft.com → Manage → Environments
- Select an environment → the GUID is in the URL and shown in the Details section

**Which environment to use:**
- For personal testing: Use a **Developer** type environment (personal to the user)
- For team use: Use a **Production** type environment (shared across the org)
- The environment ID is per-environment, NOT per-user. Shared environments have the same ID for everyone.

### Step 2: Add Selected Servers to MCP Config

Edit `~/.copilot/mcp-config.json` and add **only the servers the user selected** under `mcpServers`. Each server entry follows this pattern:

```json
"ConfigName": {
  "type": "http",
  "url": "https://agent365.svc.cloud.microsoft/mcp/environments/{ENV_ID}/servers/{SERVER_ID}",
  "tools": ["*"]
}
```

Use the **Config Name** and **Server ID** columns from the [Available MCP Servers](#available-mcp-servers) table. Replace `{ENV_ID}` with the environment GUID from Step 1.

### Step 3: Restart or Reload

Tell the user to restart the CLI or run `/mcp` to reload the configuration.

### Step 4: Verify

After reloading, run `/mcp` to check server status. Each server should show:
- Status: ✓ Connected

If a server shows "Failed", check:
- Is the environment ID correct?
- Is the user signed in with their Microsoft account?
- Has the tenant admin enabled the MCP server in M365 Admin Center → Agents and Tools?

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `Tenant id is invalid` | Missing environment ID in URL | Use the `/mcp/environments/{id}/servers/` URL format |
| `401 Unauthorized` | Auth token missing or expired | Restart CLI, re-authenticate |
| `403 Forbidden` | Admin hasn't granted MCP server permission | Tenant admin must enable in M365 Admin Center |
| `UnexpectedError` | Various server-side issues | Check environment is "Ready" state in Power Platform admin |

## Documentation Links

- MCP Servers Overview: https://aka.ms/a365-dev-mcp
- Agent 365 SDK Docs: https://aka.ms/a365-sdk-docs
- Agent 365 SDK Python: https://github.com/microsoft/Agent365-python
- Agent 365 SDK .NET: https://github.com/microsoft/Agent365-dotnet
- Agent 365 SDK Node.js: https://github.com/microsoft/Agent365-nodejs
- Agent 365 Samples: https://github.com/microsoft/Agent365-Samples
- Frontier Preview Program: https://adoption.microsoft.com/copilot/frontier-program/
