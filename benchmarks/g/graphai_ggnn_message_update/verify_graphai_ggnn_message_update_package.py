"""Static inventory and fixture consistency checker; do not invoke during profiling."""

from __future__ import annotations

import importlib.util
import json
import math
from pathlib import Path
import sys

BENCHMARKS = Path(__file__).resolve().parents[2]
ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
sys.path.insert(0, str(BENCHMARKS))
ALGORITHM = "graphai_ggnn_message_update"
SOURCE_URL = "https://github.com/chenxuhao/GraphAIBench/tree/17834cb29b7c542481c2e3740dc9664841b72f59"
PORTS = (
    "c/g/graphai_ggnn_message_update.c",
    "c3/g/graphai_ggnn_message_update.c3",
    "cpp/g/graphai_ggnn_message_update.cpp",
    "elisa/g/graphai_ggnn_message_update.elisa",
    "mojo/g/graphai_ggnn_message_update.mojo",
    "nim/g/graphai_ggnn_message_update.nim",
    "odin/g/graphai_ggnn_message_update.odin",
    "rust/g/graphai_ggnn_message_update.rs",
    "v/g/graphai_ggnn_message_update.v",
    "zig/g/graphai_ggnn_message_update.zig",
)
CASE_IDS = {
    "two-vertex-graph-message",
    "single-vertex-reset-gated-state",
    "isolated-vertices",
    "invalid-terminal-offset",
    "short-output-capacity",
    "null-output",
    "null-input",
}


def _load_oracle(name: str):
    path = BENCHMARKS / name
    spec = importlib.util.spec_from_file_location(name.removesuffix(".py"), path)
    if spec is None or spec.loader is None:
        raise ValueError(f"cannot load oracle module: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _same_values(left: list[float], right: list[float]) -> bool:
    return (len(left) == len(right)
            and all(math.isclose(a, b, rel_tol=1e-12, abs_tol=1e-12)
                    for a, b in zip(left, right)))


def validate_package() -> None:
    primary = _load_oracle("graphai_ggnn_message_update_oracle.py")
    verifier = _load_oracle("graphai_ggnn_message_update_verifier_oracle.py")
    if (primary.MAX_NODES, primary.MAX_EDGES, primary.MAX_FEATURES,
            primary.MAX_VALID_INPUT_LENGTH, primary.MAX_PARSEABLE_INPUT_LENGTH,
            primary.MAX_OUTPUT_ELEMENTS) != (8, 24, 4, 452, 453, 32):
        raise ValueError("oracle bounds differ from the package profile")

    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("algorithm") != ALGORITHM
            or workload.get("function_symbol") != ALGORITHM
            or workload.get("abi") != "float64_slice_io"
            or workload.get("pinned_source", {}).get("url") != SOURCE_URL
            or workload.get("input", {}).get("maximum_input_length") != 453
            or workload.get("input", {}).get("maximum_valid_length") != 452
            or workload.get("input", {}).get("maximum_parseable_length") != 453
            or workload.get("output", {}).get("maximum_elements") != 32
            or workload.get("workspace", {}).get("elements") != 193):
        raise ValueError("workload metadata differs from the bounded profile")
    cases = workload.get("cases")
    if (not isinstance(cases, list) or len(cases) != len(CASE_IDS)
            or {case.get("id") for case in cases if isinstance(case, dict)} != CASE_IDS):
        raise ValueError("workload fixtures are missing or have duplicate identifiers")

    for case in cases:
        if (not isinstance(case, dict)
                or set(case) - {"id", "input_values", "input_length", "output_capacity",
                                "input_is_null", "output_is_null", "expected_result",
                                "expected_output"}
                or not {"id", "input_values", "input_length", "expected_result",
                        "expected_output"}.issubset(case)):
            raise ValueError("fixture fields differ from the float64 slice contract")
        values = case["input_values"]
        if (not isinstance(values, list) or type(case["input_length"]) is not int
                or case["input_length"] != len(values)
                or len(values) > primary.MAX_PARSEABLE_INPUT_LENGTH
                or not isinstance(case["expected_output"], list)):
            raise ValueError(f"fixture framing is invalid: {case['id']}")
        options = {
            "output_capacity": case.get("output_capacity"),
            "input_is_null": case.get("input_is_null", False),
            "output_is_null": case.get("output_is_null", False),
            "input_length": case["input_length"],
        }
        result = (case["expected_result"], case["expected_output"])
        for oracle in (primary, verifier):
            actual_result, actual_output = oracle.expected_output(values, **options)
            if actual_result != result[0] or not _same_values(actual_output, result[1]):
                raise ValueError(f"fixture differs from an oracle: {case['id']}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    license_text = (PACKAGE / "LICENSE.txt").read_text(encoding="utf-8")
    for required in (SOURCE_URL, "sigmoid", "reset", "193 scalar elements", "clean-room"):
        if required not in readme:
            raise ValueError(f"README is missing contract/provenance detail: {required}")
    if SOURCE_URL not in rights or "MIT License" not in rights or "SOFTWARE" not in license_text:
        raise ValueError("rights attribution or upstream license notice is incomplete")
    for relative in PORTS:
        source = ROOT / relative
        if not source.is_file() or ALGORITHM not in source.read_text(encoding="utf-8"):
            raise ValueError(f"port is absent or lacks its exported symbol: {relative}")
        if relative not in readme:
            raise ValueError(f"README is missing a port reference: {relative}")


if __name__ == "__main__":
    validate_package()
