"""Static package metadata, fixture, reference, and port validator; not run."""

from __future__ import annotations

import json
import re
from pathlib import Path

try:
    from .independent_oracle import expected_result as independent_result
    from .primary_oracle import expected_result as primary_result
except ImportError:
    from independent_oracle import expected_result as independent_result
    from primary_oracle import expected_result as primary_result

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
MODULUS = 998_244_353
INDEX_URL = (
    "https://github.com/acmeism/RosettaCodeData/blob/"
    "1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks"
)
BROFOS_URL = "https://arxiv.org/abs/1406.2212"

PORTS = {
    "c": "c/p/penney_game_pattern_probability.c",
    "c3": "c3/p/penney_game_pattern_probability.c3",
    "cpp": "cpp/p/penney_game_pattern_probability.cpp",
    "elisa": "elisa/p/penney_game_pattern_probability.elisa",
    "mojo": "mojo/p/penney_game_pattern_probability.mojo",
    "nim": "nim/p/penney_game_pattern_probability.nim",
    "odin": "odin/p/penney_game_pattern_probability.odin",
    "rust": "rust/p/penney_game_pattern_probability.rs",
    "v": "v/p/penney_game_pattern_probability.v",
    "zig": "zig/p/penney_game_pattern_probability.zig",
}

NULL_GUARDS = {
    "c": "input == NULL",
    "c3": "input == null",
    "cpp": "input == nullptr",
    "elisa": "input.is_null()",
    "mojo": "UnsafePointer[Int64, ImmutAnyOrigin]()",
    "nim": "input.isNil",
    "odin": "input == nil",
    "rust": "input.is_null()",
    "v": "input == nil",
    "zig": "input == null",
}

REQUIRED_CASE_RESULTS = {
    "length-one-fair-odds": 499_122_177,
    "00-before-10": 249_561_089,
    "10-before-00": 748_683_265,
    "complementary-length-four": 499_122_177,
    "equal-patterns-invalid": -1,
    "length-zero-invalid": -1,
    "length-above-bound": -1,
    "mask-out-of-range": -1,
    "negative-mask": -1,
    "missing-mask": -1,
    "trailing-value": -1,
    "null-input": -1,
}


def workload_issues(workload: dict | None = None) -> list[str]:
    issues: list[str] = []
    if workload is None:
        try:
            data = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload: {error}"]
    else:
        data = workload
    if not isinstance(data, dict):
        return ["workload root must be a JSON object"]

    if data.get("schema_version") != 1:
        issues.append("workload schema version differs")
    if (data.get("id") != "penney-game-pattern-first-hit-probability-i64-array-scalar-v1"
            or data.get("algorithm") != "penney_game_pattern_probability"
            or data.get("function_symbol") != "penney_game_pattern_probability"
            or data.get("abi") != "i64_array_scalar"):
        issues.append("workload identity or ABI differs")

    source = data.get("source", {})
    if not isinstance(source, dict):
        source = {}
    if (source.get("discovery_title") != "Penneys-game"
            or source.get("discovery_score") != 49
            or source.get("discovery_index") != INDEX_URL):
        issues.append("Rosetta title, score, or pinned index provenance differs")
    discovery_note = source.get("discovery_note", "")
    if not isinstance(discovery_note, str):
        discovery_note = ""
    discovery_note = discovery_note.lower()
    if "title" not in discovery_note or "only" not in discovery_note:
        issues.append("discovery note must say the index was used for title-only discovery")
    if source.get("method_source") != "Brofos, A Markov Chain Analysis of a Pattern Matching Coin Game, arXiv:1406.2212":
        issues.append("primary method attribution differs")
    if source.get("method_urls") != [BROFOS_URL]:
        issues.append("method reference URL differs")
    if source.get("implementation_status") != "clean-room bounded profile":
        issues.append("implementation status is not marked as clean-room")

    input_meta = data.get("input", {})
    if not isinstance(input_meta, dict):
        input_meta = {}
    if (input_meta.get("word_length_range") != [1, 4]
            or input_meta.get("patterns_must_differ") is not True
            or input_meta.get("mask_range") != "0 <= mask < 2^L"
            or input_meta.get("kind") != "signed_64_bit_integer_array"
            or input_meta.get("exact_length") != 3
            or input_meta.get("maximum_valid_length") != 3
            or input_meta.get("maximum_parseable_length") != 4
            or input_meta.get("invalid_input_result") != -1
            or input_meta.get("null_input_result") != -1):
        issues.append("workload input contract differs")
    output_meta = data.get("output", {})
    if not isinstance(output_meta, dict):
        output_meta = {}
    if (output_meta.get("kind") != "signed_64_bit_integer"
            or output_meta.get("modulus") != MODULUS
            or output_meta.get("valid_result_range") != [0, MODULUS - 1]
            or output_meta.get("invalid_input_result") != -1):
        issues.append("workload output contract differs")
    workspace = data.get("workspace", {})
    if not isinstance(workspace, dict):
        workspace = {}
    if workspace.get("primary_states_maximum") != 7:
        issues.append("primary state bound differs")
    if workspace.get("independent_states_maximum") != 15:
        issues.append("independent state bound differs")

    cases = data.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases are missing"]
    seen: set[str] = set()
    actual_results: dict[str, int] = {}
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("fixture is not a named object")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate fixture id: {case_id}")
            continue
        seen.add(case_id)

        values = case.get("input_values")
        length = case.get("input_length")
        is_null = case.get("input_is_null", False)
        expected = case.get("expected_result")
        if (not isinstance(values, list)
                or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                       for value in values)
                or type(length) is not int
                or type(is_null) is not bool
                or type(expected) is not int):
            issues.append(f"invalid fixture fields: {case_id}")
            continue
        if length < 0 or length > 4:
            issues.append(f"fixture length outside parseable frame bound: {case_id}")
        if is_null:
            if values or length != 0:
                issues.append(f"null frame must have no values and zero length: {case_id}")
        elif length != len(values):
            issues.append(f"frame length mismatch: {case_id}")

        kwargs = {"input_is_null": is_null, "input_length": length}
        primary = primary_result(values, **kwargs)
        independent = independent_result(values, **kwargs)
        if primary != independent:
            issues.append(f"primary and independent references disagree: {case_id}")
        if primary != expected or independent != expected:
            issues.append(f"fixture result differs from a reference: {case_id}")
        actual_results[case_id] = expected

    for case_id, expected in REQUIRED_CASE_RESULTS.items():
        if actual_results.get(case_id) != expected:
            issues.append(f"required fixture missing or expected result differs: {case_id}")
    return issues


def artifact_issues() -> list[str]:
    issues: list[str] = []
    required_artifacts = (
        "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
        "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    )
    for name in required_artifacts:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")

    try:
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
        inventory = (PACKAGE / "INVENTORY.md").read_text(encoding="utf-8")
    except OSError as error:
        return issues + [f"cannot read package documentation: {error}"]

    for document_name, document in (("README.md", readme), ("RIGHTS.md", rights)):
        for url in (INDEX_URL, BROFOS_URL):
            if url not in document:
                issues.append(f"{document_name} is missing provenance URL: {url}")
        if "score of 49" not in document.lower():
            issues.append(f"{document_name} is missing the title-index score")
        if "no rosetta task" not in document.lower():
            issues.append(f"{document_name} is missing the clean-room boundary")

    for language, relative_path in PORTS.items():
        path = ROOT / relative_path
        if not path.is_file():
            issues.append(f"missing {language} port: {relative_path}")
            continue
        text = path.read_text(encoding="utf-8")
        if "penney_game_pattern_probability" not in text:
            issues.append(f"exported symbol text missing from {relative_path}")
        if NULL_GUARDS[language] not in text:
            issues.append(f"null guard missing from {relative_path}")
        if not re.search(r"length\s*!=\s*(?:3|csize_t\(3\))", text):
            issues.append(f"exact three-value frame check missing from {relative_path}")
        readme_link = f"](../../../{relative_path})"
        if readme_link not in readme:
            issues.append(f"README language link missing for {language}")
        if relative_path not in inventory:
            issues.append(f"inventory language path missing for {language}")
    return issues


def workload_issues_all(workload: dict | None = None) -> list[str]:
    return workload_issues(workload) + artifact_issues()


def verify_workload(workload: dict | None = None) -> list[str]:
    return workload_issues_all(workload)


if __name__ == "__main__":
    issues = verify_workload()
    if issues:
        raise ValueError("\n".join(issues))
