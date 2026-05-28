# Moodle Conventions for Aider

Use the skill that matches the task. Each lives in `skills/` of the source repo;
load with `/read-only skills/<name>/SKILL.md` before working on related code.

- `moodle-accessibility` — Use when ensuring Moodle plugin UI meets WCAG 2.1 AA — semantic HTML in Mustache, ARIA via core helpers, keyboard navigation, color contrast in SCSS, focus management in modals, screen reader testing, and Pa11y/axe automation.
- `moodle-amd-javascript` — Use when writing JavaScript for Moodle — AMD modules, ES6 source, grunt build, RequireJS loading, core/ajax + core/str + core/templates + core/modal + core/notification, Mustache template hydration, and AMD unit tests.
- `moodle-behat-testing` — Use when writing or running Behat acceptance tests for Moodle plugins. Covers feature files, custom step definitions, tags, data generators in Background, JavaScript scenarios, and Selenium/Chromedriver setup.
- `moodle-hooks-api` — Use when implementing or migrating to the Moodle 4.4+ Hooks API. Covers hook class authoring (db/hooks.php), callback registration, dispatching, replacing legacy magic callbacks (extend_navigation, before_http_headers, etc.), and testing hook listeners.
- `moodle-mobile-app` — Use when integrating a Moodle plugin with the Moodle Mobile app — db/mobile.php remote templates, Ionic/Angular components delivered server-side, mobile.php view types, addons, push notifications, and offline support.
- `moodle-performance` — Use when optimizing Moodle plugin performance — MUC caching definitions, query optimization, recordsets vs records, ad-hoc and scheduled tasks, lazy loading, OPcache, query log analysis, $PERF, and performance debug toolbar.
- `moodle-phpunit-testing` — Use when writing, running, or debugging PHPUnit tests for Moodle plugins or core. Covers advanced_testcase, resetAfterTest, data generators, mocking $DB, testing events/tasks/external functions, and CLI invocation.
- `moodle-plugin-development` — Use when creating, modifying, upgrading, or reviewing Moodle plugins (local, mod, block, format, theme, auth, enrol, report, qtype, filter, repository) - covers version.php, db/install.xml + upgrade.php, db/access.php capabilities, db/services.php web services, lang strings, classes/ PSR-4 autoloading, lib.php hooks, settings.php, privacy provider, and Moodle coding standards.
- `moodle-privacy-gdpr` — Use when implementing or reviewing the Moodle privacy provider (GDPR) — null_provider vs request\plugin\provider, get_metadata, export_user_data, delete_data_for_user_in_context, delete_data_for_users, get_contexts_for_userid, get_users_in_context, subsystem links, and core_userlist_provider.
- `moodle-security-audit` — Use when reviewing or hardening Moodle plugin code for security — capability checks, sesskey CSRF, input validation, SQL injection, XSS, file serving, SSRF, IDOR, secrets handling, and Moodle's specific anti-patterns.
- `moodle-theme-development` — Use when developing Moodle themes — Boost child themes, theme/yourtheme/config.php, SCSS pre/post hooks, layouts, Mustache template overrides, theme settings, $OUTPUT renderer overrides, and theme designer mode.
- `moodle-upgrade-migration` — Use when upgrading a Moodle plugin across versions, fixing deprecated API usage, or migrating to Moodle 4.x/5.x (incl. 5.1/5.2) conventions — print_error, add_to_log, formslib changes, external_api namespace, Hooks API, /public doc-root, Routing Engine, PSR-4 migration, PHP 8.1–8.4 upgrades, and required upgrade.txt notes.
- `moodle-web-services` — Use when adding/calling Moodle web services or external functions — db/services.php, classes/external/, REST/SOAP/AJAX protocols, tokens, capabilities, parameters/returns schemas, file uploads, and rate limiting.

## Hard rules

- 4-space indent, no closing `?>`, snake_case functions, PascalCase classes
- Every PHP file: GPL-3.0-or-later header + `defined('MOODLE_INTERNAL') || die();` (skip `classes/` PSR-4)
- Every schema change: bump `version.php` + add `db/upgrade.php` step with savepoint
- Never hard-code user-facing English — use `get_string()` + `lang/en/<component>.php`
