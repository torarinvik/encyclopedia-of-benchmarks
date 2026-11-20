"""Static package, workload, documentation, and port inspection."""

from __future__ import annotations

import json
from pathlib import Path
import re

from .independent_oracle import expected_output as independent_output
from .primary_oracle import expected_output as primary_output

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "statistical_region_merging_table"
PAPER_URL = "https://www.lix.polytechnique.fr/~nielsen/pdf/2004-StatisticalRegionMerging-PAMI.pdf"
PARSEC_URL = "https://www.cs.princeton.edu/techreports/2010/890.pdf"
PORTS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED_CASES = {
    "singleton", "equal_neighbors_merge", "merge_at_exact_squared_bound",
    "reject_above_squared_bound", "all_neighbors_merge", "short_output",
    "null_output", "bad_bound", "bad_pixel", "truncated", "null_input",
}


def verify_inventory(workload: object | None = None) -> list[str]:
    """Return source-only package issues; never compiles or invokes a port."""
    issues: list[str] = []
    required_files = (
        "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
        "primary_oracle.py", "independent_oracle.py", "check_inventory.py",
    )
    for name in required_files:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")

    for language, extension in PORTS.items():
        relative = Path(language) / "s" / f"{SYMBOL}.{extension}"
        source = ROOT / relative
        if not source.is_file():
            issues.append(f"missing language port: {relative.as_posix()}")
        elif SYMBOL not in source.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {relative.as_posix()}")

    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return issues + [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return issues + ["workload must be an object"]

    expected_input = {
        "kind": "signed_64_bit_integer_array",
        "encoding": "[height,width,bounds[height*width],pixels[height*width]]",
        "maximum_valid_length": 74,
        "maximum_parseable_length": 74,
        "invalid_input_result": -1,
    }
    expected_output = {
        "kind": "byte_vector",
        "encoding": "minimum row-major pixel index per region",
        "maximum_bytes": 36,
        "null_output_result": -2,
        "insufficient_capacity_result": -2,
        "no_write_on_error": True,
    }
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_bytes_output"):
        issues.append("workload identity or ABI differs")
    if workload.get("input") != expected_input:
        issues.append("input framing or bounds differ")
    if workload.get("output") != expected_output:
        issues.append("output contract differs")
    if workload.get("workspace") != {
            "bytes": 4096,
            "meaning": "Pixel regions, sums, sizes, ordered edges, and output.",
    }:
        issues.append("workspace metadata differs")
    if workload.get("measurement") != {
            "comparison_model": "i64_array_bytes_output_call",
            "sample_count": 8, "warmup_rounds": 1,
            "repetitions_per_sample": 100,
    }:
        issues.append("measurement metadata differs")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases must be a nonempty array"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("malformed workload case")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate case id: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        capacity = case.get("output_capacity")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        result = case.get("expected_result")
        output_hex = case.get("expected_output_hex")
        if (not isinstance(values, list) or type(length) is not int
                or type(capacity) is not int or type(input_is_null) is not bool
                or type(output_is_null) is not bool or type(result) is not int
                or not isinstance(output_hex, str)):
            issues.append(f"malformed fields: {case_id}")
            continue
        if (input_is_null and values
                or not input_is_null and length != len(values)):
            issues.append(f"input framing mismatch: {case_id}")
            continue
        try:
            declared_bytes = bytes.fromhex(output_hex)
        except ValueError:
            issues.append(f"invalid output hex: {case_id}")
            continue
        primary = primary_output(values, capacity, output_is_null,
                                 input_is_null, length)
        independent = independent_output(values, capacity, output_is_null,
                                         input_is_null, length)
        if primary != independent:
            issues.append(f"references disagree: {case_id}")
        if primary != (result, declared_bytes):
            issues.append(f"fixture differs from references: {case_id}")

    missing_cases = REQUIRED_CASES - seen
    if missing_cases:
        issues.append("missing required cases: " + ", ".join(sorted(missing_cases)))

    readme_path = PACKAGE / "README.md"
    rights_path = PACKAGE / "RIGHTS.md"
    if readme_path.is_file() and rights_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        rights = rights_path.read_text(encoding="utf-8")
        for url in (PAPER_URL, PARSEC_URL):
            if url not in readme or url not in rights:
                issues.append(f"missing provenance URL: {url}")
        for language, extension in PORTS.items():
            link = f"](../../../{language}/s/{SYMBOL}.{extension})"
            if link not in readme:
                issues.append(f"missing README port link: {language}")
        for target in re.findall(r"\]\(([^)]+)\)", readme):
            if target.startswith(("https://", "http://", "#")):
                continue
            local_path = (PACKAGE / target.split("#", 1)[0]).resolve()
            if not local_path.is_file():
                issues.append(f"broken README link: {target}")
    return issues


static_issues = verify_inventory
