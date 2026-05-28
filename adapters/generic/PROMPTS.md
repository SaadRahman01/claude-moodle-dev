# Moodle Development Prompts (agent-agnostic)

Drop these into any LLM coding assistant. Each section is self-contained.

## Skills (load on relevant tasks)

### moodle-accessibility

> Use when ensuring Moodle plugin UI meets WCAG 2.1 AA — semantic HTML in Mustache, ARIA via core helpers, keyboard navigation, color contrast in SCSS, focus management in modals, screen reader testing, and Pa11y/axe automation.

# Moodle Accessibility (WCAG 2.1 AA)

## Overview

Moodle targets WCAG 2.1 AA. UI in plugins must follow same standard for inclusion. Boost theme + Bootstrap 5 + Moodle's component library do most of the heavy lifting — your job is to use them correctly.

## When to Use

- Building any UI (Mustache template, modal, custom form element)
- Reviewing PR for accessibility regression
- Submission to moodle.org plugin directory (a11y is reviewed)
- Responding to a user-reported a11y bug

## Top rules

1. **Use semantic HTML**: `<button>` for actions, `<a>` for navigation, `<h1>`–`<h6>` in order
2. **Every interactive element keyboard-reachable** with visible `:focus`
3. **Every image** has `alt`; decorative images: `alt=""`
4. **Color contrast** ≥ 4.5:1 (text), 3:1 (UI components)
5. **Forms**: `<label for>` linked to every input
6. **Don't use color alone** to convey meaning
7. **Modals trap focus**, restore on close

## Semantic Mustache

```mustache
{{! BAD }}
<div class="btn" onclick="...">Save</div>

{{! GOOD }}
<button type="submit" class="btn btn-primary">{{#str}}save, core{{/str}}</button>
```

Headings:

```mustache
<h2 id="ann-heading">{{#str}}announcements, local_example{{/str}}</h2>
<section aria-labelledby="ann-heading">...</section>
```

Skip levels = WCAG fail. `<h2>` then `<h4>` is wrong.

## Forms — formslib

`MoodleQuickForm` outputs `<label for>` automatically. Don't bypass:

```php
$mform->addElement('text', 'name', get_string('name', 'local_example'));
$mform->setType('name', PARAM_TEXT);
$mform->addRule('name', null, 'required', null, 'client');

// Help button — adds aria-described relationship
$mform->addHelpButton('name', 'name', 'local_example');
```

For required fields, `addRule('required')` adds `aria-required="true"`.

## Buttons / links

| Element | Use for |
|---------|---------|
| `<button type="submit">` | Form submit |
| `<button type="button">` | JS action |
| `<a href="...">` | Navigation to a URL |

Never `<a href="#" onclick>` — use `<button>`. Never `<div role="button">` unless you also handle keyboard (Enter + Space) and focus.

## Icons

```mustache
{{#pix}}t/edit, core, {{#str}}edit, core{{/str}}{{/pix}}
```

Pix renderer outputs `<img alt="...">` with the title as alt. For decorative icons accompanying visible text:

```mustache
<button>
  {{#pix}}t/edit, core{{/pix}}<span class="visually-hidden"></span>
  {{#str}}edit, core{{/str}}
</button>
```

Bootstrap 5: `.visually-hidden` (was `.sr-only` in BS4).

## Color contrast

Boost defines `$primary`, `$secondary`, etc. Don't override to low-contrast values.

```scss
// theme/yourtheme/scss/post.scss
$primary: #0f6fc5;     // contrast vs white = 5.13:1 ✓
$danger:  #d9534f;     // contrast vs white = 3.34:1 ✗ — fails AA for text
```

Test: https://webaim.org/resources/contrastchecker/

Don't rely on color only:

```mustache
{{! BAD — color only }}
<span class="text-danger">{{name}}</span>

{{! GOOD — icon + color }}
<span class="text-danger">
  {{#pix}}t/error, core, {{#str}}invalid, local_example{{/str}}{{/pix}}
  {{name}}
</span>
```

## Tables

```mustache
<table class="table">
  <caption>{{#str}}attendance, local_example{{/str}}</caption>
  <thead>
    <tr>
      <th scope="col">{{#str}}user, core{{/str}}</th>
      <th scope="col">{{#str}}status, core{{/str}}</th>
    </tr>
  </thead>
  <tbody>
    {{#rows}}
    <tr>
      <th scope="row">{{name}}</th>
      <td>{{status}}</td>
    </tr>
    {{/rows}}
  </tbody>
</table>
```

`html_table` from `lib/outputcomponents.php` renders accessibly:

```php
$table = new \html_table();
$table->head = [get_string('name'), get_string('status')];
$table->headspan = [1, 1];
$table->caption = get_string('attendance', 'local_example');
echo \html_writer::table($table);
```

## ARIA — minimal use

Native HTML > ARIA. Only add ARIA when no native equivalent.

```mustache
{{! tab pattern — needs ARIA }}
<div role="tablist" aria-label="{{#str}}sections, local_example{{/str}}">
  <button role="tab" aria-selected="true" aria-controls="panel-1" id="tab-1">One</button>
  <button role="tab" aria-selected="false" aria-controls="panel-2" id="tab-2">Two</button>
</div>
<div role="tabpanel" id="panel-1" aria-labelledby="tab-1">...</div>
```

Bootstrap 5 tab JS handles arrow keys. Don't reimplement.

## Modals

Use `core/modal` — handles focus trap, ESC key, focus restore on close.

```javascript
import Modal from 'core/modal';

const modal = await Modal.create({
    title: await getString('confirm', 'core'),
    body: await Templates.render('local_example/confirm', {}),
    show: true,
    removeOnClose: true,
});
// focus auto-traps inside; on close, focus returns to trigger element
```

Custom focus management:

```javascript
import {trapFocus} from 'core/local/aria/focusmanager';
const release = trapFocus(modalEl);
// ... when closing:
release();
triggerEl.focus();
```

## Live regions (toasts, async updates)

```javascript
import {add as addToast} from 'core/toast';
addToast('Saved', {type: 'success'});
```

`core/toast` uses `aria-live="polite"`. For urgent alerts: `aria-live="assertive"` (sparingly — interrupts screen readers).

## Keyboard

Every interactive control:
- Focusable in source order (don't `tabindex="0"` everything)
- Activated with Enter / Space
- Visible focus ring (don't `outline: 0` without replacement)
- Custom widgets follow [WAI-ARIA Authoring Practices](https://www.w3.org/WAI/ARIA/apg/patterns/)

## Screen reader testing

| OS | SR | Browser |
|----|----|---------|
| Windows | NVDA (free) | Firefox |
| macOS | VoiceOver | Safari |
| Linux | Orca | Firefox |
| iOS | VoiceOver | Safari |
| Android | TalkBack | Chrome |

Quick checks:
- Tab through entire UI — every interactive element reachable
- Use SR-only — does the experience make sense?
- Resize text 200% — layout still works?
- Disable CSS — content order still meaningful?

## Automation

```bash
# axe-core via Puppeteer
npm install -g @axe-core/cli
axe http://localhost:8000/local/example/

# Pa11y
npm install -g pa11y
pa11y --standard WCAG2AA http://localhost:8000/local/example/
```

CI integration: run on PRs against staging.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| `<div onclick>` | `<button>` |
| Missing `alt` on `<img>` | Add — `alt=""` if decorative |
| `placeholder` as label | Add real `<label for>` |
| `outline: 0` no replacement | Restore visible focus indicator |
| Heading level skip | Sequential `<h1>`/`<h2>`/`<h3>` |
| Link text "click here" / "more" | Descriptive (`Edit user "Alice"`) |
| `role="button"` without keyboard | Use `<button>` instead |
| Color-only error indication | Add icon + text |
| Color contrast < 4.5:1 | Adjust SCSS palette |
| Modal without focus trap | Use `core/modal` |
| `aria-label` on a `<div>` with no role | Either add role or use text instead |
| `aria-hidden="true"` on focusable element | Either unhide or remove from tab order |

## Plugin directory review

moodle.org reviewers run a11y checks. Common rejection reasons:
- New custom modal without focus trap
- Hard-coded colors failing AA contrast
- Custom widgets without ARIA / keyboard
- Missing `<label>` on form fields

## References

- Accessibility: https://moodledev.io/general/development/policies/accessibility
- WCAG 2.1: https://www.w3.org/TR/WCAG21/
- WAI-ARIA APG: https://www.w3.org/WAI/ARIA/apg/
- Boost a11y: https://docs.moodle.org/dev/Boost_-_Accessibility
- pix renderer: https://moodledev.io/docs/apis/subsystems/output#pix-icons


---

### moodle-amd-javascript

> Use when writing JavaScript for Moodle — AMD modules, ES6 source, grunt build, RequireJS loading, core/ajax + core/str + core/templates + core/modal + core/notification, Mustache template hydration, and AMD unit tests.

# Moodle AMD JavaScript

## Overview

Moodle uses AMD (RequireJS) for browser JS. Source goes in `<plugin>/amd/src/*.js` (ES6+), built into minified AMD in `amd/build/*.min.js` via `grunt`. Never edit `amd/build/` directly. Modules import Moodle core helpers via string IDs (`core/ajax`, `core/str`, `core/templates`).

## When to Use

- Adding interactive JS to a plugin
- Calling a web service from the browser (`core/ajax`)
- Rendering a Mustache template client-side
- Showing a modal, notification, or toast
- Building a custom AMD module + grunt config
- Debugging "module not found" / "build out of date" warnings

**Skip when:** writing pure backend PHP — use `moodle-plugin-development`.

## File layout

```
<plugin>/
  amd/
    src/
      foo.js              # ES6 source — edit this
      bar.js
    build/                # generated; commit but never hand-edit
      foo.min.js
      foo.min.js.map
```

Module ID at runtime = `<component>/<filename>` (no extension):
- `local/example/amd/src/marker.js` → `local_example/marker`
- `mod/quiz/amd/src/preflight.js` → `mod_quiz/preflight`

## Module skeleton

```javascript
// amd/src/marker.js
import Ajax from 'core/ajax';
import Notification from 'core/notification';
import {get_string as getString} from 'core/str';
import Templates from 'core/templates';

const SELECTORS = {
    BUTTON: '[data-action="mark-present"]',
    ROW: '[data-region="attendance-row"]',
};

/**
 * Initialise: bind click handlers.
 *
 * @param {number} sessionid
 */
export const init = (sessionid) => {
    document.addEventListener('click', async (e) => {
        const btn = e.target.closest(SELECTORS.BUTTON);
        if (!btn) {
            return;
        }
        e.preventDefault();
        const userid = parseInt(btn.dataset.userid, 10);
        try {
            const result = await markPresent(sessionid, userid);
            const html = await Templates.render('local_example/row', result);
            const row = btn.closest(SELECTORS.ROW);
            Templates.replaceNode(row, html, '');
        } catch (err) {
            Notification.exception(err);
        }
    });
};

const markPresent = (sessionid, userid) => {
    const request = Ajax.call([{
        methodname: 'local_example_mark_present',
        args: {sessionid, userid},
    }]);
    return request[0];
};
```

## Loading from PHP

```php
$PAGE->requires->js_call_amd('local_example/marker', 'init', [$sessionid]);
```

The third argument array is JSON-encoded and passed to your `init` function.

## grunt build

Moodle ships a root `Gruntfile.js`. From Moodle root:

```bash
nvm use                # uses .nvmrc — match Moodle's required Node
npm ci
npx grunt amd          # build all AMD
npx grunt amd --root=local/example   # only your plugin
npx grunt watch        # rebuild on change
```

Build also runs ESLint + minification. `amd/build/*.min.js` and `*.min.js.map` are commit-required (Moodle plugin policy).

## Common core modules

| Module | Use |
|--------|-----|
| `core/ajax` | Call web services |
| `core/str` | Load lang strings (`getString('foo', 'local_example')`) |
| `core/templates` | Render Mustache (`render`, `renderForPromise`, `replaceNode`, `appendNodeContents`) |
| `core/notification` | Toasts, alerts, exception handling (`Notification.exception(err)`) |
| `core/modal` (Moodle 4.3+) | Replaces `core/modal_factory` |
| `core/modal_factory` | (deprecated 4.3+) — use `core/modal` |
| `core/toast` | Bootstrap-style ephemeral toasts (`add(msg, {type})`) |
| `core/pending` | Mark async work pending — required for Behat to wait |
| `core/event` | Custom DOM events for cross-module pub/sub |
| `core/log` | Console logging (silenced in production) |
| `core/fragment` | Server-rendered HTML fragments via `mod_x_output_fragment_*` |
| `core/url` | Build Moodle URLs |
| `core/config` | Access `M.cfg` (wwwroot, sesskey) safely |

## Mustache template + JS pair

```php
// PHP
$data = ['items' => $items, 'sesskey' => sesskey()];
echo $OUTPUT->render_from_template('local_example/list', $data);
$PAGE->requires->js_call_amd('local_example/list', 'init');
```

```mustache
{{! templates/list.mustache }}
<ul data-region="item-list">
  {{#items}}
  <li data-id="{{id}}">{{name}}</li>
  {{/items}}
</ul>
```

```javascript
// amd/src/list.js
import {get_strings as getStrings} from 'core/str';

export const init = async () => {
    const [confirmTitle, confirmBody] = await getStrings([
        {key: 'confirm', component: 'core'},
        {key: 'confirmdelete', component: 'local_example'},
    ]);
    // ...
};
```

## Pending — make Behat wait

Whenever JS does async work, mark it pending so Behat's `I wait until the page is ready` actually waits:

```javascript
import Pending from 'core/pending';

const pending = new Pending('local_example/marker:save');
try {
    await markPresent(...);
} finally {
    pending.resolve();
}
```

Without `Pending`, Behat scenarios are flaky.

## Modal (Moodle 4.3+)

```javascript
import Modal from 'core/modal';
import ModalEvents from 'core/modal_events';

const modal = await Modal.create({
    title: 'Confirm',
    body: Templates.render('local_example/confirm', data),
    show: true,
    removeOnClose: true,
});
modal.getRoot().on(ModalEvents.save, () => { /* handler */ });
```

## ESLint / coding style

Moodle ships `.eslintrc` in root. Run:

```bash
npx grunt eslint --root=local/example
```

Rules:
- ES2018+ source, transpile via grunt
- Prefer `const`/`let`, never `var`
- Arrow functions for callbacks
- JSDoc on every exported function (`@param`, `@return`)
- 4-space indent
- Single quotes for strings
- Semicolons mandatory
- No `console.log` (use `core/log`)

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Editing `amd/build/*.min.js` | Edit `amd/src/*.js`, run `npx grunt amd` |
| Forgetting to commit `amd/build/` | Plugin policy — commit both src + build |
| Wrong module ID (`local_example/amd/marker`) | Use `local_example/marker` (no `amd/`) |
| `require(['jquery'], ...)` syntax | Use ES6 imports — grunt transpiles to AMD |
| No `Pending` around async | Behat scenarios flake — wrap with `core/pending` |
| Hard-coded strings | Load via `core/str` so they translate |
| `core/modal_factory` in 4.3+ | Switch to `core/modal` |
| Not passing args to `js_call_amd` | Args become `init(arg1, arg2)` parameters |
| Building with wrong Node version | `nvm use` from Moodle root respects `.nvmrc` |
| `M.cfg.wwwroot` directly | Import `core/config` for safe access |

## Calling web services

```javascript
import Ajax from 'core/ajax';

const requests = Ajax.call([
    {methodname: 'local_example_get_items', args: {courseid: 5}},
    {methodname: 'local_example_get_users', args: {courseid: 5}},
]);
const [items, users] = await Promise.all(requests);
```

Methods must be declared `'ajax' => true` in `db/services.php`. The web service token is auto-attached from session (no manual sesskey for AJAX).

## Testing AMD

Moodle's AMD has limited unit-test infrastructure. Options:
- **Manual** — load page, interact, watch console (`Notification.exception` surfaces errors)
- **Behat with `@javascript`** — full browser testing
- **Jest** (Moodle 4.4+) — `npx grunt jest` runs `tests/jest/*.test.js` if present

## References

- JavaScript modules: https://moodledev.io/docs/apis/subsystems/javascript-modules
- AMD: https://moodledev.io/docs/apis/subsystems/javascript-modules#amd-modules
- Templates JS: https://moodledev.io/docs/apis/subsystems/output/templates#using-templates-from-javascript
- core/ajax: https://moodledev.io/docs/apis/subsystems/external/writing-a-service#calling-from-javascript
- Modal: https://moodledev.io/docs/apis/subsystems/output/modal
- Coding style: https://moodledev.io/general/development/policies/codingstyle/javascript


---

### moodle-behat-testing

> Use when writing or running Behat acceptance tests for Moodle plugins. Covers feature files, custom step definitions, tags, data generators in Background, JavaScript scenarios, and Selenium/Chromedriver setup.

# Moodle Behat Testing

## Overview

Behat drives a real browser against a dedicated Moodle test site. Features live in `<plugin>/tests/behat/*.feature`. Custom steps go in `tests/behat/behat_<component>.php` extending `behat_base`. Moodle provides hundreds of built-in steps (login, course creation, navigation).

## When to Use

- Writing end-to-end / acceptance tests
- Testing JavaScript-driven UI (drag-drop, modals, AJAX)
- Reproducing bugs that need full request cycle + cookies + session
- Adding scenarios to a plugin's regression suite

**Skip when:** writing unit tests for business logic — use `moodle-phpunit-testing`.

## First-time setup

```bash
# config.php additions:
$CFG->behat_wwwroot   = 'http://localhost:8000';
$CFG->behat_dataroot  = '/var/moodledata_behat';
$CFG->behat_prefix    = 'beh_';

# Initialize test site:
php admin/tool/behat/cli/init.php

# Install + start a Selenium-compatible driver (one of):
docker run -d -p 4444:4444 selenium/standalone-chrome:latest
# or chromedriver, geckodriver

# Run:
vendor/bin/behat --config /var/moodledata_behat/behat/behat.yml \
  --tags @local_example
```

## Feature file skeleton

```gherkin
@local_example @javascript
Feature: Mark attendance
  In order to track presence
  As a teacher
  I need to mark students present

  Background:
    Given the following "courses" exist:
      | fullname | shortname |
      | Maths    | M101      |
    And the following "users" exist:
      | username | firstname | lastname |
      | teacher1 | Tina      | Teach    |
      | student1 | Sam       | Student  |
    And the following "course enrolments" exist:
      | user     | course | role           |
      | teacher1 | M101   | editingteacher |
      | student1 | M101   | student        |

  Scenario: Teacher marks a student present
    Given I log in as "teacher1"
    And I am on "Maths" course homepage
    When I follow "Attendance"
    And I click on "Mark present" "button" in the "Sam Student" "table_row"
    Then I should see "1 present" in the "Today" "fieldset"
```

Tags:
- `@<component>` — required for `--tags` filtering
- `@javascript` — uses real browser; without it, runs headless (Goutte) — fast but no JS
- `@_file_upload`, `@_switch_window`, `@_alert` — capability tags so runner can skip on incompatible drivers

## Background data generators

Moodle exposes generators as Behat steps via `behat_data_generators`:

```gherkin
Given the following "local_example > items" exist:
  | course | name        | userid    |
  | M101   | First item  | student1  |
```

To enable, declare in `tests/generator/lib.php` AND register in `tests/behat/behat_local_example.php`:

```php
public function get_creatable_entities(): array {
    return [
        'items' => [
            'singular' => 'item',
            'datagenerator' => 'item',
            'required' => ['name'],
            'switchids' => ['course' => 'courseid', 'user' => 'userid'],
        ],
    ];
}
```

Generator method:

```php
// in local_example_generator
public function create_item(array $record): \stdClass {
    // same as PHPUnit generator
}
```

## Custom step definitions

`tests/behat/behat_local_example.php`:

```php
<?php
require_once(__DIR__ . '/../../../../lib/behat/behat_base.php');

use Behat\Mink\Exception\ExpectationException;

class behat_local_example extends behat_base {

    /**
     * @Given /^there are (\d+) attendance items$/
     */
    public function there_are_n_items(int $count): void {
        $gen = \testing_util::get_data_generator()
            ->get_plugin_generator('local_example');
        for ($i = 0; $i < $count; $i++) {
            $gen->create_item();
        }
    }

    /**
     * @Then /^the attendance count should be "(\d+)"$/
     */
    public function attendance_count_should_be(int $expected): void {
        global $DB;
        $actual = $DB->count_records('local_example_items');
        if ($actual !== $expected) {
            throw new ExpectationException(
                "Expected $expected, got $actual",
                $this->getSession()
            );
        }
    }
}
```

Class name **must** match `behat_<component>`. After adding/changing steps:

```bash
php admin/tool/behat/cli/init.php    # re-scan
```

## Running

```bash
# All Behat for plugin
vendor/bin/behat --config $CFG->behat_dataroot/behat/behat.yml --tags @local_example

# Single feature
vendor/bin/behat --config ... tests/behat/mark_attendance.feature

# Single scenario (line number)
vendor/bin/behat --config ... tests/behat/mark_attendance.feature:23

# Parallel (4 runners)
php admin/tool/behat/cli/init.php --parallel=4
vendor/bin/moodle_behat_parallel_run --tags @local_example
```

## Selectors (Mink)

| Type | Example |
|------|---------|
| `link` | `I follow "Settings"` |
| `button` | `I press "Save changes"` |
| `field` | `I set the field "Name" to "X"` |
| `select` | `I set the field "Role" to "Manager"` |
| `checkbox` | `I check "Visible"` |
| `table_row` | `... in the "Alice" "table_row"` |
| `fieldset` | `... in the "General" "fieldset"` |
| `dialogue` | `... in the "Confirm" "dialogue"` |
| `css_element` | `I click on ".foo .bar" "css_element"` |
| `xpath_element` | `I click on "//button[@data-x='y']" "xpath_element"` |

## Useful built-in steps

```gherkin
And I am on the "Course 1" "course" page logged in as "teacher1"
And I navigate to "Users > Enrolment methods" in current course administration
And I should see "X" in the "block_settings" "block"
And I wait until the page is ready
And I wait "2" seconds                # avoid; prefer wait-until
And I run the scheduled task "\local_example\task\cleanup"
And I run all adhoc tasks
And the following config values are set as admin:
  | config        | value | plugin        |
  | enabled       | 1     | local_example |
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Adding step but not running `behat/cli/init.php` | Re-init after every PHP step change |
| Missing `@javascript` for AJAX UI | Tag scenario `@javascript` and run with browser driver |
| Hard-coded sleeps `I wait 5 seconds` | Use `I wait until ... exists/disappears` |
| Class name mismatch | Must be `behat_<component>` |
| Not switching to dialogue context | Add `in the "..." "dialogue"` selector |
| Forgetting capability tags (`@_file_upload`) | Add so runner can skip on incompatible browsers |
| Editing `behat.yml` directly | Regenerated by `init.php` — config in `config.php` instead |

## Debugging

```bash
# Save HTML+screenshot on failure
$CFG->behat_faildump_path = '/tmp/behat-fails';

# Run a single scenario in foreground browser
vendor/bin/behat --config ... --tags @mytag --stop-on-failure -v

# Pause for inspection
And I should see "this will fail"     # forces a wait you can attach to
```

## CI snippet

```yaml
- name: Behat
  run: |
    php admin/tool/behat/cli/init.php
    vendor/bin/behat --config $MOODLE_DATA/behat/behat.yml \
      --tags @local_example --format=progress
```

## References

- Behat in Moodle: https://moodledev.io/general/development/tools/behat
- Writing tests: https://moodledev.io/general/development/tools/behat/writing
- Step reference: https://moodledev.io/general/development/tools/behat/writing#step-definitions
- Data generators: https://moodledev.io/docs/apis/subsystems/testing/generators#behat


---

### moodle-hooks-api

> Use when implementing or migrating to the Moodle 4.4+ Hooks API. Covers hook class authoring (db/hooks.php), callback registration, dispatching, replacing legacy magic callbacks (extend_navigation, before_http_headers, etc.), and testing hook listeners.

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


---

### moodle-mobile-app

> Use when integrating a Moodle plugin with the Moodle Mobile app — db/mobile.php remote templates, Ionic/Angular components delivered server-side, mobile.php view types, addons, push notifications, and offline support.

# Moodle Mobile App Integration

## Overview

Moodle Mobile app (Ionic/Angular) loads plugin UI as **remote templates** declared in `db/mobile.php`. The server returns Mustache-like templates + JS that the app renders inline. No app rebuild required — works on any user's installed app once the site declares the addon.

## When to Use

- Adding plugin UI to mobile app
- Surfacing notifications, dashboard items, or activity views in the app
- Offline-capable content
- Push notifications for plugin events

**Skip when:** plugin only used in browser admin UI.

## Architecture

```
Moodle server                          Moodle Mobile app
─────────────                          ─────────────────
db/mobile.php          ────────────►   Discovers addons via
classes/output/mobile.php              tool_mobile_get_plugins_supporting_mobile

Returns                ────────────►   Renders Ionic components
  templates (.html)
  initial JS
  styles
```

App calls a server function which returns:
- A Mustache-like template (Ionic + custom directives)
- Optional JS to run client-side
- Optional initial data
- Optional offline functions

## db/mobile.php

```php
<?php
defined('MOODLE_INTERNAL') || die();

$addons = [
    'local_example' => [
        'handlers' => [
            'mainmenu' => [
                'displaydata' => [
                    'title' => 'pluginname',
                    'icon'  => 'list',
                    'class' => '',
                ],
                'delegate'    => 'CoreMainMenuDelegate',
                'method'      => 'mobile_main_menu_view',
                'styles'      => [
                    'url'     => '/local/example/mobile/styles.css',
                    'version' => 1,
                ],
                'offlinefunctions' => [
                    'mobile_main_menu_view' => [],
                ],
            ],
            'courseoption' => [
                'displaydata' => [
                    'title' => 'attendance',
                    'class' => '',
                ],
                'delegate' => 'CoreCourseOptionsDelegate',
                'method'   => 'mobile_course_view',
            ],
        ],
        'lang' => [
            ['pluginname', 'local_example'],
            ['attendance', 'local_example'],
        ],
    ],
];
```

### Delegates

| Delegate | Where it shows |
|----------|----------------|
| `CoreMainMenuDelegate` | Main menu (bottom tab bar) |
| `CoreUserDelegate` | User profile page |
| `CoreCourseOptionsDelegate` | Course menu |
| `CoreCourseModuleDelegate` | Activity in course (for `mod_*` plugins) |
| `CoreBlockDelegate` | Sidebar block (for `block_*`) |
| `CoreSettingsDelegate` | App settings page |
| `CoreMessageOutputDelegate` | Message output handler |

## classes/output/mobile.php

```php
<?php
namespace local_example\output;
defined('MOODLE_INTERNAL') || die();

class mobile {

    public static function mobile_main_menu_view(array $args): array {
        global $DB, $USER;

        $items = $DB->get_records('local_example_items',
            ['userid' => $USER->id], 'timecreated DESC', '*', 0, 20);

        return [
            'templates' => [
                [
                    'id'   => 'main',
                    'html' => self::render_main_template(),
                ],
            ],
            'javascript' => self::get_javascript(),
            'otherdata'  => [
                'items' => json_encode(array_values($items)),
                'sesskey' => sesskey(),
            ],
            'files' => [],
        ];
    }

    private static function render_main_template(): string {
        return '
<ion-list>
    <ion-item-divider><ion-label>{{ \'plugin.local_example.attendance\' | translate }}</ion-label></ion-item-divider>
    <ion-item *ngFor="let item of CONTENT_OTHERDATA.items">
        <ion-label>
            <h2>{{ item.name }}</h2>
            <p>{{ item.timecreated | coreFormatDate }}</p>
        </ion-label>
        <ion-button slot="end" (click)="markPresent(item.id)">
            {{ \'plugin.local_example.markpresent\' | translate }}
        </ion-button>
    </ion-item>
</ion-list>';
    }

    private static function get_javascript(): string {
        return "
this.markPresent = (id) => {
    const params = {sessionid: id, userid: this.CoreSitesProvider.getCurrentSite().getUserId()};
    return this.CoreSitesProvider.getCurrentSite()
        .write('local_example_mark_present', params)
        .then((result) => {
            this.CoreDomUtilsProvider.showToast('plugin.local_example.marked', true, 2000);
        });
};";
    }
}
```

## Required web services

The function name in `db/mobile.php` (`'method' => 'mobile_main_menu_view'`) must be exposed as a web service in `db/services.php`:

```php
$functions = [
    'local_example_mobile_main_menu_view' => [
        'classname'    => 'local_example\output\mobile',
        'methodname'   => 'mobile_main_menu_view',
        'description'  => 'Main menu mobile view',
        'type'         => 'read',
        'capabilities' => '',
        'services'     => [MOODLE_OFFICIAL_MOBILE_SERVICE],
    ],
];
```

Plus the AJAX/REST functions used inside the template (`local_example_mark_present`).

## Template syntax

Mobile templates use Angular + Ionic with Moodle directives:

| Directive | Use |
|-----------|-----|
| `{{ 'plugin.local_example.foo' \| translate }}` | Lang string |
| `{{ value \| coreFormatDate }}` | Format unix timestamp |
| `{{ html \| coreFormatText }}` | Format Moodle text |
| `<core-format-text [text]="html" />` | Same, component form |
| `*ngFor="let item of CONTENT_OTHERDATA.items"` | Loop |
| `*ngIf="condition"` | Conditional |
| `(click)="handler()"` | Event |
| `<ion-item>`, `<ion-list>`, `<ion-button>` | Ionic UI |
| `<core-empty-box>` | "Nothing here" placeholder |

`CONTENT_OTHERDATA` = data passed via `'otherdata'`. Strings JSON-decoded automatically.

## JavaScript scope

Helpers injected into JS scope:

| Object | Use |
|--------|-----|
| `this.CoreSitesProvider` | Current site, current user, web service calls |
| `this.CoreDomUtilsProvider` | Toasts, alerts, modals |
| `this.CoreFilepoolProvider` | Cache files for offline |
| `this.CoreUtilsProvider` | Misc helpers |
| `this.refreshContent(false)` | Reload current view |

## Offline support

Add functions to `'offlinefunctions'`:

```php
'offlinefunctions' => [
    'mobile_main_menu_view' => [],
    'local_example_get_items' => [],
],
```

App pre-fetches results during sync — they survive offline. For mutations (mark present), use the offline write API:

```javascript
this.CoreSitesProvider.getCurrentSite().write(
    'local_example_mark_present',
    params,
    {forceOffline: false, getFromCache: false}
).catch((error) => {
    if (this.CoreUtilsProvider.isWebServiceError(error)) {
        return Promise.reject(error);
    }
    // Queue for later sync
    return this.CoreCourseProvider.storeOfflineAction(...);
});
```

## Push notifications

Push delivery via Moodle's airnotifier service. Plugin events trigger notifications via `\core\message\manager::send_message()`. Mobile app receives them automatically when:

- Site has airnotifier configured (Site admin > Mobile > Push notifications)
- User logged into mobile app
- User has the addon's notification preference enabled

## Testing

1. Local dev: install Moodle Mobile app, point at `http://10.0.2.2:8000` (Android emulator) or your LAN IP
2. Site admin > Mobile > Enable web services for mobile devices
3. Log in to app — addon appears
4. To force template re-fetch after server change: pull-to-refresh, or app settings > Synchronisation > Synchronise now
5. Browser-based dev: `npx ionic serve` against [`moodle-mobile-app`](https://github.com/moodlehq/moodleapp) source pointing at your site

## Styles

`local/example/mobile/styles.css` (referenced from `db/mobile.php`):

```css
.local_example-marked {
    color: var(--ion-color-success);
    font-weight: bold;
}
```

Bumping `'version' => N` in `db/mobile.php` invalidates app's cached styles.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Method not exposed as web service | Declare in `db/services.php` with `MOODLE_OFFICIAL_MOBILE_SERVICE` |
| Lang strings not declared in `db/mobile.php` | App can't render `{{ 'plugin...' | translate }}` |
| `<div>` instead of Ionic `<ion-*>` | Use Ionic components for native look |
| Forgetting `MOODLE_OFFICIAL_MOBILE_SERVICE` | Web service callable but not for mobile |
| Heavy DB queries on every refresh | Cache via MUC + invalidate on update |
| Hand-formatting timestamps | Use `coreFormatDate` filter |
| Embedding HTML directly | Use `coreFormatText` for `format_text`-equivalent escaping |
| No `offlinefunctions` for read views | Pre-fetch fails — declare them |
| Not bumping styles `version` | App keeps old CSS |
| Calling `fetch()` directly | Use `CoreSitesProvider` — handles auth + tokens |

## References

- Mobile addons: https://moodledev.io/general/app/development/plugins-development-guide
- Templates spec: https://moodledev.io/general/app/development/plugins-development-guide/templates
- Delegates list: https://moodledev.io/general/app/development/plugins-development-guide/api-reference
- Offline support: https://moodledev.io/general/app/development/plugins-development-guide/offline
- Push notifications: https://moodledev.io/general/app/development/plugins-development-guide/notifications
- App source: https://github.com/moodlehq/moodleapp


---

### moodle-performance

> Use when optimizing Moodle plugin performance — MUC caching definitions, query optimization, recordsets vs records, ad-hoc and scheduled tasks, lazy loading, OPcache, query log analysis, $PERF, and performance debug toolbar.

# Moodle Performance

## Overview

Moodle bottlenecks: too many DB queries per request, full-table scans, loading large recordsets into memory, blocking work on the request path. Mitigations: MUC caching, indexes, recordsets, ad-hoc tasks, careful capability checks.

## When to Use

- Page renders slowly / hits per-page query limits
- N+1 query pattern in loops
- Memory-blow on large datasets
- Long-running operations on POST handlers
- Tuning a custom report or scheduled task

## Diagnosis

### Performance debug

`config.php`:

```php
$CFG->debug = (E_ALL | E_STRICT);
$CFG->debugdisplay = 1;
$CFG->perfdebug = 15;     // shows query count + timings in footer
```

Site admin > Development > Debugging > Performance info: enables the footer toolbar (queries, time, memory, MUC hits/misses, sessions reads/writes).

### `$PERF`

```php
global $PERF;
$start = microtime(true);
// ... work ...
$PERF->dbqueries++;       // your manual counter
mtrace('Took ' . round(microtime(true) - $start, 3) . 's');
```

### Slow query log

Postgres / MySQL slow-query log — turn on in dev. Moodle prefixes queries with the source class via `$CFG->dboptions['debug']`.

## MUC — Moodle Universal Cache

3 cache modes:

| Mode | Storage | Lifetime | Use |
|------|---------|----------|-----|
| `MODE_APPLICATION` | Persistent (file/Redis/Memcached) | Until invalidated | Shared computed values |
| `MODE_SESSION` | Session | Session lifetime | Per-user computed values |
| `MODE_REQUEST` | PHP request | Single request | Memoize within request |

### Define a cache

`db/caches.php`:

```php
<?php
defined('MOODLE_INTERNAL') || die();

$definitions = [
    'active_announcements' => [
        'mode'         => cache_store::MODE_APPLICATION,
        'simplekeys'   => true,
        'simpledata'   => true,
        'ttl'          => 600,
        'invalidationevents' => ['changesin_local_announcements'],
    ],
    'user_dashboard' => [
        'mode'       => cache_store::MODE_SESSION,
        'simplekeys' => true,
    ],
];
```

Bump `version.php` after edits.

### Use the cache

```php
$cache = \cache::make('local_announcements', 'active_announcements');
$value = $cache->get('all');
if ($value === false) {
    $value = $this->compute_announcements();
    $cache->set('all', $value);
}
return $value;
```

### Invalidate

```php
\cache_helper::invalidate_by_event('changesin_local_announcements', ['all']);
// or
$cache->delete('all');
$cache->purge();
```

Trigger invalidation from a settings save or an observer.

### `simplekeys` / `simpledata`

- `simplekeys: true` — keys are alphanum (skips hashing) — faster
- `simpledata: true` — values are scalars/arrays of scalars (skips serialization) — much faster

Use both whenever possible.

### Static cache (per-request)

```php
$cache = \cache::make('local_announcements', 'request_lookup');
// MODE_REQUEST in caches.php — auto-cleared at end of request
```

## DB optimization

### Recordsets for large data

```php
// BAD — loads everything into memory
$rows = $DB->get_records('huge_table');
foreach ($rows as $r) { /* ... */ }

// GOOD — streams
$rs = $DB->get_recordset('huge_table');
foreach ($rs as $r) { /* ... */ }
$rs->close();      // ALWAYS close
```

Use `get_recordset_sql` with `LIMIT` + offset for batched processing of millions of rows.

### Avoid N+1

```php
// BAD
foreach ($courses as $c) {
    $teacher = $DB->get_record('user', ['id' => $c->teacherid]);
}

// GOOD — single query
$tids = array_column($courses, 'teacherid');
[$insql, $params] = $DB->get_in_or_equal($tids);
$teachers = $DB->get_records_sql("SELECT * FROM {user} WHERE id $insql", $params);
```

### Indexes

```xml
<INDEX NAME="userid-courseid" UNIQUE="false" FIELDS="userid, courseid"/>
```

Edit via XMLDB editor. Composite index column order matters — most-selective first, leftmost-prefix usable for partial queries.

### `EXPLAIN` your queries

```bash
mysql> EXPLAIN SELECT ... ;
postgres=# EXPLAIN ANALYZE SELECT ... ;
```

Look for:
- `type: ALL` (full scan) — needs index
- `Using filesort` / `Using temporary` — sort spilling
- High `rows` estimate — selectivity issue

## Move work off the request

### Ad-hoc task — fire-and-forget

```php
// classes/task/send_report.php
namespace local_example\task;
class send_report extends \core\task\adhoc_task {
    public function execute(): void {
        $data = $this->get_custom_data();
        // do work
    }
}

// trigger:
$task = new \local_example\task\send_report();
$task->set_custom_data(['userid' => $user->id, 'reportid' => $r->id]);
$task->set_userid($user->id);     // runs as that user
\core\task\manager::queue_adhoc_task($task);
```

Tasks run via cron. Long jobs don't block HTTP request.

### Scheduled task — recurring

`db/tasks.php`:

```php
$tasks = [[
    'classname' => 'local_example\task\cleanup',
    'blocking'  => 0,
    'minute'    => '0',
    'hour'      => '3',
    'day'       => '*',
    'month'     => '*',
    'dayofweek' => '*',
]];
```

```php
class cleanup extends \core\task\scheduled_task {
    public function get_name(): string {
        return get_string('task:cleanup', 'local_example');
    }
    public function execute(): void {
        // ...
    }
}
```

Run cron: `php admin/cli/cron.php`. Production: cron entry every minute.

### Locks for non-overlapping execution

```php
$locktype = 'local_example_cleanup';
$lockfactory = \core\lock\lock_config::get_lock_factory($locktype);
if (!$lock = $lockfactory->get_lock('main', 5)) {
    return;     // another instance running
}
try {
    // ...
} finally {
    $lock->release();
}
```

## Capability check optimization

`has_capability()` is expensive at scale. For lists:

```php
// BAD — N capability checks
foreach ($users as $u) {
    if (has_capability('mod/quiz:attempt', $context, $u)) { /* ... */ }
}

// GOOD — single batched query
$users = get_users_by_capability($context, 'mod/quiz:attempt', 'u.id, u.firstname, u.lastname');
```

## Output / page

```php
$PAGE->set_pagelayout('embedded');     // skips heavy regions when appropriate
$PAGE->add_body_class('skip-some-blocks');
```

Lazy-load AMD modules:

```javascript
// only load when needed
const onClick = async () => {
    const {init} = await import('local_example/heavy');
    init();
};
```

## OPcache + APCu

`php.ini`:

```ini
opcache.enable = 1
opcache.memory_consumption = 256
opcache.max_accelerated_files = 20000
opcache.validate_timestamps = 0    # production only
opcache.revalidate_freq = 0
```

Moodle benefits massively from OPcache. With `validate_timestamps=0`, restart PHP after deploys.

APCu for Moodle config cache: `$CFG->localcachedir = '/var/cache/moodle';`

## Sessions

- Use Redis sessions in production (`$CFG->session_handler_class = '\core\session\redis'`)
- File sessions don't scale past one app server
- Session writes — see "session lock" issues if multiple AJAX requests block on session

```php
// release session lock early when only reading
\core\session\manager::write_close();
```

## Frontend

- Run `npx grunt amd` — production builds are minified
- Enable browser caching: `$CFG->cachejs = true; $CFG->cachetemplates = true;`
- Theme designer mode (`$CFG->themedesignermode`) — OFF in production (disables CSS cache)

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| `get_records` on huge table | `get_recordset` + close |
| N+1 in loops | Batch with `get_in_or_equal` |
| Sending email on POST | Move to ad-hoc task |
| `has_capability` per row | `get_users_by_capability` |
| MUC without `simplekeys`/`simpledata` | Set both true when possible |
| MUC `MODE_REQUEST` for cross-request data | Use `MODE_APPLICATION` |
| Long lock without try/finally | Release in `finally` block always |
| Theme designer mode on prod | Off — kills CSS caching |
| `validate_timestamps = 1` | OFF in prod, restart on deploy |
| Forgetting `$rs->close()` | Recordset leaks — always close |
| File sessions on multi-app-server | Switch to Redis/Memcached |

## Profiling

`xhprof` / `tideways`:

```php
// quick on-demand profile
$CFG->profilingenabled = true;
$CFG->profilingautostart = false;
// add ?PROFILEME to URL — view in admin/tool/profiling
```

Per-request: `Site admin > Development > Profiling`.

## References

- MUC: https://moodledev.io/docs/apis/subsystems/muc
- Tasks API: https://moodledev.io/docs/apis/core/task
- Performance recommendations: https://docs.moodle.org/en/Performance_recommendations
- DB API recordsets: https://moodledev.io/docs/apis/core/dml#get_recordset
- Profiling: https://moodledev.io/general/development/tools/profiling


---

### moodle-phpunit-testing

> Use when writing, running, or debugging PHPUnit tests for Moodle plugins or core. Covers advanced_testcase, resetAfterTest, data generators, mocking $DB, testing events/tasks/external functions, and CLI invocation.

# Moodle PHPUnit Testing

## Overview

Moodle ships its own PHPUnit harness with test bootstrap, transactional resets, and data generators. Tests live in `<plugin>/tests/<thing>_test.php` and extend `advanced_testcase`. Never call `parent::setUp()` for DB cleanup — use `$this->resetAfterTest()`.

## When to Use

- Writing unit/integration tests for any Moodle plugin or core API
- Debugging test failures (`Database was modified` errors, isolation issues)
- Adding a data generator (`tests/generator/lib.php`)
- Testing events, scheduled tasks, ad-hoc tasks, external functions
- Setting up CI for Moodle test suites

**Skip when:** writing Behat acceptance tests (use `moodle-behat-testing`).

## First-time setup

```bash
php admin/tool/phpunit/cli/init.php       # writes phpunit.xml + initializes test DB
vendor/bin/phpunit --testsuite local_example_testsuite
```

`phpunit.xml` is regenerated by `init.php` — never hand-edit. Re-run after installing a new plugin.

## Test class skeleton

```php
<?php
namespace local_example;
defined('MOODLE_INTERNAL') || die();

/**
 * @group local_example
 * @covers \local_example\manager
 */
final class manager_test extends \advanced_testcase {

    public function test_create_item(): void {
        $this->resetAfterTest();
        $generator = self::getDataGenerator();
        $course = $generator->create_course();
        $user = $generator->create_user();

        $manager = new manager();
        $id = $manager->create_item($course->id, $user->id, 'hello');

        global $DB;
        $row = $DB->get_record('local_example_items', ['id' => $id], '*', MUST_EXIST);
        $this->assertSame('hello', $row->name);
    }
}
```

Key rules:
- File name: `<thing>_test.php`, class: `<thing>_test`
- `final class` (Moodle policy since 4.2)
- `@covers` annotation required by Moodle CS
- `@group <component>` enables `--group` filtering
- `void` return type on test methods, `: void` on `setUp`
- `self::` (not `$this->`) for static methods like `getDataGenerator()`

## Data generators

Plugin generator at `tests/generator/lib.php`:

```php
<?php
defined('MOODLE_INTERNAL') || die();

class local_example_generator extends component_generator_base {
    public function create_item(array $record = []): \stdClass {
        global $DB, $USER;
        $defaults = [
            'courseid'   => 0,
            'userid'     => $USER->id,
            'name'       => 'Item ' . random_string(8),
            'timecreated'=> time(),
        ];
        $record = (object)array_merge($defaults, $record);
        $record->id = $DB->insert_record('local_example_items', $record);
        return $record;
    }
}
```

Use:

```php
$gen = self::getDataGenerator()->get_plugin_generator('local_example');
$item = $gen->create_item(['name' => 'test']);
```

Activity module generator extends `testing_module_generator` and implements `create_instance()`.

## Common patterns

### Test an event

```php
$sink = $this->redirectEvents();
$manager->do_thing();
$events = $sink->get_events();
$sink->close();
$this->assertCount(1, $events);
$this->assertInstanceOf(\local_example\event\thing_done::class, $events[0]);
```

### Test an email

```php
$sink = $this->redirectEmails();
$manager->notify($user);
$messages = $sink->get_messages();
$this->assertSame($user->email, $messages[0]->to);
```

### Test a scheduled task

```php
$task = new \local_example\task\cleanup();
$task->execute();
// assert side effects
```

### Test an external (web service) function

```php
$this->setUser($user);
$result = \local_example\external\get_items::execute($courseid);
$result = \core_external\external_api::clean_returnvalue(
    \local_example\external\get_items::execute_returns(),
    $result
);
$this->assertCount(2, $result);
```

`clean_returnvalue` is mandatory — catches schema mismatches.

### Test an ad-hoc task

```php
\core\task\manager::queue_adhoc_task(new \local_example\task\send_report());
$this->runAdhocTasks(\local_example\task\send_report::class);
```

### Login as a user

```php
$user = $this->getDataGenerator()->create_user();
$this->setUser($user);             // sets $USER global
$this->setAdminUser();             // shortcut
$this->setGuestUser();
```

### Time-travel

```php
$this->mock_clock_with_frozen(1700000000);    // Moodle 4.4+
// or in older versions, manually set timecreated/timemodified
```

## Running tests

```bash
# Single suite
vendor/bin/phpunit --testsuite local_example_testsuite

# Single file
vendor/bin/phpunit local/example/tests/manager_test.php

# Single method
vendor/bin/phpunit --filter test_create_item local/example/tests/manager_test.php

# By group
vendor/bin/phpunit --group local_example

# Coverage (requires xdebug or pcov)
vendor/bin/phpunit --coverage-html coverage/ local/example/tests
```

## Test database

- Separate DB defined in `config.php`: `$CFG->phpunit_prefix = 'phpu_';`
- Reset between tests via transactions — `$this->resetAfterTest()` enables it
- Schema drift error: re-run `php admin/tool/phpunit/cli/init.php`
- "Database was modified" failure means a test mutated DB without `resetAfterTest()`

## Mocking

Moodle prefers integration tests with the real test DB over mocking `$DB`. When you must mock:

```php
$mockDB = $this->createMock(\moodle_database::class);
$mockDB->method('get_record')->willReturn((object)['id' => 1]);
// inject via DI, never replace global
```

Avoid replacing the global `$DB` — breaks isolation.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Forgetting `$this->resetAfterTest()` | Add at start of every DB-touching test |
| Class not `final` | Add `final` (Moodle 4.2+ policy) |
| Missing `@covers` | Add `@covers \Fully\Qualified\Class` |
| Hand-editing `phpunit.xml` | Re-run `admin/tool/phpunit/cli/init.php` |
| Using `parent::setUp()` to reset DB | Use `resetAfterTest()` instead |
| Skipping `clean_returnvalue` on external fn | Always wrap external returns to catch schema bugs |
| `$this->getDataGenerator()` (instance) | Moodle prefers `self::getDataGenerator()` (static) |
| Asserting time with `time()` | Use `mock_clock_with_frozen` or compare with tolerance |

## CI snippet (GitHub Actions)

```yaml
- name: PHPUnit
  run: |
    php admin/tool/phpunit/cli/init.php
    vendor/bin/phpunit --testsuite ${{ matrix.suite }}
```

## References

- PHPUnit in Moodle: https://moodledev.io/general/development/tools/phpunit
- Data generators: https://moodledev.io/docs/apis/subsystems/testing/generators
- Test writing guide: https://moodledev.io/general/development/policies/testing
- Coverage: https://moodledev.io/general/development/tools/phpunit#code-coverage


---

### moodle-plugin-development

> Use when creating, modifying, upgrading, or reviewing Moodle plugins (local, mod, block, format, theme, auth, enrol, report, qtype, filter, repository) - covers version.php, db/install.xml + upgrade.php, db/access.php capabilities, db/services.php web services, lang strings, classes/ PSR-4 autoloading, lib.php hooks, settings.php, privacy provider, and Moodle coding standards.

# Moodle Plugin Development

## Overview

Moodle plugins follow strict frankenstyle naming and a fixed file layout. Every plugin lives under a type-specific directory (`local/`, `mod/`, `blocks/`, `course/format/`, `theme/`, `auth/`, `enrol/`, `report/`, `question/type/`, `filter/`, `repository/`, etc.) and is identified by `<type>_<name>` (e.g., `local_school`, `mod_quiz`, `format_schoolgram`).

**Core principle:** Moodle code must declare `defined('MOODLE_INTERNAL') || die();` at top of every PHP file (except classes under `classes/` autoloaded via PSR-4), use `$DB` for all DB access, use `get_string()` for user-facing text, and bump `version.php` for any DB or capability change.

## When to Use

- Creating new plugin under `local/`, `mod/`, `blocks/`, `course/format/`, `theme/`, etc.
- Adding/modifying DB tables → `db/install.xml` + `db/upgrade.php`
- Adding capabilities → `db/access.php`
- Adding web services / external functions → `db/services.php` + `classes/external/`
- Adding scheduled tasks → `db/tasks.php` + `classes/task/`
- Adding events / observers → `db/events.php` + `classes/event/`
- Adding admin settings page → `settings.php`
- Translating strings → `lang/<lang>/<component>.php`
- Reviewing PR for Moodle coding-style compliance
- Bumping `version.php` after schema/capability change

**Skip when:** working purely on frontend AMD modules without backend changes, or non-Moodle PHP code.

## Plugin Skeleton

Minimum files for a `local_<name>` plugin:

```
local/<name>/
  version.php                    # required: component, version, requires, maturity
  lang/en/local_<name>.php       # required: 'pluginname' string
  lib.php                        # optional: hooks (extend_navigation, pluginfile, etc.)
  settings.php                   # optional: admin settings page
  db/
    install.xml                  # DB schema (edit via /admin/tool/xmldb/)
    upgrade.php                  # versioned upgrade steps
    access.php                   # capabilities
    services.php                 # web service definitions
    tasks.php                    # scheduled tasks
    events.php                   # event observers
    caches.php                   # cache definitions
  classes/                       # PSR-4: \local_<name>\foo\bar -> classes/foo/bar.php
    external/                    # external (web service) functions
    task/                        # scheduled task classes
    event/                       # custom events
    privacy/provider.php         # GDPR provider (REQUIRED)
  templates/                     # Mustache templates
  amd/src/                       # ES modules (built via grunt -> amd/build/)
  tests/                         # PHPUnit + Behat
```

## version.php Template

```php
<?php
defined('MOODLE_INTERNAL') || die();

$plugin->component = 'local_example';      // frankenstyle, must match dir
$plugin->version   = 2026042500;           // YYYYMMDDXX, bump on any db/capability change
$plugin->requires  = 2024100700;           // min Moodle version (4.5 LTS); use 2025041400 for 5.0+, 2025100600 for 5.1+, 2026042000 for 5.2+
$plugin->release   = '1.0.0';
$plugin->maturity  = MATURITY_STABLE;      // ALPHA | BETA | RC | STABLE
$plugin->dependencies = ['mod_quiz' => 2024100700];  // optional
```

## db/install.xml + upgrade.php

- Edit `install.xml` via Moodle XMLDB editor (`Site admin -> Development -> XMLDB editor`) — never hand-edit.
- Every schema change requires:
  1. Bump `$plugin->version` in `version.php`
  2. Add upgrade step in `db/upgrade.php` keyed on old version:

```php
function xmldb_local_example_upgrade($oldversion) {
    global $DB;
    $dbman = $DB->get_manager();

    if ($oldversion < 2026042500) {
        $table = new xmldb_table('local_example_items');
        $field = new xmldb_field('status', XMLDB_TYPE_INTEGER, '4', null,
            XMLDB_NOTNULL, null, '0', 'name');
        if (!$dbman->field_exists($table, $field)) {
            $dbman->add_field($table, $field);
        }
        upgrade_plugin_savepoint(true, 2026042500, 'local', 'example');
    }
    return true;
}
```

## db/access.php Capabilities

```php
$capabilities = [
    'local/example:view' => [
        'captype'      => 'read',
        'contextlevel' => CONTEXT_SYSTEM,
        'archetypes'   => [
            'user'           => CAP_ALLOW,
            'editingteacher' => CAP_ALLOW,
        ],
    ],
];
```

Runtime check: `require_capability('local/example:view', $context);` or `has_capability(...)`.

## db/services.php (Web Services / AJAX)

```php
$functions = [
    'local_example_get_items' => [
        'classname'    => 'local_example\external\get_items',
        'methodname'   => 'execute',
        'description'  => 'Return items',
        'type'         => 'read',
        'ajax'         => true,
        'capabilities' => 'local/example:view',
    ],
];
```

External class extends `\core_external\external_api` (Moodle 4.2+; older = `external_api`) and defines `execute_parameters()`, `execute()`, `execute_returns()`.

## Lang Strings

`lang/en/local_example.php`:

```php
$string['pluginname']    = 'Example';
$string['example:view']  = 'View example';        // capability strings: <plugin>:<cap>
$string['greeting']      = 'Hello, {$a->name}';   // placeholders
```

Use: `get_string('greeting', 'local_example', ['name' => $user->firstname]);`

## DB Access — Always `$DB`

```php
global $DB;
$DB->get_record('local_example_items', ['id' => $id], '*', MUST_EXIST);
$DB->get_records_sql('SELECT * FROM {local_example_items} WHERE status = ?', [1]);
$DB->insert_record('local_example_items', $obj);
$DB->update_record('local_example_items', $obj);
$DB->delete_records('local_example_items', ['id' => $id]);
```

Never `mysqli_*` / `PDO`. Always use `{tablename}` placeholder (Moodle prefixes). Always bind params, never concatenate.

## Hooks via lib.php

Common Moodle callbacks (function name = `<component>_<hookname>`):

- `local_example_extend_navigation(global_navigation $nav)` — add nav nodes
- `local_example_before_http_headers()` — runs before headers
- `local_example_extend_settings_navigation($settingsnav, $context)`
- `local_example_pluginfile($course, $cm, $context, $filearea, $args, $forcedl, $options)` — serve file area

Moodle 4.4+: prefer the new hooks API (`\core\hook\manager`) over magic callbacks where available.

## Output — Renderers + Templates

- HTML via `$OUTPUT->render_from_template('local_example/foo', $data)` (Mustache: `templates/foo.mustache`)
- Custom renderer: `classes/output/renderer.php` extends `plugin_renderer_base`
- Never `echo` raw HTML in business logic; always go through renderer or template

## Privacy (GDPR) — Required

Every plugin must declare privacy. Minimum (no user data stored):

```php
// classes/privacy/provider.php
namespace local_example\privacy;
defined('MOODLE_INTERNAL') || die();
class provider implements \core_privacy\local\metadata\null_provider {
    public static function get_reason(): string {
        return 'privacy:metadata';
    }
}
```

If plugin stores user data, implement `\core_privacy\local\request\plugin\provider` and define `get_metadata`, `export_user_data`, `delete_data_for_user_in_context`, `delete_data_for_users`, `get_contexts_for_userid`, `get_users_in_context`.

## Quick Reference

| Task | File | Bump version? |
|------|------|---------------|
| Add DB table/field | `db/install.xml` + `db/upgrade.php` | Yes |
| Add capability | `db/access.php` + lang string | Yes |
| Add web service fn | `db/services.php` + `classes/external/` | Yes |
| Add scheduled task | `db/tasks.php` + `classes/task/` | Yes |
| Add event observer | `db/events.php` | Yes |
| Add cache definition | `db/caches.php` | Yes |
| Add string | `lang/en/<component>.php` | No |
| Add settings | `settings.php` | No |
| Add template | `templates/*.mustache` | No |
| Add renderer | `classes/output/renderer.php` | No |

## Coding Standards

- 4-space indent, no tabs
- Opening `<?php` on line 1, no closing `?>` at end of pure PHP files
- `defined('MOODLE_INTERNAL') || die();` immediately after license block (skip in `classes/` PSR-4 files)
- snake_case for functions/vars, PascalCase for classes
- Run `vendor/bin/phpcs --standard=moodle <path>` before commit (`local_codechecker` plugin or `moodle-cs` ruleset)
- All user-facing strings via `get_string()`, never hard-coded English
- GPL-3.0-or-later license header on every PHP file

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Hand-editing `install.xml` | Use XMLDB editor at `/admin/tool/xmldb/` |
| Forgetting to bump `version.php` after schema change | Bump + add `upgrade.php` step + `upgrade_plugin_savepoint` |
| Using raw SQL with `{}` quoting wrong | Use `{tablename}` and `?` / named params, never string concat |
| `MOODLE_INTERNAL` check inside `classes/` PSR-4 file | Remove — autoloaded files don't need it |
| Storing user data without privacy provider | Implement `\core_privacy\local\request\plugin\provider` |
| Hard-coded English strings in PHP/Mustache | Move to `lang/en/<component>.php` + `get_string` / `{{#str}}` |
| Forgetting `require_capability()` on entry points | Always `require_login()` + capability check early |
| Not purging caches after `version.php` bump | `php admin/cli/upgrade.php` or Site admin -> Purge caches |
| Direct `$_GET`/`$_POST` access | Use `required_param()` / `optional_param()` with type |
| Missing `sesskey()` check on state-changing requests | Call `require_sesskey()` on POST handlers |

## Plugin Type Cheatsheet

| Type | Dir | Frankenstyle | Extra required files |
|------|-----|--------------|----------------------|
| Local | `local/<name>` | `local_<name>` | none beyond skeleton |
| Activity module | `mod/<name>` | `mod_<name>` | `mod_form.php`, `view.php`, `lib.php` w/ `<name>_add_instance` etc. |
| Block | `blocks/<name>` | `block_<name>` | `block_<name>.php` extends `block_base` |
| Course format | `course/format/<name>` | `format_<name>` | `format.php`, `lib.php` extends `core_courseformat\base` |
| Theme | `theme/<name>` | `theme_<name>` | `config.php`, `scss/`, `layout/` |
| Auth | `auth/<name>` | `auth_<name>` | `auth.php` extends `auth_plugin_base` |
| Enrol | `enrol/<name>` | `enrol_<name>` | `lib.php` extends `enrol_plugin` |
| Question type | `question/type/<name>` | `qtype_<name>` | `questiontype.php`, `question.php`, `renderer.php` |
| Filter | `filter/<name>` | `filter_<name>` | `filter.php` extends `moodle_text_filter` |
| Repository | `repository/<name>` | `repository_<name>` | `lib.php` extends `repository` |

## Security Checklist

- `require_login()` (and `require_capability()`) at top of every entry script
- `require_sesskey()` on every state-changing POST
- `required_param($name, PARAM_INT)` / `optional_param(...)` — never raw `$_REQUEST`
- Use `$DB->...` with placeholders — no SQL concat
- Escape output: `s()`, `format_string()`, `format_text()`
- File serving via `pluginfile.php` + `<component>_pluginfile()` callback, never direct path

## CLI Helpers

```bash
php admin/cli/upgrade.php --non-interactive    # apply pending upgrades
php admin/cli/purge_caches.php                  # clear all caches
php admin/tool/behat/cli/init.php               # init behat tests
vendor/bin/phpunit --testsuite local_example_testsuite
vendor/bin/phpcs --standard=moodle local/example
```

## Testing

- PHPUnit: `tests/<thing>_test.php` extending `advanced_testcase`, use `$this->resetAfterTest()`, generators via `self::getDataGenerator()->get_plugin_generator('local_example')`
- Behat: `tests/behat/*.feature` with `@local_example` tag, step definitions in `tests/behat/behat_local_example.php`

## References

- Moodle Dev Docs: https://moodledev.io
- Plugin types: https://moodledev.io/docs/apis/plugintypes
- Coding style: https://moodledev.io/general/development/policies/codingstyle
- XMLDB: https://moodledev.io/docs/apis/core/dml/xmldb
- Privacy API: https://moodledev.io/docs/apis/subsystems/privacy
- Hooks API (4.4+): https://moodledev.io/docs/apis/core/hooks


---

### moodle-privacy-gdpr

> Use when implementing or reviewing the Moodle privacy provider (GDPR) — null_provider vs request\plugin\provider, get_metadata, export_user_data, delete_data_for_user_in_context, delete_data_for_users, get_contexts_for_userid, get_users_in_context, subsystem links, and core_userlist_provider.

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


---

### moodle-security-audit

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


---

### moodle-theme-development

> Use when developing Moodle themes — Boost child themes, theme/yourtheme/config.php, SCSS pre/post hooks, layouts, Mustache template overrides, theme settings, $OUTPUT renderer overrides, and theme designer mode.

# Moodle Theme Development

## Overview

Moodle themes live under `theme/<name>/`. Almost all custom themes inherit from **Boost** (the bundled Bootstrap 5–based theme since 4.0). Override SCSS, layouts, and templates rather than building from scratch.

## When to Use

- Branding a Moodle install (logo, colors, fonts)
- Adding theme-level layout overrides
- Overriding a core Mustache template
- Adding theme settings (admin can configure)
- Per-tenant theming via category themes

**Skip when:** changing plugin UI — modify the plugin's own templates/SCSS.

## Theme skeleton

```
theme/yourtheme/
  config.php                    # required: theme manifest
  version.php                   # required: component, version, requires
  lib.php                       # SCSS hooks, post-process callbacks
  settings.php                  # admin settings
  lang/en/theme_yourtheme.php   # required: pluginname
  scss/
    pre.scss                    # injected BEFORE Boost SCSS (variables)
    post.scss                   # injected AFTER Boost SCSS (overrides)
    preset/                     # full preset alternatives
  layout/
    columns2.php                # override Boost's two-column layout
    drawers.php                 # 4.0+ default layout
    columns1.php
    secure.php
    embedded.php
    login.php
    maintenance.php
  templates/                    # override core Mustache (mirror path)
    core/
      navbar.mustache
  classes/
    output/
      core_renderer.php         # extend Boost's core_renderer
  pix/
    favicon.ico
    logo.png
```

## config.php

```php
<?php
defined('MOODLE_INTERNAL') || die();

$THEME->name             = 'yourtheme';
$THEME->parents          = ['boost'];                           // inherit
$THEME->sheets           = [];                                  // CSS files (SCSS preferred)
$THEME->editor_sheets    = [];
$THEME->scss             = function($theme) {
    return theme_yourtheme_get_main_scss_content($theme);       // see lib.php
};
$THEME->layouts          = [
    // override only the layouts you change; rest inherit from Boost
    'frontpage' => [
        'file' => 'columns2.php',
        'regions' => ['side-pre'],
        'defaultregion' => 'side-pre',
    ],
];
$THEME->enable_dock      = false;
$THEME->yuicssmodules    = [];
$THEME->rendererfactory  = 'theme_overridden_renderer_factory';
$THEME->prescsscallback  = 'theme_yourtheme_get_pre_scss';
$THEME->extrascsscallback = 'theme_yourtheme_get_extra_scss';
$THEME->iconsystem       = \core\output\icon_system::FONTAWESOME;
$THEME->haseditswitch    = true;
$THEME->usescourseindex  = true;
$THEME->precompiledcsscallback = 'theme_yourtheme_get_precompiled_css';
$THEME->addblockposition = BLOCK_ADDBLOCK_POSITION_FLATNAV;
```

## lib.php — SCSS pipeline

```php
<?php
defined('MOODLE_INTERNAL') || die();

function theme_yourtheme_get_main_scss_content($theme): string {
    global $CFG;
    $boost = file_get_contents($CFG->dirroot . '/theme/boost/scss/preset/default.scss');
    $custom = file_get_contents(__DIR__ . '/scss/post.scss');
    return $boost . "\n" . $custom;
}

function theme_yourtheme_get_pre_scss($theme): string {
    $scss = '';
    $configurable = [
        'brandcolor' => ['primary'],
    ];
    foreach ($configurable as $configkey => $vars) {
        $value = $theme->settings->{$configkey} ?? null;
        if (empty($value)) {
            continue;
        }
        foreach ($vars as $var) {
            $scss .= '$' . $var . ': ' . $value . ";\n";
        }
    }
    $scss .= file_get_contents(__DIR__ . '/scss/pre.scss');
    return $scss;
}

function theme_yourtheme_get_extra_scss($theme): string {
    return $theme->settings->scss ?? '';
}
```

`pre.scss` runs before Boost — defines variables (`$primary`, `$body-bg`, etc.).
`post.scss` runs after — overrides classes that already exist.

## Theme settings

`settings.php`:

```php
<?php
defined('MOODLE_INTERNAL') || die();

if ($ADMIN->fulltree) {
    $settings = new theme_boost_admin_settingspage_tabs(
        'themesettingyourtheme',
        get_string('configtitle', 'theme_yourtheme')
    );

    // General tab
    $page = new admin_settingpage('theme_yourtheme_general',
        get_string('generalsettings', 'theme_boost'));

    // Color
    $page->add(new admin_setting_configcolourpicker(
        'theme_yourtheme/brandcolor',
        get_string('brandcolor', 'theme_yourtheme'),
        get_string('brandcolor_desc', 'theme_yourtheme'),
        '#0f6fc5'
    ));

    // Logo
    $page->add(new admin_setting_configstoredfile(
        'theme_yourtheme/logo',
        get_string('logo', 'theme_yourtheme'),
        get_string('logo_desc', 'theme_yourtheme'),
        'logo', 0,
        ['maxfiles' => 1, 'accepted_types' => ['.png', '.svg']]
    ));

    // Raw SCSS
    $page->add(new admin_setting_scsscode(
        'theme_yourtheme/scss',
        get_string('rawscss', 'theme_boost'),
        get_string('rawscss_desc', 'theme_boost'),
        '',
        PARAM_RAW
    ));

    $settings->add($page);
}
```

## Layout files

`layout/columns2.php` controls page structure:

```php
<?php
require_once($CFG->dirroot . '/theme/boost/layout/common.php');

$secondarynavigation = false;
$overflow = '';
if ($PAGE->has_secondary_navigation()) {
    $secondarynavigation = true;
    // ...
}

$templatecontext = [
    'sitename' => format_string($SITE->fullname),
    'output' => $OUTPUT,
    'sidepreblocks' => $blockshtml,
    'hasblocks' => strpos($blockshtml, 'data-block=') !== false,
    'bodyattributes' => $bodyattributes,
    'secondarynavigation' => $secondarynavigation,
];

echo $OUTPUT->render_from_template('theme_yourtheme/columns2', $templatecontext);
```

Mustache layout at `templates/columns2.mustache` — copy from Boost and modify.

## Renderer override

`classes/output/core_renderer.php`:

```php
<?php
namespace theme_yourtheme\output;
defined('MOODLE_INTERNAL') || die();

class core_renderer extends \theme_boost\output\core_renderer {
    public function favicon(): \moodle_url {
        $logo = $this->page->theme->setting_file_url('favicon', 'favicon');
        return $logo ? new \moodle_url($logo) : parent::favicon();
    }
}
```

Activated by `$THEME->rendererfactory = 'theme_overridden_renderer_factory';` in `config.php`.

## Template override

To override `core/navbar.mustache`, copy to `theme/yourtheme/templates/core/navbar.mustache`. Moodle resolves theme templates first.

## Theme designer mode (DEV ONLY)

```php
// config.php
$CFG->themedesignermode = true;
```

Disables CSS caching — every page rebuilds SCSS. **Never** in production — kills performance.

After changing SCSS in production: Site admin > Development > Purge caches > "Theme caches".

## SCSS variables (Boost defaults)

```scss
// pre.scss — override before Boost imports
$primary:   #0f6fc5;
$secondary: #6c757d;
$success:   #5cb85c;
$danger:    #d9534f;
$warning:   #f0ad4e;
$info:      #5bc0de;
$body-bg:   #fff;
$body-color: #1d2125;
$font-family-sans-serif: 'Inter', sans-serif;
$navbar-height: 60px;
```

Full list: `theme/boost/scss/moodle/_variables.scss`.

## Per-category / per-cohort theme

Site admin > Appearance > Themes > Theme settings:
- Allow theme changes per-course/category
- `$THEME->allowedscss` for tenant-controlled SCSS

Programmatic:

```php
$category = $DB->get_record('course_categories', ['id' => $catid]);
$category->theme = 'yourtheme';
$DB->update_record('course_categories', $category);
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Editing Boost directly | Create child theme inheriting Boost |
| Theme designer mode in production | Disable, purge theme caches |
| Forgetting `theme_overridden_renderer_factory` | Renderer overrides won't load |
| Heavy logic in `lib.php` SCSS callback | Cache via `precompiledcsscallback` |
| Hardcoded colors in templates | Use CSS variables / SCSS vars from pre.scss |
| Bumping `version.php` not enough | Also purge caches: `php admin/cli/purge_caches.php` |
| Missing FontAwesome icon system | `$THEME->iconsystem = \core\output\icon_system::FONTAWESOME` |
| Layout file echoes raw HTML | Render via Mustache for theme overridability |
| SCSS contrast ratios fail AA | See `moodle-accessibility` skill |
| Logo / favicon as raw URL | Use `admin_setting_configstoredfile` + `setting_file_url` |

## Build + cache

```bash
# After SCSS changes (production)
php admin/cli/purge_caches.php

# Theme designer mode (dev) — auto-rebuild
# config.php: $CFG->themedesignermode = true;

# Build SCSS to CSS once for inspection
php admin/cli/build_theme_css.php --themes=yourtheme
```

## References

- Themes: https://moodledev.io/docs/apis/plugintypes/theme
- Boost theme: https://moodledev.io/docs/apis/plugintypes/theme/boost
- SCSS: https://moodledev.io/docs/apis/plugintypes/theme#scss
- Layouts: https://moodledev.io/docs/apis/plugintypes/theme/layouts
- Theme settings: https://moodledev.io/docs/apis/plugintypes/theme/settings
- Override templates: https://moodledev.io/docs/apis/subsystems/output/templates#overriding-templates


---

### moodle-upgrade-migration

> Use when upgrading a Moodle plugin across versions, fixing deprecated API usage, or migrating to Moodle 4.x/5.x (incl. 5.1/5.2) conventions — print_error, add_to_log, formslib changes, external_api namespace, Hooks API, /public doc-root, Routing Engine, PSR-4 migration, PHP 8.1–8.4 upgrades, and required upgrade.txt notes.

# Moodle Upgrade & Migration

## Overview

Moodle deprecates aggressively but rarely removes. Code from Moodle 2.x often still runs in 4.5 — but uses APIs that emit warnings, fail PHP 8 strict checks, or block plugin directory acceptance. This skill catalogs the migration path from each generation.

## When to Use

- Upgrading a plugin to support a newer Moodle version
- Resolving deprecation warnings
- Migrating to PHP 8.1 / 8.2 / 8.3 / 8.4
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
- Typed class constants supported

### → PHP 8.4

- Implicit nullable params now hard-deprecated: `function f(string $x = null)` → `function f(?string $x = null)`
- Optional param before required param deprecated — reorder so optionals come last
- `E_STRICT` constant removed (was already a no-op)
- `trigger_error(..., E_USER_ERROR)` deprecated — throw an exception instead
- CSV functions: `fputcsv()` / `fgetcsv()` / `str_getcsv()` default `$escape` deprecated — pass `''` explicitly to opt out of legacy escape
- `xml_set_*_handler` string-callable form deprecated — pass `[$obj, 'method']` or first-class callable
- `mysqli_kill()`, `mysqli_refresh()`, `mysqli_ping()` deprecated — irrelevant to Moodle ($DB layer), but flag in custom code
- `DatePeriod` ISO8601 string constructor deprecated → `DatePeriod::createFromISO8601String()`
- `mb_trim()`, `mb_ltrim()`, `mb_rtrim()` added — prefer over manual regex trimming for multibyte

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

### 5.0 (2025-04)

- PHP 8.2 minimum
- Bootstrap 5 fully replaces Bootstrap 4 utility classes
  - `.sr-only` → `.visually-hidden`
  - `.float-left` → `.float-start`
  - `.ml-*` → `.ms-*`
  - `data-toggle` → `data-bs-toggle`
- Some 4.x deprecations finalize
- New AI subsystem (`\core_ai`)

### 5.1 (2025-10-06)

- **PHP 8.2 min, 8.3 & 8.4 supported.** Sodium ext required. 64-bit only. `max_input_vars` ≥ 5000.
- **`/public` document root.** Web server must point at `<moodleroot>/public`. Plugins still live above (`/local/...`, `/mod/...`) — installer relocates; manual moves needed for in-place upgrades.
- **Routing Engine** (optional, BC-safe) — new request dispatcher + cleaner URLs.
- Deprecations:
  - `file_encode_url()` deprecated → use `moodle_url::make_pluginfile_url()`
  - Device-related theme functions final-deprecated
  - Quiz callback classes/functions deprecated (see `mod/quiz/UPGRADING.md`)
  - `course/changenumsections.php` page removed
  - Course "max sections" setting removed
- DB prefix max length now 10 chars.
- Always check per-component `UPGRADING.md` (5.1 replaces `upgrade.txt` for API change notes).

### 5.2 (2026-04-20)

- **PHP 8.3 min, 8.4 supported.**
- **Upgrade path:** must come from 4.4 or later. Older → upgrade through 4.4/5.0/5.1 first.
- **Oracle DB removed.** Minimums bumped: PostgreSQL 16, MySQL 8.4, MariaDB 10.11, SQL Server 2019.
- **React in core** — base library available via importmaps; new UI code may use React components.
- Composer support for third-party library installation in plugins.
- OpenTelemetry integration.
- Final deprecations:
  - `core/modal_factory`, `core/modal_registry` (AMD) — use `core/modal` directly
  - Pre-PHP 7 style constructors removed (no method named after class)
  - Everything in `lib/deprecatedlib.php` from ≤ 4.4 removed
- New/expanded web services: `site_info`, `mobile_config`, `choice_results`.

Always check `/public/lib/upgrade.txt` (path changed in 5.1) and per-component `UPGRADING.md` for the target version.

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


---

### moodle-web-services

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


---

## Agents (specialized review/scaffolding)

### moodle-reviewer

> Use this agent for a deep, Moodle-specific code review of a plugin or PR diff. Checks coding standards, security, privacy, lang strings, version bumps, deprecations, and tests. Returns a structured report.

You are a senior Moodle plugin reviewer. You have deep knowledge of:
- Moodle coding standards (`moodle-cs`, `phpcs --standard=moodle`)
- Frankenstyle conventions and plugin types
- Security checklist (capabilities, sesskey, input validation, output escaping, SQL placeholders, file API)
- Privacy / GDPR provider correctness
- XMLDB and `db/upgrade.php` conventions
- Web services (`db/services.php` + `classes/external/`)
- AMD JavaScript + Mustache templates
- Moodle 4.4+ Hooks API and deprecations
- PHPUnit + Behat patterns
- Accessibility (WCAG 2.1 AA)

## Your job

When invoked, you review the requested plugin or diff and produce a structured report.

## Process

1. **Scope** — confirm what to review (whole plugin / specific files / git diff). If unclear, ask once, then proceed.
2. **Inventory** — `Glob` the plugin to map structure. Identify plugin type from frankenstyle.
3. **Run checks** in this order, accumulating findings:
   1. **Coding standards** — `phpcs --standard=moodle` if available
   2. **Frankenstyle / structure** — required files for the plugin type present?
   3. **Security** — apply the `moodle-security-audit` checklist
   4. **Privacy** — apply the `moodle-privacy-gdpr` checklist (column ↔ provider mapping)
   5. **DB / XMLDB** — every schema change has a `version.php` bump + `upgrade.php` step + `upgrade_plugin_savepoint`
   6. **Lang strings** — no hard-coded English in user-facing PHP/Mustache/JS
   7. **Web services** — `validate_parameters` + `validate_context` + `require_capability` order, `clean_returnvalue` in tests
   8. **Deprecations** — `print_error`, `add_to_log`, `external_api` (bare), magic callbacks where Hooks API exists
   9. **Tests** — PHPUnit `final class`, `@covers`, `resetAfterTest`; Behat tags + data generators
   10. **Accessibility** — Mustache uses semantic HTML; forms have labels; modals use `core/modal`
4. **Produce report** in this format:

```markdown
# Review: <plugin>

## Summary
- Files reviewed: N
- Critical: N | High: N | Medium: N | Low: N
- Recommendation: APPROVE / REQUEST CHANGES / BLOCK

## Critical
- file.php:42 — <issue> — FIX: <action>

## High
- ...

## Medium
- ...

## Low / Style
- ...

## Positive notes
- (things done well — keep doing them)

## Suggested next steps
1. ...
2. ...
```

## Rules

- Be specific: `file:line` references, exact API names.
- Don't speculate — read the file before claiming an issue.
- Distinguish **incorrect** from **subjective**. Mark subjective items "Style".
- For each Critical/High finding, give a fix that compiles.
- Never modify files. You only report.
- If asked to review a git diff, respect the diff scope — don't audit untouched files.
- If `phpcs` isn't available, note it and run all other checks anyway.


---

### moodle-scaffolder

> Use this agent to generate a complete Moodle plugin skeleton from a brief description. Produces all required files for the plugin type with correct frankenstyle, license headers, version, privacy provider, capabilities, lang strings, and a smoke test.

You are a Moodle plugin scaffolding specialist. You generate complete, idiomatic plugin skeletons that pass `phpcs --standard=moodle` out of the box.

## Inputs

You will be given (or asked to obtain):
- **Plugin type** — `local`, `mod`, `block`, `format`, `theme`, `auth`, `enrol`, `report`, `qtype`, `filter`, `repository`
- **Plugin name** — lowercase, no underscore in name part
- **Target Moodle version** — `requires` field
- **What it does** — short description; informs feature surface
- **User data?** — drives privacy provider type
- **Moodle root path** — where to write files

If any are missing, ask once at the start, then proceed.

## Always include

For every plugin, regardless of type:

1. `version.php` with:
   - `$plugin->component` = frankenstyle (`<type>_<name>`)
   - `$plugin->version` = `YYYYMMDD00` (today)
   - `$plugin->requires` = user-supplied
   - `$plugin->maturity = MATURITY_ALPHA;` (caller can bump later)
   - `$plugin->release = '0.1.0';`

2. `lang/en/<component>.php` with at least:
   - `pluginname`
   - `privacy:metadata` (or per-table strings if full provider)

3. `classes/privacy/provider.php`:
   - `null_provider` if "stores user data?" = no
   - Full provider scaffold (per the `moodle-privacy-gdpr` skill) if yes

4. `db/access.php` if the plugin will have any access-controlled action (default: yes, with a single `<plugin>:view` capability)

5. `README.md` with install instructions

6. `CHANGELOG.md` with `## [0.1.0]` initial entry

7. GPL-3.0-or-later license header on every PHP file

8. `defined('MOODLE_INTERNAL') || die();` after license (skip in `classes/` PSR-4 files)

## Type-specific extras

### local
- Optional `lib.php`, `settings.php`

### mod (activity module)
- `mod_form.php` extending `moodleform_mod`
- `view.php`
- `lib.php` with `<name>_supports`, `<name>_add_instance`, `<name>_update_instance`, `<name>_delete_instance`
- `db/install.xml` with the required `<name>` table (id, course, name, intro, introformat, timecreated, timemodified)

### block
- `block_<name>.php` extending `block_base` with `init()`, `get_content()`
- `db/install.xml` empty (or with config table)

### format (course format)
- `format.php`
- `lib.php` with class extending `\core_courseformat\base`
- `classes/output/courseformat/content.php` (4.0+)

### theme
- `config.php` with `$THEME->parents = ['boost']`
- `lib.php` with `theme_<name>_get_main_scss_content`
- `scss/pre.scss`, `scss/post.scss`
- `settings.php` with at least one configurable color

### auth
- `auth.php` extending `auth_plugin_base`

### enrol
- `lib.php` extending `enrol_plugin`

### report
- `index.php`

### qtype (question type)
- `questiontype.php`
- `question.php`
- `renderer.php`
- `edit_<name>_form.php`

### filter
- `filter.php` extending `moodle_text_filter`

### repository
- `lib.php` extending `repository`

## Plus a smoke test

`tests/<name>_test.php`:

```php
<?php
namespace <component>;
defined('MOODLE_INTERNAL') || die();

/**
 * @group <component>
 * @covers \<component>\anything_at_all
 */
final class smoke_test extends \advanced_testcase {
    public function test_plugin_loads(): void {
        $this->resetAfterTest();
        $this->assertTrue(class_exists(\<component>\privacy\provider::class));
    }
}
```

## After writing

1. Print a tree of created files.
2. Print the next-step commands:
   ```bash
   php admin/cli/upgrade.php --non-interactive
   php admin/cli/purge_caches.php
   vendor/bin/phpcs --standard=moodle <typedir>/<name>
   php admin/tool/phpunit/cli/init.php
   vendor/bin/phpunit <typedir>/<name>/tests
   ```
3. Highlight TODO markers placed in stubs the user must fill in (form fields, capability arch types, etc.).

## Rules

- Never overwrite existing files without explicit confirmation.
- Use `Write` for new files only. If a file exists, ask.
- Code must parse — write valid PHP, valid XMLDB.
- Reference the `moodle-plugin-development` skill for layout details and the `moodle-privacy-gdpr` skill for the provider.
- Output is generated, not interactive — produce a complete tree in one pass after collecting inputs.


---

## Commands (one-shot workflows)

### /moodle-bump-version

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


---

### /moodle-capability-audit

> Audit a plugin's capabilities — verifies db/access.php declarations match runtime require_capability/has_capability calls, checks risk bitmasks, default archetypes, and lang strings.

Audit capability declarations vs. usage for the plugin at the given path.

User's input: <args>

## Procedure

1. Resolve plugin path (default: cwd). Read `version.php` to get the frankenstyle `$plugin->component`.
2. Activate `moodle-security-audit` and `moodle-plugin-development` skills.
3. Parse `db/access.php` — extract declared capabilities into a set.
4. Grep the plugin for runtime capability use:
   - `require_capability\(['"]([^'"]+)['"]`
   - `has_capability\(['"]([^'"]+)['"]`
   - `require_all_capabilities\(\[(.*?)\]`
   - `require_any_capability\(\[(.*?)\]`
   - In `db/services.php`: `'capabilities' => '...'`
   - In external function `execute_parameters` files: same as above
5. Cross-reference:
   - **Used but not declared** -> ERROR (call will always deny).
   - **Declared but never used** -> WARNING (dead capability, or used via JS/dynamic — flag for human check).
   - **Declared with risk bitmask but riskBitmask=0** for caps that grant write/admin -> WARNING.
6. For each declared capability, verify:
   - `captype` is one of `read`/`write`.
   - `contextlevel` is a valid `CONTEXT_*` constant.
   - `archetypes` includes a sensible default (most caps should have `'manager' => CAP_ALLOW` at minimum).
   - `riskbitmask` uses correct combination: `RISK_SPAM | RISK_XSS | RISK_PERSONAL | RISK_CONFIG | RISK_DATALOSS | RISK_MANAGETRUST`.
   - A lang string exists in `lang/en/<component>.php` as `$string['<component>:<capname-suffix>'] = '...'` AND a `<capname-suffix>_help` if non-trivial.
7. Check for `clone` or `extends` of risky caps (e.g., cloning `moodle/site:config`) — flag.
8. If any cap uses `CONTEXT_SYSTEM` and grants write/admin, ensure `RISK_CONFIG` or `RISK_DATALOSS` is set.

## Output

```markdown
# Capability audit: <component>

## Summary
- Declared: N | Used: N | Orphan declarations: N | Undeclared usages: N
- Risk-bitmask issues: N | Missing lang strings: N

## Errors
- foo.php:88 — `has_capability('<component>:doit', ...)` but `<component>:doit` not in db/access.php

## Warnings
- db/access.php:42 — `<component>:legacy` declared but no runtime usage (dead?)
- db/access.php:60 — `<component>:writeall` is write/CONTEXT_SYSTEM but no RISK_CONFIG flag

## Missing lang strings
- `<component>:doit` — add `$string['<component>:doit'] = '...';` to lang/en/<component>.php
- `<component>:doit_help` — add `_help` for non-trivial caps

## Suggested next steps
1. Add missing declarations to db/access.php, bump version.php
2. Remove dead caps or document why kept (e.g., used by sibling plugin)
3. Add risk bitmasks
4. Run `php admin/cli/upgrade.php` after version bump to apply changes
```

## Rules

- Never modify files — report only.
- Use `grep -rn` from `Bash`; don't rely on heuristics across files without verifying.
- If `db/access.php` doesn't exist, say so — the plugin declares no capabilities. Still scan for hardcoded `has_capability` strings.
- Capability strings can be built dynamically (`"$component:" . $action`) — flag these as "manual review needed".


---

### /moodle-codestyle

> Run phpcs with the Moodle coding standard and fix reported issues.

You will lint and fix Moodle coding-style issues.

User's input: <args>

If empty, ask for a path.

Steps:

1. Detect the linter:
   - Prefer `vendor/bin/phpcs` (project-local Composer)
   - Fall back to `phpcs` on PATH
   - If `local_codechecker` is installed, prefer its bundled standard

2. Run:
   ```bash
   phpcs --standard=moodle --report=summary <path>
   phpcs --standard=moodle --report=full <path>
   ```

3. If `phpcs` is not installed, instruct the user:
   ```bash
   composer require --dev moodlehq/moodle-cs
   # or as a Moodle plugin:
   # https://github.com/moodlehq/moodle-local_codechecker
   ```

4. Categorize findings:
   - **Auto-fixable** — run `phpcbf --standard=moodle <path>` (whitespace, missing newlines, brace style)
   - **Manual** — missing PHPDoc, naming, missing `MOODLE_INTERNAL`, missing license header, etc.

5. After auto-fix, re-run and address remaining issues:
   - **License header missing** — prepend GPL-3.0-or-later header (template from `moodle-plugin-development` skill)
   - **Missing `MOODLE_INTERNAL`** — add after license (skip if file is in `classes/` PSR-4)
   - **Missing PHPDoc on class/method** — generate doc with `@param`, `@return`, `@throws`
   - **Naming** — convert camelCase function names to snake_case (carefully — check call sites)
   - **Line length > 132** — wrap at logical breakpoints
   - **Indent** — convert tabs to 4 spaces

6. After all fixes, re-run `phpcs` and confirm zero issues.

7. Recommend hooking phpcs into CI:
   ```yaml
   - run: vendor/bin/phpcs --standard=moodle --report=full --extensions=php local/example
   ```

Reference the `moodle-plugin-development` skill for coding standard details.


---

### /moodle-mustache-lint

> Lint Mustache templates for accessibility, security, hard-coded strings, and Moodle template conventions.

Lint Mustache templates in the given path (default: `./templates` of current plugin).

User's input: <args>

## Procedure

1. Resolve target path. If `<args>` empty, glob `**/templates/**/*.mustache` under cwd.
2. Activate `moodle-accessibility` and `moodle-theme-development` skills for rule context.
3. For every `.mustache` file, check:

### Security
- No raw triple-stache `{{{ ... }}}` on user-controlled data unless the value is documented as pre-sanitized HTML (`{{{html}}}` from `format_text()` is OK; raw `{{{name}}}` of free-text input is NOT).
- No `<script>` blocks — JS belongs in `amd/src/` modules, loaded via `{{#js}}` block.
- No inline `onclick=` / `onload=` / `javascript:` URLs.

### Accessibility
- Every `<img>` has `alt=""` (decorative) or `alt="{{#str}}..."` (meaningful).
- Every interactive element is a `<button>` or `<a href>`, not `<div onclick>`.
- Form inputs have associated `<label for="...">` or `aria-label`.
- Buttons that only contain icons have `aria-label` or visually-hidden text.
- Heading order is not skipped (no `<h1>` then `<h4>`).
- Color is not the only signal (icons + text, not just red/green).

### Strings & i18n
- No hard-coded user-facing English. Use `{{#str}}identifier, component{{/str}}`.
- Detect: bare English words in text nodes, button labels, placeholders, titles.
- Aria labels likewise must use `{{#str}}`.

### Moodle conventions
- Template starts with a Mustache comment block documenting context variables:
  ```mustache
  {{!
      @template component/templatename

      Description.

      Context variables required for this template:
      * variable - description
  }}
  ```
- Use `{{#pix}}` for icons, not raw `<i class="fa-...">`.
- Use `{{#js}}` for JS init, not inline `<script>`.
- Use `core/modal` markup, not bootstrap-direct `<div class="modal">`.

### Output
Produce a markdown report:

```markdown
# Mustache lint: <path>

## Summary
- Files scanned: N
- Errors: N | Warnings: N | Info: N

## Errors (must fix)
- templates/foo.mustache:12 — raw {{{user_input}}} without sanitization context — use {{user_input}} or document why raw HTML is safe

## Warnings (should fix)
- templates/foo.mustache:34 — hard-coded "Submit" — use {{#str}}submit, core{{/str}}

## Info
- templates/foo.mustache — missing {{! @template ... }} header

## Suggested next steps
1. ...
```

## Rules

- Never modify files — report only.
- Be specific: `file:line` references.
- If the file is non-existent or empty, say so and stop.
- Distinguish definitely-broken (Errors) from style/convention (Warnings/Info).


---

### /moodle-new-plugin

> Scaffold a new Moodle plugin (asks for type + name).

You will scaffold a new Moodle plugin.

User's input: <args>

If `<args>` is empty or missing required values, ask the user:
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


---

### /moodle-privacy-audit

> Audit a Moodle plugin's privacy provider for completeness against its DB schema.

You will audit the privacy provider of a Moodle plugin.

User's input: <args>

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


---

### /moodle-security-review

> Run the Moodle security checklist on a file, directory, or entire plugin.

You will perform a Moodle-specific security review.

User's input: <args>

Activate the `moodle-security-audit` skill for context.

If `<args>` is empty, ask for a file or plugin path.

Audit each PHP file in scope against this checklist. Report findings as:

```
[FILE]:[LINE] [SEVERITY] [CATEGORY] — [issue]
                                         FIX: [actionable fix]
```

Severities: `CRITICAL` (exploitable now), `HIGH` (privilege escalation / data leak), `MEDIUM` (defense in depth), `LOW` (style / hardening).

## Checklist

For every entry script (file with `require('config.php')` or similar):
1. `require_login()` present and called early
2. `require_capability()` against the **object's** context (not arbitrary system context)
3. `require_sesskey()` on every state-changing request (POST or mutating GET)
4. All input via `required_param`/`optional_param` with appropriate `PARAM_*` type — flag any `$_GET`/`$_POST`/`$_REQUEST` usage

For every DB call:
5. Uses `$DB->...` — flag any `mysqli_*`, `PDO`, `mysql_*`
6. Placeholders (`?` / `:name`) — flag string concatenation in SQL
7. `LIKE` patterns use `$DB->sql_like()` + `sql_like_escape()`
8. `IN (...)` uses `$DB->get_in_or_equal()`

For every output:
9. User text rendered via `s()`, `format_string()`, `format_text()` — flag direct `echo $var`
10. `format_string`/`format_text` is called with a `context`
11. Mustache `{{{var}}}` raw output is justified (text already passed through `format_text`)

For file APIs:
12. `pluginfile.php` callback re-checks capability inside callback
13. Files are served via `\file_storage` + `send_stored_file`, never raw `$CFG->dataroot`
14. Uploads use `file_save_draft_area_files` with `maxfiles`, `maxbytes`, `accepted_types`

For HTTP / external:
15. Uses `\curl` wrapper, not raw `curl_exec()` / `file_get_contents($url)`
16. Open redirects: `redirect($next)` with `$next` from user input is validated against site host

For secrets:
17. No tokens / API keys committed in source — use `set_config`/`get_config`

For dangerous PHP:
18. No `eval()`, `create_function()`, `unserialize()` on user input
19. `print_error` is replaced with `throw new \moodle_exception()`

For sessions:
20. `\core\session\manager::write_close()` called early on AJAX endpoints that don't write session

After audit:
- Print summary: `N CRITICAL, N HIGH, N MEDIUM, N LOW`
- Offer to apply fixes one-by-one or as a single patch (ask before writing)
- For unresolved CRITICAL findings, recommend not deploying until fixed


---

### /moodle-string-check

> Find hard-coded English strings that should use get_string() / Mustache {{#str}}.

You will find untranslated user-facing strings in a Moodle plugin.

User's input: <args>

If empty, ask for a plugin path.

Steps:

1. Walk the plugin directory.
2. Read `lang/en/<component>.php` — list defined keys.
3. For each `.php`, `.mustache`, and `.js` file, find user-facing strings that are not loaded via `get_string`/`{{#str}}`/`core/str`:

   PHP heuristics:
   - String literals passed to:
     - `$mform->addElement(..., 'X', '<literal>')` — second arg = label
     - `new admin_setting_configtext(..., '<literal>', '<literal>')` — title + description
     - `new \html_table_cell('<literal>')`, `html_writer::tag('p', '<literal>')`
     - `notification::success('<literal>')`, `\core\notification::error('<literal>')`
     - `redirect($url, '<literal>')`
     - `throw new moodle_exception('<literal>')` — should be a string KEY, not a sentence
   - Direct `echo` of literals over 3 words

   Mustache heuristics:
   - Visible text not wrapped in `{{#str}}KEY, COMPONENT{{/str}}`
   - Aria-labels / titles with literal text

   JS heuristics:
   - String literals passed to `Notification.alert()`, `Toast.add()`, error messages thrown
   - Any UI-visible literal not loaded via `core/str` `get_string`/`get_strings`

4. Skip strings that are clearly identifiers (selectors, classes, route keys, lang keys themselves).

5. Output findings as:

```
[FILE]:[LINE] "<literal>"
   → propose key: <plugin>:<snake_case>
   → in lang/en/<component>.php:
       $string['<key>'] = '<literal>';
   → replacement:
       <PHP>: get_string('<key>', '<component>')
       <Mustache>: {{#str}}<key>, <component>{{/str}}
       <JS>: await getString('<key>', '<component>')
```

6. Optionally, propose adding `lang/en/<component>.php` keys in a single edit and substituting the literals.

Reference the `moodle-plugin-development` skill for lang string conventions.


---
