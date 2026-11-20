"""Static workload, reference, and source inventory checker."""

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SOURCE_URL = "https://en.oi-wiki.org/dp/plug/"
SYMBOL = "connectivity_aware_plug_dp_binary_grid_colorings"
PORTS = (
    "c/c/connectivity_aware_plug_dp_binary_grid_colorings.c",
    "c3/c/connectivity_aware_plug_dp_binary_grid_colorings.c3",
    "cpp/c/connectivity_aware_plug_dp_binary_grid_colorings.cpp",
    "elisa/c/connectivity_aware_plug_dp_binary_grid_colorings.elisa",
    "mojo/c/connectivity_aware_plug_dp_binary_grid_colorings.mojo",
    "nim/c/connectivity_aware_plug_dp_binary_grid_colorings.nim",
    "odin/c/connectivity_aware_plug_dp_binary_grid_colorings.odin",
    "rust/c/connectivity_aware_plug_dp_binary_grid_colorings.rs",
    "v/c/connectivity_aware_plug_dp_binary_grid_colorings.v",
    "zig/c/connectivity_aware_plug_dp_binary_grid_colorings.zig",
)


def static_issues() -> list[str]:
    """Check artifact, fixture, and source-path structure without executing references."""
    issues = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload or inventory JSON: {error}"]
    if not isinstance(workload, dict) or not isinstance(inventory, dict):
        return ["workload and inventory JSON roots must be objects"]

    if (workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("workload identity or ABI is inconsistent")
    if (inventory.get("algorithm") != SYMBOL or inventory.get("symbol") != SYMBOL
            or inventory.get("abi") != "i64_array_scalar"):
        issues.append("inventory identity or ABI is inconsistent")
    if inventory.get("ports") != list(PORTS):
        issues.append("inventory port list differs from the ten supported language paths")
    if (inventory.get("max_valid_input_length") != 2
            or inventory.get("max_parseable_input_length") != 3
            or inventory.get("workspace_bytes") != 1_259_712):
        issues.append("inventory bounds or workspace do not match the package contract")

    source = workload.get("source", {})
    if not isinstance(source, dict): source = {}
    if source.get("url") != SOURCE_URL or source.get("model_reference") != "UVA 10572 Black & White":
        issues.append("workload provenance fields are inconsistent")
    contract = workload.get("contract", {})
    if not isinstance(contract, dict): contract = {}
    if (contract.get("input_layout") != "[rows,columns]"
            or contract.get("invalid_result") != -1
            or contract.get("dimensions") != "2<=rows,columns<=4"):
        issues.append("workload contract fields are inconsistent")
    input_contract = workload.get("input", {})
    if not isinstance(input_contract, dict): input_contract = {}
    if (input_contract.get("rows_range") != [2, 4]
            or input_contract.get("columns_range") != [2, 4]
            or input_contract.get("maximum_valid_values") != 2
            or input_contract.get("maximum_parseable_values") != 3):
        issues.append("workload input bounds are inconsistent")
    measurement = workload.get("measurement", {})
    if not isinstance(measurement, dict): measurement = {}
    if (measurement.get("comparison_model") != "i64_array_scalar_call"
            or not all(type(measurement.get(key)) is int and measurement[key] > 0
                       for key in ("sample_count", "warmup_rounds", "repetitions_per_sample"))):
        issues.append("workload measurement defaults are missing or invalid")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        issues.append("workload cases must be a nonempty list")
    else:
        seen_ids = set()
        for case in cases:
            if not isinstance(case, dict):
                issues.append("workload case must be an object")
                continue
            case_id = case.get("id")
            values = case.get("input_values")
            if not isinstance(case_id, str) or case_id in seen_ids:
                issues.append("workload case IDs must be unique strings")
            else:
                seen_ids.add(case_id)
            if (not isinstance(values, list) or len(values) > 3
                    or any(type(value) is not int for value in values)
                    or type(case.get("expected_result")) is not int):
                issues.append(f"workload case has malformed scalar framing: {case_id}")

    try:
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    except OSError as error:
        issues.append(f"cannot read package documentation: {error}")
        readme = ""
        rights = ""
    if SOURCE_URL not in readme or SOURCE_URL not in rights:
        issues.append("README or rights omits the primary method source")
    for relative in PORTS:
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing port source: {relative}")
            continue
        try:
            source_text = path.read_text(encoding="utf-8")
        except OSError as error:
            issues.append(f"cannot read port source {relative}: {error}")
            continue
        if SYMBOL not in source_text:
            issues.append(f"port source omits the exported symbol: {relative}")
        if relative not in readme:
            issues.append(f"README omits port path: {relative}")
    return issues


def check_inventory() -> int:
    # This opt-in deeper checker compares fixture results through both oracles.
    # `static_issues` above deliberately does not import or invoke them.
    from .independent_oracle import expected_result as independent_result
    from .primary_oracle import (
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        WORKSPACE_BYTES,
        expected_result,
    )

    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    symbol = SYMBOL
    if (workload.get("algorithm") != symbol
            or workload.get("function_symbol") != symbol
            or workload.get("abi") != "i64_array_scalar"):
        raise ValueError("workload identity differs from package")
    if inventory.get("algorithm") != symbol or inventory.get("source_url") != SOURCE_URL:
        raise ValueError("inventory identity or provenance differs from package")
    if (inventory.get("max_valid_input_length") != MAX_VALID_INPUT_LENGTH
            or inventory.get("max_parseable_input_length") != MAX_PARSEABLE_INPUT_LENGTH
            or inventory.get("workspace_bytes") != WORKSPACE_BYTES):
        raise ValueError("inventory bounds differ from primary reference")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("workload must contain cases")
    seen = set()
    for case in cases:
        case_id = case.get("id") if isinstance(case, dict) else None
        values = case.get("input_values") if isinstance(case, dict) else None
        if not isinstance(case_id, str) or case_id in seen:
            raise ValueError("case IDs must be unique strings")
        seen.add(case_id)
        primary = expected_result(values)
        independent = independent_result(values)
        if primary != independent or primary != case.get("expected_result"):
            raise ValueError(f"fixture differs from references: {case_id}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    source = workload.get("source", {})
    if (source.get("url") != SOURCE_URL
            or source.get("model_reference") != "UVA 10572 Black & White"
            or SOURCE_URL not in readme or SOURCE_URL not in rights):
        raise ValueError("README, rights, or workload omits method attribution")
    ports = inventory.get("ports")
    if not isinstance(ports, list) or len(ports) != 10:
        raise ValueError("inventory must list ten ports")
    for relative in ports:
        path = ROOT / relative
        if (not path.is_file() or symbol not in path.read_text(encoding="utf-8")
                or relative not in readme):
            raise ValueError(f"source or README path missing: {relative}")
    return len(cases)
