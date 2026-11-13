"""Static inventory and dual-oracle fixture review for segment-tree merge/split."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .s.segment_tree_merge_split.independent_oracle import expected_output as independent_output
    from .s.segment_tree_merge_split.primary_oracle import (
        DOMAIN,
        MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        MAX_WORKSPACE_BYTES,
        MAX_OPERATION_BUFFER_BYTES,
        MAX_DECLARED_FIXED_ARRAY_BYTES,
        MAX_INTERNAL_NODE_POOL_BYTES,
        expected_output as primary_output,
    )
except ImportError:  # Direct import while benchmarks/ is on sys.path.
    from s.segment_tree_merge_split.independent_oracle import expected_output as independent_output
    from s.segment_tree_merge_split.primary_oracle import (
        DOMAIN,
        MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        MAX_WORKSPACE_BYTES,
        MAX_OPERATION_BUFFER_BYTES,
        MAX_DECLARED_FIXED_ARRAY_BYTES,
        MAX_INTERNAL_NODE_POOL_BYTES,
        expected_output as primary_output,
    )

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/s/segment_tree_merge_split"
SOURCE_URL = "https://oi-wiki.org/ds/seg-merge-split/"
PORTS = {
    "c": ROOT / "c/s/segment_tree_merge_split.c",
    "c3": ROOT / "c3/s/segment_tree_merge_split.c3",
    "cpp": ROOT / "cpp/s/segment_tree_merge_split.cpp",
    "elisa": ROOT / "elisa/s/segment_tree_merge_split.elisa",
    "mojo": ROOT / "mojo/s/segment_tree_merge_split.mojo",
    "nim": ROOT / "nim/s/segment_tree_merge_split.nim",
    "odin": ROOT / "odin/s/segment_tree_merge_split.odin",
    "rust": ROOT / "rust/s/segment_tree_merge_split.rs",
    "v": ROOT / "v/s/segment_tree_merge_split.v",
    "zig": ROOT / "zig/s/segment_tree_merge_split.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]

    if (workload.get("algorithm") != "segment_tree_merge_split"
            or workload.get("function_symbol") != "segment_tree_merge_split"
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("source", {}).get("url") != SOURCE_URL):
        issues.append("workload identity, ABI, or provenance differs")
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    if (input_spec.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or output_spec.get("maximum_output_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != MAX_WORKSPACE_BYTES
            or workload.get("workspace", {}).get("internal_node_pool_bytes")
            != MAX_INTERNAL_NODE_POOL_BYTES
            or workload.get("workspace", {}).get("operation_buffer_bytes")
            != MAX_OPERATION_BUFFER_BYTES
            or workload.get("workspace", {}).get("declared_fixed_array_bytes")
            != MAX_DECLARED_FIXED_ARRAY_BYTES):
        issues.append("workload input, output, or workspace bounds differ from the oracles")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases must be a nonempty list"]
    maximum_case_found = False
    for case in [*cases, *workload.get("abi_cases", [])]:
        if not isinstance(case, dict):
            issues.append("workload contains a non-object fixture")
            continue
        values = case.get("input_values")
        case_id = case.get("id", "<unnamed>")
        input_is_null = case.get("input_is_null", False)
        if (not isinstance(values, list)
                or (not input_is_null and case.get("input_length") != len(values))):
            issues.append(f"fixture input framing differs: {case_id}")
            continue
        if len(values) > MAX_PARSEABLE_INPUT_LENGTH:
            issues.append(f"fixture exceeds parseable input bound: {case_id}")
            continue
        options = {
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        try:
            expected = (case.get("expected_result"),
                        bytes.fromhex(case.get("expected_output_hex", "")))
        except (TypeError, ValueError):
            issues.append(f"fixture output encoding is invalid: {case_id}")
            continue
        if primary_output(values, **options) != expected:
            issues.append(f"primary oracle fixture mismatch: {case_id}")
        if independent_output(values, **options) != expected:
            issues.append(f"independent oracle fixture mismatch: {case_id}")
        if (case_id == "maximum-input-and-output"
                and len(values) == MAX_VALID_INPUT_LENGTH
                and case.get("expected_result") == MAX_OUTPUT_BYTES
                and len(expected[1]) == MAX_OUTPUT_BYTES):
            maximum_case_found = True
    if not maximum_case_found:
        issues.append("workload lacks a maximum-input and maximum-output fixture")

    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif "segment_tree_merge_split" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if SOURCE_URL not in readme or SOURCE_URL not in rights or "clean-room" not in rights:
        issues.append("README or rights note omits provenance")
    if DOMAIN != 64 or len(PORTS) != 10:
        issues.append("static domain or language inventory differs from the profile")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
