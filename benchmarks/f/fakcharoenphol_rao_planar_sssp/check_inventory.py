"""Source-only package and fixture inventory checks."""
from __future__ import annotations

import json
from pathlib import Path

try:
    from .primary_oracle import (
        MAX_INPUT_LENGTH,
        MAX_N,
        MAX_OUTPUT_BYTES,
        MAX_PIECES,
        MAX_WORKSPACE_BYTES,
        expected_output as primary_expected,
    )
    from .independent_oracle import (
        expected_output as independent_expected,
    )
except ImportError:
    from primary_oracle import (
        MAX_INPUT_LENGTH,
        MAX_N,
        MAX_OUTPUT_BYTES,
        MAX_PIECES,
        MAX_WORKSPACE_BYTES,
        expected_output as primary_expected,
    )
    from independent_oracle import (
        expected_output as independent_expected,
    )

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "fakcharoenphol_rao_planar_sssp"
LANGUAGE_PATHS = {
    "c": ROOT / "c/f/fakcharoenphol_rao_planar_sssp.c",
    "c3": ROOT / "c3/f/fakcharoenphol_rao_planar_sssp.c3",
    "cpp": ROOT / "cpp/f/fakcharoenphol_rao_planar_sssp.cpp",
    "elisa": ROOT / "elisa/f/fakcharoenphol_rao_planar_sssp.elisa",
    "mojo": ROOT / "mojo/f/fakcharoenphol_rao_planar_sssp.mojo",
    "nim": ROOT / "nim/f/fakcharoenphol_rao_planar_sssp.nim",
    "odin": ROOT / "odin/f/fakcharoenphol_rao_planar_sssp.odin",
    "rust": ROOT / "rust/f/fakcharoenphol_rao_planar_sssp.rs",
    "v": ROOT / "v/f/fakcharoenphol_rao_planar_sssp.v",
    "zig": ROOT / "zig/f/fakcharoenphol_rao_planar_sssp.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]

    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("id") != "fakcharoenphol-rao-planar-sssp-bounded-ddg-monge-i64le-v1"):
        issues.append("unexpected workload identity or ABI")
    input_meta = workload.get("input", {})
    if (input_meta.get("maximum_valid_length") != MAX_INPUT_LENGTH
            or input_meta.get("maximum_parseable_length") != MAX_INPUT_LENGTH
            or input_meta.get("vertex_range") != [2, MAX_N]
            or input_meta.get("maximum_pieces") != MAX_PIECES):
        issues.append("input bounds differ from the bounded profile")
    profile = workload.get("algorithm_profile", {})
    if (profile.get("maximum_output_bytes") != MAX_OUTPUT_BYTES
            or profile.get("workspace_bytes") != MAX_WORKSPACE_BYTES
            or "direct scans" not in profile.get("bounded_data_structure", "")):
        issues.append("output/workspace or bounded online-Monge profile mismatch")
    if workload.get("measurement", {}).get("comparison_model") != "i64_array_bytes_output_call":
        issues.append("unexpected comparison model")

    cases = workload.get("cases", [])
    ids = [case.get("id") for case in cases if isinstance(case, dict)]
    required_ids = {
        "square-with-negative-arcs-and-two-level-ddgs",
        "single-directed-edge-negative-shortest-distance",
        "single-directed-edge-unreachable-source-output",
        "negative-two-cycle-rejected",
        "root-boundary-does-not-match-source",
        "short-output-capacity",
        "null-output",
    }
    if (not isinstance(cases, list) or set(ids) != required_ids
            or len(ids) != len(cases) or len(set(ids)) != len(ids)):
        issues.append("workload fixture identifiers differ from the reviewed corpus")

    for case in cases:
        if not isinstance(case, dict):
            continue
        kwargs = {
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        primary_result, primary_bytes = primary_expected(case.get("input_values", []), **kwargs)
        independent_result, independent_bytes = independent_expected(case.get("input_values", []), **kwargs)
        expected_hex = case.get("expected_output_hex", "").lower()
        if (primary_result != case.get("expected_result")
                or primary_bytes.hex() != expected_hex):
            issues.append(f"primary reference fixture mismatch: {case.get('id')}")
        if (independent_result != case.get("expected_result")
                or independent_bytes.hex() != expected_hex):
            issues.append(f"independent Bellman-Ford fixture mismatch: {case.get('id')}")

    for language, path in LANGUAGE_PATHS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol in {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
                 "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file {name}")
    return issues
