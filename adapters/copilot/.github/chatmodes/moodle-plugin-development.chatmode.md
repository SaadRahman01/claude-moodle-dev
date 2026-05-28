---
description: Use when creating, modifying, upgrading, or reviewing Moodle plugins (local, mod, block, format, theme, auth, enrol, report, qtype, filter, repository) - covers version.php, db/install.xml + upgrade.php, db/access.php capabilities, db/services.php web services, lang strings, classes/ PSR-4 autoloading, lib.php hooks, settings.php, privacy provider, and Moodle coding standards.
tools: ['codebase', 'search', 'editFiles', 'runCommands']
---
# Moodle Plugin Development

## Overview

Moodle plugins follow strict frankenstyle naming and a fixed file layout. Every plugin lives under a type-specific directory (`local/`, `mod/`, `blocks/`, `course/format/`, `theme/`, `auth/`, `enrol/`, `report/`, `question/type/`, `filter/`, `repository/`, etc.) and is identified by `<type>_<name>` (e.g., `local_school`, `mod_quiz`, `format_schoolgram`).

**Core principle:** Moodle code must declare `defined('MOODLE_INTERNAL') || die();` at top of every PHP file (except classes under `classes/` autoloaded via PSR-4), use `$DB` for all DB access, use `get_string()` for user-facing text, and bump `version.php` for any DB or capability change.

## When to Use

- Creating new plugin under `local/`, `mod/`, `blocks/`, `course/format/`, `theme/`, etc.
- Adding/modifying DB tables → `db/install.xml` + `db/upgrade.php`
- Adding capabilities → `db/access.php`
- Adding web services / external functions → `db/services.php` + `classes/external/`
- Adding scheduled tasks → `db/tasks.php` + `classes/task/`
- Adding events / observers → `db/events.php` + `classes/event/`
- Adding admin settings page → `settings.php`
- Translating strings → `lang/<lang>/<component>.php`
- Reviewing PR for Moodle coding-style compliance
- Bumping `version.php` after schema/capability change

**Skip when:** working purely on frontend AMD modules without backend changes, or non-Moodle PHP code.

## Plugin Skeleton

Minimum files for a `local_<name>` plugin:

```
local/<name>/
  version.php                    # required: component, version, requires, maturity
  lang/en/local_<name>.php       # required: 'pluginname' string
  lib.php                        # optional: hooks (extend_navigation, pluginfile, etc.)
  settings.php                   # optional: admin settings page
  db/
    install.xml                  # DB schema (edit via /admin/tool/xmldb/)
    upgrade.php                  # versioned upgrade steps
    access.php                   # capabilities
    services.php                 # web service definitions
    tasks.php                    # scheduled tasks
    events.php                   # event observers
    caches.php                   # cache definitions
  classes/                       # PSR-4: \local_<name>\foo\bar -> classes/foo/bar.php
    external/                    # external (web service) functions
    task/                        # scheduled task classes
    event/                       # custom events
    privacy/provider.php         # GDPR provider (REQUIRED)
  templates/                     # Mustache templates
  amd/src/                       # ES modules (built via grunt -> amd/build/)
  tests/                         # PHPUnit + Behat
```

## version.php Template

```php
<?php
defined('MOODLE_INTERNAL') || die();

$plugin->component = 'local_example';      // frankenstyle, must match dir
$plugin->version   = 2026042500;           // YYYYMMDDXX, bump on any db/capability change
$plugin->requires  = 2024100700;           // min Moodle version (4.5 LTS); use 2025041400 for 5.0+, 2025100600 for 5.1+, 2026042000 for 5.2+
$plugin->release   = '1.0.0';
$plugin->maturity  = MATURITY_STABLE;      // ALPHA | BETA | RC | STABLE
$plugin->dependencies = ['mod_quiz' => 2024100700];  // optional
```

## db/install.xml + upgrade.php

- Edit `install.xml` via Moodle XMLDB editor (`Site admin -> Development -> XMLDB editor`) — never hand-edit.
- Every schema change requires:
  1. Bump `$plugin->version` in `version.php`
  2. Add upgrade step in `db/upgrade.php` keyed on old version:

```php
function xmldb_local_example_upgrade($oldversion) {
    global $DB;
    $dbman = $DB->get_manager();

    if ($oldversion < 2026042500) {
        $table = new xmldb_table('local_example_items');
        $field = new xmldb_field('status', XMLDB_TYPE_INTEGER, '4', null,
            XMLDB_NOTNULL, null, '0', 'name');
        if (!$dbman->field_exists($table, $field)) {
            $dbman->add_field($table, $field);
        }
        upgrade_plugin_savepoint(true, 2026042500, 'local', 'example');
    }
    return true;
}
```

## db/access.php Capabilities

```php
$capabilities = [
    'local/example:view' => [
        'captype'      => 'read',
        'contextlevel' => CONTEXT_SYSTEM,
        'archetypes'   => [
            'user'           => CAP_ALLOW,
            'editingteacher' => CAP_ALLOW,
        ],
    ],
];
```

Runtime check: `require_capability('local/example:view', $context);` or `has_capability(...)`.

## db/services.php (Web Services / AJAX)

```php
$functions = [
    'local_example_get_items' => [
        'classname'    => 'local_example\external\get_items',
        'methodname'   => 'execute',
        'description'  => 'Return items',
        'type'         => 'read',
        'ajax'         => true,
        'capabilities' => 'local/example:view',
    ],
];
```

External class extends `\core_external\external_api` (Moodle 4.2+; older = `external_api`) and defines `execute_parameters()`, `execute()`, `execute_returns()`.

## Lang Strings

`lang/en/local_example.php`:

```php
$string['pluginname']    = 'Example';
$string['example:view']  = 'View example';        // capability strings: <plugin>:<cap>
$string['greeting']      = 'Hello, {$a->name}';   // placeholders
```

Use: `get_string('greeting', 'local_example', ['name' => $user->firstname]);`

## DB Access — Always `$DB`

```php
global $DB;
$DB->get_record('local_example_items', ['id' => $id], '*', MUST_EXIST);
$DB->get_records_sql('SELECT * FROM {local_example_items} WHERE status = ?', [1]);
$DB->insert_record('local_example_items', $obj);
$DB->update_record('local_example_items', $obj);
$DB->delete_records('local_example_items', ['id' => $id]);
```

Never `mysqli_*` / `PDO`. Always use `{tablename}` placeholder (Moodle prefixes). Always bind params, never concatenate.

## Hooks via lib.php

Common Moodle callbacks (function name = `<component>_<hookname>`):

- `local_example_extend_navigation(global_navigation $nav)` — add nav nodes
- `local_example_before_http_headers()` — runs before headers
- `local_example_extend_settings_navigation($settingsnav, $context)`
- `local_example_pluginfile($course, $cm, $context, $filearea, $args, $forcedl, $options)` — serve file area

Moodle 4.4+: prefer the new hooks API (`\core\hook\manager`) over magic callbacks where available.

## Output — Renderers + Templates

- HTML via `$OUTPUT->render_from_template('local_example/foo', $data)` (Mustache: `templates/foo.mustache`)
- Custom renderer: `classes/output/renderer.php` extends `plugin_renderer_base`
- Never `echo` raw HTML in business logic; always go through renderer or template

## Privacy (GDPR) — Required

Every plugin must declare privacy. Minimum (no user data stored):

```php
// classes/privacy/provider.php
namespace local_example\privacy;
defined('MOODLE_INTERNAL') || die();
class provider implements \core_privacy\local\metadata\null_provider {
    public static function get_reason(): string {
        return 'privacy:metadata';
    }
}
```

If plugin stores user data, implement `\core_privacy\local\request\plugin\provider` and define `get_metadata`, `export_user_data`, `delete_data_for_user_in_context`, `delete_data_for_users`, `get_contexts_for_userid`, `get_users_in_context`.

## Quick Reference

| Task | File | Bump version? |
|------|------|---------------|
| Add DB table/field | `db/install.xml` + `db/upgrade.php` | Yes |
| Add capability | `db/access.php` + lang string | Yes |
| Add web service fn | `db/services.php` + `classes/external/` | Yes |
| Add scheduled task | `db/tasks.php` + `classes/task/` | Yes |
| Add event observer | `db/events.php` | Yes |
| Add cache definition | `db/caches.php` | Yes |
| Add string | `lang/en/<component>.php` | No |
| Add settings | `settings.php` | No |
| Add template | `templates/*.mustache` | No |
| Add renderer | `classes/output/renderer.php` | No |

## Coding Standards

- 4-space indent, no tabs
- Opening `<?php` on line 1, no closing `?>` at end of pure PHP files
- `defined('MOODLE_INTERNAL') || die();` immediately after license block (skip in `classes/` PSR-4 files)
- snake_case for functions/vars, PascalCase for classes
- Run `vendor/bin/phpcs --standard=moodle <path>` before commit (`local_codechecker` plugin or `moodle-cs` ruleset)
- All user-facing strings via `get_string()`, never hard-coded English
- GPL-3.0-or-later license header on every PHP file

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Hand-editing `install.xml` | Use XMLDB editor at `/admin/tool/xmldb/` |
| Forgetting to bump `version.php` after schema change | Bump + add `upgrade.php` step + `upgrade_plugin_savepoint` |
| Using raw SQL with `{}` quoting wrong | Use `{tablename}` and `?` / named params, never string concat |
| `MOODLE_INTERNAL` check inside `classes/` PSR-4 file | Remove — autoloaded files don't need it |
| Storing user data without privacy provider | Implement `\core_privacy\local\request\plugin\provider` |
| Hard-coded English strings in PHP/Mustache | Move to `lang/en/<component>.php` + `get_string` / `{{#str}}` |
| Forgetting `require_capability()` on entry points | Always `require_login()` + capability check early |
| Not purging caches after `version.php` bump | `php admin/cli/upgrade.php` or Site admin -> Purge caches |
| Direct `$_GET`/`$_POST` access | Use `required_param()` / `optional_param()` with type |
| Missing `sesskey()` check on state-changing requests | Call `require_sesskey()` on POST handlers |

## Plugin Type Cheatsheet

| Type | Dir | Frankenstyle | Extra required files |
|------|-----|--------------|----------------------|
| Local | `local/<name>` | `local_<name>` | none beyond skeleton |
| Activity module | `mod/<name>` | `mod_<name>` | `mod_form.php`, `view.php`, `lib.php` w/ `<name>_add_instance` etc. |
| Block | `blocks/<name>` | `block_<name>` | `block_<name>.php` extends `block_base` |
| Course format | `course/format/<name>` | `format_<name>` | `format.php`, `lib.php` extends `core_courseformat\base` |
| Theme | `theme/<name>` | `theme_<name>` | `config.php`, `scss/`, `layout/` |
| Auth | `auth/<name>` | `auth_<name>` | `auth.php` extends `auth_plugin_base` |
| Enrol | `enrol/<name>` | `enrol_<name>` | `lib.php` extends `enrol_plugin` |
| Question type | `question/type/<name>` | `qtype_<name>` | `questiontype.php`, `question.php`, `renderer.php` |
| Filter | `filter/<name>` | `filter_<name>` | `filter.php` extends `moodle_text_filter` |
| Repository | `repository/<name>` | `repository_<name>` | `lib.php` extends `repository` |

## Security Checklist

- `require_login()` (and `require_capability()`) at top of every entry script
- `require_sesskey()` on every state-changing POST
- `required_param($name, PARAM_INT)` / `optional_param(...)` — never raw `$_REQUEST`
- Use `$DB->...` with placeholders — no SQL concat
- Escape output: `s()`, `format_string()`, `format_text()`
- File serving via `pluginfile.php` + `<component>_pluginfile()` callback, never direct path

## CLI Helpers

```bash
php admin/cli/upgrade.php --non-interactive    # apply pending upgrades
php admin/cli/purge_caches.php                  # clear all caches
php admin/tool/behat/cli/init.php               # init behat tests
vendor/bin/phpunit --testsuite local_example_testsuite
vendor/bin/phpcs --standard=moodle local/example
```

## Testing

- PHPUnit: `tests/<thing>_test.php` extending `advanced_testcase`, use `$this->resetAfterTest()`, generators via `self::getDataGenerator()->get_plugin_generator('local_example')`
- Behat: `tests/behat/*.feature` with `@local_example` tag, step definitions in `tests/behat/behat_local_example.php`

## References

- Moodle Dev Docs: https://moodledev.io
- Plugin types: https://moodledev.io/docs/apis/plugintypes
- Coding style: https://moodledev.io/general/development/policies/codingstyle
- XMLDB: https://moodledev.io/docs/apis/core/dml/xmldb
- Privacy API: https://moodledev.io/docs/apis/subsystems/privacy
- Hooks API (4.4+): https://moodledev.io/docs/apis/core/hooks
