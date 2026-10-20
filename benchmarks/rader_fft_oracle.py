"""Independent direct-DFT oracle for the bounded five-point Rader FFT profile."""

from __future__ import annotations

import math
from collections.abc import Sequence

MAX_INPUT_LENGTH = 10
MAX_PARSEABLE_INPUT_LENGTH = 32
MAX_OUTPUT_ELEMENTS = 10
MAX_COMPONENT_MAGNITUDE = 100.0
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _finite_number(value: object) -> bool:
    if type(value) not in (int, float):
        return False
    try:
        return math.isfinite(float(value))
    except (OverflowError, ValueError):
        return False


def expected_output(
    values: Sequence[int | float], output_capacity: int | None = None
) -> tuple[int, list[float]]:
    """Return the interleaved unnormalized forward DFT of five complex samples."""
    if (not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(not _finite_number(value) for value in values)
            or len(values) != MAX_INPUT_LENGTH):
        return INVALID_RESULT, []
    components = [float(value) for value in values]
    if any(abs(value) > MAX_COMPONENT_MAGNITUDE for value in components):
        return INVALID_RESULT, []

    output: list[float] = []
    for frequency in range(5):
        real_sum = 0.0
        imag_sum = 0.0
        for sample in range(5):
            angle = -2.0 * math.pi * frequency * sample / 5.0
            cosine = math.cos(angle)
            sine = math.sin(angle)
            real = components[2 * sample]
            imag = components[2 * sample + 1]
            real_sum += real * cosine - imag * sine
            imag_sum += real * sine + imag * cosine
        output.extend((real_sum, imag_sum))

    if output_capacity is not None:
        if type(output_capacity) is not int or output_capacity < 0:
            return INVALID_RESULT, []
        if output_capacity < MAX_OUTPUT_ELEMENTS:
            return OUTPUT_ERROR, []
    return MAX_OUTPUT_ELEMENTS, output
