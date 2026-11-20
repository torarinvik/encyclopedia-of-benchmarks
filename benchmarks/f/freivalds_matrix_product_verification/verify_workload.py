"""Callable static inventory for the bounded Freivalds replay package."""
from __future__ import annotations

import json
import re
from pathlib import Path

from .independent_oracle import expected_result as independent
from .primary_oracle import (
    MAX_N, MAX_ROUNDS, MAX_PARSEABLE_INPUT_LENGTH, MAX_VALID_INPUT_LENGTH,
    expected_result as primary,
)

PACKAGE = Path(__file__).resolve().parent
REPO_ROOT = Path(__file__).resolve().parents[3]
NAME = "freivalds_matrix_product_verification"
LANGUAGES = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED_CASES = {
    "correct_one_by_one", "wrong_one_by_one", "false_acceptance_tape",
    "same_error_detected", "multiple_rounds_detect", "signed_correct_product",
    "invalid_dimension", "invalid_round_count", "invalid_matrix_entry",
    "invalid_sign", "trailing_word", "null_input", "maximum_dimension_and_rounds",
}


def static_issues(workload: object | None = None) -> list[str]:
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, ValueError) as error:
            return [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return ["workload must be an object"]
    issues: list[str] = []
    input_meta, output_meta, source = (workload.get("input"), workload.get("output"),
                                       workload.get("source"))
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != NAME
            or workload.get("function_symbol") != NAME
            or workload.get("abi") != "i64_array_scalar"
            or not isinstance(input_meta, dict)
            or input_meta.get("encoding") != "[n,k,A[n*n],B[n*n],C[n*n],sign_vectors[k*n]]"
            or input_meta.get("dimension_range") != [1, MAX_N]
            or input_meta.get("round_range") != [1, MAX_ROUNDS]
            or input_meta.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_meta.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or input_meta.get("matrix_entry_range") != [-3, 3]
            or input_meta.get("sign_vector_entry_values") != [-1, 1]
            or not isinstance(output_meta, dict)
            or output_meta.get("kind") != "signed_64_bit_scalar"
            or output_meta.get("valid_result_range") != [0, 1]):
        issues.append("identity, bounds, or output contract mismatch")
    if (not isinstance(source, dict)
            or source.get("doi") != "10.1007/3-540-09526-8_5"
            or source.get("author") != "Rūsiņš Freivalds"
            or "supplied sign vectors" not in source.get("implementation_status", "")):
        issues.append("source attribution mismatch")

    for language, extension in LANGUAGES.items():
        path = REPO_ROOT / language / "f" / f"{NAME}.{extension}"
        if not path.is_file():
            issues.append(f"missing language port: {language}")
        elif NAME not in path.read_text(encoding="utf-8"):
            issues.append(f"exported symbol missing from: {language}")
    for filename in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                     "independent_oracle.py"):
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package artifact: {filename}")

    readme_path = PACKAGE / "README.md"
    if readme_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        for language, extension in LANGUAGES.items():
            target = f"../../../{language}/f/{NAME}.{extension}"
            if f"]({target})" not in readme:
                issues.append(f"README port target missing: {language}")
        for target in re.findall(r"\]\(([^)]+)\)", readme):
            if target.startswith(("http://", "https://", "#")):
                continue
            if not (PACKAGE / target).resolve().is_file():
                issues.append(f"README local target does not resolve: {target}")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["fixture cases are missing"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("malformed fixture record")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate fixture id: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        input_is_null = case.get("input_is_null", False)
        if (not isinstance(values, list)
                or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                       for value in values)
                or type(length) is not int or not 0 <= length <= MAX_PARSEABLE_INPUT_LENGTH
                or type(input_is_null) is not bool
                or (input_is_null and values)
                or (not input_is_null and length != len(values))):
            issues.append(f"invalid fixture framing: {case_id}")
            continue
        expected = case.get("expected_result")
        args = (values, input_is_null, length)
        if type(expected) is not int or primary(*args) != expected or independent(*args) != expected:
            issues.append(f"oracle/fixture disagreement: {case_id}")
    if seen != REQUIRED_CASES:
        issues.append("fixture inventory mismatch")
    return issues


def verify(workload: object | None = None) -> bool:
    issues = static_issues(workload)
    if issues:
        raise ValueError("; ".join(issues))
    return True


if __name__ == "__main__":
    verify()
