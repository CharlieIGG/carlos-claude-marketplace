---
name: pulse-check
description: >
  Strategic 1:1 prep and PO oversight briefing. Use this skill whenever Carlos asks to
  "check on" a PO, "pulse check", "how is [PO name] doing", "prep for my 1:1 with",
  "what's the status of [PO name]'s work", "are POs on track", "delivery check",
  "who needs a nudge", "check all POs", or any request to understand where a PO stands.
  Also triggers when Carlos mentions preview sessions, follow-ups, or deadline tracking
  for his POs. This skill produces an opinionated chief-of-staff briefing — NOT a Jira
  report. It synthesizes data into strategic insight with roadmap rank context, tracks
  follow-through on commitments, flags blind spots, detects capacity conflicts, compares
  against previous snapshots, and gives Carlos sharp recommendations he can act on.
---

# PO Pulse Check v3 — Strategic 1:1 Briefing

This skill gives Carlos a sharp, opinionated briefing before a 1:1 or team sync. It is NOT a data dump — Carlos can look at Jira himself. The value is in **synthesis, judgment, and blind-spot detection**: placing every initiative in its roadmap rank context, tracking follow-through on commitments, analyzing developer engagement, detecting timeline overruns, and surfacing things the PO (or Carlos) might be neglecting.

## Core Principles

1. **Think like a Head of Product, not a project manager.** The goal is to help Carlos make better decisions about his POs, not to police metrics. Ask "what should Carlos be thinking about?" — not "what's off from the norm?" Every observation must connect to a strategic question Carlos can act on.
2. **Understand the PO's current phase.** A PO in a shaping phase (concept, research, exploration) looks very different from one in execution (sprints, dev handoff, QA). Activity spread across many topics is NORMAL during shaping — the question isn't "are they focused?" but "is the shaping producing decisions, or is it spinning?" Flag the difference.
3. **Visibility over deadlines.** Carlos manages through visibility, conversation, and strategic nudges — not by enforcing hard due dates. "No due date" is not always a problem. The real question: does Carlos have enough signal to know if this initiative is healthy? If the work has clear momentum (tickets moving, devs engaged, decisions being made), a missing date is low-priority. If the work is opaque AND has no date, THAT's a concern.
4. **Follow-ups must be specific and contextualized.** Not "write to Michael" but full context with initiative, person, and purpose. Apply memory corrections aggressively — if Carlos said something is a non-topic, it never appears again.
5. **Deep initiative health for top 3.** Open ticket counts per epic, dev engagement, timeline risks. But interpret, don't just count — connect the numbers to what they mean for Carlos's decisions.
6. **Progress tracking via snapshots.** Each run saves a snapshot; next run diffs to show what moved and what stalled.
7. **Persistent PO memory.** Feedback, praise, agreements, corrections, preferences — things that matter for 1:1s but aren't in Jira. Memory entries with category `correction` or `preference` MUST be applied as hard filters on all future output. The skill must get smarter with each run.
8. **AI & tooling awareness.** When relevant, surface opportunities where the PO could work faster using AI tools, the endios Product Management Plugin, Claude, or other available automation. This is particularly valuable for POs who are early in adopting these workflows.
9. **Minimum cognitive load.** Default output scannable in <30 seconds. Every bullet, every row, every action must earn its spot. If Carlos could figure it out himself by glancing at Jira, don't include it.

## Step 0 — Load Context & Build Filters

1. Read `HoP/.hop-copilot/config.json` → PO roster (stable data), dev roster cache
2. Read `HoP/.hop-copilot/memory/{po_short_name}.json` → active memory entries (create empty file `{"entries": []}` on first run)
3. Read latest snapshot from `HoP/.hop-copilot/snapshots/{po_short_name}/` → previous state for diffing. If no snapshot exists, note "first run, no baseline."
4. Load the PO's `domain` and `domain_description` from config — critical for strategic alignment assessment
5. If `dev_roster_cache` is missing or `last_refreshed` > 2 weeks, trigger dev roster refresh (see Dev Roster Refresh section below). Step 1 queries can proceed in parallel.

**Build memory filters (CRITICAL — apply throughout all subsequent steps):**
- Extract all memory entries with `category: "correction"` → these override Jira data. Examples: ticket re-attribution ("PMPO-9764 is Carlos's work, not Tiep's"), context corrections ("Carlos said parallel, not sequential").
- Extract all entries with `category: "preference"` → these are hard suppression filters. Examples: "omit AVV topic from follow-ups," "don't flag Liquid Glass research as scatter."
- Build a **suppression list** from preference entries. For each preference, extract keywords and entities (person names, initiative abbreviations, topic phrases). Matching rule: if a Granola follow-up, Jira ticket summary, or activity item contains ≥2 keywords from the same preference entry, suppress it. Single-keyword matches are weak — only suppress if the keyword is highly specific (e.g., "AVV" is specific enough alone; "timeline" is not).
- Build a **correction map** from correction entries: ticket keys, assignee re-attributions, or context overrides. Apply corrections before any analysis — memory always wins over raw Jira data. Example: if memory says "PMPO-9764 is Carlos's work," exclude PMPO-9764 from the PO's activity count entirely.
- Build an **enablement list** from preference entries that APPROVE certain activities (e.g., "Liquid Glass research is desired"). These prevent the approved activity from being flagged as scatter or distraction in any output.

**Determine scope:**
- **Single PO mode:** Carlos names a specific PO → deep briefing for that person.
- **All POs mode:** Carlos says "check all" or "who needs a nudge" → quick-scan all, flag who needs attention, offer to deep-dive.

**Determine timeframe:**
All data-gathering windows use the **same timeframe**: since last snapshot date (or 14 days on first run). This ensures Granola follow-ups, Jira activity, dev engagement, and meeting load all cover the same period.

## Step 1 — Gather Data (all in parallel where possible)

### 1a. Initiatives by Roadmap Rank

CRITICAL: Use Jira REST API **v3** (`/rest/api/3/search/jql`), NOT v2 (deprecated). When using OR in JQL, always parenthesize per-project.

```
JQL: project = PMPO AND type = Initiative AND status != Done AND assignee = '[jira_display_name]' ORDER BY rank ASC
Fields: summary, status, priority, duedate, labels, fixVersions
```

Rank position = array index in the result set (Jira Plans rank reflected via `ORDER BY rank`).

**Priority field:** Jira's native priority (Critical/High/Medium/Low). Distinct from roadmap rank — an initiative can be High priority but ranked #15.

### 1b. Deep Dive: Top 3 Ranked Committed Initiatives

"Active" means status = In Development, Wrap-up & Release, Research, Concept, or Pre-Development — any initiative the PO is currently working on. "Committed to delivery" is a narrower set: In Development or Wrap-up & Release only. Deep dive the **top 3 active** initiatives (by rank), but note which are committed to delivery vs. still in shaping.

NOT included: Roadmap Candidate, Proposed, Prioritized (Waiting), Ready for Prioritization.

For each of the **top 3 committed initiatives** (by rank):

**Epic breakdown:**
```
JQL: parent = [INITIATIVE_KEY] AND type = Epic
Fields: summary, status, assignee, duedate, fixVersions, labels
```

**Story/task counts per epic:**
```
JQL: parent = [EPIC_KEY]
Fields: summary, status, assignee, sprint, duedate, fixVersions
```

**Compute per epic:**

| Metric | How to compute | What it signals |
|--------|---------------|-----------------|
| Total / Open / In Progress / Done | Count by status category | Overall progress |
| In Sprint (%) | Open tickets with active sprint ÷ total open | Planning maturity |
| Assigned to Dev (%) | Tickets where assignee is in `dev_roster_cache` ÷ total open | Handoff — are devs actually engaged? |
| Assigned to PO/Igor/Joni | Assignee matches PO name, "Igor", or "Joni" | Not yet handed off to development |
| Timeline overrun | Open ticket sprint end dates vs. initiative due date | Schedule risk |

**Timeline & visibility assessment rules:**
- If initiative has a due date: compare latest sprint end dates against it. Overrun ≤1 sprint → ⚠️ minor. >1 sprint → 🔴 significant.
- If initiative has NO due date: do NOT automatically flag. Instead assess VISIBILITY:
  - Can Carlos see momentum? (tickets moving, devs assigned, epics progressing) → mention "no date, but visible momentum" — low concern
  - Is the work opaque? (few tickets, unclear progress, no dev activity) → flag "low visibility — Carlos can't tell if this is on track without asking"
  - The question is never "set a due date" — it's "does Carlos have the signals he needs?"
- Ignore completed tickets (historical sprint dates)

**Fix version / release alignment:**
- Check if initiative or epics have `fixVersions`
- If yes: look up the release target date. If >30% of tickets still open and release <4 weeks away → ⚠️
- If no fixVersions: note "No release version attached"
- If fixVersion has no target date: note "Fix version [name] has no target date — cannot assess alignment"

**Phase transition health check (per initiative):**
- If status = "In Development" + >50% epics Done + remaining epics are Tentative/Wrap-up → may be ready for Wrap-up & Release. Flag: "Is [Init] ready for wrap-up, or are the remaining epics still needed?"
- If status = "Research" or "Concept" + last status change >21 days ago (check snapshot or Jira changelog) + no new ticket creation → possible stall. Flag: "Has [Init] stalled in [phase], or is there a decision pending?"
- If status changed since last snapshot: auto-include in the Lead: "[Init]: [Old Status] → [New Status]."
- If top-3 set changed since last snapshot (different initiatives): flag in Lead: "[PO]'s priorities shifted — [old] dropped, [new] entered top-3."

**Developer engagement check:**
For each developer assigned to tickets in this initiative:
```
JQL: assignee = '[dev_display_name]' AND sprint in openSprints() AND parent NOT IN ([this_initiative_epics])
```
- >2 tickets from other initiatives in current sprint → capacity conflict
- >5 tickets from other initiatives → significant conflict
- Dev on epics from 2+ active initiatives → scheduling violation per AIPM capacity rules ("one major initiative per developer at a time")
- Cross-reference with `dev_roster_cache` for team and role

### 1c. Follow-ups from Previous 1:1

**Query scope:** Meetings since last snapshot date. First run: last 14 days.

Query Granola: "What action items, commitments, or follow-ups were agreed between Carlos and [PO full name] in recent meetings? Include the full context for each item — what specifically it's about, which initiative or topic it relates to, and why it was discussed."

**Pre-filter (BEFORE validation):**
- Cross-check every extracted follow-up against memory suppression list (built in Step 0). If a follow-up matches a `preference` filter (topic, person, or keyword pattern), silently skip it. Do not mention skipped items.
- Cross-check against memory `correction` entries. If a correction changes the context of a follow-up (e.g., "Carlos said parallel iteration, not sequential"), apply the correction before presenting.

**Validation rules:**
1. **Specificity check:** Does the item reference a specific initiative, person, or decision artifact (Confluence page, ticket, epic)? AND is the desired outcome explicit (what should change, how will it be confirmed)?
2. **Clarity to Carlos:** Would Carlos immediately understand what this is about without additional context? If not: one targeted Granola query for context. **Maximum 2 follow-up queries per item.** If still unclear: omit from default output, save in snapshot with note "Context insufficient — needs Carlos's clarification."
3. **Name disambiguation:** First-name-only references (e.g., "Michael") → cross-reference meeting attendee list and known people in config/memory. If ambiguous: "Unclear which [name] — needs Carlos's clarification."
4. **Priority relevance:** Does it tie to a current top-3 initiative, stakeholder commitment, or active memory concern? If not → mark Low. If Low + no evidence of incompletion → omit entirely.

**Importance tagging:**
- **High:** Tied to top-3 initiative, stakeholder commitment, deadline, or strategic decision
- **Medium:** Tied to active initiative outside top-3, or team process improvement
- **Low:** Side-topic, informational, not tied to current priorities

**Completion evidence check:**
For each item, search:
- Jira: ticket created/transitioned matching the action
- Confluence: page created/updated matching the topic
- Granola: subsequent meeting confirming completion
- Teams/Outlook: message sent matching the topic
- If nothing found: "No evidence found in Jira/Confluence/messages — may have been done outside tracked channels"

**Omission rules:**
- Low-importance + no evidence of incompletion → omit from output (save in snapshot)
- Low-importance + incomplete → show at bottom of table, flagged low
- High/medium → always show

**Carlos's own action items:** Same treatment. Same directness. Don't soften.

### 1d. Shared Meetings Requiring Prep

Query Outlook calendar for meetings in next 2 weeks where both Carlos and this PO are attendees. Store results in snapshot for drill-down.

**Default output rule:** Only surface a meeting in the Lead (Block 1) if ALL of these are true:
- Meeting is in <2 days
- A previous 1:1 follow-up or memory entry explicitly references prep for this meeting (e.g., "Carlos asked Mo to present X at Friday demo")
- OR meeting subject contains "Demo," "Sprint Review," or "Strategy" AND the PO has a committed initiative tied to the meeting topic

Carlos manages his own calendar — don't repeat it back to him. Only flag meetings where the pulse check adds insight (e.g., connecting a meeting to an initiative risk or unresolved follow-up).

**All other meetings:** Available via `meetings` drill-down only.

**Fallback if Outlook fails:** "Could not check shared meetings — Outlook access issue."

### 1e. PO Activity Analysis

**Jira activity:**
```
JQL: assignee = '[jira_display_name]' AND updated >= '[last_snapshot_date or -14d]'
Fields: summary, status, parent, sprint, issuetype
```

**Categorization rules:**
- "top-3 initiative work": parent epic's parent initiative is in PO's top-3 ranked
- "other initiative work": parent traces to an initiative NOT in top-3
- "support/bugs": support project, type = Bug, or support-related labels
- "other/unclassified": no parent epic, or parent can't be traced to an initiative
- Tickets with no epic parent (kanban-style): classify as "other"

**Percentages:** Count tickets per category. Present as: "Top-3: X% | Other initiatives: Y% | Support/bugs: Z% | Unclassified: W%"

**Phase detection algorithm (run BEFORE interpreting activity spread):**

Determine the PO's current phase using this priority order:
1. **Check memory** for explicit phase context (e.g., "Liquid Glass research is desired" → research activity is approved).
2. **Infer from the PO's initiative statuses** (not just committed — include Concept and Pre-Dev):
   - ≥2 in "In Development" or "Wrap-up & Release" with active sprints → **Execution phase.** Expect >50% on top-3. Note scatter but don't alarm.
   - Top-ranked initiatives are in "Concept," "Research," or "Pre-Development" with 0 in active execution → **Shaping phase.** Expect activity spread across estimation, research, stakeholder alignment, benchmarking. This is NORMAL. The only question: is the shaping producing output artifacts?
   - All/most in "Concept" + "Pre-Development" → **Early shaping.** This is a specific sub-phase — the PO is building the next wave. Don't expect focused execution. Look for: concepts being documented, research completed, tickets being created as prep. Activity in estimation, benchmarking, and customer validation is healthy and expected.
   - Top initiative in "Wrap-up & Release" → **Wrap-up phase.** Expect focus on that initiative.
   - Mix of execution + shaping → **Hybrid.** Flag the mix itself: "[PO] is juggling shaping AND execution — is that intentional?"
3. **Present the phase explicitly** in the Status Strip or Lead: "[PO] is in [phase]" — this frames everything else.

**Interpretation (phase-aware, not threshold-based):**
- Do NOT use a hard 20% threshold. Instead: describe the pattern, name the phase, and ask the strategic question.
- **Shaping phase strategic question:** "Is the shaping producing decisions? Look for: concepts completed, initiatives advancing to next status, tickets being created, Confluence pages published. If none of these in 2+ weeks → possible stall."
- **Execution phase strategic question:** "Is the execution producing shipped code? Look for: tickets moving to Done/Ready to Release, dev engagement, QA activity. If ticket counts aren't decreasing → possible block."
- **Wrap-up phase strategic question:** "Is wrap-up actually wrapping up? Look for: release dates being set, documentation happening, handoff to operations. If PO is already scoping next initiative heavily → premature context-switch."

**Meeting load (supplementary):** Outlook query for PO's meetings in the period. >15/week = heavy.

**Message signals (supplementary):** Teams query for PO messages. Look for support patterns, ad-hoc requests. Supplementary only — Jira is primary.

## Step 2 — Diff Against Previous Snapshot

If no previous snapshot: skip, note "First pulse check — baseline created."

Otherwise compare:

| Dimension | What to diff | Presentation |
|-----------|-------------|-------------|
| Initiative status | Status changes | "PMPO-9886: Prioritized → In Development" |
| Rank changes | Position shifts | "Overlays: #4 → #6, dropped from top-3 deep dive" |
| Open ticket counts | Per-epic deltas | "BE epic: 8→5 open (+3 closed). Metabase: 4→4 (no movement)" |
| Sprint coverage | % open in sprints trend | "Sprint coverage: 40% → 65%" |
| Dev assignment | Dev vs. PO assignment trend | "2 tickets moved from PO to devs" |
| Follow-ups | Previous open items status | "Pilot outreach: was ❓, now ✓ (Mar 20 meeting)" |
| Memory entries | Still-active entries from last check | "Feedback re: doc quality — still active (3 weeks)" |

## Step 3 — Synthesize Briefing

### Two-Tier Output: Headline Mode (default) + Drill-Down Mode (on request)

All 8 sections of data are still **computed and stored in the snapshot**. But the default output is compressed to 3 blocks targeting a Cognitive Load Index of ~40. Carlos can expand any area on demand.

---

### DEFAULT OUTPUT: Headline Mode (target: scannable in 30 seconds)

**Block 1 — The Lead (max 5 bullets, no tables)**

A short bullet list — one bullet per topic, each 1–2 sentences max. Contains only:
- The 1–3 sharpest things Carlos needs to know RIGHT NOW
- Any meeting requiring prep in <3 days
- If snapshot diff exists: the single most important change since last check

**Bullet prioritization (when >5 candidate signals compete):**
1. 🔴 Hard overruns or blockers (missed milestones, blocked initiatives)
2. Phase transition signals (status changes since last snapshot)
3. Strategic paradoxes (data contradicts expectations)
4. Meetings requiring prep in <2 days (only if connected to initiative risk)
5. Everything else → defer to Action Card or drill-down

Style: direct, opinionated, conversational. No hedging. No "it appears that." Each bullet is a distinct topic — never merge unrelated signals into one bullet. Example:
> - Overlays missed code freeze yesterday — 13/26 open, new scope crept in via a dashboard migration epic.
> - DTA is 7 weeks out but most epics have zero tickets — either the work is off-Jira or the breakdown hasn't happened.
> - Overlays handover meeting Friday — Mo will need to explain what shipped vs. what didn't.

**Block 2 — Action Card (max 3 items)**

The recommended actions with verbatim questions Carlos can use in the 1:1. These must be **strategic questions that help Carlos think** — not metric-policing or deadline-enforcement. The question should open a conversation, not demand an answer.

Format per item:
```
🔴/⚠️ [One-line action description]
→ "[Exact question or statement Carlos can say]"
```

**Generation logic — decision-support, not metric-policing:**

Actions should surface **paradoxes, blind spots, and strategic questions** — not restate data. Priority order:

1. **Initiative health paradoxes** — when data tells a story that contradicts expectations.
   - Example: "Top-ranked initiative has 0 assigned devs despite being 'In Development' for 4 weeks" → "Is DTA blocked on something besides capacity?"
   - Example: "Concept phase initiative has ticket breakdown already" → "Is [PO] confident enough to skip concept review?"
2. **Phase transition signals** — is the PO's work advancing, or stuck?
   - Example: "Research done 3 weeks ago, no concept started" → "What's blocking the move from research to concept?"
   - Example: "3/4 BE stories Ready to Release but no wrap-up activities started" → "Should we start planning the release?"
3. **Visibility gaps** — things Carlos can't assess from available data.
   - Example: "Tiep's Liquid Glass work doesn't map to any initiative" → "Is this tracked informally, or should it become an initiative?"
4. **Unresolved commitments with unclear status** — only genuinely important ones. Apply memory preference filters: if Carlos marked a follow-up as non-topic, it NEVER appears here.
5. **AI/tooling opportunities** — specific, actionable suggestions tied to the PO's current work.
   **Trigger conditions (check in order):**
   - PO has an initiative in Concept phase → suggest `concept-craft` for user flows, edge cases, data models
   - PO has epics needing ticket breakdown → suggest `ticket-craft` for story creation with acceptance criteria
   - PO has an initiative needing competitive analysis → suggest `benchmark-craft` or `research-craft`
   - PO has Confluence documentation gaps → suggest `documentation-craft`
   - PO has a Figma URL or design review pending → suggest `figma-extract`
   - Memory entry mentions Carlos wants PO to use AI tools → always include at least one AI suggestion, tied to the PO's most relevant current initiative
   **Format:** "[Initiative name] is in [phase] — [specific skill] could help [specific task] faster."
   - NEVER generic ("use AI more"). Always: specific initiative + specific skill + specific task.

**Quality gate (apply to EVERY action before including):**
- "Would Carlos already know this from glancing at Jira?" → CUT.
- "Does this help Carlos THINK about a decision, or just REACT to a metric?" → REFRAME or CUT.
- "Does this contradict a memory correction?" → CUT.
- "Does this conflict with a memory preference?" (e.g., preference says "visibility not deadlines" but action says "set a due date") → CUT.
- "Does this overlap with an enablement-list item?" (e.g., flagging research that memory says is approved) → CUT.
- "Is this the same type of action I generated last time?" → If not acted on (check approval history), reframe or cut.

**Block 3 — Status Strip (one compact table)**

| Initiative | Health | Done | Next Milestone | Flag |
|-----------|--------|------|----------------|------|

One row per committed initiative. Health is 🔴/🟡/🟢 based on **strategic assessment, not thresholds**:
- 🔴 = hard overrun (missed a committed milestone like a code freeze), blocked with no workaround, or zero visible progress on an active initiative
- 🟡 = low visibility (Carlos can't tell if it's healthy without asking), phase transition stalling, or approaching a milestone with signs of risk
- 🟢 = clear momentum visible in the data — tickets moving, devs engaged, phase transitions happening
- Note: "no due date" alone is NEVER 🔴. It contributes to 🟡 only when combined with low visibility.

Non-committed initiatives as a summary footer: "+N Prioritized (Waiting), M Roadmap Candidates, K Proposed"

**Footer:**
```
Drill down? → initiatives | follow-ups | activity | meetings | deep dive [name] | memory | diff
```

---

### DRILL-DOWN MODE: Expanded Sections (on request)

When Carlos types a drill-down keyword, expand that section with full detail. Each drill-down is self-contained — no need to re-read the headline output.

**`initiatives`** — Full initiative portfolio table:

| Rank | Initiative | Status | Priority | Due | Tickets (Open/Total) | Signal |
|------|-----------|--------|----------|-----|---------------------|--------|

All committed initiatives with rank. Non-committed as summary rows.

**`deep dive [name]`** — Full epic-level breakdown for one initiative:

```
### #[rank] [Name] ([key]) — Due [date] — ⏱️ [weeks] left

| Epic | Status | Assignee | Total | Open | In Sprint | Dev Assigned | Overrun |
|------|--------|----------|-------|------|-----------|-------------|---------|

🔧 Dev engagement: [conflicts if any]
📦 Fix versions: [alignment check]
📈 Since last check: [delta from snapshot, if available]
```

**`follow-ups`** — Full follow-through check table:

| # | Item | Owner | Imp. | Context | Evidence |
|---|------|-------|------|---------|----------|

Sorted by importance (high first). Low items omitted unless incomplete.
Apply memory-based filters: items tagged `preference` to omit in memory → skip silently.

**`activity`** — Activity & focus analysis:

| Category | Count | % | Signal |
|----------|-------|---|--------|

Plus meeting load summary and support pattern observations.

**`meetings`** — Upcoming meetings needing prep:

| Date | Meeting | Who Preps | Urgency |
|------|---------|-----------|---------|

Only meetings matching keyword rules or with explicit prep requests.

**`memory`** — Active memory entries:

| Entry | Category | Since | Related |
|-------|----------|-------|---------|

Entries created between snapshots shown as "New since last check."

**`diff`** — Progress since last check (skip on first run):

| Dimension | Last Check | Now | Delta |
|-----------|-----------|-----|-------|

---

### Drill-Down Chaining

Carlos can request multiple drill-downs in one message: "follow-ups and deep dive Overlays" → expand both. The drill-down output should still be concise — no re-stating the lead or action card.

## Step 4 — Save Snapshot

After presenting the briefing:
1. Compile current state into snapshot JSON (summary data only — see `references/state-schema.md` for schema)
2. Save to `HoP/.hop-copilot/snapshots/{po_short_name}/{YYYY-MM-DD}.json`
3. If >3 snapshot files exist, delete the oldest
4. Include list of active memory entry IDs in the snapshot
5. Memory entries created between snapshots (via `remember` command) that aren't in the prior snapshot's ID list: show as "New since last check" in the diff, not as anomalies

## Step 5 — Memory Extraction (post-briefing, batch)

After Carlos reviews and reacts:

1. Scan conversation for memorable items: feedback given/implied, agreements, concerns, praise, preferences about the pulse check itself
2. Present **all candidates as a numbered list** in one message — each with suggested category. Carlos can respond with shorthand: "1 approve, 2 skip, 3 approve, 4 edit: [new text]" or "approve all" / "skip all"
3. Save approved/edited items to `HoP/.hop-copilot/memory/{po_short_name}.json` immediately
4. Include **meta-memory** candidates: preferences about what to omit, format preferences, follow-ups Carlos declares irrelevant — these prevent future noise
5. After all processed (or Carlos says "that's enough") → done

**Also check:** Memory entries from previous checks that should be marked `addressed`? If briefing shows completion, or Carlos confirms during discussion, offer to mark as addressed.

## Dev Roster Refresh

**Trigger:** Automatic when pulse-check detects `dev_roster_cache` missing or `last_refreshed` > 2 weeks.

**Method:**
1. For each team (OP, AGENCY, FTP): `project = [KEY] AND sprint in openSprints()` — collect unique assignees
2. Also query last 2 closed sprints to catch devs not in current sprint
3. Infer role per assignee:
   - OP project + epic contains "Backend" or "BE" → backend
   - OP project + epic contains "Dashboard" or "DASH" → dashboard
   - AGENCY or FTP project → mobile
   - Ambiguous → tag `inferred_from: "needs_confirmation"`
4. Merge with existing cache — Carlos corrections (stored as memory entries with category `dev_roster_correction`) always override inference
5. Update `last_refreshed` timestamp

**Correction workflow:** Carlos says "Note: [Dev] is [role], not [inferred]" or uses the `remember` command with dev roster context. These are stored as memory entries and applied on next refresh.

## Anti-Patterns (DO NOT DO THESE)

- ❌ **Acting like a project manager** — "set a due date," "assign to sprint," "close overdue tickets." Carlos can do this himself. The skill's job is strategic insight.
- ❌ **Flagging "no due date" as a default concern** — only flag when combined with low visibility. A healthy initiative without a date is fine.
- ❌ **Hard-coding activity % thresholds** (like ">20% = flag") — understand the PO's phase first. Shaping looks like scatter; execution looks like focus. Neither is inherently wrong.
- ❌ **Repeating data Carlos can see in Jira** — if it takes 30 seconds to find in Jira, don't include it. Only surface synthesis, connections, and blind spots.
- ❌ **Generic actions** like "Follow up on overdue items" or "Review sprint coverage"
- ❌ **Vague follow-ups** without full context (initiative, person, purpose)
- ❌ **Default output that takes >30 seconds to read** (target CLI-40; drill-downs can be longer)
- ❌ **Dumping all 8 sections by default** — use headline mode; expand only on request
- ❌ **Showing data justification in the Action Card** — just the action and the words to say
- ❌ **Ignoring memory corrections** — if Carlos said "X is a non-topic," X must NEVER appear again. Memory entries with `correction` or `preference` category are hard filters.
- ❌ **Missing the forest for the trees** — don't get lost in ticket counts when the real story is about whether a PO is making progress, stuck, or being pulled in too many directions
- ❌ **Attributing work to the wrong person** — always verify ticket assignee before claiming a PO is working on something. Cross-check with memory for known corrections.

## State Files

- **PO Roster & Config:** `HoP/.hop-copilot/config.json`
- **Snapshots:** `HoP/.hop-copilot/snapshots/{po_short_name}/{YYYY-MM-DD}.json`
- **Memory:** `HoP/.hop-copilot/memory/{po_short_name}.json`
- **Approval History:** `HoP/.hop-copilot/approvals.json`

## Approval Tracking

After Carlos reviews the pulse check:
- If he approves without changes → log to `HoP/.hop-copilot/approvals.json` with `task_type: "pulse_check_[po_short_name]"`
- After 3 consecutive approvals without changes, offer: "Your pulse checks for [PO] have been consistent. Want me to auto-generate these before each 1:1 and just notify you?"
- If Carlos gives critical feedback, capture specifics and adjust future runs. Store feedback patterns in approvals.json under a `feedback` field.
