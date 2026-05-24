# /moodle-bump-version

> Bump version.php and add an upgrade.php step for a Moodle plugin.

You will bump the Moodle plugin version and wire the upgrade step.

User's input: <args>

Steps:

1. Read `version.php` of the target plugin. If path missing, ask which plugin.
2. Compute next version:
   - Current is `YYYYMMDDXX`
   - If today's date > current date portion: new version = `<today>00`
   - If today's date == current date portion: increment the trailing 2 digits
   - If current somehow > today: increment trailing 2 digits anyway, log warning
3. Update `$plugin->version` in `version.php`. Optionally bump `$plugin->release` per semver if user indicates a breaking/feature change.
4. Open `db/upgrade.php` (create if missing — use the template from the `moodle-plugin-development` skill).
5. Add a new `if ($oldversion < <newversion>) { ... upgrade_plugin_savepoint(...); }` block at the END of the function (after existing blocks, before `return true;`).
6. Inside the block, draft the schema/data change based on the reason argument or by asking the user. Use the XMLDB API (`$dbman = $DB->get_manager()`, `field_exists`, `add_field`, `change_field_*`, `add_index`, etc.). Always guard with `*_exists()` checks.
7. Remind the user:
   - Re-export `db/install.xml` from the XMLDB editor (`/admin/tool/xmldb/`)
   - Run `php admin/cli/upgrade.php --non-interactive`
   - Add an entry in `upgrade.txt`
   - Update `CHANGELOG.md` if maintained

Print the diff and the upgrade command to run.

Reference the `moodle-upgrade-migration` skill for cross-version concerns.
