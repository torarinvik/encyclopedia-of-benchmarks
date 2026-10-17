"""Bounded complex64 oracle for the quadratic Julia iteration benchmark."""

from __future__ import annotations

import math
import struct

MIN_ITERATIONS = 0
MAX_ITERATIONS = 8
MIN_POINTS = 0
MAX_POINTS = 32
COMPONENT_SCALE = 16
MAX_COMPONENT = 128
MAX_INPUT_LENGTH = 4 + 2 * MAX_POINTS
MAX_OUTPUT_BYTES = 8 * MAX_POINTS
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1


def _f32(value: float) -> float:
    """Round after each binary32 operation, preserving infinities on overflow."""
    try:
        return struct.unpack("<f", struct.pack("<f", value))[0]
    except OverflowError:
        return math.copysign(math.inf, value)


def _complex64_step(real: float, imag: float, c_real: float, c_imag: float) -> tuple[float, float]:
    real_square = _f32(real * real)
    imag_square = _f32(imag * imag)
    next_real = _f32(_f32(real_square - imag_square) + c_real)
    real_imag = _f32(real * imag)
    imag_real = _f32(imag * real)
    next_imag = _f32(_f32(real_imag + imag_real) + c_imag)
    return next_real, next_imag


def expected_output(
    values: list[int] | tuple[int, ...] | None,
    output_capacity: int | None = None,
) -> tuple[int, bytes]:
    """Return final complex64 point bytes, or an ABI status code."""
    if values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if (
        len(values) < 4
        or len(values) > MAX_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT, b""

    iterations, c_real_units, c_imag_units, count = values[:4]
    if (not MIN_ITERATIONS <= iterations <= MAX_ITERATIONS
            or not MIN_POINTS <= count <= MAX_POINTS):
        return INVALID_RESULT, b""
    if not -MAX_COMPONENT <= c_real_units <= MAX_COMPONENT:
        return INVALID_RESULT, b""
    if not -MAX_COMPONENT <= c_imag_units <= MAX_COMPONENT:
        return INVALID_RESULT, b""
    if len(values) != 4 + 2 * count:
        return INVALID_RESULT, b""
    if any(not -MAX_COMPONENT <= value <= MAX_COMPONENT for value in values[4:]):
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    needed = 8 * count
    if output_capacity is not None and output_capacity < needed:
        return INSUFFICIENT_CAPACITY_RESULT, b""

    c_real = _f32(c_real_units / float(COMPONENT_SCALE))
    c_imag = _f32(c_imag_units / float(COMPONENT_SCALE))
    output = bytearray()
    for index in range(count):
        real = _f32(values[4 + 2 * index] / float(COMPONENT_SCALE))
        imag = _f32(values[5 + 2 * index] / float(COMPONENT_SCALE))
        for _ in range(iterations):
            real, imag = _complex64_step(real, imag, c_real, c_imag)
            if not math.isfinite(real) or not math.isfinite(imag):
                return INVALID_RESULT, b""
        output.extend(struct.pack("<f", real))
        output.extend(struct.pack("<f", imag))

    return len(output), bytes(output)
