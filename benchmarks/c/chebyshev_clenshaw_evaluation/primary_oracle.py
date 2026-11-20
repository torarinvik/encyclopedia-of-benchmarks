"""Clenshaw backward recurrence for a Chebyshev series over a finite field."""

from __future__ import annotations

from collections.abc import Sequence

MODULUS = 998_244_353
MAX_DEGREE = 16
MAX_VALID_INPUT_LENGTH = MAX_DEGREE + 3
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 2
MIN_RESULT = 0
MAX_RESULT = MODULUS - 1
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, tuple[int, ...]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    degree, x = values[:2]
    if not 0 <= degree <= MAX_DEGREE or len(values) != degree + 3:
        return None
    coefficients = tuple(values[2:])
    if not 0 <= x < MODULUS or any(not 0 <= value < MODULUS for value in coefficients):
        return None
    return degree, x, coefficients


def _clenshaw(degree: int, x: int, coefficients: Sequence[int]) -> int:
    """Evaluate a0*T0 + ... + aN*TN with two rolling backward states."""
    next_one = 0
    next_two = 0
    twice_x = (2 * x) % MODULUS
    for index in range(degree, 0, -1):
        current = (coefficients[index] + twice_x * next_one - next_two) % MODULUS
        next_two, next_one = next_one, current
    return (coefficients[0] + x * next_one - next_two) % MODULUS


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    degree, x, coefficients = parsed
    return _clenshaw(degree, x, coefficients)
