"""Oracle for the bounded nonempty byte-array reversal contract."""

from __future__ import annotations

MAX_LENGTH = 256
INVALID_RESULT = -1


def expected_result(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or len(values) < 1
            or len(values) > MAX_LENGTH + 1
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT, b""
    count = values[0]
    items = values[1:]
    if not 1 <= count <= MAX_LENGTH or len(items) != count or any(not 0 <= item <= 255 for item in items):
        return INVALID_RESULT, b""
    return count, bytes(reversed(items))
