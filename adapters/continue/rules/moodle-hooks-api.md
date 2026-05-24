---
name: moodle-hooks-api
description: Use when implementing or migrating to the Moodle 4.4+ Hooks API. Covers hook class authoring (db/hooks.php), callback registration, dispatching, replacing legacy magic callbacks (extend_navigation, before_http_headers, etc.), and testing hook listeners.
---

# Moodle Hooks API

## Overview

Moodle 4.4 introduced a typed Hooks API (`core\hook\manager`) replacing the unmaintainable jungle of magic callback functions like `<plugin>_extend_navigation`, `<plugin>_before_http_headers`, `<plugin>_extend_settings_navigation`, etc. Hooks are real classes with typed payloads, dispatched through `\core\di::get(\core\hook\manager::class)`. Plugins register interest via `db/hooks.php`.

## When to Use

- Adding cross-cutting behavior triggered by core (navigation, page output, user login, course events) without monkey-patching
- Migrating a plugin off legacy magic callbacks (deprecated 4.4+, will be removed)
- Authoring a hook *class* in core or in a plugin that other plugins can listen to
- Writing tests for hook listeners

**Skip when:** the event you care about is a `\core\event\*` (Events 2 API — different system, used for audit/logging). Hooks are for *modifying* behavior; Events are for *reacting to* facts.

## Core concepts

| Concept | Where it lives | Purpose |
|---|---|---|
| Hook class | `classes/hook/<name>.php` | Typed payload, optional setters for listeners to mutate |
| Listener registration | `db/hooks.php` | Maps hook class -> callback (`Class::method`) + priority |
| Dispatcher call | Core or plugin code | `\core\di::get(\core\hook\manager::class)->dispatch(new \plugin\hook\thing(...));` |
| Listener method | Any class | Static or instance method taking the hook instance |

## Listening to a core hook

`db/hooks.php`:

```php
<?php
defined('MOODLE_INTERNAL') || die();

$callbacks = [
    [
        'hook'     => \core\hook\output\before_standard_top_of_body_html_generation::class,
        'callback' => \local_example\hook_listener::class . '::inject_banner',
        'priority' => 100, // higher runs first
    ],
];
```

`classes/hook_listener.php`:

```php
<?php
namespace local_example;

use core\hook\output\before_standard_top_of_body_html_generation as hook;

class hook_listener {
    public static function inject_banner(hook $hook): void {
        global $USER;
        if (isguestuser() || !isloggedin()) {
            return;
        }
        $hook->add_html('<div class="alert alert-info">Hello, ' . s($USER->firstname) . '</div>');
    }
}
```

After adding or changing `db/hooks.php`, purge caches: `php admin/cli/purge_caches.php`.

## Authoring your own hook

`classes/hook/before_widget_render.php`:

```php
<?php
namespace local_example\hook;

use core\hook\described_hook_interface;
use core\hook\stoppable_event_interface;

class before_widget_render implements described_hook_interface, stoppable_event_interface {
    private bool $stopped = false;
    private string $html = '';

    public function __construct(public readonly int $widgetid, public readonly \context $context) {}

    public static function get_hook_description(): string {
        return 'Dispatched before a widget renders. Listeners may append HTML or veto rendering.';
    }

    public static function get_hook_tags(): array {
        return ['output', 'widget'];
    }

    public function add_html(string $html): void { $this->html .= $html; }
    public function get_html(): string { return $this->html; }

    public function stop(): void { $this->stopped = true; }
    public function isPropagationStopped(): bool { return $this->stopped; }
}
```

Dispatch:

```php
$hook = new \local_example\hook\before_widget_render($widgetid, $context);
\core\di::get(\core\hook\manager::class)->dispatch($hook);
if ($hook->isPropagationStopped()) {
    return ''; // veto
}
echo $hook->get_html();
```

## Migrating magic callbacks

| Legacy callback | Replacement hook |
|---|---|
| `<plugin>_extend_navigation` | `\core\hook\navigation\primary_extend` (4.5+) — check core for current name |
| `<plugin>_before_http_headers` | `\core\hook\output\before_http_headers` |
| `<plugin>_before_standard_top_of_body_html` | `\core\hook\output\before_standard_top_of_body_html_generation` |
| `<plugin>_before_footer` | `\core\hook\output\before_footer_html_generation` |
| `<plugin>_after_config` | `\core\hook\after_config` |
| `<plugin>_extend_settings_navigation` | check `\core\hook\navigation\*` for current name |

Migration steps:

1. Search for legacy callbacks: `grep -rn "function.*_extend_navigation\|_before_http_headers\|_after_config" .`
2. For each, find the matching hook class in `lib/classes/hook/` of your Moodle install.
3. Create `db/hooks.php` mapping; move the callback body into a listener class.
4. Delete the legacy function from `lib.php`.
5. Bump `version.php`, purge caches, run tests.

## Testing hook listeners

```php
<?php
namespace local_example;

defined('MOODLE_INTERNAL') || die();

final class hook_listener_test extends \advanced_testcase {
    /** @covers \local_example\hook_listener::inject_banner */
    public function test_banner_injected_for_logged_in_user(): void {
        $this->resetAfterTest();
        $this->setUser($this->getDataGenerator()->create_user());

        $hook = new \core\hook\output\before_standard_top_of_body_html_generation();
        \core\di::get(\core\hook\manager::class)->dispatch($hook);

        $this->assertStringContainsString('Hello,', $hook->get_output());
    }

    public function test_skipped_for_guest(): void {
        $this->resetAfterTest();
        $this->setGuestUser();

        $hook = new \core\hook\output\before_standard_top_of_body_html_generation();
        \core\di::get(\core\hook\manager::class)->dispatch($hook);

        $this->assertStringNotContainsString('Hello,', $hook->get_output());
    }
}
```

## CLI: list registered hooks

```bash
php admin/cli/hooks_list.php          # all hooks + listeners
php admin/cli/hooks_list.php --hook=core\\hook\\output\\before_http_headers
```

## Gotchas

- **Purge caches** after any `db/hooks.php` change. Listener registration is cached.
- **Priority** is a *hint* — order between equal priorities is undefined. Don't rely on it for correctness.
- **Stoppable hooks**: only implement `stoppable_event_interface` if vetoing is meaningful. Most output hooks are not stoppable.
- **Don't dispatch hooks from constructors or `setUp()`** — they can have side effects.
- **DI container**: always resolve `manager` via `\core\di::get(...)`. Don't `new` it.
- **Backporting**: pre-4.4 plugins still need legacy callbacks. Either keep both with a version check, or drop pre-4.4 support and bump `requires` in `version.php`.

## Checklist

- [ ] `db/hooks.php` exists with correct `hook` class FQCN
- [ ] Listener class is autoloadable (under `classes/` with PSR-4)
- [ ] Caches purged after edit
- [ ] Tests cover both the action and the no-op branch
- [ ] Legacy callback removed (or version-gated) after migration
- [ ] `version.php` bumped
