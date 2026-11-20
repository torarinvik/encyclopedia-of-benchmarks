"""Static package inventory checks; this file never imports native code."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PACKAGE = Path(__file__).resolve().parent
MANIFEST = PACKAGE / "inventory.json"


def static_issues() -> list[str]:
    issues: list[str] = []
    required = (
        "README.md", "RIGHTS.md", "INVENTORY.md", "inventory.json",
        "workload.json", "primary_oracle.py", "independent_oracle.py",
        "check_inventory.py", "verify_workload.py",
    )
    for name in required:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    if not MANIFEST.is_file():
        return issues
    try:
        inventory = json.loads(MANIFEST.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return issues + ["inventory.json is not valid JSON"]
    if inventory.get("algorithm") != "succinct_bp_pioneer_match_index":
        issues.append("inventory algorithm id mismatch")
    languages = inventory.get("languages", {})
    if set(languages) != {"c", "c3", "cpp", "elisa", "mojo", "nim", "odin", "rust", "v", "zig"}:
        issues.append("inventory must list all ten supported languages")
    for language, relative in languages.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} source: {relative}")
        elif "succinct_bp_pioneer_match_index" not in path.read_text(encoding="utf-8"):
            issues.append(f"{relative}: exported symbol text missing")
    return issues


def check_inventory() -> list[str]:
    return static_issues()


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
    print("static inventory complete")
