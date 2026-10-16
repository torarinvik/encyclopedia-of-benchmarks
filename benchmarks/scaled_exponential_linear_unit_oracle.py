"""Runtime reference for the pinned NumPy SELU expression."""
from __future__ import annotations
import math
import struct

MAX_INPUT_LENGTH = 259
MAX_VECTOR_LENGTH = 256
SCALE = 1_000_000


def expected_output(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(v) is not int or not -(2**63) <= v < 2**63 for v in values)):
        return -1, b""
    count, alpha_scaled, lambda_scaled = values[:3]
    if (not 0 <= count <= MAX_VECTOR_LENGTH or len(values) != count + 3
            or not -10*SCALE <= alpha_scaled <= 10*SCALE
            or not -10*SCALE <= lambda_scaled <= 10*SCALE
            or any(not -20*SCALE <= x <= 20*SCALE for x in values[3:])):
        return -1, b""
    alpha = alpha_scaled / SCALE
    lambda_ = lambda_scaled / SCALE
    result = []
    for value in values[3:]:
        x = value / SCALE
        # Match lambda * where(x > 0, x, alpha * (exp(x) - 1)).
        inner = x if x > 0.0 else alpha * (math.exp(x) - 1.0)
        result.append(lambda_ * inner)
    output = b"".join(struct.pack("<q", math.floor(x * 1_000_000_000 + 0.5)) for x in result)
    return len(output), output
