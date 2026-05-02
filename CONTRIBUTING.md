# Contributing to moodle-dev

Thanks for helping make this the best Moodle toolkit for Claude Code.

## Ways to contribute

- **Add a skill** — covers a Moodle area not yet handled (e.g., `moodle-h5p`, `moodle-lti`, `moodle-analytics`)
- **Add a slash command** — wraps a common workflow (`/moodle-bump-version`, `/moodle-codestyle`)
- **Add a subagent** — specialized reviewer / scaffolder
- **Improve existing skills** — tighter examples, fix Moodle-version differences, link better docs
- **Report a gap** — open an issue with a prompt Claude got wrong

## Project layout

```
.claude-plugin/         # plugin + marketplace manifests
skills/<name>/SKILL.md  # auto-activating expertise
commands/<name>.md      # /<name> slash commands
agents/<name>.md        # invokable subagents
```

## Add a skill

Create `skills/<kebab-name>/SKILL.md`:

```markdown
---
name: <kebab-name>
description: Use when <trigger>. Covers <list of topics>. Skip when <negative trigger>.
---

# <Title>

## Overview
1-2 sentences on what this is.

## When to Use
- Bullet list of trigger scenarios
- **Skip when:** <negative trigger>

## <Sections covering the substance>

## References
- https://moodledev.io/...
```

Rules:
- `description` is what Claude matches against — be specific about triggers
- Lead with `When to Use` so the activation contract is clear
- Show real Moodle code (not pseudo-code), include version notes (`Moodle 4.4+:`)
- Link `moodledev.io` over wiki / outdated sources
- Cover **common mistakes** in a table — high signal for review
- Keep under ~300 lines; split into multiple skills if larger

## Add a slash command

Create `commands/<kebab-name>.md`:

```markdown
---
name: <kebab-name>
description: One line shown in /help
argument-hint: "[optional args]"
---

Instructions to Claude. Use $ARGUMENTS for the user's input.
```

## Add a subagent

Create `agents/<kebab-name>.md`:

```markdown
---
name: <kebab-name>
description: When to invoke this agent.
tools: Read, Grep, Glob, Bash
---

System prompt for the agent.
```

## PR checklist

- [ ] New/changed files use kebab-case names
- [ ] Frontmatter `name` matches directory/filename
- [ ] `description` clearly states activation triggers
- [ ] Code samples are valid Moodle (no PHP syntax errors)
- [ ] Links go to `moodledev.io` where possible
- [ ] `CHANGELOG.md` updated under `## [Unreleased]`
- [ ] `plugin.json` + `marketplace.json` version bumped if user-facing change
- [ ] Lint workflow passes (JSON valid, frontmatter present)

## Versioning

Semver:
- **patch** — typo, doc tweak, link fix
- **minor** — new skill / command / agent, new section
- **major** — breaking rename / removal

Bump in three places: `plugin.json`, `marketplace.json` (`plugins[].version`), `CHANGELOG.md`.

## Testing locally

```
/plugin marketplace add /absolute/path/to/claude-moodle-dev
/plugin install moodle-dev@moodle-dev
```

Then prompt Claude with a Moodle task and confirm the right skill activates (`/skills` to list active skills).

## Questions

Open a [discussion](https://github.com/SaadRahman01/claude-moodle-dev/discussions) or ping in an issue.
