"""Static workload/reference reconciliation; intentionally not executed."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
from typing import Any

PACKAGE = Path(__file__).resolve().parent
EXPECTED_IDS = {
    "four-documents-first-occurrence-order", "single-suffix-rank",
    "one-document-with-repeated-occurrences", "maximum-valid-frame-and-output",
    "maximum-parseable-trailing-word", "document-id-out-of-range",
    "interval-out-of-range", "truncated-query", "null-input",
    "undersized-output", "null-output",
}


def _load(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(f"_mdl_{name}", path)
    if spec is None or spec.loader is None:
        raise ImportError(f"cannot load oracle at {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def workload_issues(workload: dict[str, Any] | None = None) -> list[str]:
    errors: list[str] = []
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"invalid workload: {error}"]
    if not isinstance(workload, dict):
        return ["workload must be an object"]
    primary = _load("primary", PACKAGE / "primary_oracle.py")
    independent = _load("independent", PACKAGE / "independent_oracle.py")
    if workload.get("algorithm") != "muthukrishnan_document_listing" or \
            workload.get("function_symbol") != "muthukrishnan_document_listing" or \
            workload.get("abi") != "i64_array_bytes_output":
        errors.append("algorithm name, function symbol, or ABI differs from the contract")
    if workload.get("input", {}).get("maximum_valid_length") != primary.MAX_VALID_INPUT_LENGTH or \
            workload.get("input", {}).get("maximum_parseable_length") != primary.MAX_PARSEABLE_INPUT_LENGTH or \
            workload.get("output", {}).get("maximum_bytes") != primary.MAX_OUTPUT_BYTES or \
            workload.get("workspace", {}).get("bytes") != primary.WORKSPACE_BYTES:
        errors.append("workload input/output/workspace metadata differs from reference bounds")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return errors + ["cases must be a nonempty list"]
    ids = [case.get("id") for case in cases if isinstance(case, dict)]
    if len(ids) != len(cases) or len(set(ids)) != len(ids) or set(ids) != EXPECTED_IDS:
        errors.append("fixture identifiers differ from the pinned fixture set")
    for case in cases:
        name = case.get("id", "<unnamed>") if isinstance(case, dict) else "<non-object>"
        if not isinstance(case, dict) or not isinstance(case.get("input_values"), list):
            errors.append(f"{name}: fixture must contain input_values")
            continue
        values = case["input_values"]
        length = case.get("input_length")
        input_null = case.get("input_is_null", False)
        output_null = case.get("output_is_null", False)
        capacity = case.get("output_capacity")
        if type(length) is not int or type(input_null) is not bool or type(output_null) is not bool:
            errors.append(f"{name}: malformed ABI metadata")
            continue
        if input_null:
            if values or length != 3:
                errors.append(f"{name}: null input must use an empty frame and header length")
        elif len(values) != length:
            errors.append(f"{name}: input_length differs from the frame size")
        arguments = (values, capacity, output_null, input_null, length)
        primary_result = primary.expected_output(*arguments)
        independent_result = independent.expected_output(*arguments)
        if primary_result != independent_result:
            errors.append(f"{name}: independent references disagree")
        expected = (case.get("expected_result"), bytes.fromhex(case.get("expected_output_hex", "")))
        if primary_result != expected:
            errors.append(f"{name}: primary reference differs from pinned output")
        if primary_result[0] < 0 and primary_result[1]:
            errors.append(f"{name}: error case must leave output empty")
    by_id = {case.get("id"): case for case in cases if isinstance(case, dict)}
    if by_id.get("maximum-valid-frame-and-output", {}).get("input_length") != primary.MAX_VALID_INPUT_LENGTH:
        errors.append("maximum fixture does not pin the maximum valid frame")
    if by_id.get("maximum-valid-frame-and-output", {}).get("expected_result") != primary.MAX_OUTPUT_BYTES:
        errors.append("maximum fixture does not pin the output capacity bound")
    if by_id.get("maximum-parseable-trailing-word", {}).get("input_length") != primary.MAX_PARSEABLE_INPUT_LENGTH:
        errors.append("trailing-word fixture does not pin the parseable bound")
    return errors


def verify_workload() -> list[str]:
    return workload_issues()
