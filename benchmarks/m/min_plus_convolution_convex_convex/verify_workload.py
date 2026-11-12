"""Static workload, provenance, oracle-agreement, and port-path checker."""

import json
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(ROOT / "benchmarks"))

from min_plus_convolution_convex_convex_oracle import (  # noqa: E402
    MAX_N, MAX_M, MAX_OUTPUT_BYTES, MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH, MAX_WORKSPACE_BYTES, expected_output,
)
from min_plus_convolution_convex_convex_verifier_oracle import (  # noqa: E402
    expected_output as independent_output,
)

TASK_URL = "https://github.com/yosupo06/library-checker-problems/blob/master/convolution/min_plus_convolution_convex_convex/task.md"
INFO_URL = "https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/convolution/min_plus_convolution_convex_convex/info.toml"
LECTURE_URL = "https://info.atcoder.jp/entry/algorithm_lectures/min_plus_convolution"
PORTS = (
    "c/m/min_plus_convolution_convex_convex.c",
    "c3/m/min_plus_convolution_convex_convex.c3",
    "cpp/m/min_plus_convolution_convex_convex.cpp",
    "elisa/m/min_plus_convolution_convex_convex.elisa",
    "mojo/m/min_plus_convolution_convex_convex.mojo",
    "nim/m/min_plus_convolution_convex_convex.nim",
    "odin/m/min_plus_convolution_convex_convex.odin",
    "rust/m/min_plus_convolution_convex_convex.rs",
    "v/m/min_plus_convolution_convex_convex.v",
    "zig/m/min_plus_convolution_convex_convex.zig",
)


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    source = workload.get("source", {})
    if (workload.get("schema_version") != 1
            or workload.get("id") != "library-checker-min-plus-convolution-convex-convex-bounded-v1"
            or workload.get("algorithm") != "min_plus_convolution_convex_convex"
            or workload.get("function_symbol") != "min_plus_convolution_convex_convex"
            or workload.get("abi") != "i64_array_bytes_output"
            or source.get("task_url") != TASK_URL
            or source.get("limits_url") != INFO_URL
            or source.get("algorithm_reference_url") != LECTURE_URL
            or source.get("repository_license") != "Apache-2.0"):
        raise ValueError("workload identity or official source attribution differs")
    if (workload.get("input", {}).get("n_range") != [1, MAX_N]
            or workload.get("input", {}).get("m_range") != [1, MAX_M]
            or workload.get("input", {}).get("official_dimension_maximum") != 524288
            or workload.get("input", {}).get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("output", {}).get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != MAX_WORKSPACE_BYTES
            or MAX_OUTPUT_BYTES != 8 * (MAX_N + MAX_M - 1)):
        raise ValueError("workload bounds differ from the primary oracle")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("workload must contain named fixtures")
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            raise ValueError("fixture is not a named object")
        if case["id"] in seen:
            raise ValueError(f"duplicate fixture ID: {case['id']}")
        seen.add(case["id"])
        values = case.get("input_values", [])
        capacity = case.get("output_capacity", MAX_OUTPUT_BYTES)
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        input_length = case.get("input_length")
        primary = expected_output(values, capacity, output_is_null, input_is_null, input_length)
        independent = independent_output(values, capacity, output_is_null, input_is_null, input_length)
        if (input_length != len(values) or primary != independent
                or primary[0] != case.get("expected_result")):
            raise ValueError(f"fixture differs between independent oracles: {case['id']}")
        expected_hex = case.get("expected_output_hex")
        if expected_hex is not None and primary[1].hex() != expected_hex.lower():
            raise ValueError(f"fixture bytes differ from the oracle: {case['id']}")

    maximum = (MAX_N, MAX_M, *range(MAX_N), *range(MAX_M))
    result, payload = expected_output(maximum, MAX_OUTPUT_BYTES)
    independent_result, independent_payload = independent_output(maximum, MAX_OUTPUT_BYTES)
    if (len(maximum) != MAX_VALID_INPUT_LENGTH or result != MAX_OUTPUT_BYTES
            or (result, payload) != (independent_result, independent_payload)):
        raise ValueError("maximum linear profile differs between direct and slope-merge oracles")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if (any(url not in readme for url in (TASK_URL, INFO_URL, LECTURE_URL))
            or "Apache-2.0" not in rights or LECTURE_URL not in rights):
        raise ValueError("README or rights note omits provenance")
    for relative in PORTS:
        path = ROOT / relative
        if (not path.is_file()
                or "min_plus_convolution_convex_convex" not in path.read_text(encoding="utf-8")):
            raise ValueError(f"port or entrypoint is missing: {relative}")
        if relative not in readme:
            raise ValueError(f"README does not link port: {relative}")
    return len(cases)


if __name__ == "__main__":
    print(f"checked {verify_workload()} fixtures and {len(PORTS)} port paths")
