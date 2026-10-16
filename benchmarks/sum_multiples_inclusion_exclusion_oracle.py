"""Direct-scan oracle for the formula-based Project Euler 1 benchmark."""

from __future__ import annotations

from functools import lru_cache

MAX_LIMIT = 100_000


@lru_cache(maxsize=1)
def _direct_scan_prefix() -> tuple[int, ...]:
    prefix = [0] * (MAX_LIMIT + 1)
    total = 0
    for value in range(1, MAX_LIMIT + 1):
        if value % 3 == 0 or value % 5 == 0:
            total += value
        prefix[value] = total
    return tuple(prefix)


def expected_result(limit: int) -> int:
    if not 1 <= limit <= MAX_LIMIT:
        return -1
    return _direct_scan_prefix()[limit - 1]
