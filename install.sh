#!/usr/bin/env bash
set -e
REPO_URL="https://github.com/Alfonso-Castano/claude-init-project.git"
COMPONENT="${1:-init-project}"

TMP_DIR=$(mktemp -d)
git clone --depth 1 "$REPO_URL" "$TMP_DIR"
mkdir -p ~/.claude/skills ~/.claude/agents

install_init_project() {
  cp -r "$TMP_DIR/skills/init-project" ~/.claude/skills/
  # /init-project --thorough reads this shared file, which lives under feature/ so /feature-discuss can share it
  mkdir -p ~/.claude/skills/feature/references
  cp "$TMP_DIR/skills/feature/references/thorough-brainstorm.md" ~/.claude/skills/feature/references/
  cp "$TMP_DIR/agents/context-researcher.md" "$TMP_DIR/agents/context-research-synthesizer.md" "$TMP_DIR/agents/context-roadmapper.md" ~/.claude/agents/
  echo "✅ init-project skill and agents installed to ~/.claude/"
}

register_session_start_hook() {
  SETTINGS="$HOME/.claude/settings.json"
  HOOK_CMD="\$HOME/.claude/hooks/context-staleness-check.sh"

  if [ ! -f "$SETTINGS" ]; then
    cat > "$SETTINGS" <<JSON
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          { "type": "command", "command": "$HOOK_CMD" }
        ]
      }
    ]
  }
}
JSON
    return
  fi

  PYTHON_BIN=""
  if command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="python3"
  elif command -v python >/dev/null 2>&1; then
    PYTHON_BIN="python"
  elif command -v py >/dev/null 2>&1; then
    PYTHON_BIN="py"
  fi

  if [ -n "$PYTHON_BIN" ]; then
    "$PYTHON_BIN" - "$SETTINGS" "$HOOK_CMD" <<'PYEOF'
import json, sys

path, cmd = sys.argv[1], sys.argv[2]
with open(path) as f:
    data = json.load(f)

hooks = data.setdefault("hooks", {})
session_start = hooks.setdefault("SessionStart", [])
already_registered = any(
    h.get("command") == cmd
    for entry in session_start
    for h in entry.get("hooks", [])
)
if not already_registered:
    session_start.append({"hooks": [{"type": "command", "command": cmd}]})

with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PYEOF
  else
    echo "⚠️  python3/python not found — could not auto-register the SessionStart hook in $SETTINGS."
    echo "   Add this to your hooks.SessionStart array manually:"
    echo "   { \"hooks\": [ { \"type\": \"command\", \"command\": \"$HOOK_CMD\" } ] }"
  fi
}

install_context_update() {
  mkdir -p ~/.claude/hooks
  cp -r "$TMP_DIR/skills/update-context" ~/.claude/skills/
  cp "$TMP_DIR/agents/context-updater.md" ~/.claude/agents/
  cp "$TMP_DIR/hooks/context-staleness-check.sh" ~/.claude/hooks/
  chmod +x ~/.claude/hooks/context-staleness-check.sh
  register_session_start_hook
  echo "✅ update-context skill, agent, and staleness hook installed to ~/.claude/"
}

install_feature_workflow() {
  cp -r "$TMP_DIR/skills/feature" \
        "$TMP_DIR/skills/feature-quick" \
        "$TMP_DIR/skills/feature-discuss" \
        "$TMP_DIR/skills/feature-plan" \
        "$TMP_DIR/skills/feature-execute" \
        "$TMP_DIR/skills/feature-verify" \
        "$TMP_DIR/skills/orchestrator" \
        "$TMP_DIR/skills/prompt-engineer" \
        ~/.claude/skills/
  cp "$TMP_DIR/agents/feature-planner.md" \
     "$TMP_DIR/agents/feature-executor.md" \
     "$TMP_DIR/agents/feature-reviewer.md" \
     ~/.claude/agents/
  echo "✅ feature-workflow skills and agents installed to ~/.claude/"
}

case "$COMPONENT" in
  init-project)
    install_init_project
    ;;
  context-update)
    install_context_update
    ;;
  feature-workflow)
    install_feature_workflow
    ;;
  all)
    install_init_project
    install_context_update
    install_feature_workflow
    ;;
  *)
    echo "Unknown component: '$COMPONENT' (expected: init-project, context-update, feature-workflow, or all)" >&2
    rm -rf "$TMP_DIR"
    exit 1
    ;;
esac

rm -rf "$TMP_DIR"
