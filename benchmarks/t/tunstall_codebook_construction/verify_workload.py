"""Static package inventory for bounded Tunstall codebook construction."""

import json
from pathlib import Path

from . import independent_oracle, primary_oracle

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
LANGUAGE_FILES = {
    "c": "c/t/tunstall_codebook_construction.c",
    "c3": "c3/t/tunstall_codebook_construction.c3",
    "cpp": "cpp/t/tunstall_codebook_construction.cpp",
    "elisa": "elisa/t/tunstall_codebook_construction.elisa",
    "mojo": "mojo/t/tunstall_codebook_construction.mojo",
    "nim": "nim/t/tunstall_codebook_construction.nim",
    "odin": "odin/t/tunstall_codebook_construction.odin",
    "rust": "rust/t/tunstall_codebook_construction.rs",
    "v": "v/t/tunstall_codebook_construction.v",
    "zig": "zig/t/tunstall_codebook_construction.zig",
}


def verify(workload=None):
    issues = []
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return ["workload must be an object"]
    if workload.get("function_symbol") != "tunstall_codebook_construction":
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
    case_ids = set()
    for case in cases:
        if not isinstance(case, dict):
            issues.append("fixture must be an object")
            continue
        case_id = case.get("id")
        case_ids.add(case_id)
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"{case_id}: input_length does not match input_values")
            continue
        is_null = case.get("input_is_null", False)
        expected = case.get("expected_result")
        if expected != primary_oracle.expected_result(values, is_null, len(values)):
            issues.append(f"{case_id}: primary oracle mismatch")
        if expected != independent_oracle.expected_result(values, is_null, len(values)):
            issues.append(f"{case_id}: independent oracle mismatch")
    for required in ("maximum_leaf_frame", "maximum_trailing_word", "null_input"):
        if required not in case_ids:
            issues.append(f"missing fixture: {required}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for relative in LANGUAGE_FILES.values():
        target = ROOT / relative
        if not target.is_file():
            issues.append(f"missing language file: {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"missing README link: {relative}")
        if target.is_file() and "tunstall_codebook_construction" not in target.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {relative}")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if "Tunstall" not in rights or "Tunstall" not in readme:
        issues.append("missing source attribution")
    return issues


if __name__ == "__main__":
    problems = verify()
    if problems:
        raise ValueError("; ".join(problems))
