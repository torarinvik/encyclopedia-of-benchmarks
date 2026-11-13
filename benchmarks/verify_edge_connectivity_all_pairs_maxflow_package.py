"""Static inventory and fixture verifier; not executed during source-only work."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
from types import ModuleType

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/e/edge_connectivity_all_pairs_maxflow"
SOURCES = {
    "c": ROOT / "c/e/edge_connectivity_all_pairs_maxflow.c",
    "c3": ROOT / "c3/e/edge_connectivity_all_pairs_maxflow.c3",
    "cpp": ROOT / "cpp/e/edge_connectivity_all_pairs_maxflow.cpp",
    "elisa": ROOT / "elisa/e/edge_connectivity_all_pairs_maxflow.elisa",
    "mojo": ROOT / "mojo/e/edge_connectivity_all_pairs_maxflow.mojo",
    "nim": ROOT / "nim/e/edge_connectivity_all_pairs_maxflow.nim",
    "odin": ROOT / "odin/e/edge_connectivity_all_pairs_maxflow.odin",
    "rust": ROOT / "rust/e/edge_connectivity_all_pairs_maxflow.rs",
    "v": ROOT / "v/e/edge_connectivity_all_pairs_maxflow.v",
    "zig": ROOT / "zig/e/edge_connectivity_all_pairs_maxflow.zig",
}
EXPECTED_CASES = {
    "two_isolated_vertices", "single_bridge", "path_five", "cycle_five",
    "two_triangles_two_links", "complete_five", "complete_ten_maximum_frame",
    "repeated_edge_invalid", "self_loop_invalid", "endpoint_out_of_range",
    "trailing_word", "null_input",
}


def _load_oracle(name: str) -> ModuleType | None:
    path = PACKAGE / f"{name}_oracle.py"
    spec = importlib.util.spec_from_file_location(f"edge_connectivity_{name}_oracle", path)
    if spec is None or spec.loader is None:
        return None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def static_issues() -> list[str]:
    issues: list[str] = []
    required = (
        PACKAGE / "README.md",
        PACKAGE / "RIGHTS.md",
        PACKAGE / "workload.json",
        PACKAGE / "primary_oracle.py",
        PACKAGE / "independent_oracle.py",
    )
    for path in required:
        if not path.is_file():
            issues.append(f"missing {path.relative_to(ROOT)}")
    for language, path in SOURCES.items():
        if not path.is_file():
            issues.append(f"missing {path.relative_to(ROOT)}")
            continue
        source = path.read_text(encoding="utf-8")
        if "edge_connectivity_all_pairs_maxflow" not in source:
            issues.append(f"{path.relative_to(ROOT)} lacks the exported ABI symbol")
        if language == "elisa" and ("UnsafePointer" in source or "*i64" in source):
            issues.append("Elisa must use fixed storage internally and ABI references only")

    workload_path = PACKAGE / "workload.json"
    if workload_path.is_file():
        try:
            workload = json.loads(workload_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            issues.append(f"invalid workload JSON: {error}")
        else:
            input_spec = workload.get("input", {})
            workspace = workload.get("workspace", {})
            cases = workload.get("cases")
            case_ids = (
                {case.get("id") for case in cases}
                if isinstance(cases, list) and all(isinstance(case, dict) for case in cases)
                else set()
            )
            if (
                workload.get("algorithm") != "edge_connectivity_all_pairs_maxflow"
                or workload.get("function_symbol") != "edge_connectivity_all_pairs_maxflow"
                or workload.get("abi") != "i64_array_scalar"
                or input_spec.get("maximum_valid_input_length") != 92
                or input_spec.get("maximum_parseable_input_length") != 93
                or workspace.get("bytes") != 4096
            ):
                issues.append("workload metadata differs from the bounded scalar contract")
            if case_ids != EXPECTED_CASES:
                issues.append("workload case inventory differs from the reviewed fixture set")

    for oracle_name, tokens in {
        "primary": ("def _max_flow(", "for sink in range(source + 1, vertex_count):"),
        "independent": ("for side in range(1, (1 << vertex_count) - 1):", "crossing = sum("),
    }.items():
        path = PACKAGE / f"{oracle_name}_oracle.py"
        if path.is_file():
            source = path.read_text(encoding="utf-8")
            for token in tokens:
                if token not in source:
                    issues.append(f"{path.relative_to(ROOT)} missing expected token {token!r}")
    return issues


def verify_workload() -> list[str]:
    """Compare fixtures with the all-pairs-flow and direct-cut oracles."""
    issues = static_issues()
    workload_path = PACKAGE / "workload.json"
    if issues or not workload_path.is_file():
        return issues
    primary = _load_oracle("primary")
    independent = _load_oracle("independent")
    if primary is None or independent is None:
        return ["could not load package oracle modules"]
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    for case in workload["cases"]:
        values = case.get("input_values", [])
        keywords = {
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        expected = case.get("expected_result")
        for label, module in (("primary", primary), ("independent", independent)):
            actual = module.expected_result(values, **keywords)
            if actual != expected:
                issues.append(f"{label} oracle disagrees with workload case {case.get('id')}")
    return issues
