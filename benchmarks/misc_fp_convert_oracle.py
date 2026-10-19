"""Independent float32-aware oracle for the bounded LAC-DCC fp-convert loop."""
from __future__ import annotations

import struct

MIN_ITERATIONS = 1
MAX_ITERATIONS = 256
MAX_PARSEABLE_INPUT_LENGTH = 2
VECTOR_LENGTH = 2048
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _f32(value: float) -> float:
    return struct.unpack("<f", struct.pack("<f", value))[0]


def expected_output(values: list[float]) -> tuple[int, list[float]]:
    """Return the source's double-precision accumulated dot-product total."""
    if type(values) is not list or len(values) != 1 or type(values[0]) not in (int, float):
        return -1, []
    requested = float(values[0])
    if not requested.is_integer() or not MIN_ITERATIONS <= requested <= MAX_ITERATIONS:
        return -1, []
    iterations = int(requested)
    a = _f32(0.0)
    b = _f32(1.0)
    total = 0.0
    for iteration in range(iterations):
        if iteration % 10 != 0:
            a = _f32(0.0)
            b = _f32(1.0)
        else:
            a = _f32(a + _f32(0.1))
            b = _f32(b + _f32(0.2))
        accumulator = 0.0
        for index in range(VECTOR_LENGTH):
            x = _f32(a + _f32(float(index)))
            y = _f32(b + _f32(float(index)))
            accumulator += x * y
        total += accumulator
    return 1, [total]
