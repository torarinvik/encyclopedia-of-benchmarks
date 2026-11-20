"""Static inventory for the bounded LZ-End package; intentionally not run here."""

import json
from pathlib import Path

from . import independent_oracle, primary_oracle

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
LANGUAGE_FILES = {
    "c": "c/l/lz_end_phrase_parsing.c",
    "c3": "c3/l/lz_end_phrase_parsing.c3",
    "cpp": "cpp/l/lz_end_phrase_parsing.cpp",
    "elisa": "elisa/l/lz_end_phrase_parsing.elisa",
    "mojo": "mojo/l/lz_end_phrase_parsing.mojo",
    "nim": "nim/l/lz_end_phrase_parsing.nim",
    "odin": "odin/l/lz_end_phrase_parsing.odin",
    "rust": "rust/l/lz_end_phrase_parsing.rs",
    "v": "v/l/lz_end_phrase_parsing.v",
    "zig": "zig/l/lz_end_phrase_parsing.zig",
}


def verify(workload=None):
    issues = []
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload: {error}"]
    if workload.get("function_symbol") != "lz_end_phrase_parsing":
        issues.append("wrong function_symbol")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("wrong ABI")
    input_meta = workload.get("input", {})
    if input_meta.get("maximum_valid_input_length") != primary_oracle.MAX_VALID_INPUT_LENGTH:
        issues.append("wrong maximum valid input length")
    if input_meta.get("maximum_parseable_input_length") != primary_oracle.MAX_PARSEABLE_INPUT_LENGTH:
        issues.append("wrong maximum parseable input length")
    if workload.get("output", {}).get("maximum_result") != primary_oracle.MAX_RESULT:
        issues.append("wrong maximum result bound")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        issues.append("cases must be a nonempty list")
        cases = []
    for case in cases:
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"{case.get('id')}: input_length does not match input_values")
            continue
        is_null = case.get("input_is_null", False)
        expected = case.get("expected_result")
        if expected != primary_oracle.expected_result(values, is_null, len(values)):
            issues.append(f"{case.get('id')}: primary oracle mismatch")
        if expected != independent_oracle.expected_result(values, is_null, len(values)):
            issues.append(f"{case.get('id')}: independent oracle mismatch")
    case_ids = {case.get("id") for case in cases}
    for required in ("maximum_distinct_input", "maximum_trailing_word", "null_input"):
        if required not in case_ids:
            issues.append(f"missing fixture: {required}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for relative in LANGUAGE_FILES.values():
        target = ROOT / relative
        if not target.is_file():
            issues.append(f"missing language file: {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"missing README link: {relative}")
        if target.is_file() and "lz_end_phrase_parsing" not in target.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {relative}")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    for citation in ("10.1109/DCC.2010.29", "10.1016/j.tcs.2012.02.006"):
        if citation not in rights or citation not in readme:
            issues.append(f"missing source citation: {citation}")
    return issues


if __name__ == "__main__":
    problems = verify()
    if problems:
        raise ValueError("; ".join(problems))
