"""Static metadata, fixture, oracle, and port-presence checks for this package.

This checker is provided for later explicit verification and is not run during
source-only package work.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "benchmarks"))

from baswana_sen_weighted_spanner_oracle import (
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    expected_output as primary_oracle,
)
from baswana_sen_weighted_spanner_verifier_oracle import (
    expected_output as independent_oracle,
)

PACKAGE = Path(__file__).resolve().parent
PORTS = (
    "c/s/baswana_sen_weighted_spanner.c",
    "c3/s/baswana_sen_weighted_spanner.c3",
    "cpp/s/baswana_sen_weighted_spanner.cpp",
    "elisa/s/baswana_sen_weighted_spanner.elisa",
    "mojo/s/baswana_sen_weighted_spanner.mojo",
    "nim/s/baswana_sen_weighted_spanner.nim",
    "odin/s/baswana_sen_weighted_spanner.odin",
    "rust/s/baswana_sen_weighted_spanner.rs",
    "v/s/baswana_sen_weighted_spanner.v",
    "zig/s/baswana_sen_weighted_spanner.zig",
)
CASE_IDS = {
    "empty-edge-list",
    "no-sampled-cluster-retains-triangle",
    "sampled-merge-prunes-intra-cluster-edge",
    "two-clustering-rounds-join-distinct-sampled-centers",
    "equal-weight-sampled-edge-tie",
    "disconnected-component-is-retained",
    "maximum-complete-graph-unmasked",
    "sample-mask-outside-vertex-domain",
    "invalid-k-one",
    "reversed-edge-endpoints",
    "duplicate-edge",
    "trailing-input-word",
    "insufficient-output-capacity",
    "null-output-for-empty-result",
    "null-input",
}


def validate_package() -> None:
    if (MAX_VALID_INPUT_LENGTH, MAX_PARSEABLE_INPUT_LENGTH, MAX_OUTPUT_BYTES) != (89, 90, 28):
        raise ValueError("oracle bounds differ from the bounded profile")
    for relative in PORTS:
        if not (ROOT / relative).is_file():
            raise ValueError(f"missing port: {relative}")
    if not (PACKAGE / "README.md").is_file() or not (PACKAGE / "RIGHTS.md").is_file():
        raise ValueError("package documentation is incomplete")
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("algorithm") != "baswana_sen_weighted_spanner"
            or workload.get("function_symbol") != "baswana_sen_weighted_spanner"
            or workload.get("abi") != "i64_array_bytes_output"):
        raise ValueError("workload identity or ABI differs from the profile")
    cases = workload.get("cases")
    if not isinstance(cases, list) or {case.get("id") for case in cases} != CASE_IDS:
        raise ValueError("workload fixture identifiers differ from the checker")
    for case in cases:
        values = case.get("input_values")
        expected = (case.get("expected_result"), bytes.fromhex(case.get("expected_output_hex", "")))
        kwargs = {
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        if primary_oracle(values, **kwargs) != expected:
            raise ValueError(f"primary oracle disagrees with workload case {case['id']}")
        if independent_oracle(values, **kwargs) != expected:
            raise ValueError(f"independent oracle disagrees with workload case {case['id']}")
