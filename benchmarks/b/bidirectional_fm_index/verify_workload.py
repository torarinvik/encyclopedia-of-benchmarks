"""Static fixture and source inventory for the bidirectional FM-index profile."""

from __future__ import annotations

import json
import re
from pathlib import Path
from urllib.parse import unquote

try:
    from .independent_oracle import expected_result as independent_result
    from .primary_oracle import (
        MAX_OPERATIONS,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_TEXT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        MIN_TEXT_LENGTH,
        expected_result as primary_result,
    )
except ImportError:  # Direct import from this package directory.
    from independent_oracle import expected_result as independent_result
    from primary_oracle import (
        MAX_OPERATIONS,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_TEXT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        MIN_TEXT_LENGTH,
        expected_result as primary_result,
    )

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
ALGORITHM = "bidirectional_fm_index"
SOURCE_URL = "https://doi.org/10.1109/BIBM.2009.42"
PORTS = {
    "c": ROOT / "c/b/bidirectional_fm_index.c",
    "c3": ROOT / "c3/b/bidirectional_fm_index.c3",
    "cpp": ROOT / "cpp/b/bidirectional_fm_index.cpp",
    "elisa": ROOT / "elisa/b/bidirectional_fm_index.elisa",
    "mojo": ROOT / "mojo/b/bidirectional_fm_index.mojo",
    "nim": ROOT / "nim/b/bidirectional_fm_index.nim",
    "odin": ROOT / "odin/b/bidirectional_fm_index.odin",
    "rust": ROOT / "rust/b/bidirectional_fm_index.rs",
    "v": ROOT / "v/b/bidirectional_fm_index.v",
    "zig": ROOT / "zig/b/bidirectional_fm_index.zig",
}


def verify(workload: dict | None = None) -> list[str]:
    """Return static package issues; this function never executes a port."""
    issues: list[str] = []
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload metadata: {error}"]
    if not isinstance(workload, dict):
        return ["workload must be an object"]

    if workload.get("algorithm") != ALGORITHM:
        issues.append("algorithm name mismatch")
    if workload.get("function_symbol") != ALGORITHM:
        issues.append("function symbol mismatch")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("ABI mismatch")
    source = workload.get("source")
    if not isinstance(source, dict) or source.get("url") != SOURCE_URL:
        issues.append("primary source URL mismatch")
    input_contract = workload.get("input")
    if not isinstance(input_contract, dict):
        input_contract = {}
        issues.append("input contract must be an object")
    if input_contract.get("text_length_range") != [MIN_TEXT_LENGTH, MAX_TEXT_LENGTH]:
        issues.append("text length bounds mismatch")
    if input_contract.get("operation_count_range") != [0, MAX_OPERATIONS]:
        issues.append("operation count bounds mismatch")
    if input_contract.get("maximum_valid_input_length") != MAX_VALID_INPUT_LENGTH:
        issues.append("maximum valid frame mismatch")
    if input_contract.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH:
        issues.append("maximum parseable frame mismatch")
    if input_contract.get("kind") != "signed_64_bit_integer_array":
        issues.append("input element kind mismatch")
    if input_contract.get("encoding") != "[N,Q,text_symbols...,(side,symbol)*Q]":
        issues.append("input encoding mismatch")
    if input_contract.get("exact_length") != "2 + N + 2*Q":
        issues.append("exact frame formula mismatch")
    if input_contract.get("invalid_input_result") != -1:
        issues.append("invalid-input result mismatch")
    output_contract = workload.get("output")
    if (not isinstance(output_contract, dict)
            or output_contract.get("kind") != "signed_64_bit_scalar"
            or output_contract.get("maximum_valid_result") != 45760
            or output_contract.get("valid_result_range") != [0, 45760]
            or output_contract.get("invalid_input_result") != -1):
        issues.append("output checksum bound mismatch")

    cases = workload.get("cases")
    if not isinstance(cases, list):
        return issues + ["workload cases must be a list"]
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload contains a non-object case")
            continue
        values = case.get("input_values")
        case_id = case.get("id", "<unnamed>")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"fixture frame length mismatch: {case_id}")
            continue
        if len(values) > MAX_PARSEABLE_INPUT_LENGTH:
            issues.append(f"fixture exceeds parseable bound: {case_id}")
        args = {
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        expected = case.get("expected_result")
        if primary_result(values, **args) != expected:
            issues.append(f"primary oracle mismatch: {case_id}")
        if independent_result(values, **args) != expected:
            issues.append(f"independent oracle mismatch: {case_id}")

    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif ALGORITHM not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol in {language} port")
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")

    readme_path = PACKAGE / "README.md"
    if readme_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        if SOURCE_URL not in readme:
            issues.append("README missing primary source attribution")
        if "does not implement mismatch enumeration" not in readme:
            issues.append("README missing bounded exact-search scope")
        for language in PORTS:
            if f"](../../../{language}/b/{ALGORITHM}." not in readme:
                issues.append(f"README missing {language} port link")
        for target in re.findall(r"\[[^\]]+\]\(([^)]+)\)", readme):
            if "://" in target or target.startswith("mailto:"):
                continue
            local = unquote(target.split("#", 1)[0])
            if local and not (readme_path.parent / local).resolve().is_file():
                issues.append(f"README link target is missing: {target}")

    elisa_path = PORTS["elisa"]
    if elisa_path.is_file():
        elisa = elisa_path.read_text(encoding="utf-8")
        if "input: view[i64]" not in elisa or "input: i64&" not in elisa:
            issues.append("Elisa must use a view internally and a ref only at the ABI boundary")
    return issues


if __name__ == "__main__":
    problems = verify()
    if problems:
        raise SystemExit("\n".join(problems))
