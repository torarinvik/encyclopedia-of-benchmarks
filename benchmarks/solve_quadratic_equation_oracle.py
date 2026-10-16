"""Oracle for the bounded Lua p-q quadratic solver."""
from __future__ import annotations
import math
import struct

MAX_COEFFICIENT = 1_000_000
MAX_INPUT_LENGTH = 3
MAX_OUTPUT_BYTES = 16

def expected_output(values: tuple[int, ...] | list[int], output_capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, (tuple, list)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    if len(values) != 2 or any(not -MAX_COEFFICIENT <= value <= MAX_COEFFICIENT for value in values):
        return -1, b""
    p, q = values
    discriminant_quarter = p * p / 4.0 - q
    roots: tuple[float, ...]
    if discriminant_quarter < 0.0:
        roots = ()
    else:
        root = math.sqrt(discriminant_quarter)
        x1 = -p / 2.0 - root
        x2 = -p / 2.0 + root
        roots = (x1,) if x1 == x2 else (x1, x2)
    output = b"".join(struct.pack("<d", value) for value in roots)
    if output_capacity is not None:
        if type(output_capacity) is not int or output_capacity < 0:
            return -1, b""
        if output_capacity < len(output):
            return -2, b""
    return len(roots), output
