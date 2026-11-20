"""Static source, inventory, and workload framing review; not a benchmark runner."""

from __future__ import annotations

import json
from pathlib import Path


PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
ALGORITHM = "minimum_cost_bipartite_edge_cover_subset_dp"
ABI = "i64_array_scalar"
PORTS = {
    "c": "c/m/minimum_cost_bipartite_edge_cover_subset_dp.c",
    "c3": "c3/m/minimum_cost_bipartite_edge_cover_subset_dp.c3",
    "cpp": "cpp/m/minimum_cost_bipartite_edge_cover_subset_dp.cpp",
    "elisa": "elisa/m/minimum_cost_bipartite_edge_cover_subset_dp.elisa",
    "mojo": "mojo/m/minimum_cost_bipartite_edge_cover_subset_dp.mojo",
    "nim": "nim/m/minimum_cost_bipartite_edge_cover_subset_dp.nim",
    "odin": "odin/m/minimum_cost_bipartite_edge_cover_subset_dp.odin",
    "rust": "rust/m/minimum_cost_bipartite_edge_cover_subset_dp.rs",
    "v": "v/m/minimum_cost_bipartite_edge_cover_subset_dp.v",
    "zig": "zig/m/minimum_cost_bipartite_edge_cover_subset_dp.zig",
}
REFERENCES = ("primary_oracle.py", "independent_oracle.py")
METADATA = ("README.md", "RIGHTS.md", "workload.json", "INVENTORY.json", "check_inventory.py")
MAX_VALID_LENGTH = 66
MAX_PARSEABLE_LENGTH = 67
MAX_RESULT = 8000
WORKSPACE_BYTES = 8192


def _json(path: Path, issues: list[str], label: str) -> dict:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        issues.append(f"cannot read {label}: {error}")
        return {}
    if not isinstance(value, dict):
        issues.append(f"{label} must be a JSON object")
        return {}
    return value


def _valid_frame(values: list[int]) -> bool:
    if (not isinstance(values, list) or len(values) < 2
            or any(type(value) is not int for value in values)):
        return False
    left, right = values[:2]
    if not 1 <= left <= 8 or not 1 <= right <= 8 or len(values) != 2 + left * right:
        return False
    return all(0 <= cost <= 1000 for cost in values[2:])


def static_issues() -> list[str]:
    """Return static metadata, source-path, and workload-frame problems."""
    issues: list[str] = []
    inventory = _json(PACKAGE / "INVENTORY.json", issues, "INVENTORY.json")
    workload = _json(PACKAGE / "workload.json", issues, "workload.json")

    if inventory.get("algorithm") != ALGORITHM:
        issues.append("inventory algorithm ID mismatch")
    if inventory.get("function_symbol") != ALGORITHM:
        issues.append("inventory function symbol mismatch")
    if inventory.get("abi") != ABI:
        issues.append("inventory ABI mismatch")
    if inventory.get("languages") != PORTS:
        issues.append("inventory ten-language source map mismatch")
    if inventory.get("references") != list(REFERENCES):
        issues.append("inventory reference list mismatch")
    if inventory.get("metadata") != list(METADATA):
        issues.append("inventory metadata list mismatch")
    if inventory.get("static_checker") != "check_inventory.py":
        issues.append("inventory static-checker path mismatch")

    contract = inventory.get("contract", {})
    if not isinstance(contract, dict):
        issues.append("inventory contract must be an object")
        contract = {}
    for key, expected in (
        ("maximum_valid_input_values", MAX_VALID_LENGTH),
        ("maximum_parseable_input_values", MAX_PARSEABLE_LENGTH),
        ("maximum_output_bytes", 0),
        ("workspace_bytes", WORKSPACE_BYTES),
        ("maximum_left_vertices", 8),
        ("maximum_right_vertices", 8),
        ("maximum_edge_cost", 1000),
        ("maximum_result", MAX_RESULT),
    ):
        if contract.get(key) != expected:
            issues.append(f"inventory contract field mismatch: {key}")

    for language, relative in PORTS.items():
        source = ROOT / relative
        if not source.is_file():
            issues.append(f"missing {language} source: {relative}")
            continue
        try:
            source_text = source.read_text(encoding="utf-8")
        except OSError as error:
            issues.append(f"cannot read {language} source {relative}: {error}")
            continue
        if ALGORITHM not in source_text:
            issues.append(f"export symbol missing from {language} source: {relative}")

    for reference in REFERENCES:
        path = PACKAGE / reference
        if not path.is_file():
            issues.append(f"missing reference: {reference}")
            continue
        try:
            reference_text = path.read_text(encoding="utf-8")
        except OSError as error:
            issues.append(f"cannot read reference {reference}: {error}")
            continue
        if "WORKSPACE_BYTES = 8192" not in reference_text:
            issues.append(f"workspace constant missing in {reference}")

    for artifact in METADATA:
        if not (PACKAGE / artifact).is_file():
            issues.append(f"missing package artifact: {artifact}")

    if workload.get("algorithm") != ALGORITHM or workload.get("function_symbol") != ALGORITHM:
        issues.append("workload identity mismatch")
    if workload.get("abi") != ABI:
        issues.append("workload ABI mismatch")
    input_meta = workload.get("input", {})
    output_meta = workload.get("output", {})
    workspace_meta = workload.get("workspace", {})
    for name, value in (("input", input_meta), ("output", output_meta), ("workspace", workspace_meta)):
        if not isinstance(value, dict):
            issues.append(f"workload {name} metadata must be an object")
    if not isinstance(input_meta, dict):
        input_meta = {}
    if not isinstance(output_meta, dict):
        output_meta = {}
    if not isinstance(workspace_meta, dict):
        workspace_meta = {}
    if input_meta.get("maximum_valid_length") != MAX_VALID_LENGTH:
        issues.append("workload valid input bound mismatch")
    if input_meta.get("maximum_parseable_length") != MAX_PARSEABLE_LENGTH:
        issues.append("workload parseable input bound mismatch")
    if output_meta.get("kind") != "signed_i64_scalar" or output_meta.get("result_range") != [-1, MAX_RESULT]:
        issues.append("workload scalar output metadata mismatch")
    if workspace_meta.get("bytes") != WORKSPACE_BYTES:
        issues.append("workload workspace bound mismatch")

    readme_path = PACKAGE / "README.md"
    if readme_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        for language, relative in PORTS.items():
            if f"](../../../{relative})" not in readme:
                issues.append(f"README link missing for {language}")
        if "8,192 bytes" not in readme:
            issues.append("README workspace bound missing")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        issues.append("workload must have a nonempty case list")
        return issues
    for case in cases:
        case_id = case.get("id", "<unnamed>") if isinstance(case, dict) else "<non-object>"
        if not isinstance(case, dict):
            issues.append(f"fixture is not an object: {case_id}")
            continue
        values = case.get("input_values")
        length = case.get("input_length")
        is_null = case.get("input_is_null", False)
        result = case.get("expected_result")
        if not isinstance(values, list) or type(length) is not int:
            issues.append(f"invalid input frame metadata: {case_id}")
            continue
        if type(is_null) is not bool:
            issues.append(f"input null flag is not Boolean: {case_id}")
        if length != len(values):
            issues.append(f"input buffer/length mismatch: {case_id}")
        if length < 0 or length > MAX_PARSEABLE_LENGTH:
            issues.append(f"input length exceeds parseable bound: {case_id}")
        if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
            issues.append(f"fixture contains a non-i64 input word: {case_id}")
        if is_null and (length != 0 or values):
            issues.append(f"null input has a nonempty frame: {case_id}")
        if type(result) is not int:
            issues.append(f"expected scalar result is not an integer: {case_id}")
            continue
        if is_null or not _valid_frame(values):
            if result != -1:
                issues.append(f"malformed/null fixture must return -1: {case_id}")
        elif not 0 <= result <= MAX_RESULT:
            issues.append(f"valid fixture result is outside the documented range: {case_id}")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
