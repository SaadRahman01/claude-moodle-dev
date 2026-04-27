# moodle-dev

Moodle plugin development skills for [Claude Code](https://docs.anthropic.com/claude/docs/claude-code).

Helps Claude scaffold, modify, upgrade, and review Moodle plugins (local, mod, block, course format, theme, auth, enrol, question type, filter, repository) following Moodle coding standards.

## Install

### From this marketplace (GitHub)

```
/plugin marketplace add <github-user>/claude-moodle-dev
/plugin install moodle-dev@moodle-dev
```

### From local path (development)

```
/plugin marketplace add /absolute/path/to/moodle-dev
/plugin install moodle-dev@moodle-dev
```

## What's included

### Skill: `moodle-plugin-development`

Activates when Claude is creating, modifying, upgrading, or reviewing a Moodle plugin. Covers:

- `version.php` template and bump rules
- `db/install.xml` + `db/upgrade.php` (XMLDB)
- `db/access.php` capabilities
- `db/services.php` web services + `classes/external/`
- `db/tasks.php` scheduled tasks + `classes/task/`
- `db/events.php` event observers
- Lang strings (`get_string()`, placeholders)
- DB access via `$DB` (no raw SQL)
- `lib.php` hooks and Moodle 4.4+ hooks API
- Renderers + Mustache templates
- Privacy (GDPR) provider — required for all plugins
- Moodle coding standards + `phpcs` ruleset
- Security checklist (`require_login`, `require_capability`, `require_sesskey`, `required_param`, `pluginfile.php`)
- Plugin-type cheatsheet (local, mod, block, format, theme, auth, enrol, qtype, filter, repository)
- Common mistakes table
- CLI helpers (`upgrade.php`, `purge_caches.php`, `phpunit`, `phpcs`)

## Repository layout

```
.claude-plugin/
  marketplace.json    # marketplace manifest
  plugin.json         # plugin manifest
skills/
  moodle-plugin-development/
    SKILL.md
LICENSE
CHANGELOG.md
README.md
```

## Contributing

Issues and PRs welcome. To add a new skill, create `skills/<skill-name>/SKILL.md` with frontmatter (`name`, `description`).

## License

MIT — see [LICENSE](LICENSE).

Moodle is GPL-3.0-or-later. Code samples generated using this skill should be licensed GPL-3.0-or-later to be contributable upstream.
