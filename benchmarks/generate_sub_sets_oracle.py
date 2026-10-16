"""Independent oracle for bounded JavaScript-style subset enumeration."""
from __future__ import annotations

import struct

MAX_ITEMS = 12
MAX_SAFE_INTEGER = (1 << 53) - 1
MAX_OUTPUT_BYTES = 212_996
MAX_INPUT_LENGTH = MAX_ITEMS + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1


def expected_output(values: list[int], output_capacity: int = MAX_OUTPUT_BYTES) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) < 1 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return -1, b""
    n = values[0]
    if n < 0 or n > MAX_ITEMS or len(values) != n + 1:
        return -1, b""
    items = values[1:]
    if any(not -MAX_SAFE_INTEGER <= value <= MAX_SAFE_INTEGER for value in items):
        return -1, b""
    output = bytearray(struct.pack("<I", 1 << n))
    for mask in range(1 << n):
        subset = [items[index] for index in range(n) if mask & (1 << index)]
        output.extend(struct.pack("<I", len(subset)))
        for value in subset:
            output.extend(struct.pack("<q", value))
    encoded = bytes(output)
    if len(encoded) > MAX_OUTPUT_BYTES:
        return -1, b""
    if output_capacity < len(encoded):
        return -2, b""
    return len(encoded), encoded
