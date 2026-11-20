"""400-year-era Gregorian day-count decoder reference."""

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


def _leap(year: int) -> bool:
    return year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)


def _civil_from_unix_days(day_offset: int) -> tuple[int, int, int]:
    # March is month zero here, so the leap day closes the civil year.
    shifted = day_offset + 719_468
    era = shifted // 146_097
    day_of_era = shifted - era * 146_097
    year_of_era = (
        day_of_era - day_of_era // 1_460 + day_of_era // 36_524
        - day_of_era // 146_096
    ) // 365
    year = year_of_era + era * 400
    day_of_year_march = day_of_era - (
        365 * year_of_era + year_of_era // 4 - year_of_era // 100
    )
    month_march = (5 * day_of_year_march + 2) // 153
    day = day_of_year_march - (153 * month_march + 2) // 5 + 1
    month = month_march + (3 if month_march < 10 else -9)
    year += int(month <= 2)
    return year, month, day


def _ordinal_day(year: int, month: int, day: int) -> int:
    days_before_month = (0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334)
    leap_adjustment = int(month > 2 and _leap(year))
    return days_before_month[month - 1] + leap_adjustment + day


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
    year, month, day = _civil_from_unix_days(day_offset)
    ordinal = _ordinal_day(year, month, day)
    staged = year.to_bytes(8, "little", signed=True) + ordinal.to_bytes(8, "little", signed=True)
    if output_is_null or capacity is not None and capacity < len(staged):
        return OUTPUT_ERROR, b""
    return len(staged), staged
