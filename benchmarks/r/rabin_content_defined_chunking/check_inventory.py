"""Static package, workload, documentation, and port inspection."""

from __future__ import annotations

import json
from pathlib import Path
import re

try:
    from .independent_oracle import expected_output as independent_expected
    from .primary_oracle import (
        MAX_INPUT_LENGTH,
        MAX_OUTPUT_BYTES,
        expected_output as primary_expected,
    )
except ImportError:
    from independent_oracle import expected_output as independent_expected
    from primary_oracle import (
        MAX_INPUT_LENGTH,
        MAX_OUTPUT_BYTES,
        expected_output as primary_expected,
    )

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "rabin_content_defined_chunking"
SOURCES = (
    "https://www.cs.princeton.edu/techreports/2010/890.pdf",
    "https://www.usenix.org/legacy/events/usenix04/tech/general/full_papers/policroniades/policroniades_html/index.html",
)
EXTENSIONS = {
    "c": "c",
    "c3": "c3",
    "cpp": "cpp",
    "elisa": "elisa",
    "mojo": "mojo",
    "nim": "nim",
    "odin": "odin",
    "rust": "rs",
    "v": "v",
    "zig": "zig",
}
REQUIRED_FIXTURES = {
    "empty", "all_zero_windows", "outgoing_nonzero_byte",
    "outgoing_nonzero_byte_continues",
    "final_chunk_without_anchor", "short_output", "null_output_empty",
    "bad_byte", "truncated", "null_input",
}
REQUIRED_FILES = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "check_inventory.py",
)


def verify_inventory(workload: object | None = None) -> list[str]:
    issues: list[str] = []
    for name in REQUIRED_FILES:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")

    for language, extension in EXTENSIONS.items():
        relative = f"{language}/r/{SYMBOL}.{extension}"
        source = ROOT / relative
        if not source.is_file():
            issues.append(f"missing source port: {relative}")
        elif SYMBOL not in source.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {relative}")

    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return issues + [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return issues + ["workload must be an object"]

    input_meta = workload.get("input")
    output_meta = workload.get("output")
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_bytes_output"):
        issues.append("workload identity or ABI differs")
    if (not isinstance(input_meta, dict)
            or input_meta.get("maximum_valid_length") != MAX_INPUT_LENGTH
            or input_meta.get("maximum_parseable_length") != MAX_INPUT_LENGTH
            or input_meta.get("invalid_input_result") != -1):
        issues.append("input framing metadata differs")
    if (not isinstance(output_meta, dict)
            or output_meta.get("maximum_bytes") != MAX_OUTPUT_BYTES
            or output_meta.get("null_output_result") != -2
            or output_meta.get("insufficient_capacity_result") != -2
            or output_meta.get("no_write_on_error") is not True):
        issues.append("output metadata differs")
    workspace = workload.get("workspace")
    if not isinstance(workspace, dict) or workspace.get("bytes") != 1024:
        issues.append("workspace metadata differs")
    measurement = workload.get("measurement")
    if (not isinstance(measurement, dict)
            or measurement.get("comparison_model") != "i64_array_bytes_output_call"):
        issues.append("measurement metadata differs")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases must be a nonempty list"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid fixture record")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate fixture id: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        capacity = case.get("output_capacity")
        is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        expected = case.get("expected_result")
        expected_hex = case.get("expected_output_hex")
        if (not isinstance(values, list) or type(length) is not int
                or type(capacity) is not int or type(is_null) is not bool
                or type(output_is_null) is not bool or type(expected) is not int
                or not isinstance(expected_hex, str)):
            issues.append(f"invalid fixture fields: {case_id}")
            continue
        try:
            expected_output = bytes.fromhex(expected_hex)
        except ValueError:
            issues.append(f"invalid fixture output encoding: {case_id}")
            continue
        primary = primary_expected(values, capacity, output_is_null, is_null, length)
        independent = independent_expected(values, capacity, output_is_null, is_null, length)
        if primary != independent:
            issues.append(f"oracle disagreement: {case_id}")
        if primary != (expected, expected_output):
            issues.append(f"fixture result mismatch: {case_id}")

    missing = REQUIRED_FIXTURES - seen
    if missing:
        issues.append("missing required fixtures: " + ", ".join(sorted(missing)))

    readme_path = PACKAGE / "README.md"
    rights_path = PACKAGE / "RIGHTS.md"
    if readme_path.is_file() and rights_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        rights = rights_path.read_text(encoding="utf-8")
        for source in SOURCES:
            if source not in readme or source not in rights:
                issues.append(f"missing provenance URL: {source}")
        for language, extension in EXTENSIONS.items():
            target = f"](../../../{language}/r/{SYMBOL}.{extension})"
            if target not in readme:
                issues.append(f"missing README port link: {language}")
        for target in re.findall(r"\]\(([^)]+)\)", readme):
            if target.startswith(("http://", "https://", "#")):
                continue
            if not (PACKAGE / target.split("#", 1)[0]).resolve().is_file():
                issues.append(f"broken README target: {target}")

    return issues


static_issues = verify_inventory
