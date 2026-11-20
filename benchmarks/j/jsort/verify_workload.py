"""Static workload, oracle, documentation, and ten-port inventory checks."""

from __future__ import annotations

import json
from pathlib import Path
import re

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "jsort"
SOURCE_PATHS = (
    "c/j/jsort.c",
    "c3/j/jsort.c3",
    "cpp/j/jsort.cpp",
    "elisa/j/jsort.elisa",
    "mojo/j/jsort.mojo",
    "nim/j/jsort.nim",
    "odin/j/jsort.odin",
    "rust/j/jsort.rs",
    "v/j/jsort.v",
    "zig/j/jsort.zig",
)

try:
    from .independent_oracle import expected_result as independent_result
    from .primary_oracle import MAX_LENGTH, expected_result as primary_result
except ImportError:  # Direct invocation from the package directory.
    from independent_oracle import expected_result as independent_result  # type: ignore[no-redef]
    from primary_oracle import MAX_LENGTH, expected_result as primary_result  # type: ignore[no-redef]


def verify_workload(workload: object | None = None) -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
                 "primary_oracle.py", "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for source in SOURCE_PATHS:
        path = ROOT / source
        if not path.is_file():
            issues.append(f"missing port: {source}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol in {source}")

    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return issues + [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return issues + ["workload must be an object"]
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("input", {}).get("kind") != "signed_i64_array"
            or workload.get("input", {}).get("lengths") != [0, 16, 64, 256, MAX_LENGTH]
            or workload.get("input", {}).get("generation", {}).get("kind") != "modular_affine"
            or workload.get("input", {}).get("generation", {}).get("multiplier") != 48271
            or workload.get("input", {}).get("generation", {}).get("modulus") != 2000003
            or workload.get("input", {}).get("generation", {}).get("offset") != 1000001
            or workload.get("profile", {}).get("maximum_length") != MAX_LENGTH
            or workload.get("profile", {}).get("minimum_value") != -(1 << 63)
            or workload.get("profile", {}).get("maximum_value") != (1 << 63) - 1
            or workload.get("profile", {}).get("stable") is not False
            or workload.get("profile", {}).get("workspace_bytes") != 0
            or workload.get("profile", {}).get("heap_passes") != [
                "bottom-up min-heap construction over the full array",
                "reverse, bottom-up max-heap construction, reverse back",
            ]
            or workload.get("profile", {}).get("final_pass") != "ascending insertion sort"
            or workload.get("measurement", {}).get("comparison_model") != "sort_call"):
        issues.append("workload identity, input, or JSort profile differs")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["missing semantic workload cases"]
    seen: set[str] = set()
    for case in cases:
        if (not isinstance(case, dict) or not isinstance(case.get("id"), str)
                or not isinstance(case.get("input_values"), list)
                or not isinstance(case.get("expected_values"), list)):
            issues.append("invalid JSort workload case")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate workload case: {case_id}")
        seen.add(case_id)
        values = case["input_values"]
        expected = case["expected_values"]
        if primary_result(values) != expected or independent_result(values) != expected:
            issues.append(f"oracle fixture mismatch: {case_id}")

    readme_path = PACKAGE / "README.md"
    rights_path = PACKAGE / "RIGHTS.md"
    if readme_path.is_file() and rights_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        rights = rights_path.read_text(encoding="utf-8")
        source = workload.get("source", {})
        source_url = source.get("url") if isinstance(source, dict) else None
        if not isinstance(source_url, str) or source_url not in readme or source_url not in rights:
            issues.append("algorithm source attribution is missing from package docs")
        for target in re.findall(r"\]\(([^)]+)\)", readme):
            if target.startswith(("http://", "https://", "#")):
                continue
            if not (PACKAGE / target.split("#", 1)[0]).resolve().is_file():
                issues.append(f"broken README target: {target}")
    return issues


static_issues = verify_workload
