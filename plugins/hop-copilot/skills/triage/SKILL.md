---
name: triage
description: >
  Incoming request triage and routing assistant. Use this skill whenever Carlos says
  "triage", "someone just asked me to", "new request from", "unplanned request",
  "how should I handle this request", "where should this go", "who should own this",
  "I got asked to", "prioritize this request", "should I take this on",
  "route this request", "delegate this", or describes an incoming request, interruption,
  or piece of feedback that needs to be categorized and acted on.
  Also triggers for "review my incoming requests", "what requests are pending",
  or "show me unplanned work from this week". Helps Carlos spend 2 minutes instead of 10
  on each interruption, and ensures nothing falls through the cracks.
---

# Incoming Request Triage — Categorize, Route, Respond

This skill helps Carlos quickly process unplanned requests, interruptions, and feedback from any source (Teams, email, meetings, Jira). Instead of mentally juggling priority, ownership, and response for each interruption, Carlos dumps the request here and gets a structured recommendation in seconds.

## When to Use

- A stakeholder pings with an urgent request
- Someone asks for a feature, change, or exception
- Feedback arrives that needs routing
- Carlos wants to review all unplanned requests from the week

## Mode 1: Triage a New Request

### Step 1 — Parse the Request

Ask Carlos (or extract from his message):
- **What:** What's being asked for?
- **Who:** Who asked? (stakeholder name, team, external partner)
- **When:** Is there a deadline or urgency signal?
- **Where:** Where did it come from? (Teams, email, meeting, Jira, verbal)
- **Context:** Any additional background?

### Step 2 — Categorize

Apply the Eisenhower matrix with product context:

| Category | Criteria | Action |
|---|---|---|
| **Urgent + Important** | Blocks a customer, production issue, compliance deadline, exec request with hard deadline | Carlos handles or delegates immediately |
| **Important, Not Urgent** | Valid feature request, process improvement, strategic input | Route to appropriate PO, add to backlog |
| **Urgent, Not Important** | Someone perceives urgency but it's not blocking anything critical | Acknowledge, set expectations, schedule appropriately |
| **Neither** | Nice-to-have, duplicate request, out of scope | Decline politely or defer indefinitely |

### Step 3 — Determine Ownership

Based on the request type and the PO roster:
1. Read `HoP/.hop-copilot/config.json` for PO product areas
2. Match the request to the most relevant PO based on product area
3. If it spans multiple areas, suggest which PO should lead and who should collaborate
4. If it's a platform/infrastructure request, route to the OP Platform Team

### Step 4 — Draft Response

Produce a response draft appropriate for the channel:

**For Teams/Slack:**
```
Hi [requester], thanks for flagging this. I've categorized it as [category] and
[PO name] will be the right person to evaluate this. I'll loop them in.
[If applicable: Expected timeline for a response is [X].]
```

**For email:**
A slightly more formal version with context and next steps.

**For Jira:**
Suggest: reassign to the right PO, update labels/priority, add a comment.

### Step 5 — Log the Request

Save to a triage log for weekly review. Add an entry to `HoP/.hop-copilot/triage-log.json`:

```json
{
  "id": "auto-generated",
  "received_at": "ISO timestamp",
  "source": "teams | email | meeting | jira | verbal",
  "requester": "Name or team",
  "summary": "Brief description",
  "category": "urgent_important | important_not_urgent | urgent_not_important | neither",
  "routed_to": "PO name or team",
  "response_drafted": true,
  "status": "triaged | in_progress | resolved | declined",
  "resolution_date": null,
  "notes": ""
}
```

### Step 6 — Offer Follow-up

- "Want me to send this response via [channel]?"
- "Should I create a Jira ticket for this?"
- "Want me to add a follow-up reminder for [date]?"

## Mode 2: Review Incoming Requests

When Carlos asks to review pending requests:

1. Read `HoP/.hop-copilot/triage-log.json`
2. Show requests grouped by status (pending → in_progress → resolved)
3. Highlight overdue items (triaged but not resolved within expected timeframe)
4. Show weekly stats: how many requests, breakdown by category, avg response time
5. Identify patterns: "You've received 4 requests about [topic] this month. Worth creating a FAQ or policy?"

## Mode 3: Decline Templates

For requests that should be declined, offer templates:

**Not in scope:**
"Thanks for thinking of this. After reviewing it against our current priorities, this doesn't fit into our roadmap for [timeframe]. I'd suggest [alternative] or we can revisit in [quarter]."

**Duplicate:**
"Good news — this is actually already being worked on as part of [initiative]. [PO name] is leading it and I expect updates by [date]."

**Needs more info:**
"Interesting idea. Before we can evaluate this, we'd need [specific information]. Could you put together [brief description of what's needed]?"

## Approval Tracking

Same pattern as other skills: log approvals, offer automation after 3 consecutive no-change approvals for the same request type.

## State Files

- **Triage Log:** `HoP/.hop-copilot/triage-log.json` (created on first use)
- **Config:** `HoP/.hop-copilot/config.json`
- **Approval History:** `HoP/.hop-copilot/approvals.json`
