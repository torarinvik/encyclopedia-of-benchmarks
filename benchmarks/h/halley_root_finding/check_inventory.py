"""Static inventory API for the Halley root-finding package."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent


def static_issues() -> list[str]:
    inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    issues: list[str] = []
    if inventory.get("algorithm") != "halley_root_finding":
        issues.append("inventory algorithm does not match the package")
    if inventory.get("abi") != "float64_pair":
        issues.append("inventory ABI does not match the package")
    for label in ("workload", "primary_oracle", "independent_oracle"):
        path = ROOT / inventory.get(label, "")
        if not path.is_file():
            issues.append(f"missing {label} file")
    languages = inventory.get("languages", {})
    if len(languages) != 10:
        issues.append("inventory must list all ten language ports")
    for language, relative in languages.items():
        if not (ROOT / relative).is_file():
            issues.append(f"missing {language} port")
    return issues
