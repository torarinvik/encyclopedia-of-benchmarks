"""Static package/workload/oracle consistency checker; intentionally unrun."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SOURCES = {
    "C": ROOT / "c/t/tree_subtree_distinct_sack.c",
    "C3": ROOT / "c3/t/tree_subtree_distinct_sack.c3",
    "C++": ROOT / "cpp/t/tree_subtree_distinct_sack.cpp",
    "Elisa": ROOT / "elisa/t/tree_subtree_distinct_sack.elisa",
    "Mojo": ROOT / "mojo/t/tree_subtree_distinct_sack.mojo",
    "Nim": ROOT / "nim/t/tree_subtree_distinct_sack.nim",
    "Odin": ROOT / "odin/t/tree_subtree_distinct_sack.odin",
    "Rust": ROOT / "rust/t/tree_subtree_distinct_sack.rs",
    "V": ROOT / "v/t/tree_subtree_distinct_sack.v",
    "Zig": ROOT / "zig/t/tree_subtree_distinct_sack.zig",
}


def _load(name: str):
    spec = importlib.util.spec_from_file_location(name, PACKAGE / f"{name}.py")
    if spec is None or spec.loader is None:
        raise AssertionError(f"cannot load {name} oracle")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def verify_workload() -> None:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    assert workload["algorithm"] == "tree_subtree_distinct_sack"
    assert workload["function_symbol"] == "tree_subtree_distinct_sack"
    assert workload["abi"] == "i64_array_bytes_output"
    assert workload["input"]["maximum_valid_length"] == 128
    assert workload["input"]["maximum_parseable_length"] == 130
    assert workload["output"]["maximum_bytes"] == 512
    assert workload["workspace"]["bytes"] == 16384
    assert workload["output"]["output_untouched_on_error"] is True
    assert all(path.is_file() for path in SOURCES.values())
    for name, path in SOURCES.items():
        source = path.read_text(encoding="utf-8")
        assert "tree_subtree_distinct_sack" in source, f"missing symbol in {name}"
    primary = _load("primary_oracle")
    independent = _load("independent_oracle")
    assert workload["cases"]
    for case in workload["cases"]:
        frame_length = case.get("input_length", len(case["input_values"]))
        assert 0 <= frame_length <= workload["input"]["maximum_parseable_length"], case["id"]
        if "output_capacity" in case:
            assert 0 <= case["output_capacity"] <= workload["output"]["maximum_bytes"], case["id"]
        expected = (case["expected_result"], bytes.fromhex(case["expected_output_hex"]))
        options = {
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        assert primary.expected_output(case["input_values"], **options) == expected, case["id"]
        assert independent.expected_output(case["input_values"], **options) == expected, case["id"]


def main() -> None:
    verify_workload()
    print("tree_subtree_distinct_sack static workload metadata and package inventory are consistent")


if __name__ == "__main__":
    main()
