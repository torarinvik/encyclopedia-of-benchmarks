"""Static workload, provenance, and ten-port inventory review."""

from __future__ import annotations

import json
from pathlib import Path
import re

from .independent_oracle import expected_result as independent_expected
from .primary_oracle import (
    MAX_N,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_Q,
    MAX_RESULT,
    MAX_VALID_INPUT_LENGTH,
    expected_result as primary_expected,
)

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "fenwick_tree_in_block_array_rectangle_count"
SOURCE_URL = "https://www.timothywang.ca/OI-wiki/ds/bit-in-block-array/"
EXTENSIONS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED_CASES = {
    "singleton-full-rectangle", "maximum-n-full-rectangle",
    "maximum-q-query-ordinal",
    "nested-block-updates-and-queries", "updates-change-later-query-results",
    "empty-x-and-y-ranges", "update-only", "missing-header", "zero-n",
    "zero-operation-count", "initial-y-out-of-range", "unknown-operation",
    "update-padding-must-be-zero", "inverted-x-range", "inverted-y-range", "truncated-operation",
    "trailing-value", "null-empty-input", "null-parser-limit",
}


def verify_workload(workload: object | None = None) -> list[str]:
    issues: list[str] = []
    required = (
        "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
        "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    )
    for name in required:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    for language, extension in EXTENSIONS.items():
        relative = f"{language}/f/{SYMBOL}.{extension}"
        source = ROOT / relative
        if not source.is_file() or SYMBOL not in source.read_text(encoding="utf-8"):
            issues.append(f"missing exported port: {relative}")

    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return issues + [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return issues + ["workload must be an object"]

    input_meta = workload.get("input")
    output_meta = workload.get("output")
    source_meta = workload.get("source")
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("workload identity or ABI differs")
    if (not isinstance(input_meta, dict)
            or input_meta.get("n_range") != [1, MAX_N]
            or input_meta.get("q_range") != [1, MAX_Q]
            or input_meta.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_meta.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or input_meta.get("invalid_input_result") != -1):
        issues.append("input bounds or framing differ")
    if (not isinstance(output_meta, dict)
            or output_meta.get("result_range") != [0, MAX_RESULT]
            or output_meta.get("invalid_input_result") != -1):
        issues.append("output contract differs")
    if not isinstance(source_meta, dict) or source_meta.get("method_url") != SOURCE_URL:
        issues.append("source metadata differs")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases must be nonempty"]
    seen: set[str] = set()
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
        is_null = case.get("input_is_null", False)
        expected = case.get("expected_result")
        if (not isinstance(values, list) or type(length) is not int
                or type(is_null) is not bool or type(expected) is not int):
            issues.append(f"invalid fixture fields: {case_id}")
            continue
        if (is_null and values) or (not is_null and length != len(values)):
            issues.append(f"invalid fixture framing: {case_id}")
            continue
        if (primary_expected(values, is_null, length) != expected
                or independent_expected(values, is_null, length) != expected):
            issues.append(f"dual-reference mismatch: {case_id}")
    missing = REQUIRED_CASES - seen
    if missing:
        issues.append("missing required cases: " + ", ".join(sorted(missing)))

    readme_path = PACKAGE / "README.md"
    rights_path = PACKAGE / "RIGHTS.md"
    if readme_path.is_file() and rights_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        rights = rights_path.read_text(encoding="utf-8")
        if SOURCE_URL not in readme or SOURCE_URL not in rights:
            issues.append(f"missing source reference: {SOURCE_URL}")
        for language, extension in EXTENSIONS.items():
            target = f"](../../../{language}/f/{SYMBOL}.{extension})"
            if target not in readme:
                issues.append(f"missing README port link: {language}")
        for target in re.findall(r"\]\(([^)]+)\)", readme):
            if target.startswith(("http://", "https://", "#")):
                continue
            if not (PACKAGE / target.split("#", 1)[0]).resolve().is_file():
                issues.append(f"broken README target: {target}")
    return issues


static_issues = verify_workload
