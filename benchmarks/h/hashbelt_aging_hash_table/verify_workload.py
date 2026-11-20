"""Static fixture/oracle verifier, provided for later use and not run here."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import expected_output as independent_output
    from .primary_oracle import expected_output as primary_output
except ImportError:
    from independent_oracle import expected_output as independent_output
    from primary_oracle import expected_output as primary_output

PACKAGE = Path(__file__).resolve().parent


def workload_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    for case in workload.get("cases", []):
        case_id = case.get("id", "<missing id>")
        values = case.get("input_values", [])
        input_length = case.get("input_length")
        result = case.get("expected_result")
        try:
            expected = bytes.fromhex(case.get("expected_output_hex", ""))
        except (TypeError, ValueError):
            issues.append(f"{case_id}: malformed expected-output bytes")
            continue
        options = {
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": input_length,
        }
        primary = primary_output(values, **options)
        alternate = independent_output(values, **options)
        if primary != alternate:
            issues.append(f"{case_id}: references disagree")
        if primary != (result, expected):
            issues.append(f"{case_id}: pinned output differs from references")

        baseline_options = {
            "input_is_null": case.get("input_is_null", False),
            "input_length": input_length,
        }
        baselines = (
            primary_output(values, **baseline_options),
            independent_output(values, **baseline_options),
        )
        if baselines[0] != baselines[1]:
            issues.append(f"{case_id}: unrestricted reference outputs disagree")
            continue
        baseline_result, payload = baselines[0]
        if baseline_result == -1:
            invalid = (
                primary_output(values, capacity=0, output_is_null=True, **baseline_options),
                independent_output(values, capacity=0, output_is_null=True, **baseline_options),
            )
            if invalid != ((-1, b""), (-1, b"")):
                issues.append(f"{case_id}: invalid-input errors do not precede output-buffer errors")
        elif baseline_result >= 0:
            exact = len(payload)
            exact_results = (
                primary_output(values, capacity=exact, **baseline_options),
                independent_output(values, capacity=exact, **baseline_options),
            )
            if exact_results != ((exact, payload), (exact, payload)):
                issues.append(f"{case_id}: exact output capacity is rejected")
            if exact > 0:
                short_results = (
                    primary_output(values, capacity=exact - 1, **baseline_options),
                    independent_output(values, capacity=exact - 1, **baseline_options),
                )
                if short_results != ((-2, b""), (-2, b"")):
                    issues.append(f"{case_id}: one-byte-short capacity is accepted or writes output")
            null_results = (
                primary_output(values, capacity=exact, output_is_null=True, **baseline_options),
                independent_output(values, capacity=exact, output_is_null=True, **baseline_options),
            )
            if null_results != ((-2, b""), (-2, b"")):
                issues.append(f"{case_id}: null output buffer is not rejected")
    return issues
