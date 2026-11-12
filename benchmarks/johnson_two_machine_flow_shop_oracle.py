"""Primary Johnson-rule oracle for two-machine flow-shop makespan."""

from __future__ import annotations

from collections.abc import Sequence

MAX_JOBS = 8
MAX_TIME = 1_000
MAX_INPUT_LENGTH = 1 + 2 * MAX_JOBS
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1


def _parse(values: Sequence[int] | None) -> list[tuple[int, int]] | None:
    if not isinstance(values, (list, tuple)) or not values:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    count = values[0]
    if not 1 <= count <= MAX_JOBS or len(values) != 1 + 2 * count:
        return None
    jobs = [(values[1 + 2 * i], values[2 + 2 * i]) for i in range(count)]
    if any(not 0 <= first <= MAX_TIME or not 0 <= second <= MAX_TIME for first, second in jobs):
        return None
    return jobs


def _makespan(jobs: Sequence[tuple[int, int]], order: Sequence[int]) -> int:
    first_finish = 0
    second_finish = 0
    for job_id in order:
        first, second = jobs[job_id]
        first_finish += first
        second_finish = max(second_finish, first_finish) + second
    return second_finish


def expected_result(values: Sequence[int] | None) -> int:
    jobs = _parse(values)
    if jobs is None:
        return -1

    early = [i for i, (first, second) in enumerate(jobs) if first < second]
    late = [i for i, (first, second) in enumerate(jobs) if first >= second]
    early.sort(key=lambda i: (jobs[i][0], i))
    late.sort(key=lambda i: (-jobs[i][1], i))
    return _makespan(jobs, early + late)
