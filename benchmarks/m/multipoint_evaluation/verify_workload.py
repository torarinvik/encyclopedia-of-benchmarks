"""Static workload, provenance, dual-oracle, and ten-port inventory checker."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import expected_output as independent_output
    from .primary_oracle import expected_output as primary_output
except ImportError:  # Direct invocation from this package directory.
    from independent_oracle import expected_output as independent_output
    from primary_oracle import expected_output as primary_output

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "multipoint_evaluation"
TASK_URL = "https://github.com/yosupo06/library-checker-problems/blob/master/polynomial/multipoint_evaluation/task.md"
LIMITS_URL = "https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/polynomial/multipoint_evaluation/info.toml"
PORTS = {
    "c": ROOT / "c/m/multipoint_evaluation.c",
    "c3": ROOT / "c3/m/multipoint_evaluation.c3",
    "cpp": ROOT / "cpp/m/multipoint_evaluation.cpp",
    "elisa": ROOT / "elisa/m/multipoint_evaluation.elisa",
    "mojo": ROOT / "mojo/m/multipoint_evaluation.mojo",
    "nim": ROOT / "nim/m/multipoint_evaluation.nim",
    "odin": ROOT / "odin/m/multipoint_evaluation.odin",
    "rust": ROOT / "rust/m/multipoint_evaluation.rs",
    "v": ROOT / "v/m/multipoint_evaluation.v",
    "zig": ROOT / "zig/m/multipoint_evaluation.zig",
}


def verify() -> list[str]:
    errors: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"workload cannot be read: {error}"]
    source = workload.get("source", {})
    if (workload.get("schema_version") != 1 or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_bytes_output"
            or source.get("task_url") != TASK_URL or source.get("limits_url") != LIMITS_URL
            or source.get("official_n_max") != 131072 or source.get("official_m_max") != 131072
            or source.get("modulus") != 998244353 or source.get("repository_license") != "Apache-2.0"):
        errors.append("workload identity or official attribution mismatch")
    contract = workload.get("contract", {})
    if (contract.get("coefficient_count_range") != [1, 8]
            or contract.get("point_count_range") != [1, 8]
            or contract.get("coefficient_and_point_range") != [0, 998244352]
            or contract.get("modulus") != 998244353):
        errors.append("bounded multipoint-evaluation contract mismatch")
    if (workload.get("input", {}).get("maximum_valid_length") != 18
            or workload.get("input", {}).get("maximum_parseable_length") != 18
            or workload.get("output", {}).get("maximum_output_elements") != 8
            or workload.get("output", {}).get("maximum_bytes") != 64
            or workload.get("workspace", {}).get("maximum_bytes") != 4096):
        errors.append("input, output, or workspace bounds mismatch")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return errors + ["workload must contain named fixtures"]
    identifiers = {case.get("id") for case in cases if isinstance(case, dict)}
    if len(identifiers) != len(cases):
        errors.append("fixture IDs are missing or duplicated")
    for case in cases:
        if not isinstance(case, dict):
            errors.append("fixture entry is not an object")
            continue
        values = case.get("input_values", [])
        length = case.get("input_length")
        primary = primary_output(values, case.get("output_capacity"),
                                 case.get("output_is_null", False),
                                 case.get("input_is_null", False), length)
        independent = independent_output(values, case.get("output_capacity"),
                                         case.get("output_is_null", False),
                                         case.get("input_is_null", False), length)
        if (length != len(values) or primary != independent
                or primary[0] != case.get("expected_result")
                or primary[1].hex() != case.get("expected_output_hex")):
            errors.append(f"fixture/oracle mismatch: {case.get('id')}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if TASK_URL not in readme or LIMITS_URL not in readme or "Apache-2.0" not in rights:
        errors.append("documentation omits source attribution or rights")
    if "product tree" not in readme or "remainder tree" not in readme or "Horner" not in readme:
        errors.append("README omits the algorithm distinction")
    for language, path in PORTS.items():
        if not path.is_file():
            errors.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            errors.append(f"entrypoint missing from {language} port")
        elif str(path.relative_to(ROOT)) not in readme:
            errors.append(f"README does not link {language} port")
    return errors


if __name__ == "__main__":
    print("checked static multipoint-evaluation package")
