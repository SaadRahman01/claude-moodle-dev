---
name: moodle-capability-audit
description: Audit a plugin's capabilities — verifies db/access.php declarations match runtime require_capability/has_capability calls, checks risk bitmasks, default archetypes, and lang strings.
argument-hint: "[plugin-path] — defaults to cwd"
---

Audit capability declarations vs. usage for the plugin at the given path.

User's input: $ARGUMENTS

## Procedure

1. Resolve plugin path (default: cwd). Read `version.php` to get the frankenstyle `$plugin->component`.
2. Activate `moodle-security-audit` and `moodle-plugin-development` skills.
3. Parse `db/access.php` — extract declared capabilities into a set.
4. Grep the plugin for runtime capability use:
   - `require_capability\(['"]([^'"]+)['"]`
   - `has_capability\(['"]([^'"]+)['"]`
   - `require_all_capabilities\(\[(.*?)\]`
   - `require_any_capability\(\[(.*?)\]`
   - In `db/services.php`: `'capabilities' => '...'`
   - In external function `execute_parameters` files: same as above
5. Cross-reference:
   - **Used but not declared** -> ERROR (call will always deny).
   - **Declared but never used** -> WARNING (dead capability, or used via JS/dynamic — flag for human check).
   - **Declared with risk bitmask but riskBitmask=0** for caps that grant write/admin -> WARNING.
6. For each declared capability, verify:
   - `captype` is one of `read`/`write`.
   - `contextlevel` is a valid `CONTEXT_*` constant.
   - `archetypes` includes a sensible default (most caps should have `'manager' => CAP_ALLOW` at minimum).
   - `riskbitmask` uses correct combination: `RISK_SPAM | RISK_XSS | RISK_PERSONAL | RISK_CONFIG | RISK_DATALOSS | RISK_MANAGETRUST`.
   - A lang string exists in `lang/en/<component>.php` as `$string['<component>:<capname-suffix>'] = '...'` AND a `<capname-suffix>_help` if non-trivial.
7. Check for `clone` or `extends` of risky caps (e.g., cloning `moodle/site:config`) — flag.
8. If any cap uses `CONTEXT_SYSTEM` and grants write/admin, ensure `RISK_CONFIG` or `RISK_DATALOSS` is set.

## Output

```markdown
# Capability audit: <component>

## Summary
- Declared: N | Used: N | Orphan declarations: N | Undeclared usages: N
- Risk-bitmask issues: N | Missing lang strings: N

## Errors
- foo.php:88 — `has_capability('<component>:doit', ...)` but `<component>:doit` not in db/access.php

## Warnings
- db/access.php:42 — `<component>:legacy` declared but no runtime usage (dead?)
- db/access.php:60 — `<component>:writeall` is write/CONTEXT_SYSTEM but no RISK_CONFIG flag

## Missing lang strings
- `<component>:doit` — add `$string['<component>:doit'] = '...';` to lang/en/<component>.php
- `<component>:doit_help` — add `_help` for non-trivial caps

## Suggested next steps
1. Add missing declarations to db/access.php, bump version.php
2. Remove dead caps or document why kept (e.g., used by sibling plugin)
3. Add risk bitmasks
4. Run `php admin/cli/upgrade.php` after version bump to apply changes
```

## Rules

- Never modify files — report only.
- Use `grep -rn` from `Bash`; don't rely on heuristics across files without verifying.
- If `db/access.php` doesn't exist, say so — the plugin declares no capabilities. Still scan for hardcoded `has_capability` strings.
- Capability strings can be built dynamically (`"$component:" . $action`) — flag these as "manual review needed".
