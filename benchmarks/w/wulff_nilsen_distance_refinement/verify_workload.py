"""Static workload/reference reconciler; do not invoke during a quiet edit pass."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / "benchmarks"))

from wulff_nilsen_distance_refinement_oracle import (  # noqa: E402
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    MAX_WORKSPACE_BYTES,
    expected_result as primary_result,
)
from wulff_nilsen_distance_refinement_independent_oracle import (  # noqa: E402
    expected_result as independent_result,
)


def workload_issues():
    data = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    issues = []
    if data.get("algorithm") != "wulff_nilsen_distance_refinement":
        issues.append("workload algorithm ID mismatch")
    if data.get("input", {}).get("maximum_valid_input_length") != MAX_VALID_INPUT_LENGTH:
        issues.append("maximum valid input length mismatch")
    if data.get("input", {}).get("maximum_parseable_input_length") != MAX_PARSEABLE_INPUT_LENGTH:
        issues.append("maximum parseable input length mismatch")
    if data.get("workspace", {}).get("bytes") != MAX_WORKSPACE_BYTES:
        issues.append("workspace cap mismatch")
    for case in data.get("cases", []):
        values = case.get("input_values", [])
        declared = case.get("input_length")
        is_null = case.get("input_is_null", False)
        if not is_null and declared != len(values):
            issues.append(f"{case.get('id')}: input_length differs from fixture word count")
            continue
        primary = primary_result(values, input_is_null=is_null, input_length=declared)
        independent = independent_result(values, input_is_null=is_null, input_length=declared)
        expected = case.get("expected_result")
        if primary != expected:
            issues.append(f"{case.get('id')}: primary expected {expected}, got {primary}")
        if independent != expected:
            issues.append(f"{case.get('id')}: independent expected {expected}, got {independent}")
    return issues


if __name__ == "__main__":
    problems = workload_issues()
    if problems:
        raise SystemExit("\n".join(problems))
    print("workload references agree")
