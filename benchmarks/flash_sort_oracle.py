"""Oracle for the bounded Java/JavaScript/Python Flash Sort contract."""

from __future__ import annotations

import struct

MAX_LENGTH = 64
MAX_INPUT_LENGTH = 65
MIN_VALUE = -1_000_000
MAX_VALUE = 1_000_000
MAX_OUTPUT_BYTES = MAX_LENGTH * 4


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    if not isinstance(values, (list, tuple)) or len(values) > MAX_INPUT_LENGTH:
        return -1, b""
    if len(values) == 2 or len(values) > MAX_LENGTH:
        return -1, b""
    if any(type(value) is not int or not MIN_VALUE <= value <= MAX_VALUE for value in values):
        return -1, b""
    ordered = sorted(values)
    output = b"".join(struct.pack("<i", value) for value in ordered)
    return len(output), output
