"""Direct-transform oracle for the bounded NAS FT spectral-step profile."""

from __future__ import annotations

import math
from typing import Sequence

MIN_SIDE = 2
MAX_SIDE = 4
MIN_STEPS = 1
MAX_STEPS = 6
MAX_POINTS = MAX_SIDE ** 3
MAX_INPUT_LENGTH = 2 + 2 * MAX_POINTS
MAX_OUTPUT_ELEMENTS = 2 * MAX_STEPS
CHECKSUM_TERMS = 64
ALPHA = 1.0e-6
TAU = 6.28318530717958647692528676655900577
ABSOLUTE_TOLERANCE = 1.0e-9
RELATIVE_TOLERANCE = 1.0e-9


def _integer(value: object, low: int, high: int) -> bool:
    return (type(value) in (int, float) and math.isfinite(float(value))
            and float(value).is_integer() and low <= value <= high)


def _direct_transform(real: list[float], imag: list[float], side: int,
                      inverse: bool) -> tuple[list[float], list[float]]:
    """Compute the full 3-D DFT by its defining six nested sums."""
    volume = side ** 3
    sign = 1.0 if inverse else -1.0
    out_real = [0.0] * volume
    out_imag = [0.0] * volume
    for fx in range(side):
        for fy in range(side):
            for fz in range(side):
                total_real = total_imag = 0.0
                out_index = (fx * side + fy) * side + fz
                for x in range(side):
                    for y in range(side):
                        for z in range(side):
                            index = (x * side + y) * side + z
                            angle = sign * TAU * (x * fx + y * fy + z * fz) / side
                            cosine, sine = math.cos(angle), math.sin(angle)
                            total_real += real[index] * cosine - imag[index] * sine
                            total_imag += real[index] * sine + imag[index] * cosine
                if inverse:
                    total_real /= volume
                    total_imag /= volume
                out_real[out_index], out_imag[out_index] = total_real, total_imag
    return out_real, out_imag


def _frequency(index: int, side: int) -> int:
    return index if index <= side // 2 else index - side


def _checksum(real: Sequence[float], imag: Sequence[float], side: int) -> tuple[float, float]:
    total_real = total_imag = 0.0
    for j in range(1, CHECKSUM_TERMS + 1):
        x = (j - 1) % side
        y = (3 * j - 1) % side
        z = (5 * j - 1) % side
        index = (x * side + y) * side + z
        total_real += real[index]
        total_imag += imag[index]
    volume = side ** 3
    return total_real / volume, total_imag / volume


def expected_output(values: Sequence[int | float] | None,
                    output_capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, list[float]]:
    """Return ``(result, interleaved per-step checksums)`` for float64_slice_io."""
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
            or any(type(value) not in (int, float) or not math.isfinite(float(value))
                   for value in values)):
        return -1, []
    side_value, steps_value = values[:2]
    if not _integer(side_value, MIN_SIDE, MAX_SIDE) or not _integer(steps_value, MIN_STEPS, MAX_STEPS):
        return -1, []
    side, steps = int(side_value), int(steps_value)
    volume = side ** 3
    if side not in (2, 4) or len(values) != 2 + 2 * volume:
        return -1, []
    components = [float(value) for value in values[2:]]
    if any(not -1.0 <= value <= 1.0 for value in components):
        return -1, []
    real, imag = components[0::2], components[1::2]
    needed = 2 * steps
    if output_is_null or output_capacity is not None and output_capacity < needed:
        return -2, []

    spectrum_real, spectrum_imag = _direct_transform(real, imag, side, inverse=False)
    result: list[float] = []
    for step in range(1, steps + 1):
        field_real = [0.0] * volume
        field_imag = [0.0] * volume
        for x in range(side):
            kx = _frequency(x, side)
            for y in range(side):
                ky = _frequency(y, side)
                for z in range(side):
                    kz = _frequency(z, side)
                    index = (x * side + y) * side + z
                    factor = math.exp(-4.0 * math.pi * math.pi * ALPHA * step
                                      * (kx * kx + ky * ky + kz * kz))
                    field_real[index] = spectrum_real[index] * factor
                    field_imag[index] = spectrum_imag[index] * factor
        field_real, field_imag = _direct_transform(field_real, field_imag, side, inverse=True)
        result.extend(_checksum(field_real, field_imag, side))
    return needed, result
