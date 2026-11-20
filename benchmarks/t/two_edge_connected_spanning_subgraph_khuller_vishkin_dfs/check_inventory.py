"""Static package/fixture inventory check; does not compile or run benchmark ports."""
from __future__ import annotations

import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
PACKAGE = ROOT / "t" / "two_edge_connected_spanning_subgraph_khuller_vishkin_dfs"
SYMBOL = "two_edge_connected_spanning_subgraph_khuller_vishkin_dfs"
LANGUAGES = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
CASE_IDS = {
    "triangle_all_edges", "cycle_four_dfs_path", "k23_two_back_edges",
    "complete_eight_maximum_frame", "invalid_bridge", "invalid_duplicate_edge",
    "invalid_endpoint", "invalid_length", "maximum_parseable_trailing_value",
    "null_input", "null_output", "short_output",
}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def validate_workload() -> None:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    require(workload.get("schema_version") == 1, "schema version mismatch")
    require(workload.get("algorithm") == SYMBOL and workload.get("function_symbol") == SYMBOL,
            "algorithm/symbol mismatch")
    require(workload.get("abi") == "i64_array_bytes_output", "ABI mismatch")
    source = workload.get("source", {})
    require("Biconnectivity Approximations" in source.get("title", ""), "source title mismatch")
    require("§3.1" in source.get("algorithm_attribution", ""), "source procedure mismatch")
    inp = workload.get("input", {})
    require(inp.get("vertex_count_range") == [3, 8], "vertex bound mismatch")
    require(inp.get("edge_count_range") == [3, 28], "edge bound mismatch")
    require(inp.get("maximum_valid_length") == 58, "valid input bound mismatch")
    require(inp.get("maximum_parseable_length") == 59, "parseable input bound mismatch")
    out = workload.get("output", {})
    require(out.get("maximum_bytes") == 456, "output bound mismatch")
    cases = workload.get("cases")
    require(isinstance(cases, list), "cases must be a list")
    ids = [case.get("id") for case in cases if isinstance(case, dict)]
    require(len(ids) == len(cases) and len(ids) == len(set(ids)), "duplicate/malformed case IDs")
    require(set(ids) == CASE_IDS, "fixture ID inventory mismatch")
    for case in cases:
        vals = case.get("input_values")
        require(isinstance(vals, list), f"{case['id']}: input_values missing")
        length = case.get("input_length")
        require(type(length) is int, f"{case['id']}: input_length missing")
        require(type(case.get("expected_result")) is int, f"{case['id']}: expected result missing")
        expected_hex = case.get("expected_output_hex")
        require(isinstance(expected_hex, str) and len(expected_hex) % 2 == 0,
                f"{case['id']}: malformed expected output")
        null_input = case.get("input_is_null", False)
        if null_input:
            require(case["id"] == "null_input" and vals == [] and length == 0, "null input mismatch")
        elif case["id"] == "maximum_parseable_trailing_value":
            require(length == len(vals) == 59, "maximum parseable case mismatch")
        else:
            require(length == len(vals), f"{case['id']}: input length mismatch")
        result = case["expected_result"]
        if result >= 0:
            require(result == len(expected_hex) // 2, f"{case['id']}: output byte count mismatch")
            require(result <= case.get("output_capacity", 0), f"{case['id']}: capacity too small")
        else:
            require(expected_hex == "", f"{case['id']}: failure output must be empty")


def validate_sources_and_links() -> None:
    for language, extension in LANGUAGES.items():
        source = ROOT.parent / language / "t" / f"{SYMBOL}.{extension}"
        require(source.is_file(), f"missing {language} port: {source}")
        require(SYMBOL in source.read_text(encoding="utf-8"), f"{language} symbol not found")
    for name in ("primary_oracle.py", "independent_oracle.py", "verify_workload.py",
                 "README.md", "RIGHTS.md"):
        require((PACKAGE / name).is_file(), f"missing package file {name}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for target in re.findall(r"\]\(([^)]+)\)", readme):
        if "://" in target or target.startswith("#"):
            continue
        require((PACKAGE / target).resolve().is_file(), f"README target missing: {target}")


def main() -> int:
    validate_workload()
    validate_sources_and_links()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
