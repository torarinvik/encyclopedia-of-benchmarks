"""Static inventory and fixture-shape verifier; it never compiles or runs ports."""

from __future__ import annotations

import json
from pathlib import Path
import re
import sys
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[2]
PACKAGE = ROOT / "t" / "two_vertex_cuts_spqr"
LANGUAGES = {
    "c": "c",
    "c3": "c3",
    "cpp": "cpp",
    "elisa": "elisa",
    "mojo": "mojo",
    "nim": "nim",
    "odin": "odin",
    "rust": "rs",
    "v": "v",
    "zig": "zig",
}
SOURCE_URL = "https://github.com/yosupo06/library-checker-problems/issues/1427"
CASE_IDS = {
    "triangle_no_two_cut",
    "cycle_four_weighted_opposite_pairs",
    "cycle_eight_skeleton",
    "complete_four_rigid_piece",
    "complete_eight_maximum_frame",
    "two_paths_merge_to_series_cycle",
    "parallel_three_branch_pole_pair",
    "parallel_six_branches_pole_pair",
    "parallel_branches_with_real_pole_edge",
    "mixed_r_p_s_structure_zero_weights",
    "maximum_weights_modular_reduction",
    "maximum_weight_with_zero_contribution",
    "invalid_articulation_vertex",
    "invalid_duplicate_edge",
    "invalid_loop",
    "invalid_weight",
    "malformed_edge_record",
    "maximum_parseable_trailing_value",
    "null_input_pointer_with_positive_length",
}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def validate_workload(workload: object) -> None:
    require(isinstance(workload, dict), "workload root must be an object")
    require(workload.get("schema_version") == 1, "unsupported workload schema")
    require(workload.get("id") == "library-checker-two-vertex-cuts-bounded-spqr-v1", "workload id mismatch")
    require(workload.get("algorithm") == "two_vertex_cuts_spqr", "algorithm name mismatch")
    require(workload.get("function_symbol") == "two_vertex_cuts_spqr", "symbol mismatch")
    require(workload.get("abi") == "i64_array_scalar", "ABI mismatch")
    require(workload.get("source_basis") == {
        "organization": "Library Checker problem proposal",
        "title": "Two-Vertex Cuts",
        "url": SOURCE_URL,
        "role": "problem_definition",
    }, "source metadata mismatch")
    input_contract = workload.get("input")
    require(isinstance(input_contract, dict), "input contract must be an object")
    require(input_contract.get("vertex_count_range") == [3, 8], "vertex bound mismatch")
    require(input_contract.get("edge_count_range") == [3, 28], "edge bound mismatch")
    require(input_contract.get("weight_range") == [0, 1000000], "weight bound mismatch")
    require(input_contract.get("maximum_valid_input_length") == 66, "valid input bound mismatch")
    require(input_contract.get("maximum_parseable_input_length") == 67, "parseable input bound mismatch")
    require(input_contract.get("invalid_result") == -1, "invalid result mismatch")
    cases = workload.get("cases")
    require(isinstance(cases, list), "cases must be an array")
    ids = [case.get("id") for case in cases if isinstance(case, dict)]
    require(len(ids) == len(cases) and len(set(ids)) == len(ids), "case IDs must be unique")
    require(set(ids) == CASE_IDS, "fixture inventory mismatch")
    for case in cases:
        values = case.get("input_values")
        require(isinstance(values, list), f"{case['id']}: input_values must be a list")
        require(type(case.get("expected_result")) is int, f"{case['id']}: expected result must be an integer")
        is_null = case.get("input_is_null", False)
        require(type(is_null) is bool, f"{case['id']}: null flag must be boolean")
        input_length = case.get("input_length", len(values))
        require(type(input_length) is int, f"{case['id']}: input length must be an integer")
        if is_null:
            require(case["id"] == "null_input_pointer_with_positive_length", "unexpected null case")
            require(values == [] and input_length == 1, "null-input framing mismatch")
        elif case["id"] == "maximum_parseable_trailing_value":
            require(len(values) == 67 and input_length == 67, "maximum parseable fixture length mismatch")
        else:
            require(input_length == len(values), f"{case['id']}: declared input length mismatch")
            if case["id"] not in {"malformed_edge_record"}:
                require(len(values) == 2 + values[0] + 2 * values[1], f"{case['id']}: packed shape mismatch")


def validate_sources() -> None:
    for language, extension in LANGUAGES.items():
        source = ROOT.parent / language / "t" / f"two_vertex_cuts_spqr.{extension}"
        require(source.is_file(), f"missing {language} port")
        require("two_vertex_cuts_spqr" in source.read_text(encoding="utf-8"), f"{language} symbol missing")
    for path in (
        PACKAGE / "two_vertex_cuts_spqr_oracle.py",
        PACKAGE / "two_vertex_cuts_spqr_independent_oracle.py",
    ):
        require(path.is_file(), f"missing oracle: {path.name}")


def validate_readme_targets(readme: str) -> None:
    for raw_target in re.findall(r"\]\(([^)]+)\)", readme):
        target = unquote(raw_target.strip().split("#", 1)[0])
        if not target or "://" in target or target.startswith("mailto:"):
            continue
        destination = (PACKAGE / target).resolve()
        require(destination.is_file(), f"README target does not exist: {raw_target}")


def main() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    validate_workload(workload)
    validate_sources()
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    validate_readme_targets(readme)
    require(SOURCE_URL in readme and SOURCE_URL in rights, "proposal provenance is missing")
    require("two_vertex_cuts_spqr_oracle.py" in readme, "primary oracle is undocumented")
    require("two_vertex_cuts_spqr_independent_oracle.py" in readme, "independent oracle is undocumented")
    print("two_vertex_cuts_spqr static inventory and fixture shapes checked")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"FAIL two_vertex_cuts_spqr static verification: {error}", file=sys.stderr)
        raise SystemExit(1)
