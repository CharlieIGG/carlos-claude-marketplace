# HoP Copilot State Files — Schema Reference

All state files live in `HoP/.hop-copilot/`. Always read before writing to avoid data loss.

## config.json

The PO roster and plugin configuration. Edited manually or via the `capture` skill when Carlos provides new info.

**Design principle:** Config stores only **stable** data that rarely changes (names, domains, display names, components). **Dynamic** data like active initiatives, Confluence pages, and sprint status are always queried **live at runtime** from Jira and Confluence APIs. This avoids stale data and eliminates maintenance burden.

```json
{
  "po_roster": [
    {
      "name": "Full Name",
      "jira_display_name": "Name as it appears in Jira (may differ from real name)",
      "short_name": "First name or nickname used in conversation",
      "domain": "PO's area of ownership",
      "domain_description": "Detailed description of what falls under this domain",
      "components": ["Widget X", "Feature Y"],
      "capacity_overlaps": [{"initiative": "KEY", "natural_owner_domain": "...", "reason": "..."}],
      "notes": "Any context about this PO"
    }
  ],
  "ownership_model": {
    "domains": {"Domain Name": "PO Name"},
    "overlap_policy": "...",
    "dashboard_ownership_rule": "..."
  },
  "automation_preferences": {
    "approval_threshold": 3,
    "default_mode": "ask_first",
    "auto_approved_tasks": ["task_type_1", "task_type_2"]
  }
}
```

## backlog.json

The automation improvement backlog. Managed by the `capture` skill.

```json
{
  "items": [
    {
      "id": "uuid-v4",
      "captured_at": "2026-03-16T10:30:00Z",
      "description": "What Carlos described",
      "category": "recurring_manual | data_pull | communication | oversight | compliance | other",
      "estimated_frequency": "weekly",
      "estimated_time_per_occurrence": 20,
      "automation_approach": "How to automate this",
      "effort_estimate": "low | medium | high",
      "status": "captured | planned | in_progress | automated | deferred",
      "priority_score": 0.0,
      "notes": "",
      "related_skill": "capture | pulse-check | stakeholder-update | triage | new_skill_needed"
    }
  ]
}
```

**Priority score formula:** `(frequency_per_month × time_per_occurrence) / effort_multiplier`
- effort_multiplier: low=1, medium=3, high=10
- frequency_per_month: daily=20, weekly=4, biweekly=2, monthly=1, per_sprint=2

## approvals.json

Tracks the "always ask, but learn" mechanism. Managed by all skills after presenting output.

```json
{
  "history": [
    {
      "task_type": "pulse_check_sally | stakeholder_update_leadership | triage_feature_request",
      "approved_at": "2026-03-16T10:30:00Z",
      "approved_without_changes": true,
      "changes_made": null,
      "consecutive_clean_approvals": 3,
      "auto_approved": false
    }
  ]
}
```

When `consecutive_clean_approvals` reaches the threshold (default: 3), the skill should offer auto-approval for that task_type. If Carlos accepts, add the task_type to `config.json > automation_preferences > auto_approved_tasks`.

If Carlos makes changes after auto-approval, reset `consecutive_clean_approvals` to 0 and remove from `auto_approved_tasks`.

## snapshots/{po_short_name}/{YYYY-MM-DD}.json

Point-in-time summary of a PO's state, captured by the `pulse-check` skill after each run. Used for diff comparisons between runs.

- **Retention:** Last 3 snapshots per PO. On 4th, oldest is deleted.
- **Location:** `HoP/.hop-copilot/snapshots/{po_short_name}/`
- **Content:** Summary data only — NOT full Jira payloads.

```json
{
  "date": "2026-03-17",
  "po_short_name": "Mo Z.",
  "timeframe_start": "2026-03-03",
  "initiatives": [
    {
      "key": "PMPO-9886",
      "summary": "[DTA v2.0] Data Lake v2.0",
      "rank_position": 1,
      "status": "In Development",
      "due_date": "2026-05-08",
      "epics": [
        {
          "key": "OP-XXXXX",
          "summary": "BE Data Ingestion",
          "total_tickets": 12,
          "open": 8,
          "in_progress": 3,
          "done": 4,
          "in_sprint": 5,
          "assigned_to_dev": 4,
          "assigned_to_non_dev": 1,
          "overrun_risk": false
        }
      ],
      "fix_versions": ["v2.0-beta"],
      "fix_version_target_date": "2026-06-01",
      "fix_version_aligned": true
    }
  ],
  "follow_ups": [
    {
      "item": "Pilot customer outreach for Spark",
      "owner": "Mo",
      "importance": "high",
      "status": "no_evidence"
    }
  ],
  "activity_summary": {
    "top3_pct": 75,
    "other_initiative_pct": 15,
    "support_pct": 10,
    "flagged": false
  },
  "active_memory_ids": ["uuid-1", "uuid-2"]
}
```

**Diff rules:**
- Track initiatives by key (not rank position) — rank changes are noted separately
- Memory entries created between snapshots (via `remember`) that aren't in prior snapshot's ID list → "New since last check"
- First run (no prior snapshot): skip diff, note "Baseline created"

## memory/{po_short_name}.json

Persistent PO-specific memory. Managed by the `remember` skill and the `pulse-check` post-briefing extraction.

- **No auto-expiry.** Entries stay active until Carlos marks them `addressed` or `archived`.
- **Location:** `HoP/.hop-copilot/memory/{po_short_name}.json`

```json
{
  "entries": [
    {
      "id": "uuid-v4",
      "created_at": "2026-03-16T10:30:00Z",
      "source": "auto_extracted | manual",
      "category": "feedback_to_give | praise | agreement | priority_override | concern | context | dev_roster_correction",
      "content": "Free text: what to remember",
      "related_initiative": "PMPO-XXXX (optional, null if general)",
      "status": "active | addressed | archived",
      "addressed_at": "2026-03-20T14:00:00Z (optional, null if active)",
      "notes": "Optional follow-up notes"
    }
  ]
}
```

**Auto-extraction:** After pulse-check briefing, skill offers entries one at a time for approval. Carlos approves, edits, or skips each.

**Manual entry:** Via `remember` skill — "remember that Mo...", "note for Mo: ..."

**Dev roster corrections:** Category `dev_roster_correction` entries are applied to `config.json > dev_roster_cache` on next refresh. Corrections override inferred data.

## triage-log.json

Incoming request log. Created on first use by the `triage` skill.

```json
{
  "items": [
    {
      "id": "uuid-v4",
      "received_at": "2026-03-16T10:30:00Z",
      "source": "teams | email | meeting | jira | verbal",
      "requester": "Name or team",
      "summary": "Brief description",
      "category": "urgent_important | important_not_urgent | urgent_not_important | neither",
      "routed_to": "PO name or team",
      "response_drafted": true,
      "response_sent": false,
      "status": "triaged | in_progress | resolved | declined",
      "resolution_date": null,
      "notes": ""
    }
  ]
}
```
