"""Oracle for the bounded arrival-time greedy job scheduler."""

from collections.abc import Sequence

MAX_JOBS = 64
MAX_INPUT_LENGTH = 1 + 3 * MAX_JOBS
MAX_TIME = 64
MAX_PROFIT = 1_000_000
BASE = 64_000_001
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: Sequence[int]) -> int:
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT
    job_count = values[0]
    if not 0 <= job_count <= MAX_JOBS or len(values) != 1 + 3 * job_count:
        return INVALID_RESULT

    jobs: list[tuple[int, int, int, int]] = []
    for index in range(job_count):
        arrival = values[1 + 3 * index]
        deadline = values[2 + 3 * index]
        profit = values[3 + 3 * index]
        if (not 1 <= arrival <= MAX_TIME or not 1 <= deadline <= MAX_TIME
                or not 0 <= profit <= MAX_PROFIT):
            return INVALID_RESULT
        jobs.append((arrival, deadline, profit))

    max_deadline = max((job[1] for job in jobs), default=0)
    slots = [False] * (max_deadline + 1)
    scheduled = 0
    total_profit = 0
    for arrival, deadline, profit in sorted(jobs, key=lambda job: job[2], reverse=True):
        if arrival <= deadline:
            for slot in range(min(deadline, max_deadline), arrival - 1, -1):
                if not slots[slot]:
                    slots[slot] = True
                    scheduled += 1
                    total_profit += profit
                    break
    return scheduled * BASE + total_profit
