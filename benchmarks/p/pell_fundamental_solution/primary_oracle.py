"""Continued-fraction convergents for the fundamental Pell solution."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MIN_D = 2
MAX_D = 31
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
WORKSPACE_BYTES = 256
PACK_SHIFT = 32
PACK_MASK = (1 << PACK_SHIFT) - 1


def _decode(values, input_is_null: bool, input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) != MAX_VALID_INPUT_LENGTH:
        return None
    d = values[0]
    if not MIN_D <= d <= MAX_D:
        return None
    root = 0
    while (root + 1) * (root + 1) <= d:
        root += 1
    if root * root == d:
        return None
    return d, root


def fundamental_solution(d: int, a0: int) -> tuple[int, int]:
    previous_numerator, numerator = 0, 1
    previous_denominator, denominator = 1, 0
    m = 0
    q = 1
    coefficient = a0

    while True:
        next_numerator = coefficient * numerator + previous_numerator
        next_denominator = coefficient * denominator + previous_denominator
        if next_numerator * next_numerator - d * next_denominator * next_denominator == 1:
            return next_numerator, next_denominator

        previous_numerator, numerator = numerator, next_numerator
        previous_denominator, denominator = denominator, next_denominator
        m = q * coefficient - m
        q = (d - m * m) // q
        coefficient = (a0 + m) // q


def pack_solution(x: int, y: int) -> int:
    return (x << PACK_SHIFT) | y


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1
    d, a0 = decoded
    x, y = fundamental_solution(d, a0)
    return pack_solution(x, y)
