"""Static package inventory review; this checker never launches language ports."""

from __future__ import annotations

import json
from pathlib import Path

from lowest_common_ancestor_farach_colton_bender_oracle import expected_output
from lowest_common_ancestor_farach_colton_bender_verifier_oracle import verify_result

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/l/lowest_common_ancestor_farach_colton_bender"
LANGUAGE_PATHS = {
    "c": ROOT / "c/l/lowest_common_ancestor_farach_colton_bender.c",
    "c3": ROOT / "c3/l/lowest_common_ancestor_farach_colton_bender.c3",
    "cpp": ROOT / "cpp/l/lowest_common_ancestor_farach_colton_bender.cpp",
    "elisa": ROOT / "elisa/l/lowest_common_ancestor_farach_colton_bender.elisa",
    "mojo": ROOT / "mojo/l/lowest_common_ancestor_farach_colton_bender.mojo",
    "nim": ROOT / "nim/l/lowest_common_ancestor_farach_colton_bender.nim",
    "odin": ROOT / "odin/l/lowest_common_ancestor_farach_colton_bender.odin",
    "rust": ROOT / "rust/l/lowest_common_ancestor_farach_colton_bender.rs",
    "v": ROOT / "v/l/lowest_common_ancestor_farach_colton_bender.v",
    "zig": ROOT / "zig/l/lowest_common_ancestor_farach_colton_bender.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text())
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]
    if workload.get("function_symbol") != "lowest_common_ancestor_farach_colton_bender":
        issues.append("unexpected exported function symbol")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("unexpected ABI")
    input_meta = workload.get("input", {})
    if input_meta.get("node_count_range") != [1, 256] or input_meta.get("query_count_range") != [0, 1024]:
        issues.append("bounded input shape mismatch")
    if input_meta.get("maximum_length") != 2562:
        issues.append("maximum input length mismatch")
    if workload.get("output", {}).get("maximum_bytes") != 1024:
        issues.append("maximum output capacity mismatch")
    for case in workload.get("cases", []):
        values = case.get("input_values", [])
        result, payload = expected_output(
            values,
            capacity=case.get("output_capacity"),
            output_is_null=case.get("output_is_null", False),
            input_is_null=case.get("input_is_null", False),
            input_length=case.get("input_length"),
        )
        case_id = case.get("id")
        if result != case.get("expected_result"):
            issues.append(f"primary oracle result mismatch in {case_id}")
        if payload.hex() != case.get("expected_output_hex"):
            issues.append(f"primary oracle bytes mismatch in {case_id}")
        if not verify_result(
            values,
            result,
            payload,
            output_capacity=case.get("output_capacity"),
            output_is_null=case.get("output_is_null", False),
            input_is_null=case.get("input_is_null", False),
            input_length=case.get("input_length"),
        ):
            issues.append(f"independent verifier rejected workload case {case_id}")
    for language, path in LANGUAGE_PATHS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif "lowest_common_ancestor_farach_colton_bender" not in path.read_text():
            issues.append(f"missing exported symbol text in {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document {name}")
    for name in (
        "lowest_common_ancestor_farach_colton_bender_oracle.py",
        "lowest_common_ancestor_farach_colton_bender_verifier_oracle.py",
    ):
        if not (ROOT / "benchmarks" / name).is_file():
            issues.append(f"missing oracle {name}")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
