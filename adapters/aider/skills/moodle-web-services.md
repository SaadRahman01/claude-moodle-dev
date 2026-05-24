# moodle-web-services

> Use when adding/calling Moodle web services or external functions — db/services.php, classes/external/, REST/SOAP/AJAX protocols, tokens, capabilities, parameters/returns schemas, file uploads, and rate limiting.

# Moodle Web Services

## Overview

Moodle exposes plugin functions as web services via `db/services.php` + `classes/external/<fn>.php`. Same function is callable as REST, AJAX, SOAP, or XMLRPC. Authentication is token-based for external clients, session-based for AJAX. All inputs/outputs are typed via `external_value` / `external_single_structure` / `external_multiple_structure`.

## When to Use

- Adding a function callable from mobile app, AMD JS, or external system
- Defining a service (bundle of functions) for an external client
- Issuing/managing tokens
- Returning files via web service
- Debugging "Invalid response value" or "Missing required parameter"

**Skip when:** building UI-only PHP (no remote callers) — use `moodle-plugin-development`.

## File layout

```
<plugin>/
  db/services.php                                # function + service definitions
  classes/external/get_items.php                 # one file per external function
  classes/external/get_items_returns.php         # (optional) split returns
  lang/en/<component>.php                        # service descriptions
```

## db/services.php

```php
<?php
defined('MOODLE_INTERNAL') || die();

$functions = [
    'local_example_get_items' => [
        'classname'    => 'local_example\external\get_items',
        'methodname'   => 'execute',                // default: 'execute'
        'description'  => 'Return items in a course',
        'type'         => 'read',                   // 'read' or 'write'
        'ajax'         => true,                     // callable from core/ajax
        'capabilities' => 'local/example:view',     // checked in addition to per-method checks
        'services'     => [MOODLE_OFFICIAL_MOBILE_SERVICE], // expose to mobile
    ],
    'local_example_mark_present' => [
        'classname'    => 'local_example\external\mark_present',
        'description'  => 'Mark a user present',
        'type'         => 'write',
        'ajax'         => true,
        'capabilities' => 'local/example:mark',
    ],
];

$services = [
    'Example REST API' => [
        'functions'         => array_keys($functions),
        'restrictedusers'   => 1,        // require explicit user assignment
        'enabled'           => 1,
        'shortname'         => 'local_example_api',
        'downloadfiles'     => 1,
        'uploadfiles'       => 0,
    ],
];
```

After editing: bump `version.php`, run `php admin/cli/upgrade.php`.

## External function class

```php
<?php
namespace local_example\external;
defined('MOODLE_INTERNAL') || die();

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_value;
use core_external\external_single_structure;
use core_external\external_multiple_structure;

class get_items extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'courseid' => new external_value(PARAM_INT, 'Course ID'),
            'limit'    => new external_value(PARAM_INT, 'Max items', VALUE_DEFAULT, 50),
        ]);
    }

    public static function execute(int $courseid, int $limit = 50): array {
        global $DB, $USER;

        // 1. Validate params (re-runs schema, normalizes types)
        $params = self::validate_parameters(self::execute_parameters(), [
            'courseid' => $courseid,
            'limit'    => $limit,
        ]);

        // 2. Validate context + capability
        $context = \context_course::instance($params['courseid']);
        self::validate_context($context);
        require_capability('local/example:view', $context);

        // 3. Business logic
        $rows = $DB->get_records('local_example_items',
            ['courseid' => $params['courseid']], 'timecreated DESC', '*', 0, $params['limit']);

        return array_values(array_map(fn($r) => [
            'id'   => (int)$r->id,
            'name' => format_string($r->name, true, ['context' => $context]),
            'time' => (int)$r->timecreated,
        ], $rows));
    }

    public static function execute_returns(): external_multiple_structure {
        return new external_multiple_structure(
            new external_single_structure([
                'id'   => new external_value(PARAM_INT, 'ID'),
                'name' => new external_value(PARAM_TEXT, 'Name'),
                'time' => new external_value(PARAM_INT, 'Created timestamp'),
            ])
        );
    }
}
```

**Required ordering inside `execute()`:**
1. `validate_parameters()`
2. `validate_context()`
3. `require_capability()`
4. business logic
5. format output (`format_string`, `format_text` with context)

Skipping any of (1)-(3) is a security bug.

## Moodle version notes

| Moodle | Namespace |
|--------|-----------|
| 4.2+   | `core_external\external_api` (etc.) |
| ≤ 4.1  | bare `external_api` (no namespace) |

For 4.2+ compatibility wrappers, see `lib/classes/external/`.

## Parameter types (PARAM_*)

| Constant | Use |
|----------|-----|
| `PARAM_INT` | Integers |
| `PARAM_FLOAT` | Decimals |
| `PARAM_BOOL` | true/false |
| `PARAM_TEXT` | Plain text (strips tags) |
| `PARAM_RAW` | Untrusted text — use only if you re-format on output |
| `PARAM_NOTAGS` | Strips tags, keeps entities |
| `PARAM_CLEANHTML` | Sanitized HTML |
| `PARAM_ALPHANUM` | a-zA-Z0-9 |
| `PARAM_ALPHA` | a-zA-Z |
| `PARAM_USERNAME` | Validates Moodle username |
| `PARAM_EMAIL` | Validates email |
| `PARAM_URL` | Validates URL |
| `PARAM_FILE` | Filename (no path) |
| `PARAM_PATH` | Path (no `..`) |
| `PARAM_COMPONENT` | frankenstyle (`local_example`) |
| `PARAM_CAPABILITY` | `local/example:view` |
| `PARAM_PLUGIN` | `<name>` part |
| `PARAM_AREA` | File area names |
| `PARAM_BASE64` | Base64 |

VALUE_REQUIRED (default), VALUE_OPTIONAL (omit from response if null), VALUE_DEFAULT (with default).

## Calling from REST

```bash
TOKEN=abcdef0123456789
SITE=https://moodle.example.com

curl -X POST "$SITE/webservice/rest/server.php" \
  -d "wstoken=$TOKEN" \
  -d "moodlewsrestformat=json" \
  -d "wsfunction=local_example_get_items" \
  -d "courseid=5" \
  -d "limit=10"
```

Response on error:

```json
{"exception":"invalid_parameter_exception","errorcode":"invalidparameter","message":"..."}
```

## Calling from AJAX (browser)

```javascript
import Ajax from 'core/ajax';

const [items] = await Ajax.call([{
    methodname: 'local_example_get_items',
    args: {courseid: 5, limit: 10},
}]);
```

Requires `'ajax' => true` in `db/services.php`. Session cookie auths; no token needed.

## Token issuance

```bash
# Site admin > Server > Web services > Manage tokens
# or programmatically:
```

```php
$service = $DB->get_record('external_services', ['shortname' => 'local_example_api']);
$token = \core_external\util::generate_token(
    EXTERNAL_TOKEN_PERMANENT,
    $service,
    $userid,
    \context_system::instance()
);
```

## File uploads via web service

1. Upload to draft area: `POST /webservice/upload.php?token=$T&filearea=draft&itemid=0`
2. Returns `itemid`
3. Pass that `itemid` to your function via a `PARAM_INT` param
4. In `execute()`, move from draft to plugin area:

```php
file_save_draft_area_files($params['draftitemid'], $context->id,
    'local_example', 'attachments', $itemid,
    ['subdirs' => 0, 'maxfiles' => 5]);
```

Service must have `uploadfiles => 1`.

## File downloads

Set `downloadfiles => 1` on service, serve via `pluginfile.php`. Token-authed clients append `?token=$T` to pluginfile URLs.

## Rate limiting

No built-in per-token rate limit. Options:
- `\core\session\manager::is_loggedinas()` checks
- Custom middleware via `lib/setuplib.php` hook
- Reverse-proxy rate limit (nginx `limit_req`)

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Skipping `validate_parameters()` | Always call first — ensures types match schema |
| Skipping `validate_context()` | Required for capability + permission scoping |
| Returning unformatted user text | Run through `format_string()` / `format_text()` with context |
| Schema mismatch in returns | Wrap response with `clean_returnvalue` in tests |
| Wrong namespace pre-4.2 | Use `external_api` bare; for 4.2+ use `core_external\external_api` |
| `'ajax' => true` missing for browser calls | Calls fail with `accessexception` |
| Not bumping `version.php` after `db/services.php` change | Service won't register — bump + upgrade |
| Token user lacks required capability | `require_capability` fails — assign user to service or grant cap |
| `restrictedusers => 1` but no users assigned | Site admin > Server > Web services > Authorised users |
| `MOODLE_OFFICIAL_MOBILE_SERVICE` exposes more than intended | Audit — only add functions safe for mobile app |

## Testing

```php
// tests/external/get_items_test.php
$this->setUser($user);
$result = get_items::execute($course->id, 10);
$result = external_api::clean_returnvalue(get_items::execute_returns(), $result);
$this->assertCount(2, $result);
```

`clean_returnvalue` is mandatory — catches return schema bugs.

## References

- Web services overview: https://moodledev.io/docs/apis/subsystems/external/services
- Writing a function: https://moodledev.io/docs/apis/subsystems/external/writing-a-function
- Calling from JS: https://moodledev.io/docs/apis/subsystems/external/writing-a-service#calling-from-javascript
- File uploads: https://moodledev.io/docs/apis/subsystems/external/files
- Token API: https://moodledev.io/docs/apis/subsystems/external/security
