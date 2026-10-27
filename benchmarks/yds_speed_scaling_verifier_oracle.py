"""Independent bounded YDS verifier using Fraction comparisons and LCM energy."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence
from fractions import Fraction

MAX_INPUT = 13


def _read(values: Sequence[int] | None) -> list[dict[str, int]] | None:
    if values is None or not isinstance(values, (list, tuple)):
        return None
    if not 2 <= len(values) <= MAX_INPUT or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values):
        return None
    count = values[0]
    if count not in range(1, 5) or len(values) != 1 + 3 * count:
        return None
    jobs = []
    for ident in range(count):
        r, d, work = values[1 + 3 * ident:4 + 3 * ident]
        if r < 0 or d > 8 or r >= d or work < 1 or work > 8:
            return None
        jobs.append({"id": ident, "release": r, "deadline": d, "work": work})
    return jobs


def _derive(jobs_in: list[dict[str, int]]) -> list[int]:
    jobs = [dict(job) for job in jobs_in]
    stages: list[tuple[int, int, int, list[int]]] = []
    while jobs:
        release_set = {job["release"] for job in jobs}
        deadline_set = {job["deadline"] for job in jobs}
        candidates: list[tuple[Fraction, int, int, int]] = []
        for left in release_set:
            for right in deadline_set:
                if left >= right:
                    continue
                workload = sum(job["work"] for job in jobs
                               if job["release"] >= left and job["deadline"] <= right)
                if workload:
                    candidates.append((Fraction(workload, right - left), left, right, workload))
        # Density first, then the source-profile's deterministic earliest interval.
        density, left, right, workload = max(candidates, key=lambda item: (item[0], -item[1], -item[2]))
        chosen = [job for job in jobs
                  if job["release"] >= left and job["deadline"] <= right]
        chosen.sort(key=lambda job: (job["deadline"], job["id"]))
        stages.append((left, right, workload, [job["id"] for job in chosen]))

        duration = right - left
        chosen_ids = {job["id"] for job in chosen}
        remaining = []
        for job in jobs:
            if job["id"] in chosen_ids:
                continue
            revised = dict(job)
            for endpoint in ("release", "deadline"):
                t = revised[endpoint]
                if t <= left:
                    revised[endpoint] = t
                elif t < right:
                    revised[endpoint] = left
                else:
                    revised[endpoint] = t - duration
            remaining.append(revised)
        jobs = remaining

    energy_den = math.lcm(*( (right - left) ** 2 for left, right, _, _ in stages ))
    energy_num = sum(work ** 3 * (energy_den // ((right - left) ** 2))
                     for left, right, work, _ in stages)
    reduction = math.gcd(energy_num, energy_den)
    energy_num //= reduction
    energy_den //= reduction
    fields = [len(stages), energy_num, energy_den]
    for left, right, work, order in stages:
        duration = right - left
        job_mask = sum(1 << ident for ident in order)
        fields.extend([left, right, work, job_mask])
    return fields


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    jobs = _read(values)
    if jobs is None:
        return -1, b""
    payload = b"".join(struct.pack("<q", field) for field in _derive(jobs))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
