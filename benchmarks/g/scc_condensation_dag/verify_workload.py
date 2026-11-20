"""Static source inventory and workload/reference consistency checker."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/g/scc_condensation_dag"
SYMBOL = "scc_condensation_dag"
SOURCE_URL = "https://cp-algorithms.com/graph/strongly-connected-components.html"
PORTS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED_CASES = {
    "empty-graph", "single-isolate", "single-condensation-edge",
    "one-strong-component", "cycle-with-tail", "duplicate-quotient-edge",
    "backward-canonical-edge", "self-loops-are-internal", "maximum-complete-dag",
    "short-output-capacity", "null-output", "null-input", "invalid-vertex-count",
    "invalid-edge-count", "invalid-endpoint", "trailing-input-value",
}


def _load_oracle(filename: str):
    path = PACKAGE / filename
    spec = importlib.util.spec_from_file_location(path.stem, path)
    if spec is None or spec.loader is None:
        raise ValueError(f"cannot load reference: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    for filename in ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
                     "primary_oracle.py", "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package file: {filename}")
    for language, extension in PORTS.items():
        relative = f"{language}/g/{SYMBOL}.{extension}"
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing source: {relative}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol: {relative}")

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
            or workload.get("input", {}).get("vertex_count_range") != [0, 8]
            or workload.get("input", {}).get("edge_count_range") != [0, 28]
            or workload.get("input", {}).get("maximum_valid_length") != 58
            or workload.get("input", {}).get("maximum_parseable_length") != 59
            or workload.get("output", {}).get("maximum_bytes") != 17
            or workload.get("workspace", {}).get("bytes") != 1024):
        issues.append("workload identity, bounds, or provenance differ")
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
            issues.append(f"duplicate case: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        if (not isinstance(values, list) or type(length) is not int or length != len(values)
                or not isinstance(case.get("expected_output_bytes"), list)
                or type(case.get("expected_result")) is not int):
            issues.append(f"invalid fixture fields: {case_id}")
            continue
        options = {
            "output_capacity": case.get("output_capacity"),
            "input_is_null": case.get("input_is_null", False),
            "output_is_null": case.get("output_is_null", False),
            "input_length": length,
        }
        expected = (case["expected_result"], bytes(case["expected_output_bytes"]))
        if (primary.expected_output(values, **options) != expected
                or independent.expected_output(values, **options) != expected):
            issues.append(f"fixture differs from references: {case_id}")
    missing = REQUIRED_CASES - seen
    if missing:
        issues.append("missing required cases: " + ", ".join(sorted(missing)))

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    inventory = (PACKAGE / "INVENTORY.md").read_text(encoding="utf-8")
    for required in (SOURCE_URL, "ascending minimum vertex", "duplicate quotient edges",
                     "mutual reachability", "clean-room"):
        if required not in readme:
            issues.append(f"README missing profile detail: {required}")
    if SOURCE_URL not in rights or "clean-room" not in rights.lower():
        issues.append("rights/provenance note is incomplete")
    if "verify_workload.py" not in inventory:
        issues.append("inventory omits the static checker")
    for language, extension in PORTS.items():
        relative = f"{language}/g/{SYMBOL}.{extension}"
        if relative not in readme:
            issues.append(f"README omits port: {relative}")
    return issues
