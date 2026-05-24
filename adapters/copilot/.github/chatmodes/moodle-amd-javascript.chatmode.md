---
description: Use when writing JavaScript for Moodle — AMD modules, ES6 source, grunt build, RequireJS loading, core/ajax + core/str + core/templates + core/modal + core/notification, Mustache template hydration, and AMD unit tests.
tools: ['codebase', 'search', 'editFiles', 'runCommands']
---
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
