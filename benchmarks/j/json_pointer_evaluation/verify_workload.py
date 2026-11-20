"""Static fixture and independent-reference checks; intentionally not run."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as independent_result
from .primary_oracle import (
    MAX_NODES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_POINTER_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    RECORD_WORDS,
    WORKSPACE_BYTES,
    expected_result as primary_result,
)

PACKAGE = Path(__file__).resolve().parent
REQUIRED_CASES = {
    "root-empty-pointer", "object-member-a", "array-index-one",
    "escaped-slash-and-tilde", "malformed-tilde-escape",
    "malformed-after-missing-member", "scalar-traversal-unresolved",
}


def _record(kind: int, parent: int, *, key: str = "", index: int = -1,
            payload: int = 0) -> list[int]:
    codes = list(key.encode("ascii"))
    if len(codes) > 16:
        raise ValueError("fixture key exceeds the documented bound")
    return [kind, parent, len(codes), *codes, *([0] * (16 - len(codes))), index, payload]


def _frame(nodes: list[list[int]], pointer: str, root: int = 0) -> list[int]:
    encoded = list(pointer.encode("ascii"))
    return [len(nodes), root, len(encoded), *encoded, *(word for row in nodes for word in row)]


def _reference_cases() -> list[tuple[str, list[int], int]]:
    obj = _record(0, -1)
    scalar = lambda parent, key="", value=1: _record(2, parent, key=key,
                                                       index=-1, payload=value)
    array = _record(1, -1)
    return [
        ("tilde-zero-before-one", _frame([obj, scalar(0, "~1")], "/~01"), 1),
        ("empty-object-key", _frame([obj, scalar(0, "")], "/"), 1),
        ("missing-object-member", _frame([obj], "/absent"), -2),
        ("ambiguous-duplicate-key", _frame([obj, scalar(0, "k"), scalar(0, "k")], "/k"), -2),
        ("malformed-after-missing-member", _frame([obj], "/missing/~"), -1),
        ("array-leading-zero", _frame([array, _record(2, 0, index=0)], "/00"), -2),
        ("array-dash", _frame([array, _record(2, 0, index=0)], "/-"), -2),
        ("array-out-of-range", _frame([array, _record(2, 0, index=0)], "/1"), -2),
        ("bad-array-index", _frame([array, _record(2, 0, index=0)], "/1x"), -2),
        ("malformed-trailing-tilde", _frame([obj], "/key~"), -1),
        ("scalar-intermediate", _frame([obj, scalar(0, "leaf")], "/leaf/x"), -2),
        ("array-index-zero", _frame([array, _record(2, 0, index=0)], "/0"), 1),
        ("root-selection", _frame([_record(2, -1, payload=9)], ""), 0),
    ]


def workload_issues() -> list[str]:
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    issues: list[str] = []
    if (workload.get("algorithm") != "json_pointer_evaluation"
            or workload.get("function_symbol") != "json_pointer_evaluation"
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("workload identity or ABI differs from the package")
    input_spec = workload.get("input", {})
    expected_max = 3 + MAX_POINTER_LENGTH + MAX_NODES * RECORD_WORDS
    if (input_spec.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or expected_max != MAX_VALID_INPUT_LENGTH
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES):
        issues.append("frame or workspace bounds differ from the implementation")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload has no fixtures"]
    found: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("workload contains an unnamed case")
            continue
        name = case["id"]
        if name in found:
            issues.append(f"duplicate fixture ID: {name}")
        found.add(name)
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"fixture length is inconsistent: {name}")
            continue
        options = {
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        primary = primary_result(values, **options)
        independent = independent_result(values, **options)
        if primary != independent:
            issues.append(f"references disagree: {name}")
        if primary != case.get("expected_result"):
            issues.append(f"fixture differs from references: {name}")
    if not REQUIRED_CASES.issubset(found):
        issues.append(f"missing cases: {sorted(REQUIRED_CASES - found)}")

    for name, values, expected in _reference_cases():
        primary = primary_result(values)
        independent = independent_result(values)
        if primary != independent or primary != expected:
            issues.append(f"generated reference case disagrees: {name}")
    malformed_frames = [
        ("trailing-word", [1, 0, 0, *_record(2, -1, payload=3), 99], -1),
        ("self-parent", _frame([_record(0, -1), _record(2, 1)], ""), -1),
        ("duplicate-array-index", _frame([
            _record(1, -1),
            _record(2, 0, index=0),
            _record(2, 0, index=0),
        ], "/0"), -1),
        ("non-ascii-pointer", [1, 0, 1, 128, *_record(2, -1)], -1),
    ]
    for name, values, expected in malformed_frames:
        if primary_result(values) != expected or independent_result(values) != expected:
            issues.append(f"malformed reference case disagrees: {name}")
    return issues


if __name__ == "__main__":
    problems = workload_issues()
    if problems:
        raise SystemExit("workload issues: " + "; ".join(problems))
