"""Prime-factor formula for the arithmetic derivative."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 1_000_000_000_000
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
INVALID_RESULT = -1
MAX_RESULT = 19_500_000_000_000
MAX_RESULT_BOUND = MAX_RESULT


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if (type(actual_length) is not int or actual_length != len(values)
            or len(values) != MAX_VALID_INPUT_LENGTH):
        return None
    n = values[0]
    if not 0 <= n <= MAX_N:
        return None
    return n


def _factor_formula(n: int) -> int:
    if n < 2:
        return 0
    original = n
    derivative = 0
    factor = 2
    while factor <= n // factor:
        if n % factor == 0:
            exponent = 0
            while n % factor == 0:
                n //= factor
                exponent += 1
            derivative += (original // factor) * exponent
        factor = 3 if factor == 2 else factor + 2
    if n > 1:
        derivative += original // n
    return derivative


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return D(n), or -1 for an invalid frame/domain value."""
    n = _parse(values, input_is_null, input_length)
    return INVALID_RESULT if n is None else _factor_formula(n)
