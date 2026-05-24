# /moodle-mustache-lint

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
