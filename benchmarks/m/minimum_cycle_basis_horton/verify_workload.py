"""Static package inventory and fixture contract verifier."""

from __future__ import annotations

import json
import re
from pathlib import Path

try:
    from .independent_oracle import expected_result as independent_result
    from .primary_oracle import expected_result as primary_result
except ImportError:  # Support direct execution from the package directory.
    from independent_oracle import expected_result as independent_result
    from primary_oracle import expected_result as primary_result

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/m/minimum_cycle_basis_horton"
SYMBOL = "minimum_cycle_basis_horton"
REQUIRED_CASES = {
    "triangle-single-cycle", "connected-tree-empty-cycle-space", "weighted-square",
    "equal-weight-diamond-two-triangles", "heavier-diagonal-prefers-shorter-cycle-basis",
    "complete-four-vertex-graph", "maximum-eight-vertex-twelve-edge-frame",
    "disconnected-graph", "duplicate-edge-pair", "zero-edge-weight",
    "unsorted-edge-pairs", "trailing-word-at-parseable-bound",
    "count-out-of-range", "null-input",
}
PORTS = {
    "c": (ROOT / "c/m/minimum_cycle_basis_horton.c", ".c"),
    "c3": (ROOT / "c3/m/minimum_cycle_basis_horton.c3", ".c3"),
    "cpp": (ROOT / "cpp/m/minimum_cycle_basis_horton.cpp", ".cpp"),
    "elisa": (ROOT / "elisa/m/minimum_cycle_basis_horton.elisa", ".elisa"),
    "mojo": (ROOT / "mojo/m/minimum_cycle_basis_horton.mojo", ".mojo"),
    "nim": (ROOT / "nim/m/minimum_cycle_basis_horton.nim", ".nim"),
    "odin": (ROOT / "odin/m/minimum_cycle_basis_horton.odin", ".odin"),
    "rust": (ROOT / "rust/m/minimum_cycle_basis_horton.rs", ".rs"),
    "v": (ROOT / "v/m/minimum_cycle_basis_horton.v", ".v"),
    "zig": (ROOT / "zig/m/minimum_cycle_basis_horton.zig", ".zig"),
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
    if (contract.get("vertex_count_range") != [3, 8]
            or contract.get("maximum_valid_length") != 38
            or contract.get("maximum_parseable_length") != 39):
        issues.append("input bounds mismatch")
    output = workload.get("output", {})
    if output.get("maximum_result") != 378 or output.get("invalid_input_result") != -1:
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
        if not isinstance(values, list) or type(case.get("input_length")) is not int:
            issues.append(f"fixture shape invalid: {case_id}")
            continue
        if case["input_length"] != len(values) and not case.get("input_is_null", False):
            issues.append(f"fixture declared length mismatch: {case_id}")
            continue
        args = {"input_is_null": case.get("input_is_null", False),
                "input_length": case["input_length"]}
        expected = case.get("expected_result")
        if primary_result(values, **args) != expected:
            issues.append(f"primary reference fixture mismatch: {case_id}")
        if independent_result(values, **args) != expected:
            issues.append(f"independent reference fixture mismatch: {case_id}")
    if identifiers != REQUIRED_CASES:
        issues.append("fixture inventory does not match required coverage cases")
    for language, (path, _) in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} source: {path.relative_to(ROOT)}")
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
    if "10.1137/0216026" not in readme or "minimum_mean_cycle_karp" not in readme:
        issues.append("README missing source or distinctness discussion")
    return issues


def verify() -> list[str]:
    """Return static package and fixture issues without executing language ports."""
    return static_issues()


if __name__ == "__main__":
    problems = verify()
    if problems:
        raise SystemExit("\n".join(problems))
