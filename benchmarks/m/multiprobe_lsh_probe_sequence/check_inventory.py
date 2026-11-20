"""Static package inventory review; does not execute benchmark code."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
ALGORITHM = "multiprobe_lsh_probe_sequence"
PORTS = {
    "c": "c/m/multiprobe_lsh_probe_sequence.c",
    "c3": "c3/m/multiprobe_lsh_probe_sequence.c3",
    "cpp": "cpp/m/multiprobe_lsh_probe_sequence.cpp",
    "elisa": "elisa/m/multiprobe_lsh_probe_sequence.elisa",
    "mojo": "mojo/m/multiprobe_lsh_probe_sequence.mojo",
    "nim": "nim/m/multiprobe_lsh_probe_sequence.nim",
    "odin": "odin/m/multiprobe_lsh_probe_sequence.odin",
    "rust": "rust/m/multiprobe_lsh_probe_sequence.rs",
    "v": "v/m/multiprobe_lsh_probe_sequence.v",
    "zig": "zig/m/multiprobe_lsh_probe_sequence.zig",
}
ORACLES = (
    "benchmarks/multiprobe_lsh_probe_sequence_oracle.py",
    "benchmarks/multiprobe_lsh_probe_sequence_verifier_oracle.py",
)
PACKAGE_FILES = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json",
    "workload.json", "check_inventory.py",
)
EXPECTED_FIXTURES = {
    "single_projection",
    "zero_cost_ties_and_invalid_ancestors",
    "zero_requested",
    "short_output",
    "null_output_empty",
    "distance_outside_bin",
    "too_many_probes",
    "null_input",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    for name in PACKAGE_FILES:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for relative in ORACLES:
        if not (ROOT / relative).is_file():
            issues.append(f"missing oracle: {relative}")
    for language, relative in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        if ALGORITHM not in path.read_text(encoding="utf-8"):
            issues.append(f"export marker missing in {relative}")

    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read package JSON: {error}"]

    if (inventory.get("algorithm") != ALGORITHM
            or inventory.get("function_symbol") != ALGORITHM
            or inventory.get("abi") != "i64_array_bytes_output"
            or set(inventory.get("native_paths", [])) != set(PORTS.values())
            or set(inventory.get("oracle_paths", [])) != set(ORACLES)
            or set(inventory.get("package_files", [])) != set(PACKAGE_FILES)):
        issues.append("inventory identity or artifact lists differ from package files")
    if (workload.get("algorithm") != ALGORITHM
            or workload.get("function_symbol") != ALGORITHM
            or workload.get("abi") != "i64_array_bytes_output"):
        issues.append("workload identity or ABI differs from the package")

    bounds = inventory.get("bounds", {})
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    if (bounds.get("maximum_dimensions") != 4
            or bounds.get("maximum_width") != 1000
            or bounds.get("maximum_valid_input_length") != 7
            or bounds.get("maximum_parseable_input_length") != 7
            or bounds.get("maximum_valid_probe_count") != 80
            or bounds.get("maximum_output_bytes") != 80
            or bounds.get("workspace_bytes") != 4096
            or input_spec.get("maximum_valid_length") != 7
            or input_spec.get("maximum_parseable_length") != 7
            or output_spec.get("maximum_bytes") != 80
            or workload.get("workspace", {}).get("bytes") != 4096):
        issues.append("inventory/workload bounds differ from the bounded profile")

    cases = workload.get("cases", [])
    case_ids = [case.get("id") for case in cases if isinstance(case, dict)]
    if (len(case_ids) != len(cases) or len(case_ids) != len(set(case_ids))
            or set(case_ids) != EXPECTED_FIXTURES
            or set(case_ids) != set(inventory.get("fixture_ids", []))):
        issues.append("workload fixtures differ from the inventory list")
    for case in cases:
        if not isinstance(case, dict):
            continue
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"{case.get('id')}: input framing differs")
            continue
        expected_result = case.get("expected_result")
        expected_hex = case.get("expected_output_hex", "")
        try:
            payload = bytes.fromhex(expected_hex)
        except (TypeError, ValueError):
            issues.append(f"{case.get('id')}: output hex is malformed")
            continue
        if type(expected_result) is not int:
            issues.append(f"{case.get('id')}: expected result is not an integer")
        elif expected_result < 0 and payload:
            issues.append(f"{case.get('id')}: error fixture must not write output")
        elif expected_result >= 0 and (len(payload) != expected_result
                                       or len(payload) > 80):
            issues.append(f"{case.get('id')}: output framing exceeds declared bounds")

    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8") if (PACKAGE / "RIGHTS.md").is_file() else ""
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8") if (PACKAGE / "README.md").is_file() else ""
    for phrase in ("method identification", "not as source-code licenses", "not copied"):
        if phrase not in rights:
            issues.append(f"rights/provenance note is missing: {phrase}")
    for url in ("https://www.cs.princeton.edu/cass/papers/mplsh_vldb07.pdf",
                "https://www.cs.princeton.edu/techreports/2010/890.pdf"):
        if url not in readme or url not in rights:
            issues.append(f"method source is not linked from README and RIGHTS: {url}")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
