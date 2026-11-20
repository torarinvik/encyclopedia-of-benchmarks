"""Static fixture framing, reference agreement, provenance, and port checks."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as independent
from .primary_oracle import MAX_PARSEABLE_INPUT_LENGTH, MAX_VALID_INPUT_LENGTH, expected_result as primary

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/r/redundant_directed_connection_repair"
SYMBOL = "redundant_directed_connection_repair"
EXTENSIONS = {"c":"c","c3":"c3","cpp":"cpp","elisa":"elisa","mojo":"mojo",
              "nim":"nim","odin":"odin","rust":"rs","v":"v","zig":"zig"}
REQUIRED_CASES = {"cycle-no-parent-conflict-last-valid","two-parents-no-cycle-last-valid",
                  "two-parents-and-cycle","directed-cycle-last-edge-tie","arbitrary-root-with-conflict",
                  "too-few-vertices","duplicate-directed-edge","self-loop","endpoint-out-of-range",
                  "trailing-value","null-input","null-at-parser-limit"}


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    for name in ("README.md","RIGHTS.md","INVENTORY.md","workload.json","primary_oracle.py",
                 "independent_oracle.py","verify_workload.py"):
        if not (PACKAGE / name).is_file(): issues.append(f"missing package file: {name}")
    inventory = (PACKAGE / "INVENTORY.md").read_text(encoding="utf-8") if (PACKAGE / "INVENTORY.md").is_file() else ""
    for language, extension in EXTENSIONS.items():
        source = ROOT / language / "r" / f"{SYMBOL}.{extension}"
        if not source.is_file(): issues.append(f"missing language source: {language}")
        elif SYMBOL not in source.read_text(encoding="utf-8"): issues.append(f"missing symbol in {language}")
        if f"{language}/r/{SYMBOL}.{extension}" not in inventory:
            issues.append(f"missing inventory source link: {language}")
    if workload is None:
        try: workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error: return issues + [f"cannot read workload: {error}"]
    if not isinstance(workload, dict): return issues + ["workload must be an object"]
    spec = workload.get("input", {})
    if (workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"
            or spec.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or spec.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH):
        issues.append("workload identity or frame bounds differ")
    cases = workload.get("cases")
    if not isinstance(cases, list): return issues + ["workload cases must be a list"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid workload case record"); continue
        case_id = case["id"]
        if case_id in seen: issues.append(f"duplicate fixture id: {case_id}")
        seen.add(case_id)
        values, is_null = case.get("input_values"), case.get("input_is_null", False)
        length = case.get("input_length", len(values) if isinstance(values, list) else None)
        if (not isinstance(values, list) or type(is_null) is not bool or type(length) is not int
                or type(case.get("expected_result")) is not int or (is_null and values)
                or (not is_null and length != len(values))):
            issues.append(f"invalid fixture framing: {case_id}"); continue
        if case_id == "null-input" and (not is_null or length != 0): issues.append("null-input framing differs")
        if case_id == "null-at-parser-limit" and (not is_null or length != MAX_PARSEABLE_INPUT_LENGTH):
            issues.append("null-at-parser-limit framing differs")
        a, b = primary(values, is_null, length), independent(values, is_null, length)
        if a != b or a != case["expected_result"]: issues.append(f"fixture/reference mismatch: {case_id}")
    if seen != REQUIRED_CASES: issues.append("required fixture set differs")
    source = workload.get("source", {})
    if "leetcode.com/problems/redundant-connection-ii" not in source.get("url", ""):
        issues.append("missing title provenance")
    if "geeksforgeeks.org/dsa/extra-edge-in-a-directed-rooted-tree" not in source.get("method_reference", ""):
        issues.append("missing method reference")
    return issues
