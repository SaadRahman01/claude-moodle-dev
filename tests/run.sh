#!/usr/bin/env bash
# Repo test harness.
#
# Runs structural checks on canonical sources + adapter generator.
# Fast (< 10s). Run locally before commit, in CI.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
fail=0
total=0
passed=0

pass() { passed=$((passed+1)); total=$((total+1)); echo -e "  ${GREEN}ok${NC} $1"; }
fail() { fail=1; total=$((total+1)); echo -e "  ${RED}FAIL${NC} $1"; }
info() { echo -e "${YELLOW}» $1${NC}"; }

# --- Skill frontmatter: name, description, description has trigger keyword ---
info "Skill frontmatter contracts"
for f in skills/*/SKILL.md; do
  name=$(awk '/^name:/{print $2; exit}' "$f")
  desc=$(awk '/^description:/{sub(/^description:[[:space:]]*/, ""); print; exit}' "$f")
  [ -n "$name" ] && pass "$f: name present" || fail "$f: missing name"
  [ -n "$desc" ] && pass "$f: description present" || fail "$f: missing description"
  if echo "$desc" | grep -qiE 'use when|trigger|when (writing|creating|reviewing|building|working)'; then
    pass "$f: description has activation trigger phrase"
  else
    fail "$f: description should describe activation trigger (e.g. 'Use when ...')"
  fi
done

# --- Command frontmatter: name + description + body non-empty ---
info "Command files"
for f in commands/*.md; do
  [ -f "$f" ] || continue
  name=$(awk '/^name:/{print $2; exit}' "$f")
  desc=$(awk '/^description:/{sub(/^description:[[:space:]]*/, ""); print; exit}' "$f")
  body_lines=$(awk '/^---$/{c++; next} c==2{print}' "$f" | grep -cve '^$' || true)
  [ -n "$name" ] && pass "$f: name" || fail "$f: missing name"
  [ -n "$desc" ] && pass "$f: description" || fail "$f: missing description"
  [ "$body_lines" -gt 0 ] && pass "$f: body non-empty" || fail "$f: empty body"
done

# --- Agent frontmatter: name + description ---
info "Agent files"
for f in agents/*.md; do
  [ -f "$f" ] || continue
  name=$(awk '/^name:/{print $2; exit}' "$f")
  desc=$(awk '/^description:/{sub(/^description:[[:space:]]*/, ""); print; exit}' "$f")
  [ -n "$name" ] && pass "$f: name" || fail "$f: missing name"
  [ -n "$desc" ] && pass "$f: description" || fail "$f: missing description"
done

# --- JSON manifests parse + versions match ---
info "Plugin manifests"
python3 -c "import json; json.load(open('.claude-plugin/plugin.json'))" \
  && pass "plugin.json parses" || fail "plugin.json invalid"
python3 -c "import json; json.load(open('.claude-plugin/marketplace.json'))" \
  && pass "marketplace.json parses" || fail "marketplace.json invalid"

pv=$(python3 -c "import json; print(json.load(open('.claude-plugin/plugin.json'))['version'])")
mv=$(python3 -c "import json; print(json.load(open('.claude-plugin/marketplace.json'))['plugins'][0]['version'])")
[ "$pv" = "$mv" ] && pass "versions in sync ($pv)" || fail "versions diverge: plugin=$pv marketplace=$mv"

# --- Adapter generator runs cleanly ---
info "Adapter generator"
if python3 scripts/build-adapters.py >/dev/null 2>&1; then
  pass "scripts/build-adapters.py runs"
else
  fail "scripts/build-adapters.py crashes"
fi

# --- Skill body has 'When to Use' section (activation contract) ---
info "Skill activation contracts"
for f in skills/*/SKILL.md; do
  if grep -qiE '^##+ +When to Use|^##+ +Triggers' "$f"; then
    pass "$f: has When to Use section"
  else
    fail "$f: missing 'When to Use' section"
  fi
done

# --- No tab characters in markdown (consistent indent) ---
info "No tabs in markdown"
if ! grep -rPl '\t' --include='*.md' . >/dev/null 2>&1; then
  pass "no tabs in *.md"
else
  for f in $(grep -rPl '\t' --include='*.md' . 2>/dev/null); do
    fail "$f: contains tab characters"
  done
fi

echo
if [ "$fail" -ne 0 ]; then
  echo -e "${RED}FAILED${NC} ($passed/$total passed)"
  exit 1
fi
echo -e "${GREEN}PASSED${NC} ($passed/$total)"
