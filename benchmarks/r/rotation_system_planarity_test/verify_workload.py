"""Static package inventory and fixture agreement reviewer."""

from __future__ import annotations

import json
import re
from pathlib import Path

try:
    from .independent_oracle import expected_result as independent_result
    from .primary_oracle import expected_result as primary_result
except ImportError:
    from independent_oracle import expected_result as independent_result
    from primary_oracle import expected_result as primary_result

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/r/rotation_system_planarity_test"
SYMBOL = "rotation_system_planarity_test"
REQUIRED_CASES = {
    "isolates-only", "single-edge-and-isolates", "tree-with-bridges", "five-cycle",
    "k4-with-isolates", "octahedron-at-planar-edge-bound", "k33-nonplanar",
    "subdivided-k5-minor", "k5-fast-edge-bound", "k6-maximum-frame-fast-rejection",
    "duplicate-edge", "loop", "endpoint-out-of-range", "truncated-frame",
    "trailing-word-at-parseable-bound", "vertex-count-out-of-range", "null-input",
    "null-input-at-parseable-bound",
}
PORTS = {
    "c": ROOT / "c/r/rotation_system_planarity_test.c",
    "c3": ROOT / "c3/r/rotation_system_planarity_test.c3",
    "cpp": ROOT / "cpp/r/rotation_system_planarity_test.cpp",
    "elisa": ROOT / "elisa/r/rotation_system_planarity_test.elisa",
    "mojo": ROOT / "mojo/r/rotation_system_planarity_test.mojo",
    "nim": ROOT / "nim/r/rotation_system_planarity_test.nim",
    "odin": ROOT / "odin/r/rotation_system_planarity_test.odin",
    "rust": ROOT / "rust/r/rotation_system_planarity_test.rs",
    "v": ROOT / "v/r/rotation_system_planarity_test.v",
    "zig": ROOT / "zig/r/rotation_system_planarity_test.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    if workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL:
        issues.append("algorithm or function symbol mismatch")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("unexpected ABI")
    contract = workload.get("input", {})
    if (contract.get("vertex_count_range") != [1, 6]
            or contract.get("maximum_valid_length") != 32
            or contract.get("maximum_parseable_length") != 33):
        issues.append("input bounds mismatch")
    output = workload.get("output", {})
    if output.get("maximum_result") != 1 or output.get("invalid_input_result") != -1:
        issues.append("output bounds mismatch")
    cases = workload.get("cases")
    if not isinstance(cases, list):
        return issues + ["cases must be an array"]
    identifiers: set[str] = set()
    for case in cases:
        if not isinstance(case, dict):
            issues.append("case entry is not an object")
            continue
        case_id = case.get("id", "<unnamed>")
        if case_id in identifiers:
            issues.append(f"duplicate fixture id: {case_id}")
        identifiers.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        is_null = case.get("input_is_null", False)
        expected = case.get("expected_result")
        if (not isinstance(values, list) or type(length) is not int
                or type(is_null) is not bool or type(expected) is not int
                or (is_null and values)
                or (not is_null and length != len(values))):
            issues.append(f"fixture shape invalid: {case_id}")
            continue
        args = {"input_is_null": is_null, "input_length": length}
        if primary_result(values, **args) != expected:
            issues.append(f"primary reference fixture mismatch: {case_id}")
        if independent_result(values, **args) != expected:
            issues.append(f"independent reference fixture mismatch: {case_id}")
    if identifiers != REQUIRED_CASES:
        issues.append("fixture inventory does not match required coverage cases")
    maximum = next((case for case in cases if case.get("id") == "k6-maximum-frame-fast-rejection"), None)
    maximum_values = maximum.get("input_values") if maximum is not None else None
    if (maximum is None or maximum.get("input_length") != 32
            or not isinstance(maximum_values, list) or maximum_values[:2] != [6, 15]):
        issues.append("maximum frame does not exercise both input bounds")
    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} implementation: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing {language} symbol: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                 "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    try:
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    except OSError:
        return issues
    for target in re.findall(r"\]\(([^)]+)\)", readme):
        if "://" in target or target.startswith("#"):
            continue
        if not (PACKAGE / target).resolve().is_file():
            issues.append(f"README target does not resolve: {target}")
    if ("Heffter" not in readme or "Wagner" not in readme
            or "planar_face_count" not in readme or "upward_planarity_angle_assignment" not in readme):
        issues.append("README missing source or distinctness discussion")
    return issues


def verify() -> list[str]:
    """Return static inventory and fixture issues without running language ports."""
    return static_issues()
