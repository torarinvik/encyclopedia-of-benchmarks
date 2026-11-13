"""Static inventory and fixture checks; this file is intentionally not run here."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
from types import ModuleType

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/i/indexed_block_list"
SOURCES = {
    "c": ROOT / "c/i/indexed_block_list.c",
    "c3": ROOT / "c3/i/indexed_block_list.c3",
    "cpp": ROOT / "cpp/i/indexed_block_list.cpp",
    "elisa": ROOT / "elisa/i/indexed_block_list.elisa",
    "mojo": ROOT / "mojo/i/indexed_block_list.mojo",
    "nim": ROOT / "nim/i/indexed_block_list.nim",
    "odin": ROOT / "odin/i/indexed_block_list.odin",
    "rust": ROOT / "rust/i/indexed_block_list.rs",
    "v": ROOT / "v/i/indexed_block_list.v",
    "zig": ROOT / "zig/i/indexed_block_list.zig",
}
EXPECTED_CASES = {
    "empty_sequence", "maximum_frame_and_output", "access_initial_items",
    "interior_insert_split_and_front_insert", "repeated_interior_split",
    "zero_access_null_output", "malformed_opcode", "out_of_range_access",
    "insert_past_end", "trailing_word", "null_input", "null_output_for_access",
    "short_output_capacity",
}
NULL_INPUT_GUARDS = {
    "c": "input == NULL",
    "c3": "input == null",
    "cpp": "input == nullptr",
    "elisa": "values.is_null()",
    "mojo": "UnsafePointer[Int64, ImmutAnyOrigin]()",
    "nim": "input == nil",
    "odin": "input == nil",
    "rust": "input.is_null()",
    "v": "input == nil",
    "zig": "input == null",
}
NULL_OUTPUT_GUARDS = {
    "c": "output == NULL",
    "c3": "output == null",
    "cpp": "output == nullptr",
    "elisa": "output.is_null()",
    "mojo": "UnsafePointer[UInt8, MutAnyOrigin]()",
    "nim": "output == nil",
    "odin": "output == nil",
    "rust": "output.is_null()",
    "v": "output == nil",
    "zig": "output == null",
}


def _load_oracle(name: str) -> ModuleType | None:
    path = PACKAGE / f"{name}_oracle.py"
    spec = importlib.util.spec_from_file_location(f"indexed_block_list_{name}_oracle", path)
    if spec is None or spec.loader is None:
        return None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def static_issues() -> list[str]:
    issues: list[str] = []
    for path in (PACKAGE / "README.md", PACKAGE / "RIGHTS.md", PACKAGE / "workload.json",
                 PACKAGE / "primary_oracle.py", PACKAGE / "independent_oracle.py"):
        if not path.is_file():
            issues.append(f"missing {path.relative_to(ROOT)}")
    for language, path in SOURCES.items():
        if not path.is_file():
            issues.append(f"missing {path.relative_to(ROOT)}")
            continue
        source = path.read_text(encoding="utf-8")
        if "indexed_block_list" not in source:
            issues.append(f"{path.relative_to(ROOT)} lacks the exported ABI symbol")
        if NULL_INPUT_GUARDS[language] not in source:
            issues.append(f"{path.relative_to(ROOT)} lacks its null-input guard")
        if NULL_OUTPUT_GUARDS[language] not in source:
            issues.append(f"{path.relative_to(ROOT)} lacks its null-output guard")
        if language == "elisa" and any(token in source for token in ("UnsafePointer", "*i64", "*u8")):
            issues.append("Elisa implementation must use fixed safe storage and ABI references only")

    workload_path = PACKAGE / "workload.json"
    if workload_path.is_file():
        try:
            workload = json.loads(workload_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            issues.append(f"invalid workload JSON: {error}")
        else:
            input_spec = workload.get("input", {})
            output_spec = workload.get("output", {})
            cases = workload.get("cases")
            case_ids = ({case.get("id") for case in cases}
                        if isinstance(cases, list) and all(isinstance(case, dict) for case in cases)
                        else set())
            max_case = next((case for case in cases if case.get("id") == "maximum_frame_and_output"), {}) if isinstance(cases, list) else {}
            if (workload.get("algorithm") != "indexed_block_list"
                    or workload.get("function_symbol") != "indexed_block_list"
                    or workload.get("abi") != "i64_array_bytes_output"
                    or input_spec.get("block_size") != 4
                    or input_spec.get("maximum_valid_input_length") != 178
                    or input_spec.get("maximum_parseable_input_length") != 179
                    or output_spec.get("maximum_output_bytes") != 256
                    or workload.get("workspace", {}).get("bytes") != 4096
                    or workload.get("measurement", {}).get("comparison_model")
                    != "i64_array_bytes_output_call"):
                issues.append("workload metadata differs from the bounded block-list contract")
            if case_ids != EXPECTED_CASES:
                issues.append("workload case inventory differs from the reviewed fixture set")
            if (len(max_case.get("input_values", [])) != 178
                    or max_case.get("expected_result") != 256
                    or len(max_case.get("expected_output_hex", "")) != 512):
                issues.append("maximum-frame/output fixture does not reach its declared bounds")
    return issues


def verify_workload() -> list[str]:
    """Compare declared fixtures with both Python oracles without launching ports."""
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
        args = case.get("input_values", [])
        kwargs = {
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        expected = (case.get("expected_result"), bytes.fromhex(case.get("expected_output_hex", "")))
        for label, oracle in (("primary", primary), ("independent", independent)):
            if oracle.expected_output(args, **kwargs) != expected:
                issues.append(f"{label} oracle disagrees with workload case {case.get('id')}")
    return issues
