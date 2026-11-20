"""Static metadata and oracle checks for the PQ-tree workload."""

from __future__ import annotations

import json
import math
from pathlib import Path
import struct
import sys

from .independent_oracle import expected_output as independent_output
from .primary_oracle import (
    MAX_M,
    MAX_N,
    MAX_NODES,
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_REDUCED_NODES,
    MAX_VALID_INPUT_LENGTH,
    WORKSPACE_BYTES,
    expected_output as primary_output,
)

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SOURCES = {
    "c": ROOT / "c/p/pq_tree_consecutive_ones.c",
    "c3": ROOT / "c3/p/pq_tree_consecutive_ones.c3",
    "cpp": ROOT / "cpp/p/pq_tree_consecutive_ones.cpp",
    "elisa": ROOT / "elisa/p/pq_tree_consecutive_ones.elisa",
    "mojo": ROOT / "mojo/p/pq_tree_consecutive_ones.mojo",
    "nim": ROOT / "nim/p/pq_tree_consecutive_ones.nim",
    "odin": ROOT / "odin/p/pq_tree_consecutive_ones.odin",
    "rust": ROOT / "rust/p/pq_tree_consecutive_ones.rs",
    "v": ROOT / "v/p/pq_tree_consecutive_ones.v",
    "zig": ROOT / "zig/p/pq_tree_consecutive_ones.zig",
}


def _decode_tree(words: tuple[int, ...], cursor: int):
    kind, argument = words[cursor], words[cursor + 1]
    cursor += 2
    children = []
    if kind != 0:
        for _ in range(argument):
            child, cursor = _decode_tree(words, cursor)
            children.append(child)
    return (kind, argument, children), cursor


def _tree_stats(node, n: int):
    kind, argument, children = node
    if kind == 0:
        if children or not 0 <= argument < n:
            raise ValueError("invalid leaf record")
        return [argument], 1, 1
    if kind not in (1, 2) or argument != len(children) or argument < 2:
        raise ValueError("invalid internal node record")
    if kind == 2 and argument < 3:
        raise ValueError("Q nodes must have degree at least three")
    leaf_ids = []
    nodes = 1
    count = math.factorial(argument) if kind == 1 else 2
    child_keys = []
    for child in children:
        child_leaves, child_nodes, child_count = _tree_stats(child, n)
        leaf_ids.extend(child_leaves)
        nodes += child_nodes
        count *= child_count
        child_keys.append(_tree_key(child))
    if kind == 1 and child_keys != sorted(child_keys):
        raise ValueError("P children are not canonically sorted")
    if kind == 2 and tuple(child_keys) > tuple(reversed(child_keys)):
        raise ValueError("Q node is not in canonical orientation")
    return leaf_ids, nodes, count


def _tree_key(node):
    kind, argument, children = node
    if kind == 0:
        return kind, argument
    return kind, argument, tuple(_tree_key(child) for child in children)


def verify_workload() -> list[str]:
    issues: list[str] = []
    workload_path = PACKAGE / "workload.json"
    try:
        workload = json.loads(workload_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload.json: {error}"]

    if workload.get("algorithm") != "pq_tree_consecutive_ones":
        issues.append("algorithm metadata is missing or incorrect")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("ABI metadata must be i64_array_bytes_output")
    input_meta = workload.get("input", {})
    if input_meta.get("column_count_range") != [2, MAX_N]:
        issues.append("column-count bounds do not match the oracle")
    if input_meta.get("row_count_range") != [0, MAX_M]:
        issues.append("row-count bounds do not match the oracle")
    if input_meta.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH:
        issues.append("maximum valid input length is incorrect")
    if input_meta.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH:
        issues.append("maximum parseable input length is incorrect")
    output_meta = workload.get("output", {})
    if output_meta.get("maximum_bytes") != MAX_OUTPUT_BYTES:
        issues.append("maximum output size is incorrect")
    if output_meta.get("maximum_node_count") != MAX_REDUCED_NODES:
        issues.append("maximum node count is incorrect")
    if workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES:
        issues.append("workspace bound is incorrect")
    if output_meta.get("unsatisfiable_words") != [0, 0, 0]:
        issues.append("unsatisfiable encoding must be [0,0,0]")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        issues.append("workload must contain cases")
        cases = []
    for case in cases:
        case_id = case.get("id", "<unnamed>")
        values = case.get("input_values")
        if not isinstance(values, list):
            issues.append(f"{case_id}: input_values must be an array")
            continue
        expected_result, expected_bytes = primary_output(
            values,
            input_is_null=case.get("input_is_null", False),
            output_is_null=case.get("output_is_null", False),
            capacity=case.get("output_capacity"),
            input_length=case.get("input_length"),
        )
        if case.get("expected_result") != expected_result:
            issues.append(f"{case_id}: expected_result disagrees with the primary oracle")
        if "expected_output_hex" in case and case["expected_output_hex"] != expected_bytes.hex():
            issues.append(f"{case_id}: expected_output_hex disagrees with the primary oracle")

        if expected_result <= 0 or case.get("input_is_null", False):
            continue
        words = struct.unpack("<" + "q" * (len(expected_bytes) // 8), expected_bytes)
        if words[0] != case.get("expected_status"):
            issues.append(f"{case_id}: status metadata disagrees with the primary oracle")
        if len(values) >= 2 and isinstance(values[0], int) and values[0] <= 8:
            independent_result, independent_bytes = independent_output(values)
            if (independent_result, independent_bytes) != (expected_result, expected_bytes):
                issues.append(f"{case_id}: primary and frontier-set oracles disagree")
        if words[0] == 0:
            if words != (0, 0, 0):
                issues.append(f"{case_id}: unsatisfiable output must be [0,0,0]")
            continue
        if words[1] != case.get("expected_frontier_count"):
            issues.append(f"{case_id}: frontier count metadata disagrees with the primary oracle")
        if words[2] != case.get("expected_node_count"):
            issues.append(f"{case_id}: node count metadata disagrees with the primary oracle")
        root, cursor = _decode_tree(words, 3)
        if cursor != len(words):
            issues.append(f"{case_id}: prefix tree does not consume the full output")
        try:
            leaves, node_total, count_total = _tree_stats(root, values[0])
            if sorted(leaves) != list(range(values[0])) or len(leaves) != len(set(leaves)):
                issues.append(f"{case_id}: tree leaves do not cover each column exactly once")
            if node_total != words[2] or count_total != words[1]:
                issues.append(f"{case_id}: serialized tree statistics disagree with its header")
        except (IndexError, ValueError, RecursionError) as error:
            issues.append(f"{case_id}: invalid serialized tree: {error}")
        expected_root = case.get("expected_root")
        if expected_root and (root[0] != expected_root.get("kind")
                              or root[1] != expected_root.get("arity")):
            issues.append(f"{case_id}: root shape disagrees with the primary oracle")
        expected_kinds = case.get("expected_child_kinds")
        if expected_kinds is not None and [child[0] for child in root[2]] != expected_kinds:
            issues.append(f"{case_id}: root child kinds disagree with the fixture")
        expected_arities = case.get("expected_child_arities")
        if expected_arities is not None:
            actual_arities = [child[1] if child[0] else None for child in root[2]]
            if actual_arities != expected_arities:
                issues.append(f"{case_id}: root child arities disagree with the fixture")

    case_ids = {case.get("id") for case in cases}
    for fixture_id in (
        "unconstrained-twenty-column-p-root",
        "two-independent-ten-column-q-blocks",
        "sixteen-column-q-core-with-four-free-columns",
        "three-pair-cycle-is-unsatisfiable",
        "white-sibling-around-a-single-mixed-child",
    ):
        if fixture_id not in case_ids:
            issues.append(f"missing structural fixture: {fixture_id}")
    for language, source in SOURCES.items():
        if not source.is_file():
            issues.append(f"missing {language} source draft: {source}")
    for required in ("README.md", "RIGHTS.md", "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / required).is_file():
            issues.append(f"missing package file: {required}")
    return issues


def main() -> int:
    issues = verify_workload()
    if issues:
        for issue in issues:
            print(issue, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
