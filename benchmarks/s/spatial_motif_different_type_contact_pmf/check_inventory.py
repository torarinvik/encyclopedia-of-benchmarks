"""Static package metadata/source review; intentionally not run while drafting."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/s/spatial_motif_different_type_contact_pmf"
ALGORITHM = "spatial_motif_different_type_contact_pmf"
LANGUAGE_PATHS = {
    "c": "c/s/spatial_motif_different_type_contact_pmf.c",
    "c3": "c3/s/spatial_motif_different_type_contact_pmf.c3",
    "cpp": "cpp/s/spatial_motif_different_type_contact_pmf.cpp",
    "elisa": "elisa/s/spatial_motif_different_type_contact_pmf.elisa",
    "mojo": "mojo/s/spatial_motif_different_type_contact_pmf.mojo",
    "nim": "nim/s/spatial_motif_different_type_contact_pmf.nim",
    "odin": "odin/s/spatial_motif_different_type_contact_pmf.odin",
    "rust": "rust/s/spatial_motif_different_type_contact_pmf.rs",
    "v": "v/s/spatial_motif_different_type_contact_pmf.v",
    "zig": "zig/s/spatial_motif_different_type_contact_pmf.zig",
}
CASE_IDS = {
    "single-slot-forced-heterotypic-contact",
    "one-direction-contact-probability",
    "dependent-opposite-directions",
    "two-target-slots-hypergeometric-special-case",
    "both-contact-directions-with-shared-composition",
    "all-positions-are-heterotypic-contacts",
    "zero-contact-expectation-is-zero-over-one",
    "maximum-frame-one-byte-short-output",
    "reject-first-sequence-count-sum",
    "reject-negative-residue-count",
    "reject-trailing-input-word",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package metadata: {error}"]

    if (inventory.get("algorithm") != ALGORITHM
            or inventory.get("function_symbol") != ALGORITHM
            or inventory.get("abi") != "i64_array_bytes_output"
            or inventory.get("languages") != LANGUAGE_PATHS):
        issues.append("inventory identity, ABI, or language map differs from the package contract")
    for name in inventory.get("metadata", []):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package metadata: {name}")
    for language, relative in LANGUAGE_PATHS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} source: {relative}")
        elif ALGORITHM not in path.read_text(encoding="utf-8"):
            issues.append(f"symbol marker missing in {relative}")

    cases = workload.get("cases", [])
    ids = [case.get("id") for case in cases]
    if len(ids) != len(set(ids)) or set(ids) != CASE_IDS:
        issues.append("workload fixture IDs differ from the reviewed case set")
    for case in cases:
        values = case.get("input_values", [])
        if case.get("input_length") != len(values):
            issues.append(f"input length differs from values in {case.get('id')}")
        try:
            payload = bytes.fromhex(case.get("expected_output_hex", ""))
        except ValueError:
            issues.append(f"invalid expected-output hex in {case.get('id')}")
            continue
        result = case.get("expected_result")
        if result >= 0 and result != len(payload):
            issues.append(f"byte result differs from expected payload in {case.get('id')}")
        if result < 0 and payload:
            issues.append(f"error fixture has output bytes in {case.get('id')}")

    capacity_case = next((case for case in cases
                          if case.get("id") == "maximum-frame-one-byte-short-output"), {})
    if (workload.get("input", {}).get("maximum_valid_length") != 5
            or workload.get("input", {}).get("maximum_sequence_length") != 10
            or workload.get("input", {}).get("maximum_valid_input_words") != 5
            or workload.get("input", {}).get("maximum_parseable_input_words") != 6
            or workload.get("output", {}).get("maximum_bytes") != 120
            or workload.get("output", {}).get("maximum_multiset_arrangements") != 4200
            or workload.get("workspace", {}).get("bytes") != 1024
            or inventory.get("contract", {}).get("maximum_output_bytes") != 120
            or inventory.get("contract", {}).get("maximum_parseable_input_words") != 6
            or inventory.get("contract", {}).get("workspace_bytes") != 1024
            or capacity_case.get("output_capacity") != 119
            or capacity_case.get("expected_result") != -2):
        issues.append("bounded input/output/workspace or capacity fixture differs from the package contract")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for phrase in ("10.1109/TCBB.2008.101", "three-category hypergeometric model",
                   "120 bytes", "4,200", "0/1", "dependent"):
        if phrase not in readme:
            issues.append(f"README is missing pinned profile text: {phrase}")
    return issues
