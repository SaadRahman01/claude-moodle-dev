---
name: moodle-accessibility
description: Use when ensuring Moodle plugin UI meets WCAG 2.1 AA — semantic HTML in Mustache, ARIA via core helpers, keyboard navigation, color contrast in SCSS, focus management in modals, screen reader testing, and Pa11y/axe automation.
---

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
