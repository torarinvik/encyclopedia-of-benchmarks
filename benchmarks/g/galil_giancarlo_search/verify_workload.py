"""Static workload, provenance, and source-inventory checks."""
from __future__ import annotations

import json
from pathlib import Path
import re

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "galil_giancarlo_search"
PORTS = {
    "c": "c/g/galil_giancarlo_search.c",
    "c3": "c3/g/galil_giancarlo_search.c3",
    "cpp": "cpp/g/galil_giancarlo_search.cpp",
    "elisa": "elisa/g/galil_giancarlo_search.elisa",
    "mojo": "mojo/g/galil_giancarlo_search.mojo",
    "nim": "nim/g/galil_giancarlo_search.nim",
    "odin": "odin/g/galil_giancarlo_search.odin",
    "rust": "rust/g/galil_giancarlo_search.rs",
    "v": "v/g/galil_giancarlo_search.v",
    "zig": "zig/g/galil_giancarlo_search.zig",
}
MAX_TEXT = 4096
MAX_PATTERN = 128
MAX_VALID_LENGTH = 2 + MAX_TEXT + MAX_PATTERN
MAX_PARSEABLE_LENGTH = MAX_VALID_LENGTH + 1
MAX_SYMBOL = 3
DOI_URL = "https://doi.org/10.1137/0221028"
DESCRIPTION_URL = "https://igm.univ-mlv.fr/~lecroq/string/node11.html"


def static_issues() -> list[str]:
    """Review package metadata and paths without launching a language port."""
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]
    if not isinstance(workload, dict):
        return ["workload metadata must be an object"]

    source = workload.get("source", {})
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    contract = workload.get("contract", {})
    measurement = workload.get("measurement", {})
    workspace = workload.get("workspace", {})
    for name, value in (("source", source), ("input", input_spec),
                        ("output", output_spec), ("contract", contract),
                        ("measurement", measurement), ("workspace", workspace)):
        if not isinstance(value, dict):
            issues.append(f"{name} metadata must be an object")

    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("unexpected workload identity or ABI")
    if (source.get("doi") != "10.1137/0221028"
            or source.get("url") != DOI_URL
            or source.get("algorithm_description_url") != DESCRIPTION_URL):
        issues.append("primary paper or algorithm-description citation differs")
    if (input_spec.get("kind") != "signed_64_bit_integer_array"
            or input_spec.get("text_length_range") != [0, MAX_TEXT]
            or input_spec.get("pattern_length_range") != [1, MAX_PATTERN]
            or input_spec.get("alphabet_range") != [0, MAX_SYMBOL]
            or input_spec.get("maximum_valid_length") != MAX_VALID_LENGTH
            or input_spec.get("maximum_parseable_length") != MAX_PARSEABLE_LENGTH
            or input_spec.get("invalid_input_result") != -1):
        issues.append("input framing or bounds differ from the package contract")
    if (output_spec.get("kind") != "signed_64_bit_integer"
            or output_spec.get("encoding")
            != "(match_count << 36) | (sum_of_offsets << 12) | xor_of_offsets"
            or output_spec.get("includes_overlapping_matches") is not True
            or output_spec.get("invalid_input_result") != -1):
        issues.append("scalar output contract differs")
    if workspace.get("bytes") != 49152:
        issues.append("workspace bound differs")
    if (measurement.get("comparison_model") != "i64_array_scalar_call"
            or not isinstance(measurement.get("profiles"), list)):
        issues.append("measurement profile is missing or has the wrong ABI")
    if ("heavy_resumption" not in contract
            or "at most 4n/3" not in contract.get("complexity", "")):
        issues.append("contract omits the heavy transition or source comparison bound")

    required_files = (
        "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
        "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    )
    for filename in required_files:
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package file: {filename}")

    inventory_path = PACKAGE / "INVENTORY.md"
    if inventory_path.is_file():
        inventory = inventory_path.read_text(encoding="utf-8")
        for relative in PORTS.values():
            if relative not in inventory:
                issues.append(f"inventory omits source path: {relative}")

    for language, relative in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        contents = path.read_text(encoding="utf-8")
        if SYMBOL not in contents:
            issues.append(f"missing exported symbol in {relative}")

    readme_path = PACKAGE / "README.md"
    rights_path = PACKAGE / "RIGHTS.md"
    if readme_path.is_file() and rights_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        rights = rights_path.read_text(encoding="utf-8")
        for filename in ("RIGHTS.md", "INVENTORY.md", "workload.json",
                         "primary_oracle.py", "independent_oracle.py"):
            if not (PACKAGE / filename).is_file() or filename not in readme:
                issues.append(f"README omits package reference: {filename}")
        for document, contents in (("README.md", readme), ("RIGHTS.md", rights)):
            if DOI_URL not in contents or DESCRIPTION_URL not in contents:
                issues.append(f"source attribution missing from {document}")
        if "clean-room" not in rights or "Only mathematical algorithm descriptions" not in rights:
            issues.append("rights note omits clean-room scope")
        for target in re.findall(r"\]\(([^)]+)\)", readme):
            if target.startswith(("http://", "https://", "#")):
                continue
            if not (PACKAGE / target.split("#", 1)[0]).resolve().is_file():
                issues.append(f"broken README target: {target}")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload must contain named semantic cases"]
    cases_by_id: dict[str, dict] = {}
    for case in cases:
        if (not isinstance(case, dict) or not isinstance(case.get("id"), str)
                or not isinstance(case.get("input_values"), list)
                or type(case.get("expected_result")) is not int):
            issues.append("invalid scalar workload case")
            continue
        case_id = case["id"]
        if case_id in cases_by_id:
            issues.append(f"duplicate workload case: {case_id}")
            continue
        cases_by_id[case_id] = case
        values = case["input_values"]
        if (len(values) > MAX_PARSEABLE_LENGTH
                or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                       for value in values)):
            issues.append(f"invalid signed-i64 fixture frame: {case_id}")
            continue
        input_length = case.get("input_length", len(values))
        if type(input_length) is not int or input_length != len(values):
            issues.append(f"fixture input length differs: {case_id}")
        if case.get("input_is_null", False):
            if case["expected_result"] != -1:
                issues.append(f"null input must be invalid: {case_id}")
            continue
        expected = case["expected_result"]
        if expected >= 0:
            if len(values) < 2:
                issues.append(f"successful frame lacks header: {case_id}")
                continue
            n, m = values[:2]
            if (not 0 <= n <= MAX_TEXT or not 1 <= m <= MAX_PATTERN
                    or len(values) != 2 + n + m
                    or any(not 0 <= value <= MAX_SYMBOL for value in values[2:])):
                issues.append(f"successful fixture violates input contract: {case_id}")

    profiles = measurement.get("profiles", [])
    if isinstance(profiles, list):
        for profile in profiles:
            if not isinstance(profile, dict) or profile.get("id") not in cases_by_id:
                issues.append("measurement profile has no matching semantic case")
                continue
            case = cases_by_id[profile["id"]]
            if (profile.get("input_values") != case.get("input_values")
                    or profile.get("expected_result") != case.get("expected_result")):
                issues.append(f"measurement profile differs from fixture: {profile['id']}")
    return issues
