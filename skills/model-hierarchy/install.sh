#!/bin/sh
# Install the model-hierarchy subagents.
#   sh install.sh [--profile eco|balanced|power] [--user]
#   default profile: balanced; default scope: ./.claude/agents/ (run from the project root)
#   --user installs to ~/.claude/agents/ for all projects.
# Idempotent. An existing agent file that differs is backed up to <file>.bak before it is replaced.
set -eu

usage() { echo "Usage: sh install.sh [--profile eco|balanced|power] [--user]"; }
die() { echo "Error: $1" >&2; usage >&2; exit 1; }

base=".claude"
scope="project"
profile="balanced"
while [ $# -gt 0 ]; do
  case "$1" in
    --user) base="$HOME/.claude"; scope="user" ;;
    --profile) [ $# -ge 2 ] || die "--profile needs a value"; profile="$2"; shift ;;
    --profile=*) profile="${1#--profile=}" ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
  shift
done
case "$profile" in
  eco|balanced|power) ;;
  *) die "unknown profile: $profile (use eco, balanced or power)" ;;
esac

root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
conf="$root/profiles/$profile.conf"
[ -f "$conf" ] || die "profile file not found: $conf"
[ -d "$root/agents" ] || die "agents directory not found: $root/agents"

dest="$base/agents"
mkdir -p "$dest"
tmp="${TMPDIR:-/tmp}/model-hierarchy.$$"
trap 'rm -f "$tmp"' EXIT
trap 'exit 1' INT TERM

next_backup() {
  b="$1.bak"; n=1
  while [ -e "$b" ]; do b="$1.bak.$n"; n=$((n + 1)); done
  echo "$b"
}

echo "Installing model-hierarchy agents: profile '$profile', $scope scope, into $dest"
main_model=""; main_effort=""
while read -r agent model effort _; do
  case "$agent" in ''|'#'*) continue ;; esac
  if [ "$agent" = "main" ]; then main_model="$model"; main_effort="$effort"; continue; fi
  target="$dest/$agent.md"
  if [ "$model" = "-" ]; then
    if [ -e "$target" ]; then
      b=$(next_backup "$target"); mv "$target" "$b"
      echo "  disabled   $agent.md  (not used in $profile; moved to $b)"
    else
      echo "  skipped    $agent.md  (not used in $profile)"
    fi
    continue
  fi
  case "$effort" in low|medium|high|xhigh) ;; *) die "bad effort '$effort' for $agent in $conf" ;; esac
  src="$root/agents/$agent.md"
  [ -f "$src" ] || die "agent file not found: $src"
  # Rewrite only the model and effort lines inside the frontmatter.
  awk -v m="$model" -v e="$effort" '
    NR == 1 && $0 == "---" { fm = 1; print; next }
    fm && $0 == "---"      { fm = 0; print; next }
    fm && /^model:/        { print "model: " m; next }
    fm && /^effort:/       { print "effort: " e; next }
    { print }' "$src" > "$tmp"
  if [ ! -e "$target" ]; then
    cp "$tmp" "$target"; echo "  installed  $agent.md  ($model, $effort)"
  elif cmp -s "$tmp" "$target"; then
    echo "  unchanged  $agent.md  ($model, $effort)"
  else
    b=$(next_backup "$target"); cp "$target" "$b"; cp "$tmp" "$target"
    echo "  updated    $agent.md  ($model, $effort; previous version backed up to $b)"
  fi
done < "$conf"

# Record the active profile so the orchestrator can read it.
marker="$base/model-hierarchy-profile"
old=$(cat "$marker" 2>/dev/null || true)
if [ "$old" != "$profile" ]; then
  echo "$profile" > "$marker"
  echo "  profile    $marker: ${old:-none} -> $profile"
fi

echo "Done. Installed profile: $profile"
echo "Recommended main session (run in Claude Code):"
echo "  /model $main_model"
echo "  /effort $main_effort"
echo "Keep ultracode off (/effort ultracode off). Then run /agents to verify the agents are listed."
