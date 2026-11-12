"""Static package inventory and oracle-fixture consistency checker."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path

BENCHMARKS = Path(__file__).resolve().parents[2]
ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent

ALGORITHM = "lengauer_tarjan_dominator_tree"
DOI_URL = "https://doi.org/10.1145/357062.357071"
AUTHOR_COPY = "https://www.cs.princeton.edu/courses/archive/fall03/cs528/handouts/a%20fast%20algorithm%20for%20finding.pdf"
PORTS = (
    "c/l/lengauer_tarjan_dominator_tree.c",
    "c3/l/lengauer_tarjan_dominator_tree.c3",
    "cpp/l/lengauer_tarjan_dominator_tree.cpp",
    "elisa/l/lengauer_tarjan_dominator_tree.elisa",
    "mojo/l/lengauer_tarjan_dominator_tree.mojo",
    "nim/l/lengauer_tarjan_dominator_tree.nim",
    "odin/l/lengauer_tarjan_dominator_tree.odin",
    "rust/l/lengauer_tarjan_dominator_tree.rs",
    "v/l/lengauer_tarjan_dominator_tree.v",
    "zig/l/lengauer_tarjan_dominator_tree.zig",
)
CASE_IDS = {
    "single-root",
    "rooted-chain",
    "diamond-join",
    "cycle-with-common-entry",
    "unreachable-components",
    "nonzero-root-and-join",
    "self-loop-and-duplicate-arc",
    "short-output-capacity",
    "null-output",
    "null-input",
    "invalid-root",
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
    primary = _load_oracle("lengauer_tarjan_dominator_tree_oracle.py")
    independent = _load_oracle("lengauer_tarjan_dominator_tree_independent_oracle.py")
    expected_bounds = (63, 2047, 4097, 63)
    for oracle in (primary, independent):
        bounds = (oracle.MAX_VERTICES, oracle.MAX_EDGES,
                  oracle.MAX_INPUT_LENGTH, oracle.MAX_OUTPUT_BYTES)
        if bounds != expected_bounds:
            raise ValueError("oracle bounds differ from the bounded profile")

    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("algorithm") != ALGORITHM
            or workload.get("function_symbol") != ALGORITHM
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("source", {}).get("doi") != "10.1145/357062.357071"
            or workload.get("source", {}).get("url") != DOI_URL
            or workload.get("source", {}).get("author_hosted_copy") != AUTHOR_COPY
            or workload.get("input", {}).get("node_count_range") != [1, 63]
            or workload.get("input", {}).get("edge_count_range") != [0, 2047]
            or workload.get("input", {}).get("maximum_valid_length") != 4097
            or workload.get("output", {}).get("maximum_values") != 63
            or workload.get("output", {}).get("maximum_bytes") != 63
            or workload.get("workspace", {}).get("bytes", 0) < 63
            or workload.get("workspace", {}).get("elements") != 9206
            or "O((V+E) log V)" not in workload.get("contract", {}).get("complexity", "")
            or workload.get("measurement", {}).get("comparison_model")
            != "i64_array_bytes_output_call"):
        raise ValueError("workload metadata differs from the bounded contract")

    cases = workload.get("cases")
    if (not isinstance(cases, list) or len(cases) != len(CASE_IDS)
            or {case.get("id") for case in cases if isinstance(case, dict)} != CASE_IDS):
        raise ValueError("workload fixtures are missing or have duplicate identifiers")
    allowed_fields = {
        "id", "input_values", "input_length", "output_capacity",
        "input_is_null", "output_is_null", "expected_result", "expected_output_hex",
    }
    required_fields = {"id", "input_values", "input_length", "expected_result",
                       "expected_output_hex"}
    for case in cases:
        if (not isinstance(case, dict) or set(case) - allowed_fields
                or not required_fields.issubset(case)):
            raise ValueError("fixture fields differ from the byte-output contract")
        values = case["input_values"]
        if (not isinstance(values, list) or type(case["input_length"]) is not int
                or case["input_length"] != len(values)
                or len(values) > primary.MAX_INPUT_LENGTH
                or not isinstance(case["expected_output_hex"], str)):
            raise ValueError(f"fixture framing is invalid: {case['id']}")
        options = {
            "output_capacity": case.get("output_capacity"),
            "input_is_null": case.get("input_is_null", False),
            "output_is_null": case.get("output_is_null", False),
            "input_length": case["input_length"],
        }
        expected = (case["expected_result"], bytes.fromhex(case["expected_output_hex"]))
        tuple_values = tuple(values)
        for oracle in (primary, independent):
            if oracle.expected_output(tuple_values, **options) != expected:
                raise ValueError(f"fixture differs from an oracle: {case['id']}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    for required in (DOI_URL, AUTHOR_COPY, "O((V+E) log V)", "bitset", "clean-room"):
        if required not in readme:
            raise ValueError(f"README is missing contract/provenance detail: {required}")
    if DOI_URL not in rights or "No source code" not in rights:
        raise ValueError("rights attribution or clean-room statement is incomplete")
    for relative in PORTS:
        source = ROOT / relative
        if not source.is_file() or ALGORITHM not in source.read_text(encoding="utf-8"):
            raise ValueError(f"port is absent or lacks its exported symbol: {relative}")
        if relative not in readme:
            raise ValueError(f"README is missing a port reference: {relative}")


if __name__ == "__main__":
    validate_package()
