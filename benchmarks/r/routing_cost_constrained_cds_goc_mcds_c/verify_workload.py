"""Static package checks for the bounded DOI 621 GOC-MCDS-C profile."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": ROOT / "c/r/routing_cost_constrained_cds_goc_mcds_c.c",
    "c3": ROOT / "c3/r/routing_cost_constrained_cds_goc_mcds_c.c3",
    "cpp": ROOT / "cpp/r/routing_cost_constrained_cds_goc_mcds_c.cpp",
    "elisa": ROOT / "elisa/r/routing_cost_constrained_cds_goc_mcds_c.elisa",
    "mojo": ROOT / "mojo/r/routing_cost_constrained_cds_goc_mcds_c.mojo",
    "nim": ROOT / "nim/r/routing_cost_constrained_cds_goc_mcds_c.nim",
    "odin": ROOT / "odin/r/routing_cost_constrained_cds_goc_mcds_c.odin",
    "rust": ROOT / "rust/r/routing_cost_constrained_cds_goc_mcds_c.rs",
    "v": ROOT / "v/r/routing_cost_constrained_cds_goc_mcds_c.v",
    "zig": ROOT / "zig/r/routing_cost_constrained_cds_goc_mcds_c.zig",
}
ORACLES = (
    ROOT / "benchmarks/routing_cost_constrained_cds_goc_mcds_c_oracle.py",
    ROOT / "benchmarks/routing_cost_constrained_cds_goc_mcds_c_verifier_oracle.py",
)
STALE_DISTANCE_CUTOFFS = (
    "path_length <= 4",
    "pathLength <= 4",
    "len(path) <= 4",
    "length <= 3",
)


def verify() -> list[str]:
    errors: list[str] = []
    workload = json.loads((PACKAGE / "workload.json").read_text())
    if workload.get("algorithm") != "routing_cost_constrained_cds_goc_mcds_c":
        errors.append("workload algorithm mismatch")
    if workload.get("abi") != "i64_array_bytes_output":
        errors.append("workload ABI mismatch")
    source = workload.get("source", {})
    primary = workload.get("cited_primary_work", {})
    if source.get("reference") != "Encyclopedia of Algorithms, DOI 10.1007/978-1-4939-2864-4_621":
        errors.append("chapter source reference mismatch")
    if primary.get("doi") != "10.1109/TPDS.2012.177":
        errors.append("cited primary paper mismatch")
    if "four" not in workload.get("contract", {}).get("stage_two", "").lower():
        errors.append("stage-two distance-four connector rule missing")

    cases = workload.get("cases", [])
    path_case = next((case for case in cases
                      if case.get("id") == "path-six-with-distance-four-mis-pair"), None)
    if path_case is None:
        errors.append("distance-four MIS-pair fixture missing")
    elif (path_case.get("input_length") != 13
          or len(path_case.get("input_values", [])) != 13
          or path_case.get("expected_output_hex") != "15000000000000001f00000000000000"):
        errors.append("distance-four fixture framing or expected output mismatch")
    for case in cases:
        if case.get("input_length") != len(case.get("input_values", [])):
            errors.append(f"fixture length mismatch: {case.get('id')}")

    for language, path in PORTS.items():
        if not path.is_file():
            errors.append(f"missing {language} port: {path.relative_to(ROOT)}")
            continue
        text = path.read_text()
        if any(cutoff in text for cutoff in STALE_DISTANCE_CUTOFFS):
            errors.append(f"stale distance cutoff in {path.relative_to(ROOT)}")
    for path in ORACLES:
        if not path.is_file():
            errors.append(f"missing oracle: {path.relative_to(ROOT)}")
        elif any(cutoff in path.read_text() for cutoff in STALE_DISTANCE_CUTOFFS):
            errors.append(f"stale distance cutoff in {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json", "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            errors.append(f"missing package file: {name}")
    return errors


if __name__ == "__main__":
    errors = verify()
    for error in errors:
        print(error)
    if errors:
        raise SystemExit(1)
