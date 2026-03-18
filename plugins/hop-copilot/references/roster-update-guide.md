# PO Roster Update Guide

How to keep `HoP/.hop-copilot/config.json` in sync with actual PO ownership. Listed from best to worst approach.

## Approach 1: Jira REST API v3 via Chrome (PROVEN — used for initial setup)

This is the method that worked on 2026-03-16. It uses the browser's authenticated session to call the Jira REST API directly.

### Step A — Navigate to the Jira API in Chrome

Use the `navigate` tool to open:
```
https://endios.atlassian.net/rest/api/3/search/jql?jql=project%3DPMPO%20AND%20type%3DInitiative%20AND%20status%20!%3D%20Done%20ORDER%20BY%20assignee&fields=summary,assignee,components,status,labels&maxResults=50
```

**Important:** The v2 API (`/rest/api/2/search`) is deprecated and returns an error. Always use v3 (`/rest/api/3/search/jql`).

### Step B — Extract data with JavaScript

Use the `javascript_tool` to parse the JSON response and group by assignee:
```javascript
const data = JSON.parse(document.body.innerText);
const grouped = {};
data.issues.forEach(i => {
  const name = i.fields.assignee?.displayName || 'Unassigned';
  if (!grouped[name]) grouped[name] = [];
  grouped[name].push({
    key: i.key,
    summary: i.fields.summary,
    status: i.fields.status?.name,
    labels: i.fields.labels
  });
});
JSON.stringify({total: data.total, byPO: grouped}, null, 2);
```

### Step C — Paginate if needed

Results are capped at 50. Add `&startAt=50`, `&startAt=100`, etc. to get subsequent pages. Check `data.total` vs `data.issues.length` to know if pagination is needed.

### Step D — Derive product areas from initiative summaries

Initiative summaries follow the pattern `[COMPONENT_KEY] Description`. Extract component keys and group into product areas. Cross-reference with the PMPO Kanban board if needed.

### Known quirks
- **Display names vary:** "Mo Zimmermann" (not "Moritz"), "max.ohlig" (lowercase username, not "Max Ohlig")
- **Components field is often empty** in PMPO initiatives — derive areas from summary text and labels instead
- **Moritz Pirk** has items in PTSUP/PTJF but not PMPO — may need separate project queries
- **Sally Barth** returned zero results — her Jira username/display name needs confirmation

## Approach 2: PMPO Kanban Board scraping via Chrome

Navigate to the board and use `get_page_text`:
```
https://endios.atlassian.net/jira/software/c/projects/PMPO/boards/108
```

The board text includes initiative names, PMPO keys, and assignee names in a parseable format. This gives a good snapshot of active work but may miss items in non-visible columns.

## Approach 3: Atlassian MCP Tools (when available)

When the Atlassian MCP connector tools are loaded in the session (`searchJiraIssuesUsingJql`, `getConfluencePage`):
```
JQL: type = Initiative AND project = PMPO AND status != Done ORDER BY assignee
```
This is the cleanest approach but the tools weren't available in the first session.

## Approach 4: Confluence Database

The Component Database (ID 4923719682) is a Confluence Database that renders inside an iframe. It CANNOT be read via:
- `confluence_read_table` (returns 404 — it's not a regular page)
- `get_page_text` (returns empty — content is in an iframe)
- `read_page` accessibility tree (only shows `database-frame` generic element)

The iframe loads from `https://endios.atlassian.net/databases/standalone/index-dark.html`. Future approaches:
- Confluence Databases REST API (if it becomes available)
- Navigate directly into the iframe URL and extract from there
- CSV export (manual — see below)

## Approach 5: CSV Import (manual, one-time)

Carlos exports the Confluence Database as CSV:
1. Open https://endios.atlassian.net/wiki/spaces/PRO/database/4923719682
2. Click "..." menu → Export → CSV
3. Upload the CSV to the session

## When to Update

- After a PO joins, leaves, or swaps areas
- After quarterly planning when initiative ownership may shift
- When the pulse-check skill detects a PO working on components outside their configured areas
- Monthly as a hygiene check (add to weekly /review)
- When the weekly /review command detects stale roster data (> 30 days since last update)
