"""Independent Gregorian-date oracle for the bounded DateToDay contract."""

from __future__ import annotations

import datetime as dt
import re

I64_MIN = -(2**63)
I64_MAX = 2**63 - 1
MAX_INPUT_LENGTH = 11
_DATE = re.compile(rb"([0-9]{1,2})/([0-9]{1,2})/([0-9]{4})\Z")
_WEEKDAYS = ("Saturday", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday")


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    """Return (output byte count, weekday bytes), or (-1, empty) if invalid."""
    if (not isinstance(values, (list, tuple)) or not 9 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
            or values[-1] != 0):
        return -1, b""
    try:
        encoded = bytes(values[:-1])
    except (ValueError, OverflowError):
        return -1, b""
    match = _DATE.fullmatch(encoded)
    if match is None:
        return -1, b""
    day, month, year = (int(part) for part in match.groups())
    if year == 0:
        return -1, b""
    try:
        parsed = dt.date(year, month, day)
    except ValueError:
        return -1, b""
    weekday = _WEEKDAYS[(parsed.weekday() + 2) % 7]
    output = weekday.encode("ascii")
    return len(output), output
