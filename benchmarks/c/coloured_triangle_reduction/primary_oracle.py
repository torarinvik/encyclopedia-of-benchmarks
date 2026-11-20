"""Closed-form triangle reduction using Lucas coefficients modulo three."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 256
MAX_VALID_INPUT_LENGTH = MAX_N + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, tuple[int, ...]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != n + 1:
        return None
    colors = tuple(values[1:])
    if any(color not in (0, 1, 2) for color in colors):
        return None
    return n, colors


def _binomial_mod_three(n: int, k: int) -> int:
    """Apply Lucas' theorem digit by digit in base three."""
    coefficient = 1
    while n or k:
        n_digit = n % 3
        k_digit = k % 3
        if k_digit > n_digit:
            return 0
        if n_digit == 2 and k_digit == 1:
            coefficient = (2 * coefficient) % 3
        n //= 3
        k //= 3
    return coefficient


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, colors = parsed
    rounds = n - 1
    total = 0
    for index, color in enumerate(colors):
        total = (total + _binomial_mod_three(rounds, index) * color) % 3
    return total if rounds % 2 == 0 else (-total) % 3
