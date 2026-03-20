---
name: hod-report
description: >
  Generate the biweekly "Heads of Department Report" for the EDH Confluence space. Use this skill
  whenever Carlos asks to "write my HoD report", "department heads report", "HoD report",
  "write my biweekly report", "prepare the department report", "EDH report",
  "heads of department update", "write my CW report", or any request to create the biweekly
  product development status report for the department heads meeting. Also triggers for
  "what should go in the next department report", "prep for the department meeting",
  or "I need to write my report for Friday". This skill replaces 60-90 minutes of manual
  compilation by pulling initiative data, computing deltas, and publishing directly to Confluence.
---

# HoD Report — Heads of Department Biweekly Report Generator

This skill produces the biweekly product development status report that Carlos presents at the department heads meeting. It creates a Confluence page under the parent page `Product Team High-Level Reporting` (page ID: `3361472513`, space: `EDH`, space ID: `3350495235`).

**This is NOT the portfolio-radar.** The radar is Carlos's internal strategic tool (risk-first, blind spots, certainty labels). The HoD report is an external-facing peer report — balanced, narrative-driven, collegial. It tells other department heads what's happening in product development.

**This is NOT the stakeholder-update.** Stakeholder updates are flexible (any audience, any format). The HoD report has a rigid template, fixed audience, fixed Confluence location, and a specific narrative voice.

## Relationship to Other Skills

- **portfolio-radar →** feeds data INTO this report. The radar's certainty assessments and blind spots inform health labels and notes. Run radar first if no recent snapshot exists.
- **stakeholder-update →** independent. HoD report is more structured, always Confluence, always the same template.
- **pulse-check →** PO-level data may enrich the notes column, but pulse-check is per-PO; this report is per-initiative.

---

## PHASE 0 — STARTUP: Load References & Memory

### 0a. Load Shared References (from plugin `references/`)

Load these once — they frame all subsequent steps:
1. **`references/tool-rules.json`** — ADF construction rules, delta-patch limitations, JQL patterns, smart link base URL
2. **`references/editorial-rules.json`** — Terminology rules, HoD voice guide, health label vocabulary

### 0b. Load Skill Memory (from workspace `.hop-copilot/`)

3. **`memory/hod-report.json`** — Previous corrections and preferences (attribution rules, known errors to avoid)
4. **`memory/initiatives.json`** — Code-name mappings, sensitivity flags, display name overrides

Build filters from memory:
- **Sensitivity filter:** Extract all `sensitive_terms` from initiatives.json. Before publishing ANY content, scan for these terms and replace with `display_name` or `customer_code_name`.
- **Correction rules:** Extract all corrections from hod-report.json. Apply as hard constraints during composition (e.g., "never attribute BPW meeting content to HEMS").
- **Preferences:** Extract all preferences. Apply during composition (e.g., "use bullet points in Notes column").

### 0c. Load Latest Snapshot

5. **`snapshots/hod-report/{most_recent_date}.json`** — Previous initiative count, health labels, carried-forward sections
   - If no snapshot exists: note "first run" and fetch the most recent child page of parent `3361472513` to extract the previous report's data

---

## PHASE 1 — DATA GATHERING

### Step 1.0 — Determine Report Parameters

**Automatically derived:**
- **Report date:** Today (or tomorrow if Carlos says "for tomorrow")
- **CW range:** Calculate calendar weeks since last published report
  - Find most recent child page under parent `3361472513`
  - Extract date from page title (format: `YYYY-MM-DD (CW XX - YY)`)
  - New range: last report's YY+1 to current week

**Ask Carlos (only if ambiguous):**
- Any ad-hoc sections to include? (e.g., capacity changes, release calendar, cross-department topics)
- Any initiatives to highlight or downplay?
- Any "Points to-be-shared" items?

If Carlos doesn't specify ad-hoc sections, generate with fixed sections only and ask at the end.

### Step 1.1 — Active Initiative Census

```
JQL: project=PMPO AND type=Initiative AND status NOT IN (Done, Rejected, "Roadmap Candidate") ORDER BY rank ASC
Fields: key, summary, status, assignee, rank
```

**Extract:** Count = current active initiative count.
**Compute:** net_change = current_count - previous_count (from snapshot).

### Step 1.2 — Finished, Rejected, and Activated Since Last Report

```
# Query B: Finished and Rejected
JQL: project=PMPO AND type=Initiative AND status changed AFTER "[last_report_date]" AND status IN (Done, Rejected)
Fields: key, summary, status

# Query C: Newly Activated
JQL: project=PMPO AND type=Initiative AND status changed AFTER "[last_report_date]" AND status WAS IN ("Roadmap Candidate", "Proposed", "Prioritized (Waiting)", "Ready for Prioritization")
Fields: key, summary, status
```

**CRITICAL: Verify the math.**
```
current_count MUST = previous_count - finished_count - rejected_count + activated_count
```
If the equation doesn't balance, investigate: query for ALL status changes since last report and reconcile before proceeding. Do NOT publish a report with unexplained delta.

### Step 1.3 — Highlights Data (Initiatives Worth Reporting On)

For each initiative in status ∈ {In Development, Wrap-up & Release}:

1. **Epic health:** `parent = [INITIATIVE_KEY] AND type = Epic` → count by status
2. **Recent activity:** Check if any epics had status changes in the reporting period
3. **Fix version / code freeze alignment:** Check fixVersions and due dates

Also check initiatives in **Concept** or **Research** that are high-priority or have notable updates.

### Step 1.4 — Fresh Signals from Meetings

**Use targeted Granola queries — NOT full transcript reads.**

For each initiative in the highlights list, query:
```
query_granola_meetings(
  query="What decisions, progress updates, or blockers were discussed about [Initiative Name]?",
  date_range=[last_report_date, today]
)
```

**CRITICAL: Before attributing any meeting content to an initiative:**
1. Check the meeting title and full context
2. Verify the meeting was actually ABOUT that initiative, not just mentioning it in passing
3. Cross-reference with hod-report.json correction rules (e.g., "March 18 transcript is exclusively about BPW")
4. NEVER claim a meeting occurred without verifying it in the calendar. "Should schedule" ≠ "meeting held."

### Step 1.5 — Release Calendar (if relevant)

Check Jira fix versions and Teams for upcoming code freezes:
```
JQL: project in (OP, FTP, AGENCY) AND fixVersion in unreleasedVersions() ORDER BY duedate ASC
```

---

## PHASE 2 — COMPOSITION

### Page Title Format
```
YYYY-MM-DD (CW XX - YY)
```

### Fixed Structure

```
# Points to-be-shared

[Carlos's agenda items, if any. Ask Carlos or leave placeholder.]

# Product Development

## Overview of all running projects

[Jira dashboard embed — use iframe extension node with dashboard 11135, gadget 12588]

* There are **[N]** active product initiatives right now [±net change status lozenge]:
    * **Finished:** [Jira smart links]
    * **Started:** [Jira smart links]
    * **Rejected:** [if any]
    * **Paused:** [if any]

## Highlights on Running Projects

| **Initiative** | **Health** | **Notes** |
|---|---|---|
```

### Health Labels

Use ONLY these labels. Never invent new ones. Always compare to previous report's label.

| Label | ADF Color | Criteria |
|-------|-----------|----------|
| **good** | green | On track, no blockers, progress matching plan |
| **good?** | blue | Appears on track but unconfirmed aspects exist |
| **good, but...** | green | Fundamentally OK with a notable caveat |
| **fluctuating** | yellow | Mixed signals — some progress, some blockers/delays/uncertainty |
| **worsened** | red | Regressed since last report — timeline slipped, new blocker emerged |
| **TBD** | grey | Newly activated, insufficient data to assess |

### Notes Column Guidelines

For each highlighted initiative:
- Use **bullet points** to separate different topics within the cell
- Each bullet covers ONE aspect: progress, blocker, upcoming milestone, or decision
- Content must be **NEW since the last report** — cross-check with previous report's content
- Never repeat points from the previous report without new development
- **Tone:** Collegial and balanced. Not alarm-first (that's the radar).
- **Length:** 3-6 bullet points per initiative. Enough to be useful, short enough to scan.

**Before writing each note, check:**
1. Is this new since the last report? (Compare to snapshot's carried_forward_sections)
2. Does the meeting/source actually discuss this initiative? (Not just keyword match)
3. Am I using the correct initiative name? (Check initiatives.json for display names and sensitivity)
4. Am I attributing information to the correct initiative? (Review hod-report.json correction rules)
5. Does the initiative belong here or is it a sub-item of another? (Check Jira parent links — do not group unless Jira says so)

### Variable Sections

These appear as H1 sections at the same level as "Product Development," added after highlights when relevant:

- **Release Calendar Updates** — upcoming code freezes, release ETAs, schedule changes
- **Capacity Changes** — new hires, departures, team restructuring
- **Cross-Department Topics** — items needing other department heads' awareness
- **Statistics / Metrics** — user acquisition, push performance, app ratings
- **Experiments / Innovation** — AI experiments, process improvements

Only include a variable section if there's actual content.

### Quality Checks (before presenting to Carlos)

1. **Verify initiative count** — JQL count matches? Flag discrepancies.
2. **Verify net change math** — Show: `current(N) = previous(P) - finished(F) - rejected(R) + activated(A)`. Must balance.
3. **Compare health labels** — Did any change from last report? Call it out.
4. **Sensitivity scan** — Check ALL text against initiatives.json `sensitive_terms`. Replace violations.
5. **Terminology scan** — Check against editorial-rules.json `terminology.correct`. No "agency," no developer names, no code-names in restricted contexts.
6. **Smart links** — Every initiative name in the highlights table must have a Jira smart link.
7. **Staleness check** — Is any bullet a repeat of the previous report without new info? Cut it.
8. **Flag data gaps** — Mark uncertainties with `[NEEDS YOUR INPUT]`.

### Present for Review

Show Carlos a **markdown preview** of the full report. Include:
- The full report text
- A summary of data sources (which JQL queries, which Granola meetings)
- Any gaps or uncertainties flagged
- The net change computation showing the math

---

## PHASE 3 — PUBLISHING & POST-PUBLISH

### 3a. Create Confluence Page

Create as child of page `3361472513` in space `EDH` (space ID: `3350495235`).

**ADF Construction Rules (from tool-rules.json):**
- Build `inlineCard` nodes with explicit URLs: `https://endios.atlassian.net/browse/PMPO-XXXX`
- NEVER use `{jira:KEY}` shortcodes — they produce broken links
- Use ADF `status` nodes for health labels with correct color mapping
- Use ADF `panel` nodes with explicit `panelType` — shortcodes produce wrong types
- Use ADF `extension` node with extensionKey `iframe` for Jira dashboard embed
- Table colwidths: `[203, 121, 774]`, total 1238, layout "center"

**For rich text in table cells:** Build full ADF `bulletList` nodes. Do NOT use markdown bold (`**text**`) inside delta-patch bulletList — it renders as literal asterisks.

**Recommended approach:** Use a Python script to construct the ADF JSON programmatically with helper functions (`text()`, `strong()`, `smart_link()`, `status()`, `para()`, `heading()`, `bullet_list()`, `list_item()`, `initiative_row()`), then publish via Confluence API.

### 3b. Apply Corrections

After Carlos reviews the published page:
- Use **delta-patch tools** for targeted fixes: `confluence_update_table_cell`, `confluence_update_status`, `confluence_replace_section`
- For rich formatting corrections that delta-patch can't handle (markdown bold in bullets), rebuild the specific ADF node via Python and use the full update API
- **Cap correction rounds at 2 within a single session.** If more are needed: save draft state, resume in a new session.

### 3c. Save Snapshot

After final approval, save to `snapshots/hod-report/{YYYY-MM-DD}.json`:

```json
{
  "report_date": "YYYY-MM-DD",
  "cw_range": "XX-YY",
  "confluence_page_id": "page_id",
  "initiative_count": N,
  "net_change": 0,
  "finished": ["PMPO-XXXX"],
  "activated": ["PMPO-YYYY"],
  "health_labels": {
    "PMPO-XXXX": "good",
    "PMPO-YYYY": "fluctuating"
  },
  "carried_forward_sections": {
    "Cross-Department Topics": "summary of content"
  },
  "published_at": "ISO timestamp"
}
```

Snapshot retention: last 3. Delete oldest on 4th.

### 3d. Log Corrections to Memory

If Carlos corrected anything during review:

1. For each correction, create an entry in `memory/hod-report.json` under `corrections[]`:
   ```json
   {
     "id": "hod-NNN",
     "date": "YYYY-MM-DD",
     "category": "attribution|stale_content|fabrication|data_consistency|accuracy|grouping|terminology|role_error",
     "description": "What was wrong and what the correct answer is",
     "rule": "The general rule to prevent this in future"
   }
   ```

2. If the correction is clearly a **general rule** (terminology, tool behavior, role/person facts):
   - Propose updating `editorial-rules.json` or `tool-rules.json` directly
   - Carlos approves → commit to the plugin repo

3. If the correction involves a **new initiative code-name or alias**:
   - Propose adding to `memory/initiatives.json`
   - Carlos approves → write immediately

4. **Promotion check (threshold = 2):** If the same correction category now has 2+ entries with similar patterns, flag it:
   ```
   "This is the 2nd time I've corrected for [category]. Should I add a permanent rule to the reference files?"
   ```

### 3e. Log Approval

Write to `approvals.json` with `task_type: "hod_report"`, date, CW range, initiative count, and what Carlos changed. After 2 consecutive approvals without changes, offer: "Want me to generate this automatically and just notify you for review?"

---

## Anti-Patterns (DO NOT DO THESE)

- ❌ Risk-first framing (that's portfolio-radar, not this report)
- ❌ Certainty labels, ETA math, or blind spot language (internal concepts)
- ❌ Generic filler ("development is progressing well") — be specific or say nothing
- ❌ Including ALL initiatives — only highlight the interesting ones (typically 6-12)
- ❌ Including Roadmap Candidates in the highlights table
- ❌ Inventing health labels not in the vocabulary above
- ❌ Per-ticket detail — stay at epic/initiative level
- ❌ Pasting raw Jira data without narrative synthesis
- ❌ Adding images/screenshots (Carlos does these manually)
- ❌ Using `{jira:KEY}` shortcodes or `{status:X|color:Y}` shortcodes in ADF
- ❌ Using developer names in the report (only PO names when unavoidable)
- ❌ Using Jira project keys as team names ("AGENCY" instead of "Feature Team")
- ❌ Calling anyone "external" without verification — the Feature Team is NOT external
- ❌ Claiming a meeting happened without calendar verification
- ❌ Attributing meeting content to an initiative based on keyword match alone
- ❌ Presenting old news as current updates without new development
- ❌ Grouping initiatives under other initiatives without Jira parent-child evidence
- ❌ Reading full meeting transcripts (use targeted Granola queries instead)
- ❌ Reading historical reports in full (use snapshots)

## State Files

- **Snapshots:** `HoP/.hop-copilot/snapshots/hod-report/{YYYY-MM-DD}.json` (last 3)
- **Skill Memory:** `HoP/.hop-copilot/memory/hod-report.json` (corrections + preferences)
- **Initiative Metadata:** `HoP/.hop-copilot/memory/initiatives.json` (code-names, aliases, sensitivity)
- **Approval History:** `HoP/.hop-copilot/approvals.json` (shared)
- **Config:** `HoP/.hop-copilot/config.json` (PO roster, shared)
