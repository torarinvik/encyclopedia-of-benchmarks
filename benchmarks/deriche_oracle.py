"""Reference model for the bounded PolyBench/C Deriche image filter."""

from __future__ import annotations

import math
import struct

INVALID_RESULT = -1e300
MAX_WIDTH = 32
MAX_HEIGHT = 32
MAX_ITERATIONS = 4
MAX_INPUT_LENGTH = 3
ALPHA = 0.25


def _f32(value: float) -> float:
    return struct.unpack("=f", struct.pack("=f", value))[0]


def _add(left: float, right: float) -> float:
    return _f32(left + right)


def _mul(left: float, right: float) -> float:
    return _f32(left * right)


def _coefficients() -> tuple[float, ...]:
    alpha = _f32(ALPHA)
    one = _f32(1.0)
    two = _f32(2.0)
    exp_neg_alpha = _f32(math.exp(-alpha))
    numerator_left = _add(one, -exp_neg_alpha)
    numerator = _mul(numerator_left, numerator_left)
    denominator = _add(one, _mul(_mul(two, alpha), exp_neg_alpha))
    exp_two_alpha = _f32(math.exp(_mul(two, alpha)))
    denominator = _add(denominator, -exp_two_alpha)
    k = _f32(numerator / denominator)
    a1 = k
    a2 = _mul(_mul(k, exp_neg_alpha), _add(alpha, -one))
    a3 = _mul(_mul(k, exp_neg_alpha), _add(alpha, one))
    exp_neg_two_alpha = _f32(math.exp(-_mul(two, alpha)))
    a4 = -_mul(k, exp_neg_two_alpha)
    a5 = a1
    a6 = a2
    a7 = a3
    a8 = a4
    b1 = _f32(math.pow(2.0, -alpha))
    b2 = -exp_neg_two_alpha
    return a1, a2, a3, a4, a5, a6, a7, a8, b1, b2


def _filter_once(width: int, height: int, image: list[float]) -> list[float]:
    a1, a2, a3, a4, a5, a6, a7, a8, b1, b2 = _coefficients()
    y1 = [0.0] * (width * height)
    y2 = [0.0] * (width * height)
    output = [0.0] * (width * height)

    for i in range(width):
        ym1 = ym2 = xm1 = 0.0
        for j in range(height):
            at = i * height + j
            value = _add(_mul(a1, image[at]), _mul(a2, xm1))
            value = _add(value, _mul(b1, ym1))
            value = _add(value, _mul(b2, ym2))
            y1[at] = value
            xm1, ym2, ym1 = image[at], ym1, value

    for i in range(width):
        yp1 = yp2 = xp1 = xp2 = 0.0
        for j in range(height - 1, -1, -1):
            at = i * height + j
            value = _add(_mul(a3, xp1), _mul(a4, xp2))
            value = _add(value, _mul(b1, yp1))
            value = _add(value, _mul(b2, yp2))
            y2[at] = value
            xp2, xp1, yp2, yp1 = xp1, image[at], yp1, value

    for i in range(width):
        for j in range(height):
            at = i * height + j
            output[at] = _f32(y1[at] + y2[at])

    for j in range(height):
        tm1 = ym1 = ym2 = 0.0
        for i in range(width):
            at = i * height + j
            value = _add(_mul(a5, output[at]), _mul(a6, tm1))
            value = _add(value, _mul(b1, ym1))
            value = _add(value, _mul(b2, ym2))
            y1[at] = value
            tm1, ym2, ym1 = output[at], ym1, value

    for j in range(height):
        tp1 = tp2 = yp1 = yp2 = 0.0
        for i in range(width - 1, -1, -1):
            at = i * height + j
            value = _add(_mul(a7, tp1), _mul(a8, tp2))
            value = _add(value, _mul(b1, yp1))
            value = _add(value, _mul(b2, yp2))
            y2[at] = value
            tp2, tp1, yp2, yp1 = tp1, output[at], yp1, value

    for at in range(width * height):
        output[at] = _f32(y1[at] + y2[at])
    return output


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    if (not isinstance(values, (list, tuple)) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    width, height, iterations = values
    if not (1 <= width <= MAX_WIDTH and 1 <= height <= MAX_HEIGHT
            and 1 <= iterations <= MAX_ITERATIONS):
        return INVALID_RESULT

    image = [
        _f32(((313 * i + 991 * j) % 65536) / 65535.0)
        for i in range(width)
        for j in range(height)
    ]
    for _ in range(iterations):
        image = _filter_once(width, height, image)
    # Binary64, row-major sum of the final binary32 image, used as the ABI checksum.
    return sum(float(pixel) for pixel in image)
