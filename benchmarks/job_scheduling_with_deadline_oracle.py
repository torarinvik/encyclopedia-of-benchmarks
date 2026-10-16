"""Independent oracle for the pinned arrival-time deadline scheduler."""

from __future__ import annotations

from collections.abc import Sequence

MAX_JOBS = 128
MAX_INPUT_LENGTH = 1 + 4 * MAX_JOBS
MAX_ID = 2_147_483_647
MAX_PROFIT = 1_000_000
PACK_BASE = 1 << 32
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: Sequence[int]) -> int:
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT
    count = values[0]
    if not 0 <= count <= MAX_JOBS or len(values) != 1 + 4 * count:
        return INVALID_RESULT

    jobs: list[tuple[int, int, int, int]] = []
    ids: set[int] = set()
    for index in range(count):
        base = 1 + 4 * index
        job_id, arrival, deadline, profit = values[base:base + 4]
        if (not 0 <= job_id <= MAX_ID or not 1 <= arrival <= 32
                or not 1 <= deadline <= 32 or not -MAX_PROFIT <= profit <= MAX_PROFIT
                or job_id in ids):
            return INVALID_RESULT
        ids.add(job_id)
        jobs.append((job_id, arrival, deadline, profit))

    max_deadline = max((job[2] for job in jobs), default=0)
    occupied_slots: set[int] = set()
    scheduled = 0
    total_profit = 0

    # Python's sort is stable, so equal-profit jobs keep their input order.
    for _, arrival, deadline, profit in sorted(jobs, key=lambda job: -job[3]):
        if arrival > deadline:
            continue
        last_slot = min(deadline - 1, max_deadline - 1)
        for slot in range(last_slot, arrival - 2, -1):
            if slot not in occupied_slots:
                occupied_slots.add(slot)
                scheduled += 1
                total_profit += profit
                break

    low_word = total_profit & 0xFFFF_FFFF
    return (scheduled << 32) | low_word
