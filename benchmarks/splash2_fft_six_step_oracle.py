"""Direct DFT and independent matrix-factorization oracles for SPLASH-2 FFT."""

from __future__ import annotations

from collections.abc import Sequence
import math

INVALID_RESULT = -1
OUTPUT_ERROR = -2
VALID_SIDES = (2, 4, 8)
MAX_POINTS = 64
MAX_INPUT_LENGTH = 130
MAX_OUTPUT_ELEMENTS = 128
ABSOLUTE_TOLERANCE = 1e-9
RELATIVE_TOLERANCE = 1e-12
TAU = 2.0 * math.pi


def _finite_number(value: object) -> bool:
    if type(value) not in (int, float):
        return False
    try:
        return math.isfinite(float(value))
    except OverflowError:
        return False


def _decode(values: Sequence[int | float] | None, input_length: int | None,
            input_is_null: bool) -> tuple[int, list[complex]] | None:
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    length = len(values) if input_length is None else input_length
    if (type(length) is not int or length != len(values)
            or not 9 <= length <= MAX_INPUT_LENGTH):
        return None
    if not all(_finite_number(value) for value in values):
        return None
    side_value = float(values[0])
    if side_value != math.trunc(side_value) or int(side_value) not in VALID_SIDES:
        return None
    side = int(side_value)
    points = side * side
    if length != 1 + 2 * points:
        return None
    samples: list[complex] = []
    for index in range(points):
        real = float(values[1 + 2 * index])
        imag = float(values[2 + 2 * index])
        if not (-8.0 <= real <= 8.0 and -8.0 <= imag <= 8.0):
            return None
        samples.append(complex(real, imag))
    return side, samples


def expected_output(values: Sequence[int | float] | None,
                    output_capacity: int | None = None,
                    output_is_null: bool = False,
                    input_length: int | None = None,
                    input_is_null: bool = False) -> tuple[int, list[float]]:
    """Compute the forward DFT directly, independent of the six-step schedule."""
    parsed = _decode(values, input_length, input_is_null)
    if parsed is None:
        return INVALID_RESULT, []
    _, samples = parsed
    count = len(samples)
    result: list[float] = []
    for frequency in range(count):
        real_sum = 0.0
        imag_sum = 0.0
        for index, sample in enumerate(samples):
            angle = -TAU * (index * frequency) / count
            cosine, sine = math.cos(angle), math.sin(angle)
            real_sum += sample.real * cosine - sample.imag * sine
            imag_sum += sample.real * sine + sample.imag * cosine
        result.extend((real_sum, imag_sum))
    needed = 2 * count
    if output_is_null or (output_capacity is not None and output_capacity < needed):
        return OUTPUT_ERROR, []
    return needed, result
