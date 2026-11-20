"""Fraction-based direct interval and EDF reference for AVR."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence
from fractions import Fraction

MAX_JOBS = 8
MAX_TIME = 8
MAX_WORK = 8
MAX_INPUT_LENGTH = 1 + 3 * MAX_JOBS
MAX_SEGMENTS = 2 * MAX_JOBS - 1
MAX_OUTPUT_VALUES = 3 + 4 * MAX_SEGMENTS + 2 * MAX_JOBS
MAX_OUTPUT = 8 * MAX_OUTPUT_VALUES
DENSITY_SCALE = 840


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
    endpoints = sorted({time for release, deadline, _ in jobs
                        for time in (release, deadline)})
    remaining = [Fraction(work) for _, _, work in jobs]
    completions: list[Fraction | None] = [None] * len(jobs)
    energy = Fraction(0)
    segments: list[list[int]] = []

    for start, end in zip(endpoints, endpoints[1:]):
        active_jobs = [index for index, (release, deadline, _) in enumerate(jobs)
                       if release <= start and end <= deadline]
        speed = sum((Fraction(jobs[index][2],
                              jobs[index][1] - jobs[index][0])
                     for index in active_jobs), Fraction(0))
        if speed == 0:
            continue
        energy += speed ** 3 * (end - start)
        if (segments and segments[-1][1] == start
                and Fraction(segments[-1][2], segments[-1][3]) == speed):
            segments[-1][1] = end
        else:
            segments.append([start, end, speed.numerator, speed.denominator])

        now = Fraction(start)
        while now < end:
            ready = [index for index, (release, deadline, _) in enumerate(jobs)
                     if release <= start < deadline and remaining[index] > 0]
            if not ready:
                break
            job = min(ready, key=lambda item: (jobs[item][1], item))
            finish = now + remaining[job] / speed
            if finish <= end:
                now = finish
                remaining[job] = Fraction(0)
                completions[job] = finish
            else:
                remaining[job] -= speed * (end - now)
                now = Fraction(end)

    result = [len(segments), energy.numerator, energy.denominator]
    for segment in segments:
        result.extend(segment)
    for finish in completions:
        if finish is None:
            raise ValueError("AVR/EDF failed to complete a valid job")
        result.extend((finish.numerator, finish.denominator))
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
    payload = b"".join(struct.pack("<q", value) for value in _solve(jobs))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
