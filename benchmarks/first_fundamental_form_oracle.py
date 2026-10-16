"""Bounded exact polynomial oracle for the first fundamental form."""
from __future__ import annotations

MAX_INPUT_LENGTH = 18
INVALID_RESULT = -1
MASK64 = (1 << 64) - 1
FNV_OFFSET = 0xCBF29CE484222325
FNV_PRIME = 0x100000001B3


def _feed(h: int, x: int) -> int:
    for byte in x.to_bytes(8, "little", signed=True):
        h = ((h ^ byte) * FNV_PRIME) & MASK64
    return h


def expected_result(values: list[int]) -> int:
    if len(values) != MAX_INPUT_LENGTH or any(x < -100 or x > 100 for x in values):
        return INVALID_RESULT
    # x,y,z each use [1,u,v,u^2,uv,v^2]. Differentiate to [1,u,v].
    ru, rv = [], []
    for i in range(0, 18, 6):
        a0, a1, a2, a3, a4, a5 = values[i:i + 6]
        ru.append([a1, 2 * a3, a4])
        rv.append([a2, a4, 2 * a5])

    def dot_poly(left: list[list[int]], right: list[list[int]]) -> list[int]:
        out = [0] * 6
        for a, b in zip(left, right):
            out[0] += a[0] * b[0]
            out[1] += a[0] * b[1] + a[1] * b[0]
            out[2] += a[0] * b[2] + a[2] * b[0]
            out[3] += a[1] * b[1]
            out[4] += a[1] * b[2] + a[2] * b[1]
            out[5] += a[2] * b[2]
        return out

    coefficients = dot_poly(ru, ru) + dot_poly(ru, rv) + dot_poly(rv, rv)
    h = FNV_OFFSET
    for coefficient in coefficients:
        h = _feed(h, coefficient)
    return h if h < (1 << 63) else h - (1 << 64)
