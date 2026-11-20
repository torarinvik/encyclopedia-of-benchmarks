"""Forward Chebyshev-basis recurrence, independent of Clenshaw back-substitution."""

from __future__ import annotations

from collections.abc import Sequence

MODULUS = 998_244_353
MAX_DEGREE = 16
MAX_PARSEABLE_INPUT_LENGTH = 21
INVALID_RESULT = -1


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[int, int, tuple[int, ...]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if type(actual_length) is not int or actual_length != len(values):
        return None
    degree, point = values[0], values[1]
    if not 0 <= degree <= MAX_DEGREE or len(values) != degree + 3:
        return None
    coefficients = tuple(values[2:])
    if not 0 <= point < MODULUS or any(not 0 <= value < MODULUS for value in coefficients):
        return None
    return degree, point, coefficients


def _forward_basis_sum(degree: int, x: int, coefficients: Sequence[int]) -> int:
    """Generate T_k in increasing k and accumulate each supplied coefficient."""
    total = coefficients[0]
    if degree == 0:
        return total
    previous = 1
    current = x
    total = (total + coefficients[1] * current) % MODULUS
    for index in range(2, degree + 1):
        following = (2 * x * current - previous) % MODULUS
        total = (total + coefficients[index] * following) % MODULUS
        previous, current = current, following
    return total


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    degree, x, coefficients = parsed
    return _forward_basis_sum(degree, x, coefficients)


def verify_candidate(values: Sequence[int] | None, result: int,
                     input_is_null: bool = False,
                     input_length: int | None = None) -> bool:
    return type(result) is int and result == expected_result(values, input_is_null, input_length)
