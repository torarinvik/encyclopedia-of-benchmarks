"""Static package and workload inventory review; do not run during profiling."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import re
import sys

PACKAGE = Path(__file__).resolve().parent
BENCHMARKS = PACKAGE.parents[1]
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(BENCHMARKS))
sys.path.insert(0, str(PACKAGE))

ALGORITHM = "ordered_tree_edit_distance_zhang_shasha"
SOURCE = "https://doi.org/10.1137/0218082"
PORTS = (
    "c/o/ordered_tree_edit_distance_zhang_shasha.c",
    "c3/o/ordered_tree_edit_distance_zhang_shasha.c3",
    "cpp/o/ordered_tree_edit_distance_zhang_shasha.cpp",
    "elisa/o/ordered_tree_edit_distance_zhang_shasha.elisa",
    "mojo/o/ordered_tree_edit_distance_zhang_shasha.mojo",
    "nim/o/ordered_tree_edit_distance_zhang_shasha.nim",
    "odin/o/ordered_tree_edit_distance_zhang_shasha.odin",
    "rust/o/ordered_tree_edit_distance_zhang_shasha.rs",
    "v/o/ordered_tree_edit_distance_zhang_shasha.v",
    "zig/o/ordered_tree_edit_distance_zhang_shasha.zig",
)
CASE_IDS = {
    "identical-leaf", "rename-root", "insert-leaf", "delete-leaf",
    "identical-ordered-branches", "reordered-sibling-labels", "chain-to-star",
    "one-relabel-in-chain", "maximum-identical-chain", "maximum-all-relabels",
    "invalid-empty-tree", "invalid-parent-order", "invalid-parent-not-ancestor-in-preorder",
    "one-trailing-value", "maximum-plus-trailing", "null-input", "null-at-parser-limit",
}


def _load(filename: str):
    path = PACKAGE / filename
    spec = importlib.util.spec_from_file_location(f"{ALGORITHM}_{path.stem}", path)
    if spec is None or spec.loader is None:
        raise ValueError(f"cannot load reference module {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def verify() -> None:
    primary = _load("primary_oracle.py")
    independent = _load("independent_oracle.py")
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if workload.get("algorithm") != ALGORITHM or workload.get("function_symbol") != ALGORITHM:
        raise ValueError("workload algorithm identity differs")
    if workload.get("abi") != "i64_array_scalar" or workload.get("source", {}).get("url") != SOURCE:
        raise ValueError("workload ABI or source differs")
    if (primary.MAX_VALID_INPUT_LENGTH, primary.MAX_PARSEABLE_INPUT_LENGTH) != (34, 35):
        raise ValueError("primary bounds differ from the documented profile")
    if (workload.get("input", {}).get("maximum_valid_length"),
            workload.get("input", {}).get("maximum_parseable_length")) != (34, 35):
        raise ValueError("workload frame limits differ")
    cases = workload.get("cases")
    if (not isinstance(cases, list) or len(cases) != len(CASE_IDS)
            or {c.get("id") for c in cases if isinstance(c, dict)} != CASE_IDS):
        raise ValueError("workload fixtures are missing or duplicated")
    for case in cases:
        values = case.get("input_values")
        if not isinstance(values, list):
            raise ValueError(f"fixture values are not an array: {case.get('id')}")
        if case.get("input_is_null"):
            if values or not 0 <= case.get("input_length", -1) <= primary.MAX_PARSEABLE_INPUT_LENGTH:
                raise ValueError("null fixture must have empty values and a bounded declared length")
            if case.get("expected_result") != -1:
                raise ValueError("null input fixture must be invalid")
            continue
        if case.get("input_length") != len(values):
            raise ValueError(f"fixture length mismatch: {case.get('id')}")
        if len(values) > primary.MAX_PARSEABLE_INPUT_LENGTH:
            raise ValueError(f"fixture exceeds parseable bound: {case.get('id')}")
        actual = primary.expected_result(values)
        if actual != case.get("expected_result"):
            raise ValueError(f"primary result mismatch: {case.get('id')}")
        if len(values) <= primary.MAX_VALID_INPUT_LENGTH:
            parsed = primary.parse_input(values)
            if parsed is not None and max(len(parsed[0]), len(parsed[2])) <= independent.MAX_INDEPENDENT_NODES:
                if independent.expected_result(values) != actual:
                    raise ValueError(f"independent result mismatch: {case.get('id')}")
    for relative in PORTS:
        if not (ROOT / relative).is_file():
            raise ValueError(f"missing language port: {relative}")
    for filename in ("README.md", "RIGHTS.md", "primary_oracle.py", "independent_oracle.py", "workload.json"):
        if not (PACKAGE / filename).is_file():
            raise ValueError(f"missing package file: {filename}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for relative in PORTS:
        if relative.split("/", 1)[1] not in readme:
            raise ValueError(f"README does not link port: {relative}")
    for target in re.findall(r"\]\(([^)]+)\)", readme):
        if target.startswith(("http://", "https://", "#")):
            continue
        local_target = target.split("#", 1)[0]
        if local_target and not (PACKAGE / local_target).resolve().is_file():
            raise ValueError(f"README target does not exist: {target}")
    coverage = (BENCHMARKS / "ALGORITHM_EXPANSION_COVERAGE.md").read_text(encoding="utf-8")
    if ALGORITHM not in coverage or SOURCE not in coverage:
        raise ValueError("coverage reservation/source entry is missing")
