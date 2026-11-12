"""Independent separable direct-DFT oracle for the bounded NAS FT profile."""

from __future__ import annotations

import math
from typing import Sequence

MIN_SIDE = 2
MAX_SIDE = 4
MIN_STEPS = 1
MAX_STEPS = 6
MAX_INPUT_LENGTH = 2 + 2 * MAX_SIDE ** 3
CHECKSUM_TERMS = 64
ALPHA = 1.0e-6
TAU = 6.28318530717958647692528676655900577


def _integer(value: object, low: int, high: int) -> bool:
    return (type(value) in (int, float) and math.isfinite(float(value))
            and float(value).is_integer() and low <= value <= high)


def _axis_pass(real: list[float], imag: list[float], side: int,
               axis: int, inverse: bool) -> tuple[list[float], list[float]]:
    """Transform one family of contiguous or strided lines using direct sums."""
    out_real, out_imag = real.copy(), imag.copy()
    sign = 1.0 if inverse else -1.0
    for a in range(side):
        for b in range(side):
            line_real, line_imag = [], []
            for position in range(side):
                xyz = [a, b, position]
                if axis == 0:
                    xyz = [position, a, b]
                elif axis == 1:
                    xyz = [a, position, b]
                index = (xyz[0] * side + xyz[1]) * side + xyz[2]
                line_real.append(real[index])
                line_imag.append(imag[index])
            for frequency in range(side):
                total_real = total_imag = 0.0
                for position in range(side):
                    angle = sign * TAU * position * frequency / side
                    cosine, sine = math.cos(angle), math.sin(angle)
                    total_real += line_real[position] * cosine - line_imag[position] * sine
                    total_imag += line_real[position] * sine + line_imag[position] * cosine
                if inverse:
                    total_real /= side
                    total_imag /= side
                xyz = [a, b, frequency]
                if axis == 0:
                    xyz = [frequency, a, b]
                elif axis == 1:
                    xyz = [a, frequency, b]
                index = (xyz[0] * side + xyz[1]) * side + xyz[2]
                out_real[index], out_imag[index] = total_real, total_imag
    return out_real, out_imag


def _separable(real: list[float], imag: list[float], side: int,
               inverse: bool) -> tuple[list[float], list[float]]:
    for axis in (2, 1, 0):
        real, imag = _axis_pass(real, imag, side, axis, inverse)
    return real, imag


def _frequency(index: int, side: int) -> int:
    return index if index <= side // 2 else index - side


def _checksum(real: Sequence[float], imag: Sequence[float], side: int) -> tuple[float, float]:
    total_real = total_imag = 0.0
    for j in range(1, CHECKSUM_TERMS + 1):
        index = (((j - 1) % side) * side + (3 * j - 1) % side) * side + (5 * j - 1) % side
        total_real += real[index]
        total_imag += imag[index]
    volume = side ** 3
    return total_real / volume, total_imag / volume


def expected_output(values: Sequence[int | float] | None,
                    output_capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, list[float]]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))
            or (input_length is not None
                and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH))):
        return -1, []
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, []
    if (len(values) < 2 or len(values) > MAX_INPUT_LENGTH
            or (input_length is not None and input_length != len(values))
            or any(type(value) not in (int, float) or not math.isfinite(float(value)) for value in values)):
        return -1, []
    if not _integer(values[0], 2, 4) or not _integer(values[1], 1, 6):
        return -1, []
    side, steps = int(values[0]), int(values[1])
    if side not in (2, 4) or len(values) != 2 + 2 * side ** 3:
        return -1, []
    components = [float(value) for value in values[2:]]
    if any(not -1.0 <= value <= 1.0 for value in components):
        return -1, []
    needed, volume = 2 * steps, side ** 3
    if output_is_null or output_capacity is not None and output_capacity < needed:
        return -2, []
    real, imag = _separable(components[0::2], components[1::2], side, False)
    result: list[float] = []
    for step in range(1, steps + 1):
        work_real, work_imag = real.copy(), imag.copy()
        for x in range(side):
            for y in range(side):
                for z in range(side):
                    kx, ky, kz = _frequency(x, side), _frequency(y, side), _frequency(z, side)
                    index = (x * side + y) * side + z
                    factor = math.exp(-4.0 * math.pi * math.pi * ALPHA * step
                                      * (kx * kx + ky * ky + kz * kz))
                    work_real[index] *= factor
                    work_imag[index] *= factor
        work_real, work_imag = _separable(work_real, work_imag, side, True)
        result.extend(_checksum(work_real, work_imag, side))
    return needed, result
