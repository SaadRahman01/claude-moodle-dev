---
name: moodle-privacy-gdpr
description: Use when implementing or reviewing the Moodle privacy provider (GDPR) — null_provider vs request\plugin\provider, get_metadata, export_user_data, delete_data_for_user_in_context, delete_data_for_users, get_contexts_for_userid, get_users_in_context, subsystem links, and core_userlist_provider.
---

# Moodle Privacy / GDPR

## Overview

Every Moodle plugin **must** declare a privacy provider in `classes/privacy/provider.php`. The provider tells Moodle what user data the plugin stores so that the data export and deletion workflows (Site admin > Users > Privacy) work correctly. Without a provider, the privacy compliance report flags the plugin.

## When to Use

- Creating any new plugin (mandatory)
- Adding a DB table that stores user-identifying data
- Reviewing privacy compliance for plugin directory submission
- Responding to a GDPR data subject request

**Skip when:** the plugin only ships static files / no DB tables — still needs `null_provider` though.

## Decision tree

```
Plugin stores no user-identifying data?
└── implement \core_privacy\local\metadata\null_provider

Plugin stores user data, all of it via core subsystems (files, comments, ratings)?
└── implement \core_privacy\local\metadata\provider
        + link subsystems via add_subsystem_link

Plugin stores user data in its own tables?
└── implement \core_privacy\local\metadata\provider
       + \core_privacy\local\request\plugin\provider
       + \core_privacy\local\request\core_userlist_provider
```

## Null provider (no user data)

```php
<?php
namespace local_example\privacy;
defined('MOODLE_INTERNAL') || die();

class provider implements \core_privacy\local\metadata\null_provider {
    public static function get_reason(): string {
        return 'privacy:metadata';
    }
}
```

Lang string `lang/en/local_example.php`:

```php
$string['privacy:metadata'] = 'The Example plugin does not store any personal data.';
```

## Full provider (plugin tables hold user data)

```php
<?php
namespace local_example\privacy;
defined('MOODLE_INTERNAL') || die();

use core_privacy\local\metadata\collection;
use core_privacy\local\request\approved_contextlist;
use core_privacy\local\request\approved_userlist;
use core_privacy\local\request\contextlist;
use core_privacy\local\request\userlist;
use core_privacy\local\request\writer;

class provider implements
    \core_privacy\local\metadata\provider,
    \core_privacy\local\request\plugin\provider,
    \core_privacy\local\request\core_userlist_provider {

    public static function get_metadata(collection $collection): collection {
        $collection->add_database_table('local_example_items', [
            'userid'      => 'privacy:metadata:items:userid',
            'name'        => 'privacy:metadata:items:name',
            'content'     => 'privacy:metadata:items:content',
            'timecreated' => 'privacy:metadata:items:timecreated',
        ], 'privacy:metadata:items');

        // External system call:
        $collection->add_external_location_link('moodleorg', [
            'username' => 'privacy:metadata:moodleorg:username',
        ], 'privacy:metadata:moodleorg');

        // Subsystem link (files, comments):
        $collection->add_subsystem_link('core_files', [], 'privacy:metadata:filepurpose');

        return $collection;
    }

    public static function get_contexts_for_userid(int $userid): contextlist {
        $contextlist = new contextlist();
        $sql = "SELECT ctx.id
                  FROM {local_example_items} i
                  JOIN {context} ctx ON ctx.contextlevel = :ctxlevel
                                    AND ctx.instanceid = i.courseid
                 WHERE i.userid = :userid";
        $contextlist->add_from_sql($sql, [
            'ctxlevel' => CONTEXT_COURSE,
            'userid'   => $userid,
        ]);
        return $contextlist;
    }

    public static function get_users_in_context(userlist $userlist): void {
        $context = $userlist->get_context();
        if ($context->contextlevel !== CONTEXT_COURSE) {
            return;
        }
        $sql = "SELECT userid FROM {local_example_items} WHERE courseid = :courseid";
        $userlist->add_from_sql('userid', $sql, ['courseid' => $context->instanceid]);
    }

    public static function export_user_data(approved_contextlist $contextlist): void {
        global $DB;
        $user = $contextlist->get_user();
        foreach ($contextlist->get_contexts() as $context) {
            if ($context->contextlevel !== CONTEXT_COURSE) {
                continue;
            }
            $rows = $DB->get_records('local_example_items', [
                'courseid' => $context->instanceid,
                'userid'   => $user->id,
            ]);
            $data = (object)[
                'items' => array_map(fn($r) => [
                    'name'        => $r->name,
                    'content'     => $r->content,
                    'timecreated' => \core_privacy\local\request\transform::datetime($r->timecreated),
                ], $rows),
            ];
            writer::with_context($context)->export_data(
                [get_string('pluginname', 'local_example')],
                $data
            );
        }
    }

    public static function delete_data_for_all_users_in_context(\context $context): void {
        global $DB;
        if ($context->contextlevel !== CONTEXT_COURSE) {
            return;
        }
        $DB->delete_records('local_example_items', ['courseid' => $context->instanceid]);
    }

    public static function delete_data_for_user(approved_contextlist $contextlist): void {
        global $DB;
        $user = $contextlist->get_user();
        foreach ($contextlist->get_contexts() as $context) {
            if ($context->contextlevel !== CONTEXT_COURSE) {
                continue;
            }
            $DB->delete_records('local_example_items', [
                'courseid' => $context->instanceid,
                'userid'   => $user->id,
            ]);
        }
    }

    public static function delete_data_for_users(approved_userlist $userlist): void {
        global $DB;
        $context = $userlist->get_context();
        if ($context->contextlevel !== CONTEXT_COURSE) {
            return;
        }
        [$insql, $params] = $DB->get_in_or_equal($userlist->get_userids(), SQL_PARAMS_NAMED);
        $params['courseid'] = $context->instanceid;
        $DB->delete_records_select('local_example_items',
            "courseid = :courseid AND userid $insql", $params);
    }
}
```

## Required lang strings

```php
$string['privacy:metadata']                       = 'Stores user attendance items.';
$string['privacy:metadata:items']                 = 'Information about user-created items.';
$string['privacy:metadata:items:userid']          = 'The ID of the user who created the item.';
$string['privacy:metadata:items:name']            = 'The name of the item.';
$string['privacy:metadata:items:content']         = 'The body of the item.';
$string['privacy:metadata:items:timecreated']     = 'The time the item was created.';
$string['privacy:metadata:moodleorg']             = 'Items synced to moodle.org.';
$string['privacy:metadata:moodleorg:username']    = 'The username sent to moodle.org.';
$string['privacy:metadata:filepurpose']           = 'Files attached to items.';
```

Every column listed in `add_database_table` and every external location field needs a string.

## Subsystem links

If you use a core subsystem that stores user data on your behalf:

| Subsystem | Constant |
|-----------|----------|
| Files | `'core_files'` |
| Comments | `'core_comment'` |
| Ratings | `'core_rating'` |
| Tags | `'core_tag'` |
| Plagiarism | `'core_plagiarism'` |
| Portfolio | `'core_portfolio'` |
| Logs | `'core_log'` |
| Backup | `'core_backup'` |

```php
$collection->add_subsystem_link('core_files', [], 'privacy:metadata:filepurpose');
```

The subsystem provider handles export/delete; you only declare the link.

## Activity module specifics

Activities also implement `\mod_<name>\privacy\provider` with cm-context awareness. Use `\core_privacy\local\request\helper::get_context_data($context, $user)` to include the activity instance metadata in exports.

## Testing the provider

```php
// tests/privacy/provider_test.php
use core_privacy\tests\provider_testcase;

final class provider_test extends provider_testcase {
    public function test_get_contexts_for_userid(): void {
        $this->resetAfterTest();
        // ... set up data ...
        $contextlist = provider::get_contexts_for_userid($user->id);
        $this->assertCount(1, $contextlist);
    }
}
```

Useful core helper: `\core_privacy\tests\provider_testcase` provides `export_context_data_for_user`, `delete_data_for_user`, etc.

Run all privacy tests:

```bash
vendor/bin/phpunit --group core_privacy
```

## Compliance report

Site admin > Users > Privacy and policies > Plugin privacy registry. Lists every component with its declared metadata. Plugins missing a provider show as **Not yet implemented** (red) — fails moodle.org plugin directory review.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| No provider at all | Add at minimum `null_provider` |
| `null_provider` when DB stores user data | Switch to full provider |
| Missing `core_userlist_provider` | Required since Moodle 3.6+ |
| `add_database_table` columns missing lang strings | Every field needs a `privacy:metadata:...` string |
| `delete_data_for_user_in_context` (old name) | Method is `delete_data_for_user(approved_contextlist)` |
| Forgetting `add_subsystem_link('core_files')` when using files | Add — core files provider handles deletion |
| Returning `transform::datetime` from non-datetime column | Only for unix timestamps |
| `delete_data_for_all_users_in_context` not honoring context level | Always check `$context->contextlevel` first |
| Missing in plugin directory review | All providers required for moodle.org listing |

## References

- Privacy API: https://moodledev.io/docs/apis/subsystems/privacy
- Implementing the API: https://moodledev.io/docs/apis/subsystems/privacy/api
- Subsystems: https://moodledev.io/docs/apis/subsystems/privacy/api#subsystems
- Testing: https://moodledev.io/docs/apis/subsystems/privacy/api#testing
