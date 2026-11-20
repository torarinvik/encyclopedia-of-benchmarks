"""Static package, port, link, and fixture inventory for the bounded profile."""

from __future__ import annotations

import json
import re
from pathlib import Path

from .independent_oracle import expected_result as cut_reference
from .primary_oracle import (
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_RESULT,
    MAX_VALID_INPUT_LENGTH,
    expected_result as round_reference,
)

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/s/synchronous_round_push_relabel"
SYMBOL = "synchronous_round_push_relabel"
SOURCE_PAPER = "https://doi.org/10.1007/978-3-662-48350-3_10"
PORTS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED_CASES = {
    "single-path-bottleneck", "multi-round-chain", "two-routes-with-round-barrier", "antiparallel-arcs",
    "sink-unreachable", "no-arcs", "parallel-source-sink-maximum", "invalid-self-loop",
    "invalid-capacity", "invalid-source", "trailing-word", "null-input",
    "null-at-parser-limit",
}


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                 "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")

    for language, extension in PORTS.items():
        path = ROOT / language / "s" / f"{SYMBOL}.{extension}"
        if not path.is_file():
            issues.append(f"missing language port: {language}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text in {language}")

    try:
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        for target in re.findall(r"\]\(([^)]+)\)", readme):
            if target.startswith(("https://", "http://", "#")):
                continue
            if not (PACKAGE / target).resolve().is_file():
                issues.append(f"unresolved README target: {target}")
        if SOURCE_PAPER not in readme or "Section 3.1" not in readme:
            issues.append("README is missing paper attribution or profile scope")
    except OSError as error:
        issues.append(f"cannot read README: {error}")

    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return issues + [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return issues + ["workload must be an object"]
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    profile = workload.get("algorithm_profile", {})
    source = workload.get("source", {})
    if not all(isinstance(section, dict) for section in (input_spec, output_spec, profile, source)):
        return issues + ["workload metadata sections must be objects"]
    if (workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"
            or source.get("paper_doi") != SOURCE_PAPER
            or input_spec.get("maximum_valid_input_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_input_length") != MAX_PARSEABLE_INPUT_LENGTH
            or output_spec.get("valid_result_range") != [0, MAX_RESULT]
            or output_spec.get("invalid_input_result") != -1
            or "round_barriers" not in profile or "excluded_heuristics" not in profile):
        issues.append("workload identity, ABI, bounds, source, or profile differs")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["missing workload cases"]
    seen: set[str] = set()
    maximum_seen = False
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid workload case")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate workload case: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        expected = case.get("expected_result")
        input_is_null = case.get("input_is_null", False)
        if (not isinstance(values, list) or type(length) is not int
                or type(expected) is not int or type(input_is_null) is not bool
                or (input_is_null and (values or not 0 <= length <= MAX_PARSEABLE_INPUT_LENGTH))
                or (not input_is_null and (length != len(values)
                                           or length > MAX_PARSEABLE_INPUT_LENGTH))):
            issues.append(f"invalid workload framing: {case_id}")
            continue
        if case_id == "parallel-source-sink-maximum":
            maximum_seen = length == MAX_VALID_INPUT_LENGTH and expected == MAX_RESULT
        if round_reference(values, input_is_null, length) != expected:
            issues.append(f"synchronous reference mismatch: {case_id}")
        if cut_reference(values, input_is_null, length) != expected:
            issues.append(f"cut reference mismatch: {case_id}")

    missing = REQUIRED_CASES - seen
    if missing:
        issues.append("missing required cases: " + ", ".join(sorted(missing)))
    if not maximum_seen:
        issues.append("maximum valid frame and result fixture is missing")
    return issues


def verify(workload=None) -> list[str]:
    return verify_workload(workload)


if __name__ == "__main__":
    for issue in verify_workload():
        print(issue)
