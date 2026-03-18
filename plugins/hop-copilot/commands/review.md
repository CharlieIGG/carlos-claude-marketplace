---
name: review
description: >
  Weekly review command. Triggers on "/review", "weekly review", "what did I automate this week",
  "improvement review", "how's my automation going". Consolidates backlog progress,
  triage stats, and proactively suggests new automation opportunities.
model: opus
---

# Weekly Review — Continuous Improvement Checkpoint

This command runs a weekly review of Carlos's automation journey. It consolidates everything from the week and proactively identifies new improvement opportunities.

## What It Does

### 1. Backlog Progress Report

Read `HoP/.hop-copilot/backlog.json` and report:
- Items captured this week (new pain points identified)
- Items moved to "automated" (victories!)
- Items in progress
- Total estimated time savings from automated items

### 2. Triage Stats

Read `HoP/.hop-copilot/triage-log.json` (if it exists) and report:
- Total requests triaged this week
- Breakdown by category (urgent/important matrix)
- Avg time from triage to resolution
- Patterns: repeated request types that might warrant a policy or FAQ

### 3. Approval Learning Summary

Read `HoP/.hop-copilot/approvals.json` and report:
- Tasks approaching auto-approval threshold (2 of 3 approvals done)
- Tasks recently auto-approved
- Any tasks where Carlos made changes after auto-approval (demote candidates)

### 4. Proactive Suggestions

Based on the week's activity, suggest:
- "You asked me to do [X] 3 times this week. Want to capture that as an automation candidate?"
- "The pulse check for [PO] keeps showing stale docs. Want to set up a scheduled reminder?"
- "You haven't done a stakeholder update in 3 weeks. Due for one?"

### 5. Health Check

Verify that state files are consistent and uncorrupted:
- backlog.json parseable and schema-valid
- approvals.json parseable
- config.json has populated PO roster

## Output Format

Present as a concise brief, not a wall of text:

```
# Weekly Review — [Week of Date]

## Automation Backlog: [N] items | [M] automated | ~[X] min/week saved

**This week:**
- Captured: [list or "none"]
- Completed: [list or "none"]
- Quick wins available: [list top 2]

## Triage: [N] requests this week
- [breakdown]
- Pattern spotted: [if any]

## Learning Progress
- [task] is 2/3 toward auto-approval
- [task] was auto-approved and worked fine

## Suggested Next Steps
1. [Most impactful suggestion]
2. [Second suggestion]
```

Then ask: "Anything from this week you want to capture or change?"
