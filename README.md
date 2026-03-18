# Carlos Claude Marketplace

Private Claude Code plugin marketplace.

## Plugins

### hop-copilot

Head of Product automation plugin for product leadership oversight at endios GmbH.

**Skills:** pulse-check, stakeholder-update, triage, capture, remember
**Commands:** /review (weekly improvement review)

## Install

```
plugin marketplace add CharlieIGG/carlos-claude-marketplace
```

Then install the plugin:

```
plugin install hop-copilot
```

## Prerequisites

The following MCP connectors should be available in your Claude Code environment:

- **Atlassian** — Jira + Confluence access
- **Granola** — meeting transcript queries
- **Microsoft 365** — Outlook calendar, Teams messages

## Companion Plugin

Works best alongside `endios-product-management-copilot` from the endios-toolbox marketplace. When both are installed, pulse-check suggests PM copilot skills (concept-craft, ticket-craft, benchmark-craft, research-craft, documentation-craft, figma-extract) to POs during briefings. If the PM copilot is not installed, those suggestions are silently skipped. The two plugins are independent but synergistic.

## State

On first run, skills create a `.hop-copilot/` directory in your workspace containing:

- `config.json` — PO roster, domain ownership, automation preferences
- `backlog.json` — automation opportunity backlog
- `approvals.json` — approval learning history
- `snapshots/` — point-in-time PO initiative snapshots
- `memory/` — persistent per-PO notes

These are per-user local state and are not part of the plugin.
