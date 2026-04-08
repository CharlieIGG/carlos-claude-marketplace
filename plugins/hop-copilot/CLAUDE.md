# HoP Copilot — Head of Product Automation Plugin

Personal automation system for Carlos Garcia, Head of Product at endios GmbH.
This plugin complements the product-management-copilot (which helps POs with initiative work) by focusing on Carlos's meta-responsibilities: oversight, coordination, stakeholder communication, and continuous self-improvement.

## Design Philosophy

**"Always ask, but learn."** Every skill starts by showing you its output for approval. When you approve something 3+ times without changes, it asks: "Want me to just do this automatically next time?" You decide per-task. Approval history is tracked in `.hop-copilot/approvals.json`.

**"Quick capture, continuous improvement."** Anytime you notice a repetitive task or pain point, capture it. The backlog grows organically and becomes your personal automation roadmap.

## Automation Opportunity Detection

When Carlos explicitly mentions a repetitive task, pain point, or manual process, you may offer to log it to the automation backlog. Do NOT evaluate this after every response — only react when the mention is obvious and direct. Never append meta-commentary about whether the condition was met.

## State Storage

- **Local state:** `HoP/.hop-copilot/` directory (config, backlog, approvals, snapshots, memory)
- **Confluence mirror:** Personal space page 157977632 for visibility outside Cowork (deferred)
- Local is source of truth; Confluence sync is optional and always to your personal (private) space

## Shared Constants

- **Atlassian Cloud ID:** `7be40122-285f-443a-8a38-c3c7ba7c6447`
- **Personal Confluence Space:** `~157977632`
- **Component Ownership Page:** 4397531168 (PRO space)
- **Component Database:** database 4923719682 (PRO space)
- **Initiative Docs Root:** page 3414392845 (PRO space)
- **Documentation Conventions:** page 3452960789 (PRO space)
- **AIPM Capacity Planning KB:** page 5505875973 (PRO space)
- **Strategy Page:** page 4825874466 (PRO space)
- **Jira Plans:** Plan ID 3, Scenario 54 (roadmap rank via `ORDER BY rank ASC` in JQL)
- **PO Roster Config:** `HoP/.hop-copilot/config.json`
- **Automation Backlog:** `HoP/.hop-copilot/backlog.json`
- **Approval History:** `HoP/.hop-copilot/approvals.json`
- **PO Snapshots:** `HoP/.hop-copilot/snapshots/{po_short_name}/{YYYY-MM-DD}.json` (last 3 per PO)
- **PO Memory:** `HoP/.hop-copilot/memory/{po_short_name}.json` (persistent, no auto-expiry)
- **Portfolio Snapshots:** `HoP/.hop-copilot/snapshots/portfolio/{YYYY-MM-DD}.json` (last 4)
- **Portfolio Memory:** `HoP/.hop-copilot/memory/portfolio.json` (persistent, portfolio-level observations)

## Cross-Plugin References

This plugin complements `product-management-copilot`. It does NOT duplicate those skills. Instead:
- For initiative-level concept work → use `product-management-copilot:concept-craft`
- For ticket writing → use `product-management-copilot:ticket-craft`
- For Confluence editing → use `product-management-copilot:confluence-ops`
- For Figma extraction → use `product-management-copilot:figma-extract`

This plugin focuses on:
- **Your personal productivity** (capture, backlog, self-improvement loop)
- **Team oversight** (PO pulse checks with roadmap context, delivery tracking, nudging, persistent memory)
- **Portfolio strategy** (portfolio-radar: cross-initiative overview, capacity conflicts, shipping pipeline, strategic balance)
- **Stakeholder communication** (update drafts, reporting)
- **Incoming request management** (triage, routing, logging)

## Skill Interconnections

Skills in this plugin are aware of each other and of PM-Copilot skills:
- `portfolio-radar` suggests `pulse-check [PO]` when a risk traces to a PO, `stakeholder-update` when C-suite-watched items change, and PM-Copilot skills (`/assess`, `ticket-craft`, `concept-craft`) for initiative-level deep dives.
- `pulse-check` suggests PM-Copilot skills in its AI tooling action cards when relevant to a PO's work.
- `stakeholder-update` can suggest `portfolio-radar` if triggered without enough context ("run portfolio-radar first to gather the data").
- PM-Copilot suggestions are only made when `endios-product-management-copilot` is installed. If unavailable, silently skip.

## PO Oversight Context

Carlos manages 5-6 POs, each owning distinct product areas. The pulse-check skill gives strategic 1:1 prep briefings with: roadmap rank context, deep initiative health (ticket counts, sprint assignment, dev engagement, fix version alignment, timeline overrun detection), follow-through tracking on commitments, snapshot-based progress comparison, PO activity analysis, shared meeting prep detection, and persistent memory for feedback/praise/agreements.

Key design decisions:
- **Config stores stable data only** (names, domains, components). Initiatives, sprint status, and docs are queried live at runtime — never cached.
- **Snapshots** store summary-level data for diff comparison (last 3 per PO). Full Jira data is NOT cached.
- **Memory** is persistent (no auto-expiry). Entries surface in pulse checks until Carlos marks them addressed.
- **Dev roster** is derived from Jira board membership and sprint assignees, with Carlos corrections overriding inference.
- **Activity analysis** flags if >20% of PO's visible Jira activity is on non-top-3 ranked work.
- **Capacity rules** follow AIPM: one major initiative per developer at a time, 70-80% dev time on initiative work.

## Capacity Planning Reference

The pulse-check skill references endios capacity planning rules documented at page 5505875973. Key rules the skill checks for:
- One major initiative per developer at a time (scheduling violations flagged)
- Backend-before-dashboard dependency pattern
- Epic-to-team alignment (one team per epic)
- Timeline overrun tolerance: ≤1 sprint = minor, >1 sprint = significant
