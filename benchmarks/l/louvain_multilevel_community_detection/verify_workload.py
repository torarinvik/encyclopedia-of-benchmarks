"""Static fixture and reference agreement for bounded Louvain semantics."""

from __future__ import annotations

import json
from pathlib import Path

from louvain_multilevel_community_detection_oracle import expected_result as primary_result
from louvain_multilevel_community_detection_verifier_oracle import expected_result as independent_result

PACKAGE = Path(__file__).resolve().parent
MAX_VALID_INPUT_LENGTH = 86
MAX_PARSEABLE_INPUT_LENGTH = 87


def verify_workload(workload: dict | None = None) -> None:
    if workload is None:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("algorithm") != "louvain_multilevel_community_detection"
            or workload.get("function_symbol") != "louvain_multilevel_community_detection"
            or workload.get("abi") != "i64_array_scalar"):
        raise ValueError("unexpected Louvain workload identity")
    contract = workload.get("input", {})
    if (contract.get("encoding") != "[n,m,(u,v,w)*m]"
            or contract.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or contract.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH):
        raise ValueError("Louvain workload differs from its input bounds")
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
            raise ValueError(f"Louvain quotient-matrix fixture mismatch: {case_id}")
        if independent_result(values, **arguments) != expected:
            raise ValueError(f"Louvain original-graph fixture mismatch: {case_id}")

    maximum = (8, 28, *(value for u in range(8) for v in range(u + 1, 8) for value in (u, v, 7)))
    if len(maximum) != MAX_VALID_INPUT_LENGTH:
        raise ValueError("maximum Louvain frame construction mismatch")
    if primary_result(maximum) != 16_777_216 or independent_result(maximum) != 16_777_216:
        raise ValueError("maximum complete-graph checksum mismatch")
    if (primary_result((*maximum, 0)) != -1
            or independent_result((*maximum, 0)) != -1):
        raise ValueError("maximum parseable trailing word was accepted")


if __name__ == "__main__":
    verify_workload()
