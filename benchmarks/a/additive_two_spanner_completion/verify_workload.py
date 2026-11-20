"""Callable static inventory and additive-distance review."""
from __future__ import annotations

import json
import re
import struct
from pathlib import Path

from .independent_oracle import _floyd, expected_output as independent
from .primary_oracle import (
    MAX_M, MAX_N, MAX_OUTPUT_BYTES, MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH, _parse, expected_output as primary,
)

PACKAGE = Path(__file__).resolve().parent
REPO_ROOT = Path(__file__).resolve().parents[3]
NAME = "additive_two_spanner_completion"
PAPER = "https://doi.org/10.1007/978-3-319-08404-6_24"
LANGUAGES = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED_CASES = {
    "triangle_two_edges", "path_three", "complete_four_star",
    "disconnected_one_edge", "empty_graph", "invalid_loop",
    "invalid_duplicate", "trailing_word", "null_input", "null_output",
    "short_output", "short_empty_output",
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
    input_meta, output_meta, source = workload.get("input"), workload.get("output"), workload.get("source")
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != NAME
            or workload.get("function_symbol") != NAME
            or workload.get("abi") != "i64_array_bytes_output"
            or not isinstance(input_meta, dict)
            or input_meta.get("encoding") != "[n,m,(u,v)*m]"
            or input_meta.get("vertex_count_range") != [1, MAX_N]
            or input_meta.get("edge_count_range") != [0, MAX_M]
            or input_meta.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_meta.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or input_meta.get("simple_graph") is not True
            or input_meta.get("weighted") is not False
            or not isinstance(output_meta, dict)
            or output_meta.get("maximum_bytes") != MAX_OUTPUT_BYTES
            or output_meta.get("output_untouched_on_error") is not True):
        issues.append("identity, bounds, or output contract mismatch")
    if (not isinstance(source, dict)
            or source.get("paper_doi") != "10.1007/978-3-319-08404-6_24"
            or source.get("paper_url") != "https://arxiv.org/abs/1403.0178"
            or "2-spanner completion" not in source.get("algorithm_attribution", "")
            or "clean-room" not in source.get("implementation_status", "")):
        issues.append("source attribution mismatch")

    for language, extension in LANGUAGES.items():
        path = REPO_ROOT / language / "a" / f"{NAME}.{extension}"
        if not path.is_file():
            issues.append(f"missing language port: {language}")
        elif NAME not in path.read_text(encoding="utf-8"):
            issues.append(f"exported symbol missing from: {language}")
    for filename in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                     "independent_oracle.py"):
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package artifact: {filename}")

    readme_path = PACKAGE / "README.md"
    if readme_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        for language, extension in LANGUAGES.items():
            target = f"../../../{language}/a/{NAME}.{extension}"
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
        values, length, capacity = (case.get("input_values"), case.get("input_length"),
                                    case.get("output_capacity"))
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        if (not isinstance(values, list)
                or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                       for value in values)
                or type(length) is not int or not 0 <= length <= MAX_PARSEABLE_INPUT_LENGTH
                or type(capacity) is not int or capacity < 0
                or type(input_is_null) is not bool or type(output_is_null) is not bool
                or (input_is_null and values)
                or (not input_is_null and length != len(values))):
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
            continue
        if expected[0] >= 0:
            full_result, payload = primary(values, MAX_OUTPUT_BYTES, False, False, length)
            parsed = _parse(values)
            if full_result < 0 or parsed is None:
                issues.append(f"valid fixture failed full-capacity encoding: {case_id}")
                continue
            words = struct.unpack("<" + "q" * (len(payload) // 8), payload)
            selected = list(zip(words[1::2], words[2::2]))
            n, edges = parsed
            selected_set = set(selected)
            if (len(selected) != words[0]
                    or len(selected_set) != len(selected)
                    or any(edge not in edges for edge in selected)):
                issues.append(f"output edge inventory mismatch: {case_id}")
                continue
            original_distance = _floyd(n, edges)
            selected_distance = _floyd(n, selected)
            if any(original_distance[a][b] < 99
                   and selected_distance[a][b] > original_distance[a][b] + 2
                   for a in range(n) for b in range(n)):
                issues.append(f"output violates additive stretch two: {case_id}")
    if seen != REQUIRED_CASES:
        issues.append("fixture inventory mismatch")
    return issues


def verify(workload: object | None = None) -> bool:
    issues = static_issues(workload)
    if issues:
        raise ValueError("; ".join(issues))
    return True


if __name__ == "__main__":
    verify()
