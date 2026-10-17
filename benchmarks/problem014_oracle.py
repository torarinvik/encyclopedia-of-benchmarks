"""Bounded reference for TheAlgorithms/JavaScript Project Euler Problem 014."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_LIMIT = 1_000_000
MAX_CHAIN_LENGTH = 10_000
MAX_SAFE_TERM = (1 << 53) - 1
MAX_SAFE_ODD = (MAX_SAFE_TERM - 1) // 3
INVALID_RESULT = -1


def _collatz_length(start: int) -> int | None:
    current = start
    length = 1
    while current != 1:
        if length >= MAX_CHAIN_LENGTH:
            return None
        if current % 2 == 0:
            current //= 2
        else:
            if current > MAX_SAFE_ODD:
                return None
            current = 3 * current + 1
        length += 1
    return length


def expected_output(limit: int) -> int:
    """Return the first start with the longest chain for starts below limit."""
    if type(limit) is not int or not I64_MIN <= limit <= I64_MAX:
        return INVALID_RESULT
    if not 1 <= limit <= MAX_LIMIT:
        return INVALID_RESULT

    best_start = 1
    best_length = 1
    for start in range(2, limit):
        length = _collatz_length(start)
        if length is None:
            return INVALID_RESULT
        if length > best_length:
            best_start = start
            best_length = length
    return best_start
