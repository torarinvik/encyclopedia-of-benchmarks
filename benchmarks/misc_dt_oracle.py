"""Independent bounded oracle for the lac-dcc repeated vector division kernel."""

from __future__ import annotations

import math
import struct

MIN_ITERATIONS = 1
MAX_ITERATIONS = 128
MIN_SIZE = 1
MAX_SIZE = 64
MAX_PARSEABLE_INPUT_LENGTH = 3
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _f32(value: float) -> float:
    return struct.unpack("<f", struct.pack("<f", value))[0]


def expected_output(values: list[float] | None) -> tuple[int, list[float]]:
    """Return the final initialized numerator vector, or invalid-input status."""
    if (type(values) is not list or len(values) != 2
            or any(type(value) not in (int, float) for value in values)):
        return INVALID_RESULT, []
    raw_iterations, raw_size = values
    if (raw_iterations < MIN_ITERATIONS or raw_iterations > MAX_ITERATIONS
            or raw_size < MIN_SIZE or raw_size > MAX_SIZE):
        return INVALID_RESULT, []
    requested_iterations, requested_size = float(raw_iterations), float(raw_size)
    if not requested_iterations.is_integer() or not requested_size.is_integer():
        return INVALID_RESULT, []

    iterations, size = int(requested_iterations), int(requested_size)
    numerator = [0.0] * size
    denominator = [0.0] * size
    for index in range(size):
        cosine = _f32(math.cos(_f32(float(size - index))))
        sine = _f32(math.sin(_f32(float(index))))
        numerator[index] = 1.0000001 * cosine
        denominator[index] = 1.0 + 1e-10 * sine

    for _ in range(iterations):
        for index in range(size):
            numerator[index] /= denominator[index]
    return size, numerator
