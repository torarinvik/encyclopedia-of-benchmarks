"""Static artifact and workload-framing review; does not call the references."""

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "efficient_dominating_set_square_graph_mwis"
SOURCE_URL = "https://doi.org/10.1007/978-1-4939-2864-4_689"
PORTS = (
    "c/e/efficient_dominating_set_square_graph_mwis.c",
    "c3/e/efficient_dominating_set_square_graph_mwis.c3",
    "cpp/e/efficient_dominating_set_square_graph_mwis.cpp",
    "elisa/e/efficient_dominating_set_square_graph_mwis.elisa",
    "mojo/e/efficient_dominating_set_square_graph_mwis.mojo",
    "nim/e/efficient_dominating_set_square_graph_mwis.nim",
    "odin/e/efficient_dominating_set_square_graph_mwis.odin",
    "rust/e/efficient_dominating_set_square_graph_mwis.rs",
    "v/e/efficient_dominating_set_square_graph_mwis.v",
    "zig/e/efficient_dominating_set_square_graph_mwis.zig",
)


def static_issues() -> list[str]:
    issues = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload or inventory: {error}"]
    if not isinstance(workload, dict) or not isinstance(inventory, dict):
        return ["workload and inventory roots must be JSON objects"]
    if (workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("workload identity or ABI differs from package")
    if (inventory.get("algorithm") != SYMBOL or inventory.get("symbol") != SYMBOL
            or inventory.get("abi") != "i64_array_scalar"
            or inventory.get("source_url") != SOURCE_URL):
        issues.append("inventory identity, ABI, or provenance differs from package")
    if inventory.get("ports") != list(PORTS):
        issues.append("inventory does not list the ten expected ports")
    if (inventory.get("max_valid_input_length") != 134
            or inventory.get("max_parseable_input_length") != 135
            or inventory.get("workspace_bytes") != 4096):
        issues.append("inventory bounds or workspace differ from contract")
    source = workload.get("source", {})
    if not isinstance(source, dict) or source.get("url") != SOURCE_URL:
        issues.append("workload provenance is missing or inconsistent")
    contract = workload.get("contract", {})
    if (not isinstance(contract, dict)
            or contract.get("input_layout") != "[n,edge_count,u0,v0,...]"
            or contract.get("invalid_result") != -1):
        issues.append("workload contract fields are inconsistent")
    input_spec = workload.get("input", {})
    if (not isinstance(input_spec, dict)
            or input_spec.get("vertex_count_range") != [1, 12]
            or input_spec.get("edge_count_range") != [0, 66]
            or input_spec.get("maximum_valid_length") != 134
            or input_spec.get("maximum_parseable_length") != 135):
        issues.append("workload input limits are inconsistent")
    measurement = workload.get("measurement", {})
    if (not isinstance(measurement, dict)
            or measurement.get("comparison_model") != "i64_array_scalar_call"
            or any(type(measurement.get(key)) is not int or measurement[key] <= 0
                   for key in ("sample_count", "warmup_rounds", "repetitions_per_sample"))):
        issues.append("measurement defaults are missing or invalid")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        issues.append("workload cases must be a nonempty list")
    else:
        seen = set()
        for case in cases:
            if not isinstance(case, dict):
                issues.append("workload case is not an object")
                continue
            case_id = case.get("id")
            values = case.get("input_values")
            if not isinstance(case_id, str) or case_id in seen:
                issues.append("workload case IDs are not unique strings")
            else:
                seen.add(case_id)
            if (not isinstance(values, list)
                    or type(case.get("expected_result")) is not int
                    or any(type(value) is not int for value in values)):
                issues.append(f"workload case has malformed values: {case_id}")
                continue
            if len(values) > 135:
                issues.append(f"workload case exceeds parseable frame bound: {case_id}")
        maximum = next((case for case in cases if isinstance(case, dict)
                        and case.get("id") == "maximum-complete-graph"), None)
        trailing = next((case for case in cases if isinstance(case, dict)
                         and case.get("id") == "maximum-parseable-trailing-word"), None)
        if not isinstance(maximum, dict) or len(maximum.get("input_values", [])) != 134:
            issues.append("maximum fixture does not exercise the 134-word valid frame")
        elif maximum["input_values"][:2] != [12, 66]:
            issues.append("maximum fixture does not describe a 12-vertex 66-edge graph")
        if not isinstance(trailing, dict):
            issues.append("trailing fixture does not exercise the 135-word parse bound")
        else:
            trailing_values = trailing.get("input_values", [])
            maximum_values = maximum.get("input_values", []) if isinstance(maximum, dict) else None
            if (not isinstance(trailing_values, list) or len(trailing_values) != 135
                    or not isinstance(maximum_values, list)
                    or trailing_values[:-1] != maximum_values):
                issues.append("trailing fixture does not extend the maximum valid frame")

    try:
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    except OSError as error:
        issues.append(f"cannot read package documentation: {error}")
        readme = rights = ""
    if SOURCE_URL not in readme or SOURCE_URL not in rights:
        issues.append("README or rights omits the chapter citation")
    for relative in PORTS:
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing language port: {relative}")
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except OSError as error:
            issues.append(f"cannot read language port {relative}: {error}")
            continue
        if SYMBOL not in text:
            issues.append(f"language port omits symbol: {relative}")
        if relative not in readme:
            issues.append(f"README omits language path: {relative}")
    return issues
