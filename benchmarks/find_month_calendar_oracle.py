"""Bounded source-derived calendar output for FindMonthCalendar.js."""
from __future__ import annotations

MAX_VALID_INPUT_LENGTH = 2
MAX_INPUT_LENGTH = 3
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_OUTPUT_BYTES = 181
MIN_YEAR = 1899
MAX_YEAR = 2100
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2

DAYS = ("M", "T", "W", "Th", "F", "S", "Su")
BACKWARD_DAYS = ("M", "Su", "S", "F", "Th", "W", "T")
COMMON_MONTH_DAYS = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)


def is_leap_year(year: int) -> bool:
    return year % 400 == 0 or (year % 100 != 0 and year % 4 == 0)


def month_length(year: int, month: int) -> int:
    if month == 2 and is_leap_year(year):
        return 29
    return COMMON_MONTH_DAYS[month - 1]


def _source_start_offset(month: int, year: int) -> int:
    # Reproduce getDayDiff relative to the pinned Monday 1/1900 epoch.
    # The accepted pre-epoch year is 1899, which avoids the source's leap-year
    # month-correction quirk for dates in earlier leap years.
    difference = 0
    if year >= 1900:
        for current_year in range(1900, year):
            difference += 366 if is_leap_year(current_year) else 365
        for current_month in range(1, month):
            difference += month_length(year, current_month)
        return difference % 7

    for current_year in range(year, 1900):
        difference += 366 if is_leap_year(current_year) else 365
    for current_month in range(1, month):
        difference -= month_length(1900, current_month)
    return (7 - difference % 7) % 7


def calendar_bytes(month: int, year: int) -> bytes:
    offset = _source_start_offset(month, year)
    total_cells = offset + month_length(year, month)
    lines = ["M   T   W   Th  F   S   Su"]
    cursor = 0
    while cursor < total_cells:
        cells_in_row = min(7, total_cells - cursor)
        row = []
        for cell_index in range(cursor, cursor + cells_in_row):
            day = cell_index - offset + 1
            if day < 1:
                row.append("    ")
            else:
                text = str(day)
                row.append(text + " " * (4 - len(text)))
        lines.append("".join(row))
        cursor += cells_in_row
    return ("\n".join(lines) + "\n").encode("ascii")


def expected_output(values: list[int]) -> tuple[int, bytes]:
    if (
        not isinstance(values, list)
        or len(values) != 2
        or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
    ):
        return INVALID_RESULT, b""
    month, year = values
    if not 1 <= month <= 12 or not MIN_YEAR <= year <= MAX_YEAR:
        return INVALID_RESULT, b""
    output = calendar_bytes(month, year)
    return len(output), output
