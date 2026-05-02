# Example Prompts

Real prompts that activate this plugin's skills. Drop into Claude Code after installing `moodle-dev`.

## Scaffolding

1. **New local plugin**
   > Scaffold `local_announcements` — admins post a banner, users dismiss per-session. Settings page for max length. Capability `local/announcements:manage`.

2. **New activity module**
   > Create `mod_flashcard` — instances hold a deck, students get spaced repetition. Include `mod_form.php`, `view.php`, `lib.php` with `add_instance`/`update_instance`/`delete_instance`, gradebook integration.

3. **New block**
   > Build `block_recent_certificates` showing the user's last 5 issued certificates with download link. Configurable max count, applicable on dashboard + course pages.

4. **New course format**
   > Generate `format_kanban` — sections render as Kanban columns, AJAX drag-drop reorders sections via web service.

5. **New auth plugin**
   > Scaffold `auth_magiclink` — passwordless email login. Includes login form override, token table, scheduled task purging expired tokens.

6. **New question type**
   > Create `qtype_drawing` — student draws on canvas, teacher grades manually. Include `questiontype.php`, `question.php`, `renderer.php`, edit form.

## Database / XMLDB

7. **Add a column**
   > Add a nullable `metadata` LONGTEXT to `local_announcements_posts`, bump version, write the upgrade step.

8. **Add an index**
   > Add a composite index on `(courseid, timecreated)` to `local_attendance_records` table. Update install.xml + upgrade.php.

9. **Rename a field safely**
   > Rename `local_foo.deleted` → `local_foo.is_deleted` across install.xml, upgrade.php, and all PHP usages.

## Capabilities + security

10. **Add capability**
    > Add `local/attendance:export` capability defaulting to allow for `editingteacher` and `manager`. Wire `require_capability` into `cli/export.php`.

11. **Security audit**
    > Audit `local/attendance/index.php` — flag missing `require_login`, `require_capability`, `require_sesskey`, raw `$_GET`, SQL injection, XSS.

12. **Add CSRF protection**
    > This POST handler updates DB but doesn't check sesskey. Fix it the Moodle way.

## Privacy / GDPR

13. **Null privacy provider**
    > Add a privacy provider for `local_announcements` — stores no user data.

14. **Full provider**
    > `local_attendance` stores user attendance records keyed by userid. Generate full privacy provider with `get_metadata`, `export_user_data`, `delete_data_for_user_in_context`, `delete_data_for_users`, `get_contexts_for_userid`, `get_users_in_context`.

15. **Privacy review**
    > Review `classes/privacy/provider.php` against the schema in `db/install.xml` — does it cover all user-identifying columns?

## Web services / AJAX

16. **External function**
    > Add `local_attendance_mark_present` web service — params: `(int sessionid, int userid)`, returns `(bool success, string message)`. Wire `db/services.php`, `classes/external/mark_present.php`, capability `local/attendance:mark`, ajax-callable.

17. **AJAX from AMD**
    > Wire an AMD module `local_attendance/marker` that calls the web service from #16 via `core/ajax`. Include grunt-built ESM.

18. **REST token**
    > Show how a 3rd party app authenticates to my Moodle and calls `local_attendance_mark_present` over REST.

## Hooks (Moodle 4.4+)

19. **Listen on a hook**
    > Listen on `\core\hook\output\before_standard_top_of_body_html_generation` and inject a banner from `local_announcements` settings.

20. **Define a custom hook**
    > Define a custom hook `\local_announcements\hook\post_dismissed` and dispatch it when users dismiss a banner.

## Testing

21. **PHPUnit test**
    > Write `tests/manager_test.php` for `\local_attendance\manager::mark_present()`. Use `resetAfterTest`, `getDataGenerator`, assert DB state + raised event.

22. **Data generator**
    > Create `tests/generator/lib.php` for `local_attendance` — methods `create_session()`, `create_record()`.

23. **Behat scenario**
    > Behat scenario: a teacher in course "Maths 101" marks "Alice" as present in a new attendance session, page shows "1 present".

24. **Run tests**
    > How do I run only the PHPUnit suite for `local_attendance` and only one Behat scenario tagged `@local_attendance @critical`?

## AMD / JavaScript

25. **AMD module**
    > Build `local_attendance/marker` AMD module: ES6 source in `amd/src/marker.js`, calls `core/ajax`, displays toast via `core/toast`. Include grunt build instructions.

26. **Mustache + JS**
    > Render `templates/marker.mustache` from PHP with data, hydrate via AMD, add a click handler that POSTs back.

## Performance

27. **Add MUC cache**
    > `local_announcements\manager::get_active()` hits DB on every page. Cache it via MUC application cache, invalidate on settings change.

28. **Slow query**
    > This query is doing a full scan on `mdl_logstore_standard_log`. Suggest index + rewrite using `$DB->get_recordset_sql` to avoid memory blow.

29. **Ad-hoc task**
    > Sending email per record blocks request. Move to ad-hoc task via `\core\task\manager::queue_adhoc_task()`.

## Theme

30. **Boost child theme**
    > Scaffold `theme_arbisoft` extending Boost. Override navbar logo, add custom SCSS variables for primary color, add layout override for login page.

31. **SCSS override**
    > Override Boost's `.navbar` background per-tenant via theme settings (`admin_setting_configcolourpicker`).

## Mobile app

32. **Mobile remote template**
    > Surface `local_attendance` UI in the Moodle Mobile app via `mobile.php` remote templates. Include a sample screen listing today's sessions.

## Upgrade / migration

33. **Cross-version upgrade**
    > My plugin is on Moodle 3.11 conventions. Upgrade it to 4.5: replace deprecated `external_api`, switch to `core_external\external_api`, move to PSR-4, add Hooks API where applicable, fix deprecated `print_error`.

34. **Deprecation sweep**
    > Find all deprecated API calls in `local/attendance` against Moodle 4.5 (`print_error`, `add_to_log`, `notify`, `formslib` `MoodleQuickForm` quirks, `userdate`/`format` defaults).

## Code review

35. **PR review**
    > Review the diff in `local/attendance/` against Moodle coding standards — `phpcs`, security, privacy, version bumps, lang strings.

36. **Coding style**
    > Run `phpcs --standard=moodle local/attendance` and fix every reported issue.

## CLI

37. **CLI script**
    > Add `cli/recompute.php` for `local_attendance` — accepts `--courseid=N --dry-run`. Use `clilib.php`, exit codes, locks via `\core\lock\lock_config`.
