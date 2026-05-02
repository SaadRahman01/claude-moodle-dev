---
name: moodle-new-plugin
description: Scaffold a new Moodle plugin (asks for type + name).
argument-hint: "[type] [name] — e.g. local attendance"
---

You will scaffold a new Moodle plugin.

User's input: $ARGUMENTS

If `$ARGUMENTS` is empty or missing required values, ask the user:
1. Plugin type (one of: `local`, `mod`, `block`, `format`, `theme`, `auth`, `enrol`, `report`, `qtype`, `filter`, `repository`)
2. Plugin name (lowercase, no underscores in the name part — frankenstyle becomes `<type>_<name>`)
3. Target Moodle minimum version (default: latest LTS)
4. Whether the plugin will store user data (affects privacy provider choice)

Then:

1. Activate the `moodle-plugin-development` skill for conventions.
2. Create the directory under `<moodle-root>/<typedir>/<name>/` (e.g., `local/attendance/`). If `<moodle-root>` is unknown, ask.
3. Generate the minimum required files for the chosen plugin type using the cheatsheet in the `moodle-plugin-development` skill.
4. Always include:
   - `version.php` with correct frankenstyle component, today's date as version (`YYYYMMDD00`), and the user's `requires` value
   - `lang/en/<component>.php` with at least `pluginname`
   - `classes/privacy/provider.php` — `null_provider` if no user data, otherwise scaffold the full provider per the `moodle-privacy-gdpr` skill
   - GPL-3.0-or-later license header on every PHP file
   - `defined('MOODLE_INTERNAL') || die();` after the license block (skip in `classes/` PSR-4 files)
5. If the plugin type has type-specific required files (e.g., `mod_form.php` for activity modules, `block_<name>.php` for blocks), include them.
6. Print a summary of what was created and the next steps the user should take (run `php admin/cli/upgrade.php`, register capabilities, write tests).

Coding standards: 4-space indent, no closing `?>`, snake_case functions, PascalCase classes.

If unsure about a Moodle version difference, prefer the convention used in Moodle 4.5+ and note any back-compat concerns.
