"""Independent oracle for bounded RGB channel to hexadecimal text conversion."""

from __future__ import annotations

MAX_INPUT_LENGTH = 3
OUTPUT_LENGTH = 7
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(values: list[int], capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   or not 0 <= value <= 255 for value in values)):
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if capacity is not None and capacity < OUTPUT_LENGTH:
        return -2, b""
    return OUTPUT_LENGTH, ("#" + "".join(f"{value:02x}" for value in values)).encode("ascii")
