---
name: remember
description: >
  Store a memory entry for a specific PO or initiative. Use this skill whenever Carlos says
  "remember that [PO]...", "note for [PO]: ...", "for [PO]'s next review: ...",
  "I want to give [PO] feedback on...", "praise [PO] for...", "remember: [PO] agreed to...",
  "note: [PO] and I decided...", or any request to save a persistent note about a PO
  that should surface in future pulse checks. Also triggers for dev roster corrections
  like "Note: [Dev Name] is [role]" or "remember: [Dev] works on [team]".
  Also triggers for initiative metadata like "remember: PMPO-XXXX is called [name]",
  "code-name for [initiative] is [name]", "don't use [term] in reports",
  or "[initiative] is also known as [alias]".
---

# Remember — PO & Initiative Memory Entry

This skill stores persistent notes about POs and initiative metadata that surface in future skill runs. These are things that matter for 1:1s, reviews, reporting, and management decisions but aren't captured in Jira or Confluence.

## Categories

### PO Memory Categories

| Category | When to use | Example |
|----------|------------|---------|
| `feedback_to_give` | Carlos wants to give the PO specific feedback | "Remember: I need to tell Mo his sprint planning has been sloppy lately" |
| `praise` | Something the PO did well, to acknowledge in 1:1 | "Praise Mo for the e-world demo prep — it was excellent" |
| `agreement` | A decision or commitment between Carlos and the PO | "Mo and I agreed: Vulkan CRM pushed to Q4 at earliest" |
| `priority_override` | A priority or focus area Carlos wants to enforce | "Mo should focus on Data Lake above everything else until May" |
| `concern` | Something Carlos is worried about regarding the PO | "I'm concerned Mo is spreading too thin across 16 initiatives" |
| `context` | General context useful for future interactions | "Mo will be out the second week of next sprint" |
| `correction` | Corrects a factual error the system made | "Jonian is a PM, not a developer" |
| `preference` | Suppresses or changes how something appears in output | "Don't flag Igor carrying multiple initiatives as a capacity concern" |
| `dev_roster_correction` | Corrects the inferred dev roster | "Note: Developer X is backend, not dashboard" |

### Initiative Metadata Categories

| Category | When to use | Example |
|----------|------------|---------|
| `code_name` | Maps a code-name to an initiative | "Remember: PMPO-8724 is code-named TRI-PARK" |
| `display_name` | Sets the public-facing name | "Remember: PMPO-8724 should be called Comfort Parking" |
| `sensitivity` | Marks terms as restricted | "Don't use 'Trier' in any external reports — use 'Phoenix' instead" |
| `alias` | Adds an alternative name | "TRI-PARK is also known as Comfort Parking" |
| `grouping` | Notes parent-child or related initiative relationships | "NPS is a separate initiative, NOT part of IUO" |

## Process

### Step 1 — Detect Entry Type

**Initiative metadata** if the statement:
- Mentions a Jira key (PMPO-XXXX)
- Uses words like "code-name", "alias", "also known as", "don't use [term] in reports", "call it [name]"
- Refers to initiative grouping or relationships

**PO memory** if the statement:
- Mentions a PO by name
- Is about feedback, praise, agreements, concerns, context
- Is about a developer's role or team

**Ambiguous:** Ask Carlos which type.

### Step 2 — Parse and Confirm

#### For PO Memory

Extract:
- **PO name** — match against `config.json` PO roster (name, short_name, jira_display_name) and `non_po_people`
- **Content** — the actual thing to remember
- **Category** — infer from context (see table above). If ambiguous, ask Carlos.
- **Related initiative** — if the note mentions a specific initiative, capture the key

Present for confirmation:

"I'll save this for [PO name]'s memory:
- **Content:** [parsed content]
- **Category:** [inferred category]
- **Related:** [initiative or 'General']

Confirm? [Yes / Edit / Cancel]"

On confirm: generate a UUID, set `created_at` to now, `source` to "manual", `status` to "active", and append to `HoP/.hop-copilot/memory/{po_short_name}.json`.

#### For Initiative Metadata

Extract:
- **Jira key** — the PMPO-XXXX identifier
- **Metadata type** — code_name, display_name, sensitivity, alias, or grouping
- **Value** — the code-name, display name, restricted term, etc.

Present for confirmation:

"I'll save this to initiative metadata:
- **Initiative:** [PMPO-XXXX]
- **Type:** [metadata type]
- **Value:** [parsed value]
- **Restricted:** [true/false, for sensitivity entries]

This will be used by hod-report, portfolio-radar, and stakeholder-update skills.

Confirm? [Yes / Edit / Cancel]"

On confirm: read `HoP/.hop-copilot/memory/initiatives.json`, find or create the entry for this Jira key, update the relevant field, write back.

**Initiative entry schema:**
```json
{
  "jira_key": "PMPO-XXXX",
  "display_name": "Public Name",
  "code_name": "INTERNAL-CODE",
  "code_name_restricted": true,
  "customer_code_name": "Customer-Facing Name",
  "aliases": ["Alt Name 1", "Alt Name 2"],
  "sensitive_terms": ["Term to never use externally"],
  "sensitive_terms_note": "Why and what to use instead",
  "grouping_notes": "Not part of X, is separate",
  "added_at": "ISO date",
  "added_by": "manual",
  "archived": false
}
```

### Step 3 — Acknowledge

**PO memory:** "Saved. This will surface in the next pulse check for [PO name]."

**Initiative metadata:** "Saved. Skills that produce reports (hod-report, portfolio-radar, stakeholder-update) will use this."

### Special case: Dev roster corrections

If the note is about a developer's role or team assignment:
1. Save as memory entry with category `dev_roster_correction`
2. Also note: "This will override the inferred role for [Dev] in the dev roster cache on next refresh."
3. Do NOT modify the dev roster cache directly — it gets updated during the next pulse-check refresh cycle.

### Special case: General corrections

If Carlos says something like "remember: the Feature Team is NOT external" or "Igor is a Project Manager, not a team lead":
1. Save to the relevant PO or general memory file
2. **Also propose:** "This looks like a general rule. Should I update `editorial-rules.json` in the plugin repo so all skills learn this permanently?"
3. If Carlos approves: note it for the next plugin repo update session.

## Managing existing entries

Carlos can also say:
- "Mark [entry] as addressed for [PO]" → set status to `addressed`, set `addressed_at`
- "Archive [entry] for [PO]" → set status to `archived`
- "What do I have noted for [PO]?" → read and display all active entries from `memory/{po_short_name}.json`
- "Clear all notes for [PO]" → archive all active entries (with confirmation)
- "Show initiative metadata" → read and display all non-archived entries from `memory/initiatives.json`
- "Archive [initiative] metadata" → set `archived: true` for that Jira key

## State Files

- **PO Memory:** `HoP/.hop-copilot/memory/{po_short_name}.json`
- **Initiative Metadata:** `HoP/.hop-copilot/memory/initiatives.json`
- **PO Roster (for name matching):** `HoP/.hop-copilot/config.json`
