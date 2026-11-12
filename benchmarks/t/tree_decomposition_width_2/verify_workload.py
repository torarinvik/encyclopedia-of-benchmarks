"""Static bounds, provenance, oracle-agreement, and certificate checks."""

import json
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(ROOT / "benchmarks"))
from tree_decomposition_width_2_oracle import (  # noqa: E402
    MAX_INPUT_LENGTH, MAX_OUTPUT_BYTES, MAX_WORKSPACE_BYTES, expected_output,
)
from tree_decomposition_width_2_verifier_oracle import (  # noqa: E402
    expected_output as independent_output,
    validate_output,
)

TASK_URL = "https://github.com/yosupo06/library-checker-problems/blob/master/graph/tree_decomposition_width_2/task.md"
INFO_URL = "https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/graph/tree_decomposition_width_2/info.toml"
PORTS = (
    "c/t/tree_decomposition_width_2.c",
    "c3/t/tree_decomposition_width_2.c3",
    "cpp/t/tree_decomposition_width_2.cpp",
    "elisa/t/tree_decomposition_width_2.elisa",
    "mojo/t/tree_decomposition_width_2.mojo",
    "nim/t/tree_decomposition_width_2.nim",
    "odin/t/tree_decomposition_width_2.odin",
    "rust/t/tree_decomposition_width_2.rs",
    "v/t/tree_decomposition_width_2.v",
    "zig/t/tree_decomposition_width_2.zig",
)


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    source = workload.get("source", {})
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "tree_decomposition_width_2"
            or workload.get("function_symbol") != "tree_decomposition_width_2"
            or workload.get("abi") != "i64_array_bytes_output"
            or source.get("task_url") != TASK_URL
            or source.get("limits_url") != INFO_URL
            or source.get("repository_license") != "Apache-2.0"):
        raise ValueError("workload identity or source attribution differs from the reviewed task")
    if (workload.get("input", {}).get("maximum_parseable_length") != MAX_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_valid_length") != MAX_INPUT_LENGTH - 1
            or workload.get("input", {}).get("vertex_count_range") != [1, 32]
            or workload.get("input", {}).get("maximum_edge_count") != 64
            or workload.get("output", {}).get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("output", {}).get("size_formula") != "8*(6*N+7)"
            or workload.get("workspace", {}).get("bytes") != MAX_WORKSPACE_BYTES):
        raise ValueError("workload bounds differ from the primary oracle")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("workload must contain named fixtures")
    required_ids = {
        "single-isolated-vertex", "two-vertex-edge", "four-cycle",
        "disconnected-triangle-and-edge", "maximum-32-vertex-2-tree",
        "clique-four-width-three", "duplicate-edge-invalid", "loop-invalid",
        "reversed-edge-invalid", "extra-word-invalid", "malformed-before-capacity",
        "short-output-capacity", "null-output", "null-input",
    }
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            raise ValueError("fixture is not a named object")
        if case["id"] in seen:
            raise ValueError(f"duplicate fixture ID: {case['id']}")
        seen.add(case["id"])
        values = case.get("input_values", [])
        args = (values, case.get("output_capacity"),
                case.get("output_is_null", False), case.get("input_is_null", False),
                case.get("input_length"))
        primary = expected_output(*args)
        independent = independent_output(*args)
        if (case.get("input_length") != len(values)
                or primary != independent
                or primary[0] != case.get("expected_result")):
            raise ValueError(f"fixture differs between the independent oracles: {case['id']}")
        if "expected_output_hex" in case and primary[1].hex() != case["expected_output_hex"].lower():
            raise ValueError(f"fixture bytes differ from the pinned output: {case['id']}")
        if primary[0] >= 0 and not validate_output(values, primary[1]):
            raise ValueError(f"oracle certificate fails independent checks: {case['id']}")
        if primary[0] < 0 and primary[1]:
            raise ValueError(f"error fixture contains output bytes: {case['id']}")
    if not required_ids.issubset(seen):
        raise ValueError(f"workload omits required width-2 cases: {sorted(required_ids - seen)}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if TASK_URL not in readme or INFO_URL not in readme or "Apache-2.0" not in rights:
        raise ValueError("README or rights note omits provenance")
    if len(PORTS) != 10:
        raise ValueError("the package checker must list all ten language ports")
    for relative in PORTS:
        port = ROOT / relative
        if (not port.is_file()
                or "tree_decomposition_width_2" not in port.read_text(encoding="utf-8")
                or relative not in readme):
            raise ValueError(f"port or README link is missing: {relative}")
    return len(cases)


if __name__ == "__main__":
    print(f"checked {verify_workload()} fixtures and {len(PORTS)} port paths")
