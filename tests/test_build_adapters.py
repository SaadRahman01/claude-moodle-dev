"""Unit tests for the adapter generator.

Run: python3 -m unittest tests.test_build_adapters
or:  python3 tests/test_build_adapters.py
"""
from __future__ import annotations

import sys
import unittest
from pathlib import Path
from tempfile import NamedTemporaryFile

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))

import importlib.util
spec = importlib.util.spec_from_file_location("build_adapters", ROOT / "scripts" / "build-adapters.py")
ba = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ba)  # type: ignore[union-attr]


class ParseFrontmatterTests(unittest.TestCase):
    def _tmp(self, text: str) -> Path:
        f = NamedTemporaryFile("w", suffix=".md", delete=False)
        f.write(text)
        f.close()
        return Path(f.name)

    def test_parses_simple_frontmatter(self) -> None:
        p = self._tmp("---\nname: foo\ndescription: bar\n---\nbody\n")
        fm, body = ba.parse(p)
        self.assertEqual(fm["name"], "foo")
        self.assertEqual(fm["description"], "bar")
        self.assertEqual(body.strip(), "body")

    def test_no_frontmatter_returns_empty_dict(self) -> None:
        p = self._tmp("no fm here\n")
        fm, body = ba.parse(p)
        self.assertEqual(fm, {})
        self.assertIn("no fm here", body)

    def test_strips_surrounding_quotes(self) -> None:
        p = self._tmp('---\nname: "quoted"\n---\nx\n')
        fm, _ = ba.parse(p)
        self.assertEqual(fm["name"], "quoted")


class LoadAllTests(unittest.TestCase):
    def test_load_all_finds_known_skills(self) -> None:
        items = ba.load_all()
        skill_names = {fm.get("name") for fm, _, _ in items["skills"]}
        self.assertIn("moodle-plugin-development", skill_names)
        self.assertIn("moodle-phpunit-testing", skill_names)

    def test_load_all_finds_known_commands(self) -> None:
        items = ba.load_all()
        cmd_names = {fm.get("name") for fm, _, _ in items["commands"]}
        self.assertIn("moodle-new-plugin", cmd_names)

    def test_load_all_finds_known_agents(self) -> None:
        items = ba.load_all()
        agent_names = {fm.get("name") for fm, _, _ in items["agents"]}
        self.assertIn("moodle-reviewer", agent_names)


if __name__ == "__main__":
    unittest.main()
