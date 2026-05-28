# moodle-dev

> The most complete Moodle development toolkit for AI coding assistants — skills, slash commands, and subagents that turn your assistant into a Moodle expert.
> **Native plugin for [Claude Code](https://docs.anthropic.com/claude/docs/claude-code); ships with adapters for [Cursor](adapters/cursor/), [GitHub Copilot](adapters/copilot/), [Aider](adapters/aider/), [Continue](adapters/continue/), and a [paste-anywhere bundle](adapters/generic/PROMPTS.md).**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.4.0-blue.svg)](CHANGELOG.md)
[![Claude Code Plugin](https://img.shields.io/badge/Claude%20Code-Plugin-8A2BE2.svg)](https://docs.anthropic.com/claude/docs/claude-code)
[![Cursor](https://img.shields.io/badge/Cursor-Rules-black.svg)](adapters/cursor/)
[![Copilot](https://img.shields.io/badge/Copilot-Chatmodes-24292e.svg)](adapters/copilot/)
[![Aider](https://img.shields.io/badge/Aider-Conventions-orange.svg)](adapters/aider/)
[![Continue](https://img.shields.io/badge/Continue-Rules-blueviolet.svg)](adapters/continue/)
[![Moodle 4.x](https://img.shields.io/badge/Moodle-4.x%20%7C%205.x-orange.svg)](https://moodledev.io)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

Scaffolds plugins, writes XMLDB upgrades, audits privacy/security, generates PHPUnit + Behat tests, builds AMD modules, reviews PRs — all following official Moodle coding standards (PSR-4, frankenstyle, MOODLE_INTERNAL, GPL headers, `get_string`, `$DB`).

---

## Why this plugin

Claude already knows PHP. It does **not** know:
- Moodle's frankenstyle conventions (`local_<name>`, `mod_<name>`, `block_<name>`, ...)
- XMLDB editor workflow + `upgrade_plugin_savepoint` rules
- Privacy API contracts (`null_provider` vs `request\plugin\provider`)
- Capability + sesskey + `require_login` security pattern
- Moodle 4.4+ Hooks API vs legacy `lib.php` callbacks
- `pluginfile.php` file-serving callback
- Behat + PHPUnit Moodle harness (`resetAfterTest`, generators, tags)
- AMD/RequireJS + grunt build
- Mobile app remote templates + `get_remote_addons`

This plugin teaches Claude all of it. Auto-activates when Claude detects Moodle work.

---

## Install

### Claude Code (native plugin)

```
/plugin marketplace add https://github.com/SaadRahman01/claude-moodle-dev
/plugin install moodle-dev@moodle-dev
```

(If `git@github.com` SSH auth fails, use the full `https://` URL as shown above.)

Local dev: `/plugin marketplace add /absolute/path/to/claude-moodle-dev`.
Verify: `/plugin list`.

### Cursor

Copy `adapters/cursor/.cursor/` into your project (or `~/.cursor/` for global use). Each skill becomes an on-demand rule; agents and commands surface via `@<name>` mentions in chat.

### GitHub Copilot

Copy `adapters/copilot/.github/` into your repo. `copilot-instructions.md` is applied to every chat in the repo; per-skill chatmodes appear in the chat-mode picker.

### Aider

Drop `adapters/aider/CONVENTIONS.md` into your project root and add it to `.aider.conf.yml`:

```yaml
read:
  - CONVENTIONS.md
```

Load individual skills on demand with `/read-only adapters/aider/skills/<name>.md`.

### Continue.dev

Copy `adapters/continue/` into `~/.continue/` (merge with existing `config.yaml`). Skills load as rules; commands appear as slash prompts.

### Any other assistant

Paste relevant sections from [`adapters/generic/PROMPTS.md`](adapters/generic/PROMPTS.md) — it's one self-contained markdown file with every skill, agent, and command. Works with anything that takes a system prompt.

---

## What's inside

### Skills (auto-activate)

| Skill | Triggers on |
|-------|-------------|
| `moodle-plugin-development` | Creating/modifying any plugin (all types) |
| `moodle-phpunit-testing` | Writing/running PHPUnit tests |
| `moodle-behat-testing` | Writing/running Behat acceptance tests |
| `moodle-amd-javascript` | AMD modules, ES6, grunt build |
| `moodle-web-services` | REST/AJAX/external functions, tokens |
| `moodle-security-audit` | Security review, capability/sesskey audit |
| `moodle-privacy-gdpr` | Privacy provider, GDPR compliance |
| `moodle-performance` | MUC caching, query tuning, ad-hoc tasks |
| `moodle-accessibility` | WCAG 2.1 AA, ARIA, screen reader checks |
| `moodle-theme-development` | Boost child themes, SCSS, layouts |
| `moodle-upgrade-migration` | Cross-version upgrades, deprecations |
| `moodle-mobile-app` | Mobile app remote templates, addons |
| `moodle-hooks-api` | 4.4+ Hooks API: authoring, listening, migrating magic callbacks |

### Slash commands

| Command | What it does |
|---------|--------------|
| `/moodle-new-plugin` | Scaffold a new plugin (asks type + name) |
| `/moodle-bump-version` | Bump `version.php` + add upgrade step |
| `/moodle-privacy-audit` | Check privacy provider correctness |
| `/moodle-security-review` | Run security checklist on a file/plugin |
| `/moodle-string-check` | Find hard-coded English needing `get_string` |
| `/moodle-codestyle` | Run `phpcs` with Moodle ruleset |
| `/moodle-mustache-lint` | Lint Mustache templates: a11y, security, hard-coded strings |
| `/moodle-capability-audit` | Cross-check `db/access.php` against runtime `has_capability` use |

### Subagents

| Agent | Use case |
|-------|----------|
| `moodle-reviewer` | Deep PR review against Moodle coding standards |
| `moodle-scaffolder` | Generates a plugin skeleton from a brief |

---

## Example: from prompt to plugin

**You:**

> Build a `local_attendance_export` plugin that lets teachers export per-course attendance as CSV. Needs a capability, a settings page, and a CLI script.

**Claude (with this plugin loaded) generates:**

```
local/attendance_export/
├── version.php                            # 2026050200, requires 2024042200
├── settings.php                           # admin_setting_configtext for default delimiter
├── lib.php                                # local_attendance_export_extend_navigation()
├── cli/export.php                         # require($CFG->libdir . '/clilib.php'); cli params
├── classes/
│   ├── exporter.php                       # business logic, uses $DB
│   ├── output/renderer.php
│   └── privacy/provider.php               # null_provider (no user data stored)
├── db/
│   ├── access.php                         # local/attendance_export:export
│   └── install.xml                        # (empty — no tables)
├── lang/en/local_attendance_export.php    # pluginname, capability, settings strings
└── tests/exporter_test.php                # PHPUnit, resetAfterTest, generator
```

Every file follows Moodle conventions. `require_capability` + `require_sesskey` wired. PHPUnit test uses `$this->getDataGenerator()`. Privacy provider declared. `version.php` bumped correctly.

---

## Example prompts

See [EXAMPLES.md](EXAMPLES.md) for 30+ prompts covering scaffolding, upgrades, testing, security audits, performance tuning, theme work, and mobile app integration.

---

## Comparison

|  | Vanilla Claude | + moodle-dev |
|--|----------------|--------------|
| Knows frankenstyle naming | partial | yes |
| Bumps `version.php` correctly | no | yes |
| Adds `upgrade_plugin_savepoint` | no | yes |
| Writes privacy provider | rarely | always |
| Adds `require_sesskey` on POST | no | yes |
| Uses `$DB` not raw SQL | partial | yes |
| Uses `get_string()` not English literals | no | yes |
| Generates passing PHPUnit + Behat | no | yes |
| Knows Moodle 4.4 Hooks API | no | yes |
| Generates `pluginfile.php` callback | no | yes |
| Mobile app remote templates | no | yes |

---

## Repository layout

```
.claude-plugin/         # Claude Code plugin manifest
skills/                 # canonical skills (Claude reads these directly)
agents/                 # canonical subagents
commands/               # canonical slash commands

adapters/               # generated per-assistant — DO NOT hand-edit
  cursor/.cursor/rules/*.mdc
  copilot/.github/copilot-instructions.md + chatmodes/*.chatmode.md
  aider/CONVENTIONS.md + skills/ + commands/
  continue/config.yaml + rules/ + prompts/
  generic/PROMPTS.md    # paste-anywhere single-file bundle

scripts/build-adapters.py   # regenerates adapters/ from canonical files
.githooks/pre-commit        # phpcs + PHPUnit + version.php monotonicity (install: git config core.hooksPath .githooks)
.github/workflows/lint.yml  # CI: JSON, frontmatter, adapter sync, broken links
```

### Editing workflow

1. Edit canonical files under `skills/`, `agents/`, or `commands/`.
2. Run `python3 scripts/build-adapters.py` to regenerate adapters.
3. Commit both. CI fails if `adapters/` drifts from canonical source.

---

## Compatibility

| Moodle | Status |
|--------|--------|
| 5.2    | supported (PHP 8.3 min, `/public` doc-root, React core, Oracle dropped — releases 2026-04-20) |
| 5.1    | supported (PHP 8.2 min, `/public` doc-root introduced, Routing Engine) |
| 5.0    | supported |
| 4.5    | supported (LTS) |
| 4.4    | supported (Hooks API) |
| 4.3    | supported (legacy callbacks) |
| 4.2    | supported (`core_external` namespace) |
| ≤ 4.1  | best-effort (older external_api) |

PHP support: 8.1+ for Moodle 4.x, 8.2+ for 5.0/5.1, 8.3+ for 5.2. PHP 8.4 tested on 5.1+. Some skills note Moodle-version-specific differences.

---

## Roadmap

- [ ] `moodle-question-bank` skill (qtype/qbank deeper coverage)
- [ ] `moodle-h5p` skill
- [ ] `moodle-lti-tool` skill (LTI 1.3 tool/provider)
- [ ] `moodle-analytics` skill (analytics models)
- [ ] `moodle-cli-script` slash command
- [ ] `moodle-translation-export` slash command
- [ ] MCP server wrapping `moodledev.io` docs search
- [ ] MCP server for live Moodle dev instance (XMLDB editor, purge caches)

Vote / request: [open an issue](https://github.com/SaadRahman01/claude-moodle-dev/issues/new/choose).

---

## Contributing

PRs welcome — see [CONTRIBUTING.md](CONTRIBUTING.md). Quick path:

1. Fork
2. Add a skill: `skills/<name>/SKILL.md` with `name` + `description` frontmatter
3. Add a command: `commands/<name>.md` with frontmatter
4. Add an agent: `agents/<name>.md` with frontmatter
5. PR — CI lints JSON + frontmatter automatically

---

## License

MIT — see [LICENSE](LICENSE).

Code Claude generates with these skills should ship as **GPL-3.0-or-later** to be Moodle plugin directory compatible.

---

## Credits

Built by [Saad Rahman](https://github.com/SaadRahman01). 
Powered by [Claude Code](https://docs.anthropic.com/claude/docs/claude-code) and the [Moodle Developer Documentation](https://moodledev.io).

If this saves you time, ⭐ the repo — helps others find it.
