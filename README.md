# skill-agent365-mcp-setup

A [Copilot CLI skill](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/create-skills) for setting up Microsoft Agent 365 MCP servers (Teams, Outlook, Calendar, SharePoint, Word, Copilot Search, Dataverse, User Profile) in GitHub Copilot CLI.

## Prerequisites

- [GitHub Copilot CLI](https://docs.github.com/en/copilot/concepts/agents/about-copilot-cli)
- Enrolled in Microsoft's [Frontier Preview Program](https://adoption.microsoft.com/copilot/frontier-program/)
- A Power Platform environment with Dataverse

## Install

```bash
git clone https://github.com/danielp370-msft/skill-agent365-mcp-setup.git ~/.copilot/skills/agent365-mcp-setup
```

Then in Copilot CLI, reload skills:

```
/skills reload
```

## Usage

Ask Copilot CLI to set up Agent 365 MCP servers:

```
Set up Agent 365 MCP servers
```

Or invoke the skill directly:

```
Use the /agent365-mcp-setup skill to connect to Microsoft Teams MCP server
```

The skill will:
1. Discover available MCP servers (via MCPManagement, docs, or built-in list)
2. Ask which servers you want to install
3. Look up your Power Platform environment ID
4. Add the selected servers to `~/.copilot/mcp-config.json`

## License

MIT
