"""Static workload and source-path validation for the Manhattan MST package."""

from __future__ import annotations

import json
from pathlib import Path

from manhattan_mst_oracle import MAX_INPUT_LENGTH, MAX_POINTS, expected_output


ROOT = Path(__file__).resolve().parent
PACKAGE = ROOT / "m" / "manhattan_mst"
OFFICIAL_URL = "https://judge.yosupo.jp/problem/manhattanmst"
PORTS = {
    "c": "c/m/manhattan_mst.c",
    "c3": "c3/m/manhattan_mst.c3",
    "cpp": "cpp/m/manhattan_mst.cpp",
    "elisa": "elisa/m/manhattan_mst.elisa",
    "nim": "nim/m/manhattan_mst.nim",
    "odin": "odin/m/manhattan_mst.odin",
    "rust": "rust/m/manhattan_mst.rs",
    "v": "v/m/manhattan_mst.v",
    "zig": "zig/m/manhattan_mst.zig",
}
EXPECTED_CASE_IDS = {
    "single-point", "two-points-3-4-offset", "equal-distance-triangle",
    "duplicate-points", "unit-square-tied-mst", "opposite-coordinate-bounds",
    "maximum-size-collinear-points", "zero-points-invalid",
    "point-count-above-bound", "wrong-packed-length", "coordinate-below-bound",
    "coordinate-above-bound", "empty-array-invalid",
}


def validate_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    expected_source = {
        "name": "Library Checker Manhattan MST",
        "url": OFFICIAL_URL,
        "taxonomy_note": "The task asks for an MST over points with pairwise Manhattan edge weights.",
    }
    expected_input = {
        "kind": "signed_64_bit_integer_array",
        "encoding": "[n, x0, y0, ..., x(n-1), y(n-1)]",
        "point_count_range": [1, MAX_POINTS],
        "coordinate_range": [-1_000_000, 1_000_000],
        "maximum_valid_length": MAX_INPUT_LENGTH,
        "distance": "abs(x_i - x_j) + abs(y_i - y_j)",
        "duplicate_points": "allowed; their pairwise distance is zero",
        "invalid_input_result": -1,
    }
    expected_output = {
        "kind": "signed_64_bit_integer",
        "meaning": "minimum total Manhattan distance of a spanning tree",
        "single_point_result": 0,
        "invalid_input_result": -1,
        "maximum_result": 124_000_000,
    }
    expected_contract = {
        "operation": "Compute an MST of the implicit complete graph whose edge weight is the Manhattan distance between its endpoint coordinates.",
        "algorithm": "Prim over the complete metric graph, scanning all unselected points for each selected point.",
        "complexity": "O(n^2) time and O(n) auxiliary space.",
        "explicit_edge_list": False,
        "invalid_input_result": -1,
    }
    expected_measurement = {
        "comparison_model": "i64_array_scalar_call",
        "sample_count": 6,
        "warmup_rounds": 2,
        "repetitions_per_sample": 500,
    }
    if (workload.get("schema_version") != 1
            or workload.get("id") != "manhattan-mst-complete-metric-i64-array-scalar-v1"
            or workload.get("algorithm") != "manhattan_mst"
            or workload.get("function_symbol") != "manhattan_mst"
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("source") != expected_source
            or workload.get("input") != expected_input
            or workload.get("output") != expected_output
            or workload.get("contract") != expected_contract
            or workload.get("measurement") != expected_measurement):
        raise ValueError("manhattan_mst workload metadata differs from its bounded contract")

    cases = workload.get("cases")
    if (not isinstance(cases, list)
            or {case.get("id") for case in cases if isinstance(case, dict)} != EXPECTED_CASE_IDS
            or len(cases) != len(EXPECTED_CASE_IDS)):
        raise ValueError("manhattan_mst workload has missing or unexpected cases")
    for case in cases:
        values = case.get("input_values")
        if (not isinstance(values, list) or type(case.get("input_length")) is not int
                or case["input_length"] != len(values)
                or type(case.get("expected_result")) is not int
                or case["expected_result"] != expected_output(values)):
            raise ValueError(f"manhattan_mst fixture mismatch: {case.get('id')}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    if (OFFICIAL_URL not in readme or "explicit-edge" not in readme
            or "O(n^2)" not in readme or "O(n)" not in readme):
        raise ValueError("manhattan_mst README is missing its source, taxonomy, or complexity")
    for language, relative in PORTS.items():
        source = ROOT.parent / relative
        if not source.is_file() or "manhattan_mst" not in source.read_text(encoding="utf-8"):
            raise ValueError(f"manhattan_mst source path is missing its exported symbol: {relative}")
    return len(cases)


if __name__ == "__main__":
    print(f"validated {validate_workload()} Manhattan MST workload cases and {len(PORTS)} source paths")
