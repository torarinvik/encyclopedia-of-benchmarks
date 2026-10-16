"""Independent oracle for the bounded recursive linear-search contract."""

from __future__ import annotations

MAX_COUNT = 64
MAX_INPUT_LENGTH = MAX_COUNT + 3  # one over-cap element is parseable and reaches the ABI
MAX_VALID_INPUT_LENGTH = MAX_COUNT + 2
MIN_VALUE = -1_000_000
MAX_VALUE = 1_000_000
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT

    count, target = values[:2]
    if (not 1 <= count <= MAX_COUNT or len(values) != count + 2
            or not MIN_VALUE <= target <= MAX_VALUE):
        return INVALID_RESULT
    items = values[2:]
    if (any(not MIN_VALUE <= item <= MAX_VALUE for item in items)
            or len(set(items)) != count):
        return INVALID_RESULT
    try:
        return items.index(target)
    except ValueError:
        return INVALID_RESULT
