"""Reference the bounded Stanford FloatMM stdout contract."""

from __future__ import annotations

import struct

SIDE = 40
MAX_PASSES = 40
MAX_OUTPUT_BYTES = 14 * MAX_PASSES
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _f32(value: float | int) -> float:
    return struct.unpack("<f", struct.pack("<f", float(value)))[0]


def _matrix(seed: int) -> tuple[list[list[float]], int]:
    matrix = [[0.0] * SIDE for _ in range(SIDE)]
    for row in range(SIDE):
        for column in range(SIDE):
            seed = (seed * 1309 + 13849) & 65535
            remainder = seed - (seed // 120) * 120
            numerator = remainder - 60
            matrix[row][column] = _f32(_f32(numerator) / _f32(3.0))
    return matrix, seed


def _diagonal_product() -> list[float]:
    seed = 74755
    left, seed = _matrix(seed)
    right, _ = _matrix(seed)
    diagonal = [0.0] * SIDE
    for row in range(SIDE):
        for column in range(SIDE):
            total = _f32(0.0)
            for inner in range(SIDE):
                product = _f32(left[row][inner] * right[inner][column])
                total = _f32(total + product)
            if row == column:
                diagonal[row] = total
    return diagonal


def expected_output(passes: int) -> tuple[int, bytes]:
    """Return the source-formatted diagonal lines for a bounded pass count."""
    if type(passes) is not int or not 0 <= passes <= MAX_PASSES:
        return INVALID_RESULT, b""
    if passes == 0:
        return 0, b""

    # Every source pass resets the RNG, so the full product is identical. The
    # oracle computes it once and selects the same diagonal prefix.
    diagonal = _diagonal_product()
    lines = [f"{diagonal[run]:.6f}\n" for run in range(passes)]
    output = "".join(lines).encode("ascii")
    return len(output), output
