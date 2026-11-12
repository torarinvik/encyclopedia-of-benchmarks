"""Static package inventory review; does not launch language ports."""

from __future__ import annotations

import json
from pathlib import Path

from minimum_string_representation_oracle import expected_result
from minimum_string_representation_verifier_oracle import verify_result

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/m/minimum_string_representation"
LANGUAGE_PATHS = {
    "c": ROOT / "c/m/minimum_string_representation.c",
    "c3": ROOT / "c3/m/minimum_string_representation.c3",
    "cpp": ROOT / "cpp/m/minimum_string_representation.cpp",
    "elisa": ROOT / "elisa/m/minimum_string_representation.elisa",
    "mojo": ROOT / "mojo/m/minimum_string_representation.mojo",
    "nim": ROOT / "nim/m/minimum_string_representation.nim",
    "odin": ROOT / "odin/m/minimum_string_representation.odin",
    "rust": ROOT / "rust/m/minimum_string_representation.rs",
    "v": ROOT / "v/m/minimum_string_representation.v",
    "zig": ROOT / "zig/m/minimum_string_representation.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text())
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]
    if workload.get("function_symbol") != "minimum_string_representation":
        issues.append("unexpected exported function symbol")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("unexpected ABI")
    input_meta = workload.get("input", {})
    if input_meta.get("maximum_length") != 4096 or input_meta.get("codepoint_range") != [0, 127]:
        issues.append("bounded input profile mismatch")
    for case in workload.get("cases", []):
        values = case.get("input_values", [])
        length = case.get("input_length")
        result = expected_result(values, input_length=length)
        case_id = case.get("id")
        if result != case.get("expected_result"):
            issues.append(f"primary oracle mismatch in {case_id}")
        if not verify_result(values, result, input_length=length):
            issues.append(f"independent oracle rejected workload case {case_id}")
    for language, path in LANGUAGE_PATHS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif "minimum_string_representation" not in path.read_text():
            issues.append(f"missing exported symbol text in {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document {name}")
    for name in (
        "minimum_string_representation_oracle.py",
        "minimum_string_representation_verifier_oracle.py",
    ):
        if not (ROOT / "benchmarks" / name).is_file():
            issues.append(f"missing oracle {name}")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
