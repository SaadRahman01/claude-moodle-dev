# Security Policy

## Supported Versions

Only the latest minor release receives security updates. Pin to a tagged release for production use.

| Version | Supported |
|---------|-----------|
| 0.4.x   | yes       |
| < 0.4   | no        |

## Reporting a Vulnerability

**Do not open a public issue for security reports.**

Email: **saad.rahman010@gmail.com** with subject `[moodle-dev security]`.

Include:
- Affected skill / command / agent / adapter file
- Reproduction prompt or steps
- Impact (prompt injection, data exfiltration, malicious code generation, credential exposure, etc.)
- Suggested fix if you have one

You will receive an acknowledgement within **72 hours**. A fix or mitigation is targeted within **14 days** for high-severity issues.

## Scope

In scope:
- Skill / agent / command content that could lead Claude to generate vulnerable Moodle code (missing `require_sesskey`, SQL injection patterns, capability bypass, etc.)
- Prompt-injection vectors inside skill/agent bodies
- Adapter generation script (`scripts/build-adapters.py`) producing unsafe output
- CI workflow misconfigurations leaking secrets
- Dependency vulnerabilities in pinned GitHub Actions

Out of scope:
- Vulnerabilities in Moodle core (report to [Moodle Tracker](https://tracker.moodle.org/))
- Vulnerabilities in Claude Code itself (report to Anthropic)
- Issues that require an attacker to already control the user's editor or shell

## Disclosure

Coordinated disclosure preferred. Public credit in `CHANGELOG.md` and release notes unless you request anonymity.
