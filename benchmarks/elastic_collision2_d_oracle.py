"""Bounded source contract for the Java two-body 2D elastic impulse."""
from __future__ import annotations

import math

MAX_INPUT_LENGTH = 12
INVALID_RESULT = -1


def expected_result(values: list[int]) -> int:
    if len(values) != MAX_INPUT_LENGTH:
        return INVALID_RESULT
    ax, ay, avx, avy, am, ar, bx, by, bvx, bvy, bm, br = values
    if any(abs(v) > 200_000 for v in (ax, ay, bx, by)):
        return INVALID_RESULT
    if any(abs(v) > 5_000 for v in (avx, avy, bvx, bvy)):
        return INVALID_RESULT
    if not (1_000 <= am <= 100_000 and 1_000 <= bm <= 100_000):
        return INVALID_RESULT
    if not (1 <= ar <= 10_000 and 1 <= br <= 10_000):
        return INVALID_RESULT
    dx, dy = bx - ax, by - ay
    dist = math.hypot(dx, dy)
    if dist == 0.0:
        return INVALID_RESULT
    if dist < ar + br:
        out_x, out_y = avx, avy
    else:
        nx, ny = dx / dist, dy / dist
        rv = (bvx - avx) * nx + (bvy - avy) * ny
        if rv > 0.0:
            out_x, out_y = avx, avy
        else:
            j = -2.0 * rv / (1.0 / am + 1.0 / bm)
            out_x = avx - j * nx / am
            out_y = avy - j * ny / am
    qx, qy = math.floor(out_x + 0.5), math.floor(out_y + 0.5)
    if not (-32768 <= qx <= 32767 and -32768 <= qy <= 32767):
        return INVALID_RESULT
    packed = ((qx & 0xFFFF) << 16) | (qy & 0xFFFF)
    return packed
