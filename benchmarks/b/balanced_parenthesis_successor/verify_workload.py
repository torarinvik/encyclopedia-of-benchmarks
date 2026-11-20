"""Static package inventory and fixture/reference consistency checker."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/b/balanced_parenthesis_successor"
SYMBOL = "balanced_parenthesis_successor"
SOURCE_URL = "https://cp-algorithms.com/combinatorics/bracket_sequences.html#finding-the-lexicographical-next-balanced-sequence"
PORTS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED_CASES = {
    "two-pair-minimum", "three-pair-branch-change", "three-pair-middle",
    "three-pair-near-maximum", "one-pair-maximum", "three-pair-maximum",
    "maximum-size-maximum-with-capacity",
    "maximum-size-minimal-sequence", "short-output-capacity", "null-output",
    "maximum-null-output", "null-input", "zero-pair-out-of-profile",
    "too-many-pairs", "invalid-symbol", "negative-prefix-balance",
    "nonzero-final-balance", "missing-symbol", "trailing-input-value",
}


def _load_oracle(filename: str):
    path = PACKAGE / filename
    spec = importlib.util.spec_from_file_location(path.stem, path)
    if spec is None or spec.loader is None:
        raise ValueError(f"cannot load reference module: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    required_files = ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
                      "primary_oracle.py", "independent_oracle.py", "verify_workload.py")
    for filename in required_files:
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package file: {filename}")
    for language, extension in PORTS.items():
        relative = f"{language}/b/{SYMBOL}.{extension}"
        source = ROOT / relative
        if not source.is_file():
            issues.append(f"missing source: {relative}")
        elif SYMBOL not in source.read_text(encoding="utf-8"):
            issues.append(f"exported symbol is absent: {relative}")

    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return issues + [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return issues + ["workload must be an object"]
    primary = _load_oracle("primary_oracle.py")
    independent = _load_oracle("independent_oracle.py")
    if (workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("source", {}).get("url") != SOURCE_URL
            or workload.get("input", {}).get("pair_count_range") != [1, 10]
            or workload.get("input", {}).get("maximum_valid_length") != 21
            or workload.get("input", {}).get("maximum_parseable_length") != 22
            or workload.get("output", {}).get("maximum_bytes") != 20
            or workload.get("workspace", {}).get("bytes") != 128):
        issues.append("workload identity, bounds, provenance, or workspace differ")
    cases = workload.get("cases")
    if not isinstance(cases, list):
        return issues + ["missing workload cases"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid case record")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate fixture ID: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        output_bytes = case.get("expected_output_bytes")
        result = case.get("expected_result")
        if (not isinstance(values, list) or type(length) is not int or length != len(values)
                or not isinstance(output_bytes, list) or type(result) is not int):
            issues.append(f"invalid fixture fields: {case_id}")
            continue
        options = {
            "output_capacity": case.get("output_capacity"),
            "input_is_null": case.get("input_is_null", False),
            "output_is_null": case.get("output_is_null", False),
            "input_length": length,
        }
        expected = (result, bytes(output_bytes))
        if (primary.expected_output(values, **options) != expected
                or independent.expected_output(values, **options) != expected):
            issues.append(f"fixture disagrees with a reference: {case_id}")
    missing = REQUIRED_CASES - seen
    if missing:
        issues.append("missing required fixture IDs: " + ", ".join(sorted(missing)))

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    inventory = (PACKAGE / "INVENTORY.md").read_text(encoding="utf-8")
    for required in (SOURCE_URL, "rightmost feasible", "parentheses_generator",
                     "single-successor", "clean-room"):
        if required not in readme:
            issues.append(f"README omits package detail: {required}")
    if SOURCE_URL not in rights or "clean-room" not in rights.lower():
        issues.append("rights/provenance note is incomplete")
    if "verify_workload.py" not in inventory:
        issues.append("inventory omits static checker")
    for language, extension in PORTS.items():
        relative = f"{language}/b/{SYMBOL}.{extension}"
        if relative not in readme:
            issues.append(f"README omits source path: {relative}")
    return issues
