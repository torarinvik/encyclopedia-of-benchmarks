"""Static inventory and fixture review for the y-fast trie package."""

from __future__ import annotations

import json
from pathlib import Path

from y_fast_trie_static_predecessor_oracle import expected_result as primary_result
from y_fast_trie_static_predecessor_verifier_oracle import expected_result as independent_result

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/y/y_fast_trie_static_predecessor"
PORTS = {
    "c": ROOT / "c/y/y_fast_trie_static_predecessor.c",
    "c3": ROOT / "c3/y/y_fast_trie_static_predecessor.c3",
    "cpp": ROOT / "cpp/y/y_fast_trie_static_predecessor.cpp",
    "elisa": ROOT / "elisa/y/y_fast_trie_static_predecessor.elisa",
    "mojo": ROOT / "mojo/y/y_fast_trie_static_predecessor.mojo",
    "nim": ROOT / "nim/y/y_fast_trie_static_predecessor.nim",
    "odin": ROOT / "odin/y/y_fast_trie_static_predecessor.odin",
    "rust": ROOT / "rust/y/y_fast_trie_static_predecessor.rs",
    "v": ROOT / "v/y/y_fast_trie_static_predecessor.v",
    "zig": ROOT / "zig/y/y_fast_trie_static_predecessor.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]
    if workload.get("algorithm") != "y_fast_trie_static_predecessor":
        issues.append("unexpected algorithm name")
    if workload.get("function_symbol") != "y_fast_trie_static_predecessor":
        issues.append("unexpected exported symbol")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("unexpected ABI")
    input_contract = workload.get("input", {})
    if (input_contract.get("maximum_valid_length") != 514
            or input_contract.get("maximum_parseable_length") != 515):
        issues.append("maximum input length mismatch")
    if (input_contract.get("keys_must_be_unique") is not True
            or input_contract.get("queries_may_repeat") is not True):
        issues.append("key or repeated-query policy mismatch")
    if workload.get("algorithm_details", {}).get("cluster_size") != 16:
        issues.append("cluster size mismatch")

    for case in workload.get("cases", []):
        if not isinstance(case, dict):
            issues.append("workload contains a non-object case")
            continue
        values = case.get("input_values")
        case_id = case.get("id", "<unnamed>")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"fixture input length mismatch: {case_id}")
            continue
        arguments = {
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        expected = case.get("expected_result")
        if primary_result(values, **arguments) != expected:
            issues.append(f"primary oracle fixture mismatch: {case_id}")
        if independent_result(values, **arguments) != expected:
            issues.append(f"independent oracle fixture mismatch: {case_id}")

    maximum_values = (256, 256, *range(256), *((65535,) * 256))
    if len(maximum_values) != 514:
        issues.append("maximum frame construction mismatch")
    elif (primary_result(maximum_values) != 8421376
          or independent_result(maximum_values) != 8421376):
        issues.append("maximum frame checksum mismatch")
    maximum_parseable_invalid = (*maximum_values, 0)
    if (primary_result(maximum_parseable_invalid) != -1
            or independent_result(maximum_parseable_invalid) != -1):
        issues.append("maximum parseable trailing frame was accepted")

    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif "y_fast_trie_static_predecessor" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    if "10.1016/0020-0190(83)90075-3" not in readme:
        issues.append("README missing source attribution")
    if "does not claim" not in readme:
        issues.append("README must qualify the local complexity profile")
    elisa = PORTS["elisa"]
    if elisa.is_file():
        source = elisa.read_text(encoding="utf-8")
        if "view[i64]" not in source or "i64&" not in source:
            issues.append("Elisa must use an internal safe view and an ABI reference wrapper")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
