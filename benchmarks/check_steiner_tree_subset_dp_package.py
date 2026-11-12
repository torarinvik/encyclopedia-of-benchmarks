"""Static inventory and workload review for exact graph Steiner subset DP."""

from __future__ import annotations

import json
from pathlib import Path

from steiner_tree_subset_dp_oracle import expected_result as primary_result
from steiner_tree_subset_dp_verifier_oracle import expected_result as independent_result

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/p/steiner_tree_subset_dp"
PORTS = {
    "c": ROOT / "c/s/steiner_tree_subset_dp.c",
    "c3": ROOT / "c3/s/steiner_tree_subset_dp.c3",
    "cpp": ROOT / "cpp/s/steiner_tree_subset_dp.cpp",
    "elisa": ROOT / "elisa/s/steiner_tree_subset_dp.elisa",
    "mojo": ROOT / "mojo/s/steiner_tree_subset_dp.mojo",
    "nim": ROOT / "nim/s/steiner_tree_subset_dp.nim",
    "odin": ROOT / "odin/s/steiner_tree_subset_dp.odin",
    "rust": ROOT / "rust/s/steiner_tree_subset_dp.rs",
    "v": ROOT / "v/s/steiner_tree_subset_dp.v",
    "zig": ROOT / "zig/s/steiner_tree_subset_dp.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]
    if workload.get("algorithm") != "steiner_tree_subset_dp":
        issues.append("unexpected algorithm name")
    if workload.get("function_symbol") != "steiner_tree_subset_dp":
        issues.append("unexpected exported symbol")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("unexpected ABI")
    input_meta = workload.get("input", {})
    if input_meta.get("vertex_count_range") != [1, 8] or input_meta.get("edge_count_range") != [0, 14]:
        issues.append("graph bounds mismatch")
    if input_meta.get("terminal_count_range") != [1, 5] or input_meta.get("maximum_valid_length") != 50:
        issues.append("terminal or input-length bounds mismatch")
    if workload.get("measurement", {}).get("comparison_model") != "i64_array_scalar_call":
        issues.append("unexpected measurement model")

    cases = workload.get("cases", [])
    if not isinstance(cases, list):
        return issues + ["workload cases must be a list"]
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload contains a non-object case")
            continue
        values = case.get("input_values")
        expected = case.get("expected_result")
        case_id = case.get("id", "<unnamed>")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"fixture input length mismatch: {case_id}")
        if primary_result(values) != expected:
            issues.append(f"primary oracle fixture mismatch: {case_id}")
        if independent_result(values) != expected:
            issues.append(f"independent oracle fixture mismatch: {case_id}")

    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif "steiner_tree_subset_dp" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text in {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")
    readme_path = PACKAGE / "README.md"
    if readme_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        if ("https://oi-wiki.org/graph/steiner-tree/" not in readme
                or "clean-room work" not in readme):
            issues.append("README is missing source provenance or clean-room note")
    rights_path = PACKAGE / "RIGHTS.md"
    if rights_path.is_file():
        rights = rights_path.read_text(encoding="utf-8")
        if ("https://oi-wiki.org/graph/steiner-tree/" not in rights
                or "CC BY-SA 4.0" not in rights or "SATA" not in rights):
            issues.append("rights note is missing source link or license record")
    for name in ("steiner_tree_subset_dp_oracle.py", "steiner_tree_subset_dp_verifier_oracle.py"):
        if not (ROOT / "benchmarks" / name).is_file():
            issues.append(f"missing oracle: {name}")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
