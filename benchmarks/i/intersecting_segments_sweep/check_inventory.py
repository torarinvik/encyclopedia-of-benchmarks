"""Static package checks; does not compile or execute language ports."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/i/intersecting_segments_sweep"
ALGORITHM = "intersecting_segments_sweep"
LANGUAGE_PATHS = {
    "c": "c/i/intersecting_segments_sweep.c",
    "c3": "c3/i/intersecting_segments_sweep.c3",
    "cpp": "cpp/i/intersecting_segments_sweep.cpp",
    "elisa": "elisa/i/intersecting_segments_sweep.elisa",
    "mojo": "mojo/i/intersecting_segments_sweep.mojo",
    "nim": "nim/i/intersecting_segments_sweep.nim",
    "odin": "odin/i/intersecting_segments_sweep.odin",
    "rust": "rust/i/intersecting_segments_sweep.rs",
    "v": "v/i/intersecting_segments_sweep.v",
    "zig": "zig/i/intersecting_segments_sweep.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package inventory: {error}"]
    if inventory.get("algorithm") != ALGORITHM or inventory.get("function_symbol") != ALGORITHM:
        issues.append("inventory algorithm or symbol does not match the package")
    if inventory.get("abi") != "i64_array_scalar":
        issues.append("inventory ABI is not i64_array_scalar")
    if inventory.get("languages") != LANGUAGE_PATHS:
        issues.append("inventory must list exactly the ten expected ports")
    for language, relative_path in LANGUAGE_PATHS.items():
        if not (ROOT / relative_path).is_file():
            issues.append(f"missing {language} source: {relative_path}")
    for name in inventory.get("metadata", []):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package metadata: {name}")
    readme_path = PACKAGE / "README.md"
    if readme_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        for required in (
            "cp-algorithms.com/geometry/intersecting_segments.html", "O(n^2)",
            "endpoint-on-segment", "collinear overlap", "independent reference",
        ):
            if required not in readme:
                issues.append(f"README is missing required contract/source text: {required}")
    return issues
