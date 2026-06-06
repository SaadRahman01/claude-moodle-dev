# Adapter Authoring Guide

How to add support for a new AI coding assistant.

## Background

Canonical sources live in `skills/`, `agents/`, `commands/`. These follow the [Claude Code plugin format](https://docs.anthropic.com/claude/docs/claude-code) — frontmatter (`name`, `description`) + markdown body.

Other assistants (Cursor, Copilot, Aider, Continue, …) consume different formats. `scripts/build-adapters.py` reads the canonical sources once and emits one tree per assistant under `adapters/<name>/`.

**Never hand-edit `adapters/`.** CI fails on drift. Always edit canonical sources, then run the generator.

## How the generator works

`scripts/build-adapters.py`:

1. Parses frontmatter via `parse(path)` → `(dict, body)`.
2. Walks `skills/`, `agents/`, `commands/` via `load_all()` → returns three lists.
3. Calls one `build_<assistant>()` function per target.
4. Writes output files under `adapters/<assistant>/`.

Each `build_*` function is independent. Add one to support a new assistant.

## Adding a new adapter — checklist

1. **Decide output layout** matching the target's expected paths. Examples:
   - Cursor: `.cursor/rules/<name>.mdc` with frontmatter
   - Copilot: `.github/chatmodes/<name>.chatmode.md`
   - Continue: `~/.continue/config.yaml` + `rules/<name>.md`
   - Some-new-tool: `.<tool>/system.md` + `.<tool>/prompts/<name>.md`

2. **Write a `build_<tool>(items)` function** in `scripts/build-adapters.py`:
   ```python
   def build_mytool(items):
       out_root = ADAPTERS / "mytool"
       out_root.mkdir(parents=True, exist_ok=True)
       # write files for each skill/agent/command
       for fm, body, _ in items["skills"]:
           (out_root / "skills" / f"{fm['name']}.md").write_text(
               f"# {fm['name']}\n\n{body}"
           )
   ```

3. **Register it** in `main()`:
   ```python
   build_mytool(items)
   ```

4. **Add an installer target** in `install.sh`:
   ```bash
   mytool)
     copy_tree "$ROOT/adapters/mytool" "$dest/.mytool"
     ;;
   ```

5. **Document** in `README.md` install section.

6. **Run `python3 scripts/build-adapters.py`** locally, commit `adapters/mytool/`.

7. **Verify CI** passes (`adapters/ in sync` check).

## Design rules

- **Verbatim body reuse.** Skills are written for Claude but read fine to humans. Don't rewrite — just wrap with target-specific headers.
- **Frontmatter mapping must be lossless.** If the target supports activation triggers, map `description` → that field. If not, prepend the description as the first line of the body.
- **One file per skill/command/agent** wherever the target supports it. Avoid mega-prompts unless the target only takes a single system prompt (then use the `generic` adapter pattern).
- **No external dependencies in the generator.** It must run on `python3` stdlib only.

## Testing

- `tests/run.sh` — checks adapters regenerate cleanly + match committed output.
- `python3 -m unittest tests.test_build_adapters` — unit tests for `parse()` and `load_all()`. Add cases for any new helpers.
- CI fails if `adapters/` differs from generator output → guarantees the committed tree is reproducible.

## Adding tests for a new adapter

When you add `build_mytool`, add an assertion to `tests/test_build_adapters.py`:

```python
def test_mytool_emits_skill_file(self):
    items = ba.load_all()
    ba.build_mytool(items)
    self.assertTrue((ROOT / "adapters/mytool/skills/moodle-plugin-development.md").exists())
```

## Existing adapters

| Adapter | Output | Activation model |
|---------|--------|------------------|
| `cursor` | `.cursor/rules/*.mdc` | On-demand rules + `@<name>` mentions |
| `copilot` | `.github/copilot-instructions.md` + chatmodes | Repo-wide instructions + chatmode picker |
| `aider` | `CONVENTIONS.md` + per-skill files | Always-on conventions + `/read-only` per skill |
| `continue` | `config.yaml` + `rules/` + `prompts/` | Rules auto-load; prompts as slash commands |
| `generic` | Single `PROMPTS.md` | Paste-anywhere bundle |

Use these as references when adding a new one.
