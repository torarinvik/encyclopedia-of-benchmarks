"""Static inventory and dual-oracle checker; language ports are not launched."""
from __future__ import annotations

import json
from pathlib import Path

try:
    from .primary_oracle import expected_output
    from .independent_oracle import verify_result
except ImportError:  # Direct invocation from this package directory.
    from primary_oracle import expected_output
    from independent_oracle import verify_result

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "knuth_power_tree"
LANGUAGE_PATHS = {
    "c": ROOT / "c/k/knuth_power_tree.c",
    "c3": ROOT / "c3/k/knuth_power_tree.c3",
    "cpp": ROOT / "cpp/k/knuth_power_tree.cpp",
    "elisa": ROOT / "elisa/k/knuth_power_tree.elisa",
    "mojo": ROOT / "mojo/k/knuth_power_tree.mojo",
    "nim": ROOT / "nim/k/knuth_power_tree.nim",
    "odin": ROOT / "odin/k/knuth_power_tree.odin",
    "rust": ROOT / "rust/k/knuth_power_tree.rs",
    "v": ROOT / "v/k/knuth_power_tree.v",
    "zig": ROOT / "zig/k/knuth_power_tree.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text())
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]
    if workload.get("function_symbol") != SYMBOL or workload.get("abi") != "i64_array_bytes_output":
        issues.append("unexpected symbol or ABI")
    if workload.get("input", {}).get("target_range") != [1, 127]:
        issues.append("target bound mismatch")
    if workload.get("output", {}).get("maximum_bytes") != 1024:
        issues.append("maximum output size mismatch")
    for case in workload.get("cases", []):
        values = case.get("input_values", [])
        result, payload = expected_output(
            values, capacity=case.get("output_capacity"),
            output_is_null=case.get("output_is_null", False),
            input_length=case.get("input_length"),
        )
        case_id = case.get("id")
        if result != case.get("expected_result") or payload.hex() != case.get("expected_output_hex"):
            issues.append(f"primary oracle fixture mismatch: {case_id}")
        if not verify_result(
            values, result, payload,
            output_capacity=case.get("output_capacity"),
            output_is_null=case.get("output_is_null", False),
            input_length=case.get("input_length"),
        ):
            issues.append(f"independent oracle rejected fixture: {case_id}")
    for language, path in LANGUAGE_PATHS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text():
            issues.append(f"missing exported symbol in {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file {name}")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
