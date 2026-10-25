"""Independent gather-form oracle for bounded Parboil MRI gridding."""

from __future__ import annotations

from collections.abc import Sequence
import math
import struct

MAX_SAMPLES = 4
MAX_INPUT_LENGTH = 25
GRID_SIDE = 3
GRID_CELLS = 27
WIDTH = struct.unpack("<f", struct.pack("<f", 2.5))[0]
OVERSAMPLE = struct.unpack("<f", struct.pack("<f", 0.608933))[0]
COEFF = tuple(struct.unpack("<f", struct.pack("<f", x))[0] for x in (
    0.210580722890567e-22, 0.380715242345326e-19, 0.479440257548300e-16,
    0.435125971262668e-13, 0.300931127112960e-10, 0.160224679395361e-7,
    0.654858370096785e-5, 0.202591084143397e-2, 0.463076284721000e0,
    0.754337328948189e2, 0.830792541809429e4, 0.571661130563785e6,
    0.216415572361227e8, 0.356644482244025e9, 0.144048298227235e10,
))


def _f32(value: float) -> float:
    return struct.unpack("<f", struct.pack("<f", float(value)))[0]


def _decode(raw: int) -> float:
    return _f32(_f32(raw) / _f32(1_000_000))


def _kernel(value: float) -> float:
    z = _f32(value * value)
    numerator = COEFF[0]
    for coefficient in COEFF[1:]:
        product = _f32(z * numerator)
        numerator = _f32(product + coefficient)
    denominator = _f32(z - _f32(0.307646912682801e4))
    denominator = _f32(z * denominator)
    denominator = _f32(denominator + _f32(0.347626332405882e7))
    denominator = _f32(z * denominator)
    denominator = _f32(denominator - _f32(0.144048298227235e10))
    return _f32(_f32(-numerator) / denominator)


def _beta() -> float:
    first = _f32(_f32(4.0) * WIDTH)
    first = _f32(first * WIDTH)
    divisor = _f32(OVERSAMPLE * OVERSAMPLE)
    first = _f32(first / divisor)
    shifted = float(OVERSAMPLE) - 0.5
    argument = float(first) * shifted
    argument = argument * shifted
    argument = argument - 0.8
    return _f32(3.14159265359 * math.sqrt(argument))


def _weight(v: float, inverse_cutoff2: float, beta: float, sdc: float) -> float:
    product = _f32(v * inverse_cutoff2)
    radicand = 1.0 - float(product)
    argument = _f32(float(beta) * math.sqrt(radicand))
    return _f32(_kernel(argument) * sdc)


def _quantize(value: float) -> int:
    scaled = _f32(value * _f32(1000))
    magnitude = -scaled if scaled < 0 else scaled
    whole = int(magnitude)
    if magnitude - _f32(whole) >= _f32(0.5):
        whole += 1
    return -whole if scaled < 0 else whole


def _valid(values: Sequence[int] | None) -> bool:
    if values is None or len(values) < 1 or len(values) > MAX_INPUT_LENGTH:
        return False
    if any(type(value) is not int for value in values):
        return False
    n = values[0]
    if n < 0 or n > MAX_SAMPLES or len(values) != 1 + 6 * n:
        return False
    for sample in range(n):
        p = 1 + 6 * sample
        if any(values[p + axis] not in (0, 1_000_000, 2_000_000) for axis in range(3)):
            return False
        if any(not -1_000_000 <= values[p + axis] <= 1_000_000 for axis in (3, 4)):
            return False
        if not 0 <= values[p + 5] <= 1_000_000:
            return False
    return True


def expected_result(values: Sequence[int] | None) -> int:
    """Return the Q1000 final-grid checksum, or -1 for an invalid frame."""
    if not _valid(values):
        return -1
    n = values[0]
    samples = []
    for s in range(n):
        p = 1 + 6 * s
        samples.append(tuple(_decode(values[p + offset]) for offset in range(6)))

    cutoff = _f32(float(WIDTH) / 2.0)
    cutoff2 = _f32(cutoff * cutoff)
    inverse = _f32(_f32(1.0) / cutoff2)
    beta = _beta()
    real_grid = [0.0] * GRID_CELLS
    imag_grid = [0.0] * GRID_CELLS
    density = [0.0] * GRID_CELLS

    # Gather each final voxel from the input samples. This has a different
    # traversal shape from the source's sample-major neighborhood scatter.
    for index in range(GRID_CELLS):
        x = index % GRID_SIDE
        y = (index // GRID_SIDE) % GRID_SIDE
        z = index // (GRID_SIDE * GRID_SIDE)
        for kx, ky, kz, sample_real, sample_imag, sdc in samples:
            if not (sample_real != 0.0 or sample_imag != 0.0) or sdc == 0.0:
                continue
            dx = _f32(kx - _f32(x)); dx2 = _f32(dx * dx)
            dy = _f32(ky - _f32(y)); dy2 = _f32(dy * dy)
            dz = _f32(kz - _f32(z)); dz2 = _f32(dz * dz)
            if dz2 >= cutoff2:
                continue
            yz = _f32(dz2 + dy2)
            if yz >= cutoff2:
                continue
            v = _f32(yz + dx2)
            if v >= cutoff2:
                continue
            w = _weight(v, inverse, beta, sdc)
            real_grid[index] = _f32(real_grid[index] + _f32(w * sample_real))
            imag_grid[index] = _f32(imag_grid[index] + _f32(w * sample_imag))
            density[index] = _f32(float(density[index]) + 1.0)

    checksum = 0
    for index in range(GRID_CELLS):
        checksum += (index + 1) * (
            _quantize(real_grid[index]) + _quantize(imag_grid[index]) + int(density[index])
        )
    return checksum


oracle = expected_result
