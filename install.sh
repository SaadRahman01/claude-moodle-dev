#!/usr/bin/env bash
# moodle-dev installer for non-Claude-Code assistants.
#
# Usage:
#   ./install.sh <target> [--dest <dir>]
#
# Targets:
#   cursor    -> copies .cursor/ into <dest>
#   copilot   -> copies .github/copilot-instructions.md + chatmodes into <dest>/.github
#   aider     -> copies CONVENTIONS.md (and skills/, commands/) into <dest>
#   continue  -> copies config.yaml + rules + prompts into <dest>/.continue
#   generic   -> writes adapters/generic/PROMPTS.md into <dest>/MOODLE_PROMPTS.md
#
# Default <dest> is the current directory.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

usage() {
  sed -n '2,15p' "$0"
  exit 1
}

[ $# -ge 1 ] || usage
target="$1"; shift
dest="."

while [ $# -gt 0 ]; do
  case "$1" in
    --dest) dest="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $1" >&2; usage ;;
  esac
done

dest="$(cd "$dest" && pwd)"
echo "» Installing moodle-dev ($target) into $dest"

copy_tree() {
  src="$1"; dst="$2"
  if [ ! -d "$src" ]; then echo "Missing source: $src" >&2; exit 1; fi
  mkdir -p "$dst"
  cp -R "$src"/. "$dst"/
}

case "$target" in
  cursor)
    copy_tree "$ROOT/adapters/cursor/.cursor" "$dest/.cursor"
    echo "Done. Cursor will pick up rules in .cursor/rules/."
    ;;
  copilot)
    copy_tree "$ROOT/adapters/copilot/.github" "$dest/.github"
    echo "Done. Copilot reads .github/copilot-instructions.md per repo."
    ;;
  aider)
    cp "$ROOT/adapters/aider/CONVENTIONS.md" "$dest/CONVENTIONS.md"
    [ -d "$ROOT/adapters/aider/skills" ] && copy_tree "$ROOT/adapters/aider/skills" "$dest/.aider/skills"
    [ -d "$ROOT/adapters/aider/commands" ] && copy_tree "$ROOT/adapters/aider/commands" "$dest/.aider/commands"
    echo "Done. Add to .aider.conf.yml:"
    echo "  read:"
    echo "    - CONVENTIONS.md"
    ;;
  continue)
    copy_tree "$ROOT/adapters/continue" "$dest/.continue"
    echo "Done. Restart Continue to load rules + prompts."
    ;;
  generic)
    cp "$ROOT/adapters/generic/PROMPTS.md" "$dest/MOODLE_PROMPTS.md"
    echo "Done. Paste sections from MOODLE_PROMPTS.md into your assistant's system prompt."
    ;;
  *)
    echo "Unknown target: $target" >&2
    usage
    ;;
esac
