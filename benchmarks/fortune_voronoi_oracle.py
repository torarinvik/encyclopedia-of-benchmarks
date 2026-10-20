"""Independent exact half-plane oracle for the bounded Fortune Voronoi package."""

from __future__ import annotations

from fractions import Fraction
from itertools import combinations
from struct import pack

MAX_SITES = 8
MAX_PARSEABLE_INPUT_LENGTH = 1 + 2 * MAX_SITES
MAX_OUTPUT_BYTES = 2952
COORD_MIN = -8
COORD_MAX = 8
BOX_MIN = -16
BOX_MAX = 16
INVALID_RESULT = -1
INSUFFICIENT_OUTPUT_CAPACITY = -2


def _valid_sites(values: list[int] | tuple[int, ...]) -> list[tuple[int, int]] | None:
    if not values or len(values) < 3:
        return None
    n = values[0]
    if not 1 <= n <= MAX_SITES or len(values) != 1 + 2 * n:
        return None
    sites = [(values[1 + 2 * i], values[2 + 2 * i]) for i in range(n)]
    if any(not COORD_MIN <= x <= COORD_MAX or not COORD_MIN <= y <= COORD_MAX for x, y in sites):
        return None
    if len(set(sites)) != n or len({y for _, y in sites}) != n:
        return None
    for a, b, c in combinations(sites, 3):
        if (b[0] - a[0]) * (c[1] - a[1]) == (b[1] - a[1]) * (c[0] - a[0]):
            return None
    for a, b, c, d in combinations(sites, 4):
        ax, ay = a[0] - d[0], a[1] - d[1]
        bx, by = b[0] - d[0], b[1] - d[1]
        cx, cy = c[0] - d[0], c[1] - d[1]
        aa, bb, cc = ax * ax + ay * ay, bx * bx + by * by, cx * cx + cy * cy
        determinant = ax * (by * cc - bb * cy) - ay * (bx * cc - bb * cx) + aa * (bx * cy - by * cx)
        if determinant == 0:
            return None
    return sites


def _clip(poly: list[tuple[Fraction, Fraction]], a: int, b: int, c: int):
    if not poly:
        return []
    result: list[tuple[Fraction, Fraction]] = []
    for p, q in zip(poly, poly[1:] + poly[:1]):
        dp = a * p[0] + b * p[1] - c
        dq = a * q[0] + b * q[1] - c
        pin, qin = dp <= 0, dq <= 0
        if pin and qin:
            result.append(q)
        elif pin and not qin:
            t = dp / (dp - dq)
            result.append((p[0] + t * (q[0] - p[0]), p[1] + t * (q[1] - p[1])))
        elif not pin and qin:
            t = dp / (dp - dq)
            result.append((p[0] + t * (q[0] - p[0]), p[1] + t * (q[1] - p[1])))
            result.append(q)
    compact: list[tuple[Fraction, Fraction]] = []
    for point in result:
        if not compact or compact[-1] != point:
            compact.append(point)
    if len(compact) > 1 and compact[0] == compact[-1]:
        compact.pop()
    return compact


def _cell(sites: list[tuple[int, int]], site_index: int):
    sx, sy = sites[site_index]
    poly = [
        (Fraction(BOX_MIN), Fraction(BOX_MIN)),
        (Fraction(BOX_MAX), Fraction(BOX_MIN)),
        (Fraction(BOX_MAX), Fraction(BOX_MAX)),
        (Fraction(BOX_MIN), Fraction(BOX_MAX)),
    ]
    for j, (x, y) in enumerate(sites):
        if j == site_index:
            continue
        a, b = 2 * (x - sx), 2 * (y - sy)
        c = x * x + y * y - sx * sx - sy * sy
        poly = _clip(poly, a, b, c)
    if len(poly) < 3:
        return None
    start = min(range(len(poly)), key=lambda i: (poly[i][0], poly[i][1]))
    return poly[start:] + poly[:start]


def fortune_voronoi_values(values: list[int] | tuple[int, ...]) -> list[int] | None:
    """Return the exact output vector, or None when input is outside the profile."""
    sites = _valid_sites(values)
    if sites is None:
        return None
    output = [len(sites)]
    for i in range(len(sites)):
        poly = _cell(sites, i)
        if poly is None:
            return None
        output.extend((i, len(poly)))
        for x, y in poly:
            output.extend((x.numerator, x.denominator, y.numerator, y.denominator))
    return output


def expected_output(values: list[int] | tuple[int, ...] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    """Match the package's result code and little-endian i64 output bytes."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return INVALID_RESULT, b""
    if input_is_null:
        return INVALID_RESULT, b""
    if values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(value) is not int or value < -(1 << 63) or value >= (1 << 63) for value in values):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    vector = fortune_voronoi_values(values)
    if vector is None:
        return INVALID_RESULT, b""
    raw = b"".join(pack("<q", value) for value in vector)
    if len(raw) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < len(raw)):
        return INSUFFICIENT_OUTPUT_CAPACITY, b""
    return len(raw), raw


fortune_voronoi_oracle = expected_output
