"""Exhaustive bounded coefficient search for the Gao decoder contract."""

from __future__ import annotations

from collections.abc import Sequence
from itertools import product

FIELD = 7
MAX_N = 7
MAX_K = 3
MAX_T = 2
MAX_VALID_INPUT_LENGTH = 3 + MAX_N
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n, k, errors = values[:3]
    if (not 2 <= n <= MAX_N or not 1 <= k <= min(MAX_K, n)
            or not 0 <= errors <= MAX_T or 2 * errors > n - k
            or len(values) != 3 + n
            or any(not 0 <= symbol < FIELD for symbol in values[3:])):
        return None
    return n, k, errors, tuple(values[3:])


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    n, k, errors, received = parsed
    matches: list[tuple[int, ...]] = []
    for coefficients in product(range(FIELD), repeat=k):
        mismatches = 0
        for x, symbol in enumerate(received):
            value = 0
            for coefficient in reversed(coefficients):
                value = (value * x + coefficient) % FIELD
            mismatches += value != symbol
        if mismatches <= errors:
            matches.append(coefficients)
            if len(matches) > 1:
                return 0
    if not matches:
        return 0
    result = 1
    place = 1
    for coefficient in matches[0]:
        result += coefficient * place
        place *= FIELD
    return result
