"""Permutation-scan reference using lattice-point visibility checks."""

from __future__ import annotations

from collections.abc import Sequence
from itertools import permutations
from math import gcd

from .primary_oracle import (
    INVALID_RESULT,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_PATTERN_LENGTH,
    MIN_PATTERN_LENGTH,
)


def _valid_pattern(pattern: tuple[int, ...]) -> bool:
    visited = {pattern[0]}
    for first, second in zip(pattern, pattern[1:]):
        first_x, first_y = first % 3, first // 3
        second_x, second_y = second % 3, second // 3
        delta_x, delta_y = second_x - first_x, second_y - first_y
        steps = gcd(abs(delta_x), abs(delta_y))
        for step in range(1, steps):
            point_x = first_x + step * (delta_x // steps)
            point_y = first_y + step * (delta_y // steps)
            if point_y * 3 + point_x not in visited:
                return False
        visited.add(second)
    return True


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) != 1 or not MIN_PATTERN_LENGTH <= values[0] <= MAX_PATTERN_LENGTH:
        return None
    return values[0]


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    length = _parse(values, input_is_null, input_length)
    if length is None:
        return INVALID_RESULT
    return sum(
        1 for pattern in permutations(range(9), length)
        if _valid_pattern(pattern)
    )
