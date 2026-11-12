"""Static package inventory review; does not launch language ports."""

from __future__ import annotations

import json
from pathlib import Path

from segment_history_extreme_oracle import expected_output
from segment_history_extreme_verifier_oracle import verify_output

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/s/segment_history_extreme"
LANGUAGE_PATHS = {
    "c": ROOT / "c/s/segment_history_extreme.c",
    "c3": ROOT / "c3/s/segment_history_extreme.c3",
    "cpp": ROOT / "cpp/s/segment_history_extreme.cpp",
    "elisa": ROOT / "elisa/s/segment_history_extreme.elisa",
    "mojo": ROOT / "mojo/s/segment_history_extreme.mojo",
    "nim": ROOT / "nim/s/segment_history_extreme.nim",
    "odin": ROOT / "odin/s/segment_history_extreme.odin",
    "rust": ROOT / "rust/s/segment_history_extreme.rs",
    "v": ROOT / "v/s/segment_history_extreme.v",
    "zig": ROOT / "zig/s/segment_history_extreme.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text())
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]
    if workload.get("function_symbol") != "segment_history_extreme":
        issues.append("unexpected exported function symbol")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("unexpected ABI")
    input_meta = workload.get("input", {})
    if input_meta.get("n_range") != [1, 32] or input_meta.get("q_range") != [0, 32]:
        issues.append("bounded input profile mismatch")
    if workload.get("output", {}).get("maximum_bytes") != 256:
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
        if not verify_output(
            values,
            result,
            payload,
            capacity=case.get("output_capacity"),
            output_is_null=case.get("output_is_null", False),
            input_is_null=case.get("input_is_null", False),
            input_length=case.get("input_length"),
        ):
            issues.append(f"independent oracle rejected workload case {case_id}")
    for language, path in LANGUAGE_PATHS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif "segment_history_extreme" not in path.read_text():
            issues.append(f"missing exported symbol text in {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document {name}")
    for name in (
        "segment_history_extreme_oracle.py",
        "segment_history_extreme_verifier_oracle.py",
    ):
        if not (ROOT / "benchmarks" / name).is_file():
            issues.append(f"missing oracle {name}")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
