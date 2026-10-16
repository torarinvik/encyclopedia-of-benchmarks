"""Independent oracle for bounded sentinel-search arrays."""
from __future__ import annotations

MAX_COUNT = 1_048_576
MIN_VALUE = -2_000_001
MAX_VALUE = 2_000_001
INVALID_RESULT = -1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Decode [count, target, *items] and return the first matching index."""
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    count, target = values[:2]
    if (not 0 <= count <= MAX_COUNT or len(values) != count + 2
            or not MIN_VALUE <= target <= MAX_VALUE):
        return INVALID_RESULT
    items = values[2:]
    if any(not MIN_VALUE <= item <= MAX_VALUE for item in items):
        return INVALID_RESULT
    try:
        return items.index(target)
    except ValueError:
        return INVALID_RESULT
