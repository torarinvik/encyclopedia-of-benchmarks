"""Year-start binary-search reference for Gregorian ordinal dates."""

from __future__ import annotations

from collections.abc import Sequence

MIN_DAY_OFFSET = -146_097
MAX_DAY_OFFSET = 146_097
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
MAX_OUTPUT_BYTES = 16
WORKSPACE_BYTES = 256
INVALID_RESULT = -1
OUTPUT_ERROR = -2
_I64_MIN = -(1 << 63)
_I64_MAX = (1 << 63) - 1


def _floor_div(numerator: int, denominator: int) -> int:
    quotient = abs(numerator) // denominator
    return -quotient - int(numerator % denominator != 0) if numerator < 0 else quotient


def _days_before_year(year: int) -> int:
    # Absolute proleptic-Gregorian day number with 0000-01-01 as day zero.
    return (365 * year + _floor_div(year + 3, 4)
            - _floor_div(year + 99, 100) + _floor_div(year + 399, 400))


_UNIX_EPOCH_ABSOLUTE_DAY = _days_before_year(1970)


def _year_for_offset(day_offset: int) -> tuple[int, int]:
    target = _UNIX_EPOCH_ABSOLUTE_DAY + day_offset
    low, high = 1570, 2371
    while low + 1 < high:
        middle = (low + high) // 2
        if _days_before_year(middle) <= target:
            low = middle
        else:
            high = middle
    year_start = _days_before_year(low)
    return low, target - year_start + 1


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not _I64_MIN <= value <= _I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) != 1 or not MIN_DAY_OFFSET <= values[0] <= MAX_DAY_OFFSET:
        return None
    return values[0]


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (
                type(input_length) is not int
                or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and (not isinstance(values, (list, tuple)) or input_length != len(values))):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    day_offset = _decode(values, input_is_null, input_length)
    if day_offset is None:
        return INVALID_RESULT, b""
    year, ordinal = _year_for_offset(day_offset)
    staged = year.to_bytes(8, "little", signed=True) + ordinal.to_bytes(8, "little", signed=True)
    if output_is_null or capacity is not None and capacity < len(staged):
        return OUTPUT_ERROR, b""
    return len(staged), staged
