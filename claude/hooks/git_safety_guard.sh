#!/usr/bin/env bash
#
# git_safety_guard.sh
# Claude Code PreToolUse hook: blocks destructive git/filesystem commands.
#
# Behavior:
#   - Exit 0 with no output = allow
#   - Exit 0 with JSON permissionDecision=deny = block
#
set -euo pipefail

input="$(cat 2>/dev/null || true)"
[[ -n "$input" ]] || exit 0

tool_name="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null || true)"
command="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"

[[ "$tool_name" == "Bash" ]] || exit 0
[[ -n "$command" ]] || exit 0

SAFE_PATTERNS=(
  'git[[:space:]]+checkout[[:space:]]+-b[[:space:]]+'
  'git[[:space:]]+checkout[[:space:]]+--orphan[[:space:]]+'
  'git[[:space:]]+restore[[:space:]]+--staged[[:space:]]+'
  'git[[:space:]]+clean[[:space:]]+-n([[:space:]]|$)'
  'git[[:space:]]+clean[[:space:]]+--dry-run([[:space:]]|$)'
  # Allow rm -rf on temp directories (ephemeral by design)
  'rm[[:space:]]+-[a-z]*r[a-z]*f[a-z]*[[:space:]]+/tmp/'
  'rm[[:space:]]+-[a-z]*r[a-z]*f[a-z]*[[:space:]]+/var/tmp/'
  'rm[[:space:]]+-[a-z]*r[a-z]*f[a-z]*[[:space:]]+\\$TMPDIR/'
  'rm[[:space:]]+-[a-z]*r[a-z]*f[a-z]*[[:space:]]+\\$\\{TMPDIR'
  'rm[[:space:]]+-[a-z]*r[a-z]*f[a-z]*[[:space:]]+\"\\$TMPDIR/'
  'rm[[:space:]]+-[a-z]*r[a-z]*f[a-z]*[[:space:]]+\"\\$\\{TMPDIR'
)

for pat in "${SAFE_PATTERNS[@]}"; do
  if printf '%s' "$command" | grep -Eiq -- "$pat"; then
    exit 0
  fi
done

deny() {
  local reason="$1"
  jq -n --arg reason "$reason" --arg cmd "$command" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: ("BLOCKED by git_safety_guard.sh\n\nReason: " + $reason + "\n\nCommand: " + $cmd + "\n\nIf this operation is truly needed, ask the user for explicit permission and have them run the command manually.")
    }
  }'
  exit 0
}

# git checkout -- / git checkout <ref> -- <path>
if printf '%s' "$command" | grep -Eiq -- 'git[[:space:]]+checkout[[:space:]]+.*--[[:space:]]+'; then
  deny "git checkout ... -- can overwrite/discard uncommitted changes. Use 'git stash' first."
fi

# git restore (except --staged)
if printf '%s' "$command" | grep -Eiq -- 'git[[:space:]]+restore([[:space:]]|$)'; then
  deny "git restore can discard uncommitted changes. Use 'git diff' and 'git stash' first."
fi

# git reset hard/merge
if printf '%s' "$command" | grep -Eiq -- 'git[[:space:]]+reset[[:space:]]+--hard([[:space:]]|$)'; then
  deny "git reset --hard destroys uncommitted changes. Use 'git stash' first."
fi
if printf '%s' "$command" | grep -Eiq -- 'git[[:space:]]+reset[[:space:]]+--merge([[:space:]]|$)'; then
  deny "git reset --merge can lose uncommitted changes."
fi

# git clean -f / -fd / etc (except -n / --dry-run handled above)
if printf '%s' "$command" | grep -Eiq -- 'git[[:space:]]+clean[[:space:]]+-[a-z]*f'; then
  deny "git clean -f removes untracked files permanently. Review with 'git clean -n' first."
fi

# force push
if printf '%s' "$command" | grep -Eiq -- 'git[[:space:]]+push([[:space:]]|$)'; then
  if printf '%s' "$command" | grep -Eiq -- '--force-with-lease'; then
    exit 0
  fi
  if printf '%s' "$command" | grep -Eiq -- '(^|[[:space:]])(--force|-f)([[:space:]]|$)'; then
    deny "Force push can destroy remote history. Prefer --force-with-lease if absolutely necessary."
  fi
fi

# branch delete
if printf '%s' "$command" | grep -Eiq -- 'git[[:space:]]+branch[[:space:]]+-D([[:space:]]|$)'; then
  deny "git branch -D force-deletes without merge check. Use -d for safety."
fi

# git stash drop/clear
if printf '%s' "$command" | grep -Eiq -- 'git[[:space:]]+stash[[:space:]]+drop([[:space:]]|$)'; then
  deny "git stash drop permanently deletes stashed changes. List stashes first."
fi
if printf '%s' "$command" | grep -Eiq -- 'git[[:space:]]+stash[[:space:]]+clear([[:space:]]|$)'; then
  deny "git stash clear permanently deletes ALL stashed changes."
fi

# rm -rf (except temp dirs handled above)
if printf '%s' "$command" | grep -Eiq -- '(^|[[:space:]])rm[[:space:]]+-[a-z]*r[a-z]*f[a-z]*([[:space:]]|$)'; then
  if printf '%s' "$command" | grep -Eiq -- 'rm[[:space:]]+-[a-z]*r[a-z]*f[a-z]*[[:space:]]+[/~]([[:space:]]|$)'; then
    deny "rm -rf on root/home paths is extremely dangerous."
  fi
  deny "rm -rf is destructive. List files first, then delete individually with explicit permission."
fi

exit 0
