"""Static inventory and fixture review for the bounded GNNS package."""

from __future__ import annotations

import json
from pathlib import Path

from graphai_gnns_hill_climbing_oracle import expected_result as primary_result
from graphai_gnns_hill_climbing_verifier_oracle import expected_result as independent_result

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/g/graphai_gnns_hill_climbing"
PORTS = {
    "c": ROOT / "c/g/graphai_gnns_hill_climbing.c",
    "c3": ROOT / "c3/g/graphai_gnns_hill_climbing.c3",
    "cpp": ROOT / "cpp/g/graphai_gnns_hill_climbing.cpp",
    "elisa": ROOT / "elisa/g/graphai_gnns_hill_climbing.elisa",
    "mojo": ROOT / "mojo/g/graphai_gnns_hill_climbing.mojo",
    "nim": ROOT / "nim/g/graphai_gnns_hill_climbing.nim",
    "odin": ROOT / "odin/g/graphai_gnns_hill_climbing.odin",
    "rust": ROOT / "rust/g/graphai_gnns_hill_climbing.rs",
    "v": ROOT / "v/g/graphai_gnns_hill_climbing.v",
    "zig": ROOT / "zig/g/graphai_gnns_hill_climbing.zig",
}
RUNNER = ROOT / "benchmarks/run_i64_array_scalar.py"
VERIFIER = ROOT / "benchmarks/verify_i64_array_scalar.py"


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]
    if workload.get("algorithm") != "graphai_gnns_hill_climbing":
        issues.append("unexpected algorithm name")
    if workload.get("function_symbol") != "graphai_gnns_hill_climbing":
        issues.append("unexpected exported symbol")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("unexpected ABI")
    contract = workload.get("input", {})
    if (contract.get("maximum_valid_length") != 89
            or contract.get("maximum_parseable_length") != 90):
        issues.append("maximum input length mismatch")
    controls = workload.get("profile_controls", {})
    if (controls.get("offline_graph_construction", "").startswith("precomputed") is False
            or controls.get("K") != 1 or controls.get("R") != 1
            or controls.get("start_selection", "").find("caller-supplied") < 0
            or controls.get("visited_nodes", "").find("strict distance") < 0):
        issues.append("GNNS bounded profile controls are incomplete")
    for case in workload.get("cases", []):
        if not isinstance(case, dict):
            issues.append("workload contains a non-object case")
            continue
        values = case.get("input_values")
        case_id = case.get("id", "<unnamed>")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"fixture input length mismatch: {case_id}")
            continue
        arguments = {
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        expected = case.get("expected_result")
        if primary_result(values, **arguments) != expected:
            issues.append(f"primary oracle fixture mismatch: {case_id}")
        if independent_result(values, **arguments) != expected:
            issues.append(f"independent oracle fixture mismatch: {case_id}")
    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif "graphai_gnns_hill_climbing" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json", "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")
    for label, path in (("scalar runner", RUNNER), ("scalar verifier", VERIFIER)):
        try:
            suite_source = path.read_text(encoding="utf-8")
        except OSError as error:
            issues.append(f"cannot read {label}: {error}")
            continue
        if "graphai_gnns_hill_climbing" not in suite_source:
            issues.append(f"{label} is missing suite registration")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for marker in ("10.5591/978-1-57735-516-8/IJCAI11-222", "prebuilt", "one supplied",
                   "strictly closer", "visited-node filter", "empty per-vertex stub"):
        if marker not in readme:
            issues.append(f"README missing profile/provenance detail: {marker}")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
