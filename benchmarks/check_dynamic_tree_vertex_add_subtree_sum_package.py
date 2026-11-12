"""Static package inventory review; this checker never launches language ports."""

from __future__ import annotations

import json
from pathlib import Path

from dynamic_tree_vertex_add_subtree_sum_oracle import expected_output
from dynamic_tree_vertex_add_subtree_sum_verifier_oracle import verify_result

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/d/dynamic_tree_vertex_add_subtree_sum"
LANGUAGE_PATHS = {
    "c": ROOT / "c/d/dynamic_tree_vertex_add_subtree_sum.c",
    "c3": ROOT / "c3/d/dynamic_tree_vertex_add_subtree_sum.c3",
    "cpp": ROOT / "cpp/d/dynamic_tree_vertex_add_subtree_sum.cpp",
    "elisa": ROOT / "elisa/d/dynamic_tree_vertex_add_subtree_sum.elisa",
    "mojo": ROOT / "mojo/d/dynamic_tree_vertex_add_subtree_sum.mojo",
    "nim": ROOT / "nim/d/dynamic_tree_vertex_add_subtree_sum.nim",
    "odin": ROOT / "odin/d/dynamic_tree_vertex_add_subtree_sum.odin",
    "rust": ROOT / "rust/d/dynamic_tree_vertex_add_subtree_sum.rs",
    "v": ROOT / "v/d/dynamic_tree_vertex_add_subtree_sum.v",
    "zig": ROOT / "zig/d/dynamic_tree_vertex_add_subtree_sum.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text())
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]
    if workload.get("function_symbol") != "dynamic_tree_vertex_add_subtree_sum":
        issues.append("unexpected exported function symbol")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("unexpected ABI")
    input_meta = workload.get("input", {})
    if input_meta.get("n_range") != [1, 32] or input_meta.get("q_range") != [0, 64]:
        issues.append("bounded input shape mismatch")
    if input_meta.get("maximum_valid_length") != 416:
        issues.append("maximum input length mismatch")
    if workload.get("output", {}).get("maximum_bytes") != 512:
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
        if result != case.get("expected_result"):
            issues.append(f"primary oracle result mismatch in {case.get('id')}")
        if payload.hex() != case.get("expected_output_hex"):
            issues.append(f"primary oracle bytes mismatch in {case.get('id')}")
        if not verify_result(
            values,
            result,
            payload,
            output_capacity=case.get("output_capacity"),
            output_is_null=case.get("output_is_null", False),
            input_is_null=case.get("input_is_null", False),
            input_length=case.get("input_length"),
        ):
            issues.append(f"independent oracle rejected workload case {case.get('id')}")
    for language, path in LANGUAGE_PATHS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif "dynamic_tree_vertex_add_subtree_sum" not in path.read_text():
            issues.append(f"missing exported symbol text in {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document {name}")
    for name in (
        "dynamic_tree_vertex_add_subtree_sum_oracle.py",
        "dynamic_tree_vertex_add_subtree_sum_verifier_oracle.py",
    ):
        if not (ROOT / "benchmarks" / name).is_file():
            issues.append(f"missing oracle {name}")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
