"""Static inventory and workload review for the Chinese-postman ports."""

from __future__ import annotations

import json
from pathlib import Path

from undirected_chinese_postman_oracle import expected_result as primary_result
from undirected_chinese_postman_verifier_oracle import expected_result as independent_result

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/u/undirected_chinese_postman"
PORTS = {
    "c": ROOT / "c/u/undirected_chinese_postman.c",
    "c3": ROOT / "c3/u/undirected_chinese_postman.c3",
    "cpp": ROOT / "cpp/u/undirected_chinese_postman.cpp",
    "elisa": ROOT / "elisa/u/undirected_chinese_postman.elisa",
    "mojo": ROOT / "mojo/u/undirected_chinese_postman.mojo",
    "nim": ROOT / "nim/u/undirected_chinese_postman.nim",
    "odin": ROOT / "odin/u/undirected_chinese_postman.odin",
    "rust": ROOT / "rust/u/undirected_chinese_postman.rs",
    "v": ROOT / "v/u/undirected_chinese_postman.v",
    "zig": ROOT / "zig/u/undirected_chinese_postman.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]

    if workload.get("algorithm") != "undirected_chinese_postman":
        issues.append("unexpected algorithm name")
    if workload.get("function_symbol") != "undirected_chinese_postman":
        issues.append("unexpected exported symbol")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("unexpected ABI")
    input_meta = workload.get("input", {})
    if input_meta.get("vertex_range") != [1, 8]:
        issues.append("vertex bounds mismatch")
    if input_meta.get("edge_count_range") != [0, 12]:
        issues.append("edge-count bounds mismatch")
    if input_meta.get("positive_edge_weight_range") != [1, 1000]:
        issues.append("edge-weight bounds mismatch")

    cases = workload.get("cases", [])
    if not isinstance(cases, list):
        return issues + ["workload cases must be a list"]
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload contains a non-object case")
            continue
        values = case.get("input_values")
        case_id = case.get("id", "<unnamed>")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"fixture input length mismatch: {case_id}")
        expected = case.get("expected_result")
        if primary_result(values) != expected:
            issues.append(f"primary oracle fixture mismatch: {case_id}")
        if independent_result(values) != expected:
            issues.append(f"independent oracle fixture mismatch: {case_id}")

    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif "undirected_chinese_postman" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")

    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    if "https://xlinux.nist.gov/dads/HTML/chinesePostman.html" not in readme:
        issues.append("README missing algorithm source")
    if "Language ports" not in readme:
        issues.append("README missing language port inventory")

    elisa = PORTS["elisa"]
    if elisa.is_file():
        source = elisa.read_text(encoding="utf-8")
        if "view[i64]" not in source or "input: i64&" not in source:
            issues.append("Elisa must use safe views internally and refs only at its exported ABI")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
