# Changelog

All notable changes to `moodle-dev` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2026-05-28

### Added

- **Moodle 5.1 support** (released 2025-10-06): `/public` document root, Routing Engine, PHP 8.2 min with 8.3/8.4 supported, sodium ext requirement, DB prefix 10-char cap.
- **Moodle 5.2 support** (releases 2026-04-20): PHP 8.3 min with 8.4 supported, upgrade path from 4.4+, Oracle removed, DB minimums bumped (PostgreSQL 16 / MySQL 8.4 / MariaDB 10.11 / MSSQL 2019), React in core via importmaps, Composer for third-party libs, OpenTelemetry.
- **PHP 8.4 migration section** in `moodle-upgrade-migration` skill: implicit nullable params hard-deprecation, `E_STRICT` removal, CSV escape param, XML callable form, `mb_trim()` family, `DatePeriod::createFromISO8601String()`.
- 5.1 deprecations catalogued: `file_encode_url()`, device theme functions, quiz callback classes, `course/changenumsections.php`, course max-sections setting.
- 5.2 final deprecations catalogued: `core/modal_factory`, `core/modal_registry`, pre-PHP 7 constructors, ≤ 4.4 `lib/deprecatedlib.php` entries.

### Changed

- README compatibility table extended through Moodle 5.2; PHP support line clarified per Moodle release.
- `moodle-plugin-development` `version.php` example uses 4.5 LTS (`2024100700`) as `$plugin->requires` with inline cheatsheet for 5.0/5.1/5.2 minimums.
- Adapters regenerated for Cursor, Copilot, Aider, Continue, generic bundle.

### Compatibility notes

- Projects targeting Moodle ≤ 5.0 / PHP ≤ 8.3: pin to tag `v0.3.0` or use the `moodle-4.x-5.0` maintenance branch.

## [0.3.0] - 2026-05-23

### Added

- **Multi-assistant adapters** — generated from canonical skills/agents/commands:
  - Cursor (`.cursor/rules/*.mdc`)
  - GitHub Copilot (`.github/copilot-instructions.md` + `chatmodes/*.chatmode.md` + `prompts/*.prompt.md`)
  - Aider (`CONVENTIONS.md` + per-skill `read-only` files)
  - Continue.dev (`config.yaml` + rules + prompts)
  - Generic single-file paste-anywhere bundle (`adapters/generic/PROMPTS.md`)
- `scripts/build-adapters.py` — regenerates all adapters from canonical sources.
- New skill: `moodle-hooks-api` — authoring + listening + migrating magic callbacks (Moodle 4.4+).
- New commands:
  - `/moodle-mustache-lint` — accessibility/security/string lint on `.mustache` templates.
  - `/moodle-capability-audit` — cross-check `db/access.php` against runtime `has_capability` calls.
- `.githooks/pre-commit` — phpcs (Moodle standard) + PHPUnit on staged tests + `version.php` monotonic bump check.
- CI: adapters-in-sync check, skill-dir/name match, intra-repo broken-link warning.

### Changed

- README restructured to document install for Claude Code + Cursor + Copilot + Aider + Continue + generic.
- `plugin.json` / `marketplace.json` descriptions updated for 13 skills / 8 commands.

## [0.2.0] - 2026-05-02

### Added

- 11 new skills:
  - `moodle-phpunit-testing` — Moodle's PHPUnit harness, generators, mocking, CI
  - `moodle-behat-testing` — feature files, custom steps, generators, JS scenarios
  - `moodle-amd-javascript` — AMD modules, grunt build, `core/ajax`, `core/templates`, `core/modal`, `core/pending`
  - `moodle-web-services` — `db/services.php`, external functions, REST/AJAX, tokens, file uploads
  - `moodle-security-audit` — capability/sesskey/input/SQL/XSS/file/SSRF checklist
  - `moodle-privacy-gdpr` — null vs full provider, metadata, contextlists, userlists, subsystem links
  - `moodle-performance` — MUC caching, recordsets, ad-hoc tasks, locks, OPcache, profiling
  - `moodle-accessibility` — WCAG 2.1 AA in Mustache + AMD, ARIA, contrast, keyboard, screen readers
  - `moodle-theme-development` — Boost child themes, SCSS hooks, layouts, renderer overrides, settings
  - `moodle-upgrade-migration` — deprecated APIs, PHP 8.x migrations, Moodle 3→4→5 transitions, `upgrade.txt`
  - `moodle-mobile-app` — `db/mobile.php`, remote templates, Ionic directives, offline functions, push
- 6 slash commands:
  - `/moodle-new-plugin` — scaffold a new plugin
  - `/moodle-bump-version` — bump `version.php` + add upgrade step
  - `/moodle-privacy-audit` — verify privacy provider matches DB schema
  - `/moodle-security-review` — run the security checklist
  - `/moodle-string-check` — find hard-coded English needing `get_string`
  - `/moodle-codestyle` — run + fix `phpcs --standard=moodle`
- 2 subagents:
  - `moodle-reviewer` — deep PR / code review
  - `moodle-scaffolder` — generate complete plugin skeleton from a brief
- Community files:
  - `CONTRIBUTING.md` with contribution guide for skills, commands, agents
  - `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1)
  - `EXAMPLES.md` with 30+ real example prompts
  - `.github/ISSUE_TEMPLATE/bug_report.yml` + `feature_request.yml`
  - `.github/PULL_REQUEST_TEMPLATE.md`
  - `.github/workflows/lint.yml` — JSON validation, frontmatter checks, version sync
- Overhauled `README.md`:
  - Compelling intro, badges, value proposition vs vanilla Claude
  - Tables of skills / commands / agents
  - Worked example prompt → generated plugin tree
  - Compatibility matrix
  - Roadmap

### Changed

- `plugin.json` + `marketplace.json` updated with new keywords, longer description, repository URL
- `marketplace.json` plugin description reflects new breadth

## [0.1.0] - 2026-04-25

### Added
- Initial release
- `moodle-plugin-development` skill: scaffolding, XMLDB, capabilities, web services, lang, hooks, privacy provider, coding standards, security checklist, plugin-type cheatsheet
