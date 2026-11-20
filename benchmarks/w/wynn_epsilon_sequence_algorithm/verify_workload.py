"""Static workload/reference consistency helper; intentionally not run here."""

from __future__ import annotations

import json
import math
from pathlib import Path

try:
    from .independent_oracle import (
        ABSOLUTE_TOLERANCE as INDEPENDENT_ABS,
        RELATIVE_TOLERANCE as INDEPENDENT_REL,
        MAX_OUTPUT_ELEMENTS as INDEPENDENT_MAX_OUTPUT,
        MAX_PARSEABLE_INPUT_LENGTH as INDEPENDENT_MAX_INPUT,
        WORKSPACE_BYTES as INDEPENDENT_WORKSPACE,
        expected_output as independent_output,
    )
    from .primary_oracle import (
        ABSOLUTE_TOLERANCE,
        MAX_OUTPUT_ELEMENTS,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        RELATIVE_TOLERANCE,
        WORKSPACE_BYTES,
        expected_output,
    )
except ImportError:  # direct package-local invocation
    from independent_oracle import (
        ABSOLUTE_TOLERANCE as INDEPENDENT_ABS,
        RELATIVE_TOLERANCE as INDEPENDENT_REL,
        MAX_OUTPUT_ELEMENTS as INDEPENDENT_MAX_OUTPUT,
        MAX_PARSEABLE_INPUT_LENGTH as INDEPENDENT_MAX_INPUT,
        WORKSPACE_BYTES as INDEPENDENT_WORKSPACE,
        expected_output as independent_output,
    )
    from primary_oracle import (
        ABSOLUTE_TOLERANCE,
        MAX_OUTPUT_ELEMENTS,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        RELATIVE_TOLERANCE,
        WORKSPACE_BYTES,
        expected_output,
    )

PACKAGE = Path(__file__).resolve().parent
SOURCE_URL = "https://dlmf.nist.gov/3.9#E11"
PORTS = (
    "c/w/wynn_epsilon_sequence_algorithm.c",
    "c3/w/wynn_epsilon_sequence_algorithm.c3",
    "cpp/w/wynn_epsilon_sequence_algorithm.cpp",
    "elisa/w/wynn_epsilon_sequence_algorithm.elisa",
    "mojo/w/wynn_epsilon_sequence_algorithm.mojo",
    "nim/w/wynn_epsilon_sequence_algorithm.nim",
    "odin/w/wynn_epsilon_sequence_algorithm.odin",
    "rust/w/wynn_epsilon_sequence_algorithm.rs",
    "v/w/wynn_epsilon_sequence_algorithm.v",
    "zig/w/wynn_epsilon_sequence_algorithm.zig",
)
ROOT = PACKAGE.parents[2]


def _close(left: list[float], right: list[float]) -> bool:
    return len(left) == len(right) and all(
        math.isclose(a, b, rel_tol=RELATIVE_TOLERANCE, abs_tol=ABSOLUTE_TOLERANCE)
        for a, b in zip(left, right)
    )


def workload_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    if (workload.get("algorithm") != "wynn_epsilon_sequence_algorithm"
            or workload.get("function_symbol") != "wynn_epsilon_sequence_algorithm"
            or workload.get("abi") != "float64_slice_io"
            or workload.get("source", {}).get("url") != SOURCE_URL):
        issues.append("workload identity or source citation differs")
    if (workload.get("input", {}).get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("output", {}).get("maximum_elements") != MAX_OUTPUT_ELEMENTS
            or workload.get("output", {}).get("absolute_tolerance") != ABSOLUTE_TOLERANCE
            or workload.get("output", {}).get("relative_tolerance") != RELATIVE_TOLERANCE
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES
            or workload.get("workspace", {}).get("elements") != MAX_OUTPUT_ELEMENTS
            or (INDEPENDENT_MAX_INPUT, INDEPENDENT_MAX_OUTPUT, INDEPENDENT_WORKSPACE,
                INDEPENDENT_ABS, INDEPENDENT_REL) != (
                    MAX_PARSEABLE_INPUT_LENGTH, MAX_OUTPUT_ELEMENTS,
                    WORKSPACE_BYTES, ABSOLUTE_TOLERANCE, RELATIVE_TOLERANCE)):
        issues.append("workload bounds or tolerance metadata differ from references")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases are missing"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("fixture is not a named object")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate fixture ID: {case_id}")
            continue
        seen.add(case_id)
        values = case.get("input_values")
        if not isinstance(values, list):
            issues.append(f"fixture input is not a list: {case_id}")
            continue
        if (case.get("input_length") != len(values)
                and not case.get("input_is_null", False)):
            issues.append(f"fixture frame length differs: {case_id}")
        kwargs = {
            "output_capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        try:
            primary = expected_output(values, **kwargs)
            independent = independent_output(values, **kwargs)
        except (ArithmeticError, ValueError, TypeError, OverflowError) as error:
            issues.append(f"oracle could not classify fixture {case_id}: {error}")
            continue
        expected = case.get("expected_output")
        if (primary[0] != case.get("expected_result")
                or not isinstance(expected, list) or not _close(primary[1], expected)):
            issues.append(f"pinned fixture differs from primary oracle: {case_id}")
        if (independent[0] != primary[0]
                or not _close(independent[1], primary[1])):
            issues.append(f"independent determinant reference differs: {case_id}")
    maximum = next((item for item in cases if isinstance(item, dict)
                    and item.get("id") == "maximum-frame-and-output-singular"), None)
    if (maximum is None or maximum.get("input_length") != MAX_VALID_INPUT_LENGTH
            or maximum.get("expected_result") != MAX_OUTPUT_ELEMENTS
            or len(maximum.get("expected_output", [])) != MAX_OUTPUT_ELEMENTS):
        issues.append("maximum valid frame/output fixture is missing")
    for relative in PORTS:
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing language port: {relative}")
        elif "wynn_epsilon_sequence_algorithm" not in path.read_text(encoding="utf-8"):
            issues.append(f"port entrypoint marker missing: {relative}")
    return issues


def verify_workload() -> int:
    issues = workload_issues()
    if issues:
        raise ValueError("\n".join(issues))
    return len(json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))["cases"])
