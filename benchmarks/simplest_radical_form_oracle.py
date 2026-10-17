"""Independent bounded oracle for the Lua simplest radical form routine."""
from __future__ import annotations

import struct

MAX_INPUT_LENGTH = 1
MAX_OUTPUT_BYTES = 16
MAX_RADICAND = 100_000_000


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    """Return status and little-endian [coefficient, root_term] bytes."""
    if (not isinstance(values, (list, tuple)) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    original = values[0]
    if not 0 <= original <= MAX_RADICAND:
        return -1, b""
    if original == 0:
        return MAX_OUTPUT_BYTES, struct.pack("<qq", 1, 0)

    remainder = original
    coefficient = 1
    root_term = 1
    factor = 2
    # The source fixes this limit from the original input before its trial loop.
    while factor * factor <= original:
        count = 0
        while remainder % factor == 0:
            remainder //= factor
            count += 1
        coefficient *= factor ** (count // 2)
        if count % 2:
            root_term *= factor
        factor += 1
    root_term *= remainder
    return MAX_OUTPUT_BYTES, struct.pack("<qq", coefficient, root_term)
