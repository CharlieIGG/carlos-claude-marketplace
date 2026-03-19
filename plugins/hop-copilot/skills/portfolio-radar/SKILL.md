---
name: portfolio-radar
description: >
  Strategic portfolio overview and risk radar for the Head of Product. Triggers on:
  "check the portfolio", "portfolio radar", "initiative overview", "what's at risk",
  "what's shipping soon", "top initiatives", "radar highlights", "radar important",
  "radar all", "radar [PMPO-key]", "prep for steering committee", "what should I worry about".
  Also triggers for follow-up investigation requests after the initial radar output, like
  "check Teams for evidence that Mo is handling X" or "has anyone discussed Y recently?"
  This skill detects blind spots (prerequisites that should exist but don't), assesses
  timeline certainty against evidence, computes ETAs, and supports interactive investigation.
---

# Portfolio Radar — Strategic Initiative Risk Detection

This skill answers: **"What's at risk in the portfolio, and what is nobody tracking?"**

It replicates Carlos's roadmap scan (rank order → timeline warnings → ticket gaps → who to talk to) and adds three layers he can't do manually in 5 minutes:
1. **Blind spot detection** — prerequisites that should exist but don't have evidence
2. **Certainty assessment** — does the data support the current timeline certainty label?
3. **Interactive investigation** — Carlos asks follow-up questions, the skill searches data sources for evidence

**This is NOT a Jira dashboard.** Carlos can read Jira himself. The value is in surfacing what's MISSING — the contract nobody's tracking, the pilot nobody's kicked off, the spec that doesn't exist yet.

## Relationship to Other Skills

- **vs. pulse-check:** Pulse-check is per-PO, prep for 1:1s. Portfolio Radar is cross-portfolio, Carlos's own strategic view.
- **vs. /assess:** /assess deep-dives one initiative's concept quality (PO-facing). Portfolio Radar evaluates strategic position and prerequisites (HoP-facing). Typical flow: Radar flags a stuck initiative → Carlos runs /assess to understand why.
- **vs. stakeholder-update:** Independent but aware. If Radar detects status changes on initiatives that stakeholders care about, it suggests running stakeholder-update.

## Width Modes

| Mode | Trigger | Scope | Use case |
|------|---------|-------|----------|
| **Highlights** | `radar`, `radar highlights` (default) | Top 10 by rank + any In Development/Wrap-up initiative with `jira_escalated`, `capacityPlanningFocus`, or a missed milestone that falls outside the top 10 | Quick weekly check |
| **Important** | `radar important` | Priority ≥ High AND status ≥ Prioritized (Waiting) | Steering committee prep |
| **All** | `radar all` | All initiatives ≥ Prioritized (Waiting), max 30 | Full portfolio audit |
| **Focus** | `radar [PMPO-key]` | Single initiative deep dive | Investigate one initiative |

## Step 0 — Load Context

1. Read `HoP/.hop-copilot/config.json` → PO roster, dev roster cache
2. Read `HoP/.hop-copilot/memory/portfolio.json` → per-initiative memory entries + portfolio-level observations (create `{"entries": []}` on first run)
3. Read latest snapshot from `HoP/.hop-copilot/snapshots/portfolio/` → previous state for diffing
4. Build memory filters: suppression list, correction map, enablement list (same pattern as pulse-check)

## Step 1 — Gather Data

### 1a. Initiatives by Rank

```
JQL: project = PMPO AND type = Initiative AND status NOT IN (Done, Rejected) ORDER BY rank ASC
Fields: summary, status, priority, duedate, labels, fixVersions, assignee
```

Apply the width mode filter to determine which initiatives to include.

For each included initiative, extract:
- **Certainty label (current):** look for `HighCertainty`, `MediumCertainty`, `LowCertainty`, `VeryLowCertainty` in labels. If none → "Unlabeled."
- **Existing signal labels:** `jira_escalated`, `capacityPlanningFocus`, `tsg_alignment`, and any other relevant labels.

### 1b. Epic + Ticket Health (for In Development and Wrap-up initiatives)

For each initiative in Development or Wrap-up:
```
JQL: parent = [INITIATIVE_KEY] AND type = Epic
Fields: summary, status, assignee, duedate, fixVersions, labels
```
Then for active epics:
```
JQL: parent = [EPIC_KEY]
Fields: summary, status, assignee, sprint, duedate, fixVersions
```

Compute per initiative: total tickets, open, done, % complete, dev assignees, sprint coverage.

### 1c. ETA Computation

For each initiative, compute a **derived ETA** using this priority chain:

1. **Initiative has a due date in Jira** → use it as primary ETA.
2. **No initiative due date → roll up from epics:** take the latest epic due date among active (non-Done) epics.
3. **No epic due dates → roll up from stories/tasks:** take the latest sprint end date among open tickets.
4. **Mobile work rule:** If any epic is in AGENCY or FTP project, OR has "Mobile" / "iOS" / "Android" / "Foundation" in the epic name → find the associated code freeze fix version. **ETA = code freeze date + 2 weeks** (QA, release, app store review). If this is LATER than the rolled-up ETA, use the code freeze + 2 weeks instead.
5. **Nothing computable** → "No ETA derivable."

Present: `ETA: [date] (source: [initiative due date / epic rollup / sprint rollup / code freeze + 2w])`

### 1d. Certainty Assessment

For each initiative, assess whether the current certainty label matches observable evidence.

**Signals that push toward HIGHER certainty:**
- >70% of stories Done or In Progress
- Open tickets assigned to sprints
- Dev actively transitioning tickets this sprint
- Remaining work fits in remaining time (math checks out)
- External dependencies confirmed (contracts signed, API access — from Confluence or initiative memory)
- Code freeze alignment: mobile tickets will be done before freeze

**Signals that push toward LOWER certainty:**
- >50% of stories still To Do or Unrefined
- Open tickets without sprint assignment
- No dev activity on assigned tickets in 2+ weeks
- Remaining work exceeds remaining time
- External dependencies unknown or unconfirmed (blind spots)
- Code freeze misalignment: mobile tickets won't make the freeze
- Missed milestone (code freeze, due date already past)

**Output:** For each initiative where assessed certainty differs from the current label:

1. State the current label and the recommended label
2. List the specific signals (from the tables above) that drive the recommendation
3. **Show the math when applicable:** `Open tickets: X | Avg completion rate: Y/sprint | Sprints remaining: Z | Projected completion: [date] vs. ETA: [date]`. If projected > ETA → timeline pressure is real. If projected < ETA → timeline has buffer.
4. If the recommendation is based on blind spots (missing prerequisites) rather than ticket math, say so: "Assessment driven by missing prerequisites, not ticket velocity."

Carlos must be able to verify the recommendation from the data shown — never ask him to trust the assessment on faith.

### 1e. Blind Spot Detection

For each initiative, based on its current status and what's approaching in the next 4-6 weeks, check: **"What SHOULD be true right now for this to stay on track?"**

**Initiatives in Concept or Pre-Development (about to enter development):**
- Is there a concept page in Confluence, updated within the last 30 days?
- Are external contracts/partnerships signed? (search Confluence for partner/contract pages, search initiative memory)
- Is test environment / API access confirmed?
- Are epics created with stories broken down?
- Are dev teams aware and capacity allocated? (check dev roster for assignments)

**Initiatives In Development (mid-stream):**
- Are stories assigned to sprints? (>50% of open tickets should have sprint)
- Are devs actively transitioning tickets? (status changes this sprint)
- If mobile work: is there a code freeze target fix version?
- Are blockers aging? (any Blocked ticket >1 sprint old)
- If backend work is supposed to precede dashboard/mobile: is the BE epic ahead of others?

**Initiatives approaching Wrap-up / Release:**
- Is there a release date or fix version with a date?
- Are pilot customers confirmed? (search Confluence, Granola, initiative memory)
- Is a pilot kickoff meeting scheduled? (search Outlook)
- Is documentation being prepared? (search Confluence for recent doc updates)

**For each prerequisite:** Search Jira, Confluence, Granola, and initiative memory for evidence.

**Evidence quality tiers:**
- **Confirmed** — Recent, explicit evidence (ticket exists and is moving, Confluence page updated this month, meeting notes from last 2 weeks confirming it). → Prerequisite met.
- **Probable** — Reasonable inference from recent activity (someone discussed it in a meeting, a related ticket exists but isn't specific). → Note "likely handled, not confirmed" — don't flag as blind spot, but mention in focus mode.
- **Stale** — Evidence exists but is >30 days old and status unknown. → Flag: "Last evidence [date] — may need verification."
- **Not found** — No evidence in any searchable source. → Blind spot. BUT: acknowledge the limitation — some things (contracts, partner comms, legal agreements) may live in email, GDrive, or other systems the skill can't search. Frame as: "[Prerequisite] — no evidence found in Jira/Confluence/meetings. Carlos may need to verify directly."
- **Contradictory** — Conflicting signals across sources. → Flag both signals, recommend Carlos verify.

Auto-create blind spot memory entries for "Not found" and "Stale" items. Mark as `needs_carlos_verification` when the prerequisite is likely tracked outside searchable systems (contracts, legal, partner comms).

**On subsequent runs:** Check if previously flagged blind spots now have Confirmed or Probable evidence → auto-resolve in memory (`blind_spot_resolved`). Stale items that are now >60 days old → escalate visibility.

### 1f. Cross-Initiative Capacity Analysis

For each developer appearing in active initiative epics:
- How many In Development initiatives are they assigned to?
- **Critical conflict:** 2+ In Development initiatives → name the dev, name the initiatives, note which is higher-ranked.
- **Moderate:** In Development + Concept/Research split → usually manageable.
- Aggregate: "X developers have critical capacity conflicts."

### 1g. Portfolio Pipeline Health

- **Shipping pipeline:** Initiatives with ETA in next 8 weeks, listed chronologically.
- **Shaping pipeline:** Initiatives in Concept/Research/Pre-Development. Any status changes in last 30 days?
- **Phase transitions since last snapshot:** Which initiatives changed status?
- **Net change since last check:** What's new, what finished, what was postponed?

## Step 2 — Diff Against Previous Snapshot

If no snapshot: "First portfolio radar — baseline created."

Otherwise:
- Status changes (phase transitions)
- Rank changes (promoted/demoted)
- Certainty label changes (manual or from previous radar recommendation)
- Blind spot resolution (flagged → resolved, or still open)
- New blind spots
- ETA shifts (computed ETA moved earlier or later)
- Capacity conflict changes

## Step 3 — Synthesize Output

### DEFAULT OUTPUT (CLI-40 target)

**Block 1 — The Lead (max 5 bullets)**

Risk-first. Only portfolio-level signals.

Bullet prioritization:
1. 🔴 Blind spots on top-ranked initiatives (prerequisites missing)
2. Certainty mismatches (label says Medium but evidence says Low/VeryLow)
3. Capacity conflicts affecting In Development initiatives
4. Phase transitions or ETA shifts since last check
5. Portfolio balance concerns (nothing shipping? shaping stalled?)

**Block 2 — Portfolio Strip (table)**

| # | Initiative | PO | Status | Certainty (Current → Assessed) | ETA | Blind Spots |
|---|-----------|-----|--------|-------------------------------|-----|-------------|

- When current = assessed → show just the label: "🟡 Medium"
- When they differ → show both: "🟡 Medium → 🟠 **Low**"
- Blind Spots column: count, or "—" if none
- Row count follows the width mode (10 / filtered / 30)
- Summary footer for initiatives outside the mode scope

**Block 3 — Action Card (max 3 items)**

HoP-specific decisions only. Not PO-level actions.

Priority:
1. **Blind spots requiring Carlos's intervention** — prerequisites that only Carlos can unblock (contracts, stakeholder alignment, capacity reallocation)
2. **Certainty adjustments** — "X initiatives need label updates"
3. **Capacity allocation decisions** — "Dev Y is split across initiatives A and B — which takes priority?"

**Block 4 — Certainty Adjustments (if any)**

```
Certainty adjustments pending (N):
  1. DTA v2.0: Medium → Low (6/8 BE epics have no tickets, 7 weeks to deadline)
  2. Overlays v1.3: Low → VeryLow (code freeze missed, no revised timeline)
  3. Spark v1.0: Medium → Low (no release date despite Wrap-up status)

Approve? → "approve all" | "approve 1, skip 2" | "skip all"
```

On approval: apply the label change in Jira immediately. Log in initiative memory with reason.

**Footer:**
```
Drill down? → [PMPO-key] | blind spots | capacity | pipeline | certainty | memory | diff

Investigate? → "check Teams/Granola/Confluence for [topic] about [initiative/person]"
```

### DRILL-DOWN & FOCUS MODE

When Carlos requests a drill-down on a specific initiative (`radar PMPO-9886` or from the Portfolio Strip), the skill gathers data from ALL available sources — not just Jira:

**Data sources for drill-down (query in parallel):**
- **Jira:** Epic/ticket breakdown, status, assignees, sprint assignment, fix versions
- **Confluence:** Concept pages, decision logs, partner docs — check recency (last modified date)
- **Teams:** Recent messages mentioning the initiative name, key, or related keywords — status discussions, blockers, informal decisions
- **Granola:** Meeting notes mentioning the initiative or PO — commitments, action items
- **Outlook:** Upcoming meetings related to the initiative (kickoffs, demos, partner calls)
- **Initiative memory:** Previously flagged blind spots, certainty adjustments, Carlos's notes

This multi-source synthesis is the value — it shows what's happening across ALL channels, not just what's in tickets.

**Focus mode output:**

```
### [Initiative Name] ([key]) — Rank #[N] — [Status]

📍 Portfolio: #[rank] of [total]. [Certainty label]. ETA: [computed].
👤 PO: [name].
📊 Progress: [ticket summary]. [Epic health].
⚡ Capacity: [devs assigned, conflicts].
📅 Timeline: [ETA breakdown — source, code freeze if applicable].
🔍 Blind spots: [list of missing prerequisites, or "None detected"]
💬 Recent signals: [Teams/Granola/Outlook evidence — what's being discussed outside Jira]
📝 Memory: [active memory entries for this initiative]

Certainty: [Current] → [Assessed] — [signals justifying assessment]

**Draft message to PO:**
[Copy-paste-ready message — see CTA rules below]

**Related:**
- `/assess [key]` — concept quality deep-dive (PM-Copilot)
- `pulse-check [PO]` — PO's full workload
- `stakeholder-update` — if communication needed
```

### CTA Message Rules

Every "→" suggested action and "Draft message to PO" must be **copy-paste-ready for Teams** and follow these rules:

1. **Lead with context** — Tell the PO what Carlos sees and why he's reaching out. The PO should immediately understand the situation.
2. **Acknowledge what's going well** — If there IS progress, name it. Prevents the message from feeling like pure escalation.
3. **Name the specific gap** — Not "things are behind" but "the 6 ETL epics starting Mar 29 don't have stories yet."
4. **End with a concrete CTA that drives progress** — Not a yes/no question. Ask for a deliverable, a decision, or an update by a specific time.
5. **Never frame as interrogation** — Collaborative tone: "I want to make sure we're aligned" not "Why haven't you done this?"

**Example (bad — yes/no, no context):**
> "Mo, the ETL epics start in 3 weeks and there's no spec. Is this being designed off-Jira?"

**Example (good — contextual, progress-driving):**
> "Mo, I'm looking at DTA and the Emit Events epic is moving well — Hamdi has 4 tickets in code review, nice. But the next 6 ETL epics (starting Mar 29–Apr 19) don't have stories yet, and the Metabase decision is still pending sign-off per the Confluence page. Can you put together a breakdown plan for the remaining epics this week and let me know who needs to sign off on Metabase? I want to make sure we're not hitting May 8 without dev clarity."

## Step 4 — Post-Radar Investigation Mode

After the radar output, the skill stays active for freeform evidence-check requests. Carlos can ask things like:

- "Check Teams for evidence that Mo is handling the DTA pipeline design"
- "Has anyone discussed cleverPV test API access in recent meetings?"
- "Is there a Confluence page for the CNS v3.1 scope?"
- "Did Moritz mention the DYNT concept in any recent 1:1?"

**For each investigation request:**
1. Identify the data source(s) to search: Teams (`chat_message_search`), Granola (`query_granola_meetings`), Confluence (`searchJiraIssuesUsingJql` or `getConfluencePage`), Outlook (`outlook_email_search`, `outlook_calendar_search`)
2. Execute the search with targeted queries
3. Return findings with **evidence quality tier** (Confirmed / Probable / Stale / Not found / Contradictory — same tiers as blind spot detection):
   - **Confirmed:** "Found Teams messages from Mo this week actively discussing ETL pipeline design with Hamdi. 3 messages, most recent yesterday." → High confidence.
   - **Probable:** "Granola notes from Mar 13 mention Mo agreed to handle pipeline specs, but no follow-up evidence since." → Medium confidence — was discussed but completion unconfirmed.
   - **Stale:** "Confluence page about DTA architecture exists but was last updated Jan 15." → Low confidence — may not reflect current state.
   - **Not found:** "Searched Teams, Granola, Confluence — no results matching [query]." → Absence of evidence, not evidence of absence. Carlos may need to check directly.
   - **Contradictory:** "Teams message says 'API access confirmed,' but Confluence page says 'pending.' Most recent signal: Teams (2 days ago)." → Present both, recommend Carlos verify.
4. **Offer to update initiative state based on tier:**
   - Confirmed → "This resolves the blind spot about [X]. Mark as resolved?"
   - Probable → "This suggests [X] is being handled. Mark blind spot as 'probable — needs confirmation'?"
   - Stale/Contradictory → "Evidence is unclear. Want me to flag this for follow-up in the next radar run?"
   - Not found → "No evidence found. Keep blind spot open, or do you know this is handled?"

Investigation findings feed directly back into memory, making the next radar run smarter.

## Step 5 — Save Snapshot

1. Save to `HoP/.hop-copilot/snapshots/portfolio/{YYYY-MM-DD}.json`
2. Keep max 4 snapshots
3. Include: all scanned initiatives with rank, status, certainty (current + assessed), computed ETA, blind spot count, capacity conflicts

## Step 6 — Memory Extraction (batch, post-session)

When Carlos is done with the radar (moves on to other work or says "that's it"):

**Auto-created entries (no approval needed):**
- `blind_spot_flagged` — each new blind spot detected (with initiative_key, description, date)
- `blind_spot_resolved` — previously flagged blind spots that now have evidence
- `certainty_adjusted` — labels Carlos approved changing (with reason)

**Candidate entries (ask Carlos):**
- `strategic_decision` — Carlos made a prioritization call during the session
- `stakeholder_commitment` — Carlos mentioned telling someone something
- `dependency` — Carlos identified a cross-initiative dependency
- `preference` / `correction` — hard filters for future runs

All entries stored in `HoP/.hop-copilot/memory/portfolio.json` with `initiative_key` field. In portfolio mode all entries surface; in focus mode only entries for that initiative.

## Blind Spot Checklist Extension

The prerequisite checklists in Step 1e are the primary extension point for making the skill smarter over time. When Carlos flags a blind spot the skill missed, or identifies a new pattern ("we always forget to set up test data before dev starts"), add it to the relevant phase checklist.

The skill should also learn from memory: if `blind_spot_flagged` entries cluster around a pattern (e.g., 3 initiatives in a row missing API access before dev), surface this as a portfolio-level observation: "Pattern: initiatives entering development frequently lack confirmed API access. Consider adding this to the pre-development checklist."

## Anti-Patterns

- ❌ Reporting initiative status Carlos can see in Jira in 30 seconds
- ❌ Per-initiative ticket counts without connecting them to a risk or blind spot
- ❌ Actions that belong to the PO ("break down your epics") — Carlos's actions only
- ❌ Flagging "no due date" on Roadmap Candidates or Proposed initiatives
- ❌ Generic advice ("review the roadmap", "align with stakeholders")
- ❌ Default output that takes >30 seconds to read
- ❌ Inventing labels or metadata systems Carlos didn't ask for
- ❌ Showing certainty assessments without explaining the specific signals behind them
- ❌ Silently replacing the current certainty label — always show current vs. assessed explicitly

## Known Limitations (to address in future iterations)

1. **Certainty cascade:** If initiative A's certainty drops and initiative B depends on A, the skill doesn't automatically flag B for review. Future: detect shared dependencies and surface cascade questions after batch approval.
2. **Memory growth:** Per-initiative memory entries accumulate unbounded. For now, `blind_spot_resolved` entries older than 90 days should be moved to an `"archived": true` flag on periodic review. Future: auto-archive and cap active entries.
3. **Data source coverage:** Some prerequisites (contracts, legal agreements, partner comms) live in systems the skill can't search (GDrive, email attachments, legal tools). Blind spot detection acknowledges this with `needs_carlos_verification` flag rather than claiming absence.

## State Files

- **Snapshots:** `HoP/.hop-copilot/snapshots/portfolio/{YYYY-MM-DD}.json`
- **Memory:** `HoP/.hop-copilot/memory/portfolio.json` (per-initiative entries + portfolio-level)
- **Config:** `HoP/.hop-copilot/config.json` (shared — PO roster, dev roster)
