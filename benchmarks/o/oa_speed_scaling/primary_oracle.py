"""Exact bounded Optimal Available speed-scaling reference."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence
from fractions import Fraction

MAX_JOBS = 2
MAX_TIME = 4
MAX_WORK = 4
MAX_VALID_INPUT_LENGTH = 1 + 3 * MAX_JOBS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_SEGMENTS = 3
MAX_OUTPUT_VALUES = 3 + 4 * MAX_SEGMENTS + 2 * MAX_JOBS
MAX_OUTPUT = 8 * MAX_OUTPUT_VALUES


def _parse(values: Sequence[int] | None) -> list[tuple[int, int, int]] | None:
    if (not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
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


def _append_segment(segments: list[list[int]], start: int, end: int,
                    speed: Fraction) -> None:
    if end <= start or speed <= 0:
        return
    if (segments and segments[-1][1] == start
            and Fraction(segments[-1][2], segments[-1][3]) == speed):
        segments[-1][1] = end
    else:
        segments.append([start, end, speed.numerator, speed.denominator])


def _yds_plan(now: int, remaining: list[Fraction],
              jobs: list[tuple[int, int, int]]) -> list[tuple[int, int, Fraction, tuple[int, ...]]]:
    """Build common-release critical intervals, resolving ties by earliest end."""
    ids = [i for i, rem in enumerate(remaining) if rem > 0 and jobs[i][1] > now]
    ids.sort(key=lambda i: (jobs[i][1], i))
    plan: list[tuple[int, int, Fraction, tuple[int, ...]]] = []
    left = now
    while ids:
        prefix_work = Fraction(0)
        best_density: Fraction | None = None
        best_count = 0
        for count, job_id in enumerate(ids, 1):
            prefix_work += remaining[job_id]
            density = prefix_work / (jobs[job_id][1] - left)
            if best_density is None or density > best_density:
                best_density = density
                best_count = count
            # Equal density keeps the earlier (shorter) critical interval.
        if best_density is None or best_count == 0:
            break
        group = tuple(ids[:best_count])
        right = jobs[group[-1]][1]
        plan.append((left, right, best_density, group))
        ids = ids[best_count:]
        left = right
    return plan


def _solve(jobs: list[tuple[int, int, int]]) -> list[int]:
    remaining = [Fraction(0) for _ in jobs]
    completions: list[Fraction | None] = [None] * len(jobs)
    segments: list[list[int]] = []
    energy = Fraction(0)
    releases = sorted({job[0] for job in jobs})

    for event_index, now in enumerate(releases):
        for job_id, (release, _, work) in enumerate(jobs):
            if release == now:
                remaining[job_id] = Fraction(work)
        next_release = releases[event_index + 1] if event_index + 1 < len(releases) else None
        plan = _yds_plan(now, remaining, jobs)
        for start, end, speed, group in plan:
            run_end = end if next_release is None else min(end, next_release)
            if run_end <= start:
                break
            _append_segment(segments, start, run_end, speed)
            energy += speed ** 3 * (run_end - start)
            cursor = Fraction(start)
            for job_id in group:
                if remaining[job_id] <= 0:
                    continue
                duration = remaining[job_id] / speed
                finish = cursor + duration
                if finish <= run_end:
                    cursor = finish
                    completions[job_id] = finish
                    remaining[job_id] = Fraction(0)
                else:
                    remaining[job_id] -= speed * (Fraction(run_end) - cursor)
                    cursor = Fraction(run_end)
                    break
            if run_end < end:
                break

    if any(finish is None for finish in completions):
        raise ValueError("OA/YDS failed to complete a valid job")
    result = [len(segments), energy.numerator, energy.denominator]
    for segment in segments:
        result.extend(segment)
    for finish in completions:
        assert finish is not None
        result.extend((finish.numerator, finish.denominator))
    return result


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (
                type(input_length) is not int
                or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    jobs = _parse(values)
    if jobs is None:
        return -1, b""
    payload = b"".join(struct.pack("<q", field) for field in _solve(jobs))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
