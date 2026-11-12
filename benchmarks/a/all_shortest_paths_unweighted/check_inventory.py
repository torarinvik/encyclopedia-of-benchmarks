"""Static inventory and workload metadata review for the shortest-path enumerator."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "all_shortest_paths_unweighted"
PORTS = {
    "C": ROOT / "c/a/all_shortest_paths_unweighted.c",
    "C3": ROOT / "c3/a/all_shortest_paths_unweighted.c3",
    "C++": ROOT / "cpp/a/all_shortest_paths_unweighted.cpp",
    "Elisa": ROOT / "elisa/a/all_shortest_paths_unweighted.elisa",
    "Mojo": ROOT / "mojo/a/all_shortest_paths_unweighted.mojo",
    "Nim": ROOT / "nim/a/all_shortest_paths_unweighted.nim",
    "Odin": ROOT / "odin/a/all_shortest_paths_unweighted.odin",
    "Rust": ROOT / "rust/a/all_shortest_paths_unweighted.rs",
    "V": ROOT / "v/a/all_shortest_paths_unweighted.v",
    "Zig": ROOT / "zig/a/all_shortest_paths_unweighted.zig",
}


def check_inventory() -> list[str]:
    errors: list[str] = []
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            errors.append(f"missing package artifact: {name}")
    for language, path in PORTS.items():
        if not path.is_file():
            errors.append(f"missing {language} source: {path.relative_to(ROOT)}")
            continue
        if SYMBOL not in path.read_text(encoding="utf-8"):
            errors.append(f"{language} source does not define {SYMBOL}")
    elisa = PORTS["Elisa"]
    if elisa.is_file():
        text = elisa.read_text(encoding="utf-8")
        if "view[i64]" not in text or "mutable view[u8]" not in text:
            errors.append("Elisa implementation should use safe views internally")
        if "UnsafePointer" in text or "ptr " in text:
            errors.append("Elisa implementation must not introduce raw pointer helpers")

    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return errors + [f"invalid workload JSON: {error}"]
    if workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL:
        errors.append("workload symbol and algorithm metadata must agree")
    if workload.get("abi") != "i64_array_bytes_output":
        errors.append("workload uses the wrong ABI")
    if workload.get("input", {}).get("maximum_valid_length") != 132:
        errors.append("maximum valid frame must contain 132 i64 values")
    if workload.get("input", {}).get("maximum_parseable_length") != 133:
        errors.append("maximum parseable frame must contain 133 i64 values")
    if workload.get("output", {}).get("maximum_path_count") != 162:
        errors.append("shortest-path count cap must be 162")
    if workload.get("output", {}).get("maximum_output_bytes") != 1296:
        errors.append("maximum encoded output must be 1296 bytes")
    if workload.get("workspace", {}).get("bytes") != 4096:
        errors.append("workspace metadata must be 4096 bytes")

    case_ids: set[str] = set()
    saw_tie = saw_many = saw_unreachable = saw_equal = saw_pruned_longer = False
    for case in workload.get("cases", []):
        case_id = case.get("id", "<unnamed>")
        if case_id in case_ids:
            errors.append(f"duplicate workload case id: {case_id}")
        case_ids.add(case_id)
        values = case.get("input_values", [])
        if not case.get("input_is_null", False) and case.get("input_length") != len(values):
            errors.append(f"{case_id}: input_length differs from input_values")
        try:
            payload = bytes.fromhex(case.get("expected_output_hex", ""))
        except ValueError:
            errors.append(f"{case_id}: expected output is not hexadecimal")
            continue
        result = case.get("expected_result")
        if isinstance(result, int) and result >= 0:
            if payload.count(0xFF) != result:
                errors.append(f"{case_id}: path count differs from terminator count")
        if case_id == "two_lexicographic_shortest_paths":
            saw_tie = result == 2 and len(payload) == 10
        elif case_id == "eight_shortest_paths":
            saw_many = result == 8 and len(payload) == 48
        elif case_id == "unreachable_target":
            saw_unreachable = result == 0 and not payload
        elif case_id == "source_equals_target":
            saw_equal = result == 1 and payload == bytes((0, 0xFF))
        elif case_id == "shortest_only_among_simple_paths":
            saw_pruned_longer = result == 1 and payload == bytes((0, 3, 0xFF))
    if not saw_tie:
        errors.append("missing two-path lexicographic tie case")
    if not saw_many:
        errors.append("missing many-shortest-path case")
    if not saw_unreachable:
        errors.append("missing no-path case")
    if not saw_equal:
        errors.append("missing source-equals-target case")
    if not saw_pruned_longer:
        errors.append("missing fixture that excludes a longer simple path")
    return errors


if __name__ == "__main__":
    failures = check_inventory()
    if failures:
        raise SystemExit("\n".join(failures))
