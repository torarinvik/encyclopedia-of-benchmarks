"""Independent subset enumeration oracle for deadline-feasible job count."""

from __future__ import annotations

from collections.abc import Sequence

MAX_JOBS = 12
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_JOBS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_DEADLINE = 1000
MAX_DURATION = 1000


def expected_result(values: Sequence[int] | None) -> int:
    if not isinstance(values, (list, tuple)) or not values:
        return -1
    if any(type(value) is not int or value < -(1 << 63) or value >= (1 << 63) for value in values):
        return -1
    count = values[0]
    if not 0 <= count <= MAX_JOBS or len(values) != 1 + 2 * count:
        return -1
    jobs: list[tuple[int, int]] = []
    for job in range(count):
        deadline = values[1 + 2 * job]
        duration = values[2 + 2 * job]
        if not 0 <= deadline <= MAX_DEADLINE or not 1 <= duration <= MAX_DURATION:
            return -1
        jobs.append((deadline, duration))

    best = 0
    for subset in range(1 << count):
        selected = [job for job in range(count) if subset & (1 << job)]
        if len(selected) <= best:
            continue
        selected.sort(key=lambda job: (jobs[job][0], job))
        finish = 0
        feasible = True
        for job in selected:
            deadline, duration = jobs[job]
            finish += duration
            if finish > deadline:
                feasible = False
                break
        if feasible:
            best = len(selected)
    return best
