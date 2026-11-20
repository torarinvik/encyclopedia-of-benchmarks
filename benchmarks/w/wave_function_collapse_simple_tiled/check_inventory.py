"""Static source inventory; reading sources only, no native code is executed."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SYMBOL = "wave_function_collapse_simple_tiled"
REQUIRED = (
    PACKAGE / "README.md",
    PACKAGE / "RIGHTS.md",
    PACKAGE / "INVENTORY.md",
    PACKAGE / "INVENTORY.json",
    PACKAGE / "workload.json",
    PACKAGE / "primary_oracle.py",
    PACKAGE / "independent_oracle.py",
    PACKAGE / "verify_workload.py",
    PACKAGE / "check_inventory.py",
)


def static_issues() -> list[str]:
    issues = [f"missing artifact: {path.relative_to(ROOT)}" for path in REQUIRED if not path.is_file()]
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read inventory metadata: {error}"]
    if (inventory.get("algorithm") != SYMBOL or inventory.get("abi") != "i64_array_scalar"
            or inventory.get("symbol") != SYMBOL):
        issues.append("inventory identity or ABI differs")
    sources = inventory.get("source_paths")
    if not isinstance(sources, list) or len(sources) != 10:
        return issues + ["inventory must list ten native sources"]
    for relative in sources:
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing native source: {relative}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"exported symbol text missing: {relative}")
    for key in ("references", "workload", "metadata", "helpers"):
        entries = inventory.get(key)
        if not isinstance(entries, list) and key != "workload":
            issues.append(f"inventory field is not a file list: {key}")
        elif key == "workload":
            entries = [entries]
        if isinstance(entries, list):
            for relative in entries:
                if not (ROOT / relative).is_file():
                    issues.append(f"missing inventoried file: {relative}")
    return issues


def check_inventory() -> list[str]:
    return static_issues()


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
    print("static inventory complete")
