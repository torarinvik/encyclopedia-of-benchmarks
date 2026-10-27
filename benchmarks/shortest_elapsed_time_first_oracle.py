"""Bounded SETF oracle using a ready-job scan at every unit boundary."""

from __future__ import annotations

from collections.abc import Sequence

MAX_JOBS = 8
MAX_INPUT_LENGTH = 18
MAX_OUTPUT_BYTES = 112


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n = values[0]
    if not 0 <= n <= MAX_JOBS or len(values) != 1 + 2 * n:
        return None
    jobs = []
    for index in range(n):
        release, size = values[1 + 2 * index:3 + 2 * index]
        if not 0 <= release <= 16 or not 1 <= size <= 12:
            return None
        jobs.append((release, size))
    return jobs


def _schedule(jobs: list[tuple[int, int]]) -> bytes:
    count = len(jobs)
    attained = [0] * count
    remaining = [size for _, size in jobs]
    completed = 0
    time = 0
    trace = bytearray()
    while completed < count:
        chosen = -1
        for job, (release, _) in enumerate(jobs):
            if release <= time and remaining[job] > 0 and (
                    chosen < 0 or (attained[job], job) < (attained[chosen], chosen)):
                chosen = job
        if chosen < 0:
            trace.append(0)
        else:
            trace.append(chosen + 1)
            attained[chosen] += 1
            remaining[chosen] -= 1
            if remaining[chosen] == 0:
                completed += 1
        time += 1
    return bytes(trace)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    jobs = _decode(values)
    if jobs is None:
        return -1, b""
    payload = _schedule(jobs)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
