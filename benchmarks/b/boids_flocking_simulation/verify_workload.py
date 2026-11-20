"""Dual-reference agreement review for the pinned Boids workload."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from .check_inventory import inventory_errors
from .independent_reference import (
    expected_output as independent_expected_output,
)
from benchmarks.boids_flocking_simulation_oracle import (
    expected_output as primary_expected_output,
)


PACKAGE = Path(__file__).resolve().parent


def verify_workload() -> None:
    issues = inventory_errors()
    if issues:
        raise ValueError("Boids inventory is incomplete: " + "; ".join(issues))

    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    contract = workload.get("contract", {})
    if (
        input_spec.get("encoding") != "[N,steps,radius,max_speed,max_acceleration,(x,y,vx,vy)*N]"
        or input_spec.get("boid_count_range") != [1, 16]
        or input_spec.get("step_count_range") != [0, 16]
        or input_spec.get("neighborhood_radius_range") != [0, 128]
        or input_spec.get("maximum_speed_range") != [1, 32]
        or input_spec.get("maximum_acceleration_range") != [0, 8]
        or input_spec.get("maximum_valid_length") != 69
        or input_spec.get("maximum_parseable_length") != 70
        or output_spec.get("bytes_per_boid") != 16
        or output_spec.get("maximum_bytes") != 256
        or workload.get("workspace", {}).get("bytes") != 1280
        or "collision avoidance first" not in contract.get("acceleration_arbitration", "")
        or "All boids update synchronously" not in contract.get("profile", "")
    ):
        raise ValueError("Boids workload metadata differs from its frozen integer profile")

    cases = workload.get("cases", [])
    for case in cases:
        values = tuple(case.get("input_values", []))
        options: dict[str, Any] = {
            "output_capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        expected = (
            case.get("expected_result"),
            bytes.fromhex(case.get("expected_output_hex", "")),
        )
        primary = primary_expected_output(values, **options)
        independent = independent_expected_output(values, **options)
        if primary != independent or primary != expected:
            raise ValueError(f"Boids references or fixture differ: {case.get('id')}")

    by_id = {case.get("id"): case for case in cases}
    if (len(cases) != 12
            or by_id.get("maximum-boids-steps-and-output-bound", {}).get("expected_result") != 256
            or by_id.get("undersized-output-does-not-write", {}).get("expected_result") != -2
            or by_id.get("null-input", {}).get("expected_result") != -1):
        raise ValueError("Boids maximum-size or ABI error fixtures are missing")


if __name__ == "__main__":  # pragma: no cover - workload review entry point
    verify_workload()
