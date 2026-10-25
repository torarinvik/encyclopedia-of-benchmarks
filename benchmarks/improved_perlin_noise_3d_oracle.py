"""Independent bounded oracle for classic improved 3D Perlin gradient noise."""

from __future__ import annotations

import math
from typing import Sequence

MIN_COORDINATE = -1_000_000.0
MAX_COORDINATE = 1_000_000.0
INVALID_RESULT = -1.0

_PERMUTATION = (
    151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225,
    140, 36, 103, 30, 69, 142, 8, 99, 37, 240, 21, 10, 23, 190, 6, 148,
    247, 120, 234, 75, 0, 26, 197, 62, 94, 252, 219, 203, 117, 35, 11, 32,
    57, 177, 33, 88, 237, 149, 56, 87, 174, 20, 125, 136, 171, 168, 68, 175,
    74, 165, 71, 134, 139, 48, 27, 166, 77, 146, 158, 231, 83, 111, 229, 122,
    60, 211, 133, 230, 220, 105, 92, 41, 55, 46, 245, 40, 244, 102, 143, 54,
    65, 25, 63, 161, 1, 216, 80, 73, 209, 76, 132, 187, 208, 89, 18, 169,
    200, 196, 135, 130, 116, 188, 159, 86, 164, 100, 109, 198, 173, 186, 3,
    64, 52, 217, 226, 250, 124, 123, 5, 202, 38, 147, 118, 126, 255, 82, 85,
    212, 207, 206, 59, 227, 47, 16, 58, 17, 182, 189, 28, 42, 223, 183, 170,
    213, 119, 248, 152, 2, 44, 154, 163, 70, 221, 153, 101, 155, 167, 43,
    172, 9, 129, 22, 39, 253, 19, 98, 108, 110, 79, 113, 224, 232, 178, 185,
    112, 104, 218, 246, 97, 228, 251, 34, 242, 193, 238, 210, 144, 12, 191,
    179, 162, 241, 81, 51, 145, 235, 249, 14, 239, 107, 49, 192, 214, 31,
    181, 199, 106, 157, 184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150,
    254, 138, 236, 205, 93, 222, 114, 67, 29, 24, 72, 243, 141, 128, 195,
    78, 66, 215, 61, 156, 180,
)
_P = _PERMUTATION + _PERMUTATION


def _fade(value: float) -> float:
    return value * value * value * (value * (value * 6.0 - 15.0) + 10.0)


def _lerp(amount: float, left: float, right: float) -> float:
    return left + amount * (right - left)


def _grad(hash_value: int, x: float, y: float, z: float) -> float:
    h = hash_value & 15
    u = x if h < 8 else y
    v = y if h < 4 else (x if h in (12, 14) else z)
    return (u if (h & 1) == 0 else -u) + (v if (h & 2) == 0 else -v)


def expected_result(values: Sequence[int | float] | None) -> float:
    """Evaluate the pinned nested interpolation order for one 3D point."""
    if not isinstance(values, (list, tuple)) or len(values) != 3:
        return INVALID_RESULT
    for value in values:
        if type(value) not in (int, float):
            return INVALID_RESULT
        if value < MIN_COORDINATE or value > MAX_COORDINATE:
            return INVALID_RESULT
        if not math.isfinite(float(value)):
            return INVALID_RESULT

    x, y, z = map(float, values)
    floor_x, floor_y, floor_z = math.floor(x), math.floor(y), math.floor(z)
    ix, iy, iz = floor_x & 255, floor_y & 255, floor_z & 255
    x -= floor_x
    y -= floor_y
    z -= floor_z
    u, v, w = _fade(x), _fade(y), _fade(z)

    a = _P[ix] + iy
    aa = _P[a] + iz
    ab = _P[a + 1] + iz
    b = _P[ix + 1] + iy
    ba = _P[b] + iz
    bb = _P[b + 1] + iz

    return _lerp(
        w,
        _lerp(v,
              _lerp(u, _grad(_P[aa], x, y, z), _grad(_P[ba], x - 1.0, y, z)),
              _lerp(u, _grad(_P[ab], x, y - 1.0, z), _grad(_P[bb], x - 1.0, y - 1.0, z))),
        _lerp(v,
              _lerp(u, _grad(_P[aa + 1], x, y, z - 1.0),
                    _grad(_P[ba + 1], x - 1.0, y, z - 1.0)),
              _lerp(u, _grad(_P[ab + 1], x, y - 1.0, z - 1.0),
                    _grad(_P[bb + 1], x - 1.0, y - 1.0, z - 1.0))),
    )
