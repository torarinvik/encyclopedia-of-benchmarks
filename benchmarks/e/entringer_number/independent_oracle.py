"""Permutation-count references independent of the triangle recurrence."""

from __future__ import annotations

from itertools import permutations

MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3


def entringer_number_independent(values: list[int]) -> int:
    """List-input wrapper matching the scalar ABI's malformed-frame result."""
    if len(values) != MAX_VALID_INPUT_LENGTH:
        return -1
    n, first = values
    return entringer_subset_dp(n, first)


def entringer_subset_dp(n: int, first: int) -> int:
    """Count down-up permutations with a fixed first value by subset states."""
    if not (0 <= n <= 12 and 0 <= first <= n):
        return -1
    size = n + 1
    full = (1 << size) - 1
    start_mask = 1 << first
    ways = [[0] * size for _ in range(1 << size)]
    ways[start_mask][first] = 1
    for mask in range(1 << size):
        if not (mask & start_mask) or mask == full:
            continue
        used_count = mask.bit_count()
        next_is_lower = used_count % 2 == 1
        for last in range(size):
            count = ways[mask][last]
            if count == 0:
                continue
            for nxt in range(size):
                bit = 1 << nxt
                if mask & bit:
                    continue
                if (next_is_lower and last > nxt) or (not next_is_lower and last < nxt):
                    ways[mask | bit][nxt] += count
    return sum(ways[full])


def entringer_direct_enumeration(n: int, first: int) -> int:
    """Literal permutation enumeration for independent tiny checks."""
    if not (0 <= n <= 7 and 0 <= first <= n):
        raise ValueError("direct enumeration is limited to n <= 7")
    tail = [value for value in range(n + 1) if value != first]
    total = 0
    for suffix in permutations(tail):
        permutation = (first,) + suffix
        if all((permutation[i] > permutation[i + 1]) if i % 2 == 0
               else (permutation[i] < permutation[i + 1])
               for i in range(n)):
            total += 1
    return total
