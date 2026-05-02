# moodle-dev

> The most complete Moodle development toolkit for [Claude Code](https://docs.anthropic.com/claude/docs/claude-code) — skills, slash commands, and subagents that turn Claude into a Moodle expert.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.2.0-blue.svg)](CHANGELOG.md)
[![Claude Code Plugin](https://img.shields.io/badge/Claude%20Code-Plugin-8A2BE2.svg)](https://docs.anthropic.com/claude/docs/claude-code)
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

### Claude Code marketplace (recommended)

```
/plugin marketplace add SaadRahman01/claude-moodle-dev
/plugin install moodle-dev@moodle-dev
```

### Local development

```
/plugin marketplace add /absolute/path/to/claude-moodle-dev
/plugin install moodle-dev@moodle-dev
```

Verify install:

```
/plugin list
```

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

### Slash commands

| Command | What it does |
|---------|--------------|
| `/moodle-new-plugin` | Scaffold a new plugin (asks type + name) |
| `/moodle-bump-version` | Bump `version.php` + add upgrade step |
| `/moodle-privacy-audit` | Check privacy provider correctness |
| `/moodle-security-review` | Run security checklist on a file/plugin |
| `/moodle-string-check` | Find hard-coded English needing `get_string` |
| `/moodle-codestyle` | Run `phpcs` with Moodle ruleset |

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
.claude-plugin/
  marketplace.json
  plugin.json
skills/
  moodle-plugin-development/SKILL.md
  moodle-phpunit-testing/SKILL.md
  moodle-behat-testing/SKILL.md
  moodle-amd-javascript/SKILL.md
  moodle-web-services/SKILL.md
  moodle-security-audit/SKILL.md
  moodle-privacy-gdpr/SKILL.md
  moodle-performance/SKILL.md
  moodle-accessibility/SKILL.md
  moodle-theme-development/SKILL.md
  moodle-upgrade-migration/SKILL.md
  moodle-mobile-app/SKILL.md
commands/
  moodle-new-plugin.md
  moodle-bump-version.md
  moodle-privacy-audit.md
  moodle-security-review.md
  moodle-string-check.md
  moodle-codestyle.md
agents/
  moodle-reviewer.md
  moodle-scaffolder.md
.github/
  ISSUE_TEMPLATE/
  PULL_REQUEST_TEMPLATE.md
  workflows/lint.yml
EXAMPLES.md
CONTRIBUTING.md
CODE_OF_CONDUCT.md
CHANGELOG.md
LICENSE
README.md
```

---

## Compatibility

| Moodle | Status |
|--------|--------|
| 5.0    | supported |
| 4.5    | supported |
| 4.4    | supported (Hooks API) |
| 4.3    | supported (legacy callbacks) |
| 4.2    | supported (`core_external` namespace) |
| ≤ 4.1  | best-effort (older external_api) |

PHP 8.1+ recommended. Some skills note Moodle-version-specific differences.

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
