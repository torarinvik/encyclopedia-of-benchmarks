"""Independent oracle for the bounded Fibonacci-heap drain workload."""

from __future__ import annotations

import struct

MAX_KEYS = 128
MIN_KEY = -(2**31)
MAX_KEY = 2**31 - 1


def expected_output(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) > MAX_KEYS
            or any(type(value) is not int or not MIN_KEY <= value <= MAX_KEY for value in values)):
        return -1, b""
    ordered = sorted(values)
    output = b"".join(struct.pack("<q", value) for value in ordered)
    return len(output), output
