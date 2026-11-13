"""Static metadata, fixture, provenance, and port inventory review for ISAP."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .isap_maxflow_oracle import (
        MAX_EDGES,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        MAX_VERTICES,
        expected_result as primary_result,
    )
    from .isap_maxflow_verifier_oracle import expected_result as independent_result
except ImportError:  # Direct invocation with benchmarks/ on sys.path.
    from isap_maxflow_oracle import (
        MAX_EDGES,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        MAX_VERTICES,
        expected_result as primary_result,
    )
    from isap_maxflow_verifier_oracle import expected_result as independent_result

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/i/isap_maxflow"
SOURCE_URL = "https://oi-wiki.org/graph/flow/max-flow/#isap"
PORTS = {
    "c": ROOT / "c/i/isap_maxflow.c",
    "c3": ROOT / "c3/i/isap_maxflow.c3",
    "cpp": ROOT / "cpp/i/isap_maxflow.cpp",
    "elisa": ROOT / "elisa/i/isap_maxflow.elisa",
    "mojo": ROOT / "mojo/i/isap_maxflow.mojo",
    "nim": ROOT / "nim/i/isap_maxflow.nim",
    "odin": ROOT / "odin/i/isap_maxflow.odin",
    "rust": ROOT / "rust/i/isap_maxflow.rs",
    "v": ROOT / "v/i/isap_maxflow.v",
    "zig": ROOT / "zig/i/isap_maxflow.zig",
}
NULL_GUARDS = {
    "c": "input == NULL",
    "c3": "input==null",
    "cpp": "input == nullptr",
    "elisa": "input.is_null()",
    "mojo": "input == UnsafePointer[Int64, ImmutAnyOrigin]()",
    "nim": "input.isNil",
    "odin": "input == nil",
    "rust": "input.is_null()",
    "v": "input == nil",
    "zig": "input_opt == null",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]

    if workload.get("algorithm") != "isap_maxflow":
        issues.append("unexpected algorithm identifier")
    if workload.get("function_symbol") != "isap_maxflow":
        issues.append("unexpected exported symbol")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("unexpected ABI")
    source = workload.get("pinned_source", {})
    if source.get("url") != SOURCE_URL:
        issues.append("pinned source URL mismatch")
    contract = workload.get("input", {})
    if contract.get("vertex_count_range") != [2, MAX_VERTICES]:
        issues.append("vertex bound mismatch")
    if contract.get("edge_count_range") != [0, MAX_EDGES]:
        issues.append("edge bound mismatch")
    if contract.get("maximum_valid_input_length") != MAX_VALID_INPUT_LENGTH:
        issues.append("maximum valid frame bound mismatch")
    if contract.get("maximum_parseable_input_length") != MAX_PARSEABLE_INPUT_LENGTH:
        issues.append("maximum parseable frame bound mismatch")
    if contract.get("maximum_flow") != MAX_EDGES * 100:
        issues.append("maximum flow bound mismatch")
    if workload.get("workspace", {}).get("bytes") != 4096:
        issues.append("workspace bound mismatch")
    if primary_result(None) != -1 or independent_result(None) != -1:
        issues.append("an oracle does not reject a null input")

    cases = workload.get("cases", [])
    if not isinstance(cases, list):
        return issues + ["workload cases must be a list"]
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload contains a non-object case")
            continue
        values = case.get("input_values")
        case_id = case.get("id", "<unnamed>")
        if not isinstance(values, list):
            issues.append(f"fixture values are not an array: {case_id}")
            continue
        if len(values) > MAX_PARSEABLE_INPUT_LENGTH:
            issues.append(f"fixture exceeds parseable frame bound: {case_id}")
        expected = case.get("expected_result")
        if primary_result(values) != expected:
            issues.append(f"primary oracle fixture mismatch: {case_id}")
        if independent_result(values) != expected:
            issues.append(f"independent oracle fixture mismatch: {case_id}")

    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        else:
            source_text = path.read_text(encoding="utf-8")
            if "isap_maxflow" not in source_text:
                issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
            if NULL_GUARDS[language] not in source_text:
                issues.append(f"missing null input guard: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")
    for name in ("isap_maxflow_oracle.py", "isap_maxflow_verifier_oracle.py"):
        if not (ROOT / "benchmarks" / name).is_file():
            issues.append(f"missing oracle module: {name}")
    readme_path = PACKAGE / "README.md"
    if readme_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        if SOURCE_URL not in readme or "minimum directed cut" not in readme:
            issues.append("README is missing provenance or independent-method notes")
        if "benchmarks/check_isap_maxflow_package.py" not in readme:
            issues.append("README is missing the package checker link")
    rights_path = PACKAGE / "RIGHTS.md"
    if rights_path.is_file():
        rights = rights_path.read_text(encoding="utf-8")
        if SOURCE_URL not in rights or "CC BY-SA 4.0" not in rights:
            issues.append("rights note is missing source/license attribution")
    elisa_path = PORTS["elisa"]
    if elisa_path.is_file():
        elisa = elisa_path.read_text(encoding="utf-8")
        if "view[i64]" not in elisa or "input: i64&" not in elisa:
            issues.append("Elisa must use safe views internally and refs only at the ABI")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
