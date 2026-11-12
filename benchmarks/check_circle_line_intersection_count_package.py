"""Static inventory and fixture review for circle-line intersection ports."""

from __future__ import annotations

import json
from pathlib import Path

from circle_line_intersection_count_oracle import expected_output as primary_output
from circle_line_intersection_count_verifier_oracle import expected_output as independent_output

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/c/circle_line_intersection_count"
PORTS = {
    "c": ROOT / "c/c/circle_line_intersection_count.c",
    "c3": ROOT / "c3/c/circle_line_intersection_count.c3",
    "cpp": ROOT / "cpp/c/circle_line_intersection_count.cpp",
    "elisa": ROOT / "elisa/c/circle_line_intersection_count.elisa",
    "mojo": ROOT / "mojo/c/circle_line_intersection_count.mojo",
    "nim": ROOT / "nim/c/circle_line_intersection_count.nim",
    "odin": ROOT / "odin/c/circle_line_intersection_count.odin",
    "rust": ROOT / "rust/c/circle_line_intersection_count.rs",
    "v": ROOT / "v/c/circle_line_intersection_count.v",
    "zig": ROOT / "zig/c/circle_line_intersection_count.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]

    if workload.get("algorithm") != "circle_line_intersection_count":
        issues.append("unexpected algorithm name")
    if workload.get("function_symbol") != "circle_line_intersection_count":
        issues.append("unexpected exported symbol")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("unexpected ABI")

    input_contract = workload.get("input", {})
    if input_contract.get("query_count_range") != [0, 32]:
        issues.append("query-count bounds mismatch")
    if input_contract.get("maximum_valid_length") != 100:
        issues.append("maximum valid input length mismatch")
    if input_contract.get("maximum_parseable_length") != 101:
        issues.append("maximum parseable input length mismatch")
    output_contract = workload.get("output", {})
    if output_contract.get("maximum_bytes") != 256:
        issues.append("maximum output size mismatch")
    if workload.get("workspace", {}).get("bytes", 0) < 256:
        issues.append("workspace output capacity is too small")

    cases = workload.get("cases", [])
    if not isinstance(cases, list):
        return issues + ["workload cases must be a list"]
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload contains a non-object case")
            continue
        values = case.get("input_values")
        case_id = case.get("id", "<unnamed>")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"fixture input length mismatch: {case_id}")
            continue
        arguments = {
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
        }
        expected = (case.get("expected_result"), bytes.fromhex(case.get("expected_output_hex", "")))
        if primary_output(values, **arguments) != expected:
            issues.append(f"primary oracle fixture mismatch: {case_id}")
        if independent_output(values, **arguments) != expected:
            issues.append(f"independent oracle fixture mismatch: {case_id}")

    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif "circle_line_intersection_count" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    source_url = "https://cp-algorithms.com/geometry/circle-line-intersection.html"
    if source_url not in readme:
        issues.append("README missing algorithm source")
    elisa = PORTS["elisa"]
    if elisa.is_file():
        source = elisa.read_text(encoding="utf-8")
        if ("input: view[i64]" not in source or "output: mutable view[u8]" not in source
                or "input: i64&" not in source or "output: mutable u8&" not in source):
            issues.append("Elisa must use internal safe views and refs only at the exported ABI")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
