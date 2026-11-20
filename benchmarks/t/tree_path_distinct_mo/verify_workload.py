"""Static workload, oracle, provenance, and ten-port inventory checker."""

import importlib.util
import json
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]


def _load_reference(name: str, filename: str):
    spec = importlib.util.spec_from_file_location(name, PACKAGE / filename)
    if spec is None or spec.loader is None:
        raise ValueError(f"cannot load {filename}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


PRIMARY = _load_reference("tree_path_distinct_mo_primary", "primary_oracle.py")
INDEPENDENT = _load_reference("tree_path_distinct_mo_independent", "independent_oracle.py")

TASK_URL = "https://oi-wiki.org/misc/mo-algo-on-tree/"
PORTS = (
    "c/t/tree_path_distinct_mo.c",
    "c3/t/tree_path_distinct_mo.c3",
    "cpp/t/tree_path_distinct_mo.cpp",
    "elisa/t/tree_path_distinct_mo.elisa",
    "mojo/t/tree_path_distinct_mo.mojo",
    "nim/t/tree_path_distinct_mo.nim",
    "odin/t/tree_path_distinct_mo.odin",
    "rust/t/tree_path_distinct_mo.rs",
    "v/t/tree_path_distinct_mo.v",
    "zig/t/tree_path_distinct_mo.zig",
)


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("algorithm") != "tree_path_distinct_mo"
            or workload.get("function_symbol") != "tree_path_distinct_mo"
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("source", {}).get("task_url") != TASK_URL
            or workload.get("input", {}).get("maximum_valid_length") != PRIMARY.MAX_VALID_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_length") != PRIMARY.MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("output", {}).get("maximum_bytes") != PRIMARY.MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != 16384
            or PRIMARY.MAX_N != 32 or PRIMARY.MAX_Q != 32
            or PRIMARY.MAX_VALID_INPUT_LENGTH != 160
            or PRIMARY.MAX_PARSEABLE_INPUT_LENGTH != 161
            or PRIMARY.MAX_OUTPUT_BYTES != 256
            or PRIMARY.MAX_WORKSPACE_BYTES != 16384
            or INDEPENDENT.MAX_VALID_INPUT_LENGTH != PRIMARY.MAX_VALID_INPUT_LENGTH
            or INDEPENDENT.MAX_PARSEABLE_INPUT_LENGTH != PRIMARY.MAX_PARSEABLE_INPUT_LENGTH
            or INDEPENDENT.MAX_OUTPUT_BYTES != PRIMARY.MAX_OUTPUT_BYTES
            or INDEPENDENT.MAX_WORKSPACE_BYTES != PRIMARY.MAX_WORKSPACE_BYTES):
        raise ValueError("tree_path_distinct_mo metadata differs from its bounded contract")

    cases = workload.get("cases")
    expected_ids = {
        "branching-tree-ancestor-and-nonancestor-queries",
        "repeated-colors-and-overlapping-paths",
        "signed-extreme-colors",
        "empty-query-list",
        "invalid-cycle-from-repeated-edge",
        "invalid-query-endpoint",
        "trailing-input-word",
        "null-input",
        "short-output-buffer",
        "null-output-buffer",
    }
    if (not isinstance(cases, list) or len(cases) != len(expected_ids)
            or {case.get("id") for case in cases if isinstance(case, dict)} != expected_ids):
        raise ValueError("tree_path_distinct_mo fixtures are incomplete or duplicated")

    for case in cases:
        if not isinstance(case, dict):
            raise ValueError("tree_path_distinct_mo fixture is not an object")
        values = case.get("input_values")
        input_length = case.get("input_length")
        capacity = case.get("output_capacity")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        if (not isinstance(values, list) or type(input_length) is not int
                or input_length != len(values) or len(values) > PRIMARY.MAX_PARSEABLE_INPUT_LENGTH
                or type(capacity) is not int or not 0 <= capacity <= PRIMARY.MAX_OUTPUT_BYTES
                or type(input_is_null) is not bool or type(output_is_null) is not bool):
            raise ValueError(f"tree_path_distinct_mo fixture framing is invalid: {case.get('id')}")
        n = values[0] if values else -1
        q = values[1] if len(values) > 1 else -1
        if (n > 0 and q >= 0 and n <= PRIMARY.MAX_N and q <= PRIMARY.MAX_Q
                and len(values) == 3 * n + 2 * q
                and len(values) > PRIMARY.MAX_VALID_INPUT_LENGTH):
            raise ValueError(f"tree_path_distinct_mo valid frame exceeds its bound: {case['id']}")
        options = {
            "input_is_null": input_is_null,
            "input_length": input_length,
            "output_capacity": capacity,
            "output_is_null": output_is_null,
        }
        expected = (case.get("expected_result"),
                    bytes.fromhex(case.get("expected_output_hex", "")))
        if (PRIMARY.expected_output(values, **options) != expected
                or INDEPENDENT.expected_output(values, **options) != expected):
            raise ValueError(f"tree_path_distinct_mo fixture differs from its oracles: {case['id']}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if (TASK_URL not in readme or TASK_URL not in rights or "clean-room" not in readme
            or "O(n^2 + qn)" not in readme or "16384 bytes" not in readme):
        raise ValueError("tree_path_distinct_mo provenance or complexity notes are incomplete")
    for relative in PORTS:
        source = ROOT / relative
        if not source.is_file() or "tree_path_distinct_mo" not in source.read_text(encoding="utf-8"):
            raise ValueError(f"tree_path_distinct_mo port is absent or lacks its symbol: {relative}")
        if relative not in readme:
            raise ValueError(f"tree_path_distinct_mo README omits its port: {relative}")
    return len(cases)


def main() -> None:
    print(f"checked {verify_workload()} tree_path_distinct_mo fixtures and {len(PORTS)} ports")


if __name__ == "__main__":
    main()
