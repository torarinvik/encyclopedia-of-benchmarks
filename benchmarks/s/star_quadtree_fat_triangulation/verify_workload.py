"""Static workload/reference consistency functions for suite integration."""
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
    if workload.get("algorithm") != "star_quadtree_fat_triangulation":
        issues.append("workload algorithm name is inconsistent")
    for case in workload.get("cases", []):
        case_id = case.get("id", "<missing id>")
        try:
            expected = (case.get("expected_result"),
                        bytes.fromhex(case.get("expected_output_hex", "")))
        except (TypeError, ValueError):
            issues.append(f"{case_id}: malformed expected output hex")
            continue
        actuals = []
        for oracle in (primary_output, independent_output):
            actual = oracle(
                case.get("input_values", []),
                capacity=case.get("output_capacity"),
                output_is_null=case.get("output_is_null", False),
                input_is_null=case.get("input_is_null", False),
                input_length=case.get("input_length"),
            )
            actuals.append(actual)
            if actual != expected:
                issues.append(f"{case_id}: oracle result differs from pinned fixture")
        if len(set(actuals)) > 1:
            issues.append(f"{case_id}: independent references disagree")
        if "expected_output_values" in case and actuals[0][1]:
            expected_words = case["expected_output_values"]
            import struct
            pinned_words = [struct.unpack_from("<q", actuals[0][1], offset)[0]
                            for offset in range(0, len(actuals[0][1]), 8)]
            if pinned_words != expected_words:
                issues.append(f"{case_id}: expected output word list is inconsistent")
    return issues


def verify_workload() -> list[str]:
    return workload_issues()
