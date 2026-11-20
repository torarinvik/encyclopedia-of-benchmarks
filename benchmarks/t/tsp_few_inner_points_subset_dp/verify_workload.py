"""Callable static inventory and independent-reference review."""
from __future__ import annotations

import json
import re
from pathlib import Path

from .independent_oracle import expected_output as independent
from .primary_oracle import (
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    expected_output as primary,
)

PACKAGE = Path(__file__).resolve().parent
REPO_ROOT = Path(__file__).resolve().parents[3]
NAME = "tsp_few_inner_points_subset_dp"
LANGUAGES = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED_CASES = {
    "three-four-five-convex-triangle", "square-with-no-inner-points",
    "triangle-with-one-interior-point", "square-with-one-center-point",
    "triangle-with-two-interior-points", "square-with-inner-point-in-first-hull-gap",
    "too-few-hull-points", "trailing-word",
    "insufficient-output-capacity", "null-output", "null-input",
}


def static_issues(workload: object | None = None) -> list[str]:
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, ValueError) as error:
            return [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return ["workload must be an object"]

    issues: list[str] = []
    source = workload.get("source")
    input_meta = workload.get("input")
    output_meta = workload.get("output")
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != NAME
            or workload.get("function_symbol") != NAME
            or workload.get("abi") != "i64_array_bytes_output"
            or not isinstance(source, dict)
            or source.get("chapter_url") != "https://doi.org/10.1007/978-1-4939-2864-4_426"
            or source.get("paper_url") != "https://dopal.cs.uec.ac.jp/okamotoy/PDF/2006/FINALfewTSP.pdf"
            or "second fixed-parameter algorithm" not in source.get("algorithm_attribution", "")
            or "first hull gap" not in source.get("algorithm_attribution", "")
            or not isinstance(input_meta, dict)
            or input_meta.get("encoding", "").startswith("[n,k,outer_ids") is not True
            or input_meta.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_meta.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or not isinstance(output_meta, dict)
            or output_meta.get("maximum_bytes") != MAX_OUTPUT_BYTES
            or output_meta.get("output_untouched_on_error") is not True
            or workload.get("workspace", {}).get("bytes") != 8192):
        issues.append("identity, source, bounds, or output contract mismatch")

    for language, extension in LANGUAGES.items():
        port = REPO_ROOT / language / "t" / f"{NAME}.{extension}"
        if not port.is_file():
            issues.append(f"missing language port: {language}")
        elif NAME not in port.read_text(encoding="utf-8"):
            issues.append(f"exported symbol missing from: {language}")

    readme_path = PACKAGE / "README.md"
    if readme_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        for language, extension in LANGUAGES.items():
            target = f"../../../{language}/t/{NAME}.{extension}"
            if f"]({target})" not in readme:
                issues.append(f"README port target missing: {language}")
        for target in re.findall(r"\]\(([^)]+)\)", readme):
            if target.startswith(("http://", "https://", "#")):
                continue
            if not (PACKAGE / target).resolve().is_file():
                issues.append(f"README local target does not resolve: {target}")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["fixture cases are missing"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("malformed fixture record")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate fixture id: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        capacity = case.get("output_capacity")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        if (not isinstance(values, list)
                or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                       for value in values)
                or type(length) is not int or not 0 <= length <= MAX_PARSEABLE_INPUT_LENGTH
                or type(capacity) is not int or capacity < 0
                or type(input_is_null) is not bool or type(output_is_null) is not bool
                or input_is_null and values
                or not input_is_null and length != len(values)):
            issues.append(f"invalid fixture framing: {case_id}")
            continue
        try:
            expected = (case["expected_result"], bytes.fromhex(case["expected_output_hex"]))
        except (KeyError, TypeError, ValueError):
            issues.append(f"invalid expected output: {case_id}")
            continue
        args = (values, capacity, output_is_null, input_is_null, length)
        if type(expected[0]) is not int or primary(*args) != expected or independent(*args) != expected:
            issues.append(f"oracle/fixture disagreement: {case_id}")
    if seen != REQUIRED_CASES:
        issues.append("fixture inventory mismatch")
    return issues


def verify(workload: object | None = None) -> bool:
    issues = static_issues(workload)
    if issues:
        raise ValueError("; ".join(issues))
    return True
