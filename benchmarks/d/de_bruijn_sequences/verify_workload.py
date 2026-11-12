"""Static inventory and oracle review for the de Bruijn package; ports are not run."""
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
SYMBOL = "de_bruijn_sequences"
LANGUAGE_PATHS = {
    "c": ROOT / "c/d/de_bruijn_sequences.c",
    "c3": ROOT / "c3/d/de_bruijn_sequences.c3",
    "cpp": ROOT / "cpp/d/de_bruijn_sequences.cpp",
    "elisa": ROOT / "elisa/d/de_bruijn_sequences.elisa",
    "mojo": ROOT / "mojo/d/de_bruijn_sequences.mojo",
    "nim": ROOT / "nim/d/de_bruijn_sequences.nim",
    "odin": ROOT / "odin/d/de_bruijn_sequences.odin",
    "rust": ROOT / "rust/d/de_bruijn_sequences.rs",
    "v": ROOT / "v/d/de_bruijn_sequences.v",
    "zig": ROOT / "zig/d/de_bruijn_sequences.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text())
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]
    if workload.get("function_symbol") != SYMBOL or workload.get("abi") != "i64_array_bytes_output":
        issues.append("unexpected symbol or ABI")
    input_meta = workload.get("input", {})
    if (input_meta.get("alphabet_size_range") != [2, 10]
            or input_meta.get("order_range") != [1, 16]
            or input_meta.get("cycle_length_limit") != 10000):
        issues.append("bounded input profile mismatch")
    if workload.get("output", {}).get("maximum_bytes") != 10003:
        issues.append("maximum output size mismatch")
    for case in workload.get("cases", []):
        values = case.get("input_values", [])
        result, payload = expected_output(
            values,
            capacity=case.get("output_capacity"),
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
            issues.append(f"independent verifier rejected fixture: {case_id}")
    for language, path in LANGUAGE_PATHS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text():
            issues.append(f"missing exported symbol in {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document {name}")
    for name in ("primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing oracle {name}")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
