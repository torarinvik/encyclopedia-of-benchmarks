"""Primary reverse-deadline min-heap oracle for maximum feasible job count."""

from __future__ import annotations

from collections.abc import Sequence
from heapq import heappop, heappush

MAX_JOBS = 12
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_JOBS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_DEADLINE = 1000
MAX_DURATION = 1000


def _parse(values: Sequence[int] | None) -> list[tuple[int, int]] | None:
    if not isinstance(values, (list, tuple)) or not values:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    count = values[0]
    if not 0 <= count <= MAX_JOBS or len(values) != 1 + 2 * count:
        return None
    jobs = [(values[1 + 2 * i], values[2 + 2 * i]) for i in range(count)]
    if any(not 0 <= deadline <= MAX_DEADLINE or not 1 <= duration <= MAX_DURATION
           for deadline, duration in jobs):
        return None
    return jobs


def expected_result(values: Sequence[int] | None) -> int:
    jobs = _parse(values)
    if jobs is None:
        return -1
    order = sorted(range(len(jobs)), key=lambda i: (jobs[i][0], i))
    available: list[tuple[int, int]] = []
    completed = 0
    for position in range(len(order) - 1, -1, -1):
        job_id = order[position]
        deadline, duration = jobs[job_id]
        heappush(available, (duration, job_id))
        lower_deadline = jobs[order[position - 1]][0] if position else 0
        interval = deadline - lower_deadline
        while interval > 0 and available:
            remaining, selected = heappop(available)
            if remaining <= interval:
                interval -= remaining
                completed += 1
            else:
                heappush(available, (remaining - interval, selected))
                interval = 0
    return completed
