"""Direct repeated-power oracle for multiplicative order modulo m."""

from __future__ import annotations

from typing import Sequence

ALGORITHM = "multiplicative_order"
MIN_MODULUS = 2
MAX_MODULUS = 1000
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
INVALID_RESULT = -1
NONUNIT_RESULT = 0
WORKSPACE_BYTES = 64


def _parse(values: Sequence[int] | None,
           input_is_null: bool,
           input_length: int | None) -> tuple[int, int] | None:
    if (input_is_null or not isinstance(values, (list, tuple))
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if len(values) != 2:
        return None
    base, modulus = values
    if not MIN_MODULUS <= modulus <= MAX_MODULUS or not 0 <= base < modulus:
        return None
    return base, modulus


def _search_powers(base: int, modulus: int) -> int:
    value = 1
    for exponent in range(1, modulus + 1):
        value = value * base % modulus
        if value == 1:
            return exponent
    return NONUNIT_RESULT


def expected_result(values: Sequence[int] | None,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    return _search_powers(*parsed)
