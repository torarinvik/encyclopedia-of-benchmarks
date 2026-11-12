"""Static inventory and fixture review for common tangent count ports."""

from __future__ import annotations

import json
from pathlib import Path

from common_tangents_two_circles_oracle import (
    MAX_COORDINATE,
    MAX_INPUT_LENGTH,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_RADIUS,
    expected_result as primary_result,
)
from common_tangents_two_circles_verifier_oracle import (
    MAX_INPUT_LENGTH as INDEPENDENT_MAX_INPUT_LENGTH,
    MAX_PARSEABLE_INPUT_LENGTH as INDEPENDENT_MAX_PARSEABLE_INPUT_LENGTH,
    expected_result as independent_result,
)

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/c/common_tangents_two_circles"
PORTS = {
    "c": ROOT / "c/c/common_tangents_two_circles.c",
    "c3": ROOT / "c3/c/common_tangents_two_circles.c3",
    "cpp": ROOT / "cpp/c/common_tangents_two_circles.cpp",
    "elisa": ROOT / "elisa/c/common_tangents_two_circles.elisa",
    "mojo": ROOT / "mojo/c/common_tangents_two_circles.mojo",
    "nim": ROOT / "nim/c/common_tangents_two_circles.nim",
    "odin": ROOT / "odin/c/common_tangents_two_circles.odin",
    "rust": ROOT / "rust/c/common_tangents_two_circles.rs",
    "v": ROOT / "v/c/common_tangents_two_circles.v",
    "zig": ROOT / "zig/c/common_tangents_two_circles.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]

    if workload.get("algorithm") != "common_tangents_two_circles":
        issues.append("unexpected algorithm name")
    if workload.get("function_symbol") != "common_tangents_two_circles":
        issues.append("unexpected exported symbol")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("unexpected ABI")
    if workload.get("source", {}).get("url") != "https://cp-algorithms.com/geometry/tangents-to-two-circles.html":
        issues.append("source URL mismatch")
    input_contract = workload.get("input", {})
    if input_contract.get("center_coordinate_range") != [-MAX_COORDINATE, MAX_COORDINATE]:
        issues.append("center-coordinate bounds mismatch")
    if input_contract.get("radius_range") != [0, MAX_RADIUS]:
        issues.append("radius bounds mismatch")
    if input_contract.get("maximum_valid_length") != MAX_INPUT_LENGTH:
        issues.append("maximum valid input length mismatch")
    if input_contract.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH:
        issues.append("maximum parseable input length mismatch")
    if input_contract.get("exact_length") != MAX_INPUT_LENGTH:
        issues.append("exact input length mismatch")
    if (INDEPENDENT_MAX_INPUT_LENGTH, INDEPENDENT_MAX_PARSEABLE_INPUT_LENGTH) != (
        MAX_INPUT_LENGTH,
        MAX_PARSEABLE_INPUT_LENGTH,
    ):
        issues.append("primary and independent input-length bounds differ")
    if workload.get("output", {}).get("valid_range") != [0, 4]:
        issues.append("tangent-count output range mismatch")

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
        expected = case.get("expected_result")
        if primary_result(values) != expected:
            issues.append(f"primary oracle fixture mismatch: {case_id}")
        if independent_result(values) != expected:
            issues.append(f"independent oracle fixture mismatch: {case_id}")

    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif "common_tangents_two_circles" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")

    readme_path = PACKAGE / "README.md"
    if readme_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        if "https://cp-algorithms.com/geometry/tangents-to-two-circles.html" not in readme:
            issues.append("README missing the algorithm source")
    elisa = PORTS["elisa"]
    if elisa.is_file():
        source = elisa.read_text(encoding="utf-8")
        if "view[i64]" not in source or "input: i64&" not in source:
            issues.append("Elisa must use safe views internally and refs only at its exported ABI")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
