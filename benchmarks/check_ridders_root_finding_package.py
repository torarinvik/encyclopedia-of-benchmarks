"""Static source-inventory checks for the Ridders benchmark package."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks" / "r" / "ridders_root_finding"
SOURCES = {
    "c": ROOT / "c/r/ridders_root_finding.c",
    "c3": ROOT / "c3/r/ridders_root_finding.c3",
    "cpp": ROOT / "cpp/r/ridders_root_finding.cpp",
    "elisa": ROOT / "elisa/r/ridders_root_finding.elisa",
    "mojo": ROOT / "mojo/r/ridders_root_finding.mojo",
    "nim": ROOT / "nim/r/ridders_root_finding.nim",
    "odin": ROOT / "odin/r/ridders_root_finding.odin",
    "rust": ROOT / "rust/r/ridders_root_finding.rs",
    "v": ROOT / "v/r/ridders_root_finding.v",
    "zig": ROOT / "zig/r/ridders_root_finding.zig",
}
EXPECTED_CASES = {
    "sqrt_two_positive_bracket", "sqrt_two_negative_bracket", "cube_root_two",
    "monotone_cubic_root", "exact_left_endpoint_root", "exact_right_endpoint_root",
    "exact_midpoint_root", "tightest_tolerance_maximum_iteration_cap",
    "invalid_function_id", "invalid_unbracketed_interval", "invalid_reversed_interval",
    "invalid_fractional_field", "invalid_endpoint_outside_domain", "invalid_tolerance",
    "invalid_iteration_limit", "invalid_short_frame", "invalid_extra_frame_value",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    required = (
        PACKAGE / "README.md", PACKAGE / "RIGHTS.md", PACKAGE / "workload.json",
        ROOT / "benchmarks/ridders_root_finding_oracle.py",
        ROOT / "benchmarks/ridders_root_finding_verifier_oracle.py",
    )
    for path in required:
        if not path.is_file():
            issues.append(f"missing {path.relative_to(ROOT)}")
    contents: dict[str, str] = {}
    for language, path in SOURCES.items():
        if not path.is_file():
            issues.append(f"missing {path.relative_to(ROOT)}")
            continue
        source = path.read_text(encoding="utf-8")
        contents[language] = source
        if "ridders_root_finding" not in source:
            issues.append(f"{path.relative_to(ROOT)} lacks the exported symbol")
    elisa = contents.get("elisa", "")
    if elisa and ("view[f64]" not in elisa or "UnsafePointer" in elisa or "*f64" in elisa):
        issues.append("Elisa implementation must use safe views internally and ABI references only")

    workload_path = PACKAGE / "workload.json"
    if workload_path.is_file():
        try:
            workload = json.loads(workload_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            issues.append(f"invalid workload JSON: {error}")
        else:
            cases = workload.get("cases")
            case_ids = ({case.get("id") for case in cases}
                        if isinstance(cases, list) and all(isinstance(case, dict) for case in cases)
                        else set())
            if (workload.get("algorithm") != "ridders_root_finding"
                    or workload.get("function_symbol") != "ridders_root_finding"
                    or workload.get("abi") != "float64_slice_io"
                    or workload.get("input", {}).get("maximum_valid_input_length") != 5
                    or workload.get("input", {}).get("maximum_parseable_input_length") != 6
                    or workload.get("output", {}).get("maximum_elements") != 1
                    or workload.get("workspace", {}).get("elements") != 1
                    or workload.get("workspace", {}).get("bytes") != 8):
                issues.append("workload metadata differs from the bounded float64_slice_io contract")
            if case_ids != EXPECTED_CASES:
                issues.append("workload case inventory differs from the reviewed fixture set")
            if not isinstance(workload.get("abi_cases"), list) or not workload["abi_cases"]:
                issues.append("workload is missing ABI boundary fixtures")

    primary = ROOT / "benchmarks/ridders_root_finding_oracle.py"
    independent = ROOT / "benchmarks/ridders_root_finding_verifier_oracle.py"
    if primary.is_file():
        source = primary.read_text(encoding="utf-8")
        for token in ("MAX_VALID_INPUT_LENGTH = 5", "MAX_PARSEABLE_INPUT_LENGTH = 6",
                      "NUMERICAL_FAILURE = -3", "radicand", "candidate"):
            if token not in source:
                issues.append(f"primary oracle missing contract token {token!r}")
    if independent.is_file():
        source = independent.read_text(encoding="utf-8")
        if "Decimal" not in source or "_root(" not in source:
            issues.append("independent oracle must use Decimal root isolation")
    return issues
