"""Exact bounded Average Rate (AVR) speed-profile and EDF oracle."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence

MAX_JOBS = 8
MAX_TIME = 8
MAX_WORK = 8
MAX_INPUT_LENGTH = 1 + 3 * MAX_JOBS
MAX_SEGMENTS = 2 * MAX_JOBS - 1
MAX_OUTPUT_VALUES = 3 + 4 * MAX_SEGMENTS + 2 * MAX_JOBS
MAX_OUTPUT = 8 * MAX_OUTPUT_VALUES
DENSITY_SCALE = 840  # lcm(1, ..., MAX_TIME)
MAX_SPEED_SCALED = MAX_JOBS * MAX_WORK * DENSITY_SCALE
MAX_ENERGY_NUMERATOR_UPPER_BOUND = MAX_TIME * MAX_SPEED_SCALED ** 3


def _parse(values: Sequence[int] | None) -> list[tuple[int, int, int]] | None:
    if (not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    count = values[0]
    if not 1 <= count <= MAX_JOBS or len(values) != 1 + 3 * count:
        return None
    jobs: list[tuple[int, int, int]] = []
    for index in range(count):
        release, deadline, work = values[1 + 3 * index:4 + 3 * index]
        if (not 0 <= release < deadline <= MAX_TIME
                or not 1 <= work <= MAX_WORK):
            return None
        jobs.append((release, deadline, work))
    return jobs


def _solve(jobs: list[tuple[int, int, int]]) -> list[int]:
    changes = [0] * (MAX_TIME + 1)
    points: set[int] = set()
    remaining = [work * DENSITY_SCALE for _, _, work in jobs]
    completion: list[tuple[int, int] | None] = [None] * len(jobs)
    for release, deadline, work in jobs:
        scaled_density = work * (DENSITY_SCALE // (deadline - release))
        changes[release] += scaled_density
        changes[deadline] -= scaled_density
        points.add(release)
        points.add(deadline)

    speed_scaled = 0
    energy_scaled = 0
    segments: list[list[int]] = []
    times = sorted(points)
    for index in range(len(times) - 1):
        start = times[index]
        end = times[index + 1]
        speed_scaled += changes[start]
        if speed_scaled <= 0 or start == end:
            continue

        energy_scaled += speed_scaled ** 3 * (end - start)
        divisor = math.gcd(speed_scaled, DENSITY_SCALE)
        speed_num = speed_scaled // divisor
        speed_den = DENSITY_SCALE // divisor
        if (segments and segments[-1][1] == start
                and segments[-1][2:] == [speed_num, speed_den]):
            segments[-1][1] = end
        else:
            segments.append([start, end, speed_num, speed_den])

        cursor_scaled = start * speed_scaled
        end_scaled = end * speed_scaled
        while cursor_scaled < end_scaled:
            active = [job for job, (release, deadline, _) in enumerate(jobs)
                      if release <= start < deadline and remaining[job] > 0]
            if not active:
                break
            job = min(active, key=lambda item: (jobs[item][1], item))
            work_needed_scaled = remaining[job]
            if cursor_scaled + work_needed_scaled <= end_scaled:
                cursor_scaled += work_needed_scaled
                remaining[job] = 0
                divisor = math.gcd(cursor_scaled, speed_scaled)
                completion[job] = (cursor_scaled // divisor,
                                   speed_scaled // divisor)
            else:
                remaining[job] -= end_scaled - cursor_scaled
                cursor_scaled = end_scaled

    energy_denominator = DENSITY_SCALE ** 3
    divisor = math.gcd(energy_scaled, energy_denominator)
    energy_num = energy_scaled // divisor
    energy_den = energy_denominator // divisor
    result = [len(segments), energy_num, energy_den]
    for segment in segments:
        result.extend(segment)
    for finish in completion:
        if finish is None:
            raise ValueError("AVR/EDF failed to complete a valid job")
        result.extend(finish)
    return result


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (
                type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
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
