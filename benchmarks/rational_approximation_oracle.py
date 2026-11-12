"""Independent continued-fraction oracle for bounded rational neighbors."""
from __future__ import annotations

from fractions import Fraction
import struct
from typing import Sequence

MAX_COMPONENT = 1_000_000_000
MAX_VALID_INPUT_LENGTH = 3
MAX_PARSEABLE_INPUT_LENGTH = 4
MAX_OUTPUT_BYTES = 32
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2


def _bounded_neighbors(target: Fraction, denominator_limit: int) -> tuple[Fraction, Fraction]:
    """Return the adjacent Farey bounds using convergents and one semiconvergent."""
    previous_num, previous_den = 0, 1
    current_num, current_den = 1, 0
    numerator, denominator = target.numerator, target.denominator

    while denominator:
        quotient = numerator // denominator
        next_denominator = previous_den + quotient * current_den
        if next_denominator > denominator_limit:
            break
        previous_num, previous_den, current_num, current_den = (
            current_num, current_den,
            previous_num + quotient * current_num,
            next_denominator,
        )
        numerator, denominator = denominator, numerator - quotient * denominator

    if denominator == 0:
        exact = Fraction(current_num, current_den)
        return exact, exact

    multiplier = (denominator_limit - previous_den) // current_den
    semiconvergent = Fraction(
        previous_num + multiplier * current_num,
        previous_den + multiplier * current_den,
    )
    convergent = Fraction(current_num, current_den)
    if semiconvergent <= convergent:
        return semiconvergent, convergent
    return convergent, semiconvergent


def _neighbors(bound: int, numerator: int, denominator: int) -> tuple[int, int, int, int]:
    divisor = Fraction(numerator, denominator)
    if divisor.numerator <= bound and divisor.denominator <= bound:
        return (divisor.numerator, divisor.denominator,
                divisor.numerator, divisor.denominator)

    if divisor < 1:
        lower, upper = _bounded_neighbors(divisor, bound)
        lower_pair = (lower.numerator, lower.denominator) if lower else (0, 1)
        return (*lower_pair, upper.numerator, upper.denominator)

    reciprocal_lower, reciprocal_upper = _bounded_neighbors(1 / divisor, bound)
    lower_pair = (reciprocal_upper.denominator, reciprocal_upper.numerator)
    upper_pair = ((reciprocal_lower.denominator, reciprocal_lower.numerator)
                  if reciprocal_lower else (1, 0))
    return (*lower_pair, *upper_pair)


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (input_is_null or not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int
                     or input_length != len(values)
                     or input_length > MAX_PARSEABLE_INPUT_LENGTH))
            or len(values) != MAX_VALID_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT, b""

    bound, numerator, denominator = values
    if not (1 <= bound <= MAX_COMPONENT and 1 <= numerator <= MAX_COMPONENT
            and 1 <= denominator <= MAX_COMPONENT):
        return INVALID_RESULT, b""

    result = _neighbors(bound, numerator, denominator)
    payload = struct.pack("<4q", *result)
    if (capacity is not None
            and (type(capacity) is not int or capacity < 0)):
        return INVALID_RESULT, b""
    if output_is_null or capacity is not None and capacity < len(payload):
        return INSUFFICIENT_CAPACITY_RESULT, b""
    return len(payload), payload
