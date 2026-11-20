"""Static package inventory and fixture checker for range_union_find."""

from __future__ import annotations

import json
import re
from pathlib import Path

from .independent_oracle import expected_result as independent
from .primary_oracle import expected_result as primary

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/r/range_union_find"
SYMBOL = "range_union_find"
SOURCE_URL = "https://github.com/NyaanNyaan/library/blob/master/data-structure/range-union-find.hpp"
EXTENSIONS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED_CASES = {
    "no-operations", "unite-whole-range", "range-connectivity-and-size",
    "empty-and-singleton-ranges", "overlapping-ranges-skip-merged-boundaries",
    "maximum-valid-frame", "maximum-parseable-trailing-value",
    "truncated-record", "trailing-word", "invalid-opcode",
    "size-query-unused-field", "query-vertex-out-of-range", "null-input",
}


def validate_inventory(workload=None) -> list[str]:
    """Return static inventory or fixture issues without launching any port."""
    issues: list[str] = []
    required_files = (
        "README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
        "independent_oracle.py", "verify_workload.py",
    )
    for name in required_files:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")

    for language, extension in EXTENSIONS.items():
        source_path = ROOT / language / "r" / f"{SYMBOL}.{extension}"
        if not source_path.is_file():
            issues.append(f"missing language source: {language}")
            continue
        source_text = source_path.read_text(encoding="utf-8")
        if SYMBOL not in source_text:
            issues.append(f"missing exported symbol in {language}")

    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return issues + [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return issues + ["workload must be an object"]

    source = workload.get("source", {})
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    measurement = workload.get("measurement", {})
    if (
        workload.get("algorithm") != SYMBOL
        or workload.get("function_symbol") != SYMBOL
        or workload.get("abi") != "i64_array_scalar"
        or source.get("url") != SOURCE_URL
        or source.get("license") != "CC0 1.0; algorithm description only, clean-room implementation"
        or input_spec.get("encoding") != "[n,q,(opcode,a,b)*q]"
        or input_spec.get("n_range") != [1, 32]
        or input_spec.get("q_range") != [0, 32]
        or input_spec.get("maximum_valid_length") != 98
        or input_spec.get("maximum_parseable_length") != 99
        or input_spec.get("invalid_input_result") != -1
        or output_spec.get("result_range") != [0, 16896]
        or output_spec.get("invalid_input_result") != -1
        or measurement.get("comparison_model") != "i64_array_scalar_call"
    ):
        issues.append("workload identity, source, input/output bounds, or measurement differs")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["missing workload cases"]
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
        expected = case.get("expected_result")
        input_is_null = case.get("input_is_null", False)
        if (
            not isinstance(values, list)
            or type(length) is not int
            or length != len(values)
            or type(expected) is not int
            or type(input_is_null) is not bool
            or length > 99
        ):
            issues.append(f"invalid workload case fields: {case_id}")
            continue
        if primary(values, input_is_null, length) != expected:
            issues.append(f"primary-reference fixture mismatch: {case_id}")
        if independent(values, input_is_null, length) != expected:
            issues.append(f"independent-reference fixture mismatch: {case_id}")
    missing = REQUIRED_CASES - seen
    if missing:
        issues.append("missing required cases: " + ", ".join(sorted(missing)))
    if not any(case.get("input_length") == 98 for case in cases if isinstance(case, dict)):
        issues.append("missing maximum valid 98-word frame")
    if not any(case.get("input_length") == 99 for case in cases if isinstance(case, dict)):
        issues.append("missing maximum parseable 99-word frame")

    readme_path = PACKAGE / "README.md"
    if readme_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        for language, extension in EXTENSIONS.items():
            relative = f"../../../{language}/r/{SYMBOL}.{extension}"
            if f"]({relative})" not in readme:
                issues.append(f"README missing source link for {language}")
        if SOURCE_URL not in readme or "range_parallel_unionfind" not in readme or "union_find" not in readme:
            issues.append("README missing provenance or neighboring-algorithm distinction")
        for target in re.findall(r"\[[^\]]+\]\(([^)]+)\)", readme):
            if target.startswith(("http://", "https://", "mailto:")) or target.startswith("#"):
                continue
            local_target = target.split("#", 1)[0]
            if local_target and not (readme_path.parent / local_target).resolve().exists():
                issues.append(f"README link target does not exist: {target}")
    return issues


def review(workload=None) -> None:
    """Raise ValueError if the static package inventory contains an issue."""
    issues = validate_inventory(workload)
    if issues:
        raise ValueError("; ".join(issues))


if __name__ == "__main__":
    review()
