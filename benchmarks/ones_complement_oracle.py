"""Independent oracle for bounded ASCII one’s-complement conversion."""

from __future__ import annotations

MAX_INPUT_LENGTH = 64


def expected_output(values: list[int], capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, list) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or value not in (48, 49) for value in values)):
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if capacity is not None and capacity < len(values):
        return -2, b""
    return len(values), bytes(49 if value == 48 else 48 for value in values)
