---
name: stakeholder-update
description: >
  Draft stakeholder status updates and executive reports. Use this skill whenever Carlos asks to
  "draft a stakeholder update", "write a status report", "prepare an executive summary",
  "compile initiative status", "write a progress report", "update leadership",
  "draft a steering committee update", "what should I report this week",
  "summarize initiative progress", "prepare my biweekly update", or any request to create
  a consolidated status communication for stakeholders, leadership, or steering committees.
  Also triggers for "what changed since the last update", "key decisions to report",
  or "risks to flag to leadership". This skill replaces 45-60 minutes of manual compilation
  by pulling initiative data from Jira and Confluence and drafting a structured update.
---

# Stakeholder Update Draft — Executive Reporting Assistant

This skill compiles initiative progress from Jira and Confluence into a polished stakeholder update that Carlos reviews and sends. It replaces the manual process of opening each initiative's Jira epic, checking Confluence for context, and writing an email or slide from scratch.

## When to Use

- Biweekly or weekly stakeholder updates
- Steering committee preparation
- Executive summary requests
- "What should I report?" moments

## Step 0 — Understand the Audience

Ask Carlos (if not already clear):
- **Who is the audience?** (Leadership, specific stakeholders, steering committee, all-hands)
- **What format?** (Email draft, Confluence page, presentation slide, markdown summary)
- **What period?** (Last 2 weeks, this sprint, this month)
- **Any specific topics to highlight or omit?**

If Carlos has done this before and the audience/format are the same as last time, use the same settings without asking.

## Step 1 — Gather Initiative Data

### From Jira

For each active initiative, pull:
- **Status:** Current phase (research, concept, development, testing, release)
- **Sprint progress:** Stories completed vs. planned this sprint
- **Blockers and risks:** Issues flagged as blockers, or epics with no progress
- **Key completions:** Stories or epics completed since the last update
- **Upcoming milestones:** What's planned for the next sprint/period

Use JQL patterns:
- Active initiatives: `type = Initiative AND status != Done`
- Recent completions: `project = PMPO AND status changed to Done AFTER -14d`
- Blockers: `priority = Blocker AND status != Done`

### From Confluence

For each initiative with documentation in PRO space:
- **Recent decisions** — look for decision logs or recently updated concept pages
- **Status changes** — pages updated since the last reporting period
- **Risk flags** — any warnings, blockers, or assumption changes noted in docs

### From Meetings (if available)

Check Granola meeting transcripts or calendar for:
- **Key decisions** from recent steering or planning meetings
- **Action items** assigned to Carlos or his team
- **Stakeholder requests** that need acknowledgment

## Step 2 — Draft the Update

### Email Format (default)

```
Subject: Product Update — [Date Range]

Hi [audience],

Here's the product update for [period].

**Highlights**
- [2-3 key achievements or milestones reached]

**Initiative Status**

| Initiative | Status | Progress | Next Milestone | Risk |
|---|---|---|---|---|
| [Name] | [Phase] | [X/Y stories] | [What's next] | [GREEN/YELLOW/RED] |
| ... | ... | ... | ... | ... |

**Key Decisions**
- [Decision 1 — context and impact]
- [Decision 2]

**Risks & Blockers**
- [Risk 1 — what it affects, what we're doing about it]
- [Risk 2]

**Looking Ahead**
- [What's planned for next period]
- [Any stakeholder input needed]

Best,
Carlos
```

### Confluence Page Format

Use the same structure but formatted for Confluence with status lozenges, Jira smart links, and collapsible sections for details.

### Presentation Slide Format

Produce a concise bullet-point summary suitable for a single slide or short deck. Focus on: highlights (3 max), risks (2 max), and one "looking ahead" bullet.

## Step 3 — Quality Checks

Before presenting the draft:

1. **Verify accuracy** — Do the numbers match what Jira shows? Flag any data you couldn't verify with `[NEEDS VERIFICATION]`.
2. **Check tone** — Is it appropriate for the audience? Executive summaries should be concise and action-oriented, not exhaustive.
3. **Flag gaps** — If you couldn't get data for an initiative, say so: "I couldn't find current sprint data for [initiative]. You may want to check with [PO name]."
4. **Compare to last update** — If a previous update exists, highlight what changed: new risks, resolved blockers, milestone shifts.

## Step 4 — Present for Review

Show the draft to Carlos with:
- The full update text
- A list of data sources used (which Jira queries, which Confluence pages)
- Any gaps or uncertainties flagged
- Suggested recipients (if known from previous updates)

Carlos reviews, edits, and sends.

## Step 5 — Log and Learn

After Carlos approves (or edits and approves):
- Log to `HoP/.hop-copilot/approvals.json` with `task_type: "stakeholder_update_[audience]"`
- Note what Carlos changed — this teaches the skill his preferences over time
- After 3 consecutive approvals for the same audience without changes, offer automation

## Stakeholder Feedback Integration

Carlos mentioned that keeping up with stakeholder feedback and expectations is a key pain point. When drafting updates, also:
- Check for recent incoming emails or Teams messages from known stakeholders about initiatives
- Flag any unaddressed stakeholder feedback that should be acknowledged in the update
- Suggest: "Stakeholder X asked about [topic] on [date]. Want to address it in this update?"

## State Files

- **Config:** `HoP/.hop-copilot/config.json`
- **Approval History:** `HoP/.hop-copilot/approvals.json`
