"""Independent oracle for the pinned Sort The Odd algorithm."""

from __future__ import annotations

MAX_LENGTH = 256
MAX_INPUT_LENGTH = MAX_LENGTH + 1  # allow a one-over-bound parser canary
MIN_VALUE = -1_000_000
MAX_VALUE = 1_000_000
CHECKSUM_OFFSET = 1_000_001
INVALID_RESULT = -1


def transformed(values: list[int]) -> list[int] | None:
    """Return the sorted-odd result, or None when the raw i64 input is invalid."""
    if (not isinstance(values, list) or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return None
    if len(values) > MAX_LENGTH or any(not MIN_VALUE <= value <= MAX_VALUE for value in values):
        return None

    odds = iter(sorted(value for value in values if value % 2 != 0))
    return [next(odds) if value % 2 != 0 else value for value in values]


def expected_result(values: list[int]) -> int:
    """Return the weighted checksum of the transformed array or -1 if invalid."""
    result = transformed(values)
    if result is None:
        return INVALID_RESULT
    return sum((index + 1) * (value + CHECKSUM_OFFSET)
               for index, value in enumerate(result))
