"""Static fixture and oracle review for the D* Lite workload."""

from __future__ import annotations

import json
from pathlib import Path

from d_star_lite_incremental_replanning_oracle import expected_result as primary_result
from d_star_lite_incremental_replanning_verifier_oracle import expected_result as independent_result

PACKAGE = Path(__file__).resolve().parent
MAX_VALID_INPUT_LENGTH = 198
MAX_PARSEABLE_INPUT_LENGTH = 199
MAX_RESULT_BOUND = 316_744


def _maximum_input() -> tuple[int, ...]:
    height = width = 4
    edges = []
    for source in range(height * width):
        row, column = divmod(source, width)
        for target in range(height * width):
            target_row, target_column = divmod(target, width)
            if abs(row - target_row) + abs(column - target_column) == 1:
                edges.extend((source, target, 1 + (source * 3 + target) % 9))
    updates = []
    for index in range(16):
        updates.extend(((index * 5) % 16, index % 48, 1 + (index * 7) % 9))
    return (height, width, 48, 16, 0, 15, *edges, *updates)


def verify_workload(workload: dict | None = None) -> None:
    if workload is None:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("algorithm") != "d_star_lite_incremental_replanning"
            or workload.get("function_symbol") != "d_star_lite_incremental_replanning"
            or workload.get("abi") != "i64_array_scalar"):
        raise ValueError("unexpected D* Lite workload identity")
    contract = workload.get("input", {})
    if (contract.get("encoding") != "[H,W,E,Q,start,goal,(u,v,c)*E,(new_start,edge_id,new_cost)*Q]"
            or contract.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or contract.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH):
        raise ValueError("D* Lite workload contract differs from its bounds")
    if workload.get("output", {}).get("maximum_result_bound") != MAX_RESULT_BOUND:
        raise ValueError("D* Lite checksum bound mismatch")
    for case in workload.get("cases", []):
        values = case.get("input_values")
        case_id = case.get("id", "<unnamed>")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            raise ValueError(f"fixture input length mismatch: {case_id}")
        arguments = {
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        expected = case.get("expected_result")
        if primary_result(values, **arguments) != expected:
            raise ValueError(f"D* Lite repair fixture mismatch: {case_id}")
        if independent_result(values, **arguments) != expected:
            raise ValueError(f"Floyd-Warshall fixture mismatch: {case_id}")

    maximum = _maximum_input()
    if len(maximum) != MAX_VALID_INPUT_LENGTH:
        raise ValueError("maximum D* Lite frame construction mismatch")
    primary = primary_result(maximum)
    independent = independent_result(maximum)
    if primary != independent or not 0 <= independent <= MAX_RESULT_BOUND:
        raise ValueError("maximum D* Lite frame differs between oracles or exceeds its bound")
    trailing = (*maximum, 0)
    if len(trailing) != MAX_PARSEABLE_INPUT_LENGTH:
        raise ValueError("maximum D* Lite trailing frame construction mismatch")
    if primary_result(trailing) != -1 or independent_result(trailing) != -1:
        raise ValueError("maximum D* Lite trailing word was accepted")


if __name__ == "__main__":
    verify_workload()
