"""Independent oracle for the bounded pinned Python RGB-to-CMYK conversion."""

from __future__ import annotations

MAX_INPUT_LENGTH = 4
OUTPUT_LENGTH = 4
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(values: list[int], capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) != 3
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   or not 0 <= value <= 255 for value in values)):
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if capacity is not None and capacity < OUTPUT_LENGTH:
        return -2, b""

    red, green, blue = (value / 255.0 for value in values)
    key = 1.0 - max(red, green, blue)
    if key == 1.0:
        return OUTPUT_LENGTH, bytes((0, 0, 0, 100))
    cyan = round(100.0 * (1.0 - red - key) / (1.0 - key))
    magenta = round(100.0 * (1.0 - green - key) / (1.0 - key))
    yellow = round(100.0 * (1.0 - blue - key) / (1.0 - key))
    key_percent = round(100.0 * key)
    return OUTPUT_LENGTH, bytes((cyan, magenta, yellow, key_percent))
