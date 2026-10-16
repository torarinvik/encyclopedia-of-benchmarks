"""Oracle for deterministic mask-driven uniform crossover."""

from __future__ import annotations
import struct

MAX_COUNT = 64
MIN_GENE = -(1 << 31)
MAX_GENE = (1 << 31) - 1
INVALID_RESULT = -1

def expected_result(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or len(values) < 1
            or len(values) > 1 + 3 * MAX_COUNT
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return INVALID_RESULT, b""
    count = values[0]
    if not 1 <= count <= MAX_COUNT or len(values) != 1 + 3 * count:
        return INVALID_RESULT, b""
    mask = values[1:1 + count]
    parent_one = values[1 + count:1 + 2 * count]
    parent_two = values[1 + 2 * count:]
    if any(bit not in (0, 1) for bit in mask):
        return INVALID_RESULT, b""
    if any(value < MIN_GENE or value > MAX_GENE for value in parent_one + parent_two):
        return INVALID_RESULT, b""
    child_one = [first if bit else second for bit, first, second in zip(mask, parent_one, parent_two)]
    child_two = [second if bit else first for bit, first, second in zip(mask, parent_one, parent_two)]
    output = b"".join(struct.pack("<q", value) for value in child_one + child_two)
    return len(output), output
