"""Static package inventory and fixture/oracle consistency checker."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import sys

BENCHMARKS = Path(__file__).resolve().parents[2]
ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
sys.path.insert(0, str(BENCHMARKS))

ALGORITHM = "games_on_arbitrary_graphs"
SOURCE_URL = "https://cp-algorithms.com/game_theory/games_on_graphs.html"
PORTS = (
    "c/g/games_on_arbitrary_graphs.c",
    "c3/g/games_on_arbitrary_graphs.c3",
    "cpp/g/games_on_arbitrary_graphs.cpp",
    "elisa/g/games_on_arbitrary_graphs.elisa",
    "mojo/g/games_on_arbitrary_graphs.mojo",
    "nim/g/games_on_arbitrary_graphs.nim",
    "odin/g/games_on_arbitrary_graphs.odin",
    "rust/g/games_on_arbitrary_graphs.rs",
    "v/g/games_on_arbitrary_graphs.v",
    "zig/g/games_on_arbitrary_graphs.zig",
)
CASE_IDS = {
    "empty-graph",
    "single-terminal",
    "one-move-to-terminal",
    "two-cycle-draw",
    "alternating-chain",
    "winning-choice-over-draw",
    "all-successors-win",
    "cycle-with-terminal-exit",
    "self-loop-draw",
    "duplicate-edges-coalesced",
    "maximum-vertex-count-isolated",
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
    primary = _load_oracle("games_on_arbitrary_graphs_oracle.py")
    independent = _load_oracle("games_on_arbitrary_graphs_fixed_point_oracle.py")
    expected_bounds = (16, 32, 66, 17)
    for oracle in (primary, independent):
        actual = (oracle.MAX_VERTICES, oracle.MAX_EDGES,
                  oracle.MAX_INPUT_LENGTH, oracle.MAX_OUTPUT_BYTES)
        if actual != expected_bounds:
            raise ValueError("oracle bounds differ from the package profile")

    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("algorithm") != ALGORITHM
            or workload.get("function_symbol") != ALGORITHM
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("source", {}).get("url") != SOURCE_URL
            or workload.get("input", {}).get("vertex_count_range") != [0, 16]
            or workload.get("input", {}).get("edge_count_range") != [0, 32]
            or workload.get("input", {}).get("maximum_input_length") != 66
            or workload.get("output", {}).get("maximum_bytes") != 17
            or workload.get("workspace", {}).get("elements") != 161
            or workload.get("measurement", {}).get("comparison_model")
            != "i64_array_bytes_output_call"):
        raise ValueError("workload metadata differs from the bounded contract")

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
        # The suite supplies tuple payloads after normalizing corpus fixtures.
        tuple_values = tuple(values)
        for oracle in (primary, independent):
            actual = oracle.expected_output(tuple_values, **options)
            if actual != expected:
                raise ValueError(f"fixture differs from an oracle: {case['id']}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    for required in (SOURCE_URL, "O(V+E)", "CC BY-SA 4.0", "reverse-edge", "draw"):
        if required not in readme:
            raise ValueError(f"README is missing contract/provenance detail: {required}")
    if SOURCE_URL not in rights or "No source code" not in rights:
        raise ValueError("rights attribution or clean-room statement is incomplete")
    for relative in PORTS:
        source = ROOT / relative
        if not source.is_file() or ALGORITHM not in source.read_text(encoding="utf-8"):
            raise ValueError(f"port is absent or lacks its exported symbol: {relative}")
        if relative not in readme:
            raise ValueError(f"README is missing a port reference: {relative}")


if __name__ == "__main__":
    validate_package()
