"""Static fixture and inventory review; does not launch language ports."""
from __future__ import annotations

import json
from pathlib import Path

try:
    from .primary_oracle import expected_output
    from .independent_oracle import verify_result
except ImportError:
    from primary_oracle import expected_output
    from independent_oracle import verify_result

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "inverted_list_bitvector_intersection"
LANGUAGE_PATHS = {
    "c": ROOT / "c/i/inverted_list_bitvector_intersection.c",
    "c3": ROOT / "c3/i/inverted_list_bitvector_intersection.c3",
    "cpp": ROOT / "cpp/i/inverted_list_bitvector_intersection.cpp",
    "elisa": ROOT / "elisa/i/inverted_list_bitvector_intersection.elisa",
    "mojo": ROOT / "mojo/i/inverted_list_bitvector_intersection.mojo",
    "nim": ROOT / "nim/i/inverted_list_bitvector_intersection.nim",
    "odin": ROOT / "odin/i/inverted_list_bitvector_intersection.odin",
    "rust": ROOT / "rust/i/inverted_list_bitvector_intersection.rs",
    "v": ROOT / "v/i/inverted_list_bitvector_intersection.v",
    "zig": ROOT / "zig/i/inverted_list_bitvector_intersection.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]
    if workload.get("function_symbol") != SYMBOL or workload.get("abi") != "i64_array_bytes_output":
        issues.append("unexpected symbol or ABI")
    input_meta = workload.get("input", {})
    if (input_meta.get("maximum_valid_length") != 258
            or input_meta.get("domain_size_range") != [1, 1024]
            or input_meta.get("list_count_range") != [1, 16]):
        issues.append("input bounds mismatch")
    if (workload.get("output", {}).get("maximum_bytes") != 8200
            or workload.get("workspace", {}).get("bytes") != 8320):
        issues.append("output or workspace bound mismatch")
    for case in workload.get("cases", []):
        values = case.get("input_values", [])
        kwargs = {
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        result, payload = expected_output(values, **kwargs)
        case_id = case.get("id")
        if result != case.get("expected_result") or payload.hex() != case.get("expected_output_hex"):
            issues.append(f"primary oracle fixture mismatch: {case_id}")
        if not verify_result(values, result, payload, **{
            "output_capacity": kwargs["capacity"],
            "output_is_null": kwargs["output_is_null"],
            "input_is_null": kwargs["input_is_null"],
            "input_length": kwargs["input_length"],
        }):
            issues.append(f"independent verifier rejected fixture: {case_id}")
    for language, path in LANGUAGE_PATHS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol in {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
                 "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file {name}")
    if not (ROOT / "benchmarks/verify_inverted_list_bitvector_intersection.py").is_file():
        issues.append("missing dedicated suite verifier")
    return issues
