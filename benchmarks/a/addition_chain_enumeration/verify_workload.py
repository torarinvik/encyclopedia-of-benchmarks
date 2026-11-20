"""Static package and fixture inventory; never launches language programs."""
from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import verify_result
    from .primary_oracle import MAX_OUTPUT_BYTES, MAX_TARGET, expected_output
except ImportError:
    from independent_oracle import verify_result
    from primary_oracle import MAX_OUTPUT_BYTES, MAX_TARGET, expected_output

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "addition_chain_enumeration"
LANGUAGE_PATHS = {
    "c": ROOT / "c/a/addition_chain_enumeration.c",
    "c3": ROOT / "c3/a/addition_chain_enumeration.c3",
    "cpp": ROOT / "cpp/a/addition_chain_enumeration.cpp",
    "elisa": ROOT / "elisa/a/addition_chain_enumeration.elisa",
    "mojo": ROOT / "mojo/a/addition_chain_enumeration.mojo",
    "nim": ROOT / "nim/a/addition_chain_enumeration.nim",
    "odin": ROOT / "odin/a/addition_chain_enumeration.odin",
    "rust": ROOT / "rust/a/addition_chain_enumeration.rs",
    "v": ROOT / "v/a/addition_chain_enumeration.v",
    "zig": ROOT / "zig/a/addition_chain_enumeration.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]
    if workload.get("function_symbol") != SYMBOL or workload.get("abi") != "i64_array_bytes_output":
        issues.append("unexpected symbol or ABI")
    if workload.get("input", {}).get("target_range") != [1, MAX_TARGET]:
        issues.append("target bound mismatch")
    if workload.get("output", {}).get("maximum_bytes") != MAX_OUTPUT_BYTES:
        issues.append("output bound mismatch")
    for case in workload.get("cases", []):
        result, payload = expected_output(
            case.get("input_values", []), capacity=case.get("output_capacity"),
            output_is_null=case.get("output_is_null", False),
            input_length=case.get("input_length"),
        )
        case_id = case.get("id")
        if result != case.get("expected_result") or payload.hex() != case.get("expected_output_hex"):
            issues.append(f"primary oracle fixture mismatch: {case_id}")
        if not verify_result(
                case.get("input_values", []), result, payload,
                output_capacity=case.get("output_capacity"),
                output_is_null=case.get("output_is_null", False),
                input_length=case.get("input_length")):
            issues.append(f"independent oracle rejected fixture: {case_id}")
    for language, path in LANGUAGE_PATHS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol in {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file {name}")
    return issues
