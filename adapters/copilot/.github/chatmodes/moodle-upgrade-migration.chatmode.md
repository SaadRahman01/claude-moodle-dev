---
description: Use when upgrading a Moodle plugin across versions, fixing deprecated API usage, or migrating to Moodle 4.x/5.x conventions — print_error, add_to_log, formslib changes, external_api namespace, Hooks API, PSR-4 migration, and required upgrade.txt notes.
tools: ['codebase', 'search', 'editFiles', 'runCommands']
---
# Moodle Upgrade & Migration

## Overview

Moodle deprecates aggressively but rarely removes. Code from Moodle 2.x often still runs in 4.5 — but uses APIs that emit warnings, fail PHP 8 strict checks, or block plugin directory acceptance. This skill catalogs the migration path from each generation.

## When to Use

- Upgrading a plugin to support a newer Moodle version
- Resolving deprecation warnings
- Migrating to PHP 8.1+ / 8.2 / 8.3
- Plugin directory submission rejection ("uses deprecated API")
- Cross-version compat (`$plugin->requires` bump)

## Strategy

1. Bump `$plugin->requires` to your minimum target Moodle version
2. Replace deprecated APIs (table below)
3. Add `upgrade.txt` to document changes
4. Run `phpcs --standard=moodle` + visual smoke test
5. Bump `$plugin->version` + add `db/upgrade.php` step if schema changed

## Deprecation table

| Old | New | Since |
|-----|-----|-------|
| `print_error('errkey', 'comp')` | `throw new \moodle_exception('errkey', 'comp')` | 3.7 |
| `add_to_log()` | Trigger an event class | 2.7 |
| `notify('text', 'notifyproblem')` | `\core\notification::error('text')` | 3.0 |
| `redirect($url, 'msg', 0)` | `redirect($url, 'msg', null, \core\notification::INFO)` | 3.0 |
| `external_api` (bare) | `\core_external\external_api` | 4.2 |
| `external_function_parameters` etc. | `\core_external\...` | 4.2 |
| `$mform->setHelpButton()` | `$mform->addHelpButton()` | 2.0 |
| Magic callbacks `<comp>_extend_navigation` | Hooks API `\core\hook\...` (where applicable) | 4.4 |
| `\core\session\manager::write_close()` | Same — but check if needed | — |
| `mtrace()` in non-CLI | Use `debugging()` or proper logger | — |
| `cleardoubleslashes` | Use `clean_param($url, PARAM_URL)` | — |
| `addslashes()` for DB | Use `$DB->...` placeholders | 2.0 |
| `mysql_*` functions | `$DB` always | 2.0 |
| `userdate($t, '', false)` (no timezone) | Pass timezone or use `core_date::get_user_timezone_object()` | 3.2 |
| `create_function()` | Closures `function() { }` | PHP 7.2 removed |
| `each($array)` | `foreach` | PHP 7.2 removed |
| `assert($string)` | Real expression | PHP 7.2+ |
| `(unset)` cast | Plain `unset()` | PHP 7.2+ |
| `\Mustache_Engine` direct | `$OUTPUT->render_from_template` | — |
| `cm_info::get_modinfo` second arg | API change in 3.4 | 3.4 |
| `format_text` no `context` | Always pass `['context' => $context]` | 2.0 |
| `\html_writer::nonempty_tag` | Use `html_writer::tag` with check | 3.5 |
| `\stdClass` w/o `: \stdClass` return type in PHP 8.1+ | Add return types | 8.1 |

## PHP version migrations

### → PHP 8.0

- `each()`, `create_function()` removed
- `'string' . null` warns — explicit cast
- Negative string offset behavior changed
- Named arguments — Moodle prohibits in public APIs (positional only)

### → PHP 8.1

- Implicit nullable parameters `(string $x = null)` deprecated → `(?string $x = null)`
- `Returning by reference from a void function`
- Internal classes `#[\AllowDynamicProperties]` if you set undeclared properties
- `tempnam`, `parse_url` minor signature changes

### → PHP 8.2

- Dynamic properties on user classes deprecated
- `${...}` string interpolation deprecated → `{$...}`
- `utf8_encode`/`utf8_decode` deprecated

### → PHP 8.3

- `#[\Override]` attribute encouraged
- `Date_Create_From_Format` strict-ness

## Moodle 3.x → 4.x

### Theme

- 3.x default theme `Clean` removed; use Boost
- 4.0 introduced course index, secondary navigation, drawers
- Layouts: `frontpage`, `mydashboard`, `incourse`, `course` may need overrides

### Hooks API (4.4+)

Old:
```php
function local_example_extend_navigation(global_navigation $nav) { /* ... */ }
```

New (where supported):
```php
// db/hooks.php
$callbacks = [
    [
        'hook'     => \core\hook\navigation\primary_extend::class,
        'callback' => '\local_example\hooks\navigation::extend_primary',
    ],
];
```

```php
// classes/hooks/navigation.php
namespace local_example\hooks;
class navigation {
    public static function extend_primary(\core\hook\navigation\primary_extend $hook): void {
        $hook->get_primary_view()->add(/* ... */);
    }
}
```

Magic callbacks still work in 4.4+; Hooks API is preferred for new code, required for some new extension points.

### External API namespace

```php
// Pre-4.2
class get_items extends external_api { /* ... */ }

// 4.2+
use core_external\external_api;
use core_external\external_function_parameters;
class get_items extends external_api { /* ... */ }
```

Compatibility shim: 4.2+ aliases bare names to namespaced for back-compat — but new code should use namespaced.

### Course format API

`format_<name>` plugins migrated from `format_base` to `\core_courseformat\base`:

```php
// classes/output/courseformat/content.php
namespace format_yourname\output\courseformat;
class content extends \core_courseformat\output\local\content { /* ... */ }
```

3.x format plugins need full rewrite for 4.0+.

## Moodle 4.x → 5.x

5.0 still in early phase — verify against release notes:

- PHP 8.2 minimum (5.0+)
- Bootstrap 5 fully replaces Bootstrap 4 utility classes
  - `.sr-only` → `.visually-hidden`
  - `.float-left` → `.float-start`
  - `.ml-*` → `.ms-*`
  - `data-toggle` → `data-bs-toggle`
- Some 4.x deprecations finalize
- New AI subsystem (`\core_ai`)

Always check `/lib/upgrade.txt` and per-component `upgrade.txt` for the target version.

## upgrade.txt convention

`<plugin>/upgrade.txt`:

```
This files describes API changes in /local/example/*,
information provided here is intended especially for developers.

=== 1.5.0 ===
* The deprecated function local_example_old_thing() has been removed. Use local_example_new_thing() instead.
* New \local_example\hooks\foo class for the navigation hook (Moodle 4.4+).

=== 1.4.0 ===
* New web service local_example_export_csv.
```

Mirrors Moodle's own `lib/upgrade.txt`. Plugin directory reviewers read it.

## db/upgrade.php cumulative example

```php
<?php
defined('MOODLE_INTERNAL') || die();

function xmldb_local_example_upgrade($oldversion) {
    global $DB;
    $dbman = $DB->get_manager();

    if ($oldversion < 2024010100) {
        $table = new xmldb_table('local_example_items');
        $field = new xmldb_field('status', XMLDB_TYPE_INTEGER, '4', null,
            XMLDB_NOTNULL, null, '0', 'name');
        if (!$dbman->field_exists($table, $field)) {
            $dbman->add_field($table, $field);
        }
        upgrade_plugin_savepoint(true, 2024010100, 'local', 'example');
    }

    if ($oldversion < 2024050100) {
        // Drop legacy index
        $table = new xmldb_table('local_example_items');
        $index = new xmldb_index('legacy_idx', XMLDB_INDEX_NOTUNIQUE, ['userid']);
        if ($dbman->index_exists($table, $index)) {
            $dbman->drop_index($table, $index);
        }
        upgrade_plugin_savepoint(true, 2024050100, 'local', 'example');
    }

    if ($oldversion < 2025010100) {
        // Data migration — chunked to avoid memory blow
        $rs = $DB->get_recordset_select('local_example_items', 'metadata IS NULL');
        foreach ($rs as $r) {
            $r->metadata = json_encode([]);
            $DB->update_record('local_example_items', $r);
        }
        $rs->close();
        upgrade_plugin_savepoint(true, 2025010100, 'local', 'example');
    }

    return true;
}
```

Each `if` block targets one historical version. Never delete past blocks — sites may upgrade through multiple versions.

## Compatibility shim pattern

For plugins supporting multiple Moodle versions:

```php
if (class_exists('\core_external\external_api')) {
    class_alias('\core_external\external_api', '\local_example\compat\external_api');
} else {
    class_alias('\external_api', '\local_example\compat\external_api');
}
```

Or guard with `\core\plugin_manager::get_remote_plugin_info` and `moodle_major_version()`:

```php
if (version_compare(moodle_major_version(), '4.4', '>=')) {
    // Hooks API path
} else {
    // Magic callback fallback
}
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Bumping `$plugin->requires` without testing on min version | Test against `$plugin->requires` Moodle release |
| Removing `db/upgrade.php` blocks | Keep all historical blocks |
| Skipping `upgrade_plugin_savepoint` | Required — marks step as done |
| Adding new field without `field_exists` guard | Use guard in case site is mid-upgrade |
| Forgetting `upgrade.txt` | Plugin directory reviewers expect it |
| Removing deprecated function used by other plugins | Mark deprecated for one major, then remove |
| Using PHP 8.2 features without bumping `$plugin->requires` Moodle | Match Moodle's PHP min |
| `print_error` left after migration | Replace with `throw new moodle_exception` |
| `external_api` namespace mismatch breaking 4.1 | Use compatibility alias |

## Tools

```bash
# Find deprecated API usage
phpcs --standard=moodle --report=summary local/example
moodle-cs/standards/Moodle/...

# Find PHP version issues
phpcompatinfo analyser:run local/example
phpstan analyse local/example --level=5
```

## References

- Plugin upgrade flow: https://moodledev.io/docs/guides/migrating
- API deprecations: https://moodledev.io/general/development/policies/deprecation
- upgrade.txt format: https://moodledev.io/general/development/policies/codingstyle#upgrade
- Hooks API: https://moodledev.io/docs/apis/core/hooks
- Per-version notes: https://moodledev.io/general/releases
