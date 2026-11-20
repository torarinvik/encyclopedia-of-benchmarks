"""Callable static workload and reference review for the 3D Bird–Baker profile."""
from __future__ import annotations

import json
import re
import struct
from pathlib import Path

from .independent_oracle import expected_output as independent
from .primary_oracle import (
    MAX_DIMENSION, MAX_OUTPUT_BYTES, MAX_PARSEABLE_INPUT_LENGTH,
    MAX_PATTERN_DIMENSION, MAX_VALID_INPUT_LENGTH,
    expected_output as primary,
)

PACKAGE = Path(__file__).resolve().parent
REPO_ROOT = Path(__file__).resolve().parents[2]
NAME = "three_dimensional_bird_baker_matching"
LANGUAGES = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED_CASES = {
    "exact_two_by_two_by_two_match",
    "one_cell_pattern_maximal_overlap_and_coordinate_order",
    "repeated_slice_kmp_overlapping_depth_matches",
    "valid_pattern_with_no_matches", "pattern_exceeds_text_row_dimension",
    "symbol_outside_alphabet", "trailing_input_word", "null_input",
    "null_output", "short_output",
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
    input_meta = workload.get("input")
    output_meta = workload.get("output")
    source = workload.get("source")
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != NAME
            or workload.get("function_symbol") != NAME
            or workload.get("abi") != "i64_array_bytes_output"
            or not isinstance(input_meta, dict)
            or input_meta.get("encoding") != "[text_rows,text_columns,text_depth,pattern_rows,pattern_columns,pattern_depths,text_depth_major_row_major,pattern_depth_major_row_major]"
            or input_meta.get("text_dimension_range") != [1, MAX_DIMENSION]
            or input_meta.get("pattern_dimension_range") != [1, MAX_PATTERN_DIMENSION]
            or input_meta.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_meta.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or input_meta.get("pattern_not_larger_than_text") is not True
            or not isinstance(output_meta, dict)
            or output_meta.get("encoding") != "[match_count,(zero_based_row,zero_based_column,zero_based_depth)*match_count]"
            or output_meta.get("maximum_bytes") != MAX_OUTPUT_BYTES
            or output_meta.get("coordinate_order") != "lexicographic row, then column, then depth"
            or output_meta.get("output_untouched_on_error") is not True):
        issues.append("identity, bounds, or output contract mismatch")
    if (not isinstance(source, dict)
            or source.get("reference") != "Encyclopedia of Algorithms, DOI 10.1007/978-1-4939-2864-4_247"
            or "repeated" not in source.get("algorithm_attribution", "")):
        issues.append("source attribution mismatch")

    for language, extension in LANGUAGES.items():
        path = REPO_ROOT / language / "t" / f"{NAME}.{extension}"
        if not path.is_file():
            issues.append(f"missing language port: {language}")
        elif NAME not in path.read_text(encoding="utf-8"):
            issues.append(f"exported symbol missing from: {language}")
    for filename in ("README.md", "INVENTORY.md", "RIGHTS.md", "workload.json",
                     "primary_oracle.py", "independent_oracle.py",
                     "verify_workload.py", "check_inventory.py"):
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package artifact: {filename}")

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
        if (type(expected[0]) is not int or primary(*args) != expected
                or independent(*args) != expected):
            issues.append(f"oracle/fixture disagreement: {case_id}")
            continue
        if expected[0] >= 0:
            if expected[0] > MAX_OUTPUT_BYTES or expected[0] != len(expected[1]):
                issues.append(f"successful output exceeds bounds: {case_id}")
                continue
            words = struct.unpack("<" + "q" * (len(expected[1]) // 8), expected[1])
            coordinates = [tuple(words[index:index + 3])
                           for index in range(1, len(words), 3)]
            if (len(words) != 1 + 3 * words[0]
                    or len(coordinates) != words[0]
                    or coordinates != sorted(set(coordinates))):
                issues.append(f"result frame/order mismatch: {case_id}")
    if seen != REQUIRED_CASES:
        issues.append("fixture inventory mismatch")
    return issues


def validate_workload(workload: dict) -> None:
    issues = static_issues(workload)
    if issues:
        raise ValueError("; ".join(issues))


if __name__ == "__main__":
    validate_workload(json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8")))
