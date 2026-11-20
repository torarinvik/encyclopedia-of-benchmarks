"""Static package metadata, fixture, reference, and port validator; not run."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import expected_result as independent_result
    from .primary_oracle import expected_result as primary_result
except ImportError:
    from independent_oracle import expected_result as independent_result
    from primary_oracle import expected_result as primary_result

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
INDEX_URL = (
    "https://github.com/acmeism/RosettaCodeData/blob/"
    "1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks"
)
MAX_RESULT = 2_432_902_008_176_640_000

PORTS = {
    "c": "c/r/random_permutation_cycle_cap_count.c",
    "c3": "c3/r/random_permutation_cycle_cap_count.c3",
    "cpp": "cpp/r/random_permutation_cycle_cap_count.cpp",
    "elisa": "elisa/r/random_permutation_cycle_cap_count.elisa",
    "mojo": "mojo/r/random_permutation_cycle_cap_count.mojo",
    "nim": "nim/r/random_permutation_cycle_cap_count.nim",
    "odin": "odin/r/random_permutation_cycle_cap_count.odin",
    "rust": "rust/r/random_permutation_cycle_cap_count.rs",
    "v": "v/r/random_permutation_cycle_cap_count.v",
    "zig": "zig/r/random_permutation_cycle_cap_count.zig",
}

NULL_GUARDS = {
    "c": "input == NULL",
    "c3": "input == null",
    "cpp": "input == nullptr",
    "elisa": "input.is_null()",
    "mojo": "UnsafePointer[Int64, ImmutAnyOrigin]()",
    "nim": "input == nil",
    "odin": "input == nil",
    "rust": "input.is_null()",
    "v": "input == nil",
    "zig": "input == null",
}

REQUIRED_CASE_RESULTS = {
    "one_label": 1,
    "two_labels_singletons_only": 1,
    "two_labels_all_cycles_allowed": 2,
    "three_labels_cap_one": 1,
    "three_labels_cap_two": 4,
    "four_labels_involutions": 10,
    "four_labels_cap_three": 18,
    "four_labels_all_cycles_allowed": 24,
    "five_labels_involutions": 26,
    "five_labels_cap_three": 66,
    "six_labels_cap_three": 276,
    "twenty_labels_cap_one": 1,
    "maximum_exact_result_twenty_factorial": MAX_RESULT,
    "zero_n_invalid": -1,
    "negative_n_invalid": -1,
    "zero_cycle_cap_invalid": -1,
    "cycle_cap_above_n_invalid": -1,
    "n_above_bound_invalid": -1,
    "missing_cycle_cap_invalid": -1,
    "empty_frame_invalid": -1,
    "trailing_value_invalid": -1,
    "signed_minimum_invalid": -1,
    "signed_maximum_invalid": -1,
    "null_input_invalid": -1,
}


def workload_issues(workload: dict | None = None) -> list[str]:
    issues: list[str] = []
    if workload is None:
        try:
            data = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload: {error}"]
    else:
        data = workload
    if not isinstance(data, dict):
        return ["workload root must be a JSON object"]

    if (data.get("schema_version") != 1
            or data.get("id") != "random-permutation-cycle-cap-count-i64-array-scalar-v1"
            or data.get("algorithm") != "random_permutation_cycle_cap_count"
            or data.get("function_symbol") != "random_permutation_cycle_cap_count"
            or data.get("abi") != "i64_array_scalar"):
        issues.append("workload identity or ABI differs")

    source = data.get("source", {})
    if not isinstance(source, dict):
        source = {}
    if (source.get("discovery_title") != "100-prisoners"
            or source.get("discovery_score") != 95
            or source.get("discovery_index") != INDEX_URL):
        issues.append("title, index score, or pinned index provenance differs")
    discovery_note = source.get("discovery_note", "")
    if not isinstance(discovery_note, str) or "title" not in discovery_note.lower() \
            or "only" not in discovery_note.lower():
        issues.append("discovery note must identify title-only use")
    method_urls = source.get("method_urls")
    if (not isinstance(method_urls, list)
            or "https://doi.org/10.1007/BF02986999" not in method_urls
            or source.get("implementation_status") != "clean-room bounded profile"):
        issues.append("method source or clean-room status differs")

    input_meta = data.get("input", {})
    if not isinstance(input_meta, dict):
        input_meta = {}
    if (input_meta.get("kind") != "signed_64_bit_integer_array"
            or input_meta.get("encoding") != "[n,k]"
            or input_meta.get("exact_length") != 2
            or input_meta.get("maximum_valid_length") != 2
            or input_meta.get("maximum_parseable_length") != 3
            or input_meta.get("n_range") != [1, 20]
            or input_meta.get("k_constraint") != "1 <= k <= n"
            or input_meta.get("invalid_input_result") != -1
            or input_meta.get("null_input_result") != -1):
        issues.append("input contract differs")
    output_meta = data.get("output", {})
    if not isinstance(output_meta, dict):
        output_meta = {}
    if (output_meta.get("kind") != "signed_64_bit_integer"
            or output_meta.get("maximum_result") != MAX_RESULT
            or output_meta.get("maximum_result_definition") != "20!"
            or output_meta.get("invalid_input_result") != -1):
        issues.append("output bounds differ")
    complexity = data.get("complexity", {})
    if not isinstance(complexity, dict):
        complexity = {}
    if (complexity.get("primary_time") != "O(n * min(n,k))"
            or complexity.get("primary_space") != "O(n)"
            or complexity.get("primary_recurrence") !=
            "C[0]=1; C[s]=sum for j=1..min(s,k) of (s-1)!/(s-j)! * C[s-j]"):
        issues.append("primary recurrence or complexity differs")

    cases = data.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases are missing"]
    seen: set[str] = set()
    actual_results: dict[str, int] = {}
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("fixture is not a named object")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate fixture id: {case_id}")
            continue
        seen.add(case_id)

        values = case.get("input_values")
        length = case.get("input_length")
        is_null = case.get("input_is_null", False)
        expected = case.get("expected_result")
        if (not isinstance(values, list)
                or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                       for value in values)
                or type(length) is not int
                or type(is_null) is not bool
                or type(expected) is not int):
            issues.append(f"{case_id}: invalid fixture field types")
            continue
        if length != len(values):
            issues.append(f"{case_id}: input length does not frame its values")
        primary = primary_result(values, is_null, length)
        independent = independent_result(values, is_null, length)
        if primary != independent:
            issues.append(f"{case_id}: independent references disagree")
        if expected != primary:
            issues.append(f"{case_id}: fixture result differs from reference")
        actual_results[case_id] = expected

    for case_id, expected in REQUIRED_CASE_RESULTS.items():
        if actual_results.get(case_id) != expected:
            issues.append(f"required fixture missing or changed: {case_id}")

    for language, relative_path in PORTS.items():
        path = ROOT / relative_path
        if not path.is_file():
            issues.append(f"missing {language} port: {relative_path}")
            continue
        text = path.read_text(encoding="utf-8")
        if "random_permutation_cycle_cap_count" not in text:
            issues.append(f"{language} port does not declare its ABI symbol")
        guard = NULL_GUARDS[language]
        if guard not in text:
            issues.append(f"{language} port is missing its null-input guard")

    for name in ("README.md", "RIGHTS.md", "INVENTORY.md"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    return issues
