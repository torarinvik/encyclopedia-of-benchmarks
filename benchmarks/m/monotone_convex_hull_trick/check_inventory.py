"""Static inventory review for the monotone convex hull trick package."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "monotone_convex_hull_trick"
PORTS = {
    "C": ROOT / "c/m/monotone_convex_hull_trick.c",
    "C3": ROOT / "c3/m/monotone_convex_hull_trick.c3",
    "C++": ROOT / "cpp/m/monotone_convex_hull_trick.cpp",
    "Elisa": ROOT / "elisa/m/monotone_convex_hull_trick.elisa",
    "Mojo": ROOT / "mojo/m/monotone_convex_hull_trick.mojo",
    "Nim": ROOT / "nim/m/monotone_convex_hull_trick.nim",
    "Odin": ROOT / "odin/m/monotone_convex_hull_trick.odin",
    "Rust": ROOT / "rust/m/monotone_convex_hull_trick.rs",
    "V": ROOT / "v/m/monotone_convex_hull_trick.v",
    "Zig": ROOT / "zig/m/monotone_convex_hull_trick.zig",
}


def check_inventory() -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
            continue
        source = path.read_text(encoding="utf-8")
        if SYMBOL not in source:
            issues.append(f"{language} port does not export {SYMBOL}")
        if language == "Elisa" and ("UnsafePointer" in source or "*i64" in source):
            issues.append("Elisa port must retain safe views instead of raw pointers")

    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"invalid workload JSON: {error}"]
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    if (workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"
            or input_spec.get("maximum_valid_length") != 98
            or input_spec.get("maximum_parseable_length") != 99
            or output_spec.get("result_range") != [-533280000, 533280000]
            or workload.get("workspace", {}).get("bytes") != 512):
        issues.append("workload metadata differs from the bounded scalar contract")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        issues.append("workload cases must be a nonempty list")
    else:
        ids = {case.get("id") for case in cases if isinstance(case, dict)}
        if "maximum-valid-frame" not in ids or "duplicate-slope" not in ids:
            issues.append("workload must include maximum-frame and duplicate-slope cases")
        for case in cases:
            if not isinstance(case, dict):
                issues.append("workload contains a non-object fixture")
                continue
            values = case.get("input_values")
            if (not isinstance(values, list)
                    or case.get("input_length") != len(values)
                    or len(values) > 99):
                issues.append(f"invalid framing in fixture {case.get('id', '<unnamed>')}")
                break
    return issues


static_issues = check_inventory
