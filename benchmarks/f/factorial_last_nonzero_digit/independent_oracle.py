"""Dresden base-five digit-product reference for the final nonzero digit."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = (1 << 63) - 1
MAX_PARSEABLE_INPUT_LENGTH = 2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1

_DIGIT_FACTORIAL_MOD_10 = (1, 1, 2, 6, 4)
_TWO_POWER_MOD_10 = (1, 2, 4, 8)


def _input_value(values: Sequence[int] | None, input_length: int | None,
                 input_is_null: bool) -> int | None:
    if input_is_null is not False or not isinstance(values, (list, tuple)):
        return None
    if len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or value < I64_MIN or value > I64_MAX
           for value in values):
        return None
    actual_length = len(values) if input_length is None else input_length
    if type(actual_length) is not int or actual_length != len(values):
        return None
    if len(values) != 1 or not 0 <= values[0] <= MAX_N:
        return None
    return values[0]


def expected_result(values: Sequence[int] | None,
                    input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    """Apply the base-five product, independently of the primary recurrence."""
    n = _input_value(values, input_length, input_is_null)
    if n is None:
        return -1
    if n < 2:
        return 1

    base_five_digits: list[int] = []
    remaining = n
    while remaining:
        remaining, digit = divmod(remaining, 5)
        base_five_digits.append(digit)

    product = 6
    for position, digit in enumerate(base_five_digits):
        product = (product * _DIGIT_FACTORIAL_MOD_10[digit]
                   * _TWO_POWER_MOD_10[(position * digit) % 4]) % 10
    return product


factorial_last_nonzero_digit = expected_result
