You will audit the privacy provider of a Moodle plugin.

User's input: {{{ input }}}

Activate the `moodle-privacy-gdpr` skill for context.

Steps:

1. Locate the plugin directory. If unclear, ask.
2. Read `db/install.xml` (or `db/upgrade.php` if no install.xml) — list every table and column.
3. Identify columns that store **user-identifying data**:
   - `userid`, `user_id`, `createdby`, `modifiedby`, `usermodified`, `relateduserid`
   - Free-text fields a user authored (`content`, `comment`, `description`, `note`)
   - File pointers (`itemid` referencing `mdl_files`)
   - Identifiers from external systems linked to a user
4. Read `classes/privacy/provider.php`.
5. For each user-identifying column, check:
   - It is declared in `get_metadata()` via `add_database_table` with a lang string
   - The column has an entry in `lang/en/<component>.php` of the form `privacy:metadata:<table>:<column>`
   - `get_contexts_for_userid` returns contexts where the user has data
   - `get_users_in_context` returns users who have data in a given context
   - `export_user_data` exports the data per context
   - `delete_data_for_user` and `delete_data_for_users` delete it correctly
   - `delete_data_for_all_users_in_context` honors context level
6. Check for subsystem usage:
   - If plugin attaches files via the Moodle Files API, `add_subsystem_link('core_files', ...)` must be present
   - Same for `core_comment`, `core_rating`, `core_tag` if used
7. If plugin stores no user data, check it implements `null_provider` correctly (`get_reason` returns lang string key, `privacy:metadata` lang string defined).
8. Output findings:
   - GREEN: present and correct
   - YELLOW: present but incomplete / missing lang strings
   - RED: missing entirely

Propose a fixed `provider.php` and the missing lang strings if there are issues. Don't write the changes without user confirmation if the plugin is non-trivial.
