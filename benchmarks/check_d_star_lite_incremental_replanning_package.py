"""Static inventory for the D* Lite replanning package."""

from __future__ import annotations

import json
from pathlib import Path

from d_star_lite_incremental_replanning_oracle import expected_result as primary_result
from d_star_lite_incremental_replanning_verifier_oracle import expected_result as independent_result

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/d/d_star_lite_incremental_replanning"
SYMBOL = "d_star_lite_incremental_replanning"
PORTS = {
    "c": ROOT / "c/d/d_star_lite_incremental_replanning.c",
    "c3": ROOT / "c3/d/d_star_lite_incremental_replanning.c3",
    "cpp": ROOT / "cpp/d/d_star_lite_incremental_replanning.cpp",
    "elisa": ROOT / "elisa/d/d_star_lite_incremental_replanning.elisa",
    "mojo": ROOT / "mojo/d/d_star_lite_incremental_replanning.mojo",
    "nim": ROOT / "nim/d/d_star_lite_incremental_replanning.nim",
    "odin": ROOT / "odin/d/d_star_lite_incremental_replanning.odin",
    "rust": ROOT / "rust/d/d_star_lite_incremental_replanning.rs",
    "v": ROOT / "v/d/d_star_lite_incremental_replanning.v",
    "zig": ROOT / "zig/d/d_star_lite_incremental_replanning.zig",
}


def _maximum_input() -> tuple[int, ...]:
    edges = []
    for source in range(16):
        row, column = divmod(source, 4)
        for target in range(16):
            target_row, target_column = divmod(target, 4)
            if abs(row - target_row) + abs(column - target_column) == 1:
                edges.extend((source, target, 1 + (source * 3 + target) % 9))
    updates = tuple(component for index in range(16)
                    for component in ((index * 5) % 16, index % 48, 1 + (index * 7) % 9))
    return (4, 4, 48, 16, 0, 15, *edges, *updates)


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]
    if workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL:
        issues.append("unexpected algorithm name or exported symbol")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("unexpected ABI")
    if (workload.get("input", {}).get("maximum_valid_length") != 198
            or workload.get("input", {}).get("maximum_parseable_length") != 199):
        issues.append("maximum input length mismatch")
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
            issues.append(f"D* Lite repair oracle fixture mismatch: {case_id}")
        if independent_result(values, **arguments) != expected:
            issues.append(f"Floyd-Warshall fixture mismatch: {case_id}")

    maximum = _maximum_input()
    if len(maximum) != 198:
        issues.append("maximum input construction mismatch")
    else:
        primary = primary_result(maximum)
        independent = independent_result(maximum)
        if primary != independent or not 0 <= independent <= 316_744:
            issues.append("maximum frame differs between oracles or exceeds its checksum bound")
    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json", "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    if "AAAI02-072.pdf" not in readme or "g/rhs" not in readme:
        issues.append("README missing paper attribution or algorithm signature")
    elisa = PORTS["elisa"]
    if elisa.is_file():
        source = elisa.read_text(encoding="utf-8")
        if "view[i64]" not in source or "i64&" not in source:
            issues.append("Elisa should use a safe internal view and reference ABI wrapper")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
