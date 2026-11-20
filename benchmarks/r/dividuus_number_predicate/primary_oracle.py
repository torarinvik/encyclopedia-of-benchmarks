"""Numeric digit-scan reference for the bounded Dividuus predicate."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 100_000
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
MAX_DIGIT_SUM = 45
MAX_DIGIT_PRODUCT = 59_049
WORKSPACE_BYTES = 256
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if (type(actual_length) is not int or actual_length != len(values)
            or len(values) != MAX_VALID_INPUT_LENGTH):
        return None
    n = values[0]
    return n if 1 <= n <= MAX_N else None


def _digit_sum(value: int) -> int:
    total = 0
    while value:
        total += value % 10
        value //= 10
    return total


def _digit_product(value: int) -> int:
    product = 1
    while value:
        product *= value % 10
        value //= 10
    return product


def _digital_root(value: int) -> int:
    while value >= 10:
        value = _digit_sum(value)
    return value


def _multiplicative_digital_root(value: int) -> int:
    while value >= 10:
        value = _digit_product(value)
    return value


def _is_dividuus(n: int) -> int:
    digit_sum = _digit_sum(n)
    digit_product = _digit_product(n)
    digital_root = _digital_root(n)
    multiplicative_root = _multiplicative_digital_root(n)
    divisors = (digit_sum, digit_product, digital_root, multiplicative_root)
    if any(divisor == 0 for divisor in divisors):
        return 0
    return int(all(n % divisor == 0 for divisor in divisors))


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return 1 iff all four positive digit-derived divisors divide n; else 0."""
    n = _parse(values, input_is_null, input_length)
    return -1 if n is None else _is_dividuus(n)
