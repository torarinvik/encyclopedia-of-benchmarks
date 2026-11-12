"""Static workload, dual-oracle, provenance, and ten-port path checker."""

import json
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(ROOT / "benchmarks"))
from tree_path_composite_sum_oracle import (  # noqa: E402
    MAX_INPUT_LENGTH, MAX_N, MAX_OUTPUT_BYTES, MAX_VALID_INPUT_LENGTH,
    MAX_WORKSPACE_BYTES, expected_output,
)
from tree_path_composite_sum_verifier_oracle import (  # noqa: E402
    expected_output as independent_output,
)

TASK_URL = (
    "https://github.com/yosupo06/library-checker-problems/blob/master/"
    "tree/tree_path_composite_sum/task.md"
)
LIMITS_URL = (
    "https://raw.githubusercontent.com/yosupo06/library-checker-problems/"
    "master/tree/tree_path_composite_sum/info.toml"
)
PORTS = (
    "c/t/tree_path_composite_sum.c",
    "c3/t/tree_path_composite_sum.c3",
    "cpp/t/tree_path_composite_sum.cpp",
    "elisa/t/tree_path_composite_sum.elisa",
    "mojo/t/tree_path_composite_sum.mojo",
    "nim/t/tree_path_composite_sum.nim",
    "odin/t/tree_path_composite_sum.odin",
    "rust/t/tree_path_composite_sum.rs",
    "v/t/tree_path_composite_sum.v",
    "zig/t/tree_path_composite_sum.zig",
)


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (MAX_N != 32 or MAX_VALID_INPUT_LENGTH != 157 or MAX_INPUT_LENGTH != 158
            or MAX_OUTPUT_BYTES != 256 or MAX_WORKSPACE_BYTES != MAX_OUTPUT_BYTES
            or workload.get("algorithm") != "tree_path_composite_sum"
            or workload.get("function_symbol") != "tree_path_composite_sum"
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("source", {}).get("task_url") != TASK_URL
            or workload.get("source", {}).get("limits_url") != LIMITS_URL
            or workload.get("input", {}).get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_length") != MAX_INPUT_LENGTH
            or workload.get("output", {}).get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != MAX_WORKSPACE_BYTES):
        raise ValueError("tree_path_composite_sum metadata differs from its bounded contract")

    cases = workload.get("cases")
    expected_ids = {
        "singleton-empty-path", "two-vertex-root-direction",
        "three-vertex-noncommuting-chain", "three-vertex-asymmetric-star",
        "identity-transforms", "invalid-zero-multiplier",
        "invalid-cycle-and-disconnection", "trailing-word", "short-output", "null-output",
    }
    if (not isinstance(cases, list) or len(cases) != len(expected_ids)
            or {case.get("id") for case in cases if isinstance(case, dict)} != expected_ids):
        raise ValueError("tree_path_composite_sum fixtures are incomplete or duplicated")
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or case["id"] in seen:
            raise ValueError("tree_path_composite_sum fixture identifiers are invalid")
        seen.add(case["id"])
        values = case.get("input_values")
        input_length = case.get("input_length")
        capacity = case.get("output_capacity")
        output_is_null = case.get("output_is_null", False)
        if (not isinstance(values, list) or type(input_length) is not int
                or input_length != len(values) or len(values) > MAX_INPUT_LENGTH
                or type(capacity) is not int or not 0 <= capacity <= MAX_OUTPUT_BYTES
                or type(output_is_null) is not bool):
            raise ValueError(f"tree_path_composite_sum fixture framing is invalid: {case['id']}")
        options = {
            "output_capacity": capacity,
            "output_is_null": output_is_null,
            "input_length": input_length,
        }
        expected = (case.get("expected_result"),
                    bytes.fromhex(case.get("expected_output_hex", "")))
        primary = expected_output(values, **options)
        independent = independent_output(values, **options)
        if primary != expected or independent != expected:
            raise ValueError(f"tree_path_composite_sum fixture differs from its oracles: {case['id']}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if (TASK_URL not in readme or LIMITS_URL not in readme or TASK_URL not in rights
            or "clean-room" not in readme or "O(N^2) time" not in readme):
        raise ValueError("tree_path_composite_sum provenance or complexity notes are incomplete")
    for relative in PORTS:
        source = ROOT / relative
        if not source.is_file() or "tree_path_composite_sum" not in source.read_text(encoding="utf-8"):
            raise ValueError(f"tree_path_composite_sum port is absent or lacks its symbol: {relative}")
        if relative not in readme:
            raise ValueError(f"tree_path_composite_sum README omits its port: {relative}")
    return len(cases)


if __name__ == "__main__":
    print(f"checked {verify_workload()} tree_path_composite_sum fixtures and {len(PORTS)} ports")
