"""Fraction-based independent BKP endpoint reference for the sample profile."""
from __future__ import annotations

from collections.abc import Sequence
from fractions import Fraction
from math import gcd

MAX_JOBS = 4
MAX_SAMPLES = 8
MAX_TIME = 8
MAX_WORK = 8
E = Fraction(271_828, 100_000)
MAX_PARSEABLE_INPUT_LENGTH = 2 + 3 * MAX_JOBS + 2 * MAX_SAMPLES + 1


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63)
                   for x in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    count, sample_count = values[0], values[1]
    if not 1 <= count <= MAX_JOBS or not 1 <= sample_count <= MAX_SAMPLES:
        return None
    if len(values) != 2 + 3 * count + 2 * sample_count:
        return None
    jobs = [tuple(values[2 + 3 * j:5 + 3 * j]) for j in range(count)]
    if any(not (0 <= r < d <= MAX_TIME and 1 <= w <= MAX_WORK)
           for r, d, w in jobs):
        return None
    sample_start = 2 + 3 * count
    samples = [tuple(values[i:i + 2]) for i in range(sample_start, len(values), 2)]
    for time, active in samples:
        if not 0 <= time <= MAX_TIME or not 0 <= active < (1 << count):
            return None
        if any(active & (1 << j) and jobs[j][0] > time for j in range(count)):
            return None
    return jobs, samples


def _fraction_speed(jobs, time: int, active: int) -> Fraction:
    if active == 0:
        return Fraction(0, 1)
    critical_times = set()
    for release, deadline, _ in jobs:
        if release <= time and deadline > time:
            critical_times.add(Fraction(deadline))
        if release < time:
            critical_times.add((E * time - release) / (E - 1))
    maximum = Fraction(0, 1)
    for endpoint in critical_times:
        if endpoint <= time:
            continue
        left_boundary = E * time - (E - 1) * endpoint
        contained = sum(work for release, deadline, work in jobs
                        if release <= time and left_boundary <= release and deadline <= endpoint)
        maximum = max(maximum, Fraction(contained, 1) / (endpoint - time))
    return maximum


def expected_values(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> list[int] | int:
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return -1
    jobs, samples = parsed
    answer = [len(samples)]
    for time, active in samples:
        value = _fraction_speed(jobs, time, active)
        answer.extend((value.numerator, value.denominator))
    return answer
