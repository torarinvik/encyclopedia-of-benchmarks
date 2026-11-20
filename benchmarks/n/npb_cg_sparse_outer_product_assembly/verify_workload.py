"""Static inventory checks for the bounded NPB CG matrix assembler."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": ROOT / "c/n/npb_cg_sparse_outer_product_assembly.c",
    "c3": ROOT / "c3/n/npb_cg_sparse_outer_product_assembly.c3",
    "cpp": ROOT / "cpp/n/npb_cg_sparse_outer_product_assembly.cpp",
    "elisa": ROOT / "elisa/n/npb_cg_sparse_outer_product_assembly.elisa",
    "mojo": ROOT / "mojo/n/npb_cg_sparse_outer_product_assembly.mojo",
    "nim": ROOT / "nim/n/npb_cg_sparse_outer_product_assembly.nim",
    "odin": ROOT / "odin/n/npb_cg_sparse_outer_product_assembly.odin",
    "rust": ROOT / "rust/n/npb_cg_sparse_outer_product_assembly.rs",
    "v": ROOT / "v/n/npb_cg_sparse_outer_product_assembly.v",
    "zig": ROOT / "zig/n/npb_cg_sparse_outer_product_assembly.zig",
}


def verify() -> list[str]:
    issues: list[str] = []
    workload = json.loads((PACKAGE / "workload.json").read_text())
    inventory = json.loads((PACKAGE / "INVENTORY.json").read_text())
    if workload.get("algorithm") != "npb_cg_sparse_outer_product_assembly":
        issues.append("workload algorithm mismatch")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("workload ABI mismatch")
    if workload.get("output", {}).get("kind") != "float64_vector":
        issues.append("workload output encoding mismatch")
    if (workload.get("output", {}).get("absolute_tolerance") != 1e-12
            or workload.get("output", {}).get("relative_tolerance") != 1e-12):
        issues.append("workload floating tolerance mismatch")
    if workload.get("workspace", {}).get("bytes") != 8192:
        issues.append("workspace cap mismatch")
    if (inventory.get("algorithm") != workload.get("algorithm")
            or inventory.get("abi") != workload.get("abi")
            or inventory.get("output_kind") != workload.get("output", {}).get("kind")):
        issues.append("inventory identity or ABI mismatch")
    if inventory.get("maximum_valid_input_words") != workload.get("input", {}).get("maximum_valid_length"):
        issues.append("inventory valid input bound mismatch")
    if inventory.get("maximum_parseable_input_words") != workload.get("input", {}).get("maximum_parseable_length"):
        issues.append("inventory parseable input bound mismatch")
    if inventory.get("maximum_output_bytes") != workload.get("output", {}).get("maximum_output_bytes"):
        issues.append("inventory output bound mismatch")
    if inventory.get("workspace_bytes") != workload.get("workspace", {}).get("bytes"):
        issues.append("inventory workspace bound mismatch")
    expected_sources = {path.relative_to(ROOT).as_posix() for path in PORTS.values()}
    if set(inventory.get("sources", [])) != expected_sources:
        issues.append("inventory source list mismatch")
    if workload.get("oracle") != "benchmarks/n/npb_cg_sparse_outer_product_assembly/primary_oracle.py":
        issues.append("primary oracle path mismatch")
    if workload.get("independent_oracle") != "benchmarks/n/npb_cg_sparse_outer_product_assembly/independent_oracle.py":
        issues.append("independent oracle path mismatch")
    cases = workload.get("cases", [])
    case_by_id = {case.get("id"): case for case in cases}
    if case_by_id.get("anchor-replacement-and-endpoint-weights", {}).get("expected_result") != 72:
        issues.append("anchor replacement golden fixture missing")
    if case_by_id.get("cross-vector-duplicate-coalescing", {}).get("expected_result") != 104:
        issues.append("duplicate coalescing golden fixture missing")
    if case_by_id.get("one-byte-short-full-result-capacity", {}).get("expected_result") != -2:
        issues.append("capacity-minus-one fixture missing")
    for case in cases:
        words = case.get("input_values", [])
        if case.get("input_length") != len(words):
            issues.append(f"fixture input length mismatch: {case.get('id')}")
        expected = case.get("expected_output", [])
        if case.get("expected_result", -1) >= 0 and len(expected) * 8 != case["expected_result"]:
            issues.append(f"fixture output length mismatch: {case.get('id')}")
        if case.get("expected_result", -1) >= 0 and len(expected) >= 2:
            n, nnz = int(expected[0]), int(expected[1])
            structural_count = 2 + (n + 1) + nnz
            if len(expected) != structural_count + nnz:
                issues.append(f"fixture CSC field count mismatch: {case.get('id')}")
            if any(not float(value).is_integer() for value in expected[:structural_count]):
                issues.append(f"fixture structural field is not integral: {case.get('id')}")
        if case.get("expected_result", 0) < 0 and expected:
            issues.append(f"error fixture has output bytes: {case.get('id')}")
    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
    for relative in inventory.get("references", []) + inventory.get("artifacts", []):
        if not (PACKAGE / relative).is_file():
            issues.append(f"missing inventory artifact: {relative}")
    for required in ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
                     "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / required).is_file():
            issues.append(f"missing package file: {required}")
    return issues


static_issues = verify


if __name__ == "__main__":
    errors = verify()
    for error in errors:
        print(error)
    if errors:
        raise SystemExit(1)

