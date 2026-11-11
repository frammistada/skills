#!/bin/sh
# Install the model-hierarchy subagents.
#   sh install.sh          -> ./.claude/agents/   (project scope, run from the project root)
#   sh install.sh --user   -> ~/.claude/agents/   (all projects)
# Idempotent. An existing agent file that differs is backed up to <file>.bak before it is replaced.
set -eu

usage() { echo "Usage: sh install.sh [--user]"; }

dest=".claude/agents"
scope="project"
for arg in "$@"; do
  case "$arg" in
    --user) dest="$HOME/.claude/agents"; scope="user" ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; usage >&2; exit 1 ;;
  esac
done

src=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/agents
if [ ! -d "$src" ]; then
  echo "Error: agents directory not found at $src" >&2
  exit 1
fi

mkdir -p "$dest"
echo "Installing model-hierarchy agents ($scope scope) into $dest"

installed=0; updated=0; unchanged=0
for f in "$src"/*.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f")
  target="$dest/$name"
  if [ ! -e "$target" ]; then
    cp "$f" "$target"
    echo "  installed  $name"
    installed=$((installed + 1))
  elif cmp -s "$f" "$target"; then
    echo "  unchanged  $name"
    unchanged=$((unchanged + 1))
  else
    backup="$target.bak"
    n=1
    while [ -e "$backup" ]; do backup="$target.bak.$n"; n=$((n + 1)); done
    cp "$target" "$backup"
    cp "$f" "$target"
    echo "  updated    $name  (your previous version was backed up to $backup)"
    updated=$((updated + 1))
  fi
done

echo "Done: $installed installed, $updated updated (backed up), $unchanged unchanged."
echo "Next: run /agents in Claude Code to verify haiku-worker, sonnet-coder, opus-architect and fable-escalation are listed."
