"""Static package inventory and fixture-consistency checks; not invoked here."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
from types import ModuleType

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/a/aho_corasick_failure_tree_counts"
SOURCES = {
    "c": ROOT / "c/a/aho_corasick_failure_tree_counts.c",
    "c3": ROOT / "c3/a/aho_corasick_failure_tree_counts.c3",
    "cpp": ROOT / "cpp/a/aho_corasick_failure_tree_counts.cpp",
    "elisa": ROOT / "elisa/a/aho_corasick_failure_tree_counts.elisa",
    "mojo": ROOT / "mojo/a/aho_corasick_failure_tree_counts.mojo",
    "nim": ROOT / "nim/a/aho_corasick_failure_tree_counts.nim",
    "odin": ROOT / "odin/a/aho_corasick_failure_tree_counts.odin",
    "rust": ROOT / "rust/a/aho_corasick_failure_tree_counts.rs",
    "v": ROOT / "v/a/aho_corasick_failure_tree_counts.v",
    "zig": ROOT / "zig/a/aho_corasick_failure_tree_counts.zig",
}
EXPECTED_CASES = {
    "dense_suffix_chain", "deep_dense_suffix_chain", "failure_fallback_and_overlap",
    "no_matches", "empty_text", "duplicate_pattern", "symbol_out_of_profile",
    "trailing_value", "short_output_capacity", "null_input", "null_output",
}


def _load_oracle(name: str) -> ModuleType | None:
    path = PACKAGE / f"{name}_oracle.py"
    spec = importlib.util.spec_from_file_location(f"aho_failure_{name}_oracle", path)
    if spec is None or spec.loader is None:
        return None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def static_issues() -> list[str]:
    issues: list[str] = []
    required = (PACKAGE / "README.md", PACKAGE / "RIGHTS.md", PACKAGE / "workload.json",
                PACKAGE / "primary_oracle.py", PACKAGE / "independent_oracle.py")
    for path in required:
        if not path.is_file():
            issues.append(f"missing {path.relative_to(ROOT)}")
    for language, path in SOURCES.items():
        if not path.is_file():
            issues.append(f"missing {path.relative_to(ROOT)}")
            continue
        source = path.read_text(encoding="utf-8")
        if "aho_corasick_failure_tree_counts" not in source:
            issues.append(f"{path.relative_to(ROOT)} lacks the exported ABI symbol")
        if language == "elisa" and ("UnsafePointer" in source or "*i64" in source or "*u8" in source):
            issues.append("Elisa implementation must use safe fixed storage and ABI references only")

    workload_path = PACKAGE / "workload.json"
    if workload_path.is_file():
        try:
            workload = json.loads(workload_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            issues.append(f"invalid workload JSON: {error}")
        else:
            input_spec = workload.get("input", {})
            output_spec = workload.get("output", {})
            workspace = workload.get("workspace", {})
            cases = workload.get("cases")
            case_ids = ({case.get("id") for case in cases}
                        if isinstance(cases, list) and all(isinstance(case, dict) for case in cases)
                        else set())
            if (workload.get("algorithm") != "aho_corasick_failure_tree_counts"
                    or workload.get("function_symbol") != "aho_corasick_failure_tree_counts"
                    or workload.get("abi") != "i64_array_bytes_output"
                    or input_spec.get("maximum_valid_input_length") != 786
                    or input_spec.get("maximum_parseable_input_length") != 787
                    or input_spec.get("maximum_trie_states") != 513
                    or output_spec.get("maximum_output_bytes") != 128
                    or workspace.get("bytes") != 49152):
                issues.append("workload metadata differs from the bounded byte-output contract")
            if case_ids != EXPECTED_CASES:
                issues.append("workload case inventory differs from the reviewed fixture set")

    for oracle_name, tokens in {
        "primary": ("MAX_VALID_INPUT_LENGTH = 2 + MAX_PATTERNS", "MAX_PARSEABLE_INPUT_LENGTH",
                    "visits[failure[child]] += visits[child]", "struct.pack(\"<q\""),
        "independent": ("MAX_PARSEABLE_INPUT_LENGTH", "for start in range(len(text) - width + 1)",
                        "struct.pack(\"<q\""),
    }.items():
        oracle_path = PACKAGE / f"{oracle_name}_oracle.py"
        if oracle_path.is_file():
            source = oracle_path.read_text(encoding="utf-8")
            for token in tokens:
                if token not in source:
                    issues.append(f"{oracle_path.relative_to(ROOT)} missing expected token {token!r}")
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
        keywords = {
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        expected = (case.get("expected_result"), bytes.fromhex(case.get("expected_output_hex", "")))
        for label, module in (("primary", primary), ("independent", independent)):
            actual = module.expected_output(args, **keywords)
            if actual != expected:
                issues.append(f"{label} oracle disagrees with workload case {case.get('id')}")
    return issues
