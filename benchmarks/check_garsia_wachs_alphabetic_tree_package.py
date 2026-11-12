"""Static package inventory review; this checker never launches language ports."""

from __future__ import annotations

import json
from pathlib import Path

from garsia_wachs_alphabetic_tree_oracle import expected_output
from garsia_wachs_alphabetic_tree_verifier_oracle import verify_result

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/g/garsia_wachs_alphabetic_tree"
LANGUAGE_PATHS = {
    "c": ROOT / "c/g/garsia_wachs_alphabetic_tree.c",
    "c3": ROOT / "c3/g/garsia_wachs_alphabetic_tree.c3",
    "cpp": ROOT / "cpp/g/garsia_wachs_alphabetic_tree.cpp",
    "elisa": ROOT / "elisa/g/garsia_wachs_alphabetic_tree.elisa",
    "mojo": ROOT / "mojo/g/garsia_wachs_alphabetic_tree.mojo",
    "nim": ROOT / "nim/g/garsia_wachs_alphabetic_tree.nim",
    "odin": ROOT / "odin/g/garsia_wachs_alphabetic_tree.odin",
    "rust": ROOT / "rust/g/garsia_wachs_alphabetic_tree.rs",
    "v": ROOT / "v/g/garsia_wachs_alphabetic_tree.v",
    "zig": ROOT / "zig/g/garsia_wachs_alphabetic_tree.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text())
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]
    if workload.get("function_symbol") != "garsia_wachs_alphabetic_tree":
        issues.append("unexpected exported function symbol")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("unexpected ABI")
    input_meta = workload.get("input", {})
    if input_meta.get("n_range") != [1, 64] or input_meta.get("weight_range") != [0, 1_000_000]:
        issues.append("bounded input shape mismatch")
    if input_meta.get("maximum_valid_length") != 65:
        issues.append("maximum valid input length mismatch")
    if workload.get("output", {}).get("maximum_bytes") != 520:
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
            issues.append(f"independent oracle rejected workload case {case_id}")
    for language, path in LANGUAGE_PATHS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif "garsia_wachs_alphabetic_tree" not in path.read_text():
            issues.append(f"missing exported symbol text in {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document {name}")
    for name in (
        "garsia_wachs_alphabetic_tree_oracle.py",
        "garsia_wachs_alphabetic_tree_verifier_oracle.py",
    ):
        if not (ROOT / "benchmarks" / name).is_file():
            issues.append(f"missing oracle {name}")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
