"""Independent oracle for bounded ASCII swap-case conversion."""

from __future__ import annotations

MAX_INPUT_LENGTH = 4096


def expected_output(values: list[int], capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not 0 <= value <= 127 for value in values)):
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    output = bytes(value + 32 if 65 <= value <= 90 else value - 32 if 97 <= value <= 122 else value
                   for value in values)
    if capacity is not None and len(output) > capacity:
        return -2, b""
    return len(output), output
