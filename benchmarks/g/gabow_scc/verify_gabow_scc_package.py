"""Static package inventory and oracle-fixture checker; do not run while profiling."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import sys

BENCHMARKS = Path(__file__).resolve().parents[2]
ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
sys.path.insert(0, str(BENCHMARKS))

ALGORITHM = "gabow_scc"
DOI_URL = "https://doi.org/10.1016/S0020-0190(00)00051-X"
AUTHOR_COPY = "https://www.cs.princeton.edu/courses/archive/spr09/cos423/Lectures/bi-gabow.pdf"
PORTS = (
    "c/g/gabow_scc.c",
    "c3/g/gabow_scc.c3",
    "cpp/g/gabow_scc.cpp",
    "elisa/g/gabow_scc.elisa",
    "mojo/g/gabow_scc.mojo",
    "nim/g/gabow_scc.nim",
    "odin/g/gabow_scc.odin",
    "rust/g/gabow_scc.rs",
    "v/g/gabow_scc.v",
    "zig/g/gabow_scc.zig",
)
CASE_IDS = {
    "empty-graph",
    "isolated-vertices",
    "nested-cycles-with-outgoing-singleton",
    "edge-to-completed-component",
    "duplicate-edges-and-self-loops",
    "two-components-with-cross-boundary-edge",
    "directed-chain",
    "short-output-capacity",
    "null-output",
    "null-input",
    "invalid-endpoint",
    "trailing-input-value",
}


def _load_oracle(filename: str):
    path = BENCHMARKS / filename
    spec = importlib.util.spec_from_file_location(path.stem, path)
    if spec is None or spec.loader is None:
        raise ValueError(f"cannot load oracle module: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def validate_package() -> None:
    primary = _load_oracle("gabow_scc_oracle.py")
    verifier = _load_oracle("gabow_scc_kosaraju_oracle.py")
    expected_bounds = (40, 2047, 4096, 81)
    for oracle in (primary, verifier):
        actual_bounds = (oracle.MAX_VERTICES, oracle.MAX_EDGES,
                         oracle.MAX_INPUT_LENGTH, oracle.MAX_OUTPUT_BYTES)
        if actual_bounds != expected_bounds:
            raise ValueError("oracle bounds differ from the package profile")

    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("algorithm") != ALGORITHM
            or workload.get("function_symbol") != ALGORITHM
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("source", {}).get("url") != DOI_URL
            or workload.get("source", {}).get("author_copy") != AUTHOR_COPY
            or workload.get("input", {}).get("maximum_input_length") != 4096
            or workload.get("input", {}).get("vertex_count_range") != [0, 40]
            or workload.get("input", {}).get("edge_count_range") != [0, 2047]
            or workload.get("output", {}).get("maximum_bytes") != 81
            or workload.get("workspace", {}).get("elements") != 2001
            or "O(V^2+E)" not in workload.get("contract", {}).get("complexity", "")
            or workload.get("measurement", {}).get("comparison_model")
            != "i64_array_bytes_output_call"):
        raise ValueError("workload metadata differs from the bounded profile")

    cases = workload.get("cases")
    if (not isinstance(cases, list) or len(cases) != len(CASE_IDS)
            or {case.get("id") for case in cases if isinstance(case, dict)} != CASE_IDS):
        raise ValueError("workload fixtures are missing or have duplicate identifiers")
    allowed_fields = {
        "id", "input_values", "input_length", "output_capacity",
        "input_is_null", "output_is_null", "expected_result", "expected_output_bytes",
    }
    required_fields = {"id", "input_values", "input_length", "expected_result",
                       "expected_output_bytes"}
    for case in cases:
        if (not isinstance(case, dict) or set(case) - allowed_fields
                or not required_fields.issubset(case)):
            raise ValueError("fixture fields differ from the byte-output contract")
        values = case["input_values"]
        if (not isinstance(values, list) or type(case["input_length"]) is not int
                or case["input_length"] != len(values)
                or len(values) > primary.MAX_INPUT_LENGTH
                or not isinstance(case["expected_output_bytes"], list)):
            raise ValueError(f"fixture framing is invalid: {case['id']}")
        options = {
            "output_capacity": case.get("output_capacity"),
            "input_is_null": case.get("input_is_null", False),
            "output_is_null": case.get("output_is_null", False),
            "input_length": case["input_length"],
        }
        expected = (case["expected_result"], bytes(case["expected_output_bytes"]))
        for oracle in (primary, verifier):
            actual = oracle.expected_output(values, **options)
            if actual != expected:
                raise ValueError(f"fixture differs from an oracle: {case['id']}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    for required in (DOI_URL, AUTHOR_COPY, "O(V+E)", "O(V^2+E)",
                     "2001 scalar elements", "clean-room"):
        if required not in readme:
            raise ValueError(f"README is missing contract/provenance detail: {required}")
    if DOI_URL not in rights or AUTHOR_COPY not in rights or "No paper prose" not in rights:
        raise ValueError("rights attribution or clean-room statement is incomplete")
    for relative in PORTS:
        source = ROOT / relative
        if not source.is_file() or ALGORITHM not in source.read_text(encoding="utf-8"):
            raise ValueError(f"port is absent or lacks its exported symbol: {relative}")
        if relative not in readme:
            raise ValueError(f"README is missing a port reference: {relative}")


if __name__ == "__main__":
    validate_package()
