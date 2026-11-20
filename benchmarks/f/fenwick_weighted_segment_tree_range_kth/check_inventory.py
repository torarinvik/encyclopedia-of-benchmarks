"""Static metadata, fixture, documentation, and ten-port review."""

from __future__ import annotations

import json
from pathlib import Path
import re

from .independent_oracle import expected_result as independent_expected
from .primary_oracle import (
    MAX_N, MAX_Q, MAX_PARSEABLE_INPUT_LENGTH, MAX_VALID_INPUT_LENGTH,
    expected_result as primary_expected,
)

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "fenwick_weighted_segment_tree_range_kth"
SOURCE_URL = "https://www.timothywang.ca/OI-wiki/ds/seg-in-bit/"
EXTENSIONS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED_CASES = {
    "no-operations", "single-value-query", "replacement-changes-query-answer",
    "duplicates-negative-values-and-range-offset", "updates-only",
    "maximum-valid-frame-and-query-ordinal", "invalid-query-rank",
    "empty-query-range", "invalid-update-padding", "replacement-outside-value-domain",
    "unknown-operation", "truncated-operation", "trailing-word", "null-input",
}


def verify_inventory(workload: object | None = None) -> list[str]:
    issues: list[str] = []
    for name in (
        "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
        "primary_oracle.py", "independent_oracle.py", "check_inventory.py",
    ):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")

    for language, extension in EXTENSIONS.items():
        relative = f"{language}/f/{SYMBOL}.{extension}"
        source = ROOT / relative
        if not source.is_file():
            issues.append(f"missing source port: {relative}")
        elif SYMBOL not in source.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {relative}")

    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return issues + [f"cannot read workload metadata: {error}"]
    if not isinstance(workload, dict):
        return issues + ["workload must be an object"]

    input_meta = workload.get("input")
    if not isinstance(input_meta, dict):
        return issues + ["input metadata must be an object"]
    if (input_meta.get("n_range") != [1, MAX_N]
            or input_meta.get("operation_count_range") != [0, MAX_Q]
            or input_meta.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_meta.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH):
        issues.append("input metadata differs from oracle limits")
    if workload.get("function_symbol") != SYMBOL or workload.get("abi") != "i64_array_scalar":
        issues.append("symbol or ABI metadata differs")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases must be nonempty"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid fixture record")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate fixture id: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        is_null = case.get("input_is_null", False)
        expected = case.get("expected_result")
        if (not isinstance(values, list) or type(length) is not int
                or type(is_null) is not bool or type(expected) is not int):
            issues.append(f"malformed fixture fields: {case_id}")
            continue
        if (is_null and values) or (not is_null and length != len(values)):
            issues.append(f"malformed fixture framing: {case_id}")
            continue
        if (primary_expected(values, is_null, length) != expected
                or independent_expected(values, is_null, length) != expected):
            issues.append(f"oracle disagreement with fixture: {case_id}")
    missing = REQUIRED_CASES - seen
    if missing:
        issues.append("missing fixtures: " + ", ".join(sorted(missing)))

    readme = PACKAGE / "README.md"
    rights = PACKAGE / "RIGHTS.md"
    if readme.is_file() and rights.is_file():
        readme_text = readme.read_text(encoding="utf-8")
        rights_text = rights.read_text(encoding="utf-8")
        if SOURCE_URL not in readme_text or SOURCE_URL not in rights_text:
            issues.append(f"missing algorithm source reference: {SOURCE_URL}")
        for language, extension in EXTENSIONS.items():
            link = f"](../../../{language}/f/{SYMBOL}.{extension})"
            if link not in readme_text:
                issues.append(f"missing README source link: {language}")
        for target in re.findall(r"\]\(([^)]+)\)", readme_text):
            if target.startswith(("http://", "https://", "#")):
                continue
            if not (PACKAGE / target.split("#", 1)[0]).resolve().is_file():
                issues.append(f"broken README target: {target}")
    return issues


static_issues = verify_inventory
