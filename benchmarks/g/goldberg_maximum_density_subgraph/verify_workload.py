"""Static package inventory and hand-authored fixture contract reviewer."""

from __future__ import annotations

import json
import re
from pathlib import Path

try:
    from .independent_oracle import expected_result as independent_result
    from .primary_oracle import expected_result as primary_result
except ImportError:  # Allow package-local invocation if a reviewer chooses it.
    from independent_oracle import expected_result as independent_result
    from primary_oracle import expected_result as primary_result

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/g/goldberg_maximum_density_subgraph"
SYMBOL = "goldberg_maximum_density_subgraph"
REQUIRED_CASES = {
    "empty-edge-set", "one-edge-and-isolates", "triangle-with-isolate",
    "four-vertex-path", "five-vertex-path", "complete-four-vertex-graph",
    "two-disjoint-triangles", "complete-eight-vertex-graph",
    "maximum-frame-k8-minus-one-edge", "duplicate-edge", "self-loop",
    "endpoint-out-of-range", "truncated-frame", "trailing-word-at-parseable-bound",
    "vertex-count-out-of-range", "null-input", "null-input-at-parseable-bound",
}
PORTS = {
    "c": ROOT / "c/g/goldberg_maximum_density_subgraph.c",
    "c3": ROOT / "c3/g/goldberg_maximum_density_subgraph.c3",
    "cpp": ROOT / "cpp/g/goldberg_maximum_density_subgraph.cpp",
    "elisa": ROOT / "elisa/g/goldberg_maximum_density_subgraph.elisa",
    "mojo": ROOT / "mojo/g/goldberg_maximum_density_subgraph.mojo",
    "nim": ROOT / "nim/g/goldberg_maximum_density_subgraph.nim",
    "odin": ROOT / "odin/g/goldberg_maximum_density_subgraph.odin",
    "rust": ROOT / "rust/g/goldberg_maximum_density_subgraph.rs",
    "v": ROOT / "v/g/goldberg_maximum_density_subgraph.v",
    "zig": ROOT / "zig/g/goldberg_maximum_density_subgraph.zig",
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
    if (contract.get("vertex_count_range") != [2, 8]
            or contract.get("maximum_valid_length") != 58
            or contract.get("maximum_parseable_length") != 59):
        issues.append("input bounds mismatch")
    output = workload.get("output", {})
    if output.get("maximum_result") != 260 or output.get("invalid_input_result") != -1:
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
    maximum = next((case for case in cases if case.get("id") == "complete-eight-vertex-graph"), None)
    if (maximum is None or maximum.get("input_length") != 58
            or maximum.get("input_values", [])[:2] != [8, 28]):
        issues.append("maximum frame does not exercise the maximum vertex and edge bounds")
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
    if "CSD-84-171" not in readme or "BKV12" not in readme or "Charikar" not in readme:
        issues.append("README missing source or distinction from local approximation profiles")
    return issues


def verify() -> list[str]:
    """Return inventory and fixture issues without launching language ports."""
    return static_issues()
