"""Static fixture/oracle review for the bounded FM profile."""

from __future__ import annotations

import json
from pathlib import Path

from fiduccia_mattheyses_hypergraph_bipartitioning_oracle import expected_result as primary_result
from fiduccia_mattheyses_hypergraph_bipartitioning_verifier_oracle import expected_result as independent_result

PACKAGE = Path(__file__).resolve().parent
MAX_VALID_INPUT_LENGTH = 111
MAX_PARSEABLE_INPUT_LENGTH = 112


def verify_workload(workload: dict | None = None) -> None:
    if workload is None:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("algorithm") != "fiduccia_mattheyses_hypergraph_bipartitioning"
            or workload.get("function_symbol") != "fiduccia_mattheyses_hypergraph_bipartitioning"
            or workload.get("abi") != "i64_array_scalar"):
        raise ValueError("unexpected FM workload identity")
    contract = workload.get("input", {})
    if (contract.get("encoding") != "[n,m,initial_mask,(degree,sorted_vertex_ids...)*m]"
            or contract.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or contract.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH):
        raise ValueError("FM workload contract differs from its bounds")
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
            raise ValueError(f"FM gain-rescoring fixture mismatch: {case_id}")
        if independent_result(values, **arguments) != expected:
            raise ValueError(f"FM cut-recount fixture mismatch: {case_id}")

    maximum = (8, 12, 15, *(value for _ in range(12) for value in (8, *range(8))))
    if len(maximum) != MAX_VALID_INPUT_LENGTH:
        raise ValueError("maximum FM frame construction mismatch")
    if primary_result(maximum) != 3087 or independent_result(maximum) != 3087:
        raise ValueError("maximum repeated-full-net checksum mismatch")
    if (primary_result((*maximum, 0)) != -1
            or independent_result((*maximum, 0)) != -1):
        raise ValueError("maximum parseable trailing word was accepted")


if __name__ == "__main__":
    verify_workload()
