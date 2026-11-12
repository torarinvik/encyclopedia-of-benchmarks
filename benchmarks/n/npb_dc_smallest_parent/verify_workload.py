"""Static package checks for the bounded NPB DC profile; runs no benchmark code."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": ROOT / "c/n/npb_dc_smallest_parent.c",
    "c3": ROOT / "c3/n/npb_dc_smallest_parent.c3",
    "cpp": ROOT / "cpp/n/npb_dc_smallest_parent.cpp",
    "elisa": ROOT / "elisa/n/npb_dc_smallest_parent.elisa",
    "mojo": ROOT / "mojo/n/npb_dc_smallest_parent.mojo",
    "nim": ROOT / "nim/n/npb_dc_smallest_parent.nim",
    "odin": ROOT / "odin/n/npb_dc_smallest_parent.odin",
    "rust": ROOT / "rust/n/npb_dc_smallest_parent.rs",
    "v": ROOT / "v/n/npb_dc_smallest_parent.v",
    "zig": ROOT / "zig/n/npb_dc_smallest_parent.zig",
}
ORACLES = (PACKAGE / "primary_oracle.py", PACKAGE / "independent_oracle.py")
REQUIRED_CASES = {
    "smallest-parent-beats-other-immediate-parent",
    "empty-view-lowest-added-dimension-tie-break",
    "maximum-dimensions-single-zero-row",
    "maximum-rows-one-aggregate-per-view",
    "malformed-packed-length",
    "attribute-out-of-range",
    "measure-out-of-range",
    "null-input",
}


def verify() -> list[str]:
    errors: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"workload cannot be read: {error}"]
    if workload.get("algorithm") != "npb_dc_smallest_parent":
        errors.append("workload algorithm mismatch")
    if workload.get("function_symbol") != "npb_dc_smallest_parent":
        errors.append("workload function symbol mismatch")
    if workload.get("oracle") != "benchmarks/n/npb_dc_smallest_parent/primary_oracle.py":
        errors.append("primary oracle path mismatch")
    if workload.get("independent_oracle") != "benchmarks/n/npb_dc_smallest_parent/independent_oracle.py":
        errors.append("independent oracle path mismatch")
    contract = workload.get("contract", {})
    if contract.get("views", "").find("inclusive") < 0:
        errors.append("contract must include all views, including the empty mask")
    if "fewest groups" not in contract.get("view_construction", ""):
        errors.append("contract must specify minimum-cardinality immediate parents")
    if "npb_serial_dc" not in contract.get("distinction", ""):
        errors.append("contract must distinguish the direct-projection NPB DC profile")
    cases = workload.get("cases", [])
    case_ids = {case.get("id") for case in cases}
    if not REQUIRED_CASES <= case_ids:
        errors.append(f"missing required fixtures: {sorted(REQUIRED_CASES - case_ids)}")
    for case in cases:
        values = case.get("input_values", [])
        if case.get("input_length") != len(values):
            errors.append(f"fixture length mismatch: {case.get('id')}")
        if case.get("input_is_null") and values:
            errors.append(f"null fixture must have no values: {case.get('id')}")
        if not case.get("input_is_null") and case.get("input_length", 0) > 98:
            errors.append(f"fixture exceeds packed-input bound: {case.get('id')}")
    source = workload.get("source", {})
    if source.get("report") != "NAS-03-005" or "nas.nasa.gov" not in source.get("url", ""):
        errors.append("NASA NAS-03-005 attribution is missing")
    if "Harinarayan" not in source.get("related_work", ""):
        errors.append("Harinarayan et al. citation is missing")
    for language, path in PORTS.items():
        if not path.is_file():
            errors.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif "npb_dc_smallest_parent" not in path.read_text(encoding="utf-8"):
            errors.append(f"port symbol missing: {path.relative_to(ROOT)}")
    for path in ORACLES:
        if not path.is_file():
            errors.append(f"missing oracle: {path.name}")
    for name in ("README.md", "RIGHTS.md", "workload.json", "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            errors.append(f"missing package file: {name}")
    return errors


if __name__ == "__main__":
    for error in verify():
        print(error)
