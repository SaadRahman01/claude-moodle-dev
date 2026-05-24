# moodle-security-audit

> Use when reviewing or hardening Moodle plugin code for security — capability checks, sesskey CSRF, input validation, SQL injection, XSS, file serving, SSRF, IDOR, secrets handling, and Moodle's specific anti-patterns.

# Moodle Security Audit

## Overview

Moodle has framework-level protections (capability system, sesskey, `$DB` placeholders, output escaping) — but only if used. Most Moodle plugin CVEs come from skipping these. This skill enforces the checklist.

## When to Use

- Reviewing a PR for security
- Auditing existing plugin code
- Responding to a vulnerability report
- Pre-submission review for moodle.org plugin directory

**Skip when:** writing new feature code (use `moodle-plugin-development` — it covers the basics).

## Audit checklist (every entry script)

```php
require('../../config.php');                            // bootstrap
require_login();                                        // 1. session + cookies
$context = context_course::instance($courseid);         // 2. context
$PAGE->set_context($context);
require_capability('local/example:view', $context);     // 3. capability
require_sesskey();                                      // 4. CSRF (POST only)

$id   = required_param('id', PARAM_INT);                // 5. typed input
$name = optional_param('name', '', PARAM_TEXT);
```

Order matters. `require_login` before `context_*::instance` because login resolves $USER.

## 1. Authentication — `require_login()`

| Variant | Use |
|---------|-----|
| `require_login()` | Logged-in user, any context |
| `require_login($course)` | Logged-in + enrolled in course |
| `require_login($course, true, $cm)` | Logged-in + activity-level access |
| `require_admin()` | Site admin only |
| `require_login(null, false)` | Skips guest auto-login (rare) |

**Bug:** Forgetting `require_login()` on AJAX endpoints. AJAX still needs it — session might be valid but unauthorized.

## 2. Authorization — capabilities

```php
require_capability('local/example:edit', $context);
// or for soft check:
if (!has_capability('local/example:edit', $context)) {
    redirect(...);
}
```

**Bug — IDOR (Insecure Direct Object Reference):**

```php
// BAD — checks site-level cap, but $item belongs to a course user can't access
$item = $DB->get_record('local_example_items', ['id' => $id], '*', MUST_EXIST);
require_capability('local/example:view', context_system::instance());

// GOOD — derive context from the object
$item = $DB->get_record('local_example_items', ['id' => $id], '*', MUST_EXIST);
$context = context_course::instance($item->courseid);
require_capability('local/example:view', $context);
```

Always derive `$context` from the **object** being acted on, not from URL params.

## 3. CSRF — sesskey

Every state-changing request (POST, GET that mutates) needs:

```php
require_sesskey();
```

In forms via `formslib`: `MoodleQuickForm` adds it automatically. In raw HTML forms:

```php
<input type="hidden" name="sesskey" value="<?php echo sesskey(); ?>">
```

In AJAX `core/ajax`: token attached automatically. In raw `fetch`:

```javascript
import {sesskey} from 'core/config';
// include in body
```

**Bug:** GET request that mutates DB without sesskey check.

## 4. Input — never raw `$_GET`/`$_POST`/`$_REQUEST`

```php
$id    = required_param('id', PARAM_INT);                // throws if missing
$name  = optional_param('name', '', PARAM_TEXT);
$ids   = required_param_array('ids', PARAM_INT);
$tags  = optional_param_array('tags', [], PARAM_RAW);
```

`PARAM_RAW` accepts any input — use only with explicit downstream sanitization. `PARAM_TEXT` strips tags; `PARAM_NOTAGS` is similar; `PARAM_CLEANHTML` allows safe HTML.

**Bug:** `$_REQUEST['id']` direct access — bypasses type coercion, vulnerable to type juggling.

## 5. SQL — placeholders only

```php
// GOOD
$DB->get_records_sql('SELECT * FROM {local_example_items} WHERE name = ?', [$name]);
$DB->get_records_sql('... WHERE name = :name', ['name' => $name]);
$DB->get_records('local_example_items', ['courseid' => $cid]);

// BAD — concatenation
$DB->get_records_sql("SELECT * FROM {local_example_items} WHERE name = '$name'");

// SUBTLE BUG — string interpolation in IN clause
$ids = implode(',', $idarray);
$DB->get_records_sql("... WHERE id IN ($ids)");

// FIX — get_in_or_equal
[$insql, $params] = $DB->get_in_or_equal($idarray);
$DB->get_records_sql("... WHERE id $insql", $params);
```

**Bug:** Building `LIKE` patterns by concatenation — use `$DB->sql_like()` + `$DB->sql_like_escape()`.

```php
$pattern = '%' . $DB->sql_like_escape($search) . '%';
$where = $DB->sql_like('name', '?', false);   // case-insensitive
$DB->get_records_sql("SELECT * FROM {t} WHERE $where", [$pattern]);
```

## 6. Output — escape everything

| Function | Use |
|----------|-----|
| `s($str)` | Escape for HTML attribute / text |
| `format_string($str, true, ['context' => $c])` | Plain string with filters (multi-lang, etc.) |
| `format_text($html, FORMAT_HTML, ['context' => $c])` | Rich text — runs filters + cleans |
| `clean_text($str, FORMAT_HTML)` | Strip dangerous tags |
| `html_writer::tag('div', $content, $attrs)` | Build HTML safely |
| `$OUTPUT->render_from_template(...)` | Mustache auto-escapes `{{var}}`; raw via `{{{var}}}` |

**Always pass `context`** to `format_string`/`format_text` — controls which filters run.

**Bug:** `echo $row->name` directly — XSS if name contains tags.

```mustache
{{name}}        ← escaped (safe)
{{{name}}}      ← raw HTML (dangerous unless format_text'd in PHP first)
```

## 7. File serving — `pluginfile.php`

Never expose `$CFG->dataroot` paths directly. File areas served via `pluginfile.php` callback in `lib.php`:

```php
function local_example_pluginfile($course, $cm, $context, $filearea, $args, $forcedl, $options = []) {
    require_login($course, false, $cm);

    if ($filearea !== 'attachments') {
        return false;
    }

    $itemid = (int)array_shift($args);
    require_capability('local/example:viewfile', $context);

    $filename = array_pop($args);
    $filepath = '/' . implode('/', $args) . '/';
    $filepath = $filepath === '//' ? '/' : $filepath;

    $fs = get_file_storage();
    $file = $fs->get_file($context->id, 'local_example', $filearea, $itemid, $filepath, $filename);
    if (!$file || $file->is_directory()) {
        return false;
    }

    send_stored_file($file, 0, 0, $forcedl, $options);
}
```

**Bug:** Skipping capability check inside callback. Yes, `pluginfile.php` does session auth but **not** plugin-specific authorization.

## 8. SSRF / external HTTP

```php
$curl = new \curl();                        // Moodle's curl wrapper
$response = $curl->get($url);
```

`\curl` respects `$CFG->curlsecurityblockedhosts` + `$CFG->curlsecurityallowedport`. **Don't** use raw `curl_exec()` or `file_get_contents($url)` for user-supplied URLs.

```php
// Validate URL belongs to allowed scheme
$url = clean_param($url, PARAM_URL);
if (!$url) {
    throw new moodle_exception('invalidurl');
}
```

## 9. File uploads

- Always go through Moodle's draft area + `file_save_draft_area_files`
- Check MIME via `\core_form\filetypes_util` or `accept` filemanager option
- Set `maxfiles`, `maxbytes`, `accepted_types`
- Never trust client-provided `$_FILES['file']['type']`

## 10. Secrets

- Never commit tokens / API keys to `version.php` / source
- Store in `mdl_config_plugins` via `set_config('apikey', $value, 'local_example')`
- Read with `get_config('local_example', 'apikey')`
- For very sensitive data, encrypt with `\core\encryption` (Moodle 4.0+)

## 11. Logging

User actions trigger events; events flow to logs. **Don't log sensitive data:**

```php
// BAD
debugging("Token: $token");

// GOOD
debugging('Token issued for user ' . $userid);
```

## 12. Redirect open-redirect

```php
// BAD
$next = optional_param('returnto', '', PARAM_URL);
redirect($next);

// GOOD — whitelist or use moodle_url
$next = new moodle_url($next);
if ($next->get_host() !== (new moodle_url($CFG->wwwroot))->get_host()) {
    throw new moodle_exception('invalidurl');
}
redirect($next);
```

## Anti-patterns checklist

| Anti-pattern | Fix |
|--------------|-----|
| `$_GET['id']` | `required_param('id', PARAM_INT)` |
| Raw SQL concat | Placeholders `?` or `:name` |
| `echo $userdata` | `s()` / `format_string` / `format_text` |
| Missing `require_login()` | Add at top of every entry script |
| Missing `require_capability()` | Check on object's context, not arbitrary system |
| Missing `require_sesskey()` on POST | Always |
| Direct `$CFG->dataroot` access | Go through `\file_storage` |
| `eval()` / `create_function()` | Never |
| `unserialize($userdata)` | Never on user input — use JSON |
| `file_get_contents($userurl)` | Use `\curl` wrapper |
| `print_error()` | Deprecated — `throw new \moodle_exception(...)` |
| Hard-coded admin user check (`$USER->id == 2`) | `is_siteadmin()` or capability |
| Trusting `$_SERVER['HTTP_*']` | Check `$_SERVER['SERVER_NAME']` instead; headers spoofable |
| `md5($password)` for new code | `password_hash()` / Moodle's `hash_internal_user_password()` |
| Skipping cap check in `pluginfile` callback | Add explicitly — session auth ≠ authorization |

## Static analysis

```bash
# Moodle's local_codechecker (phpcs)
phpcs --standard=moodle local/example

# Psalm / PHPStan with Moodle stubs (community projects)
# https://github.com/MoodleHQ/moodle-local_codechecker
```

## Reporting vulnerabilities upstream

Found a bug in Moodle core? **Don't open a public issue.** Email `security@moodle.org` per the [Moodle security policy](https://moodle.org/security/).

## References

- Security overview: https://moodledev.io/general/development/policies/security
- Output escaping: https://moodledev.io/docs/apis/subsystems/output#escaping-content
- Capabilities: https://moodledev.io/docs/apis/subsystems/access
- File API: https://moodledev.io/docs/apis/subsystems/files
- DML placeholders: https://moodledev.io/docs/apis/core/dml#placeholders
- Reporting security: https://moodle.org/security/
