"""Oracle for TheAlgorithms/Go's bounded Simple sorting routine."""

from __future__ import annotations

MAX_LENGTH = 256
MIN_VALUE = -1_000_000
MAX_VALUE = 1_000_000
CHECKSUM_OFFSET = 1_000_001
INVALID_RESULT = -1


def transform(values: list[int] | tuple[int, ...]) -> list[int] | None:
    """Return the exact Simple-loop output, or None for an invalid input."""
    if (not isinstance(values, (list, tuple)) or len(values) > MAX_LENGTH
            or any(type(value) is not int or not MIN_VALUE <= value <= MAX_VALUE
                   for value in values)):
        return None
    result = list(values)
    for i in range(len(result)):
        for j in range(len(result)):
            if result[i] < result[j]:
                result[i], result[j] = result[j], result[i]
    return result


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return the sorted output's weighted checksum or INVALID_RESULT."""
    result = transform(values)
    if result is None:
        return INVALID_RESULT
    return sum((index + 1) * (value + CHECKSUM_OFFSET)
               for index, value in enumerate(result))
