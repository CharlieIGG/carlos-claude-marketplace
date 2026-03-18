---
name: capture
description: >
  The personal automation backlog for the Head of Product. Use this skill whenever Carlos says
  "capture", "log this", "I keep doing X manually", "I need help automating", "add to my backlog",
  "show my backlog", "what should I automate next", "review my improvement backlog",
  "what's on my automation list", or describes any repetitive task or pain point he wants to
  eventually automate. Also triggers when he says "this is something I need help with" or
  "I wish this was automated". This is the foundational skill of the hop-copilot plugin —
  it's the memory system that powers continuous improvement.
---

# Capture & Backlog — Personal Automation Improvement System

This skill manages Carlos's personal backlog of automation opportunities. It's the foundation of the continuous improvement loop: capture pain points as they arise, analyze them, prioritize them, and track which ones have been automated.

## How It Works

There are three modes: **capture**, **review**, and **plan**.

## Mode 1: Capture

When Carlos describes a pain point or repetitive task, do this:

1. **Parse the input.** Extract: what the task is, how often it happens, how long it takes, and any tools involved (Jira, Confluence, email, meetings, etc.)

2. **Categorize it.** Pick the best fit:
   - `recurring_manual` — Something done on a regular schedule (weekly status checks, monthly reports)
   - `data_pull` — Gathering information from multiple sources to make a decision
   - `communication` — Drafting emails, updates, meeting prep, stakeholder reporting
   - `oversight` — Checking on PO delivery, sprint health, documentation freshness
   - `compliance` — GDPR, NIS2, DPIA, processor agreements
   - `other` — Anything that doesn't fit

3. **Assess automation potential.** Consider:
   - Can an existing hop-copilot skill handle this? (pulse-check, stakeholder-update, triage)
   - Can an existing PM copilot skill handle this? (concept-craft, ticket-craft, etc.)
   - Would this need a new skill?
   - Is this better handled by a scheduled task?

4. **Estimate effort to automate:**
   - `low` — Can be done by configuring an existing skill or writing a simple prompt
   - `medium` — Needs a new skill or significant extension of an existing one
   - `high` — Requires new MCP integrations, complex multi-tool workflows, or external tooling

5. **Calculate priority.** Priority = frequency × time_per_occurrence / effort_to_automate. Higher is better.

6. **Write to backlog.** Read `HoP/.hop-copilot/backlog.json`, add the new item, write it back.

7. **Confirm to Carlos.** Show a brief summary:
   ```
   Captured: "Check if POs updated Confluence pages"
   Category: oversight | Frequency: weekly | Time: 20 min
   Automation: Could extend pulse-check skill | Effort: low
   Priority: HIGH
   Backlog now has N items.
   ```

8. **Offer next step.** If automation is low-effort, offer: "Want me to build this now, or just park it?"

## Mode 2: Review

When Carlos asks to see or review his backlog:

1. **Read `HoP/.hop-copilot/backlog.json`**

2. **Present items sorted by priority**, grouped by status:
   - Items ready to automate (captured, high priority)
   - Items in progress
   - Items already automated
   - Items deferred

3. **Highlight quick wins** — items with `low` effort and `high` priority.

4. **Show time savings** — sum up estimated time saved per week/month from automated items.

5. **Suggest next action:** "Your top 3 quick wins would save you ~X minutes per week. Want me to tackle one?"

## Mode 3: Plan

When Carlos asks to plan automation for a specific backlog item:

1. **Read the item** from backlog.json

2. **Draft an automation plan:**
   - Which skill(s) to use or create
   - What inputs are needed (Jira JQL queries, Confluence page IDs, etc.)
   - What the output should look like
   - Whether it should be a manual skill invocation or a scheduled task
   - Dependencies on MCP tools or connectors

3. **Update the item status** to `planned`

4. **Ask for approval** before building

## Confluence Sync (Optional)

When Carlos asks to sync the backlog to Confluence, update his personal space page with the current backlog summary. Use the confluence-delta-patch tools to update a section called "Automation Backlog" on his personal page. This section should show the priority-sorted list with status badges.

**Important:** Only sync to Carlos's personal Confluence space (`~157977632`). Never make this visible to others unless explicitly asked.

## State File Location

- **Backlog:** `HoP/.hop-copilot/backlog.json`
- **Config:** `HoP/.hop-copilot/config.json`

Always read the current file before writing to avoid overwriting concurrent changes.
