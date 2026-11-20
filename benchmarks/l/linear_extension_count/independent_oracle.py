"""Recursive minimal-element reference with component interleaving."""

from __future__ import annotations

from collections.abc import Sequence
from functools import lru_cache
from math import factorial

MAX_N = 12
MAX_PARSEABLE_INPUT_LENGTH = 14
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, tuple[int, ...]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    n = values[0]
    if not 0 <= n <= MAX_N or input_length != n + 1:
        return None
    full = (1 << n) - 1
    prerequisites = tuple(values[1:])
    if any(mask < 0 or mask & ~full for mask in prerequisites):
        return None
    return n, prerequisites


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, prerequisites = parsed
    full = (1 << n) - 1
    adjacency = [0] * n
    for vertex, mask in enumerate(prerequisites):
        for prior in range(n):
            if mask & (1 << prior):
                adjacency[vertex] |= 1 << prior
                adjacency[prior] |= 1 << vertex

    @lru_cache(maxsize=None)
    def count_remaining(remaining: int) -> int:
        if remaining == 0:
            return 1

        components: list[int] = []
        unseen = remaining
        while unseen:
            seed_bit = unseen & -unseen
            component = 0
            frontier = seed_bit
            unseen ^= seed_bit
            while frontier:
                bit = frontier & -frontier
                frontier ^= bit
                vertex = bit.bit_length() - 1
                neighbors = adjacency[vertex] & unseen
                component |= bit
                unseen ^= neighbors
                frontier |= neighbors
            components.append(component)

        if len(components) > 1:
            interleavings = factorial(remaining.bit_count())
            for component in components:
                size = component.bit_count()
                interleavings //= factorial(size)
            ways = interleavings
            for component in components:
                ways *= count_remaining(component)
            return ways

        total = 0
        candidates = remaining
        while candidates:
            bit = candidates & -candidates
            candidates ^= bit
            vertex = bit.bit_length() - 1
            if prerequisites[vertex] & remaining == 0:
                total += count_remaining(remaining ^ bit)
        return total

    return count_remaining(full)


def verify_candidate(values: Sequence[int] | None, result: int,
                     input_is_null: bool = False,
                     input_length: int | None = None) -> bool:
    return (type(result) is int
            and result == expected_result(values, input_is_null, input_length))
