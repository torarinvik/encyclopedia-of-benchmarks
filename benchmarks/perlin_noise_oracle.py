"""Oracle for the bounded pinned Java Perlin-like value-noise generator."""

from __future__ import annotations

from collections.abc import Sequence
import math
import struct

MIN_DIMENSION = 1
MAX_DIMENSION = 8
MIN_OCTAVES = 1
MAX_OCTAVES = 4
MIN_SEED = 0
MAX_SEED = (1 << 31) - 1
PERSISTENCE_VALUES = (0.5, 0.75, 1.0)
MAX_INPUT_ELEMENTS = 5
MAX_PARSEABLE_INPUT_ELEMENTS = MAX_INPUT_ELEMENTS + 1
MAX_OUTPUT_ELEMENTS = MAX_DIMENSION * MAX_DIMENSION
INVALID_RESULT = -1
OUTPUT_ERROR = -2

_JAVA_MULTIPLIER = 0x5DEECE66D
_JAVA_ADDEND = 0xB
_JAVA_MASK = (1 << 48) - 1
_JAVA_FLOAT_SCALE = 1 << 24


def _f32(value: float | int) -> float:
    """Round one operation result to Java IEEE-754 binary32 precision."""
    return struct.unpack("<f", struct.pack("<f", value))[0]


class _JavaRandom:
    """The 48-bit LCG and `nextFloat` sequence used by `java.util.Random`."""

    def __init__(self, seed: int) -> None:
        self._seed = (seed ^ _JAVA_MULTIPLIER) & _JAVA_MASK

    def _next(self, bits: int) -> int:
        self._seed = (self._seed * _JAVA_MULTIPLIER + _JAVA_ADDEND) & _JAVA_MASK
        return self._seed >> (48 - bits)

    def next_float(self) -> float:
        # Java computes next(24) / (float)(1 << 24); this dyadic fraction is exact.
        return _f32(self._next(24) / _JAVA_FLOAT_SCALE)


def _interpolate(a: float, b: float, alpha: float) -> float:
    """Match `a * (1 - alpha) + alpha * b`, rounding each float operation."""
    one_minus_alpha = _f32(1.0 - alpha)
    left = _f32(a * one_minus_alpha)
    right = _f32(alpha * b)
    return _f32(left + right)


def _create_base(width: int, height: int, seed: int) -> list[list[float]]:
    random = _JavaRandom(seed)
    base = [[0.0] * height for _ in range(width)]
    for x in range(width):
        for y in range(height):
            base[x][y] = random.next_float()
    return base


def _create_layer(base: list[list[float]], octave: int) -> list[list[float]]:
    width = len(base)
    height = len(base[0])
    period = 1 << octave
    frequency = _f32(1.0 / period)
    layer = [[0.0] * height for _ in range(width)]

    for x in range(width):
        x0 = (x // period) * period
        x1 = (x0 + period) % width
        horizontal_blend = _f32(_f32(x - x0) * frequency)
        for y in range(height):
            y0 = (y // period) * period
            y1 = (y0 + period) % height
            vertical_blend = _f32(_f32(y - y0) * frequency)
            top = _interpolate(base[x0][y0], base[x1][y0], horizontal_blend)
            bottom = _interpolate(base[x0][y1], base[x1][y1], horizontal_blend)
            layer[x][y] = _interpolate(top, bottom, vertical_blend)
    return layer


def _generate(width: int, height: int, octave_count: int, persistence: float, seed: int) -> list[float]:
    base = _create_base(width, height, seed)
    layers = [_create_layer(base, octave) for octave in range(octave_count)]

    out = [[0.0] * height for _ in range(width)]
    amplitude = _f32(1.0)
    total_amplitude = _f32(0.0)
    persistence_f32 = _f32(persistence)
    for octave in range(octave_count - 1, -1, -1):
        amplitude = _f32(amplitude * persistence_f32)
        total_amplitude = _f32(total_amplitude + amplitude)
        layer = layers[octave]
        for x in range(width):
            for y in range(height):
                contribution = _f32(layer[x][y] * amplitude)
                out[x][y] = _f32(out[x][y] + contribution)

    inv_total = _f32(1.0 / total_amplitude)
    for x in range(width):
        for y in range(height):
            out[x][y] = _f32(out[x][y] * inv_total)

    # The source returns float[width][height], and the ABI widens those floats
    # to f64 in x-major, then y-minor order.
    return [float(out[x][y]) for x in range(width) for y in range(height)]


def _is_number(value: object) -> bool:
    return type(value) in (int, float) and math.isfinite(float(value))


def _exact_int(value: int | float) -> int | None:
    numeric = float(value)
    if numeric.is_integer():
        return int(numeric)
    return None


def expected_output(
    values: Sequence[int | float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    """Return exact widened-f32 output values or the ABI error result."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, []
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, []
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, []
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, []
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, []
    if not 4 <= len(values) <= MAX_PARSEABLE_INPUT_ELEMENTS:
        return INVALID_RESULT, []
    if any(not _is_number(value) for value in values):
        return INVALID_RESULT, []
    if len(values) != MAX_INPUT_ELEMENTS:
        return INVALID_RESULT, []

    width = _exact_int(values[0])
    height = _exact_int(values[1])
    octave_count = _exact_int(values[2])
    seed = _exact_int(values[4])
    persistence = float(values[3])
    if width is None or not MIN_DIMENSION <= width <= MAX_DIMENSION:
        return INVALID_RESULT, []
    if height is None or not MIN_DIMENSION <= height <= MAX_DIMENSION:
        return INVALID_RESULT, []
    if octave_count is None or not MIN_OCTAVES <= octave_count <= MAX_OCTAVES:
        return INVALID_RESULT, []
    if seed is None or not MIN_SEED <= seed <= MAX_SEED:
        return INVALID_RESULT, []
    if persistence not in PERSISTENCE_VALUES:
        return INVALID_RESULT, []

    output = _generate(width, height, octave_count, persistence, seed)
    if len(output) > MAX_OUTPUT_ELEMENTS:
        return INVALID_RESULT, []
    if output_is_null or (
        output_capacity is not None and output_capacity < len(output)
    ):
        return OUTPUT_ERROR, []
    return len(output), output


def expected_result(values: Sequence[int | float] | None) -> list[float] | None:
    """Return the output list, or `None` for invalid semantic input."""
    result, output = expected_output(values)
    return output if result >= 0 else None
