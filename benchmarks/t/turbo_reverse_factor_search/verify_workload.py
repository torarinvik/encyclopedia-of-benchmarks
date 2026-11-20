"""Static workload, provenance, and ten-port inventory checks."""
from __future__ import annotations

import json
from pathlib import Path
import re

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "turbo_reverse_factor_search"
PORTS = {
    "c": "c/t/turbo_reverse_factor_search.c",
    "c3": "c3/t/turbo_reverse_factor_search.c3",
    "cpp": "cpp/t/turbo_reverse_factor_search.cpp",
    "elisa": "elisa/t/turbo_reverse_factor_search.elisa",
    "mojo": "mojo/t/turbo_reverse_factor_search.mojo",
    "nim": "nim/t/turbo_reverse_factor_search.nim",
    "odin": "odin/t/turbo_reverse_factor_search.odin",
    "rust": "rust/t/turbo_reverse_factor_search.rs",
    "v": "v/t/turbo_reverse_factor_search.v",
    "zig": "zig/t/turbo_reverse_factor_search.zig",
}
MAX_TEXT = 4096
MAX_PATTERN = 128
MAX_VALID_LENGTH = 2 + MAX_TEXT + MAX_PATTERN
MAX_PARSEABLE_LENGTH = MAX_VALID_LENGTH + 1
MAX_SYMBOL = 3
PAGE_URL = "https://www-igm.univ-mlv.fr/~lecroq/string/node24.html"
PDF_URL = "https://ligm.univ-eiffel.fr/~lecroq/string/string.pdf"
DOI_URL = "https://doi.org/10.1007/BF01185427"


def static_issues() -> list[str]:
    """Read package files only; this check does not import or invoke the oracles."""
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]
    if not isinstance(workload, dict):
        return ["workload metadata must be an object"]
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("unexpected workload identity or ABI")

    source = workload.get("source", {})
    input_spec = workload.get("input", {})
    output = workload.get("output", {})
    contract = workload.get("contract", {})
    workspace = workload.get("workspace", {})
    measurement = workload.get("measurement", {})
    if not all(isinstance(obj, dict) for obj in
               (source, input_spec, output, contract, workspace, measurement)):
        return issues + ["source, input, output, contract, workspace, and measurement must be objects"]
    if (source.get("algorithm_description_url") != PAGE_URL
            or source.get("reference_pdf") != PDF_URL
            or source.get("url") != DOI_URL):
        issues.append("algorithm attribution differs from the cited references")
    if (input_spec.get("text_length_range") != [0, MAX_TEXT]
            or input_spec.get("pattern_length_range") != [1, MAX_PATTERN]
            or input_spec.get("alphabet_range") != [0, MAX_SYMBOL]
            or input_spec.get("maximum_valid_length") != MAX_VALID_LENGTH
            or input_spec.get("maximum_parseable_length") != MAX_PARSEABLE_LENGTH
            or input_spec.get("invalid_input_result") != -1):
        issues.append("input framing or bounds differ")
    if (output.get("kind") != "signed_64_bit_integer"
            or output.get("includes_overlapping_matches") is not True
            or output.get("invalid_input_result") != -1
            or output.get("encoding")
            != "(match_count << 36) | (sum_of_offsets << 12) | xor_of_offsets"):
        issues.append("output contract differs")
    if workspace.get("bytes") != 28672:
        issues.append("workspace bound differs")
    if ("suffix automaton" not in contract.get("automaton", "")
            or "at most 2n" not in contract.get("complexity", "")):
        issues.append("contract omits the weighted automaton or source inspection bound")
    if measurement.get("comparison_model") != "i64_array_scalar_call":
        issues.append("measurement ABI differs")

    for filename in ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
                     "primary_oracle.py", "independent_oracle.py", "verify_workload.py"):
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
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol in {relative}")

    readme_path = PACKAGE / "README.md"
    rights_path = PACKAGE / "RIGHTS.md"
    if readme_path.is_file() and rights_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        rights = rights_path.read_text(encoding="utf-8")
        for filename in ("RIGHTS.md", "INVENTORY.md", "workload.json",
                         "primary_oracle.py", "independent_oracle.py"):
            if filename not in readme:
                issues.append(f"README omits package reference: {filename}")
        for document, contents in (("README.md", readme), ("RIGHTS.md", rights)):
            if PAGE_URL not in contents or PDF_URL not in contents or DOI_URL not in contents:
                issues.append(f"source attribution missing from {document}")
        if "independently written" not in rights:
            issues.append("rights note omits clean-room scope")
        for target in re.findall(r"\]\(([^)]+)\)", readme):
            if target.startswith(("http://", "https://", "#")):
                continue
            if not (PACKAGE / target.split("#", 1)[0]).resolve().is_file():
                issues.append(f"broken README target: {target}")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload must contain semantic cases"]
    seen: set[str] = set()
    for case in cases:
        if (not isinstance(case, dict) or not isinstance(case.get("id"), str)
                or not isinstance(case.get("input_values"), list)
                or type(case.get("expected_result")) is not int):
            issues.append("invalid scalar workload case")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate workload case: {case_id}")
            continue
        seen.add(case_id)
        values = case["input_values"]
        if (len(values) > MAX_PARSEABLE_LENGTH
                or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                       for value in values)):
            issues.append(f"invalid signed-i64 fixture: {case_id}")
            continue
        if case.get("input_length", len(values)) != len(values):
            issues.append(f"fixture input length differs: {case_id}")
        if case.get("input_is_null", False):
            if case["expected_result"] != -1:
                issues.append(f"null input must be invalid: {case_id}")
            continue
        if case["expected_result"] >= 0:
            if len(values) < 2:
                issues.append(f"successful fixture lacks header: {case_id}")
                continue
            n, m = values[:2]
            if (not 0 <= n <= MAX_TEXT or not 1 <= m <= MAX_PATTERN
                    or len(values) != 2 + n + m
                    or any(not 0 <= symbol <= MAX_SYMBOL for symbol in values[2:])):
                issues.append(f"successful fixture violates input contract: {case_id}")

    profiles = measurement.get("profiles")
    if not isinstance(profiles, list):
        issues.append("measurement profiles must be a list")
    else:
        cases_by_id = {case["id"]: case for case in cases
                       if isinstance(case, dict) and isinstance(case.get("id"), str)}
        for profile in profiles:
            if not isinstance(profile, dict) or profile.get("id") not in cases_by_id:
                issues.append("measurement profile has no matching case")
                continue
            case = cases_by_id[profile["id"]]
            if (profile.get("input_values") != case.get("input_values")
                    or profile.get("expected_result") != case.get("expected_result")):
                issues.append(f"measurement profile differs from case: {profile['id']}")
    return issues
