"""Compare both references with pinned workload and buffer-behavior cases.

This verifier is a package artifact. It has not been run during source-only
work.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Callable

try:
    from .independent_oracle import expected_output as independent_output
    from .primary_oracle import expected_output as primary_output
except ImportError:
    from independent_oracle import expected_output as independent_output
    from primary_oracle import expected_output as primary_output

PACKAGE = Path(__file__).resolve().parent
Oracle = Callable[..., tuple[int, bytes]]
ORACLES: tuple[tuple[str, Oracle], ...] = (
    ("primary free-list oracle", primary_output),
    ("independent interval oracle", independent_output),
)


def _call(oracle: Oracle, values: list[int], input_length: int | None,
          capacity: int | None = None, output_is_null: bool = False,
          input_is_null: bool = False) -> tuple[int, bytes]:
    return oracle(
        values,
        capacity=capacity,
        output_is_null=output_is_null,
        input_is_null=input_is_null,
        input_length=input_length,
    )


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
        capacity = case.get("output_capacity")
        output_is_null = case.get("output_is_null", False)
        input_is_null = case.get("input_is_null", False)
        try:
            pinned_bytes = bytes.fromhex(case.get("expected_output_hex", ""))
        except (TypeError, ValueError):
            issues.append(f"{case_id}: expected_output_hex is malformed")
            continue

        pinned = (case.get("expected_result"), pinned_bytes)
        observed: dict[str, tuple[int, bytes]] = {}
        for label, oracle in ORACLES:
            actual = _call(
                oracle,
                values,
                input_length,
                capacity=capacity,
                output_is_null=output_is_null,
                input_is_null=input_is_null,
            )
            observed[label] = actual
            if actual != pinned:
                issues.append(f"{case_id}: {label} differs from the pinned result/output")
        if len(observed) == len(ORACLES) and len(set(observed.values())) != 1:
            issues.append(f"{case_id}: the two references disagree")

        # Recompute valid calls without buffer restrictions, then pin exact,
        # one-byte-short, and null-output behavior against both references.
        baselines = {
            label: _call(oracle, values, input_length, input_is_null=input_is_null)
            for label, oracle in ORACLES
        }
        if len(set(baselines.values())) != 1:
            issues.append(f"{case_id}: unrestricted reference outputs disagree")
            continue
        baseline_result, payload = next(iter(baselines.values()))
        if baseline_result < 0:
            if baseline_result == -1:
                for label, oracle in ORACLES:
                    restricted = _call(
                        oracle,
                        values,
                        input_length,
                        capacity=0,
                        output_is_null=True,
                        input_is_null=input_is_null,
                    )
                    if restricted != (-1, b""):
                        issues.append(f"{case_id}: {label} gives buffer errors precedence over invalid input")
            continue

        exact = len(payload)
        for label, oracle in ORACLES:
            exact_result = _call(oracle, values, input_length, capacity=exact)
            if exact_result != (exact, payload):
                issues.append(f"{case_id}: {label} rejects exact output capacity")
            short_result = _call(oracle, values, input_length, capacity=exact - 1)
            if short_result != (-2, b""):
                issues.append(f"{case_id}: {label} accepts one-byte-short capacity or writes on error")
            null_result = _call(oracle, values, input_length, capacity=exact, output_is_null=True)
            if null_result != (-2, b""):
                issues.append(f"{case_id}: {label} does not reject a null output buffer")
    return issues


def main() -> int:
    issues = workload_issues()
    if issues:
        for issue in issues:
            print(issue)
        return 1
    print("buddy_system_allocator workload and oracle references agree")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
