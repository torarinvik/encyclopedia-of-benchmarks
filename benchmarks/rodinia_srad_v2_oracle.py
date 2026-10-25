"""Independent fixed-binary32 model of Rodinia SRAD v2's two CUDA kernels."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence

PIXELS = 16 * 16
INPUT_LENGTH = 2 + PIXELS
INVALID_RESULT = -1
CHECKSUM_SCALE = 1_000_000
LAMBDA_MIN_BITS = 0x3C23D70A  # 0.01f
LAMBDA_MAX_BITS = 0x3DCCCCCD  # 0.1f
Q0_MIN_BITS = 0x3C23D70A
Q0_MAX_BITS = 0x3F800000
IMAGE_MIN_BITS = 0x3F800000  # exp(0)
IMAGE_MAX_BITS = 0x3FA00000  # 1.25f, a bounded subrange of expf([0,1])


def _f32(value: float) -> float:
    return struct.unpack("<f", struct.pack("<f", value))[0]


def _from_bits(bits: int) -> float:
    return struct.unpack("<f", struct.pack("<I", bits))[0]


def _is_finite_positive_range(bits: int, low: int, high: int) -> bool:
    return low <= bits <= high


def _fadd(a: float, b: float) -> float:
    return _f32(a + b)


def _fsub(a: float, b: float) -> float:
    return _f32(a - b)


def _fmul(a: float, b: float) -> float:
    return _f32(a * b)


def _fdiv(a: float, b: float) -> float:
    return _f32(a / b)


def expected_result(values: Sequence[int] | None) -> int:
    """Run one 16x16 SRAD v2 kernel pair and return the fixed-point J checksum."""
    if (not isinstance(values, (tuple, list)) or len(values) != INPUT_LENGTH
            or any(type(value) is not int or value < 0 or value > 0xFFFFFFFF
                   for value in values)):
        return INVALID_RESULT

    lambda_bits, q0_bits = values[:2]
    if (not _is_finite_positive_range(lambda_bits, LAMBDA_MIN_BITS, LAMBDA_MAX_BITS)
            or not _is_finite_positive_range(q0_bits, Q0_MIN_BITS, Q0_MAX_BITS)
            or any(not _is_finite_positive_range(bits, IMAGE_MIN_BITS, IMAGE_MAX_BITS)
                   for bits in values[2:])):
        return INVALID_RESULT

    lam = _from_bits(lambda_bits)
    q0sqr = _from_bits(q0_bits)
    image = [_from_bits(bits) for bits in values[2:]]
    coeff = [0.0] * PIXELS
    north = [0.0] * PIXELS
    south = [0.0] * PIXELS
    west = [0.0] * PIXELS
    east = [0.0] * PIXELS

    # Kernel 1: source row-major block access, clamped image edges, and the
    # source's float stores after each named intermediate.
    for row in range(16):
        for col in range(16):
            index = row * 16 + col
            jc = image[index]
            n = _fsub(image[(row - 1 if row else row) * 16 + col], jc)
            s = _fsub(image[(row + 1 if row < 15 else row) * 16 + col], jc)
            w = _fsub(image[row * 16 + (col - 1 if col else col)], jc)
            e = _fsub(image[row * 16 + (col + 1 if col < 15 else col)], jc)
            north[index], south[index], west[index], east[index] = n, s, w, e

            gradient = _fadd(_fadd(_fadd(_fmul(n, n), _fmul(s, s)), _fmul(w, w)),
                             _fmul(e, e))
            gradient = _fdiv(gradient, _fmul(jc, jc))
            laplacian = _fdiv(_fadd(_fadd(_fadd(n, s), w), e), jc)

            # In the pinned C++ expressions, these unsuffixed constants are
            # double. The l*l product is float before promotion; num/den/c are
            # rounded back to float at their source assignments.
            num = _f32(0.5 * float(gradient)
                       - (1.0 / 16.0) * float(_fmul(laplacian, laplacian)))
            den = _f32(1.0 + 0.25 * float(laplacian))
            if den == 0.0:
                return INVALID_RESULT
            qsqr = _fdiv(num, _fmul(den, den))
            den = _fdiv(_fsub(qsqr, q0sqr), _fmul(q0sqr, _fadd(1.0, q0sqr)))
            if den == -1.0:
                return INVALID_RESULT
            c = _f32(1.0 / (1.0 + float(den)))
            if not math.isfinite(c):
                return INVALID_RESULT
            coeff[index] = 0.0 if c < 0.0 else 1.0 if c > 1.0 else c

    # Kernel 2: the CUDA source explicitly takes north and west coefficients
    # from the current cell; south/east use the next cell or the clamped edge.
    updated = [0.0] * PIXELS
    for row in range(16):
        for col in range(16):
            index = row * 16 + col
            cc = coeff[index]
            cs = coeff[(row + 1 if row < 15 else row) * 16 + col]
            ce = coeff[row * 16 + (col + 1 if col < 15 else col)]
            divergence = _fadd(
                _fadd(_fadd(_fmul(cc, north[index]), _fmul(cs, south[index])),
                      _fmul(cc, west[index])),
                _fmul(ce, east[index]))
            # Source uses unsuffixed 0.25, so update arithmetic is binary64
            # until the float assignment to J_cuda[index].
            updated[index] = _f32(float(image[index]) + 0.25 * float(lam) * float(divergence))
            if not math.isfinite(updated[index]) or updated[index] < 0.0:
                return INVALID_RESULT

    # Stable public observation: nearest integer to each J*1e6, ties upward,
    # accumulated in row-major source order.
    checksum = 0
    for value in updated:
        checksum += int(float(value) * CHECKSUM_SCALE + 0.5)
    return checksum
