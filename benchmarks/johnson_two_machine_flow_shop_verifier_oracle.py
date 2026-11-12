"""Independent exhaustive schedule oracle for small two-machine instances."""

from __future__ import annotations

from collections.abc import Sequence
from itertools import permutations

MAX_JOBS = 8
MAX_TIME = 1_000


def expected_result(values: Sequence[int] | None) -> int:
    if not isinstance(values, (list, tuple)) or not values:
        return -1
    if any(type(value) is not int or value < -(1 << 63) or value >= (1 << 63) for value in values):
        return -1
    count = values[0]
    if not 1 <= count <= MAX_JOBS or len(values) != 1 + 2 * count:
        return -1
    first = values[1::2]
    second = values[2::2]
    if any(value < 0 or value > MAX_TIME for value in first + second):
        return -1

    best: int | None = None
    for order in permutations(range(count)):
        time_first = 0
        time_second = 0
        for job_id in order:
            time_first += first[job_id]
            time_second = max(time_second, time_first) + second[job_id]
        if best is None or time_second < best:
            best = time_second
    return 0 if best is None else best
