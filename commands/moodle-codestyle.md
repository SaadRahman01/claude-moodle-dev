---
name: moodle-codestyle
description: Run phpcs with the Moodle coding standard and fix reported issues.
argument-hint: "[path] — e.g. local/attendance"
---

You will lint and fix Moodle coding-style issues.

User's input: $ARGUMENTS

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
