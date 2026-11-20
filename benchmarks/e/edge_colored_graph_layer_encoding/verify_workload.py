"""Callable static inventory and oracle review for the edge-color reduction."""
from __future__ import annotations

import json
import re
import struct
from pathlib import Path

from .independent_oracle import expected_output as independent
from .primary_oracle import (
    MAX_M, MAX_N, MAX_OUTPUT_BYTES, MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH, WORKSPACE_BYTES, _parse, expected_output as primary,
)

PACKAGE = Path(__file__).resolve().parent
REPO_ROOT = Path(__file__).resolve().parents[3]
NAME = "edge_colored_graph_layer_encoding"
LANGUAGES = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED_CASES = {
    "two_layers_all_bits_and_threads", "one_layer_two_edges",
    "three_layers_sparse_color_bits", "zero_edges_keeps_threads",
    "permuted_edge_records", "duplicate_unordered_edge_invalid",
    "loop_invalid", "invalid_vertex_color", "null_input", "null_output",
    "short_output",
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
            or not isinstance(input_meta, dict)
            or input_meta.get("encoding") != "[n,m,d,q,vertex_colors[n],(u,v,edge_color)*m]"
            or input_meta.get("vertex_count_range") != [1, MAX_N]
            or input_meta.get("edge_count_range") != [0, MAX_M]
            or input_meta.get("edge_color_layer_range") != [1, 3]
            or input_meta.get("vertex_color_class_range") != [1, 3]
            or input_meta.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_meta.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or input_meta.get("simple_undirected_graph") is not True
            or not isinstance(output_meta, dict)
            or output_meta.get("encoding") != "[N,K,vertex_colors[N],(u,v)*K]"
            or output_meta.get("maximum_bytes") != MAX_OUTPUT_BYTES
            or output_meta.get("output_untouched_on_error") is not True
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES):
        issues.append("identity, bounds, or output contract mismatch")
    if (not isinstance(source, dict)
            or source.get("book_chapter_doi") != "10.1007/978-1-4939-2864-4_172"
            or "color-bit" not in source.get("algorithm_attribution", "")
            or "clean-room" not in source.get("implementation_status", "")):
        issues.append("source attribution mismatch")

    for language, extension in LANGUAGES.items():
        path = REPO_ROOT / language / "e" / f"{NAME}.{extension}"
        if not path.is_file():
            issues.append(f"missing language port: {language}")
        elif NAME not in path.read_text(encoding="utf-8"):
            issues.append(f"exported symbol missing from: {language}")
    for filename in ("README.md", "INVENTORY.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                     "independent_oracle.py", "verify_workload.py", "check_inventory.py"):
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package artifact: {filename}")

    readme_path = PACKAGE / "README.md"
    if readme_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        for language, extension in LANGUAGES.items():
            target = f"../../../{language}/e/{NAME}.{extension}"
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
            result, payload = primary(values, MAX_OUTPUT_BYTES, False, False, length)
            parsed = _parse(values)
            if result < 0 or parsed is None or result != len(payload):
                issues.append(f"valid fixture failed full-capacity encoding: {case_id}")
                continue
            words = struct.unpack("<" + "q" * (len(payload) // 8), payload)
            n, layers, classes, vertex_colors, source_masks = parsed
            node_count = n * layers
            pairs = list(zip(words[2 + node_count::2], words[3 + node_count::2]))
            if (len(words) != 2 + node_count + 2 * words[1]
                    or words[0] != node_count
                    or words[1] != len(pairs)
                    or words[2:2 + node_count] != tuple(
                        layer * classes + vertex_colors[vertex]
                        for layer in range(layers) for vertex in range(n))
                    or pairs != sorted(set(pairs))
                    or any(left >= right for left, right in pairs)):
                issues.append(f"layered graph structure mismatch: {case_id}")
                continue
            expected_pairs = set()
            for layer in range(layers):
                for left in range(n):
                    for right in range(left + 1, n):
                        if source_masks[left][right] & (1 << layer):
                            expected_pairs.add((layer * n + left, layer * n + right))
            for vertex in range(n):
                for layer in range(layers - 1):
                    expected_pairs.add((layer * n + vertex, (layer + 1) * n + vertex))
            if set(pairs) != expected_pairs:
                issues.append(f"layer/thread edge encoding mismatch: {case_id}")
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
