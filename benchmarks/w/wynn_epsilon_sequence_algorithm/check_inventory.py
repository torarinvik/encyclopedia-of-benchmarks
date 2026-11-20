"""Package-local source inventory checks; intentionally not run here."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
PORTS = (
    "c/w/wynn_epsilon_sequence_algorithm.c",
    "c3/w/wynn_epsilon_sequence_algorithm.c3",
    "cpp/w/wynn_epsilon_sequence_algorithm.cpp",
    "elisa/w/wynn_epsilon_sequence_algorithm.elisa",
    "mojo/w/wynn_epsilon_sequence_algorithm.mojo",
    "nim/w/wynn_epsilon_sequence_algorithm.nim",
    "odin/w/wynn_epsilon_sequence_algorithm.odin",
    "rust/w/wynn_epsilon_sequence_algorithm.rs",
    "v/w/wynn_epsilon_sequence_algorithm.v",
    "zig/w/wynn_epsilon_sequence_algorithm.zig",
)
REQUIRED = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py", "check_inventory.py",
)


def static_issues() -> list[str]:
    issues: list[str] = []
    for name in REQUIRED:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    try:
        metadata = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read package metadata: {error}"]
    if metadata.get("algorithm") != "wynn_epsilon_sequence_algorithm":
        issues.append("inventory algorithm identity differs")
    if metadata.get("ports") != list(PORTS):
        issues.append("inventory language paths differ from required paths")
    for relative in PORTS:
        source = ROOT / relative
        if not source.is_file():
            issues.append(f"missing port: {relative}")
        elif "wynn_epsilon_sequence_algorithm" not in source.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol marker: {relative}")
        if relative not in readme:
            issues.append(f"README omits port link: {relative}")
    return issues
