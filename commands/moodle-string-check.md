---
name: moodle-string-check
description: Find hard-coded English strings that should use get_string() / Mustache {{#str}}.
argument-hint: "[plugin path] — e.g. local/attendance"
---

You will find untranslated user-facing strings in a Moodle plugin.

User's input: $ARGUMENTS

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
