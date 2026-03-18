#!/bin/bash
# Load HoP Copilot context at session start
# Provides baseline state information to every session

HOP_STATE_DIR="${HOME}/.hop-copilot"
# Also check workspace-relative path
WORKSPACE_STATE_DIR="$(dirname "${CLAUDE_PLUGIN_ROOT}")/HoP/.hop-copilot"

# Find the state directory
STATE_DIR=""
if [ -d "$WORKSPACE_STATE_DIR" ]; then
  STATE_DIR="$WORKSPACE_STATE_DIR"
elif [ -d "$HOP_STATE_DIR" ]; then
  STATE_DIR="$HOP_STATE_DIR"
fi

if [ -z "$STATE_DIR" ]; then
  echo "HoP Copilot state directory not found. Run 'capture' to initialize."
  exit 0
fi

# Load backlog summary
if [ -f "$STATE_DIR/backlog.json" ]; then
  BACKLOG_COUNT=$(python3 -c "import json; data=json.load(open('$STATE_DIR/backlog.json')); print(len(data.get('items', [])))" 2>/dev/null || echo "0")
  echo "Automation backlog: $BACKLOG_COUNT items"
fi

# Load config summary
if [ -f "$STATE_DIR/config.json" ]; then
  PO_COUNT=$(python3 -c "import json; data=json.load(open('$STATE_DIR/config.json')); print(len(data.get('po_roster', [])))" 2>/dev/null || echo "0")
  echo "PO roster: $PO_COUNT product owners configured"
fi

# Check for pending triage items
if [ -f "$STATE_DIR/triage-log.json" ]; then
  PENDING=$(python3 -c "import json; data=json.load(open('$STATE_DIR/triage-log.json')); print(len([i for i in data.get('items', []) if i.get('status') == 'triaged']))" 2>/dev/null || echo "0")
  if [ "$PENDING" -gt 0 ]; then
    echo "Pending triage items: $PENDING"
  fi
fi

echo "HoP Copilot ready. Skills: capture, pulse-check, stakeholder-update, triage. Command: /review"
