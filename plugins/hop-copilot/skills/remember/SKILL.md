---
name: remember
description: >
  Store a memory entry for a specific PO. Use this skill whenever Carlos says
  "remember that [PO]...", "note for [PO]: ...", "for [PO]'s next review: ...",
  "I want to give [PO] feedback on...", "praise [PO] for...", "remember: [PO] agreed to...",
  "note: [PO] and I decided...", or any request to save a persistent note about a PO
  that should surface in future pulse checks. Also triggers for dev roster corrections
  like "Note: [Dev Name] is [role]" or "remember: [Dev] works on [team]".
---

# Remember — PO Memory Entry

This skill stores persistent notes about POs that surface in future pulse checks. These are things that matter for 1:1s, reviews, and management decisions but aren't captured in Jira or Confluence.

## Categories

| Category | When to use | Example |
|----------|------------|---------|
| `feedback_to_give` | Carlos wants to give the PO specific feedback | "Remember: I need to tell Mo his sprint planning has been sloppy lately" |
| `praise` | Something the PO did well, to acknowledge in 1:1 | "Praise Mo for the e-world demo prep — it was excellent" |
| `agreement` | A decision or commitment between Carlos and the PO | "Mo and I agreed: Vulkan CRM pushed to Q4 at earliest" |
| `priority_override` | A priority or focus area Carlos wants to enforce | "Mo should focus on Data Lake above everything else until May" |
| `concern` | Something Carlos is worried about regarding the PO | "I'm concerned Mo is spreading too thin across 16 initiatives" |
| `context` | General context useful for future interactions | "Mo will be out the second week of next sprint" |
| `dev_roster_correction` | Corrects the inferred dev roster | "Note: Developer X is backend, not dashboard" |

## Process

### Step 1 — Parse the statement

Extract:
- **PO name** — match against `config.json` PO roster using name, short_name, or jira_display_name
- **Content** — the actual thing to remember
- **Category** — infer from context (see table above). If ambiguous, ask Carlos.
- **Related initiative** — if the note mentions a specific initiative (e.g., "PMPO-9886" or "Data Lake"), capture the key

### Step 2 — Confirm and save

Present the entry to Carlos for confirmation:

"I'll save this for [PO name]'s memory:
- **Content:** [parsed content]
- **Category:** [inferred category]
- **Related:** [initiative or 'General']

Confirm? [Yes / Edit / Cancel]"

On confirm: generate a UUID, set `created_at` to now, `source` to "manual", `status` to "active", and append to `HoP/.hop-copilot/memory/{po_short_name}.json`.

On edit: let Carlos rephrase, re-confirm.

### Step 3 — Acknowledge

"Saved. This will surface in the next pulse check for [PO name]."

### Special case: Dev roster corrections

If the note is about a developer's role or team assignment:
1. Save as memory entry with category `dev_roster_correction`
2. Also note: "This will override the inferred role for [Dev] in the dev roster cache on next refresh."
3. Do NOT modify the dev roster cache directly — it gets updated during the next pulse-check refresh cycle.

## Managing existing entries

Carlos can also say:
- "Mark [entry] as addressed for [PO]" → set status to `addressed`, set `addressed_at`
- "Archive [entry] for [PO]" → set status to `archived`
- "What do I have noted for [PO]?" → read and display all active entries from `memory/{po_short_name}.json`
- "Clear all notes for [PO]" → archive all active entries (with confirmation)

## State Files

- **Memory:** `HoP/.hop-copilot/memory/{po_short_name}.json`
- **PO Roster (for name matching):** `HoP/.hop-copilot/config.json`
