"""Heap merge of monotone positive-cube-sum rows for bounded Taxicab values."""

from __future__ import annotations

import heapq

MAX_ROOT = 444
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
WORKSPACE_BYTES = 8_192


def taxicab_number_minimum_representations(
        values: list[int] | tuple[int, ...] | None,
        input_is_null: bool = False,
        input_length: int | None = None) -> int:
    """Return Taxicab(k) for k=2 or 3; malformed inputs return -1."""
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))
            or len(values) != MAX_VALID_INPUT_LENGTH):
        return -1
    ways = values[0]
    if type(ways) is not int or not -(1 << 63) <= ways < (1 << 63) or ways not in (2, 3):
        return -1

    # Row a contains a^3+b^3 for b=a..MAX_ROOT and is strictly increasing.
    heap: list[tuple[int, int, int]] = []
    for a in range(1, MAX_ROOT + 1):
        cube = a * a * a
        heapq.heappush(heap, (2 * cube, a, a))

    while heap:
        total, a, b = heapq.heappop(heap)
        equal_pairs = [(a, b)]
        while heap and heap[0][0] == total:
            _, same_a, same_b = heapq.heappop(heap)
            equal_pairs.append((same_a, same_b))
        for row_a, row_b in equal_pairs:
            if row_b < MAX_ROOT:
                next_b = row_b + 1
                heapq.heappush(
                    heap,
                    (row_a * row_a * row_a + next_b * next_b * next_b,
                     row_a, next_b),
                )
        if len(equal_pairs) >= ways:
            return total
    return -1
