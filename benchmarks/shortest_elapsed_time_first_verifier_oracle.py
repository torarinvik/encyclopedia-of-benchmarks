"""Independent SETF verifier using a heap of ready jobs."""

from __future__ import annotations

import heapq
from collections.abc import Sequence

MAX_JOBS = 8
MAX_INPUT_LENGTH = 18
MAX_OUTPUT_BYTES = 112


def _decode(values: Sequence[int] | None):
    if not isinstance(values, (list, tuple)) or len(values) < 1 or len(values) > MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    count = values[0]
    if count < 0 or count > MAX_JOBS or len(values) != 1 + 2 * count:
        return None
    jobs = []
    for j in range(count):
        release, work = values[1 + 2 * j:3 + 2 * j]
        if release < 0 or release > 16 or work < 1 or work > 12:
            return None
        jobs.append((release, work))
    return jobs


def _heap_schedule(jobs: list[tuple[int, int]]) -> bytes:
    remaining = [work for _, work in jobs]
    ready: list[tuple[int, int]] = []
    entered = [False] * len(jobs)
    trace = bytearray()
    time = 0
    completed = 0
    while completed < len(jobs):
        for job, (release, _) in enumerate(jobs):
            if not entered[job] and release <= time:
                heapq.heappush(ready, (0, job))
                entered[job] = True
        if not ready:
            trace.append(0)
            time += 1
            continue
        service, job = heapq.heappop(ready)
        trace.append(job + 1)
        remaining[job] -= 1
        time += 1
        if remaining[job] == 0:
            completed += 1
        else:
            heapq.heappush(ready, (service + 1, job))
    return bytes(trace)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    invalid, output_error = -1, -2
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return invalid, b""
    if input_is_null or values is None:
        return invalid, b""
    jobs = _decode(values)
    if jobs is None:
        return invalid, b""
    payload = _heap_schedule(jobs)
    if output_is_null or capacity is not None and capacity < len(payload):
        return output_error, b""
    return len(payload), payload
