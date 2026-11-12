"""Signed-remainder oracle for canonical balanced ternary conversion."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VALUE = (1 << 63) - 1
MIN_VALUE = -(1 << 63)
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
MAX_OUTPUT_BYTES = 41
INVALID_RESULT = -1
CAPACITY_ERROR = -2


def _parse(values: Sequence[int] | None, input_is_null: bool = False,
           input_length: int | None = None) -> int | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values) or input_length != 1):
        return None
    value = values[0]
    if type(value) is not int or not MIN_VALUE <= value <= MAX_VALUE:
        return None
    return value


def _digits(value: int) -> bytes:
    if value == 0:
        return b"0"
    reversed_digits: list[int] = []
    while value != 0:
        quotient, remainder = divmod(value, 3)
        if remainder == 2:
            reversed_digits.append(ord("Z"))
            quotient += 1
        else:
            reversed_digits.append(ord("0") + remainder)
        value = quotient
    reversed_digits.reverse()
    return bytes(reversed_digits)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    value = _parse(values, input_is_null, input_length)
    if value is None:
        return INVALID_RESULT, b""
    required = len(_digits(value))
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if type(output_is_null) is not bool or type(effective_capacity) is not int or effective_capacity < 0:
        return CAPACITY_ERROR, b""
    if output_is_null or effective_capacity < required:
        return CAPACITY_ERROR, b""
    output = _digits(value)
    return len(output), output


def expected_result(values: Sequence[int] | None, **kwargs) -> int:
    return expected_output(values, **kwargs)[0]
