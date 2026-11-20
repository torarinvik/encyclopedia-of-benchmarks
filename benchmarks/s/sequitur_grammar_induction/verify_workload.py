"""Static inventory for the bounded Sequitur package; intentionally not run here."""

import json
from pathlib import Path

from . import independent_oracle, primary_oracle

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
LANGUAGE_FILES = {
    "c": "c/s/sequitur_grammar_induction.c",
    "c3": "c3/s/sequitur_grammar_induction.c3",
    "cpp": "cpp/s/sequitur_grammar_induction.cpp",
    "elisa": "elisa/s/sequitur_grammar_induction.elisa",
    "mojo": "mojo/s/sequitur_grammar_induction.mojo",
    "nim": "nim/s/sequitur_grammar_induction.nim",
    "odin": "odin/s/sequitur_grammar_induction.odin",
    "rust": "rust/s/sequitur_grammar_induction.rs",
    "v": "v/s/sequitur_grammar_induction.v",
    "zig": "zig/s/sequitur_grammar_induction.zig",
}


def verify(workload=None):
    issues = []
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload: {error}"]
    if workload.get("function_symbol") != "sequitur_grammar_induction":
        issues.append("wrong function_symbol")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("wrong ABI")
    input_meta = workload.get("input", {})
    if input_meta.get("maximum_valid_input_length") != primary_oracle.MAX_VALID_INPUT_LENGTH:
        issues.append("wrong maximum valid frame length")
    if input_meta.get("maximum_parseable_input_length") != primary_oracle.MAX_PARSEABLE_INPUT_LENGTH:
        issues.append("wrong maximum parseable frame length")
    output_meta = workload.get("output", {})
    if output_meta.get("maximum_result") != primary_oracle.MAX_RESULT:
        issues.append("wrong maximum result bound")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        issues.append("cases must be a nonempty list")
        cases = []
    for case in cases:
        values = case.get("input_values")
        length = case.get("input_length")
        is_null = case.get("input_is_null", False)
        if not isinstance(values, list) or length != len(values):
            issues.append(f"{case.get('id')}: input_length does not match input_values")
            continue
        expected = case.get("expected_result")
        primary = primary_oracle.expected_result(values, is_null, length)
        independent = independent_oracle.expected_result(values, is_null, length)
        if expected != primary or expected != independent:
            issues.append(f"{case.get('id')}: expected_result disagrees with references")
    case_ids = {case.get("id") for case in cases}
    for required in ("maximum_distinct_input", "maximum_trailing_word", "null_input"):
        if required not in case_ids:
            issues.append(f"missing required fixture: {required}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for relative in LANGUAGE_FILES.values():
        target = ROOT / relative
        if not target.is_file():
            issues.append(f"missing language file: {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"missing README link: {relative}")
        elif not target.exists():
            issues.append(f"unresolved README target: {relative}")
        elif "sequitur_grammar_induction" not in target.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {relative}")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if "NM-IHW-Hierarch97.pdf" not in rights or "NevMan-Thesis.pdf" not in rights:
        issues.append("source attribution links are incomplete")
    return issues


if __name__ == "__main__":
    problems = verify()
    if problems:
        raise ValueError("; ".join(problems))
