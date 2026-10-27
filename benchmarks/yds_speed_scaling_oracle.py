"""Primary bounded YDS maximum-density interval decomposition oracle."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence

MAX_INPUT = 13
MAX_OUTPUT = 152


def _parse(values: Sequence[int] | None) -> list[dict[str, int]] | None:
    if values is None or not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n = values[0]
    if not 1 <= n <= 4 or len(values) != 1 + 3 * n:
        return None
    jobs: list[dict[str, int]] = []
    for job in range(n):
        release, deadline, work = values[1 + 3 * job:4 + 3 * job]
        if not 0 <= release < deadline <= 8 or not 1 <= work <= 8:
            return None
        jobs.append({"id": job, "r": release, "d": deadline, "w": work})
    return jobs


def _solve(source: list[dict[str, int]]) -> list[int]:
    jobs = [dict(job) for job in source]
    stages: list[list[int]] = []
    energy_num, energy_den = 0, 1
    while jobs:
        release_points = sorted({job["r"] for job in jobs})
        deadline_points = sorted({job["d"] for job in jobs})
        best: tuple[int, int, int, int] | None = None
        for left in release_points:
            for right in deadline_points:
                if left >= right:
                    continue
                total_work = sum(job["w"] for job in jobs if job["r"] >= left and job["d"] <= right)
                if total_work == 0:
                    continue
                duration = right - left
                if best is None:
                    best = (left, right, total_work, duration)
                    continue
                old_left, old_right, old_work, old_duration = best
                comparison = total_work * old_duration - old_work * duration
                if comparison > 0 or (comparison == 0 and (left, right) < (old_left, old_right)):
                    best = (left, right, total_work, duration)
        assert best is not None
        left, right, total_work, duration = best
        selected = [job for job in jobs if job["r"] >= left and job["d"] <= right]
        selected.sort(key=lambda job: (job["d"], job["id"]))
        job_mask = sum(1 << job["id"] for job in selected)
        stage = [left, right, total_work, job_mask]
        stages.append(stage)

        term_num, term_den = total_work ** 3, duration ** 2
        common = math.gcd(energy_den, term_den)
        energy_num = energy_num * (term_den // common) + term_num * (energy_den // common)
        energy_den *= term_den // common
        divisor = math.gcd(energy_num, energy_den)
        energy_num //= divisor
        energy_den //= divisor

        remaining = []
        for job in jobs:
            if job in selected:
                continue
            item = dict(job)
            for endpoint in ("r", "d"):
                time = item[endpoint]
                if time <= left:
                    pass
                elif time < right:
                    item[endpoint] = left
                else:
                    item[endpoint] = time - duration
            remaining.append(item)
        jobs = remaining
    flat = [len(stages), energy_num, energy_den]
    for stage in stages:
        flat.extend(stage)
    return flat


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
    jobs = _parse(values)
    if jobs is None:
        return -1, b""
    fields = _solve(jobs)
    payload = b"".join(struct.pack("<q", field) for field in fields)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
