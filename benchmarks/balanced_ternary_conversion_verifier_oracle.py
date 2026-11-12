"""Independent ordinary-ternary carry oracle for balanced ternary output."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VALUE = (1 << 63) - 1
MIN_VALUE = -(1 << 63)
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
MAX_OUTPUT_BYTES = 41
INVALID_RESULT = -1
CAPACITY_ERROR = -2


def _parse_input(values: Sequence[int] | None, input_is_null: bool,
                 input_length: int | None) -> int | None:
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 1
            or input_length > MAX_PARSEABLE_INPUT_LENGTH or input_length != len(values)):
        return None
    if len(values) != 1 or type(values[0]) is not int:
        return None
    value = values[0]
    if value < MIN_VALUE or value > MAX_VALUE:
        return None
    return value


def _ordinary_ternary_with_carries(value: int) -> bytes:
    negative = value < 0
    magnitude = -value if negative else value
    ordinary: list[int] = []
    if magnitude == 0:
        ordinary.append(0)
    while magnitude > 0:
        ordinary.append(magnitude % 3)
        magnitude //= 3

    balanced: list[int] = []
    carry = 0
    for trit in ordinary:
        digit = trit + carry
        if digit <= 1:
            balanced.append(digit)
            carry = 0
        elif digit == 2:
            balanced.append(-1)
            carry = 1
        else:
            balanced.append(0)
            carry = 1
    if carry:
        balanced.append(1)
    if negative:
        balanced = [-digit for digit in balanced]
    symbols = { -1: ord("Z"), 0: ord("0"), 1: ord("1") }
    return bytes(symbols[digit] for digit in reversed(balanced))


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    value = _parse_input(values, input_is_null, input_length)
    if value is None:
        return INVALID_RESULT, b""
    if input_length is None:
        input_length = len(values)  # type: ignore[arg-type]
    if type(input_length) is not int or input_length != 1:
        return INVALID_RESULT, b""
    required_output = _ordinary_ternary_with_carries(value)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return CAPACITY_ERROR, b""
    if output_is_null or effective_capacity < len(required_output):
        return CAPACITY_ERROR, b""
    return len(required_output), required_output


def expected_result(values: Sequence[int] | None, **kwargs) -> int:
    return expected_output(values, **kwargs)[0]
